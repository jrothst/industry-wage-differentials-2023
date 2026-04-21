/*----------------------------------------------------------------------------*\
REPLICATION CODE

Disclosure 3, tabs 1 2 3 

input files:
$dataind/AKMests_fjc.dta
$yidata/tempevent2_m9ind.dta
$dataind/AKMests_cz*.dta
\*----------------------------------------------------------------------------*/
set linesize 255

// Set directories
include ind_paths.do
cd $yidata

*******************************************************************************
* data cleaning
* psi js (from firm effects, full sample 1)
use "$dataind/AKMests_fjc.dta", replace
gen naics2d = floor(naics4d/100)
gen naics3d = floor(naics4d/10)
foreach d in 2 3 4 {
preserve
fcollapse (mean) psi_j`d'd=akm_firm [fw=N_fjc], by(naics`d'd) fast smart
xtile qpsi_j`d'd  =psi_j`d'd, n(4)
xtile q20psi_j`d'd=psi_j`d'd, n(20)
tempfile psi`d'd
save `psi`d'd', replace
restore
}
foreach d in 2 3 4 {
preserve
fcollapse (mean) psi_jc`d'd=akm_firm [fw=N_fjc], by(naics`d'd cz) fast smart
xtile qpsi_jc`d'd  =psi_jc`d'd, n(4)
xtile q20psi_jc`d'd=psi_jc`d'd, n(20)
tempfile psijc`d'd
save `psijc`d'd', replace
restore
}

* SAMPLE ndustry movers (4-digit)
use if akm_firm~=. using tempevent2_m9ind.dta, replace
cap drop *m9*
cap drop df_m_psij df_m_psijc d_df_m_psij d_df_m_psijc
gen naics2dorig = floor(naics4dorig/100)
gen naics2ddest = floor(naics4ddest/100)
gen naics3dorig = floor(naics4dorig/10)
gen naics3ddest = floor(naics4ddest/10)
gen naics2dswitch=(naics2dorig~=naics2ddest) if edate==0
gen naics3dswitch=(naics3dorig~=naics3ddest) if edate==0

*merge psi_js
foreach d in 2 3 4 {
rename naics`d'dorig naics`d'd
merge m:1 naics`d'd using `psi`d'd', assert(match) nogen
rename psi_j`d'd psi_j`d'dorig
rename qpsi_j`d'd  qpsi_j`d'dorig
rename q20psi_j`d'd q20psi_j`d'dorig
rename naics`d'd naics`d'dorig 
}
foreach d in 2 3 4 {
rename naics`d'ddest naics`d'd
merge m:1 naics`d'd using `psi`d'd', assert(match) nogen
rename psi_j`d'd psi_j`d'ddest
rename qpsi_j`d'd  qpsi_j`d'ddest
rename q20psi_j`d'd q20psi_j`d'ddest
rename naics`d'd naics`d'ddest 
}
*merge psi_jcs
foreach d in 2 3 4 {
rename czorig cz 
rename naics`d'dorig naics`d'd
merge m:1 cz naics`d'd using `psijc`d'd', keep(master match) nogen
rename psi_jc`d'd psi_jc`d'dorig
rename qpsi_jc`d'd  qpsi_jc`d'dorig
rename q20psi_jc`d'd q20psi_jc`d'dorig
rename naics`d'd naics`d'dorig 
rename cz czorig
}
foreach d in 2 3 4 {
rename czdest cz 
rename naics`d'ddest naics`d'd
merge m:1 cz naics`d'd using `psijc`d'd', keep(master match) nogen
rename psi_jc`d'd psi_jc`d'ddest
rename qpsi_jc`d'd  qpsi_jc`d'ddest
rename q20psi_jc`d'd q20psi_jc`d'ddest
rename naics`d'd naics`d'ddest 
rename cz czdest
}
foreach d in 2 3 4 {
gen d_psij`d'd=psi_j`d'ddest-psi_j`d'dorig
gen d_psijc`d'd=psi_jc`d'ddest-psi_jc`d'dorig
}
* group, sort well
egen eventid=group(pikn czorig)
sort eventid pikn qtime
by eventid pikn: gen akm_firmorig=akm_firm[1]
by eventid pikn: gen akm_firmdest=akm_firm[10]
// Add match effect 
	local files: dir "$dataind" files "AKMests_cz*.dta"
	foreach file in `files' {
		di "Starting file `file'"
		local cz = regexr("`file'", "AKMests_", "")
		local cz = regexr("`cz'", ".dta", "")
		di "`cz'"
		merge 1:1 pikn qtime using "$dataind/`file'", keep(1 3 4) keepusing(match) update nogen
	}
