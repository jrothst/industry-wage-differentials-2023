cap log close
log using phi_cz_alt-wage.log, text replace

/*******************************************
Source:
rank6_alt-wage.do
Author: Richard Jin (richjin@berkeley.edu)
Last modified: 6/18/21
adjusted by dc to set predicts to missing for out of scope cases
adjusted by JR 9/23 for replication package
*******************************************/

set seed 912109

*Intermediate CZ names
local cznames_dta "${raw}/cznames.dta"

*Output datasets
local czranking6_altwage_dta "${scratch}/phi_cz_alt-wage.dta" //CZ-level means


use ${scratch}/working2010-2018_extravars, clear
drop if age < educ + 7 
drop if age > 62

/*
*Input datasets
forvalues y = 2010(1)2018 {
	local sub`y' "./sub`y'.dta"
}

use `sub2010', clear
append using `sub2011' `sub2012' `sub2013' `sub2014' `sub2015' `sub2016' `sub2017' `sub2018'
*/


***********************
*I. Weighted regressions
***********************


*setup 
gen alaska=(cz>=34101)*(cz<=34115)
tab year alaska , row col

replace cz=99999 if alaska==1

gen imm_r3=(region_birth==3)
gen imm_r4=(region_birth==4)
gen imm_r5=(region_birth==5) + (region_birth==7) + (region_birth==8)

gen imm_r3_f=imm_r3*female
gen imm_r4_f=imm_r4*female
gen imm_r5_f=imm_r5*female

gen imm_f=imm*female

*four measures of wages- 3800 cutoff is rule imposed in using LEHD quarterly data
gen logwage1 = .
replace logwage1=logwage if wagsal>=3800
gen logwage2 = .
replace logwage2=logwage if wagsal>=2*3800
gen logwage3 = .
replace logwage3=logwage if wagsal>=3*3800
gen logwage4 = .
replace logwage4=logwage if wagsal>=4*3800


sum logwage logwage1-logwage4 [aw=pweight]
corr logwage logwage1-logwage4 [aw=pweight]


*adjusted 1- with demographics
forvalues i=4(1)4 {
	areg logwage`i' female educ college f_educ f_college exp exp2 exp3 f_exp f_exp2 f_exp3 pt f_pt i.year imm_r3 imm_r4 imm_r5 imm_r3_f imm_r4_f imm_r5_f imm imm_f [aw=pweight], absorb(cz)
	predict czbase`i', d
	predict skillbase`i', xb
        replace czbase`i'=. if logwage`i'==.
        replace skillbase`i'=. if logwage`i'==.
}

*adjusted 2- with demographics & industry 
forvalues i = 4(1)4 {
	areg logwage`i' female educ college f_educ f_college exp exp2 exp3 f_exp f_exp2 f_exp3 pt f_pt i.year imm_r3 imm_r4 imm_r5 imm_r3_f imm_r4_f imm_r5_f imm imm_f i.naics [aw=pweight], absorb(cz)
	predict czind`i', d
	predict skillind`i', xb
        replace czind`i'=. if logwage`i'==.
        replace skillind`i'=. if logwage`i'==.

}

/***********************
II. Collapse to CZ level
***********************/

gen c = 1
forvalues i = 4(1)4 {
	gen c`i' = .
	replace c`i' = 1 if logwage`i' != .
}

collapse (mean) mlogwage4=logwage4 czbase4=czbase4 czind4=czind4 (sum) wcount=c wcount4=c4 [pw=pweight], by(cz)

forvalues i = 4(1)4 {
	*frac of obs dropped when imposing wage cutoffs
	gen fracdrop`i' = (wcount - wcount`i')/wcount
}

merge 1:1 cz using `cznames_dta'
tab _m
drop if _m == 2
drop _m

save `czranking6_altwage_dta', replace

keep cz mlogwage4 wcount
save ${tocensus}/czranking6_alt-wage.dta, replace

desc
sum
sum [aw=wcount]

/* 
corr logwage logwage1-logwage4 czbase1-czbase4 czind1-czind4 [aw=wcount]

*check
reg mlogwage1 czbase1 skillbase1 [aw=wcount1]
reg mlogwage2 czbase2 skillbase2 [aw=wcount2]
reg mlogwage3 czbase3 skillbase3 [aw=wcount3]
reg mlogwage4 czbase4 skillbase4 [aw=wcount4]
*/

cap log close
