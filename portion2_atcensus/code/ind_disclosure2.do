/*----------------------------------------------------------------------------*\
REPLICATION CODE

Disclosure 1, tabs 1 2 3 4 5 8 11 12

input files:
	$yidata/mig5_pikqtime_1018_top59A.dta
	$yidata/mig5_pikqtime_1018a.dta
	$yidata/mig5_pikqtime_1018b.dta
	$yidata/mig5_pikqtime_1018_finalpiklist.dta
	$dataind/AKMests_cz`cz'.dta
	$datadir/mig5_pikqtime_1018_cz`cz'.dta
	$lehd2018/icf_us.sas7bdat
	$dataind/AKMests_fjc.dta
	$output/Top59IndustryModelFEs.dta
	$output/Top59_t3.dta
	$yidata/tempevent2_m9ind.dta
\*----------------------------------------------------------------------------*/
set linesize 255

// Set directories
include ind_paths.do
cd $yidata

********************************************************************************
* DATA CLEANING - EVENT STUDY SAMPLE  

* Identify top 50 CZs
use cz wcount using "$yidata/czranking6_alt-wage.dta", replace
gsort -wcount
keep if _n<=50
levelsof cz, local(top50)
levelsof cz, local(top_50) sep(,)

foreach cz in `top50' d1 d2 d3 d4 d5 d6 d7 d8 d9 {	
use  pikn qtime cz naics4d y age firmid using $datadir/mig5_pikqtime_1018_cz`cz'.dta, replace
merge 1:1 pikn qtime using $dataind/AKMests_cz`cz'.dta, nogen keepusing(akm_person akm_firm) keep(master match)
gen y1=y-akm_person-akm_firm
replace age=(age-40)/40 
qui sum qtime
local maxqtime=r(max) 
reg y1 c.age##c.age##c.age ib`maxqtime'.qtime
predict akm_res, residual
gen akm_xb=y-akm_person-akm_firm-akm_res
drop y1
sum akm_res akm_xb
fsort pikn qtime
by pikn: gen t1=1 if (_n>1 & (naics4d~=naics4d[_n-1]))
by pikn: gen t2=1 if t1==1 &    ((qtime[_n+1]==qtime+1) & (naics4d==naics4d[_n+1])) & ///
				((qtime[_n+2]==qtime+2) & (naics4d==naics4d[_n+2])) & ///
				((qtime[_n+3]==qtime+3) & (naics4d==naics4d[_n+3])) & ///
				((qtime[_n+4]==qtime+4) & (naics4d==naics4d[_n+4]))
