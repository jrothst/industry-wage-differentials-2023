
cap log close
log using f89.log, text replace

*local disclosure "../output_asof20220908.xlsx"
import excel using "${disclosure1}", sheet("2") cellrange(A3:E314) firstrow clear
set scheme plotplain
rename Industry4digitNAICS naics4
rename Numberofpersonquarters Npq_t2
rename psi_j psi_2
rename alpha_j alpha_2
tempfile t2
save `t2'

import excel using "${disclosure1}", sheet("4") cellrange(A3:E625) firstrow clear
rename Industry4digitNAICS naics4
rename Numberofpersonquarters Npq_t4
rename psi_j psi_4
rename alpha_j alpha_4
tempfile t4
save `t4'

use `t2'
merge 1:m naics4 using `t4'

reg alpha_4 psi_2 if Educationsubgroup=="L" [aw=Npq_t4], robust
local b0 : display %4.2f _b[psi_2]
local se0 : display %4.2f _se[psi_2]
local r20: display %4.2f e(r2)
reg alpha_4 psi_2 if Educationsubgroup=="H" [aw=Npq_t4], robust
local b1 : display %4.2f _b[psi_2]
local se1 : display %4.2f _se[psi_2]
local r21: display %4.2f e(r2)
scatter alpha_4 psi_2 if Educationsubgroup=="L" [aw=Npq_t4], ///
    scale(1.5) mlwidth(*0.67) msymbol(oh) || ///
  lfit alpha_4 psi_2 if Educationsubgroup=="L" [aw=Npq_t4], || ///
  , xtitle("") ytitle("") ylabel(9 (0.5) 10.5) ///
    text(10 0.2 "Slope = `b0' (`se0')" "R{sup:2} = `r20'", just(left) size(small)) ///
    legend(off)  ///
    title("A. Non-college", pos(11) span size(small)) ///
    name(ed0, replace) 
scatter alpha_4 psi_2 if Educationsubgroup=="H" [aw=Npq_t4], ///
    scale(1.5) mlwidth(*0.67) msymbol(oh) || ///
 lfit alpha_4 psi_2 if Educationsubgroup=="H" [aw=Npq_t4] || ///
  , xtitle("") ytitle("") ylabel(9 (0.5) 10.5) ///
    text(9.1 0.6 "Slope = `b1' (`se1')" "R{sup:2} = `r21'", just(left) size(small)) ///
    legend(off) ///
    title("B. College", pos(11) span size(small)) ///
    name(ed1, replace) 

graph combine ed0 ed1, xcommon ycommon ///
  b1title("Industry differential") l1title("Average worker effect") ///
  /* title("Figure 9. Average worker effects by education and industry", pos(11) span) */ ///
  saving(${results}/f9.gph, replace)
graph export ${results}/f9.png, replace

reg psi_4 psi_2 if Educationsubgroup=="L" [aw=Npq_t4], robust
local b0 : display %4.2f _b[psi_2]
local se0 : display %4.2f _se[psi_2]
local r20: display %4.2f e(r2)
reg psi_4 psi_2 if Educationsubgroup=="H" [aw=Npq_t4], robust
local b1 : display %4.2f _b[psi_2]
local se1 : display %4.2f _se[psi_2]
local r21: display %4.2f e(r2)
scatter psi_4 psi_2 if Educationsubgroup=="L" [aw=Npq_t4], ///
    scale(1.5) mlwidth(*0.67) msymbol(oh) || ///
  lfit psi_4 psi_2 if Educationsubgroup=="L" [aw=Npq_t4], || ///
  , xtitle("") ytitle("")  ///
    text(0 0.5 "Slope = `b0' (`se0')" "R{sup:2} = `r20'", just(left) size(small)) ///
    legend(off)  ///
    title("A. Non-college", pos(11) span size(small)) ///
    name(ed0, replace) 
scatter psi_4 psi_2 if Educationsubgroup=="H" [aw=Npq_t4], ///
    scale(1.5) mlwidth(*0.67) msymbol(oh) || ///
 lfit psi_4 psi_2 if Educationsubgroup=="H" [aw=Npq_t4] || ///
  , xtitle("") ytitle("")  ///
    text(0 0.6 "Slope = `b1' (`se1')" "R{sup:2} = `r21'", just(left) size(small)) ///
    legend(off) ///
    title("B. College", pos(11) span size(small)) ///
    name(ed1, replace) 

graph combine ed0 ed1, xcommon ycommon ///
  b1title("Industry differential (pooled)") l1title("Industry differential (by education)") ///
  /* title("Figure 8. Pooled vs. separate estimates of industry premiums by education", pos(11) span) */ ///
  saving(${results}/f8.gph, replace)
graph export ${results}/f8.png, replace

log close

