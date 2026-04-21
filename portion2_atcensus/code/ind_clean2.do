/*----------------------------------------------------------------------------*\

* CLEAN2 - INDUSTRY

Input:
icf_us.sas7bdat 
phftemp_akm.dta
m5_icf_dob.dta
m5_piklist_educacs.dta
m5_ecf_seinunit.dta
cw_cty_czone.dta
czranking6_alt-wage.dta


Output:
cw_st_div.dta
mig5_pikqtime_1018a.dta
mig5_pikqtime_1018b.dta
mig5_pikqtime_1018_finalpiklist.dta
mig5_pikqtime_1018_top59A.dta
mig5_pikqtime_1018_top59A.raw
mig5_pikqtime_1018_top59B.dta
mig5_pikqtime_1018_top59B.raw
mig5_pikqtime_1018_educacs.dta
mig5_pikqtime_1018_educacstop59_new.dta
mig5_pikqtime_1018_educacstop59_new.raw
cw_cty_czone_v2.dta

\*----------------------------------------------------------------------------*/

local seed SEED
clear
set more off

// Set directories
include ind_paths.do
cd $yidata

********************************************************************************
*Adjust county-CZ crosswalk to reflect inconsistencies in county 
*codes over time
*** Source: DAVID DORN’S DOCUMENTATION OF COUNTY CHANGES (from 
*** http://ddorn.net/data/FIPS_County_Code_Changes.pdf)
*     Colorado, 2001: Broomfield county (FIPS 8014) is created out of 
*       parts of Adams, Boulder, Jefferson, and Weld counties. The Census 
*       Bureau estimates that the resulting population loss was 21,512 for 
*       Boulder, 15,870 for Adams, 1,726 for Jefferson, and 69 for Weld 
*       county.
*       Action: Add new record for FIPS 8014, assigned to CZ 28900 
*         which comprises the three counties Adams, Boulder and Jefferson.
*     Florida, 1997: Dade county (FIPS 12025) is renamed as Miami-Dade 
*       county (FIPS 12086).
*       Action: Add new record for the new FIPS code, mapping to the same CZ 
*         (7000)
use "cw_cty_czone.dta", clear
count
local norig=r(N)
local nnew=`norig'+2
set obs `nnew'
local i=`norig'+1
replace czone=28900 in `i'
replace cty_fips=8014 in `i'
local i=`norig'+2
replace czone=7000 in `i'
replace cty_fips=12086 in `i'
sort cty_fips
save cw_cty_czone_v2.dta, replace

********************************************************************************
* STATE - DIVISION CROSSWALK
clear
set obs 56
gen stfips_num=_n
drop if inlist(stfips_num, 3, 7, 14, 43, 52)
tostring stfips_num, gen(statefips) format(%02.0f)
gen division=1 if inlist(stfips_num, 9, 23, 25, 33, 44, 50)
replace division=2 if division==. & inlist(stfips_num, 34, 36, 42)
replace division=3 if division==. & inlist(stfips_num, 18, 17, 26, 39, 55)
replace division=4 if division==. & inlist(stfips_num, 19, 20, 27, 29, 31, 38, 46)
replace division=5 if division==. & inlist(stfips_num, 10, 11, 12, 13, 24, 37, 45, 51, 54)
replace division=6 if division==. & inlist(stfips_num, 1, 21, 28, 47)
replace division=7 if division==. & inlist(stfips_num, 5, 22, 40, 48)
replace division=8 if division==. & inlist(stfips_num, 4, 8, 16, 35, 30, 49, 32, 56)
replace division=9 if division==. & inlist(stfips_num, 2, 6, 15, 41, 53)
save $yidata/cw_st_div.dta, replace

********************************************************************************
********************************************************************************
*************************** MAIN CLEANING **************************************

* transform into pik-qtime format
forval q=97(1)134 {
noi dis "********** QTIME `q' **********"

* r1. only keep quarters with earnings above $3800
use pik sein seinunit1 e`q' state if (e`q'>=3800 & e`q'~=.) using phftemp_akm.dta, replace

rename e`q' e
gen qtime=`q'

* flag multiple jobs
sort pik qtime
by pik: gen multjob=(_N~=1)
by pik: gen N=_N
* drop obs with more than 20 jobs 
drop if N>20

* r3. age restriction
* add date of birth from icf, drop if dob missing or if not in age range 22-62
merge n:1 pik using m5_icf_dob.dta, keep(master match) nogen sorted
drop if dob==.
drop if (((qtime+99)-qofd(dob))/4<22) | (((qtime+99)-qofd(dob))/4>=63)

save m5_temp_qtime`q', replace
}

* Append/merge all separate files 
* split in three, 101-117, 118-134, 97-100, BUT: always go one extra to address transtional quarter issues
* FILE A - 101-117 (add 118, then drop)
clear
forval q=101(1)118 {
append using m5_temp_qtime`q'.dta
dis "qtime `q'"
count
}
rename seinunit1 seinunit
sort pik qtime
* r3. drop "transitional quarters"
gen est=sein+"_"+seinunit
gen trq=0
by pik: replace trq=1 if ((est~=est[_n-1]) | (est~=est[_n+1])) & _n~=1 & _n~=_N 
* addressing multiple jobs (if there is any match in to multiple job firms, then quarter is not transitional)
sum N
local maxmultjobs=r(max)
forval i=1/`maxmultjobs' {
dis "`i'"
by pik: replace trq=0 if  (qtime[_n+`i']==qtime+1) & (multjob==0 & multjob[_n+`i']==1) & (est==est[_n+`i'])
by pik: replace trq=0 if  (qtime[_n-`i']==qtime-1) & (multjob==0 & multjob[_n-`i']==1) & (est==est[_n-`i'])
} 
drop est N
tab trq, miss
keep if trq==0
drop trq
* r2. drop spells with multiple jobs
tab multjob, miss
drop if multjob==1
drop multjob
* now only keep up to qtime 117
drop if qtime==118
save mig5_pikqtime_1018a.dta, replace


