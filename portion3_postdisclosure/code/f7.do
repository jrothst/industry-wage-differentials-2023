cap log close
log using f7.log, text replace

import excel using "$disclosure1", sheet("2") cellrange(A3:E314) firstrow clear
set scheme plotplain 
rename Industry4digitNAICS naics4
rename Numberofpersonquarters Npq_t2
tempfile t2
save `t2'

import excel using "${disclosure1}", sheet("3") cellrange(A3:D314) firstrow clear
rename Industry4digitNAICS naics4
rename Numberofpersonquarters Npq_t3
tempfile t3
save `t3'

use `t2'
merge 1:1 naics4 using `t3'

preserve	
qui sum alternative_psi_j_m7 if naics4 ==7225
replace alternative_psi_j_m7=alternative_psi_j_m7-r(mean)	
reg alternative_psi_j_m7 psi_j [aw=Npq_t2] , robust
local b : display %4.2f _b[psi_j]
local se : display %4.2f _se[psi_j]
local r2: display %4.2f e(r2)

scatter alternative_psi_j_m7 psi_j [aw=Npq_t2], msymbol(oh)  || ///
  lfit alternative_psi_j_m7 psi_j [aw=Npq_t2], range(-0.1 0.8) || ///
  function y=x, range(-0.1 0.8 ) || ///
  , ylabel(-0.1 (0.1) 0.8) xlabel(-0.1 (0.1) 0.8) legend(off) ///
    text(0.38 0.75 "Fitted line" "Slope = `b'" "R-sq = `r2'", just(left) size(small)) ///
	text(0.54 0.45 "45 degree line", size(small)) ///
	xtitle("Estimated industry effect" "based on ground-up firm-level AKM") ///
	ytitle("Estimated industry effect" "based on industry movers model") ///
	/*  title("Figure 7. Industry movers effects vs. ground-up from AKM (LEHD)", */ ///
	/*       pos(11) justification(left) span) */ ///
    saving(${results}/f7.gph, replace)
graph export ${results}/f7.png, replace

log close
