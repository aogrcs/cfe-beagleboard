PROC $sc_$cpu_evs_evt_msg_gen
;**********************************************************************
; 
;  Test Name:  evs_msg_gen         06-05-06 removed _tst
;  Test Level: Build Verification
;  Test Type:  Functional 
;
;  Original 1.0 Eva Illescas Stattel
;         
;******************************************************************************
;
;  Test Description: 
;
;  Test verifies functionality of the cFE Event Message Generation for   
;  Event Messages that are Registered for filtering as well as Event 
;  Messages Not Registered for Filtering.  Message with ID 1 is 
;  registered for filtering, while Message with ID 7 is not registered 
;  for filtering.
;
;******************************************************************************
;
;  Requirements Tested: (of April 14, 2005)
;
;    cEVS3004   Application data stored (partial test)
;    cEVS3007   Enable/Disable (one at a time) an Apps' Evt Msg Types
;    cEVS3008   Enable/Disable Apps' Evt Msg Gen
;    cEVS3012   Set Binary Filter Mask
;
;    Note: requirement cEVS3018 refers to Application Telemetry Information
;    this test only verifies the following:
;      cEVS3018e      Evt Msg Truncation Counter
;      cEVS3018f      Unregistered Application Send Counter
;      cEVS3018k_1    Event Msg Sent Counter
;      cEVS3018k_2   EVS Enable Status 
;
;    The other subordinate values of cEVS3018 are tested in the EVS Commands
;    and Log tests.            
;                
;    cEVS3100     App Registers: Evt msg types statuses, Evt ID and masks
;                 for those registered for filtering 
;    cEVS3100.1   Creation of binary filter ctr for each msg ID
;                 registered for filtering  
;    cEVS3100.2   Check creation of App Event Msg Sent Counter
;    cEVS3101     Deletion of all App related info when App Un-registers
;    cEVS3102     Event Message Types (Debug, Info, Error, Crit)  
;    cEVS3103     Main requirement to test in steps 1, 2 and 3
;    cEVS3103.1   Increment un-registered App Evt Msg Sent Counter
;    cEVS3103.2   Data Types
;    cEVS3103.3   Binary Filter Ctr
;    cEVS3103.4.1 Increment the evt truncated counter
;    cEVS3104     Increment App Evt Msg Sent Ctr 
;    cEVS3105     Increment EVS msg sent Ctr 
;    cEVS3109     ASCII string to each enabled Evt Msg. Output Port.
;                 NOTE: fully verified post-processing by generating 
;                       and examining hard copy of the output port log
;
;******************************************************************************
;
;  Prerequisite Conditions or constraints:
;
;  1.  A Test Application which registers for EVS upon Load/Start, 
;      specifying (by ID) events for filtering and their Binary Filter 
;      Masks.  When the Test Application registers for EVS, 
;      all four event message types shall be disabled by default 
;      (this is the opposite for Build 1 of FSW).
;
;  1a. A command shall be sent to the Test Application with 
;      the following parameters
;      Event Id
;      Event Type (Debug | Information | Error | Critical)
;      Number of Iterations 
;
;  1b. In response to the command, the application requests the 
;      generation of 
;      the command-specified Event Message with the command-specified 
;      Event Type.
;      The request will be made the number of times specified in the 
;      iterations parameter.
;
;   1.b.1 An Evt Msg must exist for which the test string is longer 
;       than the maximum allowed which shall cause the truncation
;       counter to increment upon generation of the event.
;
;   1c. Application shall Un-register from Event Services.
;
;   2.  There shall be one output port enabled by default from which to 
;       capture data.
;
;******************************************************************************
;
;  Change History
;
;    Date      Name            Description
;    ----      ----            -----------
;    04/28/05  Eva I. Stattel  Original
;    05/25/05  EIS             Added a CPU number to GET _FILE_TO_CVT  
;    06/08/05  EIS             Added include for Utilities, 
;			       local AppEvtMsgSentCtr, 
;                              verification of TRUE vs. FALSE results
;    06/27/05  EIS             Updated to run on multiple CPUs
;    08/18/05  EIS             Updated to begin "Cleanup"
;    10/03/05  EIS             Added checks for telemetry vs. stored app
;                              data values where applicable
;    10/25/05  EIS             Added subordinate values to test for requirement
;			       cEVS3018. (see above in requirements tested)
;    11/01/05  EIS             Updated to find Event Message Type Debug
;                              Status ENABLE by default in Build 3.0 of cFE
;    06/05/06  EIS             Updated to run with LRO sub-procedures required
;			       hard coded references to test app to be modified
;                              where applicable CFE_EVS_MAX_EVENT_FILTERS which
;			       is part of the cfe_platform_cfg.h replaces 
;			       CFE_EVS_MAX_APP_EVENTS         
;    06/23/06 EIS              Post walk-through re-instated processing of evt
;                              msg which must be truncated and added a wait to
;			       command /EVS_SETBINFLTRMASK
;    03/26/07 Walt Moleski     Updating the proc for cFE 4.0.1 Build
;			       Verification Testing
;    07/31/07 Walt Moleski     Adding tests for Rqmts 3103.6, 3103.7 & 3100.3

;*******************************************************************************;
;  Procedures/Utilities Called:
;         
;         Name               Description
;         ----               -----------
;         ut_runproc         To run the proc and do initial set up stuff
;         ut_sendcmd         To send EVS commands
;         ut_setupevt        To keep track of event generation
;         get_file_to_cvt    Procedure to write FSW data to a file, 
;                            ftp the file from the FSW hardware
;                            to ASIST hardware and load file to the CVT.
;         load_start_app     Procedure to load and start a user application 
;         ut_setrequirements Directive to status cfe requirements.
;         evs_fltrinfo       To output evt msg filter info. 
;         evs_gen_evts       To request generation of evt msgs
;                            when requirement cEVS3103 is fully met
;         evs_gen_dis_ty     To request generation of event messages 
;                            while all Evt Msg Tupes are DISABLED
;         evs_gen_no_evts    To request generation of evt msgs while
;                            Event Message Generation is DISABLED
;         evs_mskd_evt       To request generation of evt msgs after change of 
;			     binary filter mask from 0 to ffff (always filter)
;			     for the event message registered for filtering
;         evs_ctr_check      To verify application evt msg sent counter EVS msg
;			     sent counter and App bin filter ctr.
;         evs_test_app_info  To provide test application information
;	  evs_app_unreg	     To
;
;*******************************************************************************;
;  Expected Test Results and Analysis:
;
;         Verification of EVS Test Application Stored Data.
;
;         load/Start/Registration of Application for Event Service
;
;         Request Generation of Event Messages of four different event types: 
;             Debug, Information, Error and Critical.
;
;         Disable event message types
;         Request Generation of event messages
;           No messages are generated 
;
;         Re-enable event messages types
;         Request Generation of event messages 
;
;         Disable evt msg generation
;         Request Generation of event messages 
;           No messages are generated           
;
;         Un-register Test Application from EVS.
;         Request Generation of event messages 
;           No messages are generated to the Local Evt Log
;
;         Re-Register application for Event Services
;         Request Generation of event messages 
; 
;         Generation of event messages with specific data types (Char, Unsigned 
;         Char, Short Int, Unsigned Short Int, Long Int, Unsigned Long Int)
;
;         Retrieval of enabled output port file.
;
;*******************************************************************************;  
;  Define variables:
;    
validation ON
;
POPUP_HAZ ON
;
#include "ut_statusdefs.h"       
#include "cfe_platform_cfg.h"
#include "cfe_mission_cfg.h" 
#include "cfe_evs_events.h" 
;      
#include "cfe_evs_gen_reqts.h"
;
FOR i = 0 to ut_req_array_size DO
   ut_requirement[i] = "U"
