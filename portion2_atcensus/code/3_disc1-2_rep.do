/*----------------------------------------------------------------------------*\

	Main Industry File
	
	Output Created Here:
		- Disc 1: tabs 9a, 9b, 10a, 10b
		- Disc 2: tabs 1, 3

	Input Datasets:
		- "$data/cw_cz_state.dta" <-- outside
		- "$data/cz_unionization.dta" <-- outside
		- "$data/cz_minwage.dta" <-- outside
		- "$yidata/mig5_pikqtime_1018_educacstop59_new.dta"
		- "$yidata/m5_ecf_seinunit.dta" <-- used in M9 AKM file
		

\*----------------------------------------------------------------------------*/

// Basic setup
cap log close
set more off
clear
clear matrix
clear mata
set linesize 85
set rmsg on

// Set directories
include ind_paths.do

// Data Switches
local d1_postAKM = 0
local d1_explanatory = 0
local d2_match_effects = 0
local d2_m9_2step_jc = 0

// Analysis Switches
local d1_means = 0
local d1_tables = 0
local d2_1a = 0
local d2_1b = 0
local d2_3 = 0


//------------------------------------------------------------------------------
// DATA
//------------------------------------------------------------------------------

// Post-AKM Processing
//------------------------------------------------------------------------------
if `d1_postAKM'==1 {

// M1A: OLS, industry FEs, time-varying controls
//------------------------------------------------------------------------------

foreach sample in A {
	import delimited "$data/M1_AKM_top59`sample'.txt", delimiter(tab) encoding(UTF-8) clear
	ren v1 naics4d
	ren v2 m1`sample'_fe
	ren v3 m1`sample'_pqcount
	tempfile m1`sample'
	save `m1`sample'', replace
}

// M3A: OLS with industry FEs, time-varying + time-invariant controls + educ
//------------------------------------------------------------------------------

foreach sample in A {
	import delimited "$data/M3_AKM_top59`sample'.txt", delimiter(tab) encoding(UTF-8) clear
	ren v1 naics4d
	ren v2 m3`sample'_fe
	ren v3 m3`sample'_pqcount
	tempfile m3`sample'
	save `m3`sample'', replace
}

// M4A: OLS, industry and cz FEs, time-varying + time-invariant controls + educ
//------------------------------------------------------------------------------

foreach sample in A {
	import delimited "$data/M4_AKM_top59`sample'.txt", delimiter(tab) encoding(UTF-8) clear
	ren v1 naics4d
	ren v2 m4`sample'_fe
	ren v3 m4`sample'_pqcount
	tempfile m4`sample'
	save `m4`sample'', replace
}

// M6A: AKM, worker and industry FEs, time-varying controls
//------------------------------------------------------------------------------

foreach sample in A {
	import delimited "$data/M6_AKM_top59`sample'.txt", delimiter(tab) encoding(UTF-8) clear
	ren v1 naics4d
	ren v2 m6`sample'_fe
	ren v3 m6`sample'_pqcount
	ren v4 m6`sample'_pe
	tempfile m6`sample'
	save `m6`sample'', replace
}

// M7A: AKM, worker and industry and cz FEs, time-varying controls
//------------------------------------------------------------------------------

foreach sample in A {
	import delimited "$data/M7_AKM_top59`sample'.txt", delimiter(tab) encoding(UTF-8) clear
	ren v1 naics4d
	ren v2 m7`sample'_fe
	ren v3 m7`sample'_pqcount
	ren v4 m7`sample'_pe
	tempfile m7`sample'
	save `m7`sample'', replace
}

// M8A: AKM, worker and industry-cz FEs, time-varying controls
//------------------------------------------------------------------------------

foreach sample in A {
	import delimited "$data/M8_AKM_top59`sample'.txt", delimiter(tab) encoding(UTF-8) clear
	ren v1 cz
	ren v2 naics4d
	ren v3 m8`sample'_fe
	ren v4 m8`sample'_pqcount
	ren v5 m8`sample'_pe
	tempfile m8`sample'
	save `m8`sample'', replace
}

// M9: AKM, worker and firm FEs, time-varying controls
//------------------------------------------------------------------------------
use "$dataind/AKMests_fjc.dta", replace

// Collapse firm-level to industry-level
preserve
collapse alpha psi [fw=N_fjc], by(naics4d)
ren (alpha psi) (alpha_j psi_j)
tempfile m9_j
save `m9_j', replace
restore
merge m:1 naics4d using `m9_j', assert(3) nogen
preserve
collapse (sum) N_fjc, by(naics4d)
ren N_fjc N_j
tempfile m9_N_j
save `m9_N_j', replace
restore
merge m:1 naics4d using `m9_N_j', assert(3) nogen

// Collapse firm-level to cz-industry-level
preserve
collapse alpha psi [fw=N_fjc], by(cz naics4d)
ren (alpha psi) (alpha_jc psi_jc)
tempfile m9_jc
save `m9_jc', replace
restore
merge m:1 cz naics4d using `m9_jc', assert(3) nogen
preserve
collapse (sum) N_fjc, by(cz naics4d)
ren N_fjc N_jc
tempfile m9_N_jc
save `m9_N_jc', replace
restore
merge m:1 cz naics4d using `m9_N_jc', assert(3) nogen
keep cz naics4d alpha_jc psi_jc N_jc alpha_j psi_j N_j
gduplicates drop
foreach var of varlist alpha_jc psi_jc N_jc alpha_j psi_j N_j {
	ren `var' m9full_`var'
}
tempfile m9full
save `m9full', replace

use `m1A', clear
merge 1:1 naics4d using `m3A', nogen
merge 1:1 naics4d using `m4A', nogen
merge 1:1 naics4d using `m6A', nogen
merge 1:1 naics4d using `m7A', nogen
merge 1:m naics4d using `m8A', nogen
merge 1:1 naics4d cz using `m9full', nogen

order cz, a(naics4d)
save "$output/Top59IndustryModelFEs.dta", replace
	
}

// Creates Explanatory Variables
//------------------------------------------------------------------------------
if `d1_explanatory'==1 {

//------------------------------------------------------------------------------
// Create RHS variables
//------------------------------------------------------------------------------

// Read in data
use "$output/Top59IndustryModelFEs.dta", clear
keep naics4d cz m9full_*
drop if mi(m9full_alpha_j)

// Indicator for non-top 50 divisions
gen byte Idiv = cz<10

// Indicators for each non-top 50 divisions
forvalues n = 1/9 {
	gen byte Idiv_`n' = cz==`n'
}

// Indicators for regions
preserve
use cz_1990 region using "$data/cw_cz_state.dta", clear
ren cz_1990 cz
duplicates drop
tempfile regions
save `regions', replace
restore
merge m:1 cz using `regions', keep(1 3) nogen
replace region = 1 if cz==1
replace region = 1 if cz==2
replace region = 2 if cz==3
replace region = 2 if cz==4
replace region = 3 if cz==5
replace region = 3 if cz==6
replace region = 3 if cz==7
replace region = 4 if cz==8
replace region = 4 if cz==9

// Average psi in CZ
preserve
sort cz naics4d
collapse (mean) m9full_psi_c=m9full_psi_jc [aw=m9full_N_jc], by(cz)
tempfile m9_psi_c
save `m9_psi_c', replace
restore
merge m:1 cz using `m9_psi_c', assert(1 3) nogen

