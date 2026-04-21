cap log close
log using apptab2.log, text replace

use ${scratch}/ind_data, clear

su npq, meanonly
gen share=npq/r(sum)

// Normalize
 su alpha [aw=npq]
 gen alpha_adj=alpha-r(mean)

gen order=naics
tempfile list mean sd
save `list'

collapse (mean) ybar alpha psi [aw=npq]
gen title="Mean" 
gen order=0
rename alpha alpha_adj
save `mean'
use `list'
collapse (sd) ybar alpha_adj psi [aw=npq]
gen title="SD" 
gen order=1
save `sd'

use `mean'
append using `sd'
append using `list'
list naics title ybar alpha_adj psi share in 1/10
keep naics title ybar alpha_adj psi share

export delimited using "${results}/apptab2.csv", replace

log close

