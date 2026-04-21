// Data come from Ben Zipperer's github, https://github.com/benzipperer/historicalminwage/releases/tag/v1.3.0

// Cite:
//
//  Vaghul, Kavya and Ben Zipperer. 2021. "Historical State and Sub-state 
//  Minimum Wages." Version 1.3.0, 
//  https://github.com/benzipperer/historicalminwage/releases/tag/v1.3.0.


cap log close
log using cz_minwage.log, replace

use "${raw}/minwages/mw_substate_stata/mw_substate_daily", clear
egen oneper=tag(statefips locality)
sort statefips

gen cz59=38300 if locality=="Los Angeles" | locality=="Los Angeles County"
replace cz59=37800 if locality=="San Francisco"
replace cz59=37500 if locality=="San Jose"
replace cz59=38000 if locality=="San Diego"
replace cz59=28900 if locality=="Denver"
replace cz59=11304 if locality=="Washington" & statename=="District of Columbia"
replace cz59=24300 if locality=="Chicago" | locality=="Cook County"
replace cz59=21501 if locality=="Minneapolis"
replace cz59=19400 if locality=="New York City"
replace cz59=38801 if locality=="Portland" & statename=="Oregon"
replace cz59=39400 if locality=="Seattle"
list statename locality cz59 if oneper==1
keep if cz59<.
tab locality
sort cz59 locality date
by cz59 locality: assert _N==6575
collapse (max) mw, by(cz59 date)
keep if date>=mdy(1,1,2010) & date<=mdy(12,31,2018)
collapse (mean) mw, by(cz59)
tempfile czlevel
save `czlevel'

// Now we need to pull state level MWs
use "${raw}/minwages/mw_state_stata/mw_state_daily", clear
keep if date>=mdy(1,1,2010) & date<=mdy(12,31,2018)
collapse (mean) mw, by(statefips statename)
tempfile statelevel
save `statelevel'

// For CZs without their own MWs, we need to average the relevant states. 
// For that, we need county-CZ crosswalk, with pops.


// Read in CZ definitions
import excel using "${raw}/cz-codes-1990.xls", clear firstrow sheet(CZLMA903) // County-CZ crosswalk
rename NameoflargestplaceinCommuti CZname
destring CountyFIPSCode, gen(fips) force
drop CountyFIPSCode
*keep fips CZ90 CountyName Population1990
replace fips=12086 if fips==12025 // Miami-Dade
replace fips=02232 if fips==02231 // Skagway-Yakutat-Angoon, AK
destring CZ90, gen(cz)
drop CZ90
tempfile CZs
save `CZs'
// And get CZ names
 sort cz fips
 isid cz fips
 by cz: keep if _n==1
 keep cz CZname
 tempfile CZnames
 save `CZnames'

// Read in top 50 CZs
use ${raw}/cw_cz_division_nottop50, clear
keep cz division top50
gen cz59=cz if top50==1
replace cz59=division if top50==0
merge 1:1 cz using `CZnames', keep(1 3)
assert _merge==3 if top50==1
drop _merge
replace CZname="Rest of division"+string(division) if top50!=1
sort cz59 cz
by cz59: assert _n==1 if top50==1
*by cz59: drop if _n>1
tempfile topczs
save `topczs'


merge 1:m cz using `CZs', assert(2 3) nogen keepusing(fips cz Population1990)
gen stfips=floor(fips/1000)
// Alaska
 replace cz59=9 if cz59==. & stfips==2
// North Dakota -- note that one county is in an MT MSA so gets the wrong division
 replace cz59=4 if cz59==. & stfips==38 & (cz59<10 | cz59==.)
// A bunch of other CZs that have to be done by hand 
 replace cz59=8 if cz59==. & inlist(cz, 28402, 28501) // stfips 8-CO
 replace cz59=4 if cz59==. & inlist(cz,29002,29008) // stfips 20-KS
 replace cz59=8 if cz59==. & inlist(cz,26402,26405,26407,34306,34309) // State 30-MT
 replace cz59=4 if cz59==. & inlist(cz,28303,28606,29102) // state 31-NE
 replace cz59=8 if cz59==. & cz==37902 // state 32-NV
 replace cz59=8 if cz59==. & inlist(cz,30702,34804) // state 35-NM
 replace cz59=7 if cz59==. & cz==33603 // state 40-OK
 replace cz59=9 if cz59==. & cz==39204 // state 41-OR
 replace cz59=4 if cz59==. & inlist(cz,26404, 26603,27010,27012,27604) // state 46-SD
 replace cz59=7 if cz59==. & inlist(cz,30605,30905,30907,31304,32502,32603) // state 48-TX
 replace cz59=8 if cz59==. & cz==35905 // state 49-UT
 replace cz59=8 if cz59==. & cz==34604 // state 56-WY
 replace cz59=4 if cz59==. & cz==26401 // split between 30 and 46 (MT, SD)- give to SD for 
assert cz59<.
gen statefips=floor(fips/1000)
merge m:1 statefips using `statelevel', assert(2 3) keep(3) nogen
rename mw st_mw
merge m:1 cz59 using `czlevel', assert(1 3) nogen
replace mw=st_mw if mw==.
collapse (mean) mw [aw=Population1990], by(cz59)
tempfile mw
save `mw'
//And grab CZ names
 use `topczs'
 sort cz59 cz
 by cz59: assert CZname==CZname[1]
 by cz59: keep if _n==1
 keep cz59 CZname
 merge 1:1 cz59 using `mw', assert(3) nogen
save "${tocensus}/cz_minwage.dta", replace

log close

