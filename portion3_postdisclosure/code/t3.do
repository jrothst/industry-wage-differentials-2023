
cap log close
log using t3.log, text replace

* Prepare industry names
import excel using "${raw}/naics2017.xlsx", clear firstrow
keep naics title
destring naics, force replace
keep if naics>=100 & naics<=999
keep if naics>=310 & naics<340
rename naics naics3
tempfile names
save `names'


// Gather LEHD measures
use ${scratch}/ind_data, clear

*Normalize skill
 su alpha [aw=npq]
 gen skill=alpha-r(mean)
 
 keep if naics>=3100 & naics<3400
gen naics3=floor(naics/10)
replace naics3=311 if naics3==312
replace naics3=313 if naics3==314
replace naics3=315 if naics3==316


collapse (mean) ybar skill psi (rawsum) size=npq [aw=npq], by(naics3)
su size, meanonly
gen share=size/r(sum)

list naics3 share ybar skill psi

tempfile list3 sds
save `list3'

collapse (sd) ybar skill psi [aw=size]
gen label="SD"
save `sds'
use `list3'
append using `sds'

tempfile lehd
save `lehd', replace

// Now gather ACS measures
use ${acsoutput}/industry_averages_3digit.dta, clear
collapse (sd) logwage ind_effects_adj skill_adj educ female [aw=wc]
gen label="SD"
tempfile acssds acslist
save `acssds'
use ${acsoutput}/industry_averages_3digit.dta, clear
append using `acssds'
save `acslist'

use `names'
merge 1:1 naics3 using `lehd', nogen
merge 1:1 naics3 label using `acslist', nogen
drop if size==. & wc==. & label==""
replace title=label if naics3==.
drop label
order naics3 title size share ybar skill psi 

export delimited using "${results}/t3.csv", replace
  
list 

log close