by pikn: gen t3=1 if t1==1  & ///
((qtime[_n-2]==qtime[_n-1]-1) & (naics4d[_n-1]==naics4d[_n-2])) & ///
((qtime[_n-3]==qtime[_n-2]-1) & (naics4d[_n-2]==naics4d[_n-3])) & ///
((qtime[_n-4]==qtime[_n-3]-1) & (naics4d[_n-3]==naics4d[_n-4])) & ///
((qtime[_n-5]==qtime[_n-4]-1) & (naics4d[_n-4]==naics4d[_n-5]))
* flag - t4 are the relevant moves (not unique by pikn)
egen t4=rowtotal(t1 t2 t3)
drop t1 t2 t3
gen t1=(t4==3) 
gen edate=0 if t1==1
by pikn: egen multmoves=sum(t1)
keep if multmoves==1
by pikn: replace edate=edate[_n-1]+1 if edate[_n-1]~=.
forval i=1/5{
by pikn: replace edate=edate[_n+1]-1 if edate[_n+1]~=.
}
keep if edate>=-5 & edate<=4
* transition gap restrictions
by pikn: gen gap=(qtime-qtime[_n-1]-1) if t1==1  
tab gap
drop if gap==0
by pikn: egen mgap=max(gap) 
keep if mgap<=6
drop mgap
by pikn: gen czswitch=1 if (_n>1 & (cz~=cz[_n-1]))
by pikn: gen naics4dswitch=1 if (_n>1 & (naics4d~=naics4d[_n-1])) 
by pikn: gen firmidswitch=1 if (_n>1 & (firmid~=firmid[_n-1])) 
fsort pikn qtime
gen x=cz if t1[_n+1]==1
by pikn: egen czorig=max(x)
drop x
gen x=naics4d if t1[_n+1]==1
by pikn: egen naics4dorig=max(x)
drop x
gen x=firmid if t1[_n+1]==1
by pikn: egen firmidorig=mode(x)
drop x
gen x=cz if t1==1
by pikn: egen czdest=max(x)
drop x
gen x=naics4d if t1==1
by pikn: egen naics4ddest=max(x)
drop x
gen x=firmid if t1==1
by pikn: egen firmiddest=mode(x)
drop x
rename cz truecz
rename naics4d truenaics4d
rename firmid truefirmid
rename y lne
fsort pikn qtime
* switch types
gen switchtype=1 if czswitch==1 & naics4dswitch==.
replace switchtype=2 if czswitch==. & naics4dswitch==1
replace switchtype=3 if czswitch==1 & naics4dswitch==1
tab switchtype if edate==0, miss
*add adjustment
qui reg lne ibn.qtime c.age##c.age##c.age, nocons
predict lnea, res
by pikn: gen d_lne=lne-lne[_n-1]
by pikn: gen d_lnea=lnea-lnea[_n-1]
by pikn: gen lne_pre=lne[_n-1]
by pikn: gen lnea_pre=lnea[_n-1]
* different time horizons (in the future, keeping t-1 fixed)
forval t1=1/4 {
by pikn: gen d_lne_t`t1'=lne[_n+`t1']-lne[_n-1] if edate==0
}
* variables for figure 3 (contemporaneous)
gen y_m_xb=lne-akm_xb
* variables for figure 4 (changes)
foreach v in y_m_xb akm_res {
by pikn: gen d_`v'=`v'-`v'[_n-1]	
}
save m9t_cz`cz'.dta, replace
}
clear
foreach cz in `czlist' {
append using m9t_cz`cz'.dta
}
fsort pikn qtime
save tempevent2_m9ind.dta, replace
foreach cz in `czlist' {
erase m9t_cz`cz'.dta
}




********************************************************************************
// D1: OUTPUT 1
* Descriptives

* full estimation sample (connected set) - aggregate at the pik level, saving Npq
cap erase indsample1.dta
clear
set obs 0
gen pikn=.
save indsample1.dta, replace

* Identify top 50 CZs
use cz wcount using "$yidata/czranking6_alt-wage.dta", replace
gsort -wcount
keep if _n<=50
levelsof cz, local(top50)
levelsof cz, local(top_50) sep(,)

foreach cz in `top50' d1 d2 d3 d4 d5 d6 d7 d8 d9 {
use pikn qtime using $dataind/AKMests_cz`cz'.dta, replace
fmerge 1:1 pikn qtime using $datadir/mig5_pikqtime_1018_cz`cz'.dta, keep(match) nogen keepusing(cz naics4d y age firmid)
* so far we have connected set for cz file
gen Npq=1
bys pikn naics4d: gen naics4dcnt=_n==1
fcollapse (sum) Npq naics4dcnt (mean) y age, by(pikn) fast smart
gen cz="`cz'"
append using indsample1.dta
save indsample1.dta, replace
}

* demographic variables
import sas using $lehd2018/icf_us.sas7bdat, clear case(lower)
keep pik race ethnicity sex dob pob
tempfile icffile
save `icffile', replace

* so far this sample has pikn-cz unique values, now get pik level
use indsample1.dta, replace
gen N=1
fcollapse (mean) y age (sum) N [fw=Npq], by(pikn) fast smart
rename N Npq
fmerge 1:1 pikn using mig5_pikqtime_1018_finalpiklist.dta, keepusing(pik) keep(master match) nogen
tempfile t1
save `t1', replace

