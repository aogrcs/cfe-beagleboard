PROC $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)
;
;  Purpose: 
;           This is a sub-procedure  
;           To verify the values of Application Event Message Sent Counter
;           (from CVT and Telemetry)
;           EVS Event Msg Sent Ctr
;           and Application Binary Filter Counter     
;
;           Upon verification of values stated above the following Requirements
;           cEVS3004     (info from App info data file)
;           cEVS3018k_1  (App evt msg sent ctr in SB telemetry)
;           cEVS3103.3   (increment app bin filter ctr)
;           cEVS3104     (increment application evt msg sent ctr)
;           cEVS3105     (increment EVS evt msg sent ctr)
;           are accordingly assigned a value of Pass or Fail.
;         
;*******************************************************************************
#include "cfe_evs_gen_reqts.h"
;
global test_app_expected_counter
global EVS_total_msgs_sent
global AppBinFltrCtrMsg1
global added_app_location

write "test app expected counter = ", test_app_expected_counter
write "EVS total messages sent ctr = ", EVS_total_msgs_sent
write "App Binary Filter Ctr for Evt msg 1 = ", AppBinFltrCtrMsg1

if (($sc_$cpu_EVS_AppData[added_app_location].EventCounter = test_app_expected_counter) AND ;;
    ($sc_$cpu_EVS_APP[added_app_location].APPMSGSENTC = test_app_expected_counter)) then 
  ut_setrequirements cEVS3004, "P"
  write"cEVS3004 passed  "
  ut_setrequirements cEVS3018k_1, "P"
  write"cEVS3018k_1 passed  "
  ut_setrequirements cEVS3104, "P"
  write"cEVS3104 passed  "
elseif (($sc_$cpu_EVS_AppData[added_app_location].EventCounter <> test_app_expected_counter) AND ;;
             ($sc_$cpu_EVS_APP[added_app_location].APPMSGSENTC <> test_app_expected_counter)) then 
  ut_setrequirements cEVS3004, "F"
  write"cEVS3004 failed because CVT and telemetry App evt msg sent ctr are not equal "
  ut_setrequirements cEVS3018k_1, "F"
  write"cEVS3018k_1 failed because CVT and telemetry App evt msg sent ctr are not equal "
  ut_setrequirements cEVS3104, "F"
  write"cEVS3104 failed because CVT and telemetry App evt msg sent ctr are not equal "
elseif (($sc_$cpu_EVS_AppData[added_app_location].EventCounter = test_app_expected_counter) AND ;;
             ($sc_$cpu_EVS_APP[added_app_location].APPMSGSENTC <> test_app_expected_counter)) then
  ut_setrequirements cEVS3004, "P"
  write"cEVS3004 passed  "
  ut_setrequirements cEVS3018k_1, "F"
  write"cEVS3018k_1 failed because the telemetry evt msg sent ctr is not as expected  "
  ut_setrequirements cEVS3104, "P"
  write"cEVS3104 passed  "
elseif (($sc_$cpu_EVS_AppData[added_app_location].EventCounter <> test_app_expected_counter) AND ;;
             ($sc_$cpu_EVS_APP[added_app_location].APPMSGSENTC = test_app_expected_counter)) then
  ut_setrequirements cEVS3004, "F"
  write"cEVS3004 failed becuase the CVT App evt msg sent counter is not as expected "
  ut_setrequirements cEVS3018k_1, "P"
  write"cEVS3018k_1 passed  "
  ut_setrequirements cEVS3104, "P"
  write"cEVS3104 passed  "
endif
;
;*******************************************************************
;
if $sc_$cpu_EVS_MSGSENTC = EVS_total_msgs_sent  then
  ut_setrequirements cEVS3105, "P"
  write"cEVS3105 passed "  
else
  ut_setrequirements cEVS3105, "F"
  write"cEVS3105 failed "  
endif
;
;*******************************************************************
;
if $sc_$cpu_EVS_AppData[added_app_location].BinFltr[1].Ctr = AppBinFltrCtrMsg1 then
  ut_setrequirements cEVS3103_3, "P"
  write"cEVS3103.3 passed"  
else
  ut_setrequirements cEVS3103_3, "F"
  write"cEVS3103.3 failed "  
  write "variable for Test App Evt Msg 1 Bin filter Ctr   = ", AppBinFltrCtrMsg1
  write "CVT Test App evt msg 1 bin fltr ctr = ", $sc_$cpu_EVS_AppData[added_app_location].BinFltr[1].Ctr
endif

;*******************************************************************
;
write"  CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
write"  CCC    Test App Evt Msgs Snt Ctr            = ", $sc_$cpu_EVS_AppData[added_app_location].EventCounter
write"  CCC    Test App Telemetry Evt Msgs Sent Ctr = ", $sc_$cpu_EVS_APP[added_app_location].APPMSGSENTC
write"  CCC    EVS Telemetry msgs sent Ctr          = ", $sc_$cpu_EVS_MSGSENTC
write"  CCC    Test App Evt Msg 1 Bin filter Ctr    = ", $sc_$cpu_EVS_AppData[added_app_location].BinFltr[1].Ctr

write"  CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
;
ENDPROC ; $sc_$cpu_evs_ctr_check
