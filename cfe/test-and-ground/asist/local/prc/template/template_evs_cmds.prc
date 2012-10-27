proc $sc_$cpu_evs_cmds
;*****************************************************************************
;
; Test Name:  EVS_Cmd
; Test Level: Build Verification
; Test Type:  Functional
; Test Description
;    The purpose of this test is to verify the CFE_EVS Command functionality for
;    the Event Service (CFE_EVS) function of the Core Flight Executive (cFE)
;    software. The operation of all CFE_EVS commands will be verified for valid
;    and invalid commands. Valid commands for event logging and binary filter
;    processing will be tested in their respective test applications. Invalid
;    commands will be sent via STOL raw commands.  Appropriate telemetry will be
;    examined to verify proper action of the CFE_EVS command issued. 
;    The TST_EVS test application will be used as needed to send commands 
;    not available thru cFE core applications.
; 
; Requirements Tested
;
; cEVS3000        Upon receipt of Command the cFE shall enable/disable, as
;		  specified in the Command, the future generation of Event
;		  Messages for the Command-specified Event Type.
;
; cEVS3002     Upon receipt of Command the cFE shall generate a NO-OP event
;		  message.
;
; cEVS3003     Upon receipt of Command the cFE shall set the following counters 
;                 to zero in Event Services telemetry.
;                 * Valid Command Counter
;	          * Invalid Command Counter
;                 * Event Message Sent Counter
;                 * Event Message Truncation Counter
;	          * Unregistered Application Send Counter
;
; cEVS3004        Upon receipt of Command, the cFE shall write the following
;		  information to the Command specified cFE EVS Application Data
;                 file for each registered Application:
;                 . Application Event Message Sent Counter
;                 . Application Event Service Enable Status
;                 . Application Event Type Enable Statuses (one per Event Type)
;                 . Application Event IDs (for events to be filtered)
;                 . Application Binary Filter Masks (one per registered EventID)
;                 . Application Binary Filter Cntrs (one per registered EventID)
;
; cEVS3004.1      If a file is not specified, the cFE shall use the 
;                 <PLATFORM_DEFINED> filename. 
;
; cEVS3005        Upon receipt of valid command, the cFE shall increment the
;		  valid command counter.
;
; cEVS3006        Upon receipt of an invalid command, the cFE shall increment
;                 the invalid command counter.
; 
; cEVS3007        Upon receipt of Command the cFE shall enable/disable, as
;		  specified in the Command, the future generation of Event
;		  Messages for the Command-specified Application and Event Type.
;
; cEVS3008        Upon receipt of Command the cFE shall enable/disable, as
;		  specified in the Command, the future generation of Event
;		  Messages for the Command-specified Application.
;
; cEVS3009        Upon receipt of Command, the cFE shall set the Command-
;		  specified Application's Event Message Sent Counter to zero.
;
; cEVS3010        Upon receipt of Command, the cFE shall set an Application's
;		  Binary Filter Counter to zero for the Command-specified Event;
;		  ID.
;
; cEVS3011        Upon receipt of Command, the cFE shall set all of an
;		  Application's Binary Filter Counters to zero.
;
; cEVS3017        Upon receipt of Command the cFE shall enable/disable, as
;		  specified in the Command, the routing of all future Event
;		  Messages to the Command-specified Event Message Port.
;
; cEVS3018        The cFE shall provide the following Event Service data items
;                 in telemetry (SB Messages):
;                 . Valid Command Counter
;                 . Invalid Command Counter
;                 . Event Message Sent Counter
;                 . Event Message Truncation Counter
;                 . Unregistered Application Send Counter
;                 . Event Message Output Port Enable Statuses
;                 . For each registered Application:
;                   . Application Event Message Sent Counter
;                   . Application Event Service Enable Status
;
; Prerequisite Conditions:
; Availability of the TST_EVS test application To send event messages 
; according to the following specifications:
; 
; 1a. Command, /TST_EVS_SendEvMsg, to the Test Application with 
;     the following parameters:
;     Event Id
;     Event Type (Debug | Information | Error | Critical)
;     Number of Iterations 
;
; 1b. In response to the command, the application requests the generation 
;     of the command-specified Event Message with the command-specified
;     Event Type. The request will be made the number of times specified
;     in the iterations parameter. In most cases the test string is:
;
;     'Iteration No. = ' %d, 'Msg ID = '  %d , Where n is the current number 
;     within the iteration.
;
; Assumptions and Constraints:
; All cFE applications can generate DEBUG, INFO, ERROR, and CRIT event 
; types.
;
; Change History
;
;     Date	 Name         Description
;     ----       -----------  -----------
;     06/27/05   S. Applebee  Original Procedure
;     07/25/05   S. Applebee  Post Walkthru Enhancements
;     08/08/05   S. Applebee  Additional Post Walkthru changes 
;     04/12/06   E. Stattel   Run with Bld 3.1 of cFE FSW
;                             DEBUG evt msg type status is DISABLE by default
;                             while INFO, ERR and CRIT are ENABLE
;                             CFE_TBL task has been added since Bld 1 of cFE FSW
;                             And all no-op evt msgs are of type INFO 
;     06/02/06   E.Stattel    Post walk through check for ERROR evt 
;                             msg ID 9 added where applicable
;                             Also changes to Evt msg Type statuses
;
;     06/07/06   EIS          Updated to run with LRO
;                             deleted all references to CI and TO because these
;                             applications are in flux.
;                             local variable added_app_lctn added
;                             made cfe_app_cnt itself minus 1 where applicable 
;
;     12/26/06   N. Schweiss  Update for cFE 4.0.
;
;     07/31/07	 W. Moleski   Added test for Rqmt 3300. Added a Power-On reset
;			      as the first command of the test. Re-ordered the
;			      Step numbers to be sequential.
;
;  Arguments
;
;     Name           Description
;     ----           -----------
;     TST_EVS        Test application to send event messages.
;
;  Procedures/Utilities Called
;         
;     Name                Description
;     ----                -----------
;     ut_runproc          Directive to formally run the procedure and capture
;                         the log file.
;     ut_sendcmd          Directive to send commands to the spacecraft  
;                         and wait for the command to be accepted/rejected 
;                         by the spacecraft. 
;     ut_sendrawcmd       Directive to send raw commands to the spacecraft 
;                         and wait for the command to be accepted/rejected 
;                         by the spacecraft. 
;     ut_setupevt         Directive to look for a particular event and increment
;                         a value in the CVT to indicate receipt.  
;     ut_tlmwait          Procedure to wait for a specified telemetry point to
;                         update to a specified value.
;     ut_pfindicate       Directive to print the pass fail status of a
;			  particular requirement number.
;     get_file_to_cvt     Procedure to write some specified FSW data to a file
;			  and then ftp the file from the FSW hardware to ASIST
;			  hardware and load file to the CVT.
;     load_start_app      Procedure to load and start a user application from
;                         the /s/opr/accounts/cfebx/apps/cpux  directory.
;     evs_send_debug, info, error, and crit
;                         sub-procedures to send evt msgs of every type
;
;  Expected Test Results and Analysis
;  CFE software will recognize and reject all invalid commands.
;  CFE software will correctly increment counts and process all valid
;     commands. 
;
;**********************************************************************
;  Define variables
;**********************************************************************
#include "ut_statusdefs.h"
#include "ut_cfe_info.h"
#include "cfe_platform_cfg.h"
#include "cfe_mission_cfg.h" 
;#include "tst_evs_events.h" 
#include "cfe_evs_events.h" 
#include "$sc_$cpu_is_app_loaded.prc"

local i = 0
local cfe_app_cnt = 8        ; dependant on number of apps being processed
local added_app_lctn = 0
local cfe_applications[cfe_app_cnt] = ["CFE_EVS", "CFE_SB", "CFE_ES", "CFE_TIME", "CFE_TBL", "CI_LAB_APP", "TO_LAB_APP", "TST_EVS"]
local cfe_debug_msgs[cfe_app_cnt] = [1,0,0,0,0,0,0,1]
local cfe_info_msgs[cfe_app_cnt] =  [1,1,1,1,1,1,1,1]
local cfe_error_msgs[cfe_app_cnt] = [0,0,0,0,0,0,0,1]
local cfe_crit_msgs[cfe_app_cnt] =  [0,0,0,0,0,0,0,1]

local cfe_port_cnt = 4
local cfe_ports[cfe_port_cnt] = ["PORT_ONE", "PORT_TWO", "PORT_THREE", "PORT_FOUR"]

local raw_command

local previous_event_type_status[cfe_app_cnt]
local current_event_type_status[cfe_app_cnt]
local event_type_status_flag[cfe_app_cnt]

local previous_app_msg_sent_ctr[cfe_app_cnt]
local current_app_msg_sent_ctr[cfe_app_cnt]
local msg_ctr_status_flag[cfe_app_cnt]

local previous_port_mask
local port_mask_status_flag

local previous_bin_fltr_ctr[cfe_app_cnt]
local current_bin_fltr_ctr[cfe_app_cnt]

local bin_fltr_msgs[cfe_app_cnt] =  [0,0,1,0,0,1,0,0]

local rqmt_ctr = 15
local cfe_requirements[rqmt_ctr] = ["cEVS3000", "cEVS3002", "cEVS3003", "cEVS3004", "cEVS3004_1", "cEVS3005", "cEVS3006", "cEVS3007", "cEVS3008", "cEVS3009", "cEVS3010", "cEVS3011", "cEVS3017", "cEVS3018", "cEVS3300"]
 
local cEVS3000 = "NOT TESTED"
local cEVS3002 = "NOT TESTED"
local cEVS3003 = "NOT TESTED" 
local cEVS3004 = "NOT TESTED"
local cEVS3004_1 = "U"
local cEVS3005 = "NOT TESTED" 
local cEVS3006 = "NOT TESTED" 
local cEVS3007 = "NOT TESTED" 
local cEVS3008 = "NOT TESTED" 
local cEVS3009 = "NOT TESTED" 
local cEVS3010 = "NOT TESTED"
local cEVS3011 = "NOT TESTED" 
local cEVS3017 = "NOT TESTED" 
local cEVS3018 = "NOT TESTED" 
local cEVS3018_vcc, cEVS3018_icc, cEVS3018_emsc, cEVS3018_emtc, cEVS3018_uasc 
local cEVS3018_emopes, cEVS3018_aemsc, cEVS3018_aeses
local cEVS3300 = "NOT TESTED" 

write ";***********************************************************************"
write "; Step 1.0: Test setup"
write ";***********************************************************************"
write "; Step 1.1: Command a Power-on Reset on $CPU"
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
write "; Step 1.2: Start the TST_EVS application."
write ";***********************************************************************"
;; Check if TST_EVS app is running
;;validation off

write "*** Initialization:  Load EVS Test App"
;;; 16 = TST_EVS_INIT_INF_EID
ut_setupevt $SC, $CPU, TST_EVS, TST_EVS_INIT_INF_EID, INFO

start load_start_app ("TST_EVS", "$CPU")
wait 10

start get_file_to_cvt ("RAM:0", "cfe_es_app_info.log", "cfe_es_app_info_afterinit.log", "$CPU")

IF ($sc_$cpu_is_app_loaded("TST_EVS") ) THEN
  write "***** Test Application TST_EVS initialization OK."
ELSE
  write "ALERT: Test Application TST_EVS failed to initialize !!!!"
  goto TST_APP_FAILED
ENDIF

write ";***********************************************************************"
write "; Step 1.3: Retrieve the application data file."
write ";***********************************************************************"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_11.dat", "$CPU")
wait 10
;Report of evt message type statuses for cFE core and added test apps
;
for i = 1 to CFE_ES_MAX_APPLICATIONS do
  if ($sc_$cpu_evs_AppData[i].AppName = "TST_EVS") then
    added_app_lctn = i
  endif
enddo
;
IF added_app_lctn > 0 THEN
  FOR i = 1 to cfe_app_cnt-1 DO
    write "  >>> Default status for every event message type "
    write " For app ", $sc_$cpu_EVS_AppData[i].AppName
    write " DEBUG = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
    write " INFO = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
    write " ERROR = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
    write " CRIT = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
    write " Evt msg types mask"
    write " CEID"
    write " ",$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
  ENDDO

  write " For app ", $sc_$cpu_EVS_AppData[added_app_lctn].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug

ELSE
   write "*** Warning; added_app_lctn = ", added_app_lctn
   wait 10
ENDIF
;
write ";***********************************************************************"
write "; Step 1.4: Generate application data file with filename argument and "
write ";           retrieve file."
write ";***********************************************************************"

local evs_cmd_cnt = $sc_$cpu_evs_cmdpc
local evs_err_cnt = $sc_$cpu_evs_cmdec
local work = %env("WORK") 
local remote_dir = "RAM:0"
local src_filename = "user_appdatafilename"
local write_app_data_arg = "/ram/" & src_filename 
local dest_filename =  "$sc_$cpu_" & src_filename
local dest_pathname = work & "/image/" & dest_filename
local evs_cmd = "/$SC_$CPU_EVS_WriteAppData2File AppDataFileName=" 
evs_cmd = evs_cmd & """"
evs_cmd = evs_cmd & write_app_data_arg
evs_cmd = evs_cmd & """"

write "EVS command/error counts: ", evs_cmd_cnt, "/", evs_err_cnt
write ">>>Write App Data File to ", write_app_data_arg

write "Sending Command: ", evs_cmd
%cmd (evs_cmd) 

wait until ((evs_cmd_cnt <> $SC_$CPU_evs_cmdpc) OR (evs_err_cnt <> $sc_$cpu_evs_cmdec)) timeout 20
write "EVS command/error counts: ", evs_cmd_cnt, "/", evs_err_cnt

write ">>>FTP ", src_filename, " to ", dest_filename
write
start ftp_file (remote_dir, src_filename , dest_filename, "$cpu", "g")
wait 10
IF file_exists(dest_pathname) THEN
  cEVS3004 =  "PASS"
  write "     *** Requirement cEVS3004 PASSED."
