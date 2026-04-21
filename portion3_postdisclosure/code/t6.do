cap log close
log using t6.log, text replace

clear *
estimates clear


use ${scratch}/merge_acs_lehd, clear
assert educ<. 
rename psi psi_j


estimates clear
su psi_j [aw=npq]
local sdpsi=r(sd)
su ind_effects_m1 [aw=npq]
local sd1=r(sd)
su ind_effects_m2 [aw=npq]
local sd2=r(sd)
su ind_effects_m3 [aw=npq]
local sd3=r(sd)
eststo, add(sdy `sd1' sdpsi `sdpsi'): reg ind_effects_m1 psi_j [aw=npq], robust
eststo, add(sdy `sd2' sdpsi `sdpsi'): reg ind_effects_m2 psi_j [aw=npq], robust
eststo, add(sdy `sd3' sdpsi `sdpsi'): reg ind_effects_m3 psi_j [aw=npq], robust
// without robust to get adjusted r2
eststo, add(sdy `sd1' sdpsi `sdpsi'): reg ind_effects_m1 psi_j [aw=npq]
eststo, add(sdy `sd2' sdpsi `sdpsi'): reg ind_effects_m2 psi_j [aw=npq]
eststo, add(sdy `sd3' sdpsi `sdpsi'): reg ind_effects_m3 psi_j [aw=npq]

esttab, b(4) se nostar r2 ar2 scalars(sdy sdpsi)
esttab using ${results}/t6.csv, b(4) se nostar r2 ar2 scalars(sdy sdpsi) replace

log close
