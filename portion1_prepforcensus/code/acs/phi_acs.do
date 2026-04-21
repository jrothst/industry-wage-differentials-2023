*program phi_acs to estimate industry diffs and worker quality by naics
*uses wage model from figure2.do (july 28, 2022)
*     plus model to assign naicsp from lehd1 (october 2022)
*     step1: assign naicsp
*     step2: fit wage model get ind effects and xb by naicsp
*     step3: collapse to naicsp and output

cap log close
log using "phi_acs.log", text replace

set seed 912109

*input data
local cz_top50 "${raw}/cw_cz_division_nottop50.dta" // top 50 CZs plus 9 census divisions for non-top 50
local acs2010_2018 "${scratch}/working2010-2018_extravars.dta" // ACS



use `acs2010_2018', clear



*STEP1 : define sample, set up covariates for wage model (including CZ), and assign naicsp


*drop obs to be consistent with 'sub' files used for main ACS analysis
drop if age < educ + 7 
drop if age > 62

gen alaska=(cz>=34101)*(cz<=34115)
replace cz=99999 if alaska==1

di _N

*set up X's

egen race_ind = rowmax(hispanic wnh bnh anh)
gen onh = (race_ind == 0)
drop race_ind 

foreach race in hispanic wnh bnh anh onh {
	gen f_`race' = female*`race'
}

gen ysa = year - yoep // years since arrival
replace ysa = 0 if imm == 0
gen useducated = 0 // educated in us
replace useducated = 1 if imm == 1 & ysa > exp+5
tab educ useducated if imm == 1

gen imm_LatAm = (region_birth == 3 & imm == 1) // region of birth indicators: omitted group is 'other'
gen imm_Asia = (region_birth == 4 & imm == 1)
gen imm_EurNAOceania = (inlist(region_birth,5,7,8) & imm == 1)
gen imm_LatAm_ysa = imm_LatAm*ysa
gen imm_Asia_ysa = imm_Asia*ysa
gen imm_EurNAOceania_ysa = imm_EurNAOceania*ysa


gen fod = field_degree_agg // 0's for non-college grads
replace fod = 0 if fod == .

