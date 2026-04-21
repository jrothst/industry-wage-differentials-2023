
// Master program to run all code at Census.
// Note that paths need to be set in these two programs, which are used by others:
//   ind_paths.sas
//   ind_paths.do
// In addition, in the following files the text "[MABLAB_BGL]" in the opening lines needs
// to be replaced with the path to the Matlab BGL package:
//   M9/firmAKM_callable.m
//   M1-M8/M1_AKM_top59A.m
//   M1-M8/M3_AKM_top59A.m
//   M1-M8/M4_AKM_top59A.m
//   M1-M8/M6_AKM_top59A.m
//   M1-M8/M7_AKM_top59A.m
//   M1-M8/M8_AKM_top59A.m
//   M9_twostep/firmAKM_spelldata_callable.m


// Cleaning
  ! sas ind_clean1.sas
  do ind_clean2.do  

// Main AKM and intermediate output
  cd M9
  do m9_runakm
    // This uses two subsidiary Matlab programs, firmAKM_callable.m and akm_pcg.m          
  do m9_cjmeans
  do m9_firmvardecomp
  cd ..
  
// Alternative models
  cd M1-M8
  ! matlab -nodisplay -nosplash -batch "M1_AKM_top59A"
  ! matlab -nodisplay -nosplash -batch "M3_AKM_top59A"
  ! matlab -nodisplay -nosplash -batch "M4_AKM_top59A"
  ! matlab -nodisplay -nosplash -batch "M6_AKM_top59A"
  ! matlab -nodisplay -nosplash -batch "M7_AKM_top59A"
  ! matlab -nodisplay -nosplash -batch "M8_AKM_top59A"
  cd ..
  cd M9_twostep
  do runakm_2step_rep.do
    // This uses two subsidiary Matlab programs, firmAKM_spelldata_callable.m and akm_pcg_spelldata.m
  cd ..
  
// Main analysis
  do 3_disc1-2_rep.do		
  do ind_disclosure2.do		
  do ind_disclosure_p2.do		
  do ind_disclosure3.do		