ENDDO 

global added_app_location = 0 
global app_data_at_init = 0
global received_app_data_at_init = app_data_at_init
;
global EVS_total_msgs_sent = 0
global AppBinFltrCtrMsg1 = 0
global test_app_expected_counter = 0
;
GLOBAL SAVE_EVS_AppData_EventCounter[CFE_ES_MAX_APPLICATIONS]
GLOBAL SAVE_EVS_AppData_AppName[CFE_ES_MAX_APPLICATIONS]
GLOBAL SAVE_EVS_AppData_ActiveFlag[CFE_ES_MAX_APPLICATIONS]
GLOBAL SAVE_EVS_AppData_EvtTypeAF_Debug[CFE_ES_MAX_APPLICATIONS]
GLOBAL SAVE_EVS_AppData_EvtTypeAF_Info[CFE_ES_MAX_APPLICATIONS]
GLOBAL SAVE_EVS_AppData_EvtTypeAF_Err[CFE_ES_MAX_APPLICATIONS]
GLOBAL SAVE_EVS_AppData_EvtTypeAF_Crit[CFE_ES_MAX_APPLICATIONS] 
;
GLOBAL SAVE_EVS_AppData_BinFltr_EvtId[CFE_ES_MAX_APPLICATIONS,CFE_EVS_MAX_EVENT_FILTERS] 
GLOBAL SAVE_EVS_AppData_BinFltr_Msk[CFE_ES_MAX_APPLICATIONS,CFE_EVS_MAX_EVENT_FILTERS]
GLOBAL SAVE_EVS_AppData_BinFltr_Ctr[CFE_ES_MAX_APPLICATIONS,CFE_EVS_MAX_EVENT_FILTERS]
; 
global AppNAF[2] = ["AppName", "ActiveFlag"]
global appevsena = "ActiveFlag"
global appname = "AppName"
global appevtctr = "EventCounter"
global ETSub[1..4] = ["Debug", "Info", "Err", "Crit"]
global DebugEvtTy = "Debug"
global InfoEvtTy = "Info"
global ErrEvtTy = "Err"
global CritEvtTy = "Crit"
global BFSub[1..3] = ["EvtID", "Msk", "Ctr"]
global BinFID = "EvtID"
global BinFMask = "Msk"
global EvtBinFCtr = "Ctr"
;
write ";***********************************************************************"
write "; Step 0: Event Message Generation TEST SETUP"  
write ";***********************************************************************"
write "; Step 0.1: Command a Power-On Reset on $CPU"
write ";***********************************************************************"
/$SC_$CPU_ES_POWERONRESET
wait 10
                                                                                
close_data_center
wait 75
                                                                                
cfe_startup $CPU
wait 5

write ";*********************************************************************"
write "; Enable DEBUG Event Messages "
write ";*********************************************************************"
ut_setupevt "$SC", "$CPU", "CFE_EVS", CFE_EVS_ENAEVTTYPE_EID, "DEBUG"
                                                                                
ut_sendcmd "$SC_$CPU_EVS_ENAEVENTTYPE DEBUG"
if (UT_SC_Status = UT_SC_Success) then
  write "<*> Passed - Debug events have been enabled."
  if ($SC_$CPU_num_found_messages = 1) then
    Write "<*> Passed - Event Msg ",$SC_$CPU_find_event[1].eventid," Found!"
  else
    Write "<!> Failed - Event Message not received for ENAEVENTTYPE command."
  endif
else
  write "<!> Failed - Could not enable Debug events."
endif

write ";***********************************************************************"
write "; Step 0.2: Retrieve Local Event Log and Application Data."
write ";           The Application data file shall contain default values for "
write ";	   registered applications and no Test application information"
write ";           since the application is not yet registered"
write ";***********************************************************************"

; Get the current EVS Log 
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "011.log", "$CPU")
wait 20

; Get the current EVS App Data
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "011.tst_appdat", "$CPU")
wait 20

write ";***********************************************************************"
write "; Step 0.3: Save the application data information for later comparison"
write ";***********************************************************************"
;
%liv (log_procedure) = FALSE
;
FOR i = 1 to CFE_ES_MAX_APPLICATIONS DO
  WRITE "Saving Original Data.  Iteration = ", i

  SAVE_EVS_AppData_EventCounter[i]      = $SC_$CPU_EVS_AppData[i].EventCounter
  SAVE_EVS_AppData_AppName[i]           = $SC_$CPU_EVS_AppData[i].AppName
  SAVE_EVS_AppData_ActiveFlag[i]        = $SC_$CPU_EVS_AppData[i].ActiveFlag
  SAVE_EVS_AppData_EvtTypeAF_Debug[i]   = $SC_$CPU_EVS_AppData[i].EvtTypeAF.Debug
  SAVE_EVS_AppData_EvtTypeAF_Info[i]    = $SC_$CPU_EVS_AppData[i].EvtTypeAF.Info
  SAVE_EVS_AppData_EvtTypeAF_Err[i]     = $SC_$CPU_EVS_AppData[i].EvtTypeAF.Err
  SAVE_EVS_AppData_EvtTypeAF_Crit[i]    = $SC_$CPU_EVS_AppData[i].EvtTypeAF.Crit

  FOR j = 1 to CFE_EVS_MAX_EVENT_FILTERS DO
    SAVE_EVS_AppData_BinFltr_EvtId[i,j] = $SC_$CPU_EVS_AppData[i].BinFltr[j].EvtId
    SAVE_EVS_AppData_BinFltr_Msk[i,j]   = $SC_$CPU_EVS_AppData[i].BinFltr[j].Msk
    SAVE_EVS_AppData_BinFltr_Ctr[i,j]   = $SC_$CPU_EVS_AppData[i].BinFltr[j].Ctr
  ENDDO
