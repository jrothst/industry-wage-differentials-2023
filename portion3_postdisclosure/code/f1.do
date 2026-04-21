
cap log close
log using f1.log, text replace

*use "../acs/xwalk/naics_chars", clear
*use "indeffs.dta", clear
use ${acsoutput}/indeffects_naicsp

set scheme plotplain 
*set scheme cleanplots

reg logwage educ [aw=wcount], robust
local b : display %5.3f _b[educ]
local se : display %5.3f _se[educ]
local r2: display %4.2f e(r2)

scatter logwage educ [aw=wcount], msymbol(oh) scheme(plotplain) || ///
  lfit logwage educ [aw=wcount] || ///
  , text(3.75 12 "Slope = `b' (`se')" "R{superscript:2} = `r2'", just(left)) ///
    xtitle("Mean Education of Workers in Industry") ///
	ytitle("Mean Log Hourly Wage") ///
	title("A. Mean log wage vs. education", pos(11) span) ///
	legend(off) name(fig1A, replace)

reg ind_effects_m3 educ [aw=wcount], robust
local b : display %5.3f _b[educ]
local se : display %5.3f _se[educ]
local r2: display %4.2f e(r2)

scatter ind_effects_m3 educ [aw=wcount], msymbol(oh) scheme(plotplain) || ///
  lfit ind_effects_m3 educ [aw=wcount] || ///
  , text(0.5 12 "Slope = `b' (`se')" "R{superscript:2} = `r2'", just(left)) ///
    xtitle("Mean Education of Workers in Industry") ///
	ytitle("Estimated Industry Wage Premium (Normalized)") ///
	title("B. Estimated industry premium vs. education", pos(11) span) ///
	legend(off) name(fig1B, replace)

graph combine fig1A fig1B, xcommon ///
  /*  title("Figure 1. Relationship of mean log wage and industry wage premium to mean education " */ ///
  /*        "of workers in industry (ACS 2010-2018)", pos(11) justification(left)) */ ///
  saving(${results}/f1.gph, replace)
graph export ${results}/f1.png, replace

log close