ELSE
  cEVS3004 = "FAIL"
  write "     *** Requirement cEVS3004 FAILED."
ENDIF
write

write ";***********************************************************************"
write "; Step 1.5: Generate application data file _without_ filename argument."
write ";***********************************************************************"
write "* Generate file on target machine "
write "EVS command/error counts: ", evs_cmd_cnt, "/", evs_err_cnt
write ">>>Write App Data File to default file. "
/$SC_$CPU_EVS_WriteAppData2File AppDataFileName= ""
wait until ((evs_cmd_cnt <> $SC_$CPU_evs_cmdpc) OR (evs_err_cnt <> $sc_$cpu_evs_cmdec)) timeout 20
write "EVS command/error counts: ", evs_cmd_cnt, "/", evs_err_cnt
write

write "* Transmit file to workstation"
src_filename = "cfe_evs_app.dat" ;default name
dest_filename =  "$sc_$cpu_" & src_filename
write ">>>FTP ", src_filename, " to ", dest_filename
write
start ftp_file (remote_dir, src_filename , dest_filename, "$cpu", "g")
wait 10

write "* Test for successful receipt of file"
dest_pathname = work & "/image/" & dest_filename
IF file_exists(dest_pathname) THEN
  cEVS3004_1 =  "PASS"
  write "     *** Requirement cEVS3004_1 PASSED."
ELSE
  cEVS3004_1 =  "FAILED"
  write "     *** Requirement cEVS3004_1 FAILED."
ENDIF
write

write ";***********************************************************************"
write "; Step 2.0: Send noop command."
write ";           Observe NOOP info message in ASIST event window"
write ";           cEVS3002"
write ";           cEVS3005"
write ";           cEVS3018 (Valid Command Counter)"
write ";***********************************************************************"

local cEVS3005_11 = "FAIL"
local cEVS3018_vcc_11
evs_cmd_cnt = $sc_$cpu_evs_cmdpc
evs_err_cnt = $sc_$cpu_evs_cmdec

;;; 0 = CFE_EVS_NOOP_EID
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_NOOP_EID, INFO
wait 5

write "EVS command/error counts: ", evs_cmd_cnt, "/", evs_err_cnt
/$SC_$CPU_EVS_NOOP
wait until ((evs_cmd_cnt <> $SC_$CPU_evs_cmdpc) OR (evs_err_cnt <> $sc_$cpu_evs_cmdec)) timeout 20
write "EVS command/error counts: ", evs_cmd_cnt, "/", evs_err_cnt

IF ($sc_$cpu_evs_cmdpc = evs_cmd_cnt + 1) THEN
   write 
   write "     Valid Command Counter incremented."
   cEVS3002 = "PASS"
   cEVS3005_11 = "PASS"
   cEVS3018_vcc_11 = "PASS"
   write "<*> Passed - (2.0)"
ELSE
   write "     Valid Command Counter NOT incremented."
   cEVS3002 = "FAIL"
   cEVS3005_11 = "FAIL"
   cEVS3018_vcc_11 = "FAIL"
   write "<!> Failed (3002;3005;3018) - (2.0)"
ENDIF

IF (cEVS3002 = "PASS") AND ($SC_$CPU_num_found_messages = 1) THEN
   write "     Event Message: ", $SC_$CPU_find_event[1].event_txt
   cEVS3002 = "PASS"
ELSE
   write "     $SC_$CPU_num_found_messages = ", $SC_$CPU_num_found_messages
   write "     NO-OP Event Message(s) NOT generated."
   cEVS3002 = "FAIL"
ENDIF 
write

write ";***********************************************************************"
write "; Step 3.0: Enable Application Event Types"
write ";     NOTE : For bld 3.1 although Valid range for Event Type is 0 - x'f'"
write ";            zero has no effect"
write ";***********************************************************************"
write "; Step 3.1: Application Event Type Command Test"
write ";***********************************************************************"
write "; Step 3.1.1: Send Enable Application Event Type command"
write ";             FSW indicates invalid command. Command Error count "
write ";             increments. Command Processed counter does not change."
write ";             Use value outside of valid range: 0 and F. "
write ";             Use cFE application that does not exist."
write ";             cEVS3006"
write ";             cEVS3007"
write ";             cEVS3018 (Invalid Command Counter)"
write ";***********************************************************************"

local cEVS3018_icc_211
local cEVS3018_icc_211a
local cEVS3018_icc_211c
;
local cEVS3006_211
local cEVS3006_211a
local cEVS3006_211c
;
local cEVS3007_211
local cEVS3007_211a
local cEVS3007_211c
;
write "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
write " >>> Cmd Error counter prior to sending cmd to Enable app" 
write "     evt msg type with mask 0 = ", $SC_$CPU_EVS_CMDEC
write " >>> Command execution counter prior to sending cmd with mask 0 = ", $SC_$CPU_EVS_CMDPC
;
write "     Sending command with APPLICATION=CFE_SB and EVENT TYPE with mask = 0"
evs_err_cnt = $SC_$CPU_EVS_CMDEC+1

/$SC_$CPU_EVS_ENAAPPEVTTYPEMASK APPLICATION="CFE_SB" BITMASK=X'0'  
wait 8

ut_tlmwait $SC_$CPU_EVS_CMDEC {evs_err_cnt}
IF (UT_TW_status = UT_Success) THEN
  write "<*> Passed - (3.1.1) "
  cEVS3006_211a = "PASS"
  cEVS3018_icc_211a = "PASS"
  cEVS3007_211a = "PASS"
ELSE
  write "<!> Failed (3006;3007;3018) - (3.1.1)"
  write "    Invalid Command Counter NOT incremented."
  cEVS3006_211a = "FAIL"
  cEVS3018_icc_211a = "FAIL"
  cEVS3007_211a = "FAIL"
ENDIF
 
write " >>> Cmd Error counter after sending command = ", $SC_$CPU_EVS_CMDEC
write " >>> Command execution counter after sending command = ", $SC_$CPU_EVS_CMDPC

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_211.dat", "$CPU")
wait 10
;
;event message types 
FOR i = 1 to cfe_app_cnt-1 DO
  write "  >>> Default status for every event message type "
  write " For app ", $sc_$cpu_EVS_AppData[i].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO

IF added_app_lctn > 0 THEN
  write " For app ", $sc_$cpu_EVS_AppData[added_app_lctn].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug

ELSE
   write "*** Warning; added_app_lctn = ", added_app_lctn
   wait 10
ENDIF
;
write ";***********************************************************************"
write "; Step 3.1.2: Disable DEBUG Event Message Type"
write ";             to continue testing Enable/Disable evt type status"
write ";***********************************************************************"
/$SC_$CPU_EVS_DISEVENTTYPE DEBUG 

write ";***********************************************************************"
write "; Step 3.1.3: Command to Enable Evt Msg Type"
write ";             Sending command with invalid Application Name"        
write ";***********************************************************************"

local local_cmd_error_ctr = $SC_$CPU_EVS_CMDEC

local_cmd_error_ctr = local_cmd_error_ctr + 1

;;; 9 = CFE_EVS_ERR_NOAPPIDFOUND_EID
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_NOAPPIDFOUND_EID, ERROR
wait 5

Ut_sendcmd "$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION=""CFE_"" DEBUG"

ut_tlmwait $SC_$CPU_EVS_CMDEC, {local_cmd_error_ctr}

write

IF (ut_sc_status = UT_SC_CmdFailure) THEN
   write "     CFE_ is NOT a valid application."
   write "     Invalid Command Counter incremented."
   write "<*> Passed - (3.1.3)"
   cEVS3006_211c = "PASS"
   cEVS3018_icc_211c = "PASS"
   cEVS3007_211c = "PASS"
ELSE
   write "     Invalid Command Counter NOT incremented."
   write "<!> Failed (3006;3007;3018) - (3.1.3)"
   cEVS3006_211c = "FAIL"
   cEVS3018_icc_211c = "FAIL"
   cEVS3007_211c = "FAIL"

ENDIF
IF ($SC_$CPU_num_found_messages <> 1) THEN
   write "     Event Message NOT generated."
ELSE
   write "     Event Message: ", $SC_$CPU_find_event[1].event_txt
ENDIF

IF (cEVS3006_211a = "PASS") AND (cEVS3006_211c = "PASS") THEN
  cEVS3006_211 = "PASS"
ELSE
  cEVS3006_211 = "FAIL"
ENDIF

IF (cEVS3007_211a = "PASS") AND (cEVS3007_211c = "PASS") THEN
  cEVS3007_211 = "PASS"
ELSE
  cEVS3007_211 = "FAIL"
ENDIF

IF (cEVS3018_icc_211a = "PASS") AND (cEVS3018_icc_211c = "PASS") THEN
  cEVS3018_icc_211 = "PASS"
ELSE
  cEVS3018_icc_211 = "FAIL"
ENDIF
write
;
write ";***********************************************************************"
write "; Step 3.1.4: Command to Enable Evt Msg Type"
write ";             to continue testing Disable/Enable evt type status"        
write ";***********************************************************************"

/$SC_$CPU_EVS_ENAEVENTTYPE DEBUG
wait 10
 
; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_2115.dat", "$CPU")
wait 10
;
;event message types 
FOR i = 1 to cfe_app_cnt-1 DO
  write "  >>> Default status for every event message type "
  write " For app ", $sc_$cpu_EVS_AppData[i].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO
  write " For app ", $sc_$cpu_EVS_AppData[added_app_lctn].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug

write ";***********************************************************************"
write "; Step 3.2: Send command to Disable Application Event Type command"
write ";             cEVS3006"
write ";             cEVS3007"
write ";             cEVS3018 (Invalid Command Counter)"
write ";***********************************************************************"

local cEVS3018_icc_212
local cEVS3018_icc_212b
local cEVS3018_icc_212c

local cEVS3006_212

local cEVS3006_212b
local cEVS3006_212c

local cEVS3007_212

local cEVS3007_212b
local cEVS3007_212c

/$SC_$CPU_EVS_DISAPPEVTTYPEMASK APPLICATION="CFE_SB" BITMASK=X'0'  
wait 8
write

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_212.dat", "$CPU")
wait 10

IF (p@$sc_$cpu_EVS_AppData[2].EvtTypeAF.Debug = "DIS") THEN
  cEVS3006_211a = "FAIL"
  cEVS3018_icc_211a = "FAIL"
  cEVS3007_211a = "FAIL"
  write " ALERT: wrong status found for evt msg type DEBUG "
  write "<!> Failed (3006;3007;3018) - (3.2)"
ELSE
  write "<*> Passed (3006;3007;3018) - (3.2)"
  cEVS3006_211a = "PASS"
  cEVS3018_icc_211a = "PASS"
  cEVS3007_211a = "PASS"
ENDIF

write " >>> Cmd Error counter after sending command = ", $SC_$CPU_EVS_CMDEC
write " >>> Command execution counter after sending command = ", $SC_$CPU_EVS_CMDPC
write
;
;event message types 
FOR i = 1 to cfe_app_cnt-1 DO
  write "  >>> Default status for every event message type "
  write " For app ", $sc_$cpu_EVS_AppData[i].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO
  write " For app ", $sc_$cpu_EVS_AppData[added_app_lctn].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug

write ";***********************************************************************"
write "; Step 3.2.1: Send command to Disable Application Event Type"
write ";             Sending command with invalid Application Name"
write ";***********************************************************************"
; 
;;; 9 = CFE_EVS_ERR_NOAPPIDFOUND_EID
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_NOAPPIDFOUND_EID, ERROR
wait 5
Ut_sendcmd "$SC_$CPU_EVS_DISAPPEVTTYPE APPLICATION=""CFE_"" DEBUG"
write
IF (ut_sc_status = UT_SC_CmdFailure) THEN
   write "     CFE_ is NOT a valid application for Disable Application Event Type command."
   write "     Invalid Command Counter incremented."
   write "<*> Passed (3006;3007;3018) - (3.2.1)"
   cEVS3006_212c = "PASS"
   cEVS3018_icc_212c = "PASS"
   cEVS3007_212c = "PASS"
ELSE
   write "     Invalid Command Counter NOT incremented."
   write "<!> Failed (3006;3007;3018) - (3.2.1)"
   cEVS3006_212c = "FAIL"
   cEVS3018_icc_212c = "FAIL"
   cEVS3007_212c = "FAIL"
ENDIF
IF ($SC_$CPU_num_found_messages = 1) THEN
   write "     Event Message: ", $SC_$CPU_find_event[1].event_txt  
ELSE
   write "     Event Message NOT generated."
ENDIF

IF (cEVS3006_212c = "PASS") THEN
  cEVS3006_212 = "PASS"
ELSE
  cEVS3006_212 = "FAIL"
ENDIF

IF (cEVS3007_212c = "PASS") THEN
  cEVS3007_212 = "PASS"
ELSE
  cEVS3007_212 = "FAIL"
ENDIF

IF (cEVS3018_icc_212c = "PASS") THEN
  cEVS3018_icc_212 = "PASS"
ELSE
  cEVS3018_icc_212 = "FAIL"
ENDIF

write 

write ";***********************************************************************"
write "; Step 3.2.2: Send Disable Application Event Type for DEBUG messages "
write ";             for each cFE application: CFE_SB, CFE_ES, CFE_EVS, "
write ";             CFE_TIME, TST_EVS"
write ";             Telemetry indicates DEBUG messages ENABLE."
write ";             cEVS3004"
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3004_aetes_221 = "PASS"
local cEVS3007_221 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_221.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug 
FOR i = 1 to cfe_app_cnt-1 DO
  /$SC_$CPU_EVS_DISAPPEVTTYPE APPLICATION=cfe_applications[i] DEBUG
  wait 5
ENDDO
/$SC_$CPU_EVS_DISAPPEVTTYPE APPLICATION="TST_EVS" DEBUG
wait 5

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_221a.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug 
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug 

write "" 
write "     DEBUG message status"
write "     --------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       cEVS3004_aetes_221 = "FAIL"
       cEVS3007_221 = "FAIL"
       write "<!> Failed - (3.2.2)"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write