// A. Average alpha in CZ
preserve
sort cz naics4d
keep cz m9full_alpha_jc m9full_N_jc
collapse (mean) m9full_alpha_c=m9full_alpha_jc [aw=m9full_N_jc], by(cz)
tempfile m9_alpha_c
save `m9_alpha_c', replace
restore
merge m:1 cz using `m9_alpha_c', assert(1 3) nogen

// B. Dispersion of alpha in CZ (fraction of workers in 1st and 5th nat'l quintiles)

preserve
local first=1
local files: dir "$dataind" files "AKMests_cz*.dta"
foreach file in `files' {
	di "Starting file `file'"
	local cz = regexr("`file'", "AKMests_", "")
	local cz = regexr("`cz'", ".dta", "")
	di "`cz'"
	use pikn akm_person using "$dataind/`file'", clear
	gduplicates drop
	tempfile temp_`cz'
	qui save `temp_`cz''
	if `first'==1 local czlist `cz'
	else local czlist `czlist' `cz'
	local first=0
}
local first=1
foreach c of local czlist {
	di "`c'"
	if `first'==1 use `temp_`c'', clear
	else append using `temp_`c''
	local first=0
}
/* isid pikn qtime */
gsort akm_person
gen ptile = int(100*(_n-1)/_N)+1
replace ptile = ptile[-1] if akm_person==akm_person[-1]
egen m9_p20 = max(akm_person) if ptile==20
egen m9_p80 = max(akm_person) if ptile==80
keep m9_p20 m9_p80
keep if (!mi(m9_p20) | !mi(m9_p80))
egen m9_alpha_p20 = max(m9_p20)
egen m9_alpha_p80 = max(m9_p80)
keep m9_alpha_p20 m9_alpha_p80
gduplicates drop
forvalues n = 1(3)4 {
 	local percentile = `n' * 20
	local m9_alpha_p`percentile' = m9_alpha_p`percentile'[1]
}
restore
gen m9_alpha_p20 = `m9_alpha_p20'
gen m9_alpha_p80 = `m9_alpha_p80'

preserve
local first=1
local files: dir "$dataind" files "AKMests_cz*.dta"
foreach file in `files' {
	di "Starting file `file'"
	local cz = regexr("`file'", "AKMests_", "")
	local cz = regexr("`cz'", ".dta", "")
	local cz = regexr("`cz'", "[czd]+", "")
	di "`cz'"
	use pikn akm_person using "$dataind/`file'", clear
	gduplicates drop
	gen cz = `cz'
	gen s_c_q1 = akm_person < `m9_alpha_p20'
	gen s_c_q5 = akm_person > `m9_alpha_p80'
	collapse (mean) s_c_q1 s_c_q5, by(cz)
	tempfile temp_`cz'
	qui save `temp_`cz''
	if `first'==1 local czlist `cz'
	else local czlist `czlist' `cz'
	local first=0
}
local first=1
di "`czlist'"
foreach c of local czlist {
	di "`c'"
	if `first'==1 use `temp_`c'', replace
	else append using `temp_`c''
	local first=0
}
tempfile scq1_scq5
save `scq1_scq5', replace
restore
merge m:1 cz using `scq1_scq5', nogen
gen s_c_q1q5 = s_c_q1 + s_c_q5
ren (s_c_q1 s_c_q5 s_c_q1q5) (s_alpha_q1 s_alpha_q5 s_alpha_q1q5)


// C. Expected average alpha in the CZ given national alpha distributions
//    by industry and the CZ's industry distributions (Reweight national 
//    industry distribution to match this CZ, then compute national mean alpha)
preserve
sort cz naics4d
keep naics4d m9full_alpha_jc m9full_N_jc
collapse (mean) m9full_alpha_jc [aw=m9full_N_jc], by(naics4d)
ren m9full_alpha_jc m9full_alpha_j
tempfile m9_alpha_j
save `m9_alpha_j', replace
restore
merge m:1 naics4d using `m9_alpha_j', assert(1 3) nogen

bys cz: egen m9_temp = total(m9full_N_jc)
bys cz: gen m9full_s_jc = m9full_N_jc / m9_temp
drop m9_temp
gen m9full_Ealpha_jc = m9full_alpha_j * m9full_s_jc
bys cz: egen m9full_Ealpha_c = total(m9full_Ealpha_jc)
drop m9full_Ealpha_jc


// D. Expected share of workers in the 1st and 5th quintiles in the CZ, 
// given national alpha dist'ns by industry and the CZ's industry dist'n
preserve
local first=1
local files: dir "$dataind" files "AKMests_cz*.dta"
foreach file in `files' {
	di "Starting file `file'"
	local cz = regexr("`file'", "AKMests_", "")
	local cz = regexr("`cz'", ".dta", "")
	di "`cz'"
	use pikn naics4d akm_person using "$dataind/`file'", clear
	gduplicates drop
	tempfile temp_`cz'
	qui save `temp_`cz''
	if `first'==1 local czlist `cz'
	else local czlist `czlist' `cz'
	local first=0
}
local first=1
foreach c of local czlist {
	di "`c'"
	if `first'==1 use `temp_`c'', clear
	else append using `temp_`c''
	local first=0
}

gsort naics4d akm_person
gen byte s_q1q5 = (akm_person <= `m9_alpha_p20') | (akm_person >= `m9_alpha_p80')
bys naics4d: egen n_alphaj_q1q5 = total(s_q1q5)
by naics4d: gen s_alphaj_q1q5 = n_alphaj_q1q5 / _N
keep naics4d s_alphaj_q1q5
duplicates drop
save `m9_alphaj_p20p80', replace

merge m:1 naics4d using `m9_alphaj_p20p80', nogen
gen m9full_Es_jc = s_alphaj_q1q5 * m9full_s_jc
bys cz: egen Es_alpha_q1q5 = total(m9full_Es_jc)
drop m9full_Es_jc s_alphaj_q1q5

// E. Mean psi_j in CZ, given industry composition
preserve
sort cz naics4d
keep naics4d m9full_psi_jc m9full_N_jc
collapse (mean) m9full_psi_j=m9full_psi_jc [aw=m9full_N_jc], by(naics4d)
tempfile m9_psi_j
save `m9_psi_j', replace
restore
merge m:1 naics4d using `m9_psi_j', assert(1 3) nogen

gen m9full_Epsi_jc = m9full_psi_j * m9full_s_jc
bys cz: egen m9full_Epsi_c = total(m9full_Epsi_jc)
drop m9full_Epsi_jc