* FILE B - 118-134 (add 117, then drop)
clear
forval q=117(1)134 {
append using m5_temp_qtime`q'.dta
dis "qtime `q'"
count
}
rename seinunit1 seinunit
sort pik qtime
* r3. drop "transitional quarters"
gen est=sein+"_"+seinunit
gen trq=0
by pik: replace trq=1 if ((est~=est[_n-1]) | (est~=est[_n+1])) & _n~=1 & _n~=_N 
* addressing multiple jobs (if there is any match in to multiple job firms, then quarter is not transitional)
sum N
local maxmultjobs=r(max)
forval i=1/`maxmultjobs' {
dis "`i'"
by pik: replace trq=0 if  (qtime[_n+`i']==qtime+1) & (multjob==0 & multjob[_n+`i']==1) & (est==est[_n+`i'])
by pik: replace trq=0 if  (qtime[_n-`i']==qtime-1) & (multjob==0 & multjob[_n-`i']==1) & (est==est[_n-`i'])
} 
drop est N
tab trq, miss
keep if trq==0
drop trq
* r2. drop spells with multiple jobs
tab multjob, miss
drop if multjob==1
drop multjob
* now only keep up to qtime 117
drop if qtime==117
save mig5_pikqtime_1018b.dta, replace


************ here, this needs to happen after all qtimes are included
* r6: LF attachment restriction - drop if not observed in at least 8 quarters (in 8 year case)
* for efficiency purposes, clean before appending
use pik e using mig5_pikqtime_1018b.dta, replace
fcollapse (count) count=e, by(pik) fast
tempfile pikb
save `pikb'
use pik e using mig5_pikqtime_1018a.dta, replace
fcollapse (count) count=e, by(pik) fast
append using `pikb'
fcollapse (sum) count, by(pik) fast
tab count
drop if count<8
drop count
sort pik
tempfile piklist
save `piklist'
* two temporary files for now
foreach file in a b {
use mig5_pikqtime_1018`file'.dta, replace
merge n:1 pik using `piklist', keep(match) nogen sorted 
save mig5_pikqtime_1018`file'.dta, replace
}

* add workplace location and industry, drop if cz or naics2d missing
use m5_ecf_seinunit.dta, clear
gen cty_fips=leg_state+leg_county
drop leg_county
rename leg_state state
destring cty_fips, replace
assert cty_fips~=.
merge n:1 cty_fips using cw_cty_czone_v2.dta, nogen keep(master match)
rename czone cz
gen naics2d=substr(naics2012fnl,1,2)
sort sein seinunit year quarter
tempfile ecf
save `ecf'
foreach file in a b {
use mig5_pikqtime_1018`file'.dta, replace
gen year=floor((qtime-1)/4+1985)
gen quarter=qtime-4*(year-1985)
sort sein seinunit year quarter
merge n:1 sein seinunit year quarter using `ecf', sorted keep(master match) keepusing(cty_fips cz naics2d)
tab _merge 
drop _merge
destring naics2d, replace force
drop if cz==.
drop if naics2d==.
save mig5_pikqtime_1018`file'.dta, replace
}



