cap log close
log using appfig1.log, text replace

clear

*import excel using "../industryeffects.xlsx", clear firstrow sheet("naics3-adj")
use ${scratch}/ind_data, clear
*import excel using ../f6/lehd_acs_bynaics2.xlsx, sheet(Data) clear firstrow
set scheme plotplain
gen naics3=floor(naics/10)
keep if naics3>=300 & naics3<=400
replace naics3=naics3-1 if inlist(naics3, 312, 314, 316)
collapse (mean) ybar alpha psi (rawsum) npq [fw=npq], by(naics3)
tempfile psis
save `psis'

import excel using "${raw}/Yehetal markdowns.xlsx", clear firstrow
drop A
rename NAICSA naics3
drop if naics3==.
rename T1C1 t1c1
rename T1C2 t1c2
destring t?c?, force replace

merge 1:1 naics3 using `psis', assert(3) nogen

set scheme plotplain

gen logmarkdown=ln(1/t1c1)

reg psi logmarkdown , robust
local b : display %4.2f _b[logmarkdown]
local se : display %4.2f _se[logmarkdown]
local r2: display %4.2f e(r2)
scatter psi logmarkdown ,  msymbol(o) || ///
lfit psi logmarkdown , range(-1 0) ||, ///
  xlabel(-1 (0.2) 0) ylabel(0 (0.1) 0.7) legend(off) ///
  xtitle("Log of median industry markdown (Yeh et al., 2023)") ///
  ytitle("Industry wage premium") ///
  text(0.35 -0.73 "Fitted line" "Slope = `b' (`se')" "R-sq = `r2'", justification(left) size(small)) ///
  /*  title("Appendix Figure 1. Relationships between markdowns and industry pay premiums" "(3-digit manufacturing)", */ ///
  /*        span pos(11) justification(left)) */ ///
  saving(${results}/appfig1, replace)
graph export ${results}/appfig1.png, replace

  
log close
