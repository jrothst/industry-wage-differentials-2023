*read simple data sets created by myyyy.do 
*to avoid further cluttering of files; keep the 2010-2018 files in a single file
*adjust lines 21 and 142 accordingly to include however many vars we want


*NOTE ******* directories and file locations have to be set ************

cap log close
log using rank_revised_extravars.log, replace



set seed 921109



forvalues y=2010/2011 {

use ${scratch}/simple`y'.dta
isid serialno sporder
sort serialno sporder
keep serialno sporder age female educ twage hrswkly weeksly imm yoep region_birth pob wnh bnh anh hispanic mobility pweight ncz cz1-cz10 af1-af10 field_degree ind occ cow wagsal selfearn
gen year = `y'

drop if twage==.

gen college=(educ>=16)
gen logwage=log(twage)
gen exp=age-educ-6
gen exp2=exp*exp/100
gen exp3=exp*exp*exp/1000
gen f_exp=female*exp
gen f_exp2=female*exp2
gen f_exp3=female*exp3
gen f_educ=female*educ
gen f_college=female*college
gen pt=(hrswkly<35)
gen f_pt=female*pt



gen rv=runiform()
gen s1=af1
gen s2=af1+af2
gen s3=af1+af2+af3 
gen s4=af1+af2+af3+af4 
gen s5=af1+af2+af3+af4+af5 
gen s6=af1+af2+af3+af4+af5+af6
gen s7=af1+af2+af3+af4+af5+af6+af7
gen s8=af1+af2+af3+af4+af5+af6+af7+af8
gen s9=af1+af2+af3+af4+af5+af6+af7+af8+af9
gen s10=af1+af2+af3+af4+af5+af6+af7+af8+af9+af10
sum s1 if ncz==1
sum s1 s2 if ncz==2
sum s1-s3 if ncz==3
sum s1-s4 if ncz==4
sum s1-s5 if ncz==5
sum s1-s6 if ncz==6
sum s1-s7 if ncz==7
sum s1-s8 if ncz==8
sum s1-s9 if ncz==9
sum s1-s10 if ncz==10

sum rv , detail

gen cz=cz1 if ncz==1
replace cz=cz1*(rv<=s1)+cz2*(rv>s1) if ncz==2
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2) if ncz==3
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3) if ncz==4
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4) if ncz==5
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5) if ncz==6
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6) if ncz==7
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6)*(rv<=s7)+cz8*(rv>s7) if ncz==8
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6)*(rv<=s7)+cz8*(rv>s7)*(rv<=s8)+cz9*(rv>s8) if ncz==9
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6)*(rv<=s7)+cz8*(rv>s7)*(rv<=s8)+cz9*(rv>s8)*(rv<=s9)+cz10*(rv>s9) if ncz==10

sum cz


gen ind3=floor(ind/10)
gen naics=(ind3>=17)*(ind3<=29)
replace naics=2  if (ind3>=37)&(ind3<=49)
replace naics=3  if (ind3>=57)&(ind3<=69)
replace naics=4  if (ind3==77)
replace naics=5  if (ind3>=107)&(ind3<=399)
replace naics=6  if (ind3>=407)&(ind3<=459)
replace naics=7  if (ind3>=467)&(ind3<=579)
replace naics=8  if (ind3>=607)&(ind3<=639)
replace naics=9  if (ind3>=647)&(ind3<=678)
replace naics=10  if (ind3>=687)&(ind3<=699)
replace naics=11 if (ind3>=707)&(ind3<=719)
replace naics=12 if (ind3>=727)&(ind3<=757)
replace naics=13 if (ind3>=758)&(ind3<=779)
replace naics=14 if (ind3>=786)&(ind3<=789)
replace naics=15 if (ind3>=797)&(ind3<=847)
replace naics=16 if (ind3>=856)&(ind3<=859)
replace naics=17  if (ind3>=866)&(ind3<=869)
replace naics=18  if (ind3>=877)&(ind3<=936)
replace naics=19  if (ind3>=937)&(ind3<=987)
replace naics=20 if naics==0

replace naics=. if ind3==0
replace naics=. if ind3>=988
replace naics=. if ind3==.