use indsample1.dta, replace
gen czcnt=1
gen naics4dswitch=naics4dcnt-1 // switches will allow us to solve the problem of stayers in multiple cz having a nais4dcnt>1
fcollapse (sum) czcnt naics4dswitch, by(pikn) fast smart
fmerge 1:1 pikn using `t1', keep(match) nogen

* merge individual (time invariant characteristics)
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
gen czcnt1=(czcnt==1)
gen czcnt2=(czcnt==2)
gen czcnt3=(czcnt>=3)
gen naics4dswitch0=(naics4dswitch==0) // if no switches, means never changed inds within CZ
gen naics4dswitch1=(naics4dswitch==1)
gen naics4dswitch2=(naics4dswitch>=2)
save indsample1_pik.dta, replace

use indsample1_pik.dta, replace
cap label var y "y ($ y \geq 3800$)"
cap label var age "Age"
cap label var age2010q1 "Age in 2010Q1"
cap label var hisp "Hispanic"
cap label var czcnt1 "CZ cnt 1"
cap label var czcnt2 "CZ cnt 2"
cap label var czcnt3 "CZ cnt 3+"
cap label var naics4dswitch0 "Ind switch 0"
cap label var naics4dswitch1 "Ind switch 1"
cap label var naics4dswitch2 "Ind switch 2+"
cap label var pe "Mean PE"
replace sex=0 if sex==2
gen s3=1 if naics4dswitch==0 
gen s4=1 if naics4dswitch>0 
egen test=rowtotal(s3 s4)
assert test==1
drop test
gen e=exp(y) 
gen e3800=e>=3799
gen econd=e
gen qobserved=Npq
label var qobserved "Observed Q's (PIK-level)"

* Construct tables (columns 2-4)
qui eststo c2: estpost sum e3800 econd age sex forborn hisp   czcnt1 czcnt2 czcnt3  naics4dswitch0 naics4dswitch1 naics4dswitch2 qobserved [fw=Npq]
drbeclass,  addest(mean sd) addcount(count) eststo(dc2) 
count
estadd scalar dpikcount=r(N)
drbrclass N, countscalar(N)
estadd scalar pikcount=r(N)
qui sum e3800 [fw=Npq]
estadd scalar dNpq=r(N)
drbrclass N, countscalar(N)
estadd scalar Npq=r(N)

forval s=3/4 {
qui eststo c`s': estpost sum e3800 econd age sex forborn hisp   czcnt1 czcnt2 czcnt3  naics4dswitch0 naics4dswitch1 naics4dswitch2 qobserved if s`s'==1 [fw=Npq]
drbeclass,  addest(mean sd) addcount(count) eststo(dc`s') 
count if s`s'==1
estadd scalar dpikcount=r(N)
drbrclass N, countscalar(N)
estadd scalar pikcount=r(N)
qui sum e3800 [fw=Npq] if s`s'==1
estadd scalar dNpq=r(N)
drbrclass N, countscalar(N)
estadd scalar Npq=r(N)
}

* event study sample
use pikn qtime age lne akm_firm truecz truenaics4d if akm_firm~=. using tempevent2_m9ind.dta, replace
fmerge m:1 pikn using indsample1_pik.dta, keep(master match) nogen keepusing(sex forborn hisp)
replace sex=0 if sex==2
rename true* *
gen e=exp(lne)
gen e3800=1
gen econd=e
bys pikn cz: gen t=_n==1
by pikn: egen czcnt=sum(t)
gen czcnt1=(czcnt==1)
gen czcnt2=(czcnt==2)
gen czcnt3=(czcnt>=3)
drop t
bys pikn cz naics4d: gen t=_n==1
by pikn cz: egen naics4dcnt=sum(t) // naics4dcount is count of ind within same cz
gen naics4dswitch=naics4dcnt-1
gen naics4dswitch0=(naics4dswitch==0) // if no switches, means never changed inds within CZ
gen naics4dswitch1=(naics4dswitch==1)
gen naics4dswitch2=(naics4dswitch>=2)
drop t
fsort pikn qtime
by pikn: gen qobserved=_N
qui eststo c5: estpost sum e3800 econd age sex forborn hisp   czcnt1 czcnt2 czcnt3  naics4dswitch0 naics4dswitch1 naics4dswitch2 qobserved
drbeclass,  addest(mean sd) addcount(count) eststo(dc5) 
gunique pikn
estadd scalar dpikcount=r(unique)
drbrclass unique, countscalar(unique)
estadd scalar pikcount=r(unique)
qui sum e3800
estadd scalar dNpq=r(N)
drbrclass N, countscalar(N)
estadd scalar Npq=r(N)

* output
esttab dc2 dc3 dc4 dc5 using ${doutput}/d1tab1.csv, type c(mean sd (par)) label replace title("Sample descriptives") mtitles("Estim" "ind stay" "ind mov" "event" ) scalar("pikcount Unique PIKs" "Npq Person-quarter observations" "dpikcount Unique PIKs" "dNpq Person-quarter observations" "Npq Person-quarter observations")

********************************************************************************


********************************************************************************
// D1: OUTPUT 2
* Industry level means and counts
use $dataind/AKMests_fjc.dta, replace
replace naics4d=[XXXX] if naics4d==[YYYY]
rename alpha alpha_jc
rename psi psi_jc
gen N_j=1
fcollapse (mean) y_j=ybar_fjc alpha_j=akm_person psi_j=akm_firm (sum) N_j [fw=N_fjc], by(naics4d) fast smart
format N_j %40.0fc
drbvars y_j alpha_j psi_j N_j, replace countsvars(N_j)
export excel naics4d y_j alpha_j psi_j N_j using ${doutput}/d1tab2.xlsx, firstrow(variable) keepcellfmt sheet(1, replace) cell(A4)



********************************************************************************
// D1: OUTPUT 3
* Industry level means and counts 
use  naics4d m3A_fe m3A_pqcount m7A_fe m7A_pqcount using $output/Top59IndustryModelFEs.dta, replace
collapse (mean) psi_j=m3A_fe N_j=m3A_pqcount psi_jm7=m7A_fe, by(naics4d)
format N_j %40.0fc
replace naics4d=[XXXX] if naics4d==[YYYY]
rename N_j t
bys naics4d: egen N_j=sum(t)
collapse (mean) psi_j N_j psi_jm7 [fw=t], by(naics4d)
format N_j %40.0fc
drbvars psi_j psi_jm7 N_j, replace countsvars(N_j)
export excel naics4d psi_j psi_jm7 N_j using ${doutput}/d1tab3.xlsx, firstrow(variable) keepcellfmt sheet(1, replace) cell(A4)


********************************************************************************
// D1: OUTPUT 4
* Industry level means and counts - top59educ
use $output/Top59_t3.dta, replace
collapse (mean) alpha_j_hied alpha_j_loed psi_j_hied psi_j_loed Npq_j_loed Npq_j_hied , by(naics4d)
reshape long Npq_j_ alpha_j_ psi_j_, i(naics4d) j(ed) string
sort ed naics4d 
replace naics4d=[XXXX] if naics4d==[YYYY] 
bys ed naics4d: egen N_j=sum(Npq_j_)
collapse (mean) alpha_j_ psi_j_ N_j [fw=Npq_j_], by(ed naics4d)
format N_j %40.0fc
rename alpha_j_  alpha_j
rename psi_j_ psi_j
gen educ="H" if ed=="hied"
replace educ="L" if ed=="loed"
gsort -educ naics4d
drbvars alpha_j psi_j N_j, replace countsvars(N_j)
export excel educ naics4d alpha_j psi_j N_j using ${doutput}/d1tab4.xlsx, firstrow(variable) keepcellfmt sheet(1, replace) cell(A4)





********************************************************************************
// D1: OUTPUT 5
* Industry level regression coefficients
use naics4d cz m8A_fe m8A_pqcount using $output/Top59IndustryModelFEs.dta, replace
gen t=1
collapse (mean) m8A_fe (sum) m8A_pqcounta=t [fw=m8A_pqcount], by(naics4d) fast 
rename m8A_pqcounta m8A_pqcount
tempfile m8A
save `m8A', replace
* all these models 1 3 4 6 7 are at the industry level
use naics4d m1A_fe m3A_fe m4A_fe m6A_fe m7A_fe using $output/Top59IndustryModelFEs.dta, replace
collapse (mean) m1A_fe m3A_fe m4A_fe m6A_fe m7A_fe, by(naics4d)
tempfile m1to7
save `m1to7', replace
use $dataind/AKMests_fjc.dta, replace
gen N_j=1
fcollapse (mean) psi_jm9=akm_firm (sum) N_j [fw=N_fjc], by(naics4d) fast smart
format N_j %40.0fc
merge 1:1 naics4d using `m1to7', nogen assert(match)
merge n:1 naics4d using `m8A', assert(3) nogen
label var psi_jm9 "psi_j"
replace naics4d=[XXXX] if naics4d==[YYYY]
rename N_j t
bys naics4d: egen double N_j=sum(t)
collapse (mean) psi_jm9 *fe N_j [fw=t], by(naics4d)
* regressions
eststo clear
 foreach m in 1 3 4 6 7 8 {	
qui reg m`m'A_fe psi_jm9  [fw=N_j]
local Npq=e(N)
noi dis `Npq'
qui eststo fem`m': reg m`m'A_fe psi_jm9  [aw=N_j], vce(cluster naics4d)
qui sum m`m'A_fe [aw=N_j] if e(sample)==1
estadd scalar sd=r(sd)
estadd scalar Npq=`Npq'
}
qui sum psi_jm9  [aw=N_j]
qui estadd scalar sdm9=r(sd)
esttab fem*, se keep(psi_jm9) ar2 scalar(sd sdm9 Npq)
qui foreach m in 1 3 4 6 7 8 {
drbeclass fem`m',  addest(sd sdm9 r2_a) eststo(dfem`m')
}
esttab dfem* using ${doutput}/d1tab5.csv, se keep(psi_jm9) scalar(sd sdm9 r2_a) ///
 type replace title("Ouput 5: Regressions coefficients of psi_j on alternative specifications") ///
 mtitles("M1" "M3" "M4" "M6" "M7" "M8") 

 