write ";***********************************************************************"
write "; Step 3.2.3: Send DEBUG message for each cFE application: CFE_SB, "
write ";             CFE_ES, CFE_EVS,CFE_TIME, TST_EVS	"
write ";             Messages not processed by CFE_EVS."
write ";             Verify by telemetry message counts not incrementing."
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3007_222 = "PASS"

local evt_msg_sent_ctr_offset = [0,0,0,0,0,0,0,0]

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_222.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_debug

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_222a.dat", "$CPU")
wait 20

FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
     msg_ctr_status_flag[i] = "OK"
     msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     write "<!> Failed - (3.2.3)"

     cEVS3007_222 = "FAIL"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ""

write ";***********************************************************************"
write "; Step 3.2.4: Send Disable Application Event Type command for INFO msgs" 
write ";             for each cFE application: CFE_SB, CFE_ES, CFE_EVS, "
write ";             CFE_TIME, TST_EVS"
write ";             Telemetry indicates INFO messages disabled."
write ";             cEVS3004"
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3004_aetes_223 = "PASS"
local cEVS3007_223 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_223.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info 

FOR i = 1 to cfe_app_cnt-1 DO
  write "     Sending DISABLE APPLICATION EVENT TYPE (INFO) command for Application: ", cfe_applications[i]

  evs_cmd_cnt = $sc_$cpu_evs_cmdpc
  evs_err_cnt = $sc_$cpu_evs_cmdec
  /$SC_$CPU_EVS_DISAPPEVTTYPE APPLICATION=cfe_applications[i] INFO
  wait until ((evs_cmd_cnt <> $SC_$CPU_evs_cmdpc) OR (evs_err_cnt <> $sc_$cpu_evs_cmdec)) timeout 20
  write "EVS command/error counts: ", evs_cmd_cnt, "/", evs_err_cnt
ENDDO

  write "     Sending DISABLE APPLICATION EVENT TYPE (INFO) command for Application: ", cfe_applications[cfe_app_cnt]
  evs_cmd_cnt = $sc_$cpu_evs_cmdpc
  evs_err_cnt = $sc_$cpu_evs_cmdec
  /$SC_$CPU_EVS_DISAPPEVTTYPE APPLICATION="TST_EVS" INFO
  wait until ((evs_cmd_cnt <> $SC_$CPU_evs_cmdpc) OR (evs_err_cnt <> $sc_$cpu_evs_cmdec)) timeout 20
  write "EVS command/error counts: ", evs_cmd_cnt, "/", evs_err_cnt

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_223a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
write "" 
write "     INFO message status"
write "     --------------------"
;EIS
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND;;
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_223 = "FAIL"
       cEVS3007_223 = "FAIL"
       write "<!> Failed - (3.2.4)"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]
write

write ";***********************************************************************"
write "; Step 3.2.5: Send INFO message for each cFE application: CFE_SB, "
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS"
write ";             Messages not processed by CFE_EVS."
write ";             Verify by telemetry INFO message counts not incrementing."
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3007_224 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_224.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
 previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[cfe_app_cnt].EventCounter 

s $sc_$cpu_evs_send_info

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_224a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[cfe_app_cnt].EventCounter

write "" 
write "     Msg Sent Counter"
write "     ----------------"

evt_msg_sent_ctr_offset = [0,0,0,0,0,0,0,0]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3007_224 = "FAIL"
     write "<!> Failed - (3.2.5)"
   ENDIF
      
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]
write

write ";***********************************************************************"
write "; Step 3.2.6: Send Disable Application Event Type command for ERROR "
write ";             messages for each cFE application: CFE_SB, CFE_ES, "
write ";             CFE_EVS, CFE_TIME, TST_EVS"
write ";             Telemetry indicates ERROR messages disabled."
write ";             cEVS3004"
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3004_aetes_225 = "PASS"
local cEVS3007_225 = "PASS"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_225.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err 

FOR i = 1 to cfe_app_cnt-1 DO
  write "     Sending DISABLE APPLICATION EVENT TYPE (ERROR) command for Application: ", cfe_applications[i]

  /$SC_$CPU_EVS_DISAPPEVTTYPE APPLICATION=cfe_applications[i] ERROR
  wait 5
ENDDO
/$SC_$CPU_EVS_DISAPPEVTTYPE APPLICATION="TST_EVS" ERROR
wait 5

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_225a.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
ENDDO
write "" 
write "     ERROR message status"
write "     --------------------"

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND;;
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_225 = "FAIL"
       cEVS3007_225 = "FAIL"
       write "<!> Failed - (3.2.6)"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 3.2.7: Send ERROR message for each cFE application: CFE_SB, "
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS"
write ";             Messages not processed by CFE_EVS."
write ";             Verify by telemetry ERROR message counts not incrementing."
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3007_226 = "PASS"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_226.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[cfe_app_cnt].EventCounter

s $sc_$cpu_evs_send_error

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_226a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter
write "" 
write "     Msg Sent Counter"
write "     ----------------"
evt_msg_sent_ctr_offset = [0,0,0,0,0,0,0,0]
 
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i]  + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt]  + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3007_226 = "FAIL"
     write "<!> Failed - (3.2.7)"
   ENDIF
      
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write

write ";***********************************************************************"
write "; Step 3.2.8: Send Disable Application Event Type command for CRITICAL "
write ";             messages for each cFE application: CFE_SB, CFE_ES, "
write ";             CFE_EVS, CFE_TIME, TST_EVS "
write ";             Telemetry indicates CRITICAL messages disabled."
write ";             cEVS3004"
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3004_aetes_227 = "PASS"
local cEVS3007_227 = "PASS"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_227.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit

FOR i = 1 to cfe_app_cnt-1 DO
  write "     Sending DISABLE APPLICATION EVENT TYPE (CRIT) command for Application: ", cfe_applications[i]

  /$SC_$CPU_EVS_DISAPPEVTTYPE APPLICATION=cfe_applications[i] CRIT
  wait 5
ENDDO
/$SC_$CPU_EVS_DISAPPEVTTYPE APPLICATION="TST_EVS" CRIT
wait 5

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_227a.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit

write "" 
write "     CRITICAL message status"
write "     ----------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;;
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_227 = "FAIL"
       cEVS3007_227 = "FAIL"
       write "<!> Failed - (3.2.8)"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write

write ";***********************************************************************"
write "; Step 3.2.9: Send CRITICAL message for each cFE application: CFE_SB, "
write ";             CFE_ES, CFE_EVS, TO_APP, TST_EVS."
write ";             Messages not processed by CFE_EVS."
write ";             Verify by telemetry ctrs not incrementing."
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3007_228 = "PASS"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_228.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_crit

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_228a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter
write "" 
write "     Msg Sent Counter"
write "     ----------------"

evt_msg_sent_ctr_offset = [0,0,0,0,0,0,0,0]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i]  + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt]  + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3007_228 = "FAIL"
     write "<!> Failed - (3.2.9)"
   ENDIF
      
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 3.3: Enable Application Event Type Command Test"
write ";***********************************************************************"
write "; Step 3.3.1: Send Enable Application Event Type command for DEBUG msgs" 
write ";             for each cFE application: CFE_SB, CFE_ES, CFE_EVS, "
write ";             CFE_TIME, TST_EVS."
write ";             Telemetry indicates DEBUG messages enabled."
write ";             cEVS3004"
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3004_aetes_231 = "PASS"
local cEVS3007_231 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_231.dat", "$CPU")
wait 20

FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[cfe_app_cnt].EvtTypeAF.Debug 

FOR i = 1 to cfe_app_cnt DO
  write "     Sending ENABLE APPLICATION EVENT TYPE (DEBUG) command for Application: ", cfe_applications[i]

  /$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION=cfe_applications[i] DEBUG
  wait 5
ENDDO

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_231a.dat", "$CPU")
wait 20

FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug 
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug

write "" 
write "     DEBUG message status"
write "     --------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;;
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_231 = "FAIL"
       cEVS3007_231 = "FAIL"
       write "<!> Failed - (3.3.1)"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
 write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write

write ";***********************************************************************"
write "; Step 3.3.2: Send DEBUG message for each cFE application: CFE_SB, "
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS"
write ";             Expect evt msgs, DEBUG evt msg type status is ENABLE"
write ";             Messages processed by CFE_EVS."
write ";             Verify by telemetry message counts incrementing."
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3007_232 = "PASS"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_232.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter

s $sc_$cpu_evs_send_debug
wait 5

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_232a.dat", "$CPU")

wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter

write "" 
write "     Msg Sent Counter"
write "     ----------------"

;;;evt_msg_sent_ctr_offset = [4,0,0,0,0,1,0,0]
evt_msg_sent_ctr_offset = [2,0,0,0,0,0,0,1]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
     msg_ctr_status_flag[i] = "OK"
     msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3007_232 = "FAIL"
     write "<!> Failed - (3.3.2)"
   ENDIF
      
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 3.3.3: Send Enable Application Event Type command for INFO "
write ";             messages for each cFE application: CFE_SB, CFE_ES,"
write ";             CFE_EVS, CFE_TIME, TST_EVS.		"
write ";             Telemetry indicates INFO messages enabled."
write ";             cEVS3004"
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3004_aetes_233 = "PASS"
local cEVS3007_233 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_233.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info

FOR i = 1 to cfe_app_cnt-1 DO
  write "     Sending ENABLE APPLICATION EVENT TYPE (INFO) command for Application: ", cfe_applications[i]

  /$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION=cfe_applications[i] INFO
  wait 5
ENDDO
/$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION="TST_EVS" INFO
wait 5

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_233a.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info

write "" 
write "     INFO message status"
write "     --------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND;;
      (previous_event_type_status[i] = current_event_type_status[i]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_233 = "FAIL"
       cEVS3007_233 = "FAIL"
       write "<!> Failed - (3.3.3)"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]
write

write ";***********************************************************************"
write "; Step 3.3.4: Send INFO message for each cFE application: CFE_SB, "
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS.	"
write ";             Messages processed by CFE_EVS."
write ";             Verify by telemetry INFO message counts incrementing."
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3007_234 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_234.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
 previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter

s $sc_$cpu_evs_send_info

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_234a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

FOR i = 1 to cfe_app_cnt-1 DO
   IF ((previous_app_msg_sent_ctr[i] = current_app_msg_sent_ctr[i]) AND cfe_info_msgs[i]) AND;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) AND cfe_info_msgs[cfe_app_cnt]  THEN
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3007_234 = "FAIL"   
     write "<!> Failed - (3.3.4)"
   ELSE
     msg_ctr_status_flag[i] = "OK"
     msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 3.3.5: Send Enable Application Event Type command for ERROR "
write ";             messages for each cFE application: CFE_SB, CFE_ES, "
write ";             CFE_EVS, CFE_TIME, TST_EVS.		"
write ";             Telemetry indicates ERROR messages enabled."
write ";             cEVS3004"
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3004_aetes_235 = "PASS"
local cEVS3007_235 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_235.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err 

FOR i = 1 to cfe_app_cnt-1 DO
  write "     Sending ENABLE APPLICATION EVENT TYPE (ERROR) command for Application: ", cfe_applications[i]

  /$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION=cfe_applications[i] ERROR
  wait 5
ENDDO
/$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION="TST_EVS" ERROR
wait 5

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_235a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
write "" 
write "     ERROR message status"
write "     --------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;;
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_235 = "FAIL"
       cEVS3007_235 = "FAIL"
       write "<!> Failed - (3.3.5)"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]
write

write ";***********************************************************************"
write "; Step 3.3.6: Send ERROR message for each cFE application: CFE_SB,"
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS."
write ";             Messages processed by CFE_EVS."
write ";             Verify by telemetry message counts incrementing."
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3007_236 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_236.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter

s $sc_$cpu_evs_send_error

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_236a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter
write "" 
write "     Msg Sent Counter"
write "     ----------------"

FOR i = 1 to cfe_app_cnt-1 DO
   IF ((previous_app_msg_sent_ctr[i] = current_app_msg_sent_ctr[i]) AND cfe_error_msgs[i])  AND ;;
      ((previous_app_msg_sent_ctr[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) AND cfe_error_msgs[cfe_app_cnt]) THEN
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3007_236 = "FAIL"
     write "<!> Failed - (3.3.6)"
   ELSE
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]
write

;snap $sc_$cpu_EVS_APP_DATA_MAIN
;wait 15

write ";***********************************************************************"
write "; Step 3.3.7: Send Enable Application Event Type command for CRITICAL "
write ";             messages for each cFE application: CFE_SB, CFE_ES,"
write ";             CFE_EVS, CFE_TIME, TST_EVS.	"
write ";             Telemetry indicates CRITICAL messages enabled."
write ";             cEVS3004"
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3004_aetes_237 = "PASS"
local cEVS3007_237 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_237.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit 

FOR i = 1 to cfe_app_cnt-1 DO
  write "     Sending ENABLE APPLICATION EVENT TYPE (CRIT) command for Application: ", cfe_applications[i]

  /$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION=cfe_applications[i] CRIT
  wait 5
ENDDO
/$SC_$CPU_EVS_ENAAPPEVTTYPE APPLICATION="TST_EVS" CRIT
wait 5

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_237a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit

write "" 
write "     CRITICAL message status"
write "     -----------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;;
      (previous_event_type_status[i] = current_event_type_status[i]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"

       cEVS3004_aetes_237 = "FAIL"
       cEVS3007_237 = "FAIL"
       write "<!> Failed - (3.3.7)"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]
write

write ";***********************************************************************"
write "; Step 3.3.8: Send CRITICAL message for each cFE application: CFE_SB, "
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS.	"
write ";             Messages processed by CFE_EVS."
write ";             Verify by telemetry CRITICAL message counts incrementing."
write ";             cEVS3007"
write ";***********************************************************************"

local cEVS3007_238 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_238.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_crit

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_238a.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