ENDDO
;
%liv (log_procedure) = TRUE
;
write ";***********************************************************************"
write "; Step 0.4: Load/Start/Register Test Application"
write ";***********************************************************************"
; Setup the event to capture
ut_setupevt $sc, $cpu, TST_EVS, 16, INFO

start load_start_app ("TST_EVS","$CPU") 
wait 10

; Verify that the expected event was received
if ($sc_$cpu_num_found_messages = 1) then
  ut_setrequirements cEVS3100, "P"
  write"<*> Passed (3100) - test app registered" 
else
  ut_setrequirements cEVS3100, "F"
  write"<!> Failed (3100) - Init message for TST_EVS was not rcv'd" 
  write"ALERT, ALERT! No event message found to indicate Load/Start/Register Test App"
  write"ALERT! The test is now over because the test application failed to load"
  goto end_it
endif 

write ";***********************************************************************"
write "; Step 0.5: Retrieve Local Event Log and Application Data."
write ";           Test application information must appear in Data file after "
write ";           the application registers for EVS."
write ";***********************************************************************"
;
EVS_total_msgs_sent = $sc_$cpu_EVS_MSGSENTC + 3

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "022.log", "$CPU")
wait 20

;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "022.tst_appdat", "$CPU" )
wait 20

write ";***********************************************************************"
write "; Step 0.6: Verify that EVS total evt msgs sent ctr incremented by 2."
write ";***********************************************************************"
; 
if $sc_$cpu_EVS_MSGSENTC <> EVS_total_msgs_sent  then
  ut_setrequirements cEVS3105, "F"
  write "cEVS3105 failed, EVS total msgs sent ctr = ", $sc_$cpu_EVS_MSGSENTC, " Expected ", EVS_total_msgs_sent
  EVS_total_msgs_sent = $sc_$cpu_EVS_MSGSENTC
else
  ut_setrequirements cEVS3105, "P"
  write"cEVS3105 passed, EVS total msgs sent       = ", $sc_$cpu_EVS_MSGSENTC
endif

write ";***********************************************************************"
write "; Step 0.7: Compare Test Application data from initial state to after "
write ";	   its initialization. The following data is compared:"
write ";	      Event Message Generation Status"
write ";              Event message types statuses"
write ";              Binary filter information"
write ";***********************************************************************"
;
app_data_at_init = 1
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
;
start $sc_$cpu_evs_test_app_info(app_data_at_init)
;
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
; output binary filter information from app stored info
start $sc_$cpu_evs_fltrinfo 
;
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
;
write ";***********************************************************************"
write ";* Conditions for requirement cEVS3103 for Test Application *"
write ";* Event Service Enable Status is Enabled                   *"
write ";* Event Type Enable Status is Enabled for the              *"
write ";* Event Type of the request-specified Event Message        *"
write ";* Application registered message filtering                 *"
write ";* algorithm indicates the message should be sent           *"
write ";***********************************************************************"
;
write ";***********************************************************************"
write "; Step 1.0: Upon verification of the conditions stated above, request "
write ";	   the generation of event messages of every evt msg type. "
write ";           Since cFE Bld 3.0, the event Msg Type DEBUG status is "
write ";	   DISABLED by default and the rest are ENABLED. After "
write ";	   verifying the default states, ENABLE DEBUG events."
write ";***********************************************************************"
;
if (p@$SC_$CPU_EVS_APP[added_app_location].APPENASTAT = "ENA")          AND ;;
   (p@$SC_$CPU_EVS_AppData[added_app_location].ActiveFlag = "ENA")      AND ;;
   (p@$SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Debug = "DIS") AND ;;
   (p@$SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Info = "ENA")  AND ;;
   (p@$SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Err = "ENA")   AND ;;
   (p@$SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Crit = "ENA")  AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Msk = 0)        AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].BinFltr[8].Msk = 0 ) then
  ut_setrequirements cEVS3018k_2, "P"
  ut_setrequirements cEVS3100_3, "P"
  write " cEVS3018k_2 passed  "
  ; change DEBUG evt msg status to ENABLE
  /$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION="TST_EVS" DEBUG 
  wait 5
else
  ut_setrequirements cEVS3018k_2, "P"
  write " cEVS3018k_2 failed at EVS enable telemetry check "
  ut_setrequirements cEVS3103, "F"
  write " cEVS3103 failed because its specifications were not met"
endif
;

write ";***********************************************************************"
write "; Step 1.1: Request the generation of event messages for every type."
write ";***********************************************************************"
write "; Before GEN_EVTS: MsgSentCtr = ", $SC_$CPU_EVS_MSGSENTC
start $SC_$CPU_evs_gen_evts 
write "; After GEN_EVTS: MsgSentCtr = ", $SC_$CPU_EVS_MSGSENTC
;; Set the following requirements to Analyze since the log file needs to be
;; inspected to see if the event messages contain the correct information
ut_setrequirements cEVS3103_6, "A"
ut_setrequirements cEVS3103_7, "A"

write ";***********************************************************************"
write "; Step 1.2: Retrieve Local Event Log and Application Data to verify "
write ";	   generation of event messages and that counters increment"
write ";	   accordingly"
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "101.log", "$CPU")
wait 20

;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "101.tst_appdat", "$CPU" )
wait 20

; Verify increment of EVS evt msg sent ctr
test_app_expected_counter = test_app_expected_counter + 8
EVS_total_msgs_sent  = EVS_total_msgs_sent + 12
AppBinFltrCtrMsg1 = AppBinFltrCtrMsg1 + 4
;
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
;
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)
;
; Set the Total Message Counter to the TLM point in order
; to avoid all subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"

write ";***********************************************************************"
write "; Step 1.3: Change statuses of event message types."
write ";***********************************************************************"
write "; Step 1.3.1: Disable DEBUG event messages for the TST_EVS application."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_DisappEvtType APPLICATION="TST_EVS" DEBUG
wait 5

write ";***********************************************************************"
write "; Step 1.3.2: Disable INFO event messages for the TST_EVS application."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_DisappEvtType APPLICATION="TST_EVS" INFO
wait 5

write ";***********************************************************************"
write "; Step 1.3.3: Disable ERROR event messages for the TST_EVS application."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_DisappEvtType APPLICATION="TST_EVS" ERROR
wait 5

write ";***********************************************************************"
write "; Step 1.3.4: Disable CRITICAL event messages for TST_EVS application."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_DISAPPEVTTYPE  APPLICATION="TST_EVS"  CRIT  
wait 5

