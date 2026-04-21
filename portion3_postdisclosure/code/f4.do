cap log close
log using f4.log, text replace


import excel using "$disclosure3", sheet("2") cellrange(A5:F165) firstrow clear
set scheme cleanplots
rename Quartileoforigin origin
rename Quartileofdestination destination
rename Eventtime eventtime

sort origin destination eventtime
line y_m_xb eventtime if origin==1 & destination==1, lstyle(p1) || ///
line y_m_xb eventtime if origin==1 & destination==2, lstyle(p2) || ///
line y_m_xb eventtime if origin==1 & destination==3, lstyle(p3) || ///
line y_m_xb eventtime if origin==1 & destination==4, lstyle(p4) || ///
line y_m_xb eventtime if origin==4 & destination==1, lstyle(p1) lpattern(dash) || ///
line y_m_xb eventtime if origin==4 & destination==2, lstyle(p2) lpattern(dash) || ///
line y_m_xb eventtime if origin==4 & destination==3, lstyle(p3) lpattern(dash) || ///
line y_m_xb eventtime if origin==4 & destination==4, lstyle(p4) lpattern(dash) || ///
 , legend(order(4 "1-4" 8 "4-4" 3 "1-3" 7 "4-3" 2 "1-2" 6 "4-2" 1 "1-1" 5 "4-1" ) ///
          cols(2) ring(0) pos(12) title("Origin-destination quartiles") region(lstyle(foreground)) ) ///
   ylabel(9.4 9.8 10.2) xlabel(-5 (1) 4) ///
   xline(0) ytitle("Log earnings") title("A. Log earnings (age adjusted)", pos(11) span) ///
   name(y_legend, replace) 

   
sort origin destination eventtime
line y_m_xb eventtime if origin==1 & destination==1, lstyle(p1) || ///
line y_m_xb eventtime if origin==1 & destination==2, lstyle(p2) || ///
line y_m_xb eventtime if origin==1 & destination==3, lstyle(p3) || ///
line y_m_xb eventtime if origin==1 & destination==4, lstyle(p4) || ///
line y_m_xb eventtime if origin==4 & destination==1, lstyle(p1) lpattern(dash) || ///
line y_m_xb eventtime if origin==4 & destination==2, lstyle(p2) lpattern(dash) || ///
line y_m_xb eventtime if origin==4 & destination==3, lstyle(p3) lpattern(dash) || ///
line y_m_xb eventtime if origin==4 & destination==4, lstyle(p4) lpattern(dash) || ///
 , legend(off) ///
   xline(0) ytitle("Age-adjusted log earnings") title("A. Log earnings (age adjusted)", pos(11) span) ///
   name(y, replace)
   
line akm_res eventtime if origin==1 & destination==1, lstyle(p1) || ///
line akm_res eventtime if origin==1 & destination==2, lstyle(p2) || ///
line akm_res eventtime if origin==1 & destination==3, lstyle(p3) || ///
line akm_res eventtime if origin==1 & destination==4, lstyle(p4) || ///
line akm_res eventtime if origin==4 & destination==1, lstyle(p1) lpattern(dash) || ///
line akm_res eventtime if origin==4 & destination==2, lstyle(p2) lpattern(dash) || ///
line akm_res eventtime if origin==4 & destination==3, lstyle(p3) lpattern(dash) || ///
line akm_res eventtime if origin==4 & destination==4, lstyle(p4) lpattern(dash) || ///
 , legend(off) ///
   ylabel(-0.06 -0.03 0 0.03) xlabel(-5 (1) 4) ///
   xline(0) ytitle("AKM residual") title("B. AKM residual ({it:{&epsilon}})", pos(11) span) ///
   name(e, replace)    

line df_m_psij eventtime if origin==1 & destination==1, lstyle(p1) || ///
line df_m_psij eventtime if origin==1 & destination==2, lstyle(p2) || ///
line df_m_psij eventtime if origin==1 & destination==3, lstyle(p3) || ///
line df_m_psij eventtime if origin==1 & destination==4, lstyle(p4) || ///
line df_m_psij eventtime if origin==4 & destination==1, lstyle(p1) lpattern(dash) || ///
line df_m_psij eventtime if origin==4 & destination==2, lstyle(p2) lpattern(dash) || ///
line df_m_psij eventtime if origin==4 & destination==3, lstyle(p3) lpattern(dash) || ///
line df_m_psij eventtime if origin==4 & destination==4, lstyle(p4) lpattern(dash) || ///
 , legend(off) ///
   xlabel(-5 (1) 4) ///
   xline(0) ytitle("Firm hierarchy effect") title("C. Firm hierarchy effect ({it:h})", pos(11) span) ///
   name(delta, replace)    

grc1leg2 y_legend e delta , xcommon ///
  /* title("Figure 4. Event studies for workers moving from top- and bottom-quartile industries", pos(11) span) */ ///
  legendfrom(y_legend) ring(0) pos(4) lxoffset(-8) lyoffset(13) xtob1title ///  
  saving(${results}/f4.gph, replace)
graph export ${results}/f4.png, replace
   
log close