gen field_degree2d = floor(field_degree/100)
gen field_degree_agg1 = ""
replace field_degree_agg1 = "Computers,Mathematics,and Statistics" if inlist(field_degree,2100,2102,2103,2105,2106,2107,2199) | (field_degree2d == 37)
replace field_degree_agg1 = "Biological,Agricultural,and Environmental Sciences" if (field_degree2d == 11) | (field_degree2d == 13) | (field_degree2d == 36)
replace field_degree_agg1 = "Physical and Related Science" if field_degree2d == 50
replace field_degree_agg1 = "Psychology" if field_degree2d == 52
replace field_degree_agg1 = "Social Science" if (field_degree == 1501) | (field_degree2d == 55) | (field_degree == 6401)
replace field_degree_agg1 = "Engineering" if field_degree2d == 24
replace field_degree_agg1 = "Multidisciplinary Studies" if field_degree2d == 40
replace field_degree_agg1 = "Science and Engineering Related Fields" if (field_degree == 1401) | inlist(field_degree,2101,2104) |  inlist(field_degree,2302,2305,2308) | (field_degree2d == 25) | (field_degree2d == 51) | (field_degree2d == 61 & field_degree != 6101)
replace field_degree_agg1 = "Business" if (field_degree == 3201) | (field_degree == 6101) | (field_degree2d == 62)
replace field_degree_agg1 = "Education" if (field_degree2d == 23) & !inlist(field_degree,2301,2305,2308)
replace field_degree_agg1 = "Literature and Languages" if (field_degree2d == 26) | (field_degree2d == 33)
replace field_degree_agg1 = "Liberal Arts and History" if (field_degree2d == 34) | (field_degree == 4801) | (field_degree == 4901) | inlist(field_degree,6402,6403)
replace field_degree_agg1 = "Visual and Performing Arts" if field_degree2d == 60
replace field_degree_agg1 = "Communications" if (field_degree2d == 19) | (field_degree == 2001)
replace field_degree_agg1 = "Other" if field_degree_agg1 == "" & field_degree != .

encode field_degree_agg1, gen(field_degree_agg)
drop field_degree2d field_degree_agg1

tempfile working`y'_tmp
save `working`y'_tmp', replace

tab naics
tab field_degree_agg
sum female age educ exp twage imm wnh bnh anh hispanic imm   
sum female age educ exp twage imm wnh bnh anh hispanic imm [aw=pweight] 
clear

}


forvalues y=2012/2018 {

use ${scratch}/simple`y'.dta
isid serialno sporder
sort serialno sporder