write ";***********************************************************************"
write "; Step 1.3.5: Retrieve Application Data and verify Event Message Type "
write ";	     Statuses."
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "1141.tst_appdat", "$CPU" )
wait 20

if (p@$SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Debug = "DIS") AND ;;
   (p@$SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Info = "DIS")  AND ;;
   (p@$SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Err = "DIS")   AND ;;
   (p@$SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Crit = "DIS") then
  ut_setrequirements cEVS3007, "P"
  write"cEVS3007 passed.  All Evt Msg Types Statuses are as expected"
else
  ut_setrequirements cEVS3007, "F"
  write"ALERT: cEVS3007 failed at Event Message Types statuses check"
  ut_setrequirements cEVS3103, "F"
  write"ALERT: cEVS3103 failed at Event Message Types statuses check"
  write"************************************************************"
  write " --- Evt Msg Type --- Status ---"
  for i = 1 to 4 do
    write"     ",ETSub [i], "    ",$sc_$cpu_EVS_AppData[added_app_location].EvtTypeAF.{ETSub[i]} 
  enddo 
  write " The Test ended because the Evt Msg Types statuses are incorrect"
  goto end_it ; end the test
endif

write ";***********************************************************************"
write "; Step 1.3.6: Request generation of every evt msg type. No event msgs "
write ";             should be generated since all types are DISABLED."
write ";***********************************************************************"
; request generation of event messages
start $sc_$cpu_evs_gen_dis_ty

write ";***********************************************************************"
write "; Step 1.3.7: Retrieve Local Event Log and Stored Application Data and "
write ";             verify that no evt msgs appear in the Local Evt Log and "
write ";             the correct counter values exist."
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "1143.log", "$CPU")
wait 20

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "1143.tst_appdat", "$CPU" )
wait 20

EVS_total_msgs_sent  = EVS_total_msgs_sent + 9
AppBinFltrCtrMsg1 = AppBinFltrCtrMsg1 + 4
;
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
;
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)
;
; Set the Total Message Counter to the TLM point in order to avoid all 
; subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"

write ";***********************************************************************"
write "; Step 1.4: Change Event Message Type Statuses: "
write ";***********************************************************************"
write "; Step 1.4.1: Enable DEBUG event messages for the TST_EVS application."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION="TST_EVS" DEBUG
wait 5

write ";***********************************************************************"
write "; Step 1.4.2: Enable INFO event messages for the TST_EVS application."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION="TST_EVS" INFO
wait 5

write ";***********************************************************************"
write "; Step 1.4.3: Enable ERROR event messages for the TST_EVS application."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION="TST_EVS" ERROR
wait 5
 
write ";***********************************************************************"
write "; Step 1.4.3: Enable CRITICAL event messages for TST_EVS application."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION="TST_EVS" CRIT
wait 5
 
write ";***********************************************************************"
write "; Step 1.4.4 Retrieve Application Data and verify that all evt msg "
write ";            types are enabled "
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "1241.tst_appdat", "$CPU")
wait 20
 
write ";***********************************************************************"
write "; Conditions for requirement cEVS3103 for Test Application "
write "; Event Service Enable Status is Enabled                   "
write "; Event Type Enable Status is Enabled for the              "
write "; Event Type of the request-specified Event Message        "
write "; Application registered message filtering                 "
write "; algorithm indicates the message should be sent           "
write ";***********************************************************************"

if (p@$sc_$cpu_EVS_AppData[added_app_location].EvtTypeAF.Debug = "ENA") AND ;;
   (p@$sc_$cpu_EVS_AppData[added_app_location].EvtTypeAF.Info = "ENA") AND ;;
   (p@$sc_$cpu_EVS_AppData[added_app_location].EvtTypeAF.Err = "ENA") AND ;;
   (p@$sc_$cpu_EVS_AppData[added_app_location].EvtTypeAF.Crit = "ENA") then
  ut_setrequirements cEVS3007, "P"
  write"cEVS3007 passed at verification of evt msg types statuses and is now fully verified"
else
  ut_setrequirements cEVS3007, "F"
  write"cEVS3007 failed at verification of evt msg types statuses"
  ut_setrequirements cEVS3103, "F"
  write"cEVS3103 failed at verification of evt msg types statuses"
  write"  The Test ended because of incorrect evt msg types statuses"
  goto end_it ; end the test  
endif

write ";***********************************************************************"
write "; Step 1.4.5 Request event msg generation for each type."
write ";***********************************************************************"
;
start $sc_$cpu_evs_gen_evts
 
write ";***********************************************************************"
write "; Step 1.4.6 Retrieve the Local Evt Log and data information to verify "
write ";            that the messages were generated as requested and the "
write ";	    respective counters increment properly. "
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "1243.log", "$CPU")
wait 20

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "1243.tst_appdat", "$CPU" )
wait 20
 
test_app_expected_counter = test_app_expected_counter + 8
EVS_total_msgs_sent  = EVS_total_msgs_sent  + 17
AppBinFltrCtrMsg1 = AppBinFltrCtrMsg1 + 4
;
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)
 
; Set the Total Message Counter to the TLM point in order
; to avoid all subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
 
write ";***********************************************************************"
write "; Step 2.0 Event Message Generation Filtering Algorithm Test "
write ";***********************************************************************"
write "; Step 2.1 Send command to set binary filter mask for evt msg 1 which is"
write ";          registered for filtering to FFFF (always filter). "
write ";***********************************************************************"
;
/$SC_$CPU_EVS_SETBINFLTRMASK APPLICATION="TST_EVS" Event_ID = "1" FILTERMASK=x'ffff' 
wait 5
 
write ";***********************************************************************"
write "; Step 2.2: Send command to set the binary filter mask for evt msg 7"
write ";           which is not registered for filtering. This command should"
write ";	   fail since the evt msg is not registered for filtering"
write ";***********************************************************************"
; NOTE: For Build 1 of the FSW no event message was generated 
;       indicating this failure."
;       For Bld 3.0 this action caused EVS to generate evt msg ID 6"
; 
/$SC_$CPU_EVS_SETBINFLTRMASK APPLICATION="TST_EVS" Event_ID = "7" FILTERMASK=x'ffff'
wait 8
 
write ";***********************************************************************"
write "; Step 2.3: Retrieve Stored Application Data to verify the change of "
write ";	   binary filter masks"
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "203.tst_appdat", "$CPU")
wait 20
 
write "Evt Msg  |  Bin Fltr  "
write "  ID     |    Mask    "
write "_________________________________ "
write "   ", $SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].EvtId, "    |   ", ;;
%hex($SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Msk, 4)
write "_________________________________ "

