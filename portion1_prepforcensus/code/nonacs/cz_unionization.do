// Union stats come from CPS ORG, as produced by Barry Hirsch and David Macpherson
// http://unionstats.com/
//
// Cite:
// Barry T. Hirsch and David A. Macpherson, "Union Membership and Coverage 
// Database from the Current Population Survey: Note," Industrial and Labor 
// Relations Review, Vol. 56, No. 2, January 2003, pp. 349-54 (updated annually 
// at unionstats.com).
//

cap log close
log using cz_unionization.log, replace

// Read in CZ definitions
import excel using "${raw}/cz-codes-1990.xls", clear firstrow sheet(CZLMA903) // County-CZ crosswalk
rename NameoflargestplaceinCommuti CZname
destring CountyFIPSCode, gen(fips) force
drop CountyFIPSCode
*keep fips CZ90 CountyName Population1990
replace fips=12086 if fips==12025 // Miami-Dade
replace fips=02232 if fips==02231 // Skagway-Yakutat-Angoon, AK
destring CZ90, gen(cz)
drop CZ90
tempfile CZs
save `CZs'
// And get CZ names
 sort cz fips
 isid cz fips
 by cz: keep if _n==1
 keep cz CZname
 tempfile CZnames
 save `CZnames'

// Read in top 50 CZs
use ${raw}/cw_cz_division_nottop50, clear
keep cz division top50
gen cz59=cz if top50==1
replace cz59=division if top50==0
merge 1:1 cz using `CZnames', keep(1 3)
assert _merge==3 if top50==1
drop _merge
replace CZname="Rest of division"+string(division) if top50==0
sort cz59 cz
by cz59: assert _n==1 if top50==1
*by cz59: drop if _n>1
tempfile topczs
save `topczs'


// Read in county-MSA crosswalk for 2003 definitions
import excel using "${raw}/cbsa03_msa99.xls", clear firstrow
keep FIPS State County_Name CBSA_2003_Code CSA_2003_Code CSA_2003_Title
destring FIPS, gen(fips) force
drop if fips==.
replace fips=12086 if fips==12025 // Miami-Dade
replace fips=02232 if fips==02231 // Skagway-Yakutat-Angoon, AK
drop if fips>56999
drop FIPS
tempfile msas03
save `msas03'

// Read in county-MSA crosswalk for 2013 definitions
import excel using "${raw}/CBSA2013.xlsx", clear firstrow cellrange(A3:L1885)
gen FIPS=FIPSStateCode+FIPSCountyCode
destring FIPS, gen(fips) force
rename CBSACode CBSA_2013_Code
rename CSACode CSA_2013_Code
rename CBSATitle CBSA_2013_Title
rename CSATitle CSA_2013_Title
rename CountyCountyEquivalent County_Name
rename StateName State
keep fips State County_Name *_2013_*
drop if fips==.
replace fips=12086 if fips==12025 // Miami-Dade
replace fips=02232 if fips==02231 // Skagway-Yakutat-Angoon, AK
drop if fips>56999
tempfile msas13
save `msas13'


// Read in unionization from 2010-2018
local rangeA "A5:I933"
local rangeB "A5:I1001"
forvalues y=10/18 {
	if `y'<=14 local range "`rangeA'"
	if `y'>=15 local range "`rangeB'"
	import excel using "${raw}/Hirsch/Met_1`y'.xlsx", cellrange(`range') clear firstrow
	keep if Sector=="Total"
	drop Sector
	gen len=length(Code)
	gen type="CSA" if len==3
	replace type="MSA" if len==5
	drop len
	keep Code MetropolitanArea Obs Employment Mem Cov type
	foreach v of varlist Obs Employment Mem Cov {
		rename `v' `v'_20`y'
	}
	tempfile union20`y'
	save `union20`y''
}
// Make two merged versions of the unionization data: One for 2010-2014, the other 2015-2018
use `union2010'
merge 1:1 type Code using `union2011', assert(3) nogen
merge 1:1 type Code using `union2012', assert(3) nogen
merge 1:1 type Code using `union2013', assert(3) nogen
merge 1:1 type Code using `union2014', assert(3) nogen
tempfile unionsA unionsB
save `unionsA'
use `union2015'
merge 1:1 type Code using `union2016', assert(3) nogen
merge 1:1 type Code using `union2017', assert(3) nogen
merge 1:1 type Code using `union2018', assert(3) nogen
save `unionsB'

// Read in state unionization from 2010-2018
forvalues y=2010/2018 {
	import excel using "${raw}/Hirsch/State_U_2010.xlsx", cellrange(A4:I259) clear firstrow
	keep if Sector=="Total"
	drop Sector
	keep Code State Obs Employment Mem Cov 
	foreach v of varlist Obs Employment Mem Cov {
		rename `v' `v'_`y'
	}
	tempfile unionst`y'
	save `unionst`y''
}
use `unionst2010'
merge 1:1 Code State using `unionst2011', assert(3) nogen
merge 1:1 Code State using `unionst2012', assert(3) nogen
merge 1:1 Code State using `unionst2013', assert(3) nogen
merge 1:1 Code State using `unionst2014', assert(3) nogen
merge 1:1 Code State using `unionst2015', assert(3) nogen
merge 1:1 Code State using `unionst2016', assert(3) nogen
merge 1:1 Code State using `unionst2017', assert(3) nogen
merge 1:1 Code State using `unionst2018', assert(3) nogen
gen division=1 if inlist(State,"Connecticut","Massachusetts","Maine","New Hampshire","Rhode Island","Vermont")
replace division=2 if inlist(State,"New Jersey", "New York", "Pennsylvania")
replace division=3 if inlist(State,"Illinois","Indiana","Ohio","Michigan","Wisconsin")
replace division=4 if inlist(State,"North Dakota","South Dakota","Nebraska","Kansas","Minnesota","Iowa","Missouri")
replace division=5 if inlist(State,"West Virginia","Maryland","Delaware","D.C.","Virginia","North Carolina","South Carolina","Georgia","Florida")
replace division=6 if inlist(State,"Kentucky","Tennessee","Alabama","Mississippi")
replace division=7 if inlist(State,"Arkansas","Louisiana","Oklahoma","Texas")
replace division=8 if inlist(State,"Montana","Idaho","Wyoming","Nevada","Utah","Colorado","New Mexico","Arizona")
replace division=9 if inlist(State,"California","Oregon","Washington","Alaska","Hawaii")
tempfile unionst
save `unionst'

