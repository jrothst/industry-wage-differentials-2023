cap log close
log using t4.log, text replace

clear *
estimates clear

* Table to relate national-level education, alphabar, ybar, psi
local disclosure "Yi_1_tabs_T13T26.xlsx"

*Two samples -- one is LEHD only, the other is linked
*Sample 1
import excel using "${disclosure1}", sheet("2") cellrange(A3:E314) firstrow clear
rename Industry4digitNAICS naics4
rename Numberofpersonquarters Npq_t2
tempfile lehdonly
save `lehdonly'

/*  
use "ind_data", clear
merge 1:1 naics using "../acs/xwalk/naics_chars", assert(3) nogen
gen naics1=floor(naics/1000)
tab naics1, gen(naics1d)
collapse (mean) ybar alpha psi logwage-wcount naics1d* (rawsum) npq [aw=npq], by(naicsp)
*/
use ${scratch}/merge_acs_lehd, clear
tempfile lehdacs
save `lehdacs'

use `lehdonly'
eststo: reg alpha_j y_j [aw=Npq_t2], robust
eststo: reg psi_j y_j [aw=Npq_t2], robust
eststo: reg alpha_j psi_j [aw=Npq_t2], robust

use `lehdacs', clear
assert educ<. 
rename psi psi_j
eststo: reg alpha psi_j [aw=npq], robust
eststo: reg alpha skill_m3 [aw=npq], robust
predict alphahat, xb
predict alphar, r
eststo: reg alpha psi_j skill_m3 [aw=npq], robust
eststo: reg alphahat psi_j [aw=npq], robust
eststo: reg alphar psi_j [aw=npq], robust

/* 
eststo: reg alpha educ [aw=npq], robust
predict alphahat, xb
predict alphar, r
eststo: reg alpha psi_j educ [aw=npq], robust
eststo: reg alphahat psi_j [aw=npq], robust
eststo: reg alphar psi_j [aw=npq], robust
*/
 
esttab, b(4) se nostar r2
esttab using ${results}/t4.csv, b(4) se nostar r2 replace

estimates clear
eststo: reg ind_effects_m1 psi_j [aw=npq], robust
eststo: reg ind_effects_m2 psi_j [aw=npq], robust
eststo: reg ind_effects_m3 psi_j [aw=npq], robust
// without robust to get adjusted r2
eststo: reg ind_effects_m1 psi_j [aw=npq]
eststo: reg ind_effects_m2 psi_j [aw=npq]
eststo: reg ind_effects_m3 psi_j [aw=npq]
esttab, b(4) se nostar r2 ar2

log close
