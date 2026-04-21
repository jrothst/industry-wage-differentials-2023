

cap log close
log using cw_cz_state.log, replace

use "${raw}/dorn/cw_czone_state.dta", clear
ren czone cz_1990

// 1990 to 2000 crosswalk
preserve
import delim using "${raw}/cz00_equiv.csv", clear encoding("utf-8")
tempfile cz00_equiv
save `cz00_equiv', replace
restore
merge 1:m cz_1990 using `cz00_equiv', keep(3) nogen

// Divisions
gen byte division = .
replace division = 1 if inlist(statefip,9,23,25,33,44,50)
replace division = 2 if inlist(statefip,34,36,42)
replace division = 3 if inlist(statefip,17,18,26,39,55)
replace division = 4 if inlist(statefip,19,20,27,29,31,38,46)
replace division = 5 if inlist(statefip,10,11,12,13,24,37,45,47,51,54)
replace division = 6 if inlist(statefip,1,21,28,47)
replace division = 7 if inlist(statefip,5,22,40,48)
replace division = 8 if inlist(statefip,4,8,16,30,32,35,49,56)
replace division = 9 if inlist(statefip,2,6,15,41,53)

// Regions
gen byte region = .
replace region = 1 if inlist(statefip,9,23,25,33,34,36,42,44,50)
replace region = 2 if inlist(statefip,17,18,19,20,26,27,29,31,38,39,46,55)
replace region = 3 if inlist(statefip,1,5,10,11,12,13,21,22,24,28,37,40,45,47,48,51,54)
replace region = 4 if inlist(statefip,2,4,6,8,15,16,30,32,35,41,49,53,56)

save "${tocensus}/cw_cz_state.dta", replace

// Top 50 region crosswalk
drop cz_2000
duplicates drop
ren cz_1990 cz
keep if inlist(cz,900,1701,2000,5600,6700,7000,7100,7400,7600,9100,11302,11304,11600,12200,12701,14200,15200,15900,16300,18000,19400,19600,19700,20401,20500,20600,20901,21501,24100,24300,24701,28900,29502,31201,31301,32000,33000,33100,33803,35001,36100,37200,37400,37500,37800,37901,38000,38300,38801,39400)
save "${tocensus}/cw_cz_state_top50.dta", replace