if ($SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Msk = x'ffff' ) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].BinFltr[added_app_location].Msk = 0 ) then
  ut_setrequirements cEVS3012, "P"
  write "   cEVS3012 passed"
else
  ut_setrequirements cEVS3012, "F"
  write " ALERT: cEVS3012 failed at binary filter masks check"
  write"  The Test has ended because of bad bin filter info."
  goto end_it ; end the test
endif  

write ";***********************************************************************"
write "; Step 2.4: Request the generation of event messages 1 and 7."
write ";***********************************************************************"
;
start $sc_$cpu_evs_mskd_evt 
;
 
write ";***********************************************************************"
write "; Step 2.5: Retrieve Local Event Log and Application Data and verify "
write "; 	   that evt msg of ID 1 was not generated since its binary "
write ";	   filter mask is FFFF (always filter) while evt msg of ID 7 "
write ";	   is generated because the evt is not registered for filtering"
write ";	   and therefore has no binary filter mask set."
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "211.log", "$CPU")
wait 20

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "211.tst_appdat", "$CPU")
wait 20

test_app_expected_counter = test_app_expected_counter + 20
EVS_total_msgs_sent  = EVS_total_msgs_sent  + 27
AppBinFltrCtrMsg1 = AppBinFltrCtrMsg1 + 20
;
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
;
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)
;
; Set the Total Message Counter to the TLM point in order to avoid all 
; subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
 
write ";***********************************************************************"
write "; Step 2.6: Change binary filter masks (where applicable) to 0"
write ";***********************************************************************"
write "; Step 2.6.1: Send command to change binary filter mask for evt msg 1"
write ";***********************************************************************"
;
/$SC_$CPU_EVS_SETBINFLTRMASK APPLICATION="TST_EVS" Event_ID ="1" FILTERMASK=x'0'
wait 5

write ";***********************************************************************"
write "; Step 2.6.2: Send command to change binary filter mask for evt 7."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_SETBINFLTRMASK APPLICATION="TST_EVS" Event_ID = "7" FILTERMASK=x'0'
wait 5

write ";***********************************************************************"
write "; Step 2.6.3: Retrieve Stored Application Data to verify correct binary"
write ";             filter mask changes."
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "223.tst_appdat", "$CPU")
wait 20
 
write ";***********************************************************************"
write "; Conditions for requirement cEVS3103 for Test Application "
write "; Event Service Enable Status is Enabled                   "
write "; Event Type Enable Status is Enabled for the              "
write "; Event Type of the request-specified Event Message        "
write "; Application registered message filtering                 "
write "; algorithm indicates the message should be sent           "
write ";***********************************************************************"
;
if ($SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Msk = 0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].BinFltr[added_app_location].Msk = 0) then
  ut_setrequirements cEVS3012, "P"
  write"  |  cEVS3012 passed and is now fully verified" 
else
  ut_setrequirements cEVS3012, "F"
  write"  |  cEVS3012 failed at bin filter mask verification" 
  ut_setrequirements cEVS3103, "F"
  write"  |  cEVS3103 failed at bin filter mask verification" 
  write"  The Test has ended because of the bin filter mask found"
  goto end_it              
endif

write ";***********************************************************************"
write "; Step 2.6.4: Request the generation of every event message type."
write "; 	     NOTE: evt msg 1 is registered for filtering"
write "; 	     its binary filter mask is 0 (never filter)"
write ";             Evt msg 7 is NOT registered for filtering at all."
write ";***********************************************************************"
start $sc_$cpu_evs_gen_evts

; Get the Local Event Log
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "224.log", "$CPU")
wait 20

; Get the application data
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "224.tst_appdat", "$CPU")
wait 20
 
test_app_expected_counter = test_app_expected_counter + 8
EVS_total_msgs_sent  = EVS_total_msgs_sent + 15
AppBinFltrCtrMsg1 = AppBinFltrCtrMsg1 + 4
;
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)
 
; Set the Total Message Counter to the TLM point in order to avoid all 
; subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
 
write ";***********************************************************************"
write "; Step 3.0: Disable Event Message Generation Test "
write ";***********************************************************************"
write "; Step 3.1: Send command to disable evt msg generation for the TST_EVS"
write ";	   application."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_DISAPPEVGEN APPLICATION="TST_EVS"
wait 8 

write ";***********************************************************************"
write "; Step 3.2: Retrieve the application information to verify that event "
write ";          message generation has been disabled for TST_EVS."
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "3011.tst_appdat", "$CPU")
wait 20
 
;
if (p@$sc_$cpu_EVS_APP[added_app_location].APPENASTAT = "DIS") AND ;;
   (p@$sc_$cpu_EVS_AppData[added_app_location].ActiveFlag = "DIS") then
  ut_setrequirements cEVS3018k_2, "P"
  write " |   cEVS3018k_2 passed because the telemetry value for EVS matches the one from CVT"
  ut_setrequirements cEVS3008, "P"
  write"  |   cEVS3008 passed"
else
  ut_setrequirements cEVS3008, "F"
  write "ALERT: cEVS3008 failed "  
  ut_setrequirements cEVS3103, "F"
  write "ALERT: cEVS3103 failed " 
  write" ***** Event Msg Generation status = " , p@$sc_$cpu_EVS_AppData[added_app_location].ActiveFlag
  write" *** Telemetry Evt Msg Gen Status  = " , p@$sc_$cpu_EVS_APP[added_app_location].APPENASTAT 
  write" The Test has ended because of the Evt Msg Gen Status"
  goto end_it ; end the test
endif

write ";***********************************************************************"
write "; Step 3.3: Request generation of filtered and non-filtered event msgs "
write ";	   of every evt msg type. These msgs shall not be generated "
write ";	   since evt msg generation is Disabled."
write ";***********************************************************************"
start $sc_$cpu_evs_gen_no_evts

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "302.log", "$CPU")
wait 20

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "302.tst_appdat", "$CPU")
wait 20
 
;write"           |  No increment to App evt msg sent ctr"
;write"           |  No increment to EVS msg sent ctr"
;write"           |  Increment to App binary filter ctr"
;write"           |  for evt registered for filtering although no"
;write"           |  evt msgs registered for filtering are generated"
;write"           | "
;
EVS_total_msgs_sent  = EVS_total_msgs_sent + 6
AppBinFltrCtrMsg1 = AppBinFltrCtrMsg1 + 4
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
;
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)
 
; Set the Total Message Counter to the TLM point in order to avoid all 
; subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"

