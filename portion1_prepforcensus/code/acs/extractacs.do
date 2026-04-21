*extractacs.do

cap log close extractacs
log using extractacs.log, replace text name(extractacs)

local fyear=2010
local lyear=2018

*Extract ACS data from CSV to SAS format (because Census programs to read data
* are in SAS format only), process/clean, and then convert to Stata
forvalues yy=`fyear'/`lyear' {
  local y=`yy'-2000
  ! \rm ${tmp}/ss*.csv
  ! \rm ${tmp}/psam*.csv
  ! \rm ${tmp}/acs*.*
  ! \rm ${tmp}/extract`yy'.sas7bdat
  ! \rm ${tmp}/ACS`yy'_PUMS_README.pdf
  
  di "Starting unzip for `yy'" // Need some displays, as Stata is not verbose about shell commands.
  ! unzip ${acsraw}/csv_pus_`yy'.zip -d ${tmp}
! ls ${tmp}
  di "Finished unzip for `yy' - starting concatenation"
  if `yy'<=2016 {
    ! cat ${tmp}/ss`y'pusa.csv ${tmp}/ss`y'pusb.csv > ${tmp}/acs`yy'.csv
    ! \rm ${tmp}/ss`y'pus?.csv 
  }
  else {
    ! cat ${tmp}/psam_pusa.csv ${tmp}/psam_pusb.csv > ${tmp}/acs`yy'.csv
    ! \rm ${tmp}/psam_pus?.csv 
  }
! ls ${tmp}
  di "Finished concatenation for `yy' - starting StatTransfer to SAS"
  ! \rm ${tmp}/acs`yy'.sas7bdat
  ! st ${tmp}/acs`yy'.csv ${tmp}/acs`yy'.sas7bdat
! ls ${tmp}
  di "Finished StatTransfer to SAS for `yy' - starting SAS extract program"
  ! sas extract`y'.sas
! ls ${tmp}
  di "Finished SAS extract program for `yy' - starting StatTransfer to Stata"
  ! \rm ${scratch}/extract`yy'.dta
  ! st ${tmp}/extract`yy'.sas7bdat ${scratch}/extract`yy'.dta
  di "Finished StatTransfer to Stata for `yy' - cleaning up"
  ! \rm ${tmp}/acs`yy'.csv
  ! \rm ${tmp}/acs`yy'.sas7bdat
  ! \rm ${tmp}/ACS`yy'_PUMS_README.pdf
  ! \rm ${tmp}/extract`yy'.sas7bdat
}



log close extractacs