// F. Dispersion of psi_f in CZ, given industry composition (Fraction of
//    workers in CZ in firms in the 1st and 5th nat'l quintiles')
preserve
use cz naics4d firmid akm_firm N_fjc using "$dataind/AKMests_fjc.dta", clear
bys cz naics4d: egen N_jc = total(N_fjc)
bys cz: egen N_c = total(N_fjc)
bys naics4d: egen N_j = total(N_fjc)
_pctile akm_firm, p(20, 80)
local firm_p20 = r(r1)
local firm_p80 = r(r2)
gen byte q1q5 = (akm_firm <= `firm_p20') | (akm_firm >= `firm_p80')
gen N_fjc_q1q5 = N_fjc * q1q5
bys cz: egen N_c_q1q5 = sum(N_fjc_q1q5)
gen s_psi_q1q5 = N_c_q1q5 / N_c
bys naics4d: egen N_j_q1q5 = sum(N_fjc_q1q5)
gen s_psij_q1q5 = N_j_q1q5 / N_j
keep cz naics4d s_psi_q1q5 s_psij_q1q5
duplicates drop
tempfile psi_s_q1q5
save `psi_s_q1q5', replace
restore
merge m:1 cz naics4d using `psi_s_q1q5', keep(1 3) nogen

//	Expected dispersion of psi_j in CZ, given industry composition
gen m9full_Es_jc = s_psij_q1q5 * m9full_s_jc
bys cz: egen Es_psi_q1q5 = total(m9full_Es_jc)
drop m9full_Es_jc s_psij_q1q5

// G. Unionization rate in CZ
preserve
use "$data/cz_unionization.dta", clear
ren cz59 cz
tempfile union
save `union'
restore
merge m:1 cz using `union', nogen

// H. Size of CZ
preserve
collapse (sum) m9full_N_jc, by(cz)
ren m9full_N_jc m9full_N_c
gen m9full_lnN_c = ln(m9full_N_c)
tempfile m9full_N_c
save `m9full_N_c'
restore
merge m:1 cz using `m9full_N_c', nogen

// I. Minimum wage in CZ/state averaged over a period
preserve
use "$data/cz_minwage.dta", clear
ren cz59 cz
gen lnmw = ln(mw)
drop mw
tempfile minwage
save `minwage'
restore
merge m:1 cz using `minwage', nogen

// Alternate CZ effect: mean(delta(f,j,c)-psi(j)) in each CZ
// (equivalently, can use "cz_alt_eff=m9full_psi_c - m9full_Epsi_c"")
preserve
use "$dataind/AKMests_fjc.dta", clear
collapse (mean) psi_j=akm_firm [aw=N_fjc], by(naics4d)
tempfile psij
save `psij'
restore
preserve
use "$dataind/AKMests_fjc.dta", clear
merge m:1 naics4d using `psij', nogen
gen diff = akm_firm - psi_j
collapse alt_cz_eff=diff [aw=N_fjc], by(cz)
tempfile altCZeff
save `altCZeff'
restore
merge m:1 cz using `altCZeff', nogen

// Alpha_jc, alpha_j, and alpha_c for high-education workers
preserve
use pikn qtime educacs if inlist(educacs,2,3,4) using "$yidata/mig5_pikqtime_1018_educacstop59_new.dta", clear
tempfile educ
save `educ', replace
restore
preserve
local datadir "$dataind"
local first=1
local files: dir "`datadir'" files "AKMests_cz*.dta"
foreach file in `files' {
  di "Starting file `file'"
  local cz = regexr("`file'", "AKMests_", "")
  local cz = regexr("`cz'", ".dta", "")
  di "`cz'"
  use `educ', clear
  merge 1:1 pikn qtime using "`datadir'/`file'", keep(3) nogen
  gen Npq=1
  collapse (mean) alpha_jc_hied=akm_person (sum) Npq_hied=Npq, by(naics4d)
  gen cz = regexr("`cz'", "[a-z]+", "")
  destring cz, replace
  tempfile cjmean_`cz'
  save `cjmean_`cz'', replace
  if `first'==1 local czlist `cz'
  else local czlist `czlist' `cz'
  local first=0
}

local first=1
foreach c of local czlist {
  if `first'==1 use `cjmean_`c'', clear
  else append using `cjmean_`c''
  local first=0
}
save "$dataind/AKMests_jc_hied", replace
restore
preserve
use "$dataind/AKMests_jc_hied", clear
ren Npq_hied Npq_jc_hied
tempfile alpha_jc_hied
save `alpha_jc_hied', replace
restore
merge 1:1 cz naics4d using `alpha_jc_hied', nogen

preserve
use "$dataind/AKMests_jc_hied", clear
collapse (mean) alpha_j_hied = alpha_jc_hied [aw=Npq_hied], by(naics4d)
tempfile alpha_j_hied
save `alpha_j_hied', replace
restore
merge m:1 naics4d using `alpha_j_hied', nogen
bys naics4d: egen Npq_j_hied = total(Npq_jc_hied)

preserve
use "$dataind/AKMests_jc_hied", clear
collapse (mean) alpha_c_hied = alpha_jc_hied [aw=Npq_hied], by(cz)
tempfile alpha_c_hied
save `alpha_c_hied', replace
restore
merge m:1 cz using `alpha_c_hied', nogen
bys cz: egen Npq_c_hied = total(Npq_jc_hied)

// Alpha_jc, alpha_j, and alpha_c for low-education workers
preserve
use pikn qtime educacs if inlist(educacs,1) using "$yidata/mig5_pikqtime_1018_educacstop59_new.dta", clear
tempfile educ
save `educ', replace
restore
preserve
local datadir "$dataind"
local first=1
local files: dir "`datadir'" files "AKMests_cz*.dta"
foreach file in `files' {
  di "Starting file `file'"
  local cz = regexr("`file'", "AKMests_", "")
  local cz = regexr("`cz'", ".dta", "")
  di "`cz'"
  use `educ', clear
  merge 1:1 pikn qtime using "`datadir'/`file'", keep(3) nogen
  gen Npq=1
  collapse (mean) alpha_jc_loed=akm_person (sum) Npq_loed=Npq, by(naics4d)
  gen cz = regexr("`cz'", "[a-z]+", "")
  destring cz, replace
  tempfile cjmean_`cz'
  save `cjmean_`cz'', replace
  if `first'==1 local czlist `cz'
  else local czlist `czlist' `cz'
  local first=0
}