//Start with counties in our list of CZs. Link to CZ defs, then to unionization data. 
//Figure out how many we are missing (not in MSAs reported in CPS), weighted by population.
//Then aggregate what we have.
use cz fips CountyName Population1990 using `CZs'
merge m:1 cz using `topczs', assert(1 3) keepusing(cz division top50 cz59 CZname)
// fix some up
gen stfips=floor(fips/1000)
// Alaska
 replace cz59=9 if stfips==2
// North Dakota -- note that one county is in an MT MSA so gets the wrong division
 replace cz59=4 if stfips==38 & (cz59<10 | cz59==.)
// A bunch of other CZs that have to be done by hand 
 replace cz59=8 if inlist(cz, 28402, 28501) // stfips 8-CO
 replace cz59=4 if inlist(cz,29002,29008) // stfips 20-KS
 replace cz59=8 if inlist(cz,26402,26405,26407,34306,34309) // State 30-MT
 replace cz59=4 if inlist(cz,28303,28606,29102) // state 31-NE
 replace cz59=8 if cz==37902 // state 32-NV
 replace cz59=8 if inlist(cz,30702,34804) // state 35-NM
 replace cz59=7 if cz==33603 // state 40-OK
 replace cz59=9 if cz==39204 // state 41-OR
 replace cz59=4 if inlist(cz,26404, 26603,27010,27012,27604) // state 46-SD
 replace cz59=7 if inlist(cz,30605,30905,30907,31304,32502,32603) // state 48-TX
 replace cz59=8 if cz==35905 // state 49-UT
 replace cz59=8 if cz==34604 // state 56-WY
 replace cz59=4 if cz==26401 // split between 30 and 46 (MT, SD)- give to SD for slightly larger pop.
