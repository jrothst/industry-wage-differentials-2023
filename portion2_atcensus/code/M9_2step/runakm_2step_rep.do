
/*----------------------------------------------------------------------------*\


	2-step AKM, 100% Sample

	Input Datasets:
		- "$yidata/m5_ecf_seinunit.dta"
		- "$yidata/czranking6_alt-wage.dta"
		- "$yidata/mig5_pikqtime_1018a.dta"
		- "$yidata/mig5_pikqtime_1018b.dta"
		- "$yidata/mig5_pikqtime_1018_finalpiklist.dta"
		- "$yidata/cw_st_div.dta"		
		- "$yidata/cw_cty_czone_v2.dta"
			
	Output Datasets:
		- "$tempdir/datafrommatlab_firm.raw" 		
		- "$data2step/AKMests_2step.dta" 
		- "$data2step/AKMstats_2step.dta"
		- "$data2step/M9twostep_step1xbr.dta"	

		
\*----------------------------------------------------------------------------*/

// Basic setup
cap log close
set more off
clear
clear matrix
clear mata
set rmsg on

// Set directories 
include ind_paths.do


//------------------------------------------------------------------------------
// 2-STEP AKM MODEL
//------------------------------------------------------------------------------

local first=1
local files: dir "$datadir" files "mig5_*_cz*.dta"
foreach file in `files' {

		di "Opening: `file'"
		local cz = regexr("`file'", ".dta", "")
		local cz = regexr("`cz'", "mig5_pikqtime_1018_", "")
		local cz = regexr("`cz'", "[czd]+", "")
		di "Entering loop for CZ `cz'"
		
		use "$datadir/`file'", clear
		order pikn state qtime cz sein seinunit naics2d naics4d firmid y firmsize age
		
		* Add CZ for division 1-9
		if `cz'<10 {
			gen year=floor((qtime-1)/4+1985)
			gen quarter=qtime-4*(year-1985)
			merge m:1 sein seinunit year quarter using "$yidata/m5_ecf_seinunit.dta", keep(master match) keepusing(leg_state leg_county) nogen
			gen cty_fips = leg_state+leg_county
			destring cty_fips, replace
			merge m:1 cty_fips using "$yidata/cw_cty_czone_v2.dta", keep(1 3) nogen
			drop year quarter leg_state leg_county cty_fips
		}
		else if `cz'>10 {
			gen czone = cz
		}
		if `first'==1 {
			local czs `cz'
		}
		else if `first'==0 {
			local czs `czs' `cz'
		}
		tempfile temp_`cz'
		save `temp_`cz'', replace
		local first=0
	}
	
	di "`czs'"

	local first=1
	foreach cz in `czs' {
		if `first'==1 {
			di "`cz'"
			use `temp_`cz'', clear
		}
		else if `first'==0 {
			append using `temp_`cz''
		}
		local first=0
	}


timer on 21
qui count
di "Original sample has observation count=`r(N)'"
sort firmid pikn qtime
isid pikn qtime
egen double firmnum=group(czone state firmid)

// Estimate a preliminary regression to adjust for X controls
// This is estimated within CZ-industry-worker-firm cells.
egen double jobid=group(pikn czone state naics4d firmnum)
gen double age2=((age-40)/40)^2
gen double age3=((age-40)/40)^3
areg y age age2 age3 i.qtime, a(jobid) 
// Question: Should we adjust for gender-by-age?
predict jobmean, d
replace jobmean=jobmean+_b[_cons]
predict xb, xb
replace xb=xb-_b[_cons]
local dof_match=e(df_r)
local rmse_match=e(rmse)
local r2_match=e(r2)
local adjr2_match=e(r2_a)
predict e, residual
su e
local evar=r(Var)

gen byte havejobmean=(jobmean<.)
assert havejobmean<.
sort jobid qtime
by jobid: gen joblength=_N
by jobid: gen byte oneperjob=(_n==1)

// We are going to normalize a single industry to have zero mean firm effect
// Note: 7225 is restaurants
gen byte normind=(naics4d==7225)
sort pikn qtime
gen top59cz = cz
replace cz = 99
order pikn firmnum jobmean cz normind joblength
export delimited pikn firmnum jobmean cz normind joblength if oneperjob==1 ///
       using "$tempdir/data2matlab.raw", replace
