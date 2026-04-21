*merge acs psis and worker skills to LEHD summary data 

cap log close
log using merge_acs_lehd.log, replace

* this is the public release summary file of data by industry
* extracted from main sheet from industryeffects.xlsx (dc may 2023)

use ${scratch}/ind_data, clear
desc
sum

* next pull in naics_lehd -- this has naics and naicsp (lehd version)

merge 1:1 naics using ${raw}/naics_lehd, assert(3) nogen

desc

* now pull in data from indeffects_naicsp -- created by phi_acs.do
merge m:1 naicsp using ${acsoutput}/indeffects_naicsp

// Note: NAICS 5211 is central banking - not in ACS.
tab naics if _merge==1
drop if _merge==1


sum [w=npq]


save ${scratch}/merge_acs_lehd, replace
