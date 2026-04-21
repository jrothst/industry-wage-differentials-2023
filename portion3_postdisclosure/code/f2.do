
cap log close
log using f2.log, text replace


use "${scratch}/ind_data", clear

set scheme cleanplots



su psi, meanonly

local min=r(min)
local max=r(max)
gen bin=floor(psi*10)/10 + 0.05
gen naics1=floor(naics/1000)
tab naics1, gen(naics1d)

su npq, meanonly
gen share=npq/r(sum)
graph bar (sum) share, ///
      over(naics1, relabel(1 "Agriculture" 2 "Mining/Util./Cons." 3 "Manufacturing" ///
	                       4 "Trade/Transport" 5 "FIRE/Admin" 6 "Educ/Health" ///
						   7 "Arts/Ent./Accom." 8 "Other Svcs" 9 "Pub. Admin") ///
				   descending) ///
	  over(bin, relabel(1 "-0.1-0" 2 "0-0.1" 3 "0.1-0.2" 4 "0.2-0.3" 5 "0.3-0.4" ///
	                    6 "0.4-0.5" 7 "0.5-0.6" 8 "0.6-0.7" 9 "0.7-0.8")) asyvars stack  ///
	  ytitle("Share of workers")  ///
	  b1title("Industry wage premium ({it:{&psi}})") ///
	  /* title("Figure 2. Histogram of estimated 4-digit industry wage premiums", span pos(11)) */ ///
	  saving(${results}/f2.gph, replace)
graph export ${results}/f2.png, replace
	  
log close

