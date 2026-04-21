cap log close
log using f5.log, text replace

import excel using "$disclosure3", sheet("3") cellrange(A6:F406) firstrow clear
set scheme plotplain

gen dpsi = d_y_m_xb - d_df_m_psij - d_akm_res

reg d_y_m_xb dpsi
local b : display %4.2f _b[dpsi]
local se : display %4.2f _se[dpsi]
local r2: display %4.2f e(r2)
scatter d_y_m_xb dpsi, msymbol(p) || function y=x, range(-0.5 0.5)  || , ///
 legend(off) scale(1.5)  ///
 text(0.3 -0.3 "Slope = `b' (`se')", size(vsmall)) ///
 title("A. Age-adjusted log earnings ({it:y-X{&theta}})", pos(11) span size(small)) name(dy, replace) 

reg d_akm_res dpsi
local b : display %4.2f _b[dpsi]
local se : display %4.2f _se[dpsi]
local r2: display %4.2f e(r2)
scatter d_akm_res dpsi, msymbol(p) || function y=x, range(-0.5 0.5) ///
 legend(off) scheme(plotplain) scale(1.5)  ///
 text(0.3 -0.3 "Slope = `b' (`se')", size(vsmall)) ///
 title("B. AKM residual ({it:{&epsilon}})", pos(11) span size(small)) name(de, replace)

reg d_df_m_psij dpsi
local b : display %4.2f _b[dpsi]
local se : display %4.2f _se[dpsi]
local r2: display %4.2f e(r2)
scatter d_df_m_psij dpsi, msymbol(p) || function y=x, range(-0.5 0.5) ///
 legend(off) scheme(plotplain) scale(1.5)  ///
 text(-0.4 0 "Slope = `b' (`se')", size(vsmall)) ///
 title("C. Firm hierarchy effect ({it:h})", pos(11) span size(small)) name(ddelta, replace)

 gen d_earn_adj=d_y_m_xb-d_df_m_psij
reg d_earn_adj dpsi
local b : display %4.2f _b[dpsi]
local se : display %4.2f _se[dpsi]
local r2: display %4.2f e(r2)
scatter d_earn_adj dpsi, msymbol(p) || function y=x, range(-0.5 0.5) ///
 legend(off) scheme(plotplain) scale(1.5)  ///
 text(0.3 -0.3 "Slope = `b' (`se')", size(vsmall)) ///
 title("D. Earnings net of firm hierarchy effect ({it:y-X{&theta}-h})", pos(11) span size(small)) name(dadjy, replace)
 
graph combine dy de ddelta dadjy, xcommon ycommon  ///
  /*  title("Figure 5. Changes in earnings components for between-industry movers", pos(11) span) */ ///
  b1title("Change in industry premium") l1title("Change in earnings component") ///
  note("Note: Slopes are unweighted. Dashed lines are 45-degree lines.") ///
  saving(${results}/f5.gph, replace)
graph export ${results}/f5.png, replace

log close
