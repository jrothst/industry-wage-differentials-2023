*Construct industry averages at the 2- and 3-digit level

cap log close
log using industry_averages.log, replace

use ${scratch}/indeffects_naicsp, clear

gen r=logwage-skill_m3-ind_effects_m3
sum r


sum
gen c=1
sum [w=wcount]

gen naics2=substr(naicsp,1,2)
replace naics2="33" if naics2=="3M"

tab naics2 [w=wcount]

replace naics2="31" if naics2=="32"
replace naics2="31" if naics2=="33"
replace naics2="44" if naics2=="45"
replace naics2="48" if naics2=="49"

tab naics2 [w=wcount]
assert real(naics2)<.

gen naics3=substr(naicsp,1,3)
gen mfg=0
replace mfg=1 if naics2=="31"
replace mfg=1 if naics2=="32"
replace mfg=1 if naics2=="33"
replace naics3="339" if naics3=="3MS"
replace naics3="311" if naics3=="312"
replace naics3="313" if naics3=="314"
replace naics3="315" if naics3=="316"
tab naics3 if mfg==1

destring naics2, replace

*Normalize
 //Industry effects should be .038937 on average in 72 (based on LEHD)
 su ind_effects_m3 if naics2==72 [aw=wcount]
 gen ind_effects_adj=ind_effects_m3-r(mean) + 0.038937
 //Person effects should be zero on average
 su skill_m3 [aw=wcount]
 gen skill_adj=skill_m3-r(mean)
 
tempfile cleaned
save `cleaned'


// Make a 2-digit file
collapse (mean) logwage educ female ind_effects_adj skill_adj (sum) wc=c [pw=wcount], by(naics2)
sum [w=wc]
list naics2 wc logwage educ female ind_effects_adj skill_adj
save ${scratch}/industry_averages_2digit, replace


// Make a 3-digit file
use `cleaned', clear
sum [w=wcount]
*now select only MFG
keep if mfg==1
assert real(naics3)<.
destring naics3, replace
drop naics2 mfg
sum [w=wcount]

collapse (mean) logwage educ female ind_effects_adj skill_adj (sum) wc=c [pw=wcount], by(naics3)
sum [w=wc]
list naics3 wc logwage educ female ind_effects_adj skill_adj

save ${scratch}/industry_averages_3digit, replace

log close