FOR i = 1 to cfe_app_cnt-1 DO
   IF ((previous_app_msg_sent_ctr[i] = current_app_msg_sent_ctr[i]) AND cfe_crit_msgs[i]) AND ;;
      ((previous_app_msg_sent_ctr[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) AND cfe_crit_msgs[cfe_app_cnt])  THEN
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3007_238 = "FAIL"
     write "<!> Failed - (3.3.8)"
   ELSE
     msg_ctr_status_flag[i] = "OK"
     msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

; Disable status for DEBUG event message type before sending enabling command
;
/$SC_$CPU_EVS_DISEVENTTYPE DEBUG 
wait 8
;
; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_238.dat", "$CPU")
wait 10
;
;event message types 
FOR i = 1 to cfe_app_cnt-1 DO
  write "  >>> Default status for every event message type "
  write " For app ", $sc_$cpu_EVS_AppData[i].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO
  write " For app ", $sc_$cpu_EVS_AppData[added_app_lctn].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
;

write ";***********************************************************************"
write "; Step 4.0: Enable/Disable Event Types Test"
write ";***********************************************************************"
write "; Step 4.1: Enable DEBUG Event Type"
write ";***********************************************************************"
;           Valid value range x'0'-x'f'
; Set event msg type to respective status 
; in order to correctly test cmd to disable
; and enable event message types 
;

/$SC_$CPU_EVS_ENAEVENTTYPE DEBUG
wait 10

;
; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_30.dat", "$CPU")
wait 10
;
;event message types 
FOR i = 1 to cfe_app_cnt-1 DO
  write "  >>> Default status for every event message type "
  write " For app ", $sc_$cpu_EVS_AppData[i].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO
  write " For app ", $sc_$cpu_EVS_AppData[added_app_lctn].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
;

write ";***********************************************************************"
write "; Step 4.2: Disable Event Type Command Test"
write ";***********************************************************************"
write "; Step 4.2.1: Send Disable Event Type Command for DEBUG messages"
write ";            Telemetry indicates DEBUG messages enabled."
write ";            cEVS3000"
write ";            cEVS3004"
write ";***********************************************************************"

local cEVS3000_321 = "PASS"
local cEVS3004_aetes_321 = "PASS"

FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug 

Ut_sendcmd "$SC_$CPU_EVS_DISEVENTTYPE DEBUG"
wait 10

IF (ut_sc_status = UT_SC_Success) THEN
  write ""
  write "     DEBUG messages are ENABLED"
  write ""
ELSE
  write "     *** ALERT *** Command Error !!! "
ENDIF

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_321a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug

write "" 
write "     DEBUG message status"
write "     --------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;;
      (previous_event_type_status[i] = current_event_type_status[i]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_321 = "FAIL"
       cEVS3000_321 = "FAIL"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]
write

write ";***********************************************************************"
write "; Step 4.2.2: Send DEBUG message for each cFE application: CFE_SB,  "
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS "
write ";             Messages not processed by CFE_EVS. "
write ";             Expect NO generation of event messages. "
write ";             Verify by telemetry message counts incrementing. "
write ";             cEVS3000 "
write ";***********************************************************************"

local cEVS3000_322 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_322.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_debug

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_322a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter
write "" 
write "     Msg Sent Counter"
write "     ----------------"

evt_msg_sent_ctr_offset = [0,0,0,0,0,0,0,0]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3000_322 = "FAIL"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.2.3: Send Disable Event Type Command for INFO messages	"
write ";             Telemetry indicates INFO messages disabled."
write ";             cEVS3000"
write ";             cEVS3004"
write ";***********************************************************************"

local cEVS3004_aetes_323 = "PASS"
local cEVS3000_323 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_323.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info 

Ut_sendcmd "$SC_$CPU_EVS_DISEVENTTYPE INFO"
IF (ut_sc_status = UT_SC_Success) THEN
  write ""
  write "     INFO messages are DISABLED." 
  write ""
ELSE
  write "     *** ALERT *** Command Error !!! "
ENDIF
wait 10

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_323a.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info

write "" 
write "     INFO message status"
write "     --------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;;
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_323 = "FAIL"
       cEVS3000_323 = "FAIL"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO

write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.2.4:  Send INFO message for each cFE application: CFE_SB, "
write ";              CFE_ES, CFE_EVS, CFE_TIME, TST_EVS	"
write ";              Messages not processed by CFE_EVS."
write ";              Verify by telemetry INFO message counts not incrementing."
write ";              cEVS3000"
write ";***********************************************************************"

local cEVS3000_324 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_324.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter

s $sc_$cpu_evs_send_info

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_324a.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

evt_msg_sent_ctr_offset = [0,0,0,0,0,0,0,0]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3000_324 = "FAIL"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.2.5: Send Disable Event Type Command for ERROR messages	"
write ";             Telemetry indicates ERROR messages disabled."
write ";             cEVS3000"
write ";             cEVS3004"
write ";***********************************************************************"

local cEVS3000_325 = "PASS"
local cEVS3004_aetes_325 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_325.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err 

Ut_sendcmd "$SC_$CPU_EVS_DISEVENTTYPE ERROR"
IF (ut_sc_status = UT_SC_Success) THEN
  write ""
  write "     ERROR messages are DISABLED."
  write ""
ELSE
  write "     *** ALERT *** Command Error !!! "
ENDIF
wait 10

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_325a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err

write "" 
write "     ERROR message status"
write "     --------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;; 
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_325 = "FAIL"
       cEVS3000_325 = "FAIL"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]
write

write ";***********************************************************************"
write "; Step 4.2.6: Send ERROR message for each cFE application: CFE_SB, "
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS	"
write ";             Messages not processed by CFE_EVS."
write ";             Verify by telemetry ERROR message counts not incrementing."
write ";             cEVS3000"
write ";***********************************************************************"

local cEVS3000_326 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_326.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_error

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_326a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

evt_msg_sent_ctr_offset = [0,0,0,0,0,0,0,0]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3000_326 = "FAIL"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.2.7: Send Disable Event Type Command for CRITICAL messages"
write ";             Telemetry indicates CRITICAL messages disabled."
write ";             cEVS3000"
write ";             cEVS3004"
write ";***********************************************************************"

local cEVS3000_327 = "PASS"
local cEVS3004_aetes_327 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_327.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit 

Ut_sendcmd "$SC_$CPU_EVS_DISEVENTTYPE CRIT"
IF (ut_sc_status = UT_SC_Success) THEN
  write ""
  write "     CRITICAL messages are DISABLED."
  write ""
ELSE
  write "     *** ALERT *** Command Error !!! "
ENDIF
wait 10

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_327a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit

write "" 
write "     CRITICAL message status"
write "     -----------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;;
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_327 = "FAIL"
       cEVS3000_327 = "FAIL"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.2.8: Send CRITICAL message for each cFE application: CFE_SB, "
write ";             CFE_ES, CFE_EVS, CFE_TIME, CI_APP, TO_APP, TST_EVS	"
write ";             Messages not processed by CFE_EVS."
write ";             Verify by telemetry CRITICAL message counts not "
write ";	     incrementing."
write ";             cEVS3000"
write ";***********************************************************************"

local cEVS3000_328 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_328.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_crit

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_328a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

evt_msg_sent_ctr_offset = [0,0,0,0,0,0,0,0]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3000_328 = "FAIL"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.3: Disable Event Type Command Test"
write ";***********************************************************************"
write "; Step 4.3.1  To correctly test disabling of Evt Msg Types, ENABLE all "
write ";             evt msg types"
write ";***********************************************************************"

/$SC_$CPU_EVS_ENAEVENTTYPE DEBUG
wait 8
/$SC_$CPU_EVS_ENAEVENTTYPE INFO
wait 8
/$SC_$CPU_EVS_ENAEVENTTYPE ERROR
wait 8
/$SC_$CPU_EVS_ENAEVENTTYPE CRIT
wait 8

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_3281.dat", "$CPU")
wait 10
;
;event message types 
FOR i = 1 to cfe_app_cnt-1 DO
  write "  >>> Default status for every event message type "
  write " For app ", $sc_$cpu_EVS_AppData[i].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO
  write " For app ", $sc_$cpu_EVS_AppData[added_app_lctn].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug

write ";***********************************************************************"
write "; Step 4.3.2: Send Disable Event Type Command for DEBUG messages	"
write ";             Telemetry indicates DEBUG messages enabled. "
write ";             cEVS3000 "
write ";             cEVS3004 "
write ";***********************************************************************"

local cEVS3000_331 = "PASS"
local cEVS3004_aetes_331 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_321.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug 

Ut_sendcmd "$SC_$CPU_EVS_DISEVENTTYPE DEBUG"
IF (ut_sc_status = UT_SC_Success) THEN
  write ""
  write "     DEBUG messages are DISABLED."
  write ""
ELSE
  write "     *** ALERT *** Command Error !!! "
ENDIF
wait 10

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_321a.dat", "$CPU")
wait 20

FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug

write "" 
write "     DEBUG message status"
write "     --------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;; 
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_331 = "FAIL"
       cEVS3000_331 = "FAIL"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.3.3: Send DEBUG message for each cFE application: CFE_SB,  "
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS	 "
write ";             Messages processed by CFE_EVS. "
write ";             Expect no event msgs. "
write ";             Verify by telemetry counts not incrementing. "
write ";             cEVS3000 "
write ";***********************************************************************"

local cEVS3000_332 = "PASS"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_332.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_debug

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_332a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