********************************************************************************
// D1: OUTPUT 8
* CZ-industry group means 
use $dataind/AKMests_fjc.dta, replace
replace naics4d=[XXXX] if naics4d==[YYYY]
gen N_c=1
collapse (mean) alpha_c=akm_person psi_c=akm_firm (sum) N_c [fw=N_fjc], by(cz) fast 
tempfile cz
save `cz', replace
use $dataind/AKMests_fjc.dta, replace
replace naics4d=[XXXX] if naics4d==[YYYY]
gen N_j=1
fcollapse (mean) alpha_j=akm_person psi_j=akm_firm (sum) N_j [fw=N_fjc], by(naics4d) fast smart
format N_j %40.0fc
tempfile psij
save `psij', replace
use $dataind/AKMests_fjc.dta, replace
replace naics4d=[XXXX] if naics4d==[YYYY]
gen N_jc=1
collapse (mean) alpha_jc=akm_person psi_jc=akm_firm (sum) N_jc [fw=N_fjc], by(cz naics4d) fast 
merge n:1 naics4d using `psij', nogen assert(match)
merge n:1 cz using `cz', nogen assert(match)
format N_j N_jc %40.0fc
* fefe regressions
gen b_fefe=.
gen b_fefe_se=.
gen fefe_r2=.
levelsof cz
qui foreach cz in `r(levels)' {
if `cz'==0 {
	continue
}
qui reg psi_jc psi_j [fw=N_j] if cz==`cz', vce(cluster naics4d) //note weights here are national
replace b_fefe=_b[psi_j] if cz==`cz'
replace b_fefe_se=_se[psi_j] if cz==`cz'
replace fefe_r2=e(r2) if cz==`cz'
}
* pefe regressions
gen b_pefe=.
gen b_pefe_se=.
gen pefe_r2=.
levelsof cz
qui foreach cz in `r(levels)' {
if `cz'==0 {
	continue
}
qui reg alpha_jc psi_j [fw=N_j] if cz==`cz', vce(cluster naics4d) //note weights here are national
replace b_pefe=_b[psi_j] if cz==`cz'
replace b_pefe_se=_se[psi_j] if cz==`cz'
replace pefe_r2=e(r2) if cz==`cz'
}
* pepe regressions
gen b_pepe=.
gen b_pepe_se=.
gen pepe_r2=.
levelsof cz
qui foreach cz in `r(levels)' {
if `cz'==0 {
	continue
}
qui reg alpha_jc alpha_j [fw=N_j] if cz==`cz', vce(cluster naics4d) //note weights here are national
replace b_pepe=_b[alpha_j] if cz==`cz'
replace b_pepe_se=_se[alpha_j] if cz==`cz'
replace pepe_r2=e(r2) if cz==`cz'
}
bys cz: egen czpqcount=sum(N_jc)
save fig8data_jc.dta, replace
bys cz: keep if _n==1
keep cz b_* *r2 czpqcount N_c  alpha_c
label var b_fefe "slope of psijc on psij"
label var b_pefe "slope of ajc on psij"
label var b_pepe "slope of ajc on aj"
gen div=cz<=9
gsort b_fefe
gen g=1 if _n<=12
gsort div -b_fefe
replace g=3 if _n<=12
drop div
replace g=2 if g==.
label var g "1 small b_fe slope, 3 large b_fe slope"
save fig8data_c.dta, replace
use fig8data_jc.dta, replace
merge n:1 cz using fig8data_c.dta, keepusing(g) assert(3) nogen
save fig8data_jc.dta, replace