assert cz59<.
drop _merge
tempfile counties
save `counties'

// This part will be done separately for 2010-2014 and 2015-2018. This is part A
  //Now, for each county, we merge on the CBSA and CSA codes, when they have them
  use `counties'
  merge 1:1 fips using `msas03'
  list fips CountyName Population1990 cz59 if _merge==1
  list fips County_Name -CSA_2003_Title if _merge==2
   // Note: Broomfield CO (fips 8014) didn't exist in older data / MSA codes
  drop if _merge!=3
  drop _merge

  // Merge to MSA data
  gen Code=CBSA_2003_Code
  // Fix some New England areas
   replace Code="77200" if Code=="39300" // Providence
   replace Code="71650" if Code=="14460" // Boston
   replace Code="715" if Code=="31700" // Use the Boston-Worcester-Manchester CBSA, since Manchester isn't broken out
   replace Code="73450" if Code=="25540" // Hartford
  merge m:1 Code using `unionsA'
  drop if _merge==2 & type=="CSA"
  tab _merge 
  list Code MetropolitanArea if _merge==2 // All New England areas, which will need to be done by hand
  gen ne=inlist(stfips,9,23,25,33,44,50)
  tab top50 _merge [aw=Population1990] // About 95% of counties (pop weighted) in top 50 CZs merge
  tab top50 _merge [aw=Population1990] if !ne, row // Outside NE, this is 98%
  tempfile czunionA
  save `czunionA'

  // Construct CZ means for top-50, ignoring unmatched CZs
  keep if top50==1
  keep if Cov_2010<.
  collapse (rawsum) Population1990 (mean) Mem_20?? Cov_20?? [aw=Population1990], by(division cz59 CZname)
  forvalues y=2010/2014 {
    replace Mem_`y'=Mem_`y'/100
    replace Cov_`y'=Cov_`y'/100
  }
  tempfile czcovA
  save `czcovA'
  
// This part will be done separately for 2010-2014 and 2015-2018. This is part B
  //Now, for each county, we merge on the CBSA and CSA codes, when they have them
  use `counties'
  merge 1:1 fips using `msas13'
  list fips County_Name CBSA* if _merge==2 
   // Note: Broomfield CO (fips 8014) didn't exist in older data / MSA codes
  tab top50 _merge, row
  tab top50 _merge [aw=Population1990], row
   // We get 93% of top-50 CZ counties with >99% of population
  drop if _merge!=3
  drop _merge

  // Merge to MSA data - don't need to fix New England in 2013 defs
  gen Code=CBSA_2013_Code
  merge m:1 Code using `unionsB'
  drop if _merge==2 & type=="CSA"
  tab _merge 
  gen ne=inlist(stfips,9,23,25,33,44,50)
  tab top50 _merge [aw=Population1990], row // About 98% of counties (pop weighted) in top 50 CZs merge
  drop _merge
  tempfile czunionB
  save `czunionB'

  // Construct CZ means for top-50, ignoring unmatched CZs
  keep if top50==1
  keep if Cov_2015<.
  collapse (rawsum) Population1990 (mean) Mem_20?? Cov_20?? [aw=Population1990], by(division cz59 CZname)
  forvalues y=2015/2018 {
    replace Mem_`y'=Mem_`y'/100
    replace Cov_`y'=Cov_`y'/100
  }
  tempfile czcovB
  save `czcovB'

// Now we can bring together the 2010-2014 and 2015-2018 data
 use `czcovA'
 rename Population1990 PopA
 merge 1:1 division cz59 using `czcovB', assert(3) nogen
 rename Population1990 PopB
 tempfile czcov
 save `czcov', replace

// Now we need to go back to get coverage rates for the 9 rest-of-division "CZs",
// which weren't well represented in the CPS MSA tabulations. Strategy:
// Compute total population and coverage rate of the entire states and add up 
// to divisions, then subtract off the population and coverage in the top-50 CZs 
// to get the rest-of-division part
use `counties'
replace division=cz59 if division==. & cz59<10
assert division<. & Population1990<.
collapse (sum) Population1990, by(division)
tempfile divpops
save `divpops'

use `unionst'
// compute division mean coverage weighting by average state employment (not exactly population)
egen avgemp=rowmean(Employment_20??)
collapse (mean) Mem_* Cov_* [aw=avgemp], by(division)
merge 1:1 division using `divpops', assert(3) nogen
rename Population1990 div_Pop
forvalues y=2010/2018 {
	gen div_Mem`y'=Mem_`y'*div_Pop/100
	gen div_Cov`y'=Cov_`y'*div_Pop/100
}
drop Mem_20?? Cov_20??
tempfile divcov
save `divcov'

use `czcov'
forvalues y=2010/2018 {
  if `y'<=2014 local pop "PopA"
  else local pop "PopB"
  gen czmembers`y'=Mem_`y'*`pop'
  gen czcoverage`y'=Cov_`y'*`pop'
}
collapse (sum) PopA PopB czmembers20?? czcoverage20??, by(division)
merge 1:1 division using `divcov'
gen rod_PopA=div_Pop-PopA
gen rod_PopB=div_Pop-PopB
forvalues y=2010/2018 {
	if `y'<=2014 local pop "PopA"
	else local pop "PopB"
	gen rod_Mem`y'=div_Mem`y'-czmembers`y'
	gen rod_Cov`y'=div_Cov`y'-czcoverage`y'
	gen Mem_`y'=rod_Mem`y'/rod_`pop'
	gen Cov_`y'=rod_Cov`y'/rod_`pop'
	gen czMem`y'=czmembers`y'/`pop'
	gen czCov`y'=czcoverage`y'/`pop'
}
keep division rod_PopA rod_PopB Mem_20?? Cov_20??
gen cz59=division
rename rod_PopA PopA
rename rod_PopB PopB
append using `czcov'
// Now we will take simple averages
 egen membership=rowmean(Mem_????)
 egen coverage=rowmean(Cov_????)
 keep division cz59 membership coverage
 tempfile unionization
 save `unionization'
//And grab CZ names
 use `topczs'
 sort cz59 cz
 by cz59: assert CZname==CZname[1]
 by cz59: keep if _n==1
 keep cz59 CZname
 merge 1:1 cz59 using `unionization', assert(3) nogen
 save "${tocensus}/cz_unionization.dta", replace
 
log close
