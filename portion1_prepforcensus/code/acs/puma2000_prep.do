*read puma-to-cz file from David Dorn and create one record per state/puma
*this version for 2000 pumas

*only keep cz allocations if over 5% of PUMA is in CZ
*creates max of 10 czs per puma


cap log close
log using puma2000_prep.log, replace

set seed 921109

use ${raw}/dorn/cw_puma2000_czone, clear

gen state=floor(puma2000/10000)
gen puma=puma2000-state*10000
rename czone cz
gen randorder=runiform()

// Arbitrary tiebreakers. These reproduce what was sent to Census in 2021.
gen tiebreak=10
/* 
replace tiebreak=1 if (puma2000==200200 & cz==29202) | ///
                      (puma2000==310100 & cz==27704) | ///
                      (puma2000==460500 & cz==27004) | ///
                      (puma2000==460500 & cz==27008) | ///
                      (puma2000==480100 & cz==30908) | ///
                      (puma2000==483100 & cz==31403) | ///
                      (puma2000==550100 & cz==21101) | ///
                      (puma2000==380100 & cz==26403)
replace tiebreak=2 if puma2000==310100 & cz==27003
*/
isid state puma afactor tiebreak randorder

*next line deletes cz allocations if less than 5% of pop in cz
keep if afactor>.05
local maxcz=10


gsort state puma -afactor tiebreak randorder

by state puma: gen ccounter=_n
by state puma: gen ncz=_N
by state puma: egen afsum=sum(afactor)



tab ncz if ccounter==1
sum afactor afsum
sum afactor if ccounter==1, detail


*next line has max of maxcz czs per puma, hardwired
*note afactors are adjusted to add to 1 despite some missing cz weights

forvalues i=1/`maxcz' {

 by state puma: gen cz`i'=cz[`i']
 by state puma: gen af`i'=afactor[`i']/afsum

 }


*now retain only 1 observation per state/puma with all possible czs

keep if ccounter==1


tab ncz

forvalues i=1/`maxcz' {
sum if ncz==`i'
 }


keep state puma ncz afsum cz1-cz`maxcz' af1-af`maxcz'
sum

*list of pumas that have one or more czs dropped due to small share of pop in cz
list state puma ncz afsum if afsum<.998

save ${scratch}/puma2000_cz, replace
desc

gen checksum=cond(af1~=.,af1,0)+cond(af2~=.,af2,0)+cond(af3~=.,af3,0)+cond(af4~=.,af4,0)+cond(af5~=.,af5,0)+cond(af6~=.,af6,0)+cond(af7~=.,af7,0)+cond(af8~=.,af8,0)+cond(af9~=.,af9,0)+cond(af10~=.,af10,0)
sum checksum

log close
