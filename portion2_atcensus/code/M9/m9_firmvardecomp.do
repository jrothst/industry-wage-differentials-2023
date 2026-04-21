
/*----------------------------------------------------------------------------*\

	Industry Project
	Program to estimate a variance decomposition of AKM firm effects from M9 into
	CZ, industry, and CZ-by-industry components
	To be run after "m9_cjmeans.do" 
	Loops over 50+9 CZs, 100% sample

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
// Loop over all CZs in 100% sample
//------------------------------------------------------------------------------
/*foreach file in mig5_pikqtime_1018_czd1.dta mig5_pikqtime_1018_czd2.dta {*/
local first=1
local files: dir "$datadir" files "mig5_pikqtime_1018_*.dta"
foreach file in `files' {
  di "Starting file `file'"
  local cz = regexr("`file'", "mig5_pikqtime_1018_", "")
  local cz = regexr("`cz'", ".dta", "")
  di "`cz'"
  use pikn qtime y naics4d cz using "$datadir/`file'", clear
  merge 1:1 pikn qtime using "$dataind/AKMests_`cz'", assert(1 3) keep(3) nogen
  sort firmid pikn qtime
  by firmid: egen f_alpha=mean(akm_person)
  by firmid: egen f_psi=mean(akm_firm)
  by firmid: egen f_ybar=mean(y)
  if regexm("`cz'", "d") {
  	drop cz
  	gen cz = regexr("`cz'", "[czd]+", "")
	destring cz, replace
  }
  merge m:1 cz naics4d using "$dataind/AKMests_jc.dta", assert(2 3) keep(3) keepusing(alpha psi ybar_akmsamp)
  gen r1=y-akm_person-akm_firm
  gen r2=akm_firm-psi
  gen fresid_alpha=f_alpha-alpha
  gen iresid_alpha=akm_person-f_alpha
  di "Summary statistics for CZ `cz'"
  su y r1 r2 psi akm_person iresid_alpha fresid_alpha alpha
  //Make a firm-level dataset
  rename ybar_akmsamp ybar_jc
  rename f_ybar ybar_fjc
  collapse (mean) akm_firm akm_person alpha psi ybar_fjc ybar_jc (count) N_fjc=y, by(cz naics4d firmid)
  tempfile cjmean_`cz'
  save `cjmean_`cz''
  if `first'==1 local czlist `cz'
  else local czlist `czlist' `cz'
  local first=0
}

local first=1
foreach c of local czlist {
  if `first'==1 use `cjmean_`c'', clear
  else append using `cjmean_`c''
  local first=0
}

destring naics4d, replace
di "ANOVA for firm effects and firm-mean person effects, by CZ/industry"
anova akm_firm cz naics4d [aw=N_fjc]
anova akm_person cz naics4d [aw=N_fjc]
anova ybar_fjc cz naics4d [aw=N_fjc]
save "$dataind/AKMests_fjc.dta", replace