FOR i = 1 to cfe_app_cnt DO
   IF (previous_app_msg_sent_ctr[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
      msg_ctr_status_flag[i] = "*** ALERT ***"
      msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3000_332 = "FAIL"
  ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.3.4: Send Enable Event Type Command for INFO messages	"
write ";             Telemetry indicates INFO messages enabled."
write ";             cEVS3000"
write ";             cEVS3004"
write ";***********************************************************************"

local cEVS3000_333 = "PASS"
local cEVS3004_aetes_333 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_333.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info 

Ut_sendcmd "$SC_$CPU_EVS_DISEVENTTYPE INFO"
IF (ut_sc_status = UT_SC_Success) THEN
  write ""
  write "     INFO messages are ENABLED."
  write ""
ELSE
  write "     *** ALERT *** Command Error !!! "
ENDIF
wait 10
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_333a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info

write "" 
write "     INFO message status"
write "     --------------------"

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;; 
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_333 = "FAIL"
       cEVS3000_333 = "FAIL"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.3.5: Send INFO message for each cFE application: CFE_SB, "
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS	"
write ";             Messages processed by CFE_EVS."
write ";             Verify by telemetry message counts incrementing."
write ";             cEVS3000"
write ";***********************************************************************"

local cEVS3000_334 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_334.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_info

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_334a.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3000_334 = "FAIL"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.3.6: Send Enable Event Type Command for ERROR messages"
write ";             Telemetry indicates ERROR messages enabled."
write ";             cEVS3000"
write ";             cEVS3004"
write ";***********************************************************************"

local cEVS3000_335 = "PASS"
local cEVS3004_aetes_335 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_335.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err

Ut_sendcmd "$SC_$CPU_EVS_DISEVENTTYPE ERROR"
IF (ut_sc_status = UT_SC_Success) THEN
  write ""
  write "     ERROR messages are ENABLED."
  write ""
ELSE
  write "     *** ALERT *** Command Error !!! "
ENDIF
wait 10

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_335a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err

write "" 
write "     ERROR message status"
write "     --------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;;
      (previous_event_type_status[i] = current_event_type_status[i]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_335 = "FAIL"
       cEVS3000_335 = "FAIL"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.3.7: Send ERROR message for each cFE application: CFE_SB, "
write ";             CFE_EVS, CFE_TIME, TST_EVS"
write ";             Messages processed by CFE_EVS."
write ";             Verify by telemetry ERROR message counts incrementing."
write ";             cEVS3000"
write ";***********************************************************************"

local cEVS3000_336 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_336.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_error

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_336a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[i] = current_app_msg_sent_ctr[i]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3000_336 = "FAIL"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 4.3.8: Send Enable Event Type Command for CRITICAL messages"
write ";             Telemetry indicates CRITICAL messages enabled."
write ";             cEVS3000"
write ";             cEVS3004"
write ";***********************************************************************"

local cEVS3000_337 = "PASS"
local cEVS3004_aetes_337 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_337.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit 
ENDDO
previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit 

Ut_sendcmd "$SC_$CPU_EVS_DISEVENTTYPE CRIT"
IF (ut_sc_status = UT_SC_Success) THEN
  write ""
  write "     CRITICAL messages are ENABLED."
  write ""
ELSE
  write "     *** ALERT *** Command Error !!! "
ENDIF
wait 10

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_337a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
ENDDO
current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit

write "" 
write "     CRITICAL message status"
write "     -----------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND  ;;
      (previous_event_type_status[i] = current_event_type_status[i]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aetes_337 = "FAIL"
       cEVS3000_337 = "FAIL"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write

write ";***********************************************************************"
write "; Step 4.3.9: Send CRITICAL message for each cFE application: CFE_SB,"
write ";             CFE_ES, CFE_EVS, CFE_TIME, TST_EVS	"
write ";             Messages processed by CFE_EVS."
write ";             Verify by telemetry CRITICAL message counts incrementing."
write ";             cEVS3000"
write ";***********************************************************************"

local cEVS3000_338 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_338.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_crit

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_338a.dat", "$CPU")
wait 10
;
;event message types 
FOR i = 1 to cfe_app_cnt-1 DO
  write "  >>> Default status for every event message type "
  write " For app ", $sc_$cpu_EVS_AppData[i].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO
  write " For app ", $sc_$cpu_EVS_AppData[added_app_lctn].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
;
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[i] = current_app_msg_sent_ctr[i]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3000_338 = "FAIL"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 5.0: Event Message Generation Test"
write ";***********************************************************************"
write "; Step 5.1: ENABLE event generation for all message types. "
write ";***********************************************************************"

/$SC_$CPU_EVS_ENAEVENTTYPE DEBUG
wait 8
/$SC_$CPU_EVS_ENAEVENTTYPE INFO
wait 8
/$SC_$CPU_EVS_ENAEVENTTYPE ERROR
wait 8
/$SC_$CPU_EVS_ENAEVENTTYPE CRIT
wait 8

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_3381.dat", "$CPU")
wait 10
;
;event message types 
FOR i = 1 to cfe_app_cnt-1 DO
  write "  >>> Default status for every event message type "
  write " For app ", $sc_$cpu_EVS_AppData[i].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO
  write " For app ", $sc_$cpu_EVS_AppData[added_app_lctn].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug

write ";***********************************************************************"
write "; Step 5.2: Invalid Event Message Generation Command Test"
write ";***********************************************************************"
write "; Step 5.2.1: Send Enable Event Generation command with invalid"
write ";             application name. FSW indicates invalid command. The "
write ";	     Command Error count increments. "
write ";             Command Processed counter does not change."
write ";    Requirements: "
write ";    cEVS3006, cEVS3008, cEVS3018 (Invalid Command Counter)"
write ";***********************************************************************"

local cEVS3006_411 

local cEVS3018_icc_411

local cEVS3008_411 
;;; 9 = CFE_EVS_ERR_NOAPPIDFOUND_EID
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_NOAPPIDFOUND_EID, ERROR
wait 5
Ut_sendcmd "$SC_$CPU_EVS_ENAAPPEVGEN APPLICATION=""CFE_"""

IF (ut_sc_status = UT_SC_CmdFailure) THEN
   write "     CFE_ is NOT a valid application."
   write "     Invalid Command Counter incremented."
   cEVS3006_411 = "PASS"
   cEVS3018_icc_411 = "PASS"
   cEVS3008_411 = "PASS"
   write "<*> Passed (3006;3008;3018) - (5.2.1)"
ELSE
   write "     Invalid Command Counter NOT incremented."
   cEVS3006_411 = "FAIL"
   cEVS3018_icc_411 = "FAIL"
   cEVS3008_411 = "FAIL"
   write "<!> Failed (3006;3008;3018) - (5.2.1)"
ENDIF
IF ($SC_$CPU_num_found_messages = 1) THEN
   write "     Event Message: ", $SC_$CPU_find_event[1].event_txt  
ELSE
   write "     Event Message NOT generated."
ENDIF
write 

write ";***********************************************************************"
write "; Step 5.2.2: Send invalid Disable Event Generation command"
write ";             FSW indicates invalid command. The Command Error count "
write ";	     increments. Command Processed counter does not change."
write ";             cEVS3006"
write ";             cEVS3008"
write ";             cEVS3018 (Invalid Command Counter)"
write ";***********************************************************************"

local cEVS3006_412 

local cEVS3018_icc_412 

local cEVS3008_412 
;;; 9 = CFE_EVS_ERR_NOAPPIDFOUND_EID
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_NOAPPIDFOUND_EID, ERROR
wait 5
Ut_sendcmd "$SC_$CPU_EVS_DISAPPEVGEN APPLICATION=""CFE_"""

IF (ut_sc_status = UT_SC_CmdFailure) THEN
   write "     CFE_ is NOT a valid application."
   write "     Invalid Command Counter incremented."
   cEVS3006_412 = "PASS"
   cEVS3018_icc_412 = "PASS"
   cEVS3008_412 = "PASS"
   write "<*> Passed (3006;3008;3018) - (5.2.2)"
ELSE
   write "     Invalid Command Counter NOT incremented."
   cEVS3006_412 = "FAIL"
   cEVS3018_icc_412 = "FAIL"
   cEVS3008_412 = "FAIL"
   write "<!> Failed (3006;3008;3018) - (5.2.2)"
ENDIF
IF ($SC_$CPU_num_found_messages = 1) THEN
   write "     Event Message: ", $SC_$CPU_find_event[1].event_txt  
ELSE
   write "     Event Message NOT generated."
ENDIF

write ";***********************************************************************"
write "; Step 5.3: Disable Application Event Generation Command Test"
write ";***********************************************************************"
write "; Step 5.3.1: Send Disable Application Event Generation Command for "
write ";             each application. Telemetry indicates that events are "
write ";	     disabled for each application."
write ";             cEVS3004"
write ";             cEVS3008"
write ";             cEVS3018"
write ";***********************************************************************"

local cEVS3004_aeses_422 = "PASS"
local cEVS3008_422 = "PASS"
local cEVS3018_aeses_422 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_422.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].ActiveFlag 
ENDDO
   previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].ActiveFlag 

FOR i = 1 to cfe_app_cnt-1 DO
  write "     Sending DISABLE APPLICATION EVENT GENERATION command for Application: ", cfe_applications[i]
  /$SC_$CPU_EVS_DISAPPEVGEN APPLICATION=cfe_applications[i]
  wait 5
ENDDO

/$SC_$CPU_EVS_DISAPPEVGEN APPLICATION="TST_EVS"
wait 5

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_422a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].ActiveFlag
ENDDO
  current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].ActiveFlag

write "" 
write "     APP EVENT message status"
write "     ------------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;;
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN 
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aeses_422 = "FAIL"
       cEVS3008_422 = "FAIL"
       cEVS3018_aeses_422 = "FAIL"
       write "<!> Failed (3004;3008;3018) - (5.3.1)"
   ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]
write

write ";***********************************************************************"
write "; Step 5.3.2: Send a DEBUG, INFO, ERROR, and CRIT command for cFE app"
write ";             Verify that app's commands are not processed."
write ";             cEVS3008"
write ";***********************************************************************"

local cEVS3008_423 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_423.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
   previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[cfe_app_cnt].EventCounter 

s $sc_$cpu_evs_send_debug

s $sc_$cpu_evs_send_info

s $sc_$cpu_evs_send_error

s $sc_$cpu_evs_send_crit

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_423a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
   current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[cfe_app_cnt].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"
;
evt_msg_sent_ctr_offset = [0,0,0,0,0,0,0,0]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3008_422 = "FAIL"
     write "<!> Failed - (5.3.2)"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]
write ""

write ";***********************************************************************"
write "; Step 5.4: Enable Application Event Generation Command Test "
write ";***********************************************************************"
write "; Step 5.4.1: Send Enable Application Event Generation Command for each"
write ";             application. Telemetry indicates that events are enabled "
write ";             for each app. "
write ";             cEVS3004 "
write ";             cEVS3008 "
write ";             cEVS3018 "
write ";***********************************************************************"

local cEVS3008_432 = "PASS"
local cEVS3004_aeses_432 = "PASS"
local cEVS3018_aeses_432 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_432.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].ActiveFlag 
ENDDO
   previous_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].ActiveFlag 

FOR i = 1 to cfe_app_cnt-1 DO
  write "     Sending ENABLE APPLICATION EVENT GENERATION command for Application: ", cfe_applications[cfe_app_cnt]
  /$SC_$CPU_EVS_ENAAPPEVGEN APPLICATION=cfe_applications[i]
  wait 5
ENDDO
/$SC_$CPU_EVS_ENAAPPEVGEN APPLICATION="TST_EVS"
wait 5

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_432a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_event_type_status[i] = p@$sc_$cpu_EVS_AppData[i].ActiveFlag
ENDDO
   current_event_type_status[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].ActiveFlag

write "" 
write "     APP EVENT message status"
write "     ------------------------"
FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_event_type_status[i] = current_event_type_status[i]) AND ;; 
      (previous_event_type_status[cfe_app_cnt] = current_event_type_status[cfe_app_cnt]) THEN
       event_type_status_flag[i] = "*** ALERT ***"
       event_type_status_flag[cfe_app_cnt] = "*** ALERT ***"
       cEVS3004_aeses_432 = "FAIL"
       cEVS3008_432 = "FAIL"
       cEVS3018_aeses_432 = "FAIL"
       write "<!> Failed (3004;3008;3018) - (5.4.1)"
    ELSE
       event_type_status_flag[i] = "OK"
       event_type_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_event_type_status[i] , " -> " , current_event_type_status[i], "   ", event_type_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_event_type_status[cfe_app_cnt] , " -> " , current_event_type_status[cfe_app_cnt], "   ", event_type_status_flag[cfe_app_cnt]

write

write ";***********************************************************************"
write "; Step 5.4.2: Send a DEBUG, INFO, ERROR, and CRIT command for cFE app"
write ";             Verify that app's commands are processed."
write ";             cEVS3008"
write ";***********************************************************************"

local cEVS3008_433 = "PASS"

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_433.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
   previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_debug

s $sc_$cpu_evs_send_info

s $sc_$cpu_evs_send_error

s $sc_$cpu_evs_send_crit

; Retrieve application data file
start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_433a.dat", "$CPU")
wait 10

FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
   current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"
;
;;;evt_msg_sent_ctr_offset = [6,2,2,2,2,4,0,0]
evt_msg_sent_ctr_offset = [3,2,2,2,2,1,2,4]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
     msg_ctr_status_flag[i] = "OK"
     msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3008_433 = "FAIL"
     write "<!> Failed - (5.4.2)"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

;event message types 
FOR i = 1 to cfe_app_cnt-1 DO
  write "  >>> Default status for every event message type "
  write " For app ", $sc_$cpu_EVS_AppData[i].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[i].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[i].EvtTypeAF.Debug
ENDDO
  write " For app ", $sc_$cpu_EVS_AppData[added_app_lctn].AppName
  write " DEBUG = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug
  write " INFO = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info
  write " ERROR = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err
  write " CRIT = ", p@$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit
  write " Evt msg types mask"
  write " CEID"
  write " ",$sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Crit, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Err, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Info, $sc_$cpu_EVS_AppData[added_app_lctn].EvtTypeAF.Debug

write ";***********************************************************************"
write "; Step 6.0: Enable/Disable Ports Test"
write ";***********************************************************************"
write "; Step 6.1: Send invalid Enable Port Mask command. "
write ";           In cFE 4.2.0, the valid range for the mask is x'1' - x'f' "
write ";             cEVS3006 "
write ";             cEVS3017 "
write ";             cEVS3018 (Invalid Command Counter) "
write ";***********************************************************************"

local cEVS3018_icc_511
local cEVS3018_icc_511a
local cEVS3018_icc_511b

local cEVS3006_511
local cEVS3006_511b

local cEVS3017_511
local cEVS3017_511a
local cEVS3017_511b

local output_port_mask = 0

output_port_mask = $SC_$CPU_EVS_OUTPUTPORT 

write " Prior to sending enable port command with mask of zero, Output Port Mask = ", %bin($SC_$CPU_EVS_OUTPUTPORT, 4)
write " Prior to sending enable port Command, execution Ctr = ", $SC_$CPU_EVS_CMDPC
write " Prior to sending enable port Cmd, Error Ctr = ", $SC_$CPU_EVS_CMDEC 

; Command to enable port with mask value of zero
; expect ERROR event ID 40 from EVS
 
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_INVALID_BITMASK_EID, ERROR

/$SC_$CPU_EVS_ENAPORTMASK BITMASK=X'0'  
wait 5

if ($SC_$CPU_num_found_messages = 1) then 
  write "     Event Message: ", $SC_$CPU_find_event[1].event_txt
  IF ($SC_$CPU_EVS_OUTPUTPORT = b'0001') then
    cEVS3018_icc_511a = "PASS"
    cEVS3017_511a = "PASS"
    write "<*> Passed (3017;3018) - (6.1)"
  ELSE
    cEVS3018_icc_511a = "FAIL"
    cEVS3017_511a = "FAIL"
    write" Unexpected output port mask found"
    write "<!> Failed (3017;3018) - (6.1)"
  ENDIF
  write" Mask = ", %bin($SC_$CPU_EVS_OUTPUTPORT,4)
else
  write " ALERT: failure to find evt msg for port enable cmd"
endif

write "   After sending enable port command with mask of zero, Output Port Mask = ", %bin($SC_$CPU_EVS_OUTPUTPORT, 4) 
write "  After sending enable port Command execution Ctr = ", $SC_$CPU_EVS_CMDPC
write " After sending enable port Cmd Error Ctr = ", $SC_$CPU_EVS_CMDEC 

IF (cEVS3017_511a = "PASS") THEN
  cEVS3017_511 = "PASS"
ELSE
  cEVS3017_511 = "FAIL"
ENDIF

IF (cEVS3018_icc_511a = "PASS") THEN
  cEVS3018_icc_511 = "PASS"
ELSE
  cEVS3018_icc_511 = "FAIL"
ENDIF

write ";***********************************************************************"
write "; Step 6.2: Send invalid Disable Port Mask command."
write ";           In cFE 4.2.0, the valid range for the mask is x'1' - x'f' "
write ";           cEVS3006 "
write ";           cEVS3017 "
write ";           cEVS3018 (Invalid Command Counter) "
write ";***********************************************************************"

local cEVS3018_icc_512
local cEVS3018_icc_512a

local cEVS3017_512
local cEVS3017_512a

output_port_mask = $SC_$CPU_EVS_OUTPUTPORT 

write " Prior to sending disable port command with mask of zero, Output Port Mask = ", $SC_$CPU_EVS_OUTPUTPORT 

; Command to disable port with mask value of zero
; expect ERROR event ID 40 from EVS
 
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_INVALID_BITMASK_EID, ERROR

/$SC_$CPU_EVS_DISPORTMASK BITMASK=X'0' 
wait 5

if ($SC_$CPU_num_found_messages = 1) then
  write "     Event Message: ", $SC_$CPU_find_event[1].event_txt
  cEVS3018_icc_512a = "PASS"
  cEVS3017_512a= "PASS"
  write "<*> Passed (3017;3018) - (6.2)"
else
  local cEVS3018_icc_512a = "FAIL"
  write "ALERT: Failure to generate expected evt msg at commanding Port ENABLE"
  cEVS3017_512a= "PASS"
  write "<!> Failed (3017;3018) - (6.2)"
endif

if ($SC_$CPU_EVS_OUTPUTPORT = output_port_mask) then
  cEVS3018_icc_512a = "PASS"
  cEVS3017_512a = "PASS"
  write "<*> Passed - (6.2)"
