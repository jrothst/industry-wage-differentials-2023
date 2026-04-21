
cap log close
log using t2.log, text replace

* Prepare industry names
import excel using "${raw}/naics2017.xlsx", clear firstrow
keep naics title
* Fix a couple of aggregated industries
 replace naics="31" if naics=="31-33"
 replace naics="44" if naics=="44-45"
 replace naics="48" if naics=="48-49"
destring naics, force replace
keep if naics>=10 & naics<=99
rename naics naics2
tempfile names
save `names'

// Gather LEHD measures
use ${scratch}/ind_data, clear

*Normalize skill
 su alpha [aw=npq]
 gen skill=alpha-r(mean)
 
gen naics2=floor(naics/100)
replace naics2=31 if naics2==32 | naics2==33
replace naics2=44 if naics2==45
replace naics2=48 if naics2==49

collapse (mean) ybar skill psi (rawsum) size=npq [aw=npq], by(naics2)
su size, meanonly
gen share=size/r(sum)

list naics2 share ybar skill psi

tempfile list2 sds
save `list2'

collapse (sd) ybar skill psi [aw=size]
gen label="SD"
save `sds'
use `list2'
append using `sds'

tempfile lehd
save `lehd', replace

// Now gather ACS measures
use ${acsoutput}/industry_averages_2digit.dta, clear
collapse (sd) logwage ind_effects_adj skill_adj educ female [aw=wc]
gen label="SD"
tempfile acssds acslist
save `acssds'
use ${acsoutput}/industry_averages_2digit.dta, clear
append using `acssds'
save `acslist'

use `names'
merge 1:1 naics2 using `lehd', nogen
merge 1:1 naics2 label using `acslist', nogen
replace title=label if naics2==.
drop label
order naics2 title size share ybar skill psi 
export delimited using "${results}/t2.csv", replace
  
list 

log close