tempfile data_quarters
save `data_quarters'
clear

*Clean up, so we will know if AKM worked
cap rm "$tempdir/datafrommatlab.raw"
timer off 21

***
*Run matlab to run the AKM model
timer on 22 // Matlab call
di "Starting the matlab call"
! matlab -nodisplay -nosplash -batch ///
 "firmAKM_spelldata_callable('$tempdir/data2matlab.raw', '$tempdir/datafrommatlab')"
di "Matlab call finished" 
timer off 22
***

timer on 23 // Post matlab call processing

*Confirm that it worked
import delimited using "$tempdir/datafrommatlab_cz.raw", clear
di v1[1]

*Now read in statistics from Matlab -- R2, sample sizes, etc.;
import delimited using "$tempdir/datafrommatlab_stats.raw", clear
*gen cz = regexr("`cz'", "[czd]+","")
*destring cz, replace
su reffirm, meanonly
local ref=r(min)
tempfile stats
save `stats', replace

*Read in the results
import delimited using "$tempdir/datafrommatlab_firm.raw", clear
rename v1 firmnum
rename v2 akm_firm
tempfile firmfx
save `firmfx'
import delimited using "$tempdir/datafrommatlab_person.raw", clear
rename v1 pikn
rename v2 akm_person
tempfile personfx
save `personfx'

use "`data_quarters'", clear
merge m:1 pikn using `personfx', assert(1 3) nogen
merge m:1 firmnum using `firmfx', assert(1 3) nogen
assert akm_person==. if akm_firm==.
assert akm_person<. if akm_firm<.
keep if akm_person<.
gen r = y - akm_person - akm_firm - xb
qui levelsof firmid if firmnum==`ref', clean
local reffirmtxt =r(levels)
save "$data2step/M9twostep_step1xbr.dta", replace

***Compute summary statistics that we used to do in matlab
timer on 31 // Post estimation summary stats
  corr akm_person akm_firm if oneperjob==1 [fw=joblength], cov
  local covpefe=r(cov_12)
  di "Variance-Covariance of worker and firm effs: `covpefe'"
  corr akm_person akm_firm if oneperjob==1 [fw=joblength]
  local corrpefe=r(rho)
  di "Correlation coefficient: `corrpefe'"
  su akm_person if oneperjob==1 [fw=joblength], meanonly
  local meanpe=r(mean)
  su akm_firm if oneperjob==1 [fw=joblength], meanonly
  local meanfe=r(mean)
  di "Mean of person effects is `meanpe'"
  di "Mean of firm effects is `meanfe'"

  di "Full Covariance Matrix of Components"
  corr y akm_person akm_firm xb r, cov
  tempname C
  matrix `C'=r(C)
  matrix list `C'
  
  di "Decomposition #1"
  di "var(y) = cov(pe,y) + cov(fe,y) + cov(xb,y) + cov(r,y)"
  local c11=el(`C', 1, 1)
  local c21=el(`C', 2, 1)
  local c31=el(`C', 3, 1)
  local c41=el(`C', 4, 1)
  local c51=el(`C', 5, 1)
  tempname decomp decomp_shares
  matrix `decomp'=[`c11', `c21', `c31', `c41' , `c51']
  matrix colnames `decomp'=y pe fe xb r
  matrix list `decomp'
  di "Identity is: " `c11' " = " `c21'+`c31'+`c41'+`c51'
  di "Explained shares"
  matrix `decomp_shares'=`decomp'/`c11'
  matrix list `decomp_shares'
  
  di "Decomposition #2"
  di "var(y) = var(pe) + var(fe) + var(xb) + 2*cov(pe,fe) + 2*cov(pe,xb) + 2*cov(fe,xb) + var(r)"
  tempname decomp2 sum decomp2_shares
  matrix `decomp2'=[el(`C',1,1), el(`C',2,2), el(`C',3,3), el(`C',4,4), 2*el(`C',2,3), 2*el(`C',2,4), 2*el(`C',3,4), el(`C',5,5)]
  matrix colnames `decomp2' = y pe fe xb cov_pe_fe cov_pe_xb cov_fe_xb r
  matrix list `decomp2'
  matrix `sum'=`decomp2'[1,2..8]*J(7,1,1)
  di "Identity is: " el(`decomp2', 1,1) " = " el(`sum', 1, 1)
  matrix `decomp2_shares'=`decomp2'/el(`decomp2', 1, 1)
  di "Explained shares"
  matrix list `decomp2_shares'

  di "joint distribution and separability"
  xtile pedec = akm_person, nquantiles(10)
  xtile fedec = akm_firm, nquantiles(10)
  tempname p
  tab pedec fedec if oneperjob==1 [fw=joblength], matcell(`p')
  qui count if pedec<. & fedec<.
  matrix `p'=`p'/r(N)
  table pedec fedec, contents(mean r)
  drop pedec fedec
  
  di "Further Decompositions:"
  di "Decomposing residual into match and transitory component"
  su jobmean if naics4d==2 & oneperjob==1 [fw=joblength], meanonly
  gen match=jobmean - akm_person - akm_firm
  gen e_second=r-match
  assert abs(e-e_second)<1e-5
  di "Full covariance matrix of components"
  corr y akm_person akm_firm xb m e, cov
  tempname C_match
  matrix `C_match'=r(C)
  matrix list `C_match'
  local matchshare=el(`C_match', 5, 5)/el(`C_match', 1, 1)
timer off 31

keep if oneperjob==1
keep pikn firmid firmnum jobid top59cz czone state naics4d akm_person akm_firm joblength match 
save "$data2step/AKMests_2step.dta", replace

*Now go back and fill in our stats
 use `stats', clear
 list
 rename r2 r2_spell
 rename adjr2 adjr2_spell
 gen meanpe=`meanpe'
 gen meanfe=`meanfe'
 gen corrpefe=`corrpefe'
 gen r2_match=`r2_match'
 gen adjr2_match=`adjr2_match'
 gen r2=r2_match - `matchshare'
 gen reffirm_orig="`reffirmtxt'"
 save "$data2step/AKMstats_2step.dta", replace

// Clean up residuals file
use "$data2step/M9twostep_step1xbr.dta", replace
keep pikn qtime sein seinunit firmnum jobid joblength naics4d top59cz czone akm_person akm_firm xb r
compress
order pikn qtime sein seinunit firmnum jobid joblength naics4d top59cz czone akm_person akm_firm xb r
save "$data2step/M9twostep_step1xbr.dta", replace


timer off 23
timer off 12
timer list 
qui timer list 12
di "This took `r(t12)' seconds to complete"
di "It finished on `c(current_date)' at `c(current_time)'"
di ""
di ""

log close
