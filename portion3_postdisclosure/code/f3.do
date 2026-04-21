cap log close
log using f3.log, text replace

import excel using "$disclosure1", sheet("2") cellrange(A3:E314) firstrow clear
set scheme plotplain

rename Industry4digitNAICS naics4
rename Numberofpersonquarters Npq_t2
tempfile t2
save `t2'


reg y_j psi_j [aw=Npq_t2] , robust
local b : display %4.2f _b[psi_j]
local se : display %4.2f _se[psi_j]
local r2: display %4.2f e(r2)
scatter y_j psi_j [aw=Npq_t2], msymbol(oh) || ///
  lfit y_j psi_j [aw=Npq_t2] || ///
  , xtitle("Estimated industry effect ({it:{&psi}})") ///
    ytitle("Mean log quarterly earnings in industry") ylabel(9 (0.5) 10.5) ///
    text(10.1 0.1 "Slope = `b' (`se')" "R{superscript:2} = `r2'", just(left)) ///
    legend(off) ///
    title("A. Industry differentials and average industry earnings",  pos(11) span) ///
    name(f3a, replace) 
	
reg alpha_j psi_j [aw=Npq_t2] , robust
local b : display %4.2f _b[psi_j]
local se : display %4.2f _se[psi_j]
local r2: display %4.2f e(r2)
scatter alpha_j psi_j [aw=Npq_t2], msymbol(oh) || ///
  lfit alpha_j psi_j [aw=Npq_t2] || ///
  , xtitle("Estimated industry effect ({it:{&psi}})") ///
    ytitle("Average person effect ({it:{&alpha}}) in industry") ylabel(9 (0.5) 10.5) ///
    text(10.1 0.1 "Slope = `b' (`se')" "R{superscript:2} = `r2'", just(left)) ///
    legend(off) ///
    title("B. Industry differentials and average worker effects", pos(11) span) ///
    name(f3b, replace) 

graph combine f3a f3b, xcommon ycommon ///
  /*  title("Figure 3. Industry wage differentials, mean wages, and average worker effects", span pos(11)) */ ///
  saving(${results}/f3, replace)
graph export ${results}/f3.png, replace

  
log close