else
  cEVS3018_icc_512a = "FAIL"
  cEVS3017_512a = "FAIL"
  write " ALERT: failures at check of output port mask"
  write "<!> Failed - (6.2)"
endif

write " After sending disable port command with mask of zero, Output Port Mask = ", %bin($SC_$CPU_EVS_OUTPUTPORT,4)


IF (cEVS3017_512a = "PASS") THEN
  cEVS3017_512 = "PASS"
ELSE
  cEVS3017_512 = "FAIL"
ENDIF

IF (cEVS3018_icc_512a = "PASS") THEN
  cEVS3018_icc_512 = "PASS"
ELSE
  cEVS3018_icc_512 = "FAIL"
ENDIF

write ";***********************************************************************"
write "; Step 6.3: Disable Ports Command Test"
write ";***********************************************************************"
write "; Step 6.3.1: Send Disable Port Command for each valid port."
write ";             Telemetry indicates that all ports have been disabled."
write ";             cEVS3017"
write ";             cEVS3018 (Event Message Output Port Enable Status)"
write ";***********************************************************************"

local cEVS3017_522
local cEVS3018_emopes_522

previous_port_mask = $SC_$CPU_EVS_OUTPUTPORT

FOR i = 1 to cfe_port_cnt DO
  write "     Sending DISABLE PORT command to ", cfe_ports[i]
  /$SC_$CPU_EVS_DISPORT {cfe_ports[i]}
  wait 5
ENDDO

IF ($SC_$CPU_EVS_OUTPUTPORT = b'0000') THEN
    port_mask_status_flag = "OK"
    cEVS3017_522 = "PASS"
    cEVS3018_emopes_522 = "PASS"
    write "<*> Passed (3017;3018) - (6.3.1)"
ELSE
    cEVS3017_522 = "FAIL"
    cEVS3018_emopes_522 = "FAIL" 
    port_mask_status_flag = "*** ALERT ***"
    write "<!> Failed (3017;3018) - (6.3.1)"
ENDIF

write
write "     Port Mask"
write "     ---------"
write "     ", %bin(previous_port_mask,4), " -> ", %bin($SC_$CPU_EVS_OUTPUTPORT,4), "     ", port_mask_status_flag

write ";***********************************************************************"
write "; Step 6.3.2: Send events for each cFE application to each disabled port"
write ";             Verify that app's event not processed."
write ";             cEVS3017"
write ";***********************************************************************"

local cEVS3017_524 = "PASS"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_524.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
   previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_debug

s $sc_$cpu_evs_send_info

s $sc_$cpu_evs_send_error

s $sc_$cpu_evs_send_crit

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_524a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
   current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

;;;evt_msg_sent_ctr_offset = [6,2,2,2,2,4,0,0]
evt_msg_sent_ctr_offset = [3,2,2,2,2,1,2,4]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
     msg_ctr_status_flag[i] = "OK"
     msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3017_524 = "FAIL"
     write "<!> Failed - (6.3.2)"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]


write ";***********************************************************************"
write "; Step 6.4: Enable Ports Command Test"
write ";***********************************************************************"
write "; Step 6.4.1: Send Enable Port Command"
write ";             Telemetry indicates that port has been enabled."
write ";             cEVS3017"
write ";             cEVS3018 (Event Message Output Port Enable Status)"
write ";***********************************************************************"

local cEVS3017_532 = "PASS"
local cEVS3018_emopes_532 = "PASS"

previous_port_mask = $SC_$CPU_EVS_OUTPUTPORT

FOR i = 1 to cfe_port_cnt DO
  write "     Sending ENABLE PORT command to ", cfe_ports[i]
  /$SC_$CPU_EVS_ENAPORT {cfe_ports[i]}
  wait 5
ENDDO

IF ($SC_$CPU_EVS_OUTPUTPORT = b'1111') THEN 
    port_mask_status_flag = "OK"
ELSE
    write "<!> Failed (3017;3018) - (6.4.1)"
    cEVS3017_532 = "FAIL"
    cEVS3018_emopes_532 = "FAIL"
    port_mask_status_flag = "*** ALERT ***"
ENDIF

write
write "     Port Mask"
write "     ---------"
write "     ", %bin(previous_port_mask,4), " -> ", %bin($SC_$CPU_EVS_OUTPUTPORT,4), "     ", port_mask_status_flag

write ";***********************************************************************"
write "; Step 6.4.2: Send an event to enabled ports"
write ";             Verify that app's event is processed."
write ";             cEVS3017"
write ";***********************************************************************"

local cEVS3017_534 = "PASS"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_534.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
   previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

s $sc_$cpu_evs_send_debug

s $sc_$cpu_evs_send_info

s $sc_$cpu_evs_send_error

s $sc_$cpu_evs_send_crit

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_534a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
   current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     Msg Sent Counter"
write "     ----------------"

;;;evt_msg_sent_ctr_offset = [6,2,2,2,2,4,0,0]
evt_msg_sent_ctr_offset = [3,2,2,2,2,1,2,4]

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] + evt_msg_sent_ctr_offset[i] = current_app_msg_sent_ctr[i]) AND ;; 
      (previous_app_msg_sent_ctr[cfe_app_cnt] + evt_msg_sent_ctr_offset[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
     msg_ctr_status_flag[i] = "OK"
     msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ELSE
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3017_534 = "FAIL"
     write "<!> Failed - (6.4.2)"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[i]

; Set ports back to initial configuration - only PORT_ONE is enabled
write "     Setting Ports back to initial configuration (Port 1 Enabled)"
write
FOR i = 2 to cfe_port_cnt DO
  write "     Sending DISABLE PORT command to ", cfe_ports[i]
  /$SC_$CPU_EVS_DISPORT {cfe_ports[i]}
  wait 5
ENDDO
write
write "Port mask: ",%bin($SC_$CPU_EVS_OUTPUTPORT,4)
write

write ";***********************************************************************"
write "; Step 6.5: Test the number of ports supported. Try to Enable and "
write "; 	   and disable an invalid port."
write ";***********************************************************************"
local errcnt,rawcmd
errcnt = $SC_$CPU_EVS_CMDEC+1

;; Setup to capture Event ID = 40
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_INVALID_BITMASK_EID, ERROR

;; Send an invalid ENAPORT command
rawcmd = ""
if ("$CPU" = "CPU1") then
  rawcmd = "1801C00000030C281000"
elseif ("$CPU" = "CPU2") then
  rawcmd = "1821C00000030C081000"
elseif ("$CPU" = "$CPU") then
  rawcmd = "1841C00000030C681000"
endif

ut_sendrawcmd "$SC_$CPU_EVS", (rawcmd)

ut_tlmwait $SC_$CPU_EVS_CMDEC {errcnt}
IF (UT_TW_status = UT_Success) THEN
  write "<*> Passed (3300) - Enable Port command failed as expected"
  cEVS3300 = "PASS"
else
  write "<!> Failed (3300) - Enable Port command with an invalid port did not increment the error counter"
  cEVS3300 = "FAIL"
endif

;; Check for the failure event
if ($SC_$CPU_num_found_messages = 1) then
  write "<*> Passed (3300) - Error event msg ",$SC_$CPU_evs_eventid," received"
  cEVS3300 = "PASS"
else
  write "<!> Failed (3300) - Event msg ",$SC_$CPU_evs_eventid," received. Expected event msg ",CFE_EVS_ERR_INVALID_BITMASK_EID
  cEVS3300 = "FAIL"
endif

;; Send an invalid DISABLE PORT command
errcnt = $SC_$CPU_EVS_CMDEC+1
;; Setup to capture Event ID = 40
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_INVALID_BITMASK_EID, ERROR

rawcmd = ""
if ("$CPU" = "CPU1") then
  rawcmd = "1801C00000030D2A1000"
elseif ("$CPU" = "CPU2") then
  rawcmd = "1821C00000030D091000"
elseif ("$CPU" = "$CPU") then
  rawcmd = "1841C00000030D691000"
endif

ut_sendrawcmd "$SC_$CPU_EVS", (rawcmd)

ut_tlmwait $SC_$CPU_EVS_CMDEC {errcnt}
IF (UT_TW_status = UT_Success) THEN
  write "<*> Passed (3300) - Disable Port command failed as expected"
  cEVS3300 = "PASS"
else
  write "<!> Failed (3300) - Disable Port command with an invalid port did not increment the error counter"
  cEVS3300 = "FAIL"
endif

;; Check for the failure event
if ($SC_$CPU_num_found_messages = 1) then
  write "<*> Passed (3300) - Error event msg ",$SC_$CPU_evs_eventid," received"
  cEVS3300 = "PASS"
else
  write "<!> Failed (3300) - Event msg ",$SC_$CPU_evs_eventid," received. Expected event msg ",CFE_EVS_ERR_INVALID_BITMASK_EID
  cEVS3300 = "FAIL"
endif

write ";***********************************************************************"
write "; Step 7.0: Reset Application Event Msg Sent Counters Tests"
write ";***********************************************************************"
write "; Step 7.1: Send an invalid Reset Application Event Msg Sent Counter "
write ";           Command. FSW indicates invalid command. Command Error count "
write ";	   increments. Command Processed counter does not change."
write ";           cEVS3018 (Invalid Command Counter)"
write ";           cEVS3018 (Application Event Message Sent Counter)"
write ";           cEVS3004"
write ";           cEVS3009"
write ";***********************************************************************"
local cEVS3004_aemsc_611 
local cEVS3018_aemsc_611
local cEVS3018_icc_611
local cEVS3009_611
;;;; 9 = CFE_EVS_ERR_NOAPPIDFOUND_EID
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_NOAPPIDFOUND_EID, ERROR
wait 5
Ut_sendcmd "$SC_$CPU_EVS_RSTAPPCTRS APPLICATION=""CFE_"""
write
IF (ut_sc_status = UT_SC_CmdFailure) THEN
   write "     CFE_ is NOT a valid application."
   write "     Invalid Command Counter incremented."
   cEVS3004_aemsc_611 = "PASS"
   cEVS3018_aemsc_611 = "PASS"
   cEVS3018_icc_611 = "PASS"
   cEVS3009_611 = "PASS"
   write "<*> Passed (3004;3009;3018) - (7.1)"
ELSE
   write "     Invalid Command Counter NOT incremented."
   cEVS3004_aemsc_611 = "FAIL"
   cEVS3018_aemsc_611 = "FAIL"
   cEVS3018_icc_611 = "FAIL"
   cEVS3009_611 = "FAIL"
   write "<!> Failed (3004;3009;3018) - (7.1)"
ENDIF
IF ($SC_$CPU_num_found_messages = 1) THEN
  write "     Event Message: ", $SC_$CPU_find_event[1].event_txt  
ELSE
   write "     Event Message NOT generated."
ENDIF
write 

write ";***********************************************************************"
write "; Step 7.2: Send the Reset Application Command for each cFE app:"
write ";	   CFE_SB, CFE_ES, CFE_EVS, CFE_TIME, TST_EVS	"
write ";           cEVS3009"
write ";           cEVS3004"
write ";           cEVS3018 (Application Event Message Sent Counter)"
write ";***********************************************************************"

local cEVS3009 = "PASS"
local cEVS3004_aemsc_622 = "PASS"
local cEVS3018_aemsc_622 = "PASS"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_622.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
   previous_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

FOR i = 1 to cfe_app_cnt-1 DO
  write "     Sending RESET APPLICATION COMMAND COUNTER command for Application: ", cfe_applications[i]
  /$SC_$CPU_EVS_RSTAPPCTRS APPLICATION=cfe_applications[i]
  wait 5
ENDDO
/$SC_$CPU_EVS_RSTAPPCTRS APPLICATION="TST_EVS"
wait 5

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_622a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_app_msg_sent_ctr[i] = p@$sc_$cpu_EVS_AppData[i].EventCounter 
ENDDO
   current_app_msg_sent_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].EventCounter 

write "" 
write "     App EMS Counter"
write "     ----------------"

FOR i = 1 to cfe_app_cnt-1 DO
   IF (previous_app_msg_sent_ctr[i] = current_app_msg_sent_ctr[i]) AND ;;
      (previous_app_msg_sent_ctr[cfe_app_cnt] = current_app_msg_sent_ctr[cfe_app_cnt]) THEN
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3009 = "FAIL"
     cEVS3004_aemsc_622 = "FAIL"
     cEVS3018_aemsc_622 = "FAIL"
     write "<!> Failed (3004;3009;3018) - (7.2)"
   ELSE
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_app_msg_sent_ctr [i] , " -> " , current_app_msg_sent_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
  write "     ", cfe_applications[cfe_app_cnt], " - ", previous_app_msg_sent_ctr [cfe_app_cnt] , " -> " , current_app_msg_sent_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ""

write ";***********************************************************************"
write "; Step 8.0: Set / Reset Binary Filters Test "
write ";***********************************************************************"
write "; Step 8.1: Send an invalid Binary Filter Mask Commands"
write ";           Valid Mask range  x'0' to x'ffff'"
write ";           cEVS3004"
write ";           cEVS3006"
write ";           cEVS3018 (Invalid Command Counter)"
write ";***********************************************************************"
write "*** NOTE: Cannot test for Invalid Event ID / Invalid Mask."
write "***       Valid Range(s) are '0' - 'ffff'. Both Event ID and"
write "***       and Event Mask are defined to be unsigned integers"
write "***       (16 bits) and selecting a value outside the valid "
write "***       range would exceed the bit allocation."

write "Sending command with a non-existent cFE aplication."

local cEVS3006_7111
local cEVS3018_icc_7111
local cEVS3004_abfm_7111
;;; 9 = CFE_EVS_ERR_NOAPPIDFOUND_EID
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_NOAPPIDFOUND_EID, ERROR
wait 5
Ut_sendcmd "$SC_$CPU_EVS_SETBINFLTRMASK APPLICATION=""CFE_"" EVENT_ID=X'ffff' FILTERMASK=X'ffff'"
write
IF (ut_sc_status = UT_SC_CmdFailure) THEN
   write "     CFE_ is NOT a valid application for Binary Filter Mask Command."
   write "     Invalid Command Counter incremented."
   cEVS3006_7111 = "PASS"
   cEVS3018_icc_7111 = "PASS"
   cEVS3004_abfm_7111 = "PASS"
   write "<*> Passed (3004;3006;3018) - (8.1)"
ELSE
   write "     Invalid Command Counter NOT incremented."
   cEVS3006_7111 = "FAIL"
   cEVS3018_icc_7111 = "FAIL"
   cEVS3004_abfm_7111 = "FAIL"
   write "<!> Failed (3004;3006;3018) - (8.1)"
ENDIF
IF ($SC_$CPU_num_found_messages = 1) THEN
  write "     Event Message: ", $SC_$CPU_find_event[1].event_txt  
ELSE
   write "     Event Message NOT generated."
ENDIF
write 

write ";***********************************************************************"
write "; Step 8.2: Send invalid Reset All Filters Commands for a non-existing"
write ";           Application. FSW indicates invalid command. Command Error "
write ";	   count increments.Command Processed counter does not change."
write ";           cEVS3004"
write ";           cEVS3006"
write ";           cEVS3011"
write ";           cEVS3018 (Invalid Command Counter)"
write ";***********************************************************************"

local cEVS3006_7211
local cEVS3018_icc_7211

write "Sending command with a non-existent cFE aplication."
;;; 9 = CFE_EVS_ERR_NOAPPIDFOUND_EID
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_NOAPPIDFOUND_EID, ERROR
wait 5
Ut_sendcmd "$SC_$CPU_EVS_RSTALLFLTRS APPLICATION=""CFE_"""
write
IF (ut_sc_status = UT_SC_CmdFailure) THEN
   write "     CFE_ is NOT a valid application."
   write "     Invalid Command Counter incremented."
   cEVS3006_7211 = "PASS"
   cEVS3018_icc_7211 = "PASS"
   cEVS3011 = "PASS"
   write "<*> Passed (3006;3011;3018) - (8.2)"
ELSE
   write "     Invalid Command Counter NOT incremented."
   cEVS3006_7211 = "FAIL"
   cEVS3018_icc_7211 = "FAIL"
   cEVS3011 = "FAIL"
   write "<!> Failed (3006;3011;3018) - (8.2)"
ENDIF
IF ($SC_$CPU_num_found_messages = 1) THEN
  write "     Event Message: ", $SC_$CPU_find_event[1].event_txt  
ELSE
   write "     Event Message NOT generated."
ENDIF
write 

write ";***********************************************************************"
write "; Step 9.0: Reset Binary Filter Counter Tests "
write ";***********************************************************************"
write "; Step 9.1: Send invalid Reset Binary Filter Counter command "
write ";             Select cFE application that does not exist. "
write ";             FSW indicates invalid command. Command Error count " 
write ";             increments. Command Processed counter does not change."
write ";             cEVS3006"
write ";             cEVS3010"
write ";             cEVS3018 (Invalid Command Counter)"
write ";***********************************************************************"
write "*** NOTE: Cannot test for Invalid Event ID. Valid Range is"
write "***       '0' - 'ffff'. Event ID is defined to be unsigned integer "
write "***       (16 bits) and selecting a value outside the valid range "
write "***       would exceed the bit allocation."

local cEVS3006_811
local cEVS3018_icc_811
local cEVS3010_811
;;; 9 = CFE_EVS_ERR_NOAPPIDFOUND_EID
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_NOAPPIDFOUND_EID, ERROR
wait 5
Ut_sendcmd "$SC_$CPU_EVS_RSTBINFLTRCTR APPLICATION=""CFE_"" EVENT_ID=X'FFFF'"
write
IF (ut_sc_status = UT_SC_CmdFailure) THEN
   write "     CFE_ is NOT a valid application."
   write "     Invalid Command Counter incremented."
   cEVS3006_811 = "PASS"
   cEVS3018_icc_811 = "PASS"
   cEVS3010_811 = "PASS"
   write "<*> Passed (3006;3010;3018) - (9.1)"
ELSE
   write "     Invalid Command Counter NOT incremented."
   cEVS3006_811 = "FAIL"
   cEVS3018_icc_811 = "FAIL"
   cEVS3010_811 = "FAIL"
   write "<!> Failed (3006;3010;3018) - (9.1)"
ENDIF
IF ($SC_$CPU_num_found_messages = 1) THEN
  write "     Event Message: ", $SC_$CPU_find_event[1].event_txt  
ELSE
   write "     Event Message NOT generated."
ENDIF
write 

write ";***********************************************************************"
write "; Step 9.2: Send Reset Binary Filter Counter command for each cFE app."
write ";           cEVS3004"
write ";           cEVS3010"
write ";***********************************************************************"

local cEVS3004_abfc_822 = "PASS"
local cEVS3010_822 = "PASS"

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_822.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   previous_bin_fltr_ctr[i] = p@$sc_$cpu_EVS_AppData[i].BinFltr[1].Ctr
ENDDO
previous_bin_fltr_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].BinFltr[1].Ctr