local first=1
foreach c of local czlist {
  if `first'==1 use `cjmean_`c'', clear
  else append using `cjmean_`c''
  local first=0
}
tempfile alpha_jc_loed
save "$dataind/AKMests_jc_loed", replace
restore
preserve
use "$dataind/AKMests_jc_loed", clear
ren Npq_loed Npq_jc_loed
tempfile alpha_jc_loed
save `alpha_jc_loed', replace
restore
merge 1:1 cz naics4d using `alpha_jc_loed', nogen

preserve
use "$dataind/AKMests_jc_loed", clear
ren Npq_loed Npq_jc_loed
tempfile alpha_jc_loed
save `alpha_jc_loed', replace
restore
merge 1:1 cz naics4d using `alpha_jc_loed', nogen

preserve
use "$dataind/AKMests_jc_loed", clear
collapse (mean) alpha_j_loed = alpha_jc_loed [aw=Npq_loed], by(naics4d)
tempfile alpha_j_loed
save `alpha_j_loed', replace
restore
merge m:1 naics4d using `alpha_j_loed', nogen
bys naics4d: egen Npq_j_loed = total(Npq_jc_loed)


// Create psi_jc psi_j betas
//------------------------------------------------------------------------------
levelsof cz, local(czlist)
local first=1
foreach cz of local czlist{
	preserve
	di "`cz'"
	keep if cz==`cz'
	reg m9full_psi_jc m9full_psi_j [aw=m9full_N_j]
	gen b_pjc_pj = _b[m9full_psi_j]
	gen se_pjc_pj = _se[m9full_psi_j]
	keep cz b_pjc_pj se_pjc_pj
	duplicates drop
	tempfile temp_`cz'
	save `temp_`cz''
	restore
	local first=0
}
preserve
local first=1
di "`czlist'"
foreach c of local czlist {
	di "`c'"
	if `first'==1 use `temp_`c'', replace
	else append using `temp_`c''
	local first=0
}
tempfile betas
save `betas'
restore
merge m:1 cz using `betas', nogen


// Create alpha_jc psi_j betas
//------------------------------------------------------------------------------
levelsof cz, local(czlist)
local first=1
foreach cz of local czlist{
	preserve
	di "`cz'"
	keep if cz==`cz'
	reg m9full_alpha_jc m9full_psi_j [aw=m9full_N_j]
	gen b_ajc_pj = _b[m9full_psi_j]
	gen se_ajc_pj = _se[m9full_psi_j]
	keep cz b_ajc_pj se_ajc_pj
	duplicates drop
	tempfile temp_`cz'
	save `temp_`cz''
	restore
	local first=0
}
preserve
local first=1
di "`czlist'"
foreach c of local czlist {
	di "`c'"
	if `first'==1 use `temp_`c'', replace
	else append using `temp_`c''
	local first=0
}
tempfile betas
save `betas'
restore
merge m:1 cz using `betas', nogen


// Create alpha_jc alpha_j betas
//------------------------------------------------------------------------------
levelsof cz, local(czlist)
local first=1
foreach cz of local czlist{
	preserve
	di "`cz'"
	keep if cz==`cz'
	reg m9full_alpha_jc m9full_alpha_j [aw=m9full_N_j]
	gen b_ajc_aj = _b[m9full_alpha_j]
	gen se_ajc_aj = _se[m9full_alpha_j]
	keep cz b_ajc_aj se_ajc_aj
	duplicates drop
	tempfile temp_`cz'
	save `temp_`cz''
	restore
	local first=0
}
preserve
local first=1
di "`czlist'"
foreach c of local czlist {
	di "`c'"
	if `first'==1 use `temp_`c'', replace
	else append using `temp_`c''
	local first=0
}
tempfile betas
save `betas'
restore
merge m:1 cz using `betas', nogen


// Create alpha_jc psi_j betas for high-education sample
//------------------------------------------------------------------------------
levelsof cz, local(czlist)
local first=1
foreach cz of local czlist{
	preserve
	di "`cz'"
	keep if cz==`cz'
	reg alpha_jc_hied m9full_psi_j [aw=m9full_N_j]
	gen b_ajc_pj_hied = _b[m9full_psi_j]
	keep cz b_ajc_pj_hied
	duplicates drop
	tempfile temp_`cz'
	save `temp_`cz''
	restore
	local first=0
}
preserve
local first=1
di "`czlist'"
foreach c of local czlist {
	di "`c'"
	if `first'==1 use `temp_`c'', replace
	else append using `temp_`c''
	local first=0
}
tempfile betas
save `betas'
restore
merge m:1 cz using `betas', nogen


// Create alpha_jc alpha_j betas for high-education sample
//------------------------------------------------------------------------------
levelsof cz, local(czlist)
local first=1
foreach cz of local czlist{
	preserve
	di "`cz'"
	keep if cz==`cz'
	reg alpha_jc_hied m9full_alpha_j [aw=m9full_N_j]
	gen b_ajc_aj_hied = _b[m9full_alpha_j]
	keep cz b_ajc_aj_hied
	duplicates drop
	tempfile temp_`cz'
	save `temp_`cz''
	restore
	local first=0
}
preserve
local first=1
di "`czlist'"
foreach c of local czlist {
	di "`c'"
	if `first'==1 use `temp_`c'', replace
	else append using `temp_`c''
	local first=0
}
tempfile betas
save `betas'
restore
merge m:1 cz using `betas', nogen


// Create alpha_jc psi_j betas for low-education sample
//------------------------------------------------------------------------------
levelsof cz, local(czlist)
local first=1
foreach cz of local czlist{
	preserve
	di "`cz'"
	keep if cz==`cz'
	reg alpha_jc_loed m9full_psi_j [aw=m9full_N_j]
	gen b_ajc_pj_loed = _b[m9full_psi_j]
	keep cz b_ajc_pj_loed
	duplicates drop
	tempfile temp_`cz'
	save `temp_`cz''
	restore
	local first=0
}
preserve
local first=1
di "`czlist'"
foreach c of local czlist {
	di "`c'"
	if `first'==1 use `temp_`c'', replace
	else append using `temp_`c''
	local first=0
}
tempfile betas
save `betas'
restore
merge m:1 cz using `betas', nogen


// Create alpha_jc alpha_j betas for high-education sample
//------------------------------------------------------------------------------
levelsof cz, local(czlist)
local first=1
foreach cz of local czlist{
	preserve
	di "`cz'"
	keep if cz==`cz'
	reg alpha_jc_loed m9full_alpha_j [aw=m9full_N_j]
	gen b_ajc_aj_loed = _b[m9full_alpha_j]
	keep cz b_ajc_aj_loed
	duplicates drop
	tempfile temp_`cz'
	save `temp_`cz''
	restore
	local first=0
}
preserve
local first=1
di "`czlist'"
foreach c of local czlist {
	di "`c'"
	if `first'==1 use `temp_`c'', replace
	else append using `temp_`c''
	local first=0
}
tempfile betas
save `betas'
restore
merge m:1 cz using `betas', nogen


// Add high-education sample psi's
//------------------------------------------------------------------------------
preserve
use pikn qtime educacs if inlist(educacs,2,3,4) using "$yidata/mig5_pikqtime_1018_educacstop59_new.dta", clear
tempfile educ
save `educ', replace
restore
preserve
local datadir "$dataind"
local first=1
local files: dir "`datadir'" files "AKMests_cz*.dta"
foreach file in `files' {
  di "Starting file `file'"
  local cz = regexr("`file'", "AKMests_", "")
  local cz = regexr("`cz'", ".dta", "")
  di "`cz'"
  use `educ', clear
  merge 1:1 pikn qtime using "`datadir'/`file'", keep(3) nogen
  gen Npq=1
  collapse (mean) psi_jc_hied=akm_firm (sum) Npq_jc_hied=Npq, by(naics4d)
  gen cz = regexr("`cz'", "[a-z]+", "")
  destring cz, replace
  tempfile cjmean_`cz'
  save `cjmean_`cz'', replace
  if `first'==1 local czlist `cz'
  else local czlist `czlist' `cz'
  local first=0
}

local first=1
foreach c of local czlist {
  if `first'==1 use `cjmean_`c'', clear
  else append using `cjmean_`c''
  local first=0
}
save "$dataind/psi_jc_hied", replace
restore
preserve
use "$dataind/psi_jc_hied", clear
tempfile psi_jc_hied
save `psi_jc_hied', replace
restore
merge 1:1 cz naics4d using `psi_jc_hied', nogen

preserve
use "$dataind/psi_jc_hied.dta", clear
collapse (mean) psi_j_hied = psi_jc_hied [aw=Npq_jc_hied], by(naics4d)
tempfile psi_j_hied
save `psi_j_hied', replace
restore
merge m:1 naics4d using `psi_j_hied', nogen

preserve
use "$dataind/psi_jc_hied.dta", clear
collapse (mean) psi_c_hied = psi_jc_hied [aw=Npq_jc_hied], by(cz)
tempfile psi_c_hied
save `psi_c_hied', replace
restore
merge m:1 cz using `psi_c_hied', nogen


// Add low-education sample psi's
//------------------------------------------------------------------------------
preserve
use pikn qtime educacs if inlist(educacs,1) using "$yidata/mig5_pikqtime_1018_educacstop59_new.dta", clear
tempfile educ
save `educ', replace
restore
preserve
local datadir "$dataind"
local first=1
local files: dir "`datadir'" files "AKMests_cz*.dta"
foreach file in `files' {
  di "Starting file `file'"
  local cz = regexr("`file'", "AKMests_", "")
  local cz = regexr("`cz'", ".dta", "")
  di "`cz'"
  use `educ', clear
  merge 1:1 pikn qtime using "`datadir'/`file'", keep(3) nogen
  gen Npq=1
  collapse (mean) psi_jc_loed=akm_firm (sum) Npq_jc_loed=Npq, by(naics4d)
  gen cz = regexr("`cz'", "[a-z]+", "")
  destring cz, replace
  tempfile cjmean_`cz'
  save `cjmean_`cz'', replace
  if `first'==1 local czlist `cz'
  else local czlist `czlist' `cz'
  local first=0
}

