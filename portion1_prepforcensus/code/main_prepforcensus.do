cap log close mainlog
log using main_prepforcensus.log, replace text name(mainlog)
clear *

// Which parts to run?
local dononacs  1 // Prepare non-ACS data
local doacsstep1  0 // Prepare PUMA-CZ crosswalks
local doacsstep2a 0 // Prepare ACS raw files - get into stata (v slow)
local doacsstep2b 1 // Prepare ACS raw files - preparation in stata (slow)
local doacsstep2c 1 // Prepare ACS raw files - preparation in stata (slow)
local doacsstep3 1 //  Estimate industry effects and create industry-level collapsed files
local doacsstep4 1 // Final preparation - 2 and 3-digit aggregates, etc.

creturn list
global home "~/replication/industries/portion1_prepforcensus" // change to reflect local settings
global code "${home}/code"
global acscode "${code}/acs"
global nonacscode "${code}/nonacs"
global raw "${home}/origdata"
global acsraw "${raw}/rawacs"
global tocensus "${home}/tocensus"
global scratch "${home}/intermediate" // For intermediate files that we might want
global tmp "${home}/tmp" // for large, temporary files that can be wiped.
// On our system, this is a symbolic link to a directory on a temp drive.
// Note that the extract??.sas programs in step 2, and the household.sas program in
// step 5, hard-code its (relative) location, so may need to be adjusted if it is moved.

/*  
Uses Stata packages:
cleanplots:  <net install cleanplots, from(http://fmwww.bc.edu/RePEc/bocode/c)>
outreg2.ado: <net install outreg2, from(http://fmwww.bc.edu/RePEc/bocode/o)>
*/ 
which outreg2

if `dononacs'==1 {
  cd $nonacscode
  do cz_unionization.do
  do cz_minwage
}

if `doacsstep1'==1 {
  cd ${acscode}
  do puma2000_prep.do
  do puma2010_prep.do
  do cw_cz_state.do
}

if `doacsstep2a'==1 {
  cd ${acscode}
  do extractacs.do // This is slow
  drop _all
}

if `doacsstep2b'==1 {
  cd ${acscode}
  *Renaming, recoding, and merging CZs
  do readacs.do
  *Check sample sizes
  d using ${scratch}/simple2010
  assert r(N)==1941443
  d using ${scratch}/simple2018
  assert r(N)==2011848
}

if `doacsstep2c'==1 {
  cd ${acscode}
  *Cleaning, assigning to CZs, NAICS; creating key variables for regressions
  do rank_revised_extravars.do
  drop _all
}  

if `doacsstep3'==1 {
  cd ${acscode}
  do phi_acs.do
  do phi_cz_alt-wage.do
}

if `doacsstep4'==1 {
  cd ${acscode}
  do industry_averages.do
}
// Change back to code home directory
cd $code

log close mainlog