write ";***********************************************************************"
write "; Step 3.4: Enable the Generation of Event Messages for the TST_EVS "
write ";	   Application. "
write ";***********************************************************************"
;
/$SC_$CPU_EVS_ENAAPPEVGEN APPLICATION="TST_EVS"
wait 8 
 
write ";***********************************************************************"
write "; Step 3.5: Retrieve Local Evt Log and Stored Application Data and "
write ";           verify that event message generation status is correct"
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "312.log", "$CPU")
wait 20

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "312.tst_appdat", "$CPU")
wait 20
 
write ";***********************************************************************"
write "; Conditions for requirement cEVS3103 for Test Application *"
write "; Event Service Enable Status is Enabled                   *"
write "; Event Type Enable Status is Enabled for the              *"
write "; Event Type of the request-specified Event Message        *"
write "; Application registered message filtering                 *"
write "; algorithm indicates the message should be sent           *"
write ";***********************************************************************"
;
if ((p@$SC_$CPU_EVS_APP[added_app_location].APPENASTAT = "ENA")  AND ;;
   (p@$SC_$CPU_EVS_AppData[added_app_location].ActiveFlag = "ENA")) then
  ut_setrequirements cEVS3018k_2, "P"
  write " |   cEVS3018k_2 passed because the telemetry value for EVS matches the one from CVT"
  ut_setrequirements cEVS3008, "P"
  write"  |   cEVS3008 passed and is now fully verified"
else
  ut_setrequirements cEVS3103, "F"
  write " cEVS3103 failed at EVS enabled check" 
  ut_setrequirements cEVS3008, "F"
  write "cEVS3008 failed at EVS enabled check"
  ut_setrequirements cEVS3018k_2, "F"
  write " cEVS3018k_2 failed "
  write "ALERT: either invalid app Event Msg Gen status = " , p@$SC_$CPU_EVS_AppData[added_app_location].ActiveFlag
  write "!!! or telemetry Event Msg Generation status = " , p@$SC_$CPU_EVS_APP[added_app_location].APPENASTAT 
  write " test ended because the Evt msg Gen Status is incorrect"
  goto end_it ; end the test 
endif ; to check of telemetry and stored appl data values

write ";***********************************************************************"
write "; Step 3.6: Request generation of filtered and non-filtered event msgs "
write "; 	   of every type. These should be generated since event msg "
write "; 	   generation is Enabled."
write ";***********************************************************************"
;
start $sc_$cpu_evs_gen_evts   ; request generation of event messages of every evt msg type
;
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "313.log", "$CPU")
wait 20

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "313.tst_appdat", "$CPU")
wait 20
 
; check the counters
EVS_total_msgs_sent  = EVS_total_msgs_sent  + 15
AppBinFltrCtrMsg1 = AppBinFltrCtrMsg1 + 4
test_app_expected_counter = test_app_expected_counter + 8
 
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
 
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)

; Set the Total Message Counter to the TLM point in order to avoid all 
; subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
 
write ";***********************************************************************"
write "; Step 3.7: Request generation of an event message for which the text "
write ";	   string length is greater than the defined value of ", CFE_EVS_MAX_MESSAGE_LENGTH
write ";           and it is therefore truncated.   "
write ";***********************************************************************"
; Setup for the expected event
ut_setupevt $sc, $cpu, TST_EVS, 6, INFO
wait 3

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "6" Iters = "10" Milliseconds = "10"
wait 10

; Verify increment of truncation counter"
if ($SC_$CPU_EVS_MSGTRUNC = 10) AND ($SC_$CPU_num_found_messages = 10) then
  ut_setrequirements cEVS3103_4_1, "P"
  write " cEVS3103.4.1 passed and it is fullly verified"  
  ut_setrequirements cEVS3018e, "P"
  write " cEVS3018e passed and it is fullly verified"  
else
  ut_setrequirements cEVS3103_4_1, "F"
  write " cEVS3103.4.1 failed"  
  ut_setrequirements cEVS3018e, "F"
  write " cEVS3018e failed at truncation counter check"  
endif

write " Event Message Truncated Counter ", $SC_$CPU_EVS_MSGTRUNC
write " Evt Msg content = ", $SC_$CPU_find_event[1].event_txt
 
write ";***********************************************************************"
write "; Step 3.8: Retrieve the stored App data to verify counters and the "
write"             Local Evt log to ensure generation of evt for which the text"
write"             string gets truncated."
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "322.tst_appdat", "$CPU")
wait 20

;
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "322.log", "$CPU")
wait 20

; Verify the couters
test_app_expected_counter = test_app_expected_counter + 10
EVS_total_msgs_sent  = EVS_total_msgs_sent  + 13

write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)

; Set the Total Message Counter to the TLM point in order to avoid all 
; subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"

write ";***********************************************************************"
write "; Step 4.0: Un-registered Application Test"
write ";***********************************************************************"
write "; Step 4.1: Un-register the TST_EVS Application"
write ";***********************************************************************"
;
/$SC_$CPU_TST_EVS_Unregister                
wait 20
 
write
write "*** EVS Total Msgs sent (local) = ", EVS_total_msgs_sent
write "*** EVS Total Msgs sent (EVS)   = ", $SC_$CPU_EVS_MSGSENTC
write

; Get the application data
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "401.tst_appdat", "$CPU")
wait 20
EVS_total_msgs_sent = EVS_total_msgs_sent + 2
 
write ";***********************************************************************"
write "; Step 4.2 Verify absence of Test Application name and that all other "
write ";	  counters associated with the TST_EVS App are equal to zero" 
write ";***********************************************************************"
write
write "*** EVS Total Msgs sent (local) = ", EVS_total_msgs_sent
write "*** EVS Total Msgs sent (EVS)   = ", $SC_$CPU_EVS_MSGSENTC
write
;
write ";<><>Application Name     = ", $SC_$CPU_EVS_AppData[added_app_location].AppName
write ";<><>App evt msg gen info = ", $SC_$CPU_EVS_AppData[added_app_location].ActiveFlag
;
write ";<><>App evt msg ctr info = ",$SC_$CPU_EVS_AppData[added_app_location].EventCounter 
;
write ";<><>Evt msg id info      = ", $SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].EvtId
;
write ";<><>Evt msg mask         = ", $SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Msk
;
write ";<><>Binary filter ctr    = ", $SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Ctr