local first=1
foreach c of local czlist {
  if `first'==1 use `cjmean_`c'', clear
  else append using `cjmean_`c''
  local first=0
}
save "$dataind/psi_jc_loed.dta", replace
restore
preserve
use "$dataind/psi_jc_loed.dta", clear
tempfile psi_jc_loed
save `psi_jc_loed', replace
restore
merge 1:1 cz naics4d using `psi_jc_loed', nogen
preserve
use "$dataind/psi_jc_loed.dta", clear
collapse (mean) psi_j_loed = psi_jc_loed [aw=Npq_jc_loed], by(naics4d)
tempfile psi_j_loed
save `psi_j_loed', replace
restore
merge m:1 naics4d using `psi_j_loed', nogen


// Label variables
lab var Idiv "Idiv"
lab var m9full_alpha_c "alpha_c"
lab var s_alpha_q1q5 "share_alpha_q1q5"
lab var m9full_Ealpha_c "Ealpha_c"
lab var m9full_Epsi_c  "Epsi_c"
lab var s_psi_q1q5 "share_psi_q1q5"
lab var membership "union membership"
lab var coverage "union coverage"
lab var m9full_N_c "N_c"
lab var m9full_lnN_c "ln(N_c)"
lab var lnmw "ln(min wage)"
lab var b_pjc_pj "d psi_jc/d psi_j"
lab var b_ajc_pj "d alpha_jc/d psi_j"
lab var b_ajc_pj_hied "d alpha_jc_hied/d psi_j"
lab var b_ajc_pj_loed "d alpha_jc_loed/d psi_j"
lab var b_ajc_aj "d alpha_jc/d alpha_j"
lab var b_ajc_aj_hied "d alpha_jc_hied/d alpha_j"
lab var b_ajc_aj_loed "d alpha_jc_loed/d alpha_j"
lab var alpha_j_hied "alpha_j_hied"
lab var Npq_j_hied "Npq_j_hied"
lab var alpha_j_loed "alpha_j_loed"
lab var Npq_j_loed "Npq_j_loed"
lab var m9full_psi_j "psi_j"
lab var psi_j_hied "psi_j_hied"
lab var psi_j_loed "psi_j_loed"


// Save output
//------------------------------------------------------------------------------
sort naics4d cz
save "$output/Top59_t3.dta", replace

cap log close
}

// Saving match effects
//------------------------------------------------------------------------------
if `d2_match_effects'==1 {
	
	// Match effect (pikn-firmid average residual; match=0 within CZ)
	local files: dir "$dataind" files "AKMests_cz*.dta"
	foreach file in `files' {
		di "Starting file `file'"
		local cz = regexr("`file'", "AKMests_", "")
		local cz = regexr("`cz'", ".dta", "")
		di "`cz'"
		use "$dataind/`file'", clear
		cap drop match
		sort pikn firmid
		by pikn firmid: egen match = mean(r)
		save "$dataind/`file'", replace
	}

}

// Collapse 2step Estimates to JC-level
if `d2_m9_2step_jc'==1 {
	
	// 4jc
	use "$data2step/AKMests_2step.dta", clear
	bys czone naics4d: egen N_4jc_2step = total(joblength)
	collapse (mean) psi_4jc_2step=akm_firm alpha_4jc_2step=akm_person N_4jc_2step [aw=joblength], by(czone naics4d)
	xtile ving_4jc = psi_4jc_2step, n(20)
	xtile vingw_4jc = psi_4jc_2step [fw=N_4jc_2step], n(20)
	
	// 2jc
	order czone
	gen naics2d = floor(naics4d/100), b(naics4d)
	preserve
		collapse (mean) psi_2jc_2step=psi_4jc_2step alpha_2jc_2step=alpha_4jc_2step [fw=N_4jc_2step], by(czone naics2d)
		tempfile psi_2jc_2step
		save `psi_2jc_2step'
	restore
	merge m:1 czone naics2d using `psi_2jc_2step', assert(3) nogen
	preserve
		collapse (sum) N_2jc_2step=N_4jc_2step, by(czone naics2d)
		tempfile N_2jc_2step
		save `N_2jc_2step'
	restore
	merge m:1 czone naics2d using `N_2jc_2step', assert(3) nogen
	preserve
		keep czone naics2d *_2jc_2step
		duplicates drop
		xtile ving_2jc = psi_2jc_2step, n(20)
		xtile vingw_2jc = psi_2jc_2step [fw=N_2jc_2step], n(20)
		keep czone naics2d ving*
		tempfile ving_2jc
		save `ving_2jc'
	restore
	merge m:1 czone naics2d using `ving_2jc', assert(3) nogen
	tempfile AKMests_2stepfull_jc
	save `AKMests_2stepfull_jc'
	
	// Rest of CZ-ind variables
	preserve
	use czone naics4d akm_person akm_firm xb r using "$data2step/M9twostep_step1xbr.dta", replace
	gen naics2d = floor(naics4d/100), b(naics4d)
	gen y = akm_person + akm_firm + xb + r
	merge m:1 czone naics4d using `AKMests_2stepfull_jc', assert(3) nogen keepusing(psi_2jc_2step)
	gen df_m_psi2jc = akm_firm - psi_2jc_2step
	collapse (mean) y_2jc=y xb_2jc=xb r_2jc=r df_m_psi2jc_2jc=df_m_psi2jc, by(czone naics2d)
	tempfile yxbr
	save `yxbr'
	restore
	merge m:1 czone naics2d using `yxbr', assert(3) nogen
	
	// Save CZ-ind AKM ests
	isid czone naics4d
	save "$data2step/AKMests_2stepfull_jc.dta", replace
	
}

//------------------------------------------------------------------------------
// ANALYSIS
//------------------------------------------------------------------------------

// D1: Tab 9a Mean/SD
//------------------------------------------------------------------------------
if `d1_means'==1 {
	
	use "$output/Top59_t3.dta", clear
	keep cz Idiv* region m9full_alpha_c s_alpha_q1 s_alpha_q5 s_alpha_q1q5 m9full_psi_c m9full_Ealpha_c Es_alpha_q1q5 m9full_Epsi_c s_psi_q1q5 Es_psi_q1q5 membership coverage m9full_N_c m9full_lnN_c lnmw alt_cz_eff b_pjc_pj b_ajc_pj b_ajc_aj b_ajc_pj_hied b_ajc_aj_hied b_ajc_pj_loed b_ajc_aj_loed
	ren (m9full_alpha_c m9full_psi_c m9full_Ealpha_c m9full_Epsi_c m9full_N_c m9full_lnN_c) (alpha_c psi_c Ealpha_c Epsi_c N_c lnN_c)
	duplicates drop
	
	// Generate table
	gen Means = uniform()
	reg Means alpha_c Ealpha_c alt_cz_eff s_alpha_q1q5 Es_alpha_q1q5 psi_c Epsi_c s_psi_q1q5 Es_psi_q1q5 membership coverage lnmw lnN_c b_pjc_pj b_ajc_pj b_ajc_aj b_ajc_pj_hied b_ajc_aj_hied b_ajc_pj_loed b_ajc_aj_loed [aw=N_c], ro nocons
	drbeclass
	eststo r1
	reg Means Epsi_c [aw=N_c], ro nocons
	drbeclass
	eststo r2
	estadd summ : *
	
	// Save
	esttab r* using "${output}/disc/t3t7_means.csv", main(mean) aux(sd) nostar nonotes replace  title("Table 3-7 - Means")
	
}