sort eventid pikn qtime
foreach d in 2 3 4 {
gen hfj`d'd= akm_firm-psi_j`d'dorig if edate<0
replace hfj`d'd= akm_firm-psi_j`d'ddest if edate>=0
assert hfj`d'd~=.
gen hfjc`d'd= akm_firm-psi_jc`d'dorig if edate<0
replace hfjc`d'd= akm_firm-psi_jc`d'ddest if edate>=0
assert hfjc`d'd~=.
by eventid pikn: gen d_hfj`d'd=hfj`d'd-hfj`d'd[_n-1] if edate==0
by eventid pikn: gen d_hfjc`d'd=hfjc`d'd-hfjc`d'd[_n-1] if edate==0
}	
by eventid pikn: gen d_y_m_xb_t4=y_m_xb[_n+4]-y_m_xb[_n-1] if edate==0
by eventid pikn: gen d_akm_res_t4=akm_res[_n+4]-akm_res[_n-1] if edate==0
by eventid pikn: gen d_match=match-match[_n-1] if edate==0	
sort eventid pikn qtime
save tempevent2_m9ind_fixed.dta, replace


********************************************************************************
// D3: OUTPUT 1
* BINSCATTER SLOPES

* 4-digit movers 
use if naics4dswitch==1 & edate==0 using tempevent2_m9ind_fixed.dta, replace
fcollapse (mean) d_y_m_xb* d_akm_res* d_hfj*d d_psij?d d_match (count) Npq=d_y_m_xb, by(q20psi_j4dorig q20psi_j4ddest) fast smart
eststo clear
qui eststo r1: reg d_y_m_xb_t4    d_psij4d 
qui eststo r2: reg d_akm_res_t4   d_psij4d 
qui eststo r3: reg d_match        d_psij4d 
esttab r?, se title(4 digit slopes)
forval r=1/3 {
drbeclass r`r',  eststo(dc`r')
}
esttab dc1 dc2 dc3 using ${doutput}/d3tab1.csv, keep(d_psij4d) se replace

* 3-digit movers
use if edate==0 using tempevent2_m9ind_fixed.dta, replace 
fcollapse (mean) d_y_m_xb* d_akm_res* d_hfj*d d_psij?d d_match (count) Npq=d_y_m_xb, by(q20psi_j3dorig q20psi_j3ddest  naics3dswitch) fast smart
gen d_psij=d_psij3d if naics3dswitch==1
eststo clear
qui eststo r1: reg d_hfj3d       d_psij if naics3dswitch==1
forval r=1/1 {
drbeclass r`r',  eststo(dc`r')
}
esttab dc1 using ${doutput}/d3tab1.csv, keep(d_psij) se append

* 2-digit movers
use if edate==0 using tempevent2_m9ind_fixed.dta, replace 
fcollapse (mean) d_y_m_xb* d_akm_res* d_hfj*d d_psij?d d_match (count) Npq=d_y_m_xb, by(q20psi_j2dorig q20psi_j2ddest  naics2dswitch) fast smart
gen d_psij=d_psij2d if naics2dswitch==1
eststo clear
qui eststo r1: reg d_hfj2d       d_psij if naics2dswitch==1
forval r=1/1 {
drbeclass r`r',  eststo(dc`r')
}
esttab dc1 using ${doutput}/d3tab1.csv, keep(d_psij4d) se append


********************************************************************************
// D3: OUTPUT 2
* Event study 
use tempevent2_m9ind_fixed.dta, replace 
collapse (mean) y_m_xb akm_res hfj4d (count) Npq=y_m_xb, by(qpsi_j4dorig qpsi_j4ddest edate) fast
drbvars y_m_xb akm_res hfj4d Npq, countsvars(Npq)  replace
export excel qpsi_j4dorig qpsi_j4ddest edate y_m_xb akm_res hfj4d Npq using ${doutput}/d3tab2.xlsx, firstrow(variable) keepcellfmt sheet(1, replace)  cell(A4)


********************************************************************************
// D3: OUTPUT 3
* BINSCATTER vingtile means
use if naics4dswitch==1 & edate==0 using tempevent2_m9ind_fixed.dta, replace
fcollapse (mean) d_y_m_xb* d_akm_res* d_hfj*d d_psij?d d_match (count) Npq=d_y_m_xb, by(q20psi_j4dorig q20psi_j4ddest) fast smart
drbvars d_y_m_xb d_akm_res d_hfj4d Npq, countsvars(Npq)  replace
export excel q20psi_j4dorig q20psi_j4ddest d_y_m_xb d_akm_res d_hfj4d Npq using ${doutput}/d3tab3.xlsx, firstrow(variable) keepcellfmt sheet(1, replace)  cell(A4)
********************************************************************************