FOR i = 1 to cfe_app_cnt-1 DO
  write "     Sending RESET BINARY FILTER COUNTER command for application: ", cfe_applications[i], " Event ID = 1"
  /$SC_$CPU_EVS_RSTBINFLTRCTR  APPLICATION=$sc_$cpu_EVS_AppData[i].AppName EVENT_ID=X'1'   
  wait 5
ENDDO

/$SC_$CPU_EVS_RSTBINFLTRCTR  APPLICATION="TST_EVS" EVENT_ID=X'1'   
wait 5

start get_file_to_cvt ("RAM:0", "cfe_evs_app.dat", "cfe_evs_app_822a.dat", "$CPU")
wait 10
FOR i = 1 to cfe_app_cnt-1 DO
   current_bin_fltr_ctr[i] = p@$sc_$cpu_EVS_AppData[i].BinFltr[1].Ctr
ENDDO
   current_bin_fltr_ctr[cfe_app_cnt] = p@$sc_$cpu_EVS_AppData[added_app_lctn].BinFltr[1].Ctr
write
write "    BinFltr Counter values"
write "    ----------------------" 
FOR i = 1 to cfe_app_cnt-1 DO
   IF ((previous_bin_fltr_ctr[i] = current_bin_fltr_ctr[i]) AND bin_fltr_msgs[i]) AND ;;
      ((previous_bin_fltr_ctr[cfe_app_cnt] = current_bin_fltr_ctr[cfe_app_cnt]) AND bin_fltr_msgs[cfe_app_cnt]) THEN
     msg_ctr_status_flag[i] = "*** ALERT ***"
     msg_ctr_status_flag[cfe_app_cnt] = "*** ALERT ***"
     cEVS3010_822 = "FAIL"
     cEVS3004_abfc_822 = "FAIL"
   ELSE
      msg_ctr_status_flag[i] = "OK"
      msg_ctr_status_flag[cfe_app_cnt] = "OK"
   ENDIF
   write "     ", cfe_applications[i], " - ", previous_bin_fltr_ctr [i] , " -> " , current_bin_fltr_ctr [i], "     ", msg_ctr_status_flag[i]
ENDDO
   write "     ", cfe_applications[cfe_app_cnt], " - ", previous_bin_fltr_ctr [cfe_app_cnt] , " -> " , current_bin_fltr_ctr [cfe_app_cnt], "     ", msg_ctr_status_flag[cfe_app_cnt]

write ";***********************************************************************"
write "; Step 10.0: Reset Counters Test "
write ";***********************************************************************"
write "; Step 10.1: Check the message counters to ensure that they are not 0 "
write ";	    before sending the Reset Counters Command."
write ";            Verify that the CommandCounter, CommandErrCounter, "
write ";            MessagesendCounter, MessageTrunkCounter, and "
write ";	    UnregisteredAppCounter have non-zero values. "
write ";***********************************************************************"

if ($SC_$CPU_EVS_CMDPC = 0) then
  ;; Send a NO-Op command to increment this counter
endif

if ($SC_$CPU_EVS_CMDEC = 0) then
  ;; Send an invalid command to increment this counter
endif

if ($SC_$CPU_EVS_MSGSENTC = 0) then
  ;; Send a command that will generate an event
endif

if ($SC_$CPU_EVS_MSGTRUNC = 0) then
  write "Cause an event message to be sent that will increment the MessageTrunkCounter"

  /$SC_$CPU_TST_EVS_SendEvtMsg DEBUG EventId = "6" Iters = "1" Milliseconds = "10"
  ut_tlmwait $SC_$CPU_EVS_MSGTRUNC 1
  IF (UT_TW_status = UT_Success) THEN
    cEVS3018_emtc = "PASS"
    write "<*> Passed (3018) - (10.1)"
  ELSE
    write "<!> Failed (3018) - (10.1) - MsgTrunc counter did not increment"
  ENDIF
endif

if ($SC_$CPU_EVS_UNREGAPPC = 0) then
  write "Unregister the TST_EVS test application"
  /$SC_$CPU_TST_EVS_UNREGISTER
  wait 10

  write "Cause an event message to be sent by the TST_EVS test application that was just unregistered"
  /$SC_$CPU_TST_EVS_SendEvtMsg DEBUG EventId = "1" Iters = "1" Milliseconds = "15"
  ut_tlmwait $SC_$CPU_EVS_UNREGAPPC 1
  IF (UT_TW_status = UT_Success) THEN
    cEVS3018_uasc = "PASS"
    write "<*> Passed (3018) - (10.1)"
  ELSE
    write "<!> Failed (3018) - (10.1) - Unregistered App Msg counter did not increment"
  ENDIF
endif

write ";***********************************************************************"
write "; Step 10.2: Send the Reset Counters Command.  Telemetry indicates that "
write "; 	    CommandCounter, CommandErrCounter, MessagesendCounter, "
write ";	    MessageTrunkCounter, and UnregisteredAppCounter have zero "
write ";	    values."
write ";            cEVS3003"
write ";            cEVS3018"
write ";***********************************************************************"

local previousCommandCounter
local previousCommandErrCounter
local previousMessageSendCounter
local previousMessageTrunkCounter
local previousUnregisteredAppCounter
local CounterStatusFlag

local cfeCountersCnt = 5
local cfeCounters[cfeCountersCnt] = ["CommandCounter", "CommandErrCounter", "MessageSendCounter", "MessageTrunkCounter", "UnregisteredAppCounter"]
local cfeCountersM[cfeCountersCnt] = ["CMDPC", "CMDEC", "MSGSENTC", "MSGTRUNC", "UNREGAPPC"]

;;cEVS3018_emtc = "FAIL"
;;cEVS3018_uasc = "FAIL"
cEVS3018_emsc = "FAIL"

previousCommandCounter = $SC_$CPU_EVS_CMDPC
previousCommandErrCounter = $SC_$CPU_EVS_CMDEC 
previousMessageSendCounter = $SC_$CPU_EVS_MSGSENTC 
previousMessageTrunkCounter = $SC_$CPU_EVS_MSGTRUNC 
previousUnregisteredAppCounter = $SC_$CPU_EVS_UNREGAPPC

; Set evt msg type DEBUG status to disable to prevent 
; generation of evt msg when reset ctr command is received

/$SC_$CPU_EVS_DISEVENTTYPE DEBUG 
wait 8

write  "Issue RESETCTRS command:"

/$SC_$CPU_EVS_RESETCTRS
ut_tlmwait $SC_$CPU_EVS_MSGSENTC 0
IF (UT_TW_status = UT_Success) THEN
      cEVS3018_emsc = "PASS"
     write "<*> Passed (3018) - (10.2)"
ELSE
    write "<!> Failed (3018) - (10.2)"
ENDIF
write

write "Results of RESETCTRS command:"
FOR i = 1 to cfeCountersCnt DO
    IF {"$SC_$CPU_EVS_" & cfeCountersM[i]} = 0 THEN
        CounterStatusFlag = "OK"
    ELSE
        CounterStatusFlag = "*** ALERT ***"
    ENDIF 
    write "     ", cfeCounters[i]," = ",{"previous"& cfeCounters[i]}, " -> ", {"$SC_$CPU_EVS_" & cfeCountersM[i]}, "     ", CounterStatusFlag
ENDDO
write
  
IF  $SC_$CPU_EVS_CMDPC = 0 AND  $SC_$CPU_EVS_CMDEC = 0 AND $SC_$CPU_EVS_MSGSENTC = 0 AND $SC_$CPU_EVS_MSGTRUNC = 0 AND $SC_$CPU_EVS_UNREGAPPC = 0 THEN
   cEVS3003 = "PASS"
ELSE
   cEVS3003 = "FAIL"
ENDIF

/$SC_$CPU_EVS_ENAEVENTTYPE DEBUG 
wait 8


write ";***********************************************************************"
write "; Step 11.0: Log Mode Tests"
write ";***********************************************************************"
write "; Step 11.1: Send invalid Log Mode command. The FSW indicates invalid "
write ";	    command. The Command Error count increments and the "
write ";            Command Processed counter does not change."
write ";            cEVS3006 "
write ";            cEVS3018 (Invalid Command Counter) "
write ";***********************************************************************"

local cEVS3006_1111
local cEVS3018_icc_1111

write "    Sending Log Mode = 2 (Overwrite = 0, Discard = 1)"
;;;; 9 = CFE_EVS_ERR_NOAPPIDFOUND_EID
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_NOAPPIDFOUND_EID, ERROR
wait 5
 raw_command = "18"&%hex($CPU_CMDAPID_BASE + EVS_CMDAPID_OFF, 2)&"C0000002140002"
 Ut_sendrawcmd "$SC_$CPU_EVS", {raw_command}
write
IF (ut_rcs_status = UT_RCS_CmdFailure) THEN
   write "     2 is NOT a valid mode for Log Mode command"
   write "     Invalid Command Counter incremented."
   cEVS3006_1111 = "PASS"
   cEVS3018_icc_1111 = "PASS"
   write "<*> Passed (3006;3018) - (11.1)"