; Verify that the App info was cleared
if ($SC_$CPU_EVS_AppData[added_app_location].AppName = "")       AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].ActiveFlag = 0)     AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Crit = 0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Err =0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Info = 0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Debug = 0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].EventCounter = 0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].EvtId = 0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Msk = 0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Ctr = 0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Crit = 0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Err =0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Info = 0) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].EvtTypeAF.Debug = 0) then
  ;
  ; *************************************************************
  ; Assign current values to application evt msg sent ctr
  ; and binary filter ctr
  ; *************************************************************
  test_app_expected_counter = $SC_$CPU_EVS_AppData[added_app_location].EventCounter
  AppBinFltrCtrMsg1 = $SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Ctr
  write"<><> cEVS3101 passed"
  ut_setrequirements cEVS3101, "P"
else
  write "Unexpected result for un-registered test application name"
  ut_setrequirements cEVS3101, "F"
  write" cEVS3101 failed"
  ut_setrequirements cEVS3101, "F"
  write" cEVS3101 failed at check of un-registered application information"
  goto end_it
endif
 
write ";***********************************************************************"
write "; Step 4.3: Request generation of every type of event message. These "
write ";           messages should not be generated since the Test App has "
write ";           un-registered from EVS. "
write ";***********************************************************************"
write
write "*** EVS Total Msgs sent (local) = ", EVS_total_msgs_sent
write "*** EVS Total Msgs sent (EVS)   = ", $SC_$CPU_EVS_MSGSENTC
write
;
start $sc_$cpu_evs_app_unreg   ; request generation of event messages of every evt msg type
EVS_total_msgs_sent = EVS_total_msgs_sent + 1
 
write ";***********************************************************************"
write "; Step 4.4: Retrieve the Application Data and the local EVS Log and "
write ";           verify that the appropriate counters are correct."
write ";***********************************************************************"
write
write "*** EVS Total Msgs sent (local) = ", EVS_total_msgs_sent
write "*** EVS Total Msgs sent (EVS)   = ", $SC_$CPU_EVS_MSGSENTC
write
;
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "411.log", "$CPU")
wait 20
EVS_total_msgs_sent = EVS_total_msgs_sent + 1

;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "411.tst_appdat", "$CPU")
wait 20
EVS_total_msgs_sent = EVS_total_msgs_sent + 2
;
;Verify un-registered application counter increments"
;EVS evt msg sent counter does NOT increment "
;NO increment to App evt ctr NOR for the evt filter ctr corresponding to event"
;
if ($SC_$CPU_EVS_UNREGAPPC = 1) then
  ut_setrequirements cEVS3103_1, "P"
  write "cEVS3103.1 passed and it is fully verified"
  ut_setrequirements cEVS3018f, "P"
  write "cEVS3018f passed "
else
  ut_setrequirements cEVS3103_1, "F"
  ut_setrequirements cEVS3018f, "F"
  write "ALERT: cEVS3103.1 & cEVS3018f failed, wrong value for unregistered App ctr. Expected 8."
endif

write "Un-registered App counter = ", $SC_$CPU_EVS_UNREGAPPC

;
if ($SC_$CPU_EVS_AppData[added_app_location].EventCounter = 0 ) AND ;;
   ($SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Ctr = 0) then
  write "values found as expected"
else
  write " ALERT! ALERT!, unexpected values for added app"
endif

write ";<><> App evt msg ctr info   = ", $SC_$CPU_EVS_AppData[added_app_location].EventCounter 
write ";<><> Evt msg id info        = ", $SC_$CPU_EVS_AppData[added_app_location].BinFltr[1].Ctr
 
write ";***********************************************************************"
write "; Step 4.5: Re-Register the TST_EVS Application with EVS."
write ";***********************************************************************"
write
write "*** EVS Total Msgs sent (local) = ", EVS_total_msgs_sent
write "*** EVS Total Msgs sent (EVS)   = ", $SC_$CPU_EVS_MSGSENTC
write
;
ut_setupevt $sc, $cpu, TST_EVS, 16, INFO

/$SC_$CPU_TST_EVS_Register
wait 10
 
; Verify the expected event was generated
if ($SC_$CPU_num_found_messages = 1) then
  write "Test Application status evt msg text: ", $SC_$CPU_find_event[1].event_txt 
  write" cEVS3100 passed and it is fully tested "
  ut_setrequirements cEVS3100, "P"
  start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "421.tst_appdat", "$CPU")
  wait 20 
  EVS_total_msgs_sent = EVS_total_msgs_sent + 2
else
  write" cEVS3100 failed " 
  ut_setrequirements cEVS3100, "F"
  write"ALERT, ALERT! No event message found to indicate Re-registraton of Test Application"
  write"ALERT! The test is now over because the test application failed to Re-register for EVS"
  goto end_it ; end the test
endif
 
write ";***********************************************************************"
write "; Step 4.6: Verification of application information is correct for the"
write ";           TST_EVS Application."
write ";***********************************************************************"
write
write "*** EVS Total Msgs sent (local) = ", EVS_total_msgs_sent
write "*** EVS Total Msgs sent (EVS)   = ", $SC_$CPU_EVS_MSGSENTC
write
;
app_data_at_init = 0

;
start $sc_$cpu_evs_test_app_info(app_data_at_init)  ; to output test app info
;
;write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
;
start $sc_$cpu_evs_fltrinfo  ; to output binary filter information from app stored info
 
;write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
;
EVS_total_msgs_sent  = EVS_total_msgs_sent  + 1
;
;write "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
;
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)
 
; Set the Total Message Counter to the TLM point in order to avoid all 
; subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
write
write "*** EVS Total Msgs sent (local) = ", EVS_total_msgs_sent
write "*** EVS Total Msgs sent (EVS)   = ", $SC_$CPU_EVS_MSGSENTC
write
 
write ";***********************************************************************"
write "; Step 4.7: Enable DEBUG Event Messages for TST_EVS."
write ";***********************************************************************"
;
/$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION="TST_EVS" DEBUG 
wait 5
 
write ";***********************************************************************"
write "; Conditions for requirement cEVS3103 for Test Application *"
write "; Event Service Enable Status is Enabled                   *"
write "; Event Type Enable Status is Enabled for the              *"
write "; Event Type of the request-specified Event Message        *"
write "; Application registered message filtering                 *"
write "; algorithm indicates the message should be sent           *"
write ";***********************************************************************"
 
write ";***********************************************************************"
write "; Step 4.8: Request the generation of Filtered and non-filtered evt msgs"
write ";           of every evt msg type." 
write ";***********************************************************************"
;
start $sc_$cpu_evs_gen_evts    ; request generation of event messages of every evt msg type
 
write ";***********************************************************************"
write "; Step 4.9: Retrieve the Local Evt Log and Application Data to verify "
write ";           the event msg generation as requested"
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "4221.log", "$CPU")
wait 20
 
;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "4221.tst_appdat", "$CPU")
wait 20
 
