
*read acs extract, merge on cz information
*uses files puma2000_cz and puma2010_cz created by puma2000_prep.do and puma2010_prep.do
*   these files have 1 record per puma and up to 10 cz's (9 in 2010 file) with allocation shares

cap log close
log using readacs.log, replace

cap program drop readoneyear
program define readoneyear
  args year
  
    di "Starting `year'"
	use ${scratch}/extract`year'.dta, clear

	keep serialno sporder st puma mig migsp migpuma agep sex RAC1P schl sch cit pobp ///
	     waob yoep decade relp semp wagp pernp wkhp wkw wrk esr cow fcowp fsemp fwagp ///
	     dis FOD1P hisp indp occp pwgtp naicsp
    // Convert serial no to string if needed
    cap confirm string variable serialno
    if _rc!=0 tostring serialno, replace format(%13.0f)
	//renames

	rename st state
	rename mig mobility
	rename pwgtp pweight
	rename migsp state_ly
	rename migpuma puma_ly
	rename agep age
	rename relp relhead
	rename RAC1P race1
	rename pobp pob
	rename waob region_birth
	rename cit citizen
	rename semp selfearn
	rename wagp wagsal
	rename pernp earnings
	rename wkhp hrswkly
	rename wrk workly
	rename dis disabilitty
	rename FOD1P field_degree
	rename indp ind
	rename occp occ
	rename fcowp cowflag
	rename fsemp selfearnflag
	rename fwagp wagsalflag


	gen female=(sex==2)
	tab age female, row col
	tab relhead female, row col

	gen black=(race1==2)
	gen white=(race1==1)
	gen asian=(race1==6)
	gen hispanic=(hisp>=2)

	tab race1 hispanic, row col

	gen wnh=white*(1-hispanic)
	gen bnh=black*(1-hispanic)
	gen anh=asian*(1-hispanic)
	gen other_race=1-hispanic-wnh-bnh-anh

	gen racegroup=1*wnh+2*bnh+3*hispanic+4*anh+5*other_race
	tab racegroup race1, row col


	tab citizen
	gen imm=(citizen>=4)

	tab region_birth imm, row col


	gen educ=(schl-3)
	replace educ=0 if educ<0
	replace educ=11 if schl==15
	replace educ=12 if (schl>=16) & (schl<=18)
	replace educ=13 if schl==19
	replace educ=14 if schl==20
	replace educ=16 if schl==21
	replace educ=18 if schl==22
	replace educ=20 if schl>=23

	tab educ female if age>=25, row col
	tab educ hispanic if age>=25 , row col
	tab educ imm if age>=25, row col




	*var wkw is weeks worked category
	*1=50-52, 2=48-49, 3=40-47, 4=27-39, 5=14-26, 6=under 14

	*lets check how wkw varies across gender by education
	replace wkw=0 if wkw==.
	tab wkw female, row col 
	tab wkw female if educ<=11, row col 
	tab wkw female if educ==12, row col
	tab wkw female if educ>12 & educ<16, row col
	tab wkw female if educ==16 , row col
	tab wkw female if educ>16 , row col

	//assign midpoints
	gen weeksly=0
	replace weeksly=52 if wkw==1
	replace weeksly=48 if wkw==2
	replace weeksly=44 if wkw==3
	replace weeksly=33 if wkw==4
	replace weeksly=20 if wkw==5
	replace weeksly=7 if wkw==6


	//now hours last year and hourly wages
	replace hrswkly=0 if hrswkly==.
	tab hrswkly female if hrswkly>0, col

	replace wagsal=0 if wagsal==.
	gen hoursly=hrswkly*weeksly

	gen wage=wagsal/hoursly if hoursly>0 & wagsal>0 
	*winsorized wage
	gen twage=wage
	replace twage=5 if wage>0 & wage<5
	replace twage=500 if wage>500 & twage~=. 

	gen poshours=(hoursly>0)
	replace poshours=0 if hoursly==.

	tab poshours workly, row col
	tab poshours workly if female==0, row col
	tab poshours workly if female==1, row col



	sum wage twage, detail

	sum hrswkly weeksly hoursly wage twage if female==0
	corr hrswkly weeksly hoursly wage twage if female==0

	sum hrswkly weeksly hoursly wage twage if female==1
	corr hrswkly weeksly hoursly wage twage if female==1
 


	//mobility since last year (ACS mig variable renamed mobility)
	//1=same house 2=out of country ly 3=moved within US

	tab mobility imm, row col

	gen movely=0
	replace movely=1 if mobility>=2

	replace state_ly=state if movely==0
	replace puma_ly=puma if movely==0

	tab state_ly movely if state_ly<100, row

	//special coding for puma 77777  (new orleans parishes)
	//2010 and 2011 ACS Only - put everyone in puma 1801
	if `year'<=2011 {
  	  sum if puma==77777
	  replace puma=1801 if state==22 & puma==77777
	  replace puma_ly=1801 if state_ly==22 & puma_ly==77777
    }

    // Merge to PUMA list
    sort state puma serialno sporder
    isid state puma serialno sporder
    if `year'<=2011 {
      merge m:1 state puma using ${scratch}/puma2000_cz, assert(2 3) 
    }
    if `year'>2011 {
      merge m:1 state puma using ${scratch}/puma2010_cz, assert(2 3) 
      gen cz10=.
      gen af10=.
    }
	tab _merge
	list state puma if _merge==2
	keep if _merge==3
	drop _merge

	tab ncz 
	sum cz? cz10 af? af10 afsum
	
    sort serialno sporder
    isid serialno sporder

    // Arbitrary tiebreakers - these reproduce what was sent to Census in 2021
    /* 
    merge 1:1 serialno sporder using ${raw}/tiebreak/tiebreak`year', assert(1 3)
    assert twage==. if _merge==1
    drop _merge
    sort sequence serialno sporder
    */    
	save ${scratch}/simple`year', replace
end

readoneyear 2010
readoneyear 2011
readoneyear 2012
readoneyear 2013
readoneyear 2014
readoneyear 2015
readoneyear 2016
readoneyear 2017
readoneyear 2018

log close
