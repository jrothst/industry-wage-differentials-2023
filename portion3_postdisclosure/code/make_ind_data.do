*Makes a Stata data set of main industry estimates

cap log close
log using make_ind_data.log, text replace

* Prepare industry names
import excel using "${raw}/naics2017.xlsx", clear firstrow
keep naics title
destring naics, force replace
keep if naics>=1000 & naics<=9999
tempfile names
save `names'

import excel using "${disclosure1}", clear sheet(2) firstrow cellrange(A3:E314)
rename Industry4digitNAICS naics
rename y_j ybar
rename alpha_j alpha
rename psi_j psi
rename Numberofpersonquarters npq

merge 1:1 naics using `names', keep(1 3) nogen

save ${scratch}/ind_data, replace