; Verify the counters
test_app_expected_counter = test_app_expected_counter + 8
EVS_total_msgs_sent  = EVS_total_msgs_sent  + 12
AppBinFltrCtrMsg1 = AppBinFltrCtrMsg1 + 4
 
;
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)
 
; Set the Total Message Counter to the TLM point in order to avoid all 
; subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
 
write ";***********************************************************************"
write "; Step 5.0: Specific Event Message Type Generation Test "
write ";***********************************************************************"
write "; Step 5.1: Request the generation of an INFO evt msg with a Signed "
write ";	   Character Data Type value."
write ";***********************************************************************"
;
ut_setupevt $sc, $cpu, TST_EVS, 8, INFO
wait 3
 
/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "8" Iters = "1" Milliseconds = "0"
wait 2

;
if ($SC_$CPU_num_found_messages = 1) then
  ut_setrequirements cEVS3103_2, "P"
  write" cEVS3103.2 passed"
else 
  ut_setrequirements cEVS3103_2, "F"
  write" cEVS3103.2 failed "
endif
 
write ";***********************************************************************"
write "; Step 5.2: Request the generation of an INFO evt msg with an Un-signed"
write ";	   Character Data Type value."
write ";***********************************************************************"
;
ut_setupevt $sc, $cpu, TST_EVS, 9, INFO
wait 3

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "9" Iters = "1" Milliseconds = "0"
wait 2
 
; Check if the expected event was rcv'd
if ($sc_$cpu_num_found_messages = 1) then
  ut_setrequirements cEVS3103_2, "P"
  write" cEVS3103.2 passed"
else
  ut_setrequirements cEVS3103_2, "F"
  write" cEVS3103.2 failed"
endif             
 
write ";***********************************************************************"
write "; Step 5.3: Request the generation of an INFO evt msg with a Short "
write "; 	   Integer Data Type value."
write ";***********************************************************************"
;
ut_setupevt $sc, $cpu, TST_EVS, 10, INFO
wait 3

;
/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "10" Iters = "1" Milliseconds = "0"
wait 2 
;
if ($SC_$CPU_num_found_messages = 1) then
  ut_setrequirements cEVS3103_2, "P"
  write" cEVS3103.2 passed"
else
  ut_setrequirements cEVS3103_2, "F"
  write" cEVS3103.2 failed"
endif             
 
write ";***********************************************************************"
write "; Step 5.4: Request the generation of an INFO evt msg with an Unsigned "
write "; 	   Short integer Data Type value."
write ";***********************************************************************"
;
ut_setupevt $sc, $cpu, TST_EVS, 11, INFO
wait 3

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "11" Iters = "1" Milliseconds = "0"
wait 4

;
if ($SC_$CPU_num_found_messages = 1) then
  ut_setrequirements cEVS3103_2, "P"
  write" cEVS3103.2 passed"
else
  ut_setrequirements cEVS3103_2, "F"
  write" cEVS3103.2 failed"
endif             
 
write ";***********************************************************************"
write "; Step 5.5: Request the generation of an INFO evt msg with a Signed "
write ";  	   Integer Data Type value."
write ";***********************************************************************"
;
ut_setupevt $sc, $cpu, TST_EVS, 12, INFO
wait 3

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "12" Iters = "1"  Milliseconds = "0"
wait 4

;
if ($SC_$CPU_num_found_messages = 1) then
  ut_setrequirements cEVS3103_2, "P"
  write" cEVS3103.2 passed"
else 
  ut_setrequirements cEVS3103_2, "P"
  write" cEVS3103.2 failed "
endif
 
write ";***********************************************************************"
write "; Step 5.6: Request the generation of an INFO evt msg with an Unsigned "
write ";  	   Integer Data Type value."
write ";***********************************************************************"
;
ut_setupevt $sc, $cpu, TST_EVS, 13, INFO
wait 3

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "13" Iters = "1" Milliseconds = "0"
wait 4 

;
if ($SC_$CPU_num_found_messages = 1) then 
  ut_setrequirements cEVS3103_2, "P"
  write" cEVS3103.2 passed"
else
  ut_setrequirements cEVS3103_2, "F"
  write" cEVS3103.2 failed"
endif             

write ";***********************************************************************"
write "; Step 5.7: Retrieve Log and Stored Application Data" 
write ";***********************************************************************"
;
start get_file_to_cvt ("RAM:0", "cfe_evs.log", "507.log", "$CPU")
wait 20

;
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "507.tst_appdat", "$CPU")
wait 20
 
;; Verify counter incrementation:
;;   App evt msg sent ctr increments
;;   EVS evt msg sent ctr increments
;;   App evt msg registered for filtering does not increment"
;
test_app_expected_counter = test_app_expected_counter + 6
EVS_total_msgs_sent  = EVS_total_msgs_sent  + 9

;
start $sc_$cpu_evs_ctr_check(test_app_expected_counter,EVS_total_msgs_sent,AppBinFltrCtrMsg1)
 
; Set the Total Message Counter to the TLM point in order to avoid all 
; subsequent tests to fail if the cnt is off
EVS_total_msgs_sent = $SC_$CPU_EVS_MSGSENTC
 
; Set this requirement to Analyze
ut_setrequirements cEVS3109, "A"

write ";***********************************************************************"
write "; Requirements Tested:"
write "; Note: Requirement cEVS3004 is assigned a value of P is this test;" 
write ";       it is only partially tested here. The requirement is also tested"
write ";       in the EVS Processor Reset Test."
write ";       Requirement cEVS3109 has a value of A at this point. It shall "
write ";       only be assigned a value of P on the test summary after manual "
write ";       inspection of a hard copy of the file obtained from the enabled "
write ";       output port"
write ";***********************************************************************"

;
end_it:
LOCAL rqmt_p_or_f
local cfe_requirements[0 .. ut_req_array_size] = ["cEVS3004", "cEVS3007", "cEVS3008", "cEVS3012", "cEVS3018e", "cEVS3018f", "cEVS3018k_1", "cEVS3018k_2", "cEVS3100", "cEVS3100.1", "cEVS3100.2", "cEVS3100.3", "cEVS3101", "cEVS3102", "cEVS3103", "cEVS3103.1", "cEVS3103.2", "cEVS3103.3", "cEVS3103.4.1", "cEVS3103.6", "cEVS3103.7", "cEVS3104", "cEVS3105", "cEVS3109"]
FOR i = 0 to ut_req_array_size DO
  ut_pfindicate {cfe_requirements[i]} {ut_requirement[i]}
ENDDO
;
drop ut_req_array_size
drop ut_requirement
;
;**********************************************************************
write" END of PROCEDURE "
;**********************************************************************
ENDPROC
;**********************************************************************
