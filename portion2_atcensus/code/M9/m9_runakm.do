
/*----------------------------------------------------------------------------*\

	Industry Project
	M9: AKM
	Loops over 50+9 CZs, 100% sample

\*----------------------------------------------------------------------------*/

// Basic setup
cap log close
set more off
clear
clear matrix
clear mata
set linesize 95
set rmsg on

// Set directories
include ind_paths.do


//------------------------------------------------------------------------------
// CREATE 100% SAMPLE BY TOP59CZ
//------------------------------------------------------------------------------
	
	// NAICS 4-digit
	//----------------------------------------------------------------------
	use sein seinunit year quarter naics2012fnl using "$yidata/m5_ecf_seinunit.dta", clear
	gen naics4d = substr(naics2012fnl,1,4)
	drop naics2012fnl
	sort sein seinunit year quarter
	tempfile ecf
	save `ecf'

	// Top 59 saved by CZ, 100% sample
	//----------------------------------------------------------------------

	* Identify top 50 CZs
	use cz wcount using "$yidata/czranking6_alt-wage.dta", replace
	gsort -wcount
	keep if _n<=50
	levelsof cz, local(top50)
	levelsof cz, local(top_50) sep(,)

	foreach cz in `top50' {
		use pik qtime sein seinunit e dob cz naics2d state if cz==`cz' using "$yidata/mig5_pikqtime_1018a.dta", replace
		tempfile tempdata
		save `tempdata', replace
		use pik qtime sein seinunit e dob cz naics2d state if cz==`cz' using "$yidata/mig5_pikqtime_1018b.dta", replace
		append using `tempdata'
		sort pik qtime
		merge m:1 pik using "$yidata/mig5_pikqtime_1018_finalpiklist.dta", keep(match) sorted nogen
		drop sample
		order pikn, a(pik)

		// Merge in naics4d
		gen year=floor((qtime-1)/4+1985)
		gen quarter=qtime-4*(year-1985)
		sort sein seinunit year quarter
		merge m:1 sein seinunit year quarter using `ecf', sorted keep(master match) keepusing(naics4d)
		destring naics4d, replace force
		drop _merge year quarter

		* reformatting to match matlab (encoding might change across samples)
		gen firmid=sein + "_" + seinunit
		gen y=ln(e)
		bys firmid qtime: gen firmsize=_N
		gen age=floor(((qtime+99)-qofd(dob))/4)
		drop e dob pik
		bys pikn qtime: assert _n==1

		compress
		save "$datadir/mig5_pikqtime_1018_cz`cz'", replace
	}

	* Add non-top 50 CZs as divisions
	forvalues n = 1(1)9 {
		use pik qtime cz state if !inlist(cz,`top_50') using "$yidata/mig5_pikqtime_1018a.dta", replace
		ren state statefips
		merge m:1 statefips using "$yidata/cw_st_div.dta", keep(master match) nogen
		ren statefips state
		keep if division==`n'
		merge 1:1 pik qtime using "$yidata/mig5_pikqtime_1018a.dta", keep(match) keepusing(sein seinunit e dob naics2d) nogen
		replace cz = division
		tempfile tempdata
		save `tempdata', replace
		use pik qtime cz state if !inlist(cz,`top_50') using "$yidata/mig5_pikqtime_1018b.dta", replace
		ren state statefips
		merge m:1 statefips using "$yidata/cw_st_div.dta", keep(master match) nogen
		ren statefips state
		keep if division==`n'
		merge 1:1 pik qtime using "$yidata/mig5_pikqtime_1018b.dta", keep(match) keepusing(sein seinunit e dob naics2d) nogen
		replace cz = division
		append using `tempdata'
		sort pik qtime
		merge m:1 pik using "$yidata/mig5_pikqtime_1018_finalpiklist.dta", keep(match) sorted nogen
		drop sample
		order pikn, a(pik)

		// Merge in naics4d
		gen year=floor((qtime-1)/4+1985)
		gen quarter=qtime-4*(year-1985)
		sort sein seinunit year quarter
		merge m:1 sein seinunit year quarter using `ecf', sorted keep(master match) keepusing(naics4d)
		destring naics4d, replace force
		drop _merge year quarter
		
		* reformatting to match matlab (encoding might change across samples)
		gen firmid=sein + "_" + seinunit
		gen y=ln(e)
		bys firmid qtime: gen firmsize=_N
		gen age=floor(((qtime+99)-qofd(dob))/4)
		drop e dob pik
		bys pikn qtime: assert _n==1

		compress
		order pikn state qtime cz sein seinunit naics2d naics4d firmid y firmsize age
		save "$datadir/mig5_pikqtime_1018_czd`n'", replace
		
	}


//------------------------------------------------------------------------------
// Loop over all CZs in 100% sample
//------------------------------------------------------------------------------

local first=1
local files: dir "$datadir" files "mig5_*_cz*.dta"
foreach file in `files' {

	di "Opening: `file'"
	d using "$datadir/`file'"
	timer clear 12
	timer on 12
	local cz = regexr("`file'", ".dta", "")
	local cz = regexr("`cz'", "mig5_pikqtime_1018_", "")
	di "Entering loop for CZ `cz'"
	use "$datadir/`file'", clear
	order pikn state qtime cz sein seinunit naics2d naics4d firmid y firmsize age
	qui count
	di "Original sample has observation count=`r(N)'"
	isid pikn qtime
	sort firmid pikn qtime
	egen double firmnum=group(firmid)
	// We are going to normalize a single industry to have zero mean firm effect
	// Note: 7225 is restaurants
	gen byte normind=(naics4d==7225)
	sort pikn qtime
	export delimited pikn qtime firmnum y age cz normind using "$datadir/data2matlab.raw", replace
	tempfile data_`cz'
	save `data_`cz''

	*Clean up, so we will know if AKM worked
	cap rm "$datadir/datafrommatlab_cz.raw"

	*Run matlab to run the AKM model
	di "Starting the matlab call for CZ `cz'"
	! matlab -nodisplay -nosplash -batch ///
	 "firmAKM_callable('$datadir/data2matlab.raw', '$datadir/datafrommatlab')"
	di "Matlab call finished for CZ `cz'" 

	*Confirm that it worked
	import delimited using "$datadir/datafrommatlab_cz.raw", clear
	di v1[1]

	*Now read in statistics from Matlab -- R2, sample sizes, etc.;
	import delimited using "$datadir/datafrommatlab_stats.raw", clear
	gen cz = regexr("`cz'", "[czd]+","")
	destring cz, replace
	su reffirm, meanonly
	local ref=r(min)
	tempfile stats
	save `stats', replace

	*Read in the results
	import delimited using "$datadir/datafrommatlab_firm.raw", clear
	rename v1 firmnum
	rename v2 akm_firm
	tempfile firmfx
	save `firmfx'
	import delimited using "$datadir/datafrommatlab_person.raw", clear
	rename v1 pikn
	rename v2 akm_person
	tempfile personfx
	save `personfx'
	import delimited using "$datadir/datafrommatlab_xbr.raw", clear
	rename v1 pikn
	rename v2 qtime
	rename v3 xb
	rename v4 r
	tempfile xbr
	save `xbr'

	use "`data_`cz''", replace
	qui levelsof firmid if firmnum==`ref', clean
	local reffirmtxt =r(levels)
	merge m:1 pikn using `personfx', assert(1 3) nogen
	merge m:1 firmnum using `firmfx', assert(1 3) nogen
	merge 1:1 pikn qtime using `xbr', assert(1 3) nogen
	assert akm_person==. if akm_firm==.
	assert akm_person<. if akm_firm<.
	keep if akm_person<.
	keep pikn qtime firmid naics4d akm_person akm_firm xb r
	save "$dataind/AKMests_`cz'.dta", replace

	use `stats'
	gen reffirm_orig="`reffirmtxt'"
	if `first'!=1 append using "$dataind/AKMstats.dta"
	save "$dataind/AKMstats.dta", replace

	di "Finished loop for CZ `cz'"
	timer off 12
	qui timer list 12
	di "This loop took `r(t12)' seconds to complete"
	di "It finished on `c(current_date)' at `c(current_time)'"
	di ""
	di ""

	local first=0
}

log close