*CZ redefinition: top 50+reallocation of rest to 9 divisions
sort cz year serialno sporder
isid cz year serialno sporder
merge m:1 cz using `cz_top50'
drop if _m == 2
drop _m
replace top50 = 0 if top50 == . // Alaska, aka cz=99999

gen cz_top50 = cz
replace cz_top50 = division if top50 == 0 // Alaska to missing

drop if cz_top50 == . // drop Alaska to ensure consistent sample across models; to keep Alaska, assign division 9



*now adjust industry codes using hand fixes from compare_ind.do in data/raw/2018/ 
*ind is now 2018 coding of ind
sort year serialno sporder
isid year serialno sporder

set seed 9211
gen u1=runiform()
sum u1


gen ind_old=ind
replace ind=1691 if ind==1680
replace ind=1691 if ind==1690

replace ind=3095 if ind==3090

replace ind=3291 if ind==3190
replace ind=3291 if ind==3290

replace ind=3365 if ind==3360

replace ind=3875 if ind==3870

replace ind=3895 if ind==3890

replace ind=4195 if ind==4190

replace ind=4265 if ind==4260

replace ind=4795 if ind==4790

replace ind=4971 if ind==4970
replace ind=4971 if ind==4972

replace ind=5275 if ind==5270

replace ind=5295 if ind==5290

*dept stores and superstores mess
*up to 2017 depart and discount in 5380, misc general in 5390
*in 2018+ depart in 5381 (about 45% of 5380), misc general+superstores in 5391 (all 5390+55% of 5380)

replace ind=5381 if ind==5380 & u1<=0.45
replace ind=5391 if ind==5380 & u1>0.45
replace ind=5391 if ind==5390


replace ind=5593 if ind==5590
replace ind=5593 if ind==5591
replace ind=5593 if ind==5592

replace ind=6991 if ind==6990 & u1<=0.75
replace ind=6992 if ind==6990 & u1>0.75

replace ind=7071 if ind==7070 & u1<=0.78
replace ind=7072 if ind==7070 & u1>0.78

replace ind=7181 if ind==7170
replace ind=7181 if ind==7180

replace ind=8191 if ind==8190 & u1<=0.98
replace ind=8192 if ind==8190 & u1>0.98

replace ind=8561 if ind==8560 & u1<=0.21
replace ind=8562 if ind==8560 & u1>0.21 & u1<=0.39
replace ind=8563 if ind==8560 & u1>0.39 & u1<=0.59
replace ind=8564 if ind==8560 & u1>0.59 

replace ind=8891 if ind==8880


*now assign ind2018fix from assign_naics.xlsx -- this pools 2+ inds that go to same naics
* 38 cases

replace ind=680 if ind==670
replace ind=680 if ind==590
replace ind=680 if ind==690

replace ind=1270 if ind==1190

replace ind=1691 if ind==1670

replace ind=1870 if ind==1880

replace ind=3875 if ind==3790

replace ind=2070 if ind==2090

replace ind=2380 if ind==2390

replace ind=2480 if ind==2470

replace ind=2980 if ind==2970

replace ind=3580 if ind==3590

replace ind=3990 if ind==3970
replace ind=3990 if ind==3980
replace ind=3990 if ind==2990

replace ind=4290 if ind==4280

replace ind=4580 if ind==4570
replace ind=4580 if ind==4590

replace ind=4795 if ind==4780

replace ind=4870 if ind==4880

replace ind=4971 if ind==4972

replace ind=5070 if ind==5080

replace ind=5275 if ind==5280
replace ind=5275 if ind==5295


replace ind=5480 if ind==5570

replace ind=5690 if ind==5680

replace ind=5580 if ind==5790

replace ind=6480 if ind==6470

replace ind=6770 if ind==6672
replace ind=6770 if ind==6780

replace ind=7480 if ind==7490

replace ind=8080 if ind==7990
replace ind=8080 if ind==8070

replace ind=8590 if ind==8580

replace ind=8770 if ind==8780

replace ind=8980 if ind==8970
replace ind=8980 if ind==8990

replace ind=9190 if ind==9180

replace ind=9370 if ind==9380
replace ind=9370 if ind==9390

gen ind2018=ind


*** now bring in naicsp (this is assigned based on ind2018)
sort ind2018 year serialno sporder
isid ind2018 year serialno sporder
merge m:1 ind2018 using ${raw}/assign_naics_step3
tab _m
drop if _m == 2
drop _m

*missing military obs
tab ind if naicsp==""


drop if naicsp==""





***STEP2 fit model

*legacy fixes (missing from above code)

gen f_age=female*age
gen exp4=exp2*exp2
gen f_exp4=female*exp4

sum [w=pweight]
tab naicsp [w=pweight]

*model1: basic mincer

areg logwage female educ f_educ exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_bnh f_anh f_hispanic  ///
i.year [aw=pweight], absorb(naicsp)
predict ind_effects_m1, d
predict skill_m1, xb


*model2: main model but no CZ

areg logwage age female f_age exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_wnh f_bnh f_anh f_hispanic imm useducated i.educ ///
i.educ#female i.educ#imm i.educ#useducated imm_LatAm imm_Asia imm_EurNAOceania ysa imm_LatAm_ysa imm_Asia_ysa imm_EurNAOceania_ysa i.fod i.fod#female i.year [aw=pweight], absorb(naicsp)
predict ind_effects_m2, d
predict skill_m2, xb


*model3: main model 

areg logwage age female f_age exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_wnh f_bnh f_anh f_hispanic imm useducated i.educ ///
i.educ#female i.educ#imm i.educ#useducated imm_LatAm imm_Asia imm_EurNAOceania ysa imm_LatAm_ysa imm_Asia_ysa imm_EurNAOceania_ysa i.fod i.fod#female i.year i.cz_top50 [aw=pweight], absorb(naicsp)
predict ind_effects_m3, d
predict skill_m3, xb


reg skill_m3 educ [w=pweight]
reg skill_m3 educ female [w=pweight]
reg skill_m3 skill_m1 [w=pweight]
reg skill_m3 skill_m2 [w=pweight]


**STEP3 collapse 

gen c=1
gen iw=1/pweight

collapse (mean) logwage female educ ind_effects_m1 ind_effects_m2 ind_effects_m3  skill_m1 skill_m2 skill_m3  (sum) count=iw wcount=c [pw=pweight], by(naicsp)

save ${scratch}/indeffects_naicsp, replace

sum
sum [w=wcount]
reg logwage ind_effects_m3 skill_m3 [w=wcount]
reg logwage ind_effects_m3  [w=wcount]
reg skill_m3 educ           [w=wcount]
reg skill_m3 educ female    [w=wcount]
reg skill_m3 skill_m1       [w=wcount]
reg skill_m3 skill_m2       [w=wcount]

reg skill_m3 logwage            [w=wcount]
reg ind_effects_m3 logwage      [w=wcount]

reg skill_m2 logwage            [w=wcount]
reg ind_effects_m2 logwage      [w=wcount]
reg skill_m1 logwage            [w=wcount]
reg ind_effects_m1 logwage      [w=wcount]


list naicsp count wcount logwage educ female ind_effects_m3 skill_m3 

log close