* r7: drop pq observations in cz-ind cells with less than 200 pik-q obs - this requires full sample
use  pik cz naics2d e using mig5_pikqtime_1018a.dta, replace
collapse (count) count=e, by(cz naics2d) fast
tempfile cellsa
save `cellsa'
use  pik cz naics2d e using mig5_pikqtime_1018b.dta, replace
collapse (count) count=e, by(cz naics2d) fast
append using `cellsa'
collapse (sum) count, by(cz naics2d) fast
sum count, d
count
unique cz
unique naics2d
unique cz naics2d
save mig5_cells_1018.dta, replace
use mig5_cells_1018.dta, replace
keep if count<200
keep cz naics2d 
sort cz naics2d
tempfile droplist
save `droplist'

foreach file in a b {
use mig5_pikqtime_1018`file'.dta, replace
sort cz naics2d
merge n:1 cz naics2d using `droplist', sorted keep(master match)
tab _merge
keep if _merge==1
drop _merge
sort pik qtime
save mig5_pikqtime_1018`file'.dta, replace
}


**************** done with restrictions **************************
* get final list of piks
* split into 30 random samples (of piks)
use pik qtime if qtime>=101 using mig5_pikqtime_1018a.dta, replace
drop qtime
by pik: keep if _n==1
tempfile finalpiklista
save `finalpiklista'
use pik using mig5_pikqtime_1018b.dta, replace
append using `finalpiklista'
bys pik: keep if _n==1
set type double
destring pik, gen(pikn) force
encode pik if pikn==., gen(pikn2)
replace pikn=pikn2 if pikn==. & pikn2~=.
drop pikn2
format pikn %20.0f
bys pikn: assert _n==1
sort pik
set seed `seed'
gen x2=runiform()
egen sample=cut(x2), group(30)
replace sample=sample+1
drop x?
save mig5_pikqtime_1018_finalpiklist.dta, replace


* UP UNTIL HERE mig5_pikqtime_1018a.dta + mig5_pikqtime_1018b.dta CONTAIN 100% SAMPLE
* 100% LIST OF PIKS IS IN mig5_pikqtime_1018_finalpiklist.dta
********************************************************************************
********************************************************************************
********************************************************************************





********************************************************************************
* ACS EDUCATION SAMPLE - 100% 
* add demographic variables
import sas pik sex using "$lehd2018/icf_us.sas7bdat", clear case(lower)
tempfile icffile
save `icffile', replace

* spliting Cplus sample
use pik pikn using mig5_pikqtime_1018_finalpiklist.dta, replace
merge 1:1 pik using m5_piklist_educacs.dta, keepusing(educacs) keep(match) nogen
keep if (educacs==2 | educacs==3 | educacs==4)
drop educacs
set seed `seed'
gen Cplussample=runiform()>=.5
replace Cplussample=Cplussample+1
assert Cplussample==1 | Cplussample==2
keep pikn Cplussample
tempfile Cplussample
save `Cplussample', replace

