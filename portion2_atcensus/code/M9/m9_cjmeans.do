
/*----------------------------------------------------------------------------*\

	Industry Project
	Program to loop over CZs, read in the firm AKM estimates, and compute CZ-industry averages

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

/*foreach file in mig5_pikqtime_1018_cz900.dta mig5_pikqtime_1018_cz1701.dta {*/
local first=1
local files: dir "$datadir" files "mig5_pikqtime_1018_*.dta"
foreach file in `files' {
  di "Starting file `file'"
  local cz = regexr("`file'", "mig5_pikqtime_1018_", "")
  local cz = regexr("`cz'", ".dta", "")
  di "`cz'"
  use pikn qtime y naics4d cz using "$datadir/`file'", clear
  merge 1:1 pikn qtime using "$dataind/AKMests_`cz'", assert(1 3) nogen  
  gen y_akmsamp=y if akm_person<.
  gen Npq=1
  gen Npq_akmsamp=(akm_person<.)
  collapse (mean) y y_akmsamp akm_person akm_firm (sum) Npq Npq_akmsamp, by(naics4d)
  gen cz = regexr("`cz'", "[a-z]+", "")
  destring cz, replace
  tempfile cjmean_`cz'
  save `cjmean_`cz'', replace
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
rename akm_person alpha
rename akm_firm psi
rename y ybar
rename y_akmsamp ybar_akmsamp
order cz naics4d ybar ybar_akmsamp alpha psi Npq Npq_akmsamp
save "$dataind/AKMests_jc.dta", replace