ELSE
   write "     Invalid Command Counter NOT incremented."
   cEVS3006_1111 = "FAIL"
   cEVS3018_icc_1111 = "FAIL"
   write "<!> Failed (3006;3018) - (11.1)"
ENDIF
;NOTE see note above
IF ($SC_$CPU_num_found_messages = 1) THEN
   write "     Event Message: ", $SC_$CPU_find_event[1].event_txt  
ELSE
   write "     Event Message NOT generated, but expected"
ENDIF 

write ";***********************************************************************"
write "; Step 12.0: Enable and Disable Event Type Mask Tests"
write ";***********************************************************************"
write "; Step 12.1: Send invalid Enable command. The FSW should generate an "
write "; 	    Error event message."
write ";***********************************************************************"
;; Setup to capture Event ID = 40
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_INVALID_BITMASK_EID, ERROR

errcnt = $SC_$CPU_EVS_CMDEC+1

/$SC_$CPU_EVS_ENAEVENTTYPEMASK BITMASK=X'0'
wait 8

ut_tlmwait $SC_$CPU_EVS_CMDEC {errcnt}
IF (UT_TW_status = UT_Success) THEN
  write "<*> Passed - Enable Event Type Mask command failed as expected"
else
  write "<!> Failed - Enable Event Type Mask command with an invalid mask did not increment the error counter"
endif

;; Check for the failure event
if ($SC_$CPU_num_found_messages = 1) then
  write "<*> Passed - Error event msg ",$SC_$CPU_evs_eventid," received"
else
  write "<!> Failed - Event msg ",$SC_$CPU_evs_eventid," received. Expected event msg ",CFE_EVS_ERR_INVALID_BITMASK_EID
endif

write ";***********************************************************************"
write "; Step 12.2: Send invalid Disable command. The FSW should generate an "
write "; 	    Error event message."
write ";***********************************************************************"
;; Setup to capture Event ID = 40
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ERR_INVALID_BITMASK_EID, ERROR

errcnt = $SC_$CPU_EVS_CMDEC+1

/$SC_$CPU_EVS_DISEVENTTYPEMASK BITMASK=X'0'
wait 8

ut_tlmwait $SC_$CPU_EVS_CMDEC {errcnt}
IF (UT_TW_status = UT_Success) THEN
  write "<*> Passed - Disable Event Type Mask command failed as expected"
else
  write "<!> Failed - Disable Event Type Mask command with an invalid mask did not increment the error counter"
endif

;; Check for the failure event
if ($SC_$CPU_num_found_messages = 1) then
  write "<*> Passed - Error event msg ",$SC_$CPU_evs_eventid," received"
else
  write "<!> Failed - Event msg ",$SC_$CPU_evs_eventid," received. Expected event msg ",CFE_EVS_ERR_INVALID_BITMASK_EID
endif

write ";***********************************************************************"
write "; Step 12.3: Send a valid Disable command. "
write ";***********************************************************************"
;; Setup to capture Event ID = 21
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_DISEVTTYPE_EID, DEBUG

local cmdcnt = $SC_$CPU_EVS_CMDPC+1

/$SC_$CPU_EVS_DISEVENTTYPEMASK BITMASK=X'2'
wait 8

ut_tlmwait $SC_$CPU_EVS_CMDPC {cmdcnt}
IF (UT_TW_status = UT_Success) THEN
  write "<*> Passed - Disable Event Type Mask command"
else
  write "<!> Failed - Enable Event Type Mask command did not increment the command counter"
endif

;; Check for the failure event
if ($SC_$CPU_num_found_messages = 1) then
  write "<*> Passed - Error event msg ",$SC_$CPU_evs_eventid," received"
else
  write "<!> Failed - Event msg ",$SC_$CPU_evs_eventid," received. Expected event msg ",CFE_EVS_DISEVTTYPE_EID
endif

write ";***********************************************************************"
write "; Step 12.4: Send a valid Enable command. "
write ";***********************************************************************"
;; Setup to capture Event ID = 20
ut_setupevt $SC, $CPU, CFE_EVS, CFE_EVS_ENAEVTTYPE_EID, DEBUG

cmdcnt = $SC_$CPU_EVS_CMDPC+1

/$SC_$CPU_EVS_ENAEVENTTYPEMASK BITMASK=X'2'
wait 8

ut_tlmwait $SC_$CPU_EVS_CMDPC {cmdcnt}
IF (UT_TW_status = UT_Success) THEN
  write "<*> Passed - Enable Event Type Mask command"
else
  write "<!> Failed - Enable Event Type Mask command did not increment the command counter"
endif

;; Check for the failure event
if ($SC_$CPU_num_found_messages = 1) then
  write "<*> Passed - Error event msg ",$SC_$CPU_evs_eventid," received"
else
  write "<!> Failed - Event msg ",$SC_$CPU_evs_eventid," received. Expected event msg ",CFE_EVS_ENAEVTTYPE_EID
endif

write ";***********************************************************************"
write "; Step 13.0: Send the WRITEAPPDATA2FILE command without a path "
write ";	    specification for the filename."
write ";***********************************************************************"
ut_setupevents $SC, $CPU, CFE_EVS, CFE_EVS_ERR_CRDATFILE_EID, ERROR, 1

errcnt = $SC_$CPU_EVS_CMDEC + 1

/$SC_$CPU_EVS_WRITEAPPDATA2FILE APPDATAFILENAME="nopathname"
wait 10

ut_tlmwait $SC_$CPU_EVS_CMDEC, {errcnt}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - WriteAppData command failed as expected."
else
  write "<!> Failed - WriteAppData command did not increment the CMDEC."
endif

;; Look for expected event #1
if ($SC_$CPU_num_found_messages = 1) then
  write "<*> Passed - Event Msg ",$SC_$CPU_find_event[1].eventid," Found!"
else
  write "<!> Failed - Expected Event Message ", CFE_EVS_ERR_CRDATFILE_EID, " not received."
endif

;*******************************************************************************
; Requirements Report
;*******************************************************************************
REQUIREMENTS:

local rqmt_p_or_f
local cEVS3004_aetes = "FAIL"
local cEVS3004_aeses = "FAIL"
local cEVS3004_aemsc = "FAIL"
local cEVS3004_abfc = "FAIL"
local cEVS3004_abfm = "FAIL"

write "*** Requirements Status Reporting"

; cEVS3000
IF (cEVS3000_322 = "PASS") AND (cEVS3000_324 = "PASS") AND (cEVS3000_326 = "PASS") AND (cEVS3000_328 = "PASS") AND (cEVS3000_332 = "PASS") AND (cEVS3000_334 = "PASS") AND (cEVS3000_336 = "PASS") AND (cEVS3000_338 = "PASS") THEN
    cEVS3000 = "PASS"
ELSE
    cEVS3000 = "FAIL"
ENDIF

; cEVS3004


IF (cEVS3004_aetes_223 = "PASS") AND (cEVS3004_aetes_225 = "PASS") AND (cEVS3004_aetes_227 = "PASS") AND (cEVS3004_aetes_231 = "PASS") AND (cEVS3004_aetes_233 = "PASS") AND (cEVS3004_aetes_235 = "PASS") AND (cEVS3004_aetes_237 = "PASS") AND (cEVS3004_aetes_321 = "PASS") AND (cEVS3004_aetes_323 = "PASS") AND (cEVS3004_aetes_325 = "PASS") AND (cEVS3004_aetes_327 = "PASS") AND (cEVS3004_aetes_331 = "PASS") AND (cEVS3004_aetes_333 = "PASS") AND (cEVS3004_aetes_335 = "PASS") AND (cEVS3004_aetes_337 = "PASS") THEN
   cEVS3004_aetes = "PASS"
ELSE
   goto EVS3004
ENDIF


IF (cEVS3004_aeses_432 = "PASS") THEN
    cEVS3004_aeses = "PASS"
ELSE
    goto EVS3004
ENDIF


IF (cEVS3004_aemsc_611 = "PASS") AND (cEVS3004_aemsc_622 = "PASS") THEN
    cEVS3004_aemsc = "PASS"
ELSE
    goto EVS3004
ENDIF


IF (cEVS3004_abfc_822 = "PASS") THEN
    cEVS3004_abfc = "PASS"
ELSE
    goto EVS3004
ENDIF


IF (cEVS3004_abfm_7111 = "PASS") THEN
    cEVS3004_abfm = "PASS"
ELSE
    goto EVS3004
ENDIF

EVS3004:
IF (cEVS3004_aetes = "PASS") AND (cEVS3004_aeses = "PASS") AND (cEVS3004_aemsc = "PASS") AND (cEVS3004_abfc = "PASS") AND (cEVS3004_abfm = "PASS") THEN
    cEVS3004 = "PASS"
ELSE
    cEVS3004 = "FAIL"
ENDIF
 
; cEVS3005

if (cEVS3005_11 = "PASS") then
    cEVS3005 = "PASS"
else
    cEVS3005 = "FAIL"
endif 

; cEVS3006

IF (cEVS3006_212 = "PASS") AND (cEVS3006_411 = "PASS") AND (cEVS3006_412 = "PASS") AND (cEVS3006_7111 = "PASS") THEN
    cEVS3006 = "PASS"
ELSE
    cEVS3006 = "FAIL"
ENDIF

; cEVS3007


IF (cEVS3007_211 =  "PASS") AND (cEVS3007_212 = "PASS") AND (cEVS3007_221 = "PASS") AND (cEVS3007_222 = "PASS") AND (cEVS3007_223 = "PASS") AND (cEVS3007_224 = "PASS") AND (cEVS3007_225 = "PASS") AND (cEVS3007_226 = "PASS") AND (cEVS3007_227 = "PASS") AND (cEVS3007_228 = "PASS") AND (cEVS3007_231 = "PASS") AND (cEVS3007_232 = "PASS") AND (cEVS3007_233 = "PASS") AND (cEVS3007_234 = "PASS") AND (cEVS3007_235 = "PASS") AND (cEVS3007_236 = "PASS") AND (cEVS3007_237 = "PASS") AND (cEVS3007_238  = "PASS") THEN
    cEVS3007 = "PASS"
ELSE
    cEVS3007 = "FAIL"
ENDIF

; cEVS3008

IF (cEVS3008_412 = "PASS") AND (cEVS3008_422 = "PASS") AND (cEVS3008_423 = "PASS") AND (cEVS3008_432 = "PASS") AND (cEVS3008_433 = "PASS") THEN
    cEVS3008 = "PASS"
ELSE
    cEVS3008 = "FAIL"
ENDIF

; cEVS3009

IF (cEVS3009_611 = "PASS") THEN
    cEVS3009 = "PASS"
ELSE
    cEVS3009 = "FAIL"
ENDIF

; cEVS3010

IF (cEVS3010_822 = "PASS") THEN
    cEVS3010 = "PASS"
ELSE
    cEVS3010 = "FAIL"
ENDIF

; cEVS3017

IF (cEVS3017_511 = "PASS") AND (cEVS3017_522 = "PASS") AND (cEVS3017_522 = "PASS") AND (cEVS3017_524 = "PASS") AND (cEVS3017_532 = "PASS") AND (cEVS3017_534 = "PASS") THEN
    cEVS3017 = "PASS"
ELSE
    cEVS3017 = "FAIL"
ENDIF

; cEVS3018

cEVS3018_vcc = "FAIL"
cEVS3018_icc = "FAIL"
cEVS3018_aeses = "FAIL"
cEVS3018_aemsc = "FAIL"
cEVS3018_emopes = "FAIL"

IF (cEVS3018_vcc_11 = "PASS") THEN
    cEVS3018_vcc = "PASS"
ELSE
   goto EVS3018
ENDIF

IF (cEVS3018_aeses_432 = "PASS") THEN
   cEVS3018_aeses = "PASS"
ELSE
   goto EVS3018
ENDIF

IF (cEVS3018_aemsc_611 = "PASS") AND (cEVS3018_aemsc_622 = "PASS") THEN
   cEVS3018_aemsc = "PASS"
ELSE
   goto EVS3018
ENDIF

IF (cEVS3018_emopes_522 = "PASS") AND (cEVS3018_emopes_532 = "PASS") THEN
   cEVS3018_emopes = "PASS"
ELSE
   goto EVS3018
ENDIF

IF (cEVS3018_icc_212 = "PASS") AND (cEVS3018_icc_411 = "PASS") AND (cEVS3018_icc_412 = "PASS") AND (cEVS3018_icc_511 = "PASS") AND (cEVS3018_icc_512 = "PASS") AND (cEVS3018_icc_611 = "PASS") AND (cEVS3018_icc_7111 = "PASS") AND (cEVS3018_icc_7211 = "PASS") AND (cEVS3018_icc_811 = "PASS") AND (cEVS3018_icc_1111 = "PASS") THEN
    cEVS3018_icc = "PASS"
ENDIF

EVS3018:

IF (cEVS3018_icc = "PASS") AND (cEVS3018_vcc = "PASS") AND (cEVS3018_emtc = "PASS") AND (cEVS3018_uasc = "PASS") AND (cEVS3018_aeses = "PASS") AND (cEVS3018_aemsc = "PASS") AND (cEVS3018_emopes = "PASS") AND (cEVS3018_emsc = "PASS") THEN
    cEVS3018 = "PASS"
ELSE
    cEVS3018 = "FAIL"
    write "*** 3018 set to FAILED!!! "
ENDIF

write
write "Requirement(s) Report"
write "---------------------"
; FOR i = 1 to rqmt_ctr DO
;  write cfe_requirements[i], " -> ", {cfe_requirements[i]}
; ENDDO
; write

FOR i = 1 to rqmt_ctr DO
  rqmt_p_or_f = %substring({cfe_requirements[i]},1,1)
  ut_pfindicate {cfe_requirements[i]} {rqmt_p_or_f} 
ENDDO
write

TST_APP_FAILED:
END_TEST:

validation on
end_it:
endproc