use pik pikn using mig5_pikqtime_1018_finalpiklist.dta, replace
merge 1:1 pik using m5_piklist_educacs.dta, keepusing(educacs schl)
tab _merge
keep if _merge==3
drop _merge
gen t=educacs~=.
tab t
keep if t==1
drop t
destring schl, replace force
cap drop _merge
merge 1:1 pikn using `Cplussample', keep(master match) keepusing(Cplussample)
assert Cplussample==. if (educacs~=2 & educacs~=3 & educacs~=4)
assert Cplussample~=. if (educacs==2 | educacs==3 | educacs==4)
sort pik
preserve
* a
merge 1:n pik using mig5_pikqtime_1018a.dta, keep(match) sorted nogen
tempfile ta
save `ta', replace
*b
restore
merge 1:n pik using mig5_pikqtime_1018b.dta, keep(match) sorted nogen
append using `ta'
* reformatting to match matlab (encoding might change across samples)
tostring cz, gen(t) format(%05.0f)
gen firmid=string(naics2d)+t
drop t
destring firmid, replace
assert firmid~=.
gen y=ln(e)
bys firmid qtime: gen firmsize=_N
gen age=floor(((qtime+99)-qofd(dob))/4)
bys pikn qtime: assert _n==1
by pikn: gen qobserved_ever=_n
replace qobserved_ever=5 if qobserved_ever>5
by pikn: gen t1=(cz~=cz[_n-1]) if _n>1
by pikn: gen t2=sum(t1)
sort pikn t2 qtime
by pikn t2: gen qobserved_incz=_n
replace qobserved_incz=5 if qobserved_incz>5
gen qobserved_inczt=qobserved_incz
replace qobserved_inczt=99 if t2==0 // before first move we don't know time in cz
drop t1 t2
merge n:1 pik using `icffile', keep(master match) nogen
foreach v in sex {
rename `v' `v'c
encode `v'c, gen(`v')
drop `v'c
}
sort pikn qtime
save mig5_pikqtime_1018_educacs.dta, replace


********************************************************************************
* EDUCATION SAMPLE 100% - "TOP 59" CZ SAMPLEs WITH 4-DIG IND
* note variable CZ is modified 

use cz wcount using czranking6_alt-wage.dta, replace
gsort -wcount
keep if _n<=50
levelsof cz, local(top50)

* data for 4-digit industry move testing
use sein seinunit year quarter naics2012fnl using m5_ecf_seinunit.dta, clear
gen naics4d=substr(naics2012fnl,1,4)
drop naics2012fnl
sort sein seinunit year quarter
tempfile ecf
save `ecf'

* demographic variables
import sas using "$lehd2018/icf_us.sas7bdat", clear case(lower)
keep pik race ethnicity sex dob pob
tempfile icffile
save `icffile', replace

use mig5_pikqtime_1018_educacs.dta, replace
cap drop _merge
gen keep=0
foreach cz in `top50' {
	replace keep=1 if cz==`cz'
}
* code non-top50 CZs into divisions
rename state statefips
merge n:1 statefips using cw_st_div.dta, keep(master match) nogen
drop state
replace cz=division if keep~=1
assert cz~=.
drop keep division
* add naics4d
cap gen year=floor((qtime-1)/4+1985)
cap gen quarter=qtime-4*(year-1985)
sort sein seinunit year quarter
merge n:1 sein seinunit year quarter using `ecf', sorted keep(master match) keepusing(naics4d)
tab _merge 
drop _merge year quarter
destring naics4d, replace force
* reformatting to match matlab (encoding might change across samples)
tostring cz, gen(t) format(%05.0f)
cap drop firmid
*gen firmid=string(naics2d)+t
gen firmid4d=string(naics4d)+t
drop t
*destring firmid, replace
destring firmid4d, replace
format firmid4d %9.0f
assert firmid4d~=.
*gen y=ln(e)
cap drop firmsize
*bys firmid qtime: gen firmsize=_N
bys firmid4d qtime: gen firmsize4d=_N
*gen age=floor(((qtime+99)-qofd(dob))/4)
drop e dob
cap drop sex
merge n:1 pik using `icffile', keep(master match) nogen
foreach v in race sex {
rename `v' `v'c
encode `v'c, gen(`v')
drop `v'c
}
gen hisp=(ethnicity=="H")
gen forborn=(pob~="A")
drop pob ethnicity dob
destring sex, replace
replace sex=0 if sex==2
bys pikn qtime: assert _n==1
save mig5_pikqtime_1018_educacstop59_new.dta, replace
outfile pikn qtime firmid4d y firmsize4d age cz naics4d educacs sex race hisp forborn  using mig5_pikqtime_1018_educacstop59_new.raw, comma replace nolabel




********************************************************************************
* "TOP 59" CZ SAMPLEs 20% - A & B (for disclosure, this is the combination of samples A s2-s7, B s8-s13)
* not variable CZ is modified 
use cz wcount using czranking6_alt-wage.dta, replace
gsort -wcount
keep if _n<=50
levelsof cz, local(top50)

* data for 4-digit industry move testing
use sein seinunit year quarter naics2012fnl using m5_ecf_seinunit.dta, clear
gen naics4d=substr(naics2012fnl,1,4)
drop naics2012fnl
sort sein seinunit year quarter
tempfile ecf
save `ecf'

* 20% random sample A - (2-7)
use if (sample==2 | sample==3 | sample==4 | sample==5 | sample==6 | sample==7) using mig5_pikqtime_1018_finalpiklist.dta, replace
merge 1:n pik using mig5_pikqtime_1018a.dta, keep(match) sorted nogen
keep pikn pik qtime sein seinunit e dob cz naics2d state
gen keep=0
foreach cz in `top50' {
	replace keep=1 if cz==`cz'
}
rename state statefips
merge n:1 statefips using cw_st_div.dta, keep(master match) nogen
drop state
replace cz=division if keep~=1
assert cz~=.
drop keep division
tempfile ta
save `ta', replace
use if (sample==2 | sample==3 | sample==4 | sample==5 | sample==6 | sample==7) using mig5_pikqtime_1018_finalpiklist.dta, replace
merge 1:n pik using mig5_pikqtime_1018b.dta, keep(match) sorted nogen
keep pikn pik qtime sein seinunit e dob cz naics2d state
gen keep=0
foreach cz in `top50' {
	replace keep=1 if cz==`cz'
}
rename state statefips
merge n:1 statefips using cw_st_div.dta, keep(master match) nogen
drop state
replace cz=division if keep~=1
assert cz~=.
drop keep division
append using `ta'
* add naics4d
gen year=floor((qtime-1)/4+1985)
gen quarter=qtime-4*(year-1985)
sort sein seinunit year quarter
merge n:1 sein seinunit year quarter using `ecf', sorted keep(master match) keepusing(naics4d)
tab _merge 
drop _merge year quarter
destring naics4d, replace force
tostring cz, gen(t) format(%05.0f)
gen firmid4d=string(naics4d)+t
drop t
destring firmid4d, replace
format firmid4d %9.0f
assert firmid4d~=.
gen y=ln(e)
bys firmid4d qtime: gen firmsize4d=_N
gen age=floor(((qtime+99)-qofd(dob))/4)
drop e dob
merge n:1 pik using `icffile', keep(master match) nogen
foreach v in race sex {
rename `v' `v'c
encode `v'c, gen(`v')
drop `v'c
}
gen hisp=(ethnicity=="H")
gen forborn=(pob~="A")
drop pob ethnicity dob
destring sex, replace
replace sex=0 if sex==2
bys pikn qtime: assert _n==1
save mig5_pikqtime_1018_top59A.dta, replace
outfile pikn qtime firmid4d y firmsize4d age cz naics4d sex race hisp forborn using mig5_pikqtime_1018_top59A.raw, comma replace nolabel



* 20% random sample B - (8-13)
use if (sample==8 | sample==9 | sample==10 | sample==11 | sample==12 | sample==13) using mig5_pikqtime_1018_finalpiklist.dta, replace
merge 1:n pik using mig5_pikqtime_1018a.dta, keep(match) sorted nogen
keep pikn pik qtime sein seinunit e dob cz naics2d state
gen keep=0
foreach cz in `top50' {
	replace keep=1 if cz==`cz'
}
* code non-top50 CZs into divisions
rename state statefips
merge n:1 statefips using cw_st_div.dta, keep(master match) nogen
drop state
replace cz=division if keep~=1
assert cz~=.
drop keep division
tempfile ta
save `ta', replace
use if (sample==8 | sample==9 | sample==10 | sample==11 | sample==12 | sample==13) using mig5_pikqtime_1018_finalpiklist.dta, replace
merge 1:n pik using mig5_pikqtime_1018b.dta, keep(match) sorted nogen
keep pikn pik qtime sein seinunit e dob cz naics2d state
gen keep=0
foreach cz in `top50' {
	replace keep=1 if cz==`cz'
}
* code non-top50 CZs into divisions
rename state statefips
merge n:1 statefips using cw_st_div.dta, keep(master match) nogen
drop state
replace cz=division if keep~=1
assert cz~=.
drop keep division
append using `ta'
* add naics4d
gen year=floor((qtime-1)/4+1985)
gen quarter=qtime-4*(year-1985)
sort sein seinunit year quarter
merge n:1 sein seinunit year quarter using `ecf', sorted keep(master match) keepusing(naics4d)
tab _merge 
drop _merge year quarter
destring naics4d, replace force
* reformatting to match matlab (encoding might change across samples)
tostring cz, gen(t) format(%05.0f)
*gen firmid=string(naics2d)+t
gen firmid4d=string(naics4d)+t
drop t
*destring firmid, replace
destring firmid4d, replace
format firmid4d %9.0f
assert /*firmid~=. & */ firmid4d~=.
gen y=ln(e)
*bys firmid qtime: gen firmsize=_N
bys firmid4d qtime: gen firmsize4d=_N
gen age=floor(((qtime+99)-qofd(dob))/4)
drop e dob
merge n:1 pik using `icffile', keep(master match) nogen
foreach v in race sex {
rename `v' `v'c
encode `v'c, gen(`v')
drop `v'c
}
gen hisp=(ethnicity=="H")
gen forborn=(pob~="A")
drop pob ethnicity dob
destring sex, replace
replace sex=0 if sex==2
bys pikn qtime: assert _n==1
save mig5_pikqtime_1018_top59B.dta, replace
outfile pikn qtime firmid4d y firmsize4d age cz naics4d sex race hisp forborn using mig5_pikqtime_1018_top59B.raw, comma replace nolabel