keep serialno sporder age female educ twage hrswkly weeksly imm yoep region_birth pob wnh bnh anh hispanic mobility pweight ncz cz1-cz9 af1-af9 ind occ field_degree cow wagsal selfearn
gen year = `y'

drop if twage==.

gen college=(educ>=16)
gen logwage=log(twage)
gen exp=age-educ-6
gen exp2=exp*exp/100
gen exp3=exp*exp*exp/1000
gen f_exp=female*exp
gen f_exp2=female*exp2
gen f_exp3=female*exp3
gen f_educ=female*educ
gen f_college=female*college
gen pt=(hrswkly<35)
gen f_pt=female*pt



gen rv=runiform()
gen s1=af1
gen s2=af1+af2
gen s3=af1+af2+af3 
gen s4=af1+af2+af3+af4 
gen s5=af1+af2+af3+af4+af5 
gen s6=af1+af2+af3+af4+af5+af6
gen s7=af1+af2+af3+af4+af5+af6+af7
gen s8=af1+af2+af3+af4+af5+af6+af7+af8
gen s9=af1+af2+af3+af4+af5+af6+af7+af8+af9

tab ncz
sum s1 if ncz==1
sum s1 s2 if ncz==2
sum s1-s3 if ncz==3
sum s1-s4 if ncz==4
sum s1-s5 if ncz==5
sum s1-s6 if ncz==6
sum s1-s7 if ncz==7
sum s1-s8 if ncz==8
sum s1-s9 if ncz==9

sum rv , detail

gen cz=cz1 if ncz==1
replace cz=cz1*(rv<=s1)+cz2*(rv>s1) if ncz==2
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2) if ncz==3
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3) if ncz==4
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4) if ncz==5
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5) if ncz==6
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6) if ncz==7
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6)*(rv<=s7)+cz8*(rv>s7) if ncz==8
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6)*(rv<=s7)+cz8*(rv>s7)*(rv<=s8)+cz9*(rv>s8) if ncz==9

sum cz

gen ind3=floor(ind/10)
gen naics=(ind3>=17)*(ind3<=29)
replace naics=2  if (ind3>=37)&(ind3<=49)
replace naics=3  if (ind3>=57)&(ind3<=69)
replace naics=4  if (ind3==77)
replace naics=5  if (ind3>=107)&(ind3<=399)
replace naics=6  if (ind3>=407)&(ind3<=459)
replace naics=7  if (ind3>=467)&(ind3<=579)
replace naics=8  if (ind3>=607)&(ind3<=639)
replace naics=9  if (ind3>=647)&(ind3<=678)
replace naics=10  if (ind3>=687)&(ind3<=699)
replace naics=11 if (ind3>=707)&(ind3<=719)
replace naics=12 if (ind3>=727)&(ind3<=757)
replace naics=13 if (ind3>=758)&(ind3<=779)
replace naics=14 if (ind3>=786)&(ind3<=789)
replace naics=15 if (ind3>=797)&(ind3<=847)
replace naics=16 if (ind3>=856)&(ind3<=859)
replace naics=17  if (ind3>=866)&(ind3<=869)
replace naics=18  if (ind3>=877)&(ind3<=936)
replace naics=19  if (ind3>=937)&(ind3<=987)
replace naics=20 if naics==0

replace naics=. if ind3==0
replace naics=. if ind3>=988
replace naics=. if ind3==.

gen field_degree2d = floor(field_degree/100)
gen field_degree_agg1 = ""
replace field_degree_agg1 = "Computers,Mathematics,and Statistics" if inlist(field_degree,2100,2102,2103,2105,2106,2107,2199) | (field_degree2d == 37)
replace field_degree_agg1 = "Biological,Agricultural,and Environmental Sciences" if (field_degree2d == 11) | (field_degree2d == 13) | (field_degree2d == 36)
replace field_degree_agg1 = "Physical and Related Science" if field_degree2d == 50
replace field_degree_agg1 = "Psychology" if field_degree2d == 52
replace field_degree_agg1 = "Social Science" if (field_degree == 1501) | (field_degree2d == 55) | (field_degree == 6401)
replace field_degree_agg1 = "Engineering" if field_degree2d == 24
replace field_degree_agg1 = "Multidisciplinary Studies" if field_degree2d == 40
replace field_degree_agg1 = "Science and Engineering Related Fields" if (field_degree == 1401) | inlist(field_degree,2101,2104) |  inlist(field_degree,2302,2305,2308) | (field_degree2d == 25) | (field_degree2d == 51) | (field_degree2d == 61 & field_degree != 6101)
replace field_degree_agg1 = "Business" if (field_degree == 3201) | (field_degree == 6101) | (field_degree2d == 62)
replace field_degree_agg1 = "Education" if (field_degree2d == 23) & !inlist(field_degree,2301,2305,2308)
replace field_degree_agg1 = "Literature and Languages" if (field_degree2d == 26) | (field_degree2d == 33)
replace field_degree_agg1 = "Liberal Arts and History" if (field_degree2d == 34) | (field_degree == 4801) | (field_degree == 4901) | inlist(field_degree,6402,6403)
replace field_degree_agg1 = "Visual and Performing Arts" if field_degree2d == 60
replace field_degree_agg1 = "Communications" if (field_degree2d == 19) | (field_degree == 2001)
replace field_degree_agg1 = "Other" if field_degree_agg1 == "" & field_degree != .

encode field_degree_agg1, gen(field_degree_agg)
drop field_degree2d field_degree_agg1

tempfile working`y'_tmp
save `working`y'_tmp', replace

tab naics
tab field_degree_agg
sum female age educ exp twage imm wnh bnh anh hispanic imm   
sum female age educ exp twage imm wnh bnh anh hispanic imm [aw=pweight] 

}

use `working2010_tmp', clear
append using `working2011_tmp' `working2012_tmp' `working2013_tmp' `working2014_tmp' `working2015_tmp' `working2016_tmp' `working2017_tmp' `working2018_tmp'
compress
save ${scratch}/working2010-2018_extravars.dta, replace

cap log close


