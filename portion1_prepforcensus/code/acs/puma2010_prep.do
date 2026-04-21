*read puma-to-cz file from David Dorn and create one record per state/puma
*this version for 2010 pumas

*only keep cz allocations if over 5% of PUMA is in CZ
*creates max of 9 czs per puma


cap log close
log using puma2010_prep.log, replace

set seed 921109

use ${raw}/dorn/cw_puma2010_czone, clear

gen state=floor(puma2010/100000)
gen puma=puma2010-state*100000
rename czone cz
gen randorder=runiform()

// Arbitrary tiebreakers. These reproduce what was sent to Census in 2021.
gen tiebreak=10
/*
replace tiebreak=1 if (puma2010==2000200 & cz==29202) | ///
                      (puma2010==3100100 & cz==27704) | ///
                      (puma2010==3800100 & cz==26603) | ///
                      (puma2010==3800300 & cz==26603) | ///
                      (puma2010==4600200 & cz==27008) | ///
                      (puma2010==4600200 & cz==27009) | ///
                      (puma2010==4600400 & cz==27008) | ///
                      (puma2010==4600400 & cz==27009) | ///
                      (puma2010==4800100 & cz==30908) | ///
                      (puma2010==4802600 & cz==31403) | ///
                      (puma2010==4802800 & cz==31403) | ///
                      (puma2010==5500100 & cz==21001) 
replace tiebreak=2 if puma2010==3100100 & cz==28304
*/
isid state puma afactor tiebreak randorder

*next line deletes cz allocations if less than 5% of pop in cz
*maxcz is set in local

keep if afactor>.05
local maxcz=9


gsort state puma -afactor tiebreak randorder

by state puma: gen ccounter=_n
by state puma: gen ncz=_N
by state puma: egen afsum=sum(afactor)



tab ncz if ccounter==1
sum afactor afsum
sum afactor if ccounter==1, detail


*next line has max of maxcz czs per puma, hardwired
*note afactors are adusted to add to 1

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

*list of pumas with one or more czs dropped due to small share of pop in cz
list state puma ncz afsum if afsum<.998

save ${scratch}/puma2010_cz, replace
desc

gen checksum=cond(af1~=.,af1,0)+cond(af2~=.,af2,0)+cond(af3~=.,af3,0)+cond(af4~=.,af4,0)+cond(af5~=.,af5,0)+cond(af6~=.,af6,0)+cond(af7~=.,af7,0)+cond(af8~=.,af8,0)+cond(af9~=.,af9,0)
sum checksum

drop checksum

log close