// D1: Tab 9a/9b/10a/10b Regressions
//------------------------------------------------------------------------------
if `d1_tables'==1 {
	
	// Tab 9a (Bivariate)
	//--------------------------------------------------------------------------
	foreach lhs in b_pjc_pj b_ajc_pj b_ajc_aj {
	
	// Table labels
	if "`lhs'"=="b_pjc_pj" local t 3
	if "`lhs'"=="b_ajc_pj" local t 4
	if "`lhs'"=="b_ajc_aj" local t 6
	
	// Read in data
	use "$output/Top59_t3.dta", clear
	keep cz Idiv_? region m9full_alpha_c s_alpha_q1 s_alpha_q5 s_alpha_q1q5 m9full_psi_c m9full_Ealpha_c Es_alpha_q1q5 m9full_Epsi_c s_psi_q1q5 Es_psi_q1q5 membership coverage m9full_N_c m9full_lnN_c lnmw alt_cz_eff b_pjc_pj b_ajc_pj b_ajc_pj_hied b_ajc_pj_loed b_ajc_aj b_ajc_aj_hied b_ajc_aj_loed
	ren (m9full_alpha_c m9full_psi_c m9full_Ealpha_c m9full_Epsi_c m9full_N_c m9full_lnN_c) (alpha_c psi_c Ealpha_c Epsi_c N_c lnN_c)
	duplicates drop
	eststo clear
	estimates clear
	clear results
	
	// Controls
	local div9 "Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9"
	local div9region "Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9 i.region"
	
	// RHS variables
	#delimit ;
	local single_vars "alpha_c" "alt_cz_eff" "s_alpha_q1q5" "psi_c" "Ealpha_c" 
		"Es_alpha_q1q5" "Epsi_c" "s_psi_q1q5" "membership" "coverage" 
		"lnN_c" "lnmw" "Es_psi_q1q5" "b_pjc_pj" 
		"b_ajc_pj" "b_ajc_aj";
	#delimit cr
	
	// Variations
	local n=1
	foreach rhs in "`single_vars'" {
		
		// Base
		reg `lhs' `rhs' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		qui sum `rhs' [aw=N_c]
		estadd scalar mean = r(mean)
		estadd scalar sd = r(sd)
		local ++n
		
		// 9 Division-CZ indicators
		reg `lhs' `rhs' `div9' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n

		// 9 Division-CZ indicators + Region indicators
		reg `lhs' `rhs' `div9region' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
	
	}
	local n = `n'-1
	
	// Output
	forval r = 1/`n' {
		drbeclass top59100t`t'm`r', addest(r2_a rmse mean sd) eststo(dtop59100t`t'm`r')
	}
	noi esttab dtop59100t`t'm*, cells(b(star) se(par)) drop(1.region _cons) indicate("Division-CZ dummies=Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9" "Region dummies=2.region 3.region 4.region") stats(N r2_a rmse mean sd) star(* 0.10 ** 0.05 *** 0.01) title("Table `t' - Top59 100%") nonotes

	noi esttab dtop59100t`t'm* using "${output}/disc/tab`t'a.csv", cells(b(star) se(par)) drop(1.region _cons) indicate("Division-CZ dummies=Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9" "Region dummies=2.region 3.region 4.region") stats(N r2_a rmse mean sd) star(* 0.10 ** 0.05 *** 0.01) title("Table `t' - Top59 100%") nonotes replace
	
	
	
	
}

	// Tab 9b (Multivariate)
	//--------------------------------------------------------------------------
	foreach lhs in b_pjc_pj b_ajc_pj b_ajc_aj {
	
	// Table labels
	if "`lhs'"=="b_pjc_pj" local t 3
	if "`lhs'"=="b_ajc_pj" local t 4
	if "`lhs'"=="b_ajc_aj" local t 6
	
	// Read in data
	use "$output/Top59_t3.dta", clear
	keep cz Idiv_? region m9full_alpha_c s_alpha_q1 s_alpha_q5 s_alpha_q1q5 m9full_psi_c m9full_Ealpha_c Es_alpha_q1q5 m9full_Epsi_c s_psi_q1q5 Es_psi_q1q5 membership coverage m9full_N_c m9full_lnN_c lnmw alt_cz_eff b_pjc_pj b_ajc_pj b_ajc_pj_hied b_ajc_pj_loed b_ajc_aj b_ajc_aj_hied b_ajc_aj_loed
	ren (m9full_alpha_c m9full_psi_c m9full_Ealpha_c m9full_Epsi_c m9full_N_c m9full_lnN_c) (alpha_c psi_c Ealpha_c Epsi_c N_c lnN_c)
	duplicates drop
	eststo clear
	estimates clear
	clear results
	
	// Controls
	local div9 "Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9"
	local div9region "Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9 i.region"
	
	// RHS variables
	#delimit ;
		
	local multiple_vars 
		"alpha_c Ealpha_c" 
		"s_alpha_q1q5 Es_alpha_q1q5" 
		"psi_c Epsi_c" 
		"s_psi_q1q5 Es_psi_q1q5" 
		"alpha_c psi_c" 
		"alpha_c s_alpha_q1q5" 
		"psi_c s_psi_q1q5" 
		"alpha_c psi_c s_alpha_q1q5 s_psi_q1q5" 
		"Ealpha_c Epsi_c" 
		"Ealpha_c Es_alpha_q1q5" 
		"Ealpha_c Epsi_c Es_alpha_q1q5 Es_psi_q1q5" 
		"lnmw coverage" 
		"Ealpha_c Epsi_c Es_alpha_q1q5 Es_psi_q1q5 lnmw coverage" ;
	#delimit cr
	
	// Variations
	local n=1
	foreach rhs in "`multiple_vars'" {
		
		// Base
		reg `lhs' `rhs' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
		
		// 9 Division-CZ indicators
		reg `lhs' `rhs' `div9' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n

		// 9 Division-CZ indicators + Region indicators
		reg `lhs' `rhs' `div9region' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
	
	}
	local n = `n'-1
	
	// Output
	forval r = 1/`n' {
		drbeclass top59100t`t'm`r', addest(r2_a rmse mean sd) eststo(dtop59100t`t'm`r')
	}
	noi esttab dtop59100t`t'm*, cells(b(star) se(par)) drop(1.region _cons) indicate("Division-CZ dummies=Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9" "Region dummies=2.region 3.region 4.region") stats(N r2_a rmse mean sd) star(* 0.10 ** 0.05 *** 0.01) title("Table `t' - Top59 100%") nonotes

	noi esttab dtop59100t`t'm* using "${output}/disc/tab`t'b.csv", cells(b(star) se(par)) drop(1.region _cons) indicate("Division-CZ dummies=Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9" "Region dummies=2.region 3.region 4.region") stats(N r2_a rmse mean sd) star(* 0.10 ** 0.05 *** 0.01) title("Table `t' - Top59 100%") nonotes replace
	
}

	// Tab 10a (Bivariate)
	//--------------------------------------------------------------------------
	foreach lhs in b_ajc_pj b_ajc_aj {
	
	// Table labels
	if "`lhs'"=="b_ajc_pj" local t 5
	if "`lhs'"=="b_ajc_aj" local t 7
	
	// Read in data
	use "$output/Top59_t3.dta", clear
	keep cz Idiv_? region m9full_alpha_c s_alpha_q1 s_alpha_q5 s_alpha_q1q5 m9full_psi_c m9full_Ealpha_c Es_alpha_q1q5 m9full_Epsi_c s_psi_q1q5 Es_psi_q1q5 membership coverage m9full_N_c m9full_lnN_c lnmw alt_cz_eff b_pjc_pj b_ajc_pj b_ajc_pj_hied b_ajc_pj_loed b_ajc_aj b_ajc_aj_hied b_ajc_aj_loed
	ren (m9full_alpha_c m9full_psi_c m9full_Ealpha_c m9full_Epsi_c m9full_N_c m9full_lnN_c) (alpha_c psi_c Ealpha_c Epsi_c N_c lnN_c)
	duplicates drop
	eststo clear
	estimates clear
	clear results
	
	// Controls
	local div9 "Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9"
	local div9region "Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9 i.region"
	
	// RHS variables
	#delimit ;
	local single_vars "alpha_c" "Ealpha_c" "alt_cz_eff" "s_alpha_q1q5" "Es_alpha_q1q5" 
		"psi_c" "Epsi_c" "s_psi_q1q5" "Es_psi_q1q5" "membership" 
		"coverage" "lnmw" "lnN_c" "b_ajc_pj_hied" "b_ajc_pj_loed" 
		"b_ajc_aj_hied" "b_ajc_aj_loed";
	#delimit cr
	
	// Variations
	local n=1
	foreach rhs in "`single_vars'" {
		
		// Base
		reg `lhs'_hied `rhs' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
		
		// 9 Division-CZ indicators
		reg `lhs'_hied `rhs' `div9' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n

		// 9 Division-CZ indicators + Region indicators
		reg `lhs'_hied `rhs' `div9region' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
	
	}
	foreach rhs in "`single_vars'" {
		
		// Base
		reg `lhs'_loed `rhs' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
		
		// 9 Division-CZ indicators
		reg `lhs'_loed `rhs' `div9' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n

		// 9 Division-CZ indicators + Region indicators
		reg `lhs'_loed `rhs' `div9region' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
	
	}
	local n = `n'-1
	
	// Output
	forval r = 1/`n' {
		drbeclass top59100t`t'm`r',  addest(r2_a rmse) eststo(dtop59100t`t'm`r')
	}
	noi esttab dtop59100t`t'm*, cells(b(star) se(par)) drop(1.region _cons) indicate("Division-CZ dummies=Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9" "Region dummies=2.region 3.region 4.region") stats(N r2_a rmse) star(* 0.10 ** 0.05 *** 0.01) title("Table `t' - Top59 100%") nonotes

	noi esttab dtop59100t`t'm* using "${output}/disc/tab`t'a.csv", cells(b(star) se(par)) drop(1.region _cons) indicate("Division-CZ dummies=Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9" "Region dummies=2.region 3.region 4.region") stats(N r2_a rmse) star(* 0.10 ** 0.05 *** 0.01) title("Table `t' - Top59 100%") nonotes replace
	
}


	// Tab 10b (Multivariate)
	//--------------------------------------------------------------------------
	foreach lhs in b_ajc_pj b_ajc_aj {
	
	// Table labels
	if "`lhs'"=="b_ajc_pj" local t 5
	if "`lhs'"=="b_ajc_aj" local t 7
	
	// Read in data
	use "$output/Top59_t3.dta", clear
	keep cz Idiv_? region m9full_alpha_c s_alpha_q1 s_alpha_q5 s_alpha_q1q5 m9full_psi_c m9full_Ealpha_c Es_alpha_q1q5 m9full_Epsi_c s_psi_q1q5 Es_psi_q1q5 membership coverage m9full_N_c m9full_lnN_c lnmw alt_cz_eff b_pjc_pj b_ajc_pj b_ajc_pj_hied b_ajc_pj_loed b_ajc_aj b_ajc_aj_hied b_ajc_aj_loed
	ren (m9full_alpha_c m9full_psi_c m9full_Ealpha_c m9full_Epsi_c m9full_N_c m9full_lnN_c) (alpha_c psi_c Ealpha_c Epsi_c N_c lnN_c)
	duplicates drop
	eststo clear
	estimates clear
	clear results
	
	// Controls
	local div9 "Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9"
	local div9region "Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9 i.region"
	
	// RHS variables
	#delimit ;		
	local multiple_vars 
		"alpha_c Ealpha_c" 
		"s_alpha_q1q5 Es_alpha_q1q5" 
		"psi_c Epsi_c" 
		"s_psi_q1q5 Es_psi_q1q5" 
		"alpha_c psi_c" 
		"alpha_c s_alpha_q1q5" 
		"psi_c s_psi_q1q5" 
		"alpha_c psi_c s_alpha_q1q5 s_psi_q1q5" 
		"Ealpha_c Epsi_c" 
		"Ealpha_c Es_alpha_q1q5" 
		"Ealpha_c Epsi_c Es_alpha_q1q5 Es_psi_q1q5" 
		"lnmw coverage" 
		"Ealpha_c Epsi_c Es_alpha_q1q5 Es_psi_q1q5 lnmw coverage" ;
	#delimit cr
	
	// Variations
	local n=1
	foreach rhs in "`multiple_vars'" {
		
		// Base
		reg `lhs'_hied `rhs' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
		
		// 9 Division-CZ indicators
		reg `lhs'_hied `rhs' `div9' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n

		// 9 Division-CZ indicators + Region indicators
		reg `lhs'_hied `rhs' `div9region' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
	
	}
	foreach rhs in "`multiple_vars'" {
		
		// Base
		reg `lhs'_loed `rhs' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
		
		// 9 Division-CZ indicators
		reg `lhs'_loed `rhs' `div9' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n

		// 9 Division-CZ indicators + Region indicators
		reg `lhs'_loed `rhs' `div9region' [aw=N_c], cluster(cz)
		qui estimates store top59100t`t'm`n'
		local ++n
	
	}
	local n = `n'-1
	
	// Output
	forval r = 1/`n' {
		drbeclass top59100t`t'm`r',  addest(r2_a rmse) eststo(dtop59100t`t'm`r')
	}
	noi esttab dtop59100t`t'm*, cells(b(star) se(par)) drop(1.region _cons) indicate("Division-CZ dummies=Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9" "Region dummies=2.region 3.region 4.region") stats(N r2_a rmse) star(* 0.10 ** 0.05 *** 0.01) title("Table `t' - Top59 100%") nonotes

	noi esttab dtop59100t`t'm* using "${output}/disc/tab`t'b.csv", cells(b(star) se(par)) drop(1.region _cons) indicate("Division-CZ dummies=Idiv_1 Idiv_2 Idiv_3 Idiv_4 Idiv_5 Idiv_6 Idiv_7 Idiv_8 Idiv_9" "Region dummies=2.region 3.region 4.region") stats(N r2_a rmse) star(* 0.10 ** 0.05 *** 0.01) title("Table `t' - Top59 100%") nonotes replace
	
}
}

