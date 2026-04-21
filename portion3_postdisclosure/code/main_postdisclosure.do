*Program to run all analyses involving disclosed LEHD results. Runs after external
*ACS analyses and internal LEHD analyses


cap log close postlog
log using main_postdisclosure.log, replace text name(postlog)
clear *

// Stop Stata from looking to site archive for (sometimes outdated) extensions
sysdir set SITE "~"
creturn list
global mainhome "~/replication/industries"
global home "${mainhome}/portion3_postdisclosure" // change to reflect local settings
global code "${home}/code"
global results "${home}/results"
global raw "${home}/origdata"
global disclosed "${home}/disclosed"
global scratch "${home}/intermediate" // For intermediate files that we might want 

global acsraw "${mainhome}/portion1_prepforcensus/origdata"
global acsoutput "${mainhome}/portion1_prepforcensus/intermediate" // data files created by phase 1 of the project

global disclosure1 "${disclosed}/Yi_1_tabs_T13T26_edited.xlsx"
global disclosure2 "${disclosed}/Yi_1_tabs_T13T26_2_edited.xlsx"
global disclosure3 "${disclosed}/Yi_1_tabs_T13T26_3_edited.xlsx"

/* 
  
Uses Stata packages:
cleanplots:  <net install cleanplots, from(http://fmwww.bc.edu/RePEc/bocode/c)>
plotplain:   <net install gr0070>
grc1leg2:    <net install grc1leg2, from(http://digital.cgdev.org/doc/stata/MO/Misc)
esttab:      <ssc install estout, replace>
*/
which grc1leg2
which esttab

do make_ind_data
do merge_acs_lehd

do f1
do f2
do f3
do f4
do f5
do f6 
do f7
do f89
do appfig1

do t2
do t3
do t4
do t6
do apptab2



log close postlog