* select cz groups (pick size)
local gsize 10
use fig8data_c.dta, replace
cap drop g
gen div=cz<=9
gsort div b_fefe
gen g=1 if _n<=`gsize'
gsort div -b_fefe
replace g=3 if _n<=`gsize'
replace g=2 if g==.
drop div
levelsof cz if g==1, local(smallb) separate(,)
levelsof cz if g==3, local(largeb) separate(,)
* output
use fig8data_jc.dta, replace
drop g
gen g=1 if inlist(cz,`smallb')
replace g=3 if inlist(cz,`largeb')
replace g=2 if g==.
replace naics4d=9999 if inlist(naics4d,1119,1122,1124,1125,1131,1152,2121,2122,3117,3122,3131,3132,3169,3211,3271,3313,3322,3336,3343,3346,3351,3361,3362,3379,4832,4871,4911,4922,5122,5174,5232,6222,6223,6232,6239,7115,7121,9281)==1 // aggregate industries
gen N_jg=1
fcollapse (mean) alpha_jc psi_jc psi_j N_j (sum) N_jg [fw=N_jc], by(g naics4d)
format N_jg %50.0fc
rename N_jg Npq
drbvars alpha_jc psi_jc Npq, countsvars(Npq)  replace
export excel g naics4d alpha_jc psi_jc Npq using ${doutput}/d1tab8.xlsx, firstrow(variable) keepcellfmt sheet(1, replace)  cell(A4)
 
 
********************************************************************************
// D1: OUTPUT 11
* R2 descriptives 
use fig8data_c.dta, replace
sum fefe_r2 pefe_r2 pepe_r2 [fw=N_c ] 
eststo clear
qui eststo c1: estpost sum fefe_r2 pefe_r2 pepe_r2 [fw=N_c ], d 
drbeclass,  addest(mean sd skewness kurtosis) addcount(count) eststo(c1) 
esttab c1 using ${doutput}/d1tab11.csv,  type c(mean sd skewness kurtosis) replac



********************************************************************************
// D1: OUTPUT 12
* Regressions of psi_f-psi_j on industry experience 
use $dataind/AKMests_fjc.dta, replace
gen N_j=1
fcollapse (mean) alpha_j=akm_person psi_j=akm_firm (sum) N_j [fw=N_fjc], by(naics4d) fast smart
tempfile psij
save `psij', replace
use pik pikn qtime cz naics4d y age sex race hisp forborn using mig5_pikqtime_1018_top59A.dta, replace
merge 1:1 pik qtime using mig5_pikqtime_1018a.dta, keep(master match) keepusing(sein seinunit state) nogen
merge 1:1 pik qtime using mig5_pikqtime_1018b.dta, keep(1 3 4 5) keepusing(sein seinunit state) update nogen
drop pik
gen firmid=sein + "_" + seinunit
drop sein seinunit
cap assert firmid~=""
fsort pikn qtime
by pikn: egen firstage=min(age)
gen young=(firstage<=26) // first observed at age 26 or below (full history)
drop firstage
fmerge m:1 naics4d using `psij', keep(master match) nogen keepusing(psi_j)
merge m:1 cz naics4d firmid using $dataind/AKMests_fjc.dta, keep(master match) nogen keepusing(akm_firm)
gen df_m_psij=akm_firm-psi_j
* industry tenure
gen timeincurrentind=.
levelsof naics4d
foreach ind in `r(levels)' {
gen t1=naics4d==`ind'
bys pikn: gen timein`ind'=sum(t1)
replace timeincurrentind=timein`ind' if naics4d==`ind'
drop t1 timein`ind'
}
rename timeincurrentind iexp
qui sum df_m_psij if young==1
replace df_m_psij=r(mean) if df_m_psij==. & young==1
qui sum df_m_psij if young==0
replace df_m_psij=r(mean) if df_m_psij==. & young==0
assert df_m_psij~=.
eststo clear
qui eststo r1: reg df_m_psij c.iexp##c.iexp if young==1, vce(cluster naics4d)
gunique pikn if e(sample)==1
estadd scalar Np=r(unique)
estadd scalar Npq=r(N)
gunique state if e(sample)==1
estadd scalar nstates=r(unique)
qui sum df_m_psij if e(sample)==1
estadd scalar ymean=r(mean)
estadd scalar ysd=r(sd)
qui sum iexp if e(sample)==1
estadd scalar xmean=r(mean)
estadd scalar xsd=r(sd)
qui eststo r2: reghdfe df_m_psij c.iexp##c.iexp c.age##c.age if young==1, absorb(i.pikn i.cz i.qtime i.naics4d) vce(cluster naics4d)
qui eststo r3: reg df_m_psij c.iexp##c.iexp if young==0, vce(cluster naics4d)
gunique pikn if e(sample)==1
estadd scalar Np=r(unique)
estadd scalar Npq=r(N)
gunique state if e(sample)==1
estadd scalar nstates=r(unique)
qui sum df_m_psij if e(sample)==1
estadd scalar ymean=r(mean)
estadd scalar ysd=r(sd)
qui sum iexp if e(sample)==1
estadd scalar xmean=r(mean)
estadd scalar xsd=r(sd)
qui eststo r4: reghdfe df_m_psij c.iexp##c.iexp c.age##c.age if young==0, absorb(i.pikn i.cz i.qtime i.naics4d) vce(cluster naics4d)
qui foreach r in 1 2 3 4 {
drbeclass r`r',  addest(ymean ysd xmean xsd r2_a) eststo(dr`r')
}
* regression output
esttab dr* using ${doutput}/d1tab12.csv, se keep(*iexp*) scalar(ymean ysd xmean xsd r2_a) ///
 type replace title("Ouput 12: Regressions coefficients of psi_f-psi_j on industry experience") ///
 mtitles("young" "young" "old" "old") 
 
 