// D2: Tab 1 Summary of SEs of the betas [3 estimates]
//------------------------------------------------------------------------------
if `d2_1a'==1 {
	
	// Log
	log using "$root/support/6_disc8_1.log", text replace
	
	matrix T = J(3,1,.)
	matrix rownames T = pjc_pj ajc_aj ajc_pj
	matrix colnames T = mean_sq
	
	use "$output/Top59_t3.dta", clear
	keep cz se_pjc_pj se_ajc_aj se_ajc_pj m9full_N_c
	duplicates drop
	
	foreach v of var se_pjc_pj se_ajc_aj se_ajc_pj {
		gen `v'_2 = `v'^2, a(`v')
	}
	
	// se_pjc_pj
	qui sum se_pjc_pj_2 [aw=m9full_N_c]
	qui matrix T[1,1] = r(mean)
	mat list T
	
	// se_ajc_aj
	qui sum se_ajc_aj_2 [aw=m9full_N_c]
	qui matrix T[2,1] = r(mean)
	mat list T
	
	// se_ajc_pj
	qui sum se_ajc_pj_2 [aw=m9full_N_c]
	qui matrix T[3,1] = r(mean)
	mat list T

cap log close
}

// D2: Tab 1 Summary stats for underlying AKM [8 estimates + SEs for coeffs]
//------------------------------------------------------------------------------
if `d2_1b'==1 {
	
	// Log
	log using "$root/support/6_disc8_3.log", text replace
	
	// AKM estimates [sample PQ-weighted]
	//--------------------------------------------------------------------------	
	matrix T = J(7,2,.)
	matrix rownames T = b_r2 d_r2 e_sd f_n g_reg h_reg i_r2
	matrix colnames T = est_coeff se
	
	use "$dataind/AKMests_fjc.dta", replace
	
	// b. R2 of regression of firm FEs on 4-digit industry dummies
	qui areg akm_firm [aw=N_fjc], a(naics4d)
	qui matrix T[1,1] = e(r2)
	matrix list T
	
	// e. SD of match effect
	local first=1
	local files: dir "$dataind" files "AKMests_cz*.dta"
	foreach file in `files' {
		di "Starting file `file'"
		local cz = regexr("`file'", "AKMests_", "")
		local cz = regexr("`cz'", ".dta", "")
		di "`cz'"
		use "$dataind/`file'", clear
		keep pikn akm_person firmid naics4d match
		if `first'==1 {
			local czs `cz'
		}
		else if `first'==0 {
			local czs `czs' `cz'
		}
		tempfile temp_`cz'
		save `temp_`cz'', replace
		local first=0
	}
	
	di "`czs'"

	local first=1
	foreach cz in `czs' {
		if `first'==1 {
			di "`cz'"
			use `temp_`cz'', clear
		}
		else if `first'==0 {
			append using `temp_`cz''
		}
		local first=0
	}
	qui sum match
	qui matrix T[3,1] = r(sd)
	matrix list T
	
	// d. R2 of regression of PEs on 4-digit industry dummies
	drop match
	reghdfe akm_person, a(naics4d)
	qui matrix T[2,1] = e(r2)
	matrix list T
	
	// i. R2 of regression of person FEs on firm dummies
	*fcollapse (first) akm_person (count) Npq=akm_person, by(pikn firmid) fast smart
	areg akm_person, a(firmid)
	qui matrix T[7,1] = e(r2)
	matrix list T
	
	// f. Share of workers who never switched establishments
	// Note: sample 1 - want PQ count, sort takes ~1.5 hours
	keep pikn firmid
	sort pikn firmid
	by pikn firmid: gen temp = 1 if _n==1
	by pikn: egen n_estabs = total(temp)
	cou if n_estabs==1
	qui matrix T[4,1] = r(N)
	matrix list T
	
	// g. coeff+SE of reg alpha_f on firm FE
	use "$dataind/AKMests_fjc.dta", replace
	preserve
	collapse (mean) psi_j=akm_firm [aw=N_fjc], by(naics4d)
	tempfile psi_j
	save `psi_j'
	restore
	merge m:1 naics4d using `psi_j', assert(3) nogen
	gen df_m_psij = akm_firm - psi_j
	gen byte N_f = 1
	collapse (mean) akm_firm akm_person df_m_psij (sum) N_f [fw=N_fjc], by(firmid)
	reg akm_person akm_firm [aw=N_f]
	qui matrix T[5,1] = _b[akm_firm]
	qui matrix T[5,2] = _se[akm_firm]
	matrix list T
	
	// h. coeff+SE of reg alpha_f on hierarchy effect
	reg akm_person df_m_psij [aw=N_f]
	qui matrix T[6,1] = _b[df_m_psij]
	qui matrix T[6,2] = _se[df_m_psij]
	matrix list T
	
	clear
	svmat T
	drbvars T1 T2, replace
	mkmat T1 T2, mat(S)
	matrix rownames S = b_r2 d_r2 e_sd f_n g_reg h_reg i_r2
	matrix colnames S = est_coeff se
	mat list S
	
	// i. r2_alpha_firm
	local first=1
	local files: dir "$dataind" files "AKMests_cz*.dta"
	foreach file in `files' {
		di "Starting file `file'"
		local cz = regexr("`file'", "AKMests_", "")
		local cz = regexr("`cz'", ".dta", "")
		di "`cz'"
		use "$dataind/`file'", clear
		keep pikn akm_person firmid naics4d match
		if `first'==1 {
			local czs `cz'
		}
		else if `first'==0 {
			local czs `czs' `cz'
		}
		tempfile temp_`cz'
		save `temp_`cz'', replace
		local first=0
	}
	
	di "`czs'"

	local first=1
	foreach cz in `czs' {
		if `first'==1 {
			di "`cz'"
			use `temp_`cz'', clear
		}
		else if `first'==0 {
			append using `temp_`cz''
		}
		local first=0
	}
	
	sort pikn firmid
	by pikn firmid: gen Npq=_N
	by pikn firmid: keep if _n==1
	areg akm_person [aw=Npq], a(firmid)
	ereturn list
	

cap log close
}


// D2: Tab 3 Industry psi_j on Location psi_j [1 coeff + SE]
//------------------------------------------------------------------------------
if `d2_3'==1 {
	
	// Log
	log using "$root/support/6_disc8_4.log", text replace
	
	* PSIJ COMPARISONS ACROSS MODELS (LOC VS IND PAPERS)
	* nat akm model ground-up cz effects (baseline, 100pct sample)
	use "$data2step/AKMests_2stepfull_jc.dta", replace
	gen double N=1
	fcollapse (mean) psi_j_loc=psi_4jc_2step (sum) N [fw=N_4jc_2step], by(naics4d)
	rename N N_j_loc
	tempfile fe_loc
	save `fe_loc', replace

	* industry paper, j-level psi
	use "$dataind/AKMests_fjc.dta", replace
	gen double N_j=1
	collapse (mean)  psi_j_ip=akm_firm (sum) N_j [fw=N_fjc], by(naics4d) fast 
	rename N_j N_j_ip
	merge 1:1 naics4d using `fe_loc'
	format N* %10.0fc
	
	// Regressions
	eststo clear
	qui eststo r1: reg psi_j_ip psi_j_loc [aw=N_j_loc]
	qui eststo r2: reg psi_j_loc psi_j_ip [aw=N_j_loc]
	esttab r?, se r2 ar2 label replace type title("Psi J Comparison Across Models") mtitles("psi_j_ip" "psi_j_loc")  scalar(rmse)

	forval r=1/2 {
	drbeclass r`r',  addest(r2 r2_a rmse) eststo(r`r')
	}
	esttab r?, se r2 ar2 label replace type title("Psi J Comparison Across Models") mtitles("psi_j_ip" "psi_j_loc")  scalar(rmse)
	
cap log close
}


cap log close


