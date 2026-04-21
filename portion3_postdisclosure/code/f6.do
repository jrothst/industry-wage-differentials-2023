
cap log close
log using f6.log, replace text

use ${scratch}/merge_acs_lehd, clear
*import excel using lehd_acs_bynaics2.xlsx, sheet(Data) clear firstrow
set scheme plotplain

 //Industry effects should be .038937 on average in 72 (based on LEHD)
 gen naics2=floor(naics/100)
 su ind_effects_m3 if naics2==72 [aw=wcount]
 gen ind_effects_adj=ind_effects_m3-r(mean) + 0.038937

reg ind_effects_adj psi [aw=npq], robust
local b : display %4.2f _b[psi]
local se : display %4.2f _se[psi]
local r2: display %4.2f e(r2)

su psi, meanonly
local min=r(min)
local max=r(max)

scatter ind_effects_adj psi [aw=npq], msymbol(oh)  || ///
  lfit ind_effects_adj psi [aw=npq], range(-0.1 0.7) || ///
  function y=x, range(-0.1 0.8 ) || ///
  , ylabel(-0.1 (0.1) 0.8) xlabel(-0.1 (0.1) 0.8) legend(off) ///
    text(0.8 0.54 "Fitted line" "Slope = `b' (`se')"  "R-sq = `r2'", just(left) size(small)) ///
	text(0.54 0.63 "45 degree line", size(small)) ///
	xtitle("Estimated industry effect" "based on ground-up firm-level AKM") ///
	ytitle("Estimated industry effect" "based on cross-sectional model") ///
	/*  title("Figure 6. Cross-sectional industry effects (ACS) vs. ground-up from AKM (LEHD)", */ ///
	/*        pos(11) justification(left) span) */ ///
    saving(${results}/f6.gph, replace)
graph export ${results}/f6.png, replace
   
log close 
