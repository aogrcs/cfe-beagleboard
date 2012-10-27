PROC $sc_$cpu_evs_log
;**********************************************************************
;  Test Name:  cFE EVS Log
;  Test Level: Build Verification 
;  Test Type:  Functional 
;  Test Description
;     The purpose of this test is to verify the EVS log requirements
;  for the Event Service (EVS) function of the Core Flight Executive
; (cFE) software.
;     The operation of EVS Log will be verified in both the Overwrite
;  and Discard modes. The Local Event Log Full flag, Local Event Log
;  Overflow Counter, Event Logging Mode flag, and Event Format flag
;  will be examined for proper value(s) during the execution of the
;  test scenario.  The contents of the Event Log will be periodically
;  dumped from the FSW to the ASIST box for examination using telemetry
;  pages and off-line analysis.
;    The TST_EVS test application will be used to send multiple event 
; messages. The supplied event text / event time will serve to uniquely 
; identify each event message.
;
;  Requirements Tested
;
; cEVS3001     Upon receipt of Command, the cFE shall set the SB Event 
;              Format Mode to the command specified value, either Long 
;              or Short.
; cEVS3013    <OPTIONAL> Upon receipt of Command, the cFE shall clear
;             the Local Event Log. 
; cEVS3014   <OPTIONAL> Upon receipt of Command, the cFE shall set the
;             Event Logging Mode to the Command-specified mode, either
;             overwrite or discard.
; cEVS3015    <OPTIONAL> Upon receipt of Command, the cFE shall write
;             the contents of the Local Event Log to the Command specified  file. 
;     *** Requirement cEVS3015 requires ANALYSIS.
;     *** Compare Local Event Log file cfe_evs_3_431.log to Event Telemetry to verify that ***
;     *** the event messages logged agree with the telemetry.       *** 
; cEVS3015_1  If a file is not specified, the cFE shall use the 
;             <PLATFORM_DEFINED> filename. 
;     *** Requirement cEVS3015_1 requires ANALYSIS.
;     *** Compare Local Event Log file cfe_evs_3_432.log to Event Telemetry to verify that ***
;     *** the event messages logged agree with the telemetry.       *** 
; cEVS3016    <OPTIONAL> The cFE shall write each Event Message from
;             the earliest logged message to the most recently logged
;             message. 
; cEVS3018    The cFE shall provide the following Event Service data 
;             items in telemetry (SB Messages):
;             c) SB Event Format Mode
;             h) <OPTIONAL> Local Event Log Full Flag
;             i) <OPTIONAL> Local Event Log Overflow Counter
;             j) <OPTIONAL> Logging Mode
; cEVS3108    <OPTIONAL> For each created Event Message, the cFE shall
;             store the Event Message in the Local Event Log in the 
;             Long Event Message Format. 
; cEVS3108.1  <OPTIONAL> If the Local Event Log becomes full, the cFE
;             shall set the Local Event Log Full Flag to true. 
; cEVS3108.2  <OPTIONAL> If the Local Event Log is full, the cFE shall 
;             increment the Local Event Log Overflow counter. 
; cEVS3108.3  <OPTIONAL> If the Local Event Log is full, the cFE shall
;             either (1) overwrite the oldest Event Message if the
;             Event Logging Mode is overwrite, or (2) discard the Event
;             Message if the Event Logging Mode is discard. 
;     *** Requirement cEVS3108_31 requires ANALYSIS.
; See Steps 2.3.1 and 2.4 for verification checks.
; cEVS3301    <OPTIONAL> The cFE shall define a Local Event Log with a 
;             capacity of <PLATFORM_DEFINED, 20> Event Messages. 
;
;  Prerequisite Conditions
;  Availability of the TST_EVS test application to send repeated event
;  messages according to the following specifications:
;
; 1a. Command, /$SC_$CPU_TST_EVS_SendEvtMsg, to the Test Application
;     with the following parameters:
;     Event Id
;     Event Type (Debug | Information | Error | Critical)
;     Number of Iterations 
;
; 1b. In response to the command, the application requests the
;     generation of the command-specified Event Message with the
;     command-specified Event Type.  The request will be made the
;     number of times specified in the iterations parameter. In most
;     cases the test string is:
;
;    "Iteration No. = " %d, "Msg ID = "  %d , Where n is the current
;     number within the iteration.
;
;  Assumptions and Constraints
;  Flight software has been configured for the generation of a local 
;    event log.
;
;  Change History
;
;	Date		   Name		Description
;     ----           ----           -----------
;     06/14/05       S. Applebee    Original Procedure
;     06/20/05       S. Applebee    Add changes from informal-walkthrough
;     07/20/05       S. Applebee    Add new requirements
;     07/21/05       S. Applebee    Scenario Cleanup 
;     08/12/05       S. Applebee    Update to standards
;     09/13/05       S. Applebee    Post Formal-walkthrough changes
;     01/06/06       E. Stattel     Build 3.1 
;     09/06          W. Moleski     Adapted to template procedure.
;     12/08/06       N. Schweiss    Changed "RAM:" to "RAM:0" for cFE 4.0.
;
;  Arguments
;
;      Name           Description
;      ----           -----------
;      TST_EVS        Test application to send event messages 
;                     repeatedly
;
;  Procedures/Utilities Called
;         
;      Name                Description
;      ----                -----------
;      ut_runproc          Directive to formally run the procedure and capture the 
;                          log file.
;      ut_pfindicate       Directive to print the pass fail status of a particular 
;                          requirement number.
;      ut_setupevt         Directive to look for a particular event and increment a value
;                          in the CVT to indicate receipt. 
;      ut_tlmupdate        Procedure to wait for a specified telemetry point to update.
;      ut_tlmwait          Procedure to wait for a specified telemetry point to update to 
;                          a specified value.
;      get_file_to_cvt     Procedure to write some specified FSW data to a file and 
;                          then ftp the file from the FSW hardware to ASIST hardware 
;                          and load file to the CVT.
;      load_start_app      Procedure to load and start a user application from the
;                          /s/opr/accounts/cfebx/apps/cpux  directory.
;      ut_setrequirements  Directive to status cfe requirements.
;
;  Expected Test Results and Analysis
;
;  Saved event log files will be loaded to the CVT and examined to
;  verify expected results. Verify that correct event messages are
;  received on the ground.
;
;**********************************************************************
;  Define variables
;**********************************************************************
#include "ut_statusdefs.h"
#include "cfe_platform_cfg.h"
#include "ut_cfe_info.h"
; cfe_utils added to access CPU3_IP, etc.
#include "cfe_utils.h"
#include "cfe_evs_events.h"
#include "cfe_es_events.h"
#include "tst_evs_events.h"

global ut_req_array_size = 17
global ut_requirement[0 .. ut_req_array_size]

#define cEVS3001	0
#define cEVS3013	1
#define cEVS3014	2 
#define cEVS3015	3        
#define cEVS3015_1	4        
#define cEVS3016	5        
#define cEVS3018c	6 
#define cEVS3018h	7
#define cEVS3018i	8
#define cEVS3018j	9      
#define cEVS31034	10      
#define cEVS31035	11      
#define cEVS3108	12      
#define cEVS3108_1	13       
#define cEVS3108_2	14     
#define cEVS3108_31	15
#define cEVS3108_32	16
#define cEVS3301	17

;*******************************************************************************
; If CFE_EVS_LOG_ON configuration parameter is not defined then exit proc with
; appropriate message.
;*******************************************************************************

#ifdef CFE_EVS_LOG_ON 

; CFE_EVS_LOG_ON configuration parameter is defined.

local evs_logfull_f = "FALSE"
local evs_logfull_t = "TRUE"
local evs_logoflctr_0 = 0
local evs_logoflctr_old
local evs_logmode_o = "OVERWRITE"
local evs_logmode_d = "DISCARD"
local evs_msgfmtmde_l = "LONG"
local evs_msgfmtmde_s = "SHORT"

local evs_msg_sent_counter = 0

FOR i = 0 to ut_req_array_size DO
   ut_requirement[i] = "U"
ENDDO
         
local step_241_log_file_time
local step_321_log_file_time
local step_3421_log_file_time
local step_351_log_file_time
local step_352_log_file_time
local step_431_log_file_time
local step_432_log_file_time

write"*****************************************************************"
write " Step 1.0: EVS Reset Test"
write"*****************************************************************"
write " Step 1.1: Command a Power-On Reset on $CPU"
write"*****************************************************************"
/$SC_$CPU_ES_POWERONRESET
wait 10
                                                                                
close_data_center
wait 75
                                                                                
cfe_startup $CPU
wait 5                                                                                 
write ";**********************************************************************"
write ";  Step 2.0:  Verify Platform Startup Settings & Initialize Log"
write ";             Verify FSW configured for Local Event Log"
write ";             Requirement: cEVS3301"
write ";**********************************************************************"
write
write "*** FSW configured for Local Event Log generation."
write
if CFE_EVS_LOG_MAX > 0 then
   ut_setrequirements cEVS3301, "P"
   write "     *** Requirement cEVS3301 PASSED."
else
   ut_setrequirements cEVS3301, "F"
   write "     *** Requirement cEVS3301 FAILED."
endif
write

write ";**********************************************************************"
write ";  Step 2.1: Verify initial EVS Log telemetry values."
write ";	    Requirement(s): cEVS3018c, cEVS3018j"
write ";**********************************************************************"
;		Verify that:
;               p@$SC_$CPU_EVS_LOGFULL = FALSE
;               $SC_$CPU_EVS_LOGOVERFLOWC = 0
;               $SC_$CPU_EVS_LOGMODE = DISCARD (1)
;               $SC_$CPU_EVS_MSGFMTMODE = LONG
;             Get Local Event Log.
;             Local Event Log file dump containing all entries written 
;             as part of FSW startup.
;             cEVS3018c, cEVS3018j

local work = %env("WORK") 
local file = work & "/image/$sc_$cpu_cfe_evs_1_01.log"

write
write "        Message Format Mode: ",  p@$SC_$CPU_EVS_MSGFMTMODE
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write

start get_file_to_cvt ("RAM:0","cfe_evs.log","$sc_$cpu_cfe_evs_2_01.log","$cpu")
wait 10

ut_tlmupdate $SC_$CPU_EVS_MSGFMTMODE

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) THEN
  ut_setrequirements cEVS3018c, "P"
  write "     *** Requirement cEVS3018c PASSED." 
ELSE
  ut_setrequirements cEVS3018c, "F"
  write "     *** Requirement cEVS3018c FAILED."
ENDIF
write

IF (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_d) THEN
  ut_setrequirements cEVS3018j, "P"
  write "     *** Requirement cEVS3018j PASSED."  
ELSE      
  ut_setrequirements cEVS3018j, "F"
  write "     *** Requirement cEVS3018j FAILED."
ENDIF
write

start $sc_$cpu_print_evs_log_file
write 

;drop work
drop file
write

write ";**********************************************************************"
write ";  Step 2.2:  Load EVS Test App"
write ";             Event message indicates test app has started."
write ";**********************************************************************"
;  Dump the properties of all running apps
s get_file_to_cvt ("RAM:0","cfe_es_app_info.log","$sc_$cpu_es_app_info.log","$CPU")
wait 10
                                                                                
local found_app = FALSE

ut_setupevt $SC, $CPU, TST_EVS, 16, INFO

;; Check if the TST_EVS app is in the info tlm
for app_index = 1 to CFE_ES_MAX_APPLICATIONS do
  if ($SC_$CPU_ES_ALE[app_index].ES_AL_AppName = "TST_EVS") then
    found_app = TRUE
  endif
enddo

if (found_app = FALSE) then
  ;; Setup events to capture for TST_EVS start
  ut_setupevents $SC, $CPU, CFE_ES, CFE_ES_START_INF_EID, INFO, 1
  ut_setupevents $SC, $CPU, TST_EVS, TST_EVS_INIT_INF_EID, INFO, 2

   start load_start_app ("TST_EVS", "$CPU")
   wait 20

  ;; Look for expected event #1 & #2
  if (($SC_$CPU_num_found_messages = 1) AND ;;
      ($SC_$CPU_find_event[2].num_found_messages = 1)) then
    write "TST_EVS started successfully."
  else
    write "TST_EVS failed to start. Ending this test."
    goto TST_APP_FAILED
  endif
ELSE
   write "TST_EVS already loaded"
   wait 4
ENDIF

write
;
write
write "        Message Format Mode: ",  p@$SC_$CPU_EVS_MSGFMTMODE
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write

write ";**********************************************************************"
write ";  Step 2.3:  Clear entries from local event log"
write ";**********************************************************************"
;             /$SC_$CPU_EVS_CLRLOG
;            Verify that:
;              p@$SC_$CPU_EVS_LOGFULL = FALSE
;              $SC_$CPU_EVS_LOGOVERFLOWC = 0
;              $SC_$CPU_EVS_LOGMODE = OVERWRITE (0)
;              $SC_$CPU_EVS_MSGFMTMODE = LONG
;            No change in telemetry from Step 1.1

/$SC_$CPU_EVS_CLRLOG
wait 5

write
write "        Message Format Mode: ",  p@$SC_$CPU_EVS_MSGFMTMODE
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_d) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_f) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write 

write ";**********************************************************************"
write ";  Step 2.4: Get Local Event Log."
write ";	    Requirement(s): cEVS3013"
write ";**********************************************************************"
;             Log file dumped containing no entries. File size is 
;             288 bytes.
;             Local event log cleared. Page should show no entries.
;             cEVS3013

local empty_log = TRUE

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_1_4.log", "$cpu")
wait 10

FOR i = 1 to CFE_EVS_LOG_MAX DO
   IF (p@$SC_$CPU_EVS_LOG[i].EVTLOGENTRY.SCID <> "UNK" ) AND (p@$SC_$CPU_EVS_LOG[i].EVTLOGENTRY.PRCID <> "UNK") AND (p@$SC_$CPU_EVS_LOG[i].EVTLOGENTRY.EVTTYPE <> "UNK") THEN 
    empty_log = FALSE
    ut_setrequirements cEVS3013, "F"
    write "     *** Requirement cEVS3013 FAILED."
    write
ENDIF
continue if empty_log = TRUE
ENDDO

IF empty_log = TRUE THEN
  ut_setrequirements cEVS3013, "P"
  write "     *** Requirement cEVS3013 PASSED."
  write
ENDIF
    
start $sc_$cpu_print_evs_log_file 
write

drop empty_log
write

write ";**********************************************************************"
write "; Step 3.0: Test Event Logging Mode - Overwrite"
write ";**********************************************************************"
write "; Step 3.1: Send CFE_EVS_LOG_MAX - 1 Event Messages"
write ";**********************************************************************"
;            Verify that:
;               p@$SC_$CPU_EVS_LOGFULL = FALSE
;               $SC_$CPU_EVS_LOGOVERFLOWC = 0
;               $SC_$CPU_EVS_LOGMODE = OVERWRITE (0)
;               $SC_$CPU_EVS_MSGFMTMODE = LONG

local evs_cmdcnt = $sc_$cpu_evs_cmdpc
local evs_errcnt = $sc_$cpu_evs_cmdec
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec

/$SC_$CPU_EVS_SETLOGMODE OVERWRITE

wait until ($sc_$cpu_evs_cmdpc <> evs_cmdcnt) OR ($sc_$cpu_evs_cmdec <> evs_errcnt) timeout 20
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "7" Iters = CFE_EVS_LOG_MAX-1 Milliseconds = 15
wait CFE_EVS_LOG_MAX+1

evs_msg_sent_counter = CFE_EVS_LOG_MAX - 1

write
write "        Message Format Mode: ",  p@$SC_$CPU_EVS_MSGFMTMODE
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_f) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write 


write ";**********************************************************************"
write ";  Step 3.1.1: Get Local Event Log. "
write ";**********************************************************************"

start get_file_to_cvt ("RAM:0","cfe_evs.log","$sc_$cpu_cfe_evs_2_11.log","$cpu")
wait 10

start $sc_$cpu_print_evs_log_file
write 
write ";**********************************************************************"
write "; Step 3.2: Send more event messages until a total of CFE_EVS_LOG_MAX "
write ";	   have been sent. "
write ";	   Requirement(s): cEVS3108_1, cEVS3018h"
write ";**********************************************************************"
;            Verify that:
;              p@$SC_$CPU_EVS_LOGFULL = TRUE
;              $SC_$CPU_EVS_LOGOVERFLOWC = 0
;              $SC_$CPU_EVS_LOGMODE = OVERWRITE (0)
;              $SC_$CPU_EVS_MSGFMTMODE = LONG
;              cEVS3108.1
;              cEVS3018h

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "6" Iters = CFE_EVS_LOG_MAX-evs_msg_sent_counter Milliseconds = 15
wait CFE_EVS_LOG_MAX-evs_msg_sent_counter+1

ut_tlmwait $SC_$CPU_EVS_LOGFULL 1

write
write "        Message Format Mode: ",  p@$SC_$CPU_EVS_MSGFMTMODE
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write 

IF (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
  ut_setrequirements cEVS3108_1, "P"
  write "     *** Requirement cEVS3108_1 PASSED."
  write
  ut_setrequirements cEVS3018h, "P"
  write "     *** Requirement cEVS3018h PASSED."
ELSE
  ut_setrequirements cEVS3108_1, "F"
  write "     *** Requirement cEVS3108_1 FAILED."
  write
  ut_setrequirements cEVS3018h, "F"
  write "     *** Requirement cEVS3018h FAILED."
ENDIF
write

write ";**********************************************************************"
write ";  Step 3.3: Generate an event after the log is full and verify the log "
write ";            removes the oldest entry."
write ";**********************************************************************"
;             Verify that:
;               p@$SC_$CPU_EVS_LOGFULL = TRUE
;               $SC_$CPU_EVS_LOGOVERFLOWC = 1
;             cEVS3108.1
;             cEVS3108.2
;             cEVS3018h
;             cEVS3018i

write ";***********************************************************************"
write ";  Step 3.3.1: Get Local Event Log. "
write ";***********************************************************************"
;             Log file dumped containing the number and type of entries 
;             sent in previous steps.

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_2_31.log", "$cpu")
wait 10

start $sc_$cpu_print_evs_log_file
write 

write ";**********************************************************************"
write "; Step 3.3.2: Add 1 more event message to the log."
write ";	     Requirements: cEVS3108.1, cEVS3108.2, cEVS3018h, cEVS3018i"
write ";**********************************************************************"

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "7" Iters = "1" Milliseconds = 15
wait 10

write
write "        Message Format Mode: ",  p@$SC_$CPU_EVS_MSGFMTMODE
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0+1) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write 

IF (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
  ut_setrequirements cEVS3108_1, "P"
  write "     *** Requirement cEVS3108_1 PASSED."
  write
  ut_setrequirements cEVS3018h, "P"
  write "     *** Requirement cEVS3018h PASSED."
ELSE
  ut_setrequirements cEVS3108_1, "F"
  write "     *** Requirement cEVS3108_1 FAILED."
  write
  ut_setrequirements cEVS3018h, "F"
  write "     *** Requirement cEVS3018h FAILED."
ENDIF
write

IF ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0+1) THEN
  ut_setrequirements cEVS3108_2, "P"
  write "     *** Requirement cEVS3108_2 PASSED."
  write
  ut_setrequirements cEVS3018i, "P"
  write "     *** Requirement cEVS3018i PASSED."
ELSE
  ut_setrequirements cEVS3108_2, "F"
  write "     *** Requirement cEVS3108_2 FAILED."
  write
  ut_setrequirements cEVS3018i, "F"
  write "     *** Requirement cEVS3018i FAILED."
ENDIF
write

write ";***********************************************************************"
write "; Step 3.3.3: Get Local Event Log. "
write ";	     Requirement: cEVS3108.3"
write ";***********************************************************************"
;             Log file dumped containing the number and type of entries 
;             sent in previous steps.
;             Message previously at top of log (oldest message) has been
;             'popped off'
;             cEVS3108.3

ut_setrequirements cEVS3108_31, "A"
write "     *** Requirement cEVS3108_31 requires ANALYSIS."
write

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_2_33.log", "$cpu")
wait 10

start $sc_$cpu_print_evs_log_file
write 

write ";***********************************************************************"
write "; Step 3.4: Send 14 more event messages."
write ";***********************************************************************"
;            Verify that:
;              p@$SC_$CPU_EVS_LOGFULL = TRUE
;              $SC_$CPU_EVS_LOGOVERFLOWC = 1+ n
;              $SC_$CPU_EVS_LOGMODE = OVERWRITE (0)
;              $SC_$CPU_EVS_MSGFMTMODE = LONG
;            cEVS3108.1
;            cEVS3108.2

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "6" Iters = "14" Milliseconds = 15
wait 15
 
write
write "        Message Format Mode: ",  p@$SC_$CPU_EVS_MSGFMTMODE
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0+15) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write 

IF (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
  ut_setrequirements cEVS3108_1, "P"
  write "     *** Requirement cEVS3108_1 PASSED."
ELSE
  ut_setrequirements cEVS3108_1, "F"
  write "     *** Requirement cEVS3108_1 FAILED."
ENDIF
write

IF ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0+15) THEN
  ut_setrequirements cEVS3108_2, "P"
  write "     *** Requirement cEVS3108_2 PASSED."
ELSE
  ut_setrequirements cEVS3108_2, "F"
  write "     *** Requirement cEVS3108_2 FAILED."
ENDIF
write

IF (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) THEN
  ut_setrequirements cEVS3108j, "P"
  write "     *** Requirement cEVS3108j PASSED."
ELSE
  ut_setrequirements cEVS3108j, "F"
  write "     *** Requirement cEVS3108j FAILED."
ENDIF
write

write ";***********************************************************************"
write "; Step 3.4.1: Get Local Event Log."
write ";	     Requirement(s): cEVS3108.3"
write ";***********************************************************************"
;             Log file dumped containing the number and type of entries 
;             sent in previous steps.'n' messages previously at top of 
;             log (oldest messages) have been 'popped off'.
;             cEVS3108.3

ut_setrequirements cEVS3108_31, "A"
write "     *** Requirement cEVS3108_31 requires ANALYSIS."
write

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_2_41.log", "$cpu")
wait 10

step_241_log_file_time = {"pf" & %hex($CPU_CMDAPID_BASE, 2) & "cFE_createtimeseconds"}

start $sc_$cpu_print_evs_log_file
write 

write ";**********************************************************************"
write "; Step 4.0: Test Event Logging Mode - Discard"
write ";**********************************************************************"
write "; Step 4.1: Set Event Logging Mode to Discard"
write "; 	   Requirement(s): cEVS3014"
write ";**********************************************************************"
;            $SC_$CPU_EVS_LOGMODE = DISCARD
;            Verify that:
;              p@$SC_$CPU_EVS_LOGFULL = TRUE
;              $SC_$CPU_EVS_LOGOVERFLOWC = 1 + n
;              $SC_$CPU_EVS_LOGMODE =DISCARD (1)
;              $SC_$CPU_EVS_MSGFMTMODE = LONG
;            cEVS3014

/$SC_$CPU_EVS_SETLOGMODE DISCARD
wait 5

write
write "        Message Format Mode: ",  p@$SC_$CPU_EVS_MSGFMTMODE
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0+15) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_d) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write

if (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_d) then
   ut_setrequirements cEVS3014 , "P"
   write "     *** Requirement cEVS3014 PASSED."
else
   ut_setrequirements cEVS3014 , "F"
   write "     *** Requirement cEVS3014 FAILED."
endif
write

write ";***********************************************************************"
write "; Step 4.2: Send 12 more event messages"
write ";	   Requirement(s): cEVS3108.1, cEVS3108.2"
write ";***********************************************************************"
;             Verify that:
;               p@$SC_$CPU_EVS_LOGFULL = TRUE
;               $SC_$CPU_EVS_LOGOVERFLOWC = 1 + n + m
;               $SC_$CPU_EVS_LOGMODE = DISCARD (1)
;               $SC_$CPU_EVS_MSGFMTMODE = LONG
;               cEVS3108.1
;               cEVS3108.2

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "7" Iters = "12" Milliseconds = 15
wait 13
 
write
write "        Message Format Mode: ",  p@$SC_$CPU_EVS_MSGFMTMODE
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0+27) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_d) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write 

IF (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
  ut_setrequirements cEVS3108_1, "P"
  write "     *** Requirement cEVS3108_1 PASSED."
ELSE
  ut_setrequirements cEVS3108_1, "F"
  write "     *** Requirement cEVS3108_1 FAILED."
ENDIF
write

IF ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0+27) THEN
    ut_setrequirements cEVS3108_2, "P"
  write "     *** Requirement cEVS3108_2 PASSED."
ELSE
    ut_setrequirements cEVS3108_2, "F"
  write "     *** Requirement cEVS3108_2 FAILED."
ENDIF
write

write ";***********************************************************************"
write "; Step 4.2.1: Get Local Event Log and compare time with previous"
write "; 	     Requirement(s): cEVS3108.3"
write ";***********************************************************************"
;              Verify file dump time changed.
;              Verify file contents are the same as the previous Local 
;              Event Log.
;              Files should only differ in time captured in file header.
;              cEVS3108.3
write

ut_setrequirements cEVS3108_32, "A"
write "     *** Requirement cEVS3108_32 requires ANALYSIS."
write

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_3_21.log", "$cpu")
wait 10

start $sc_$cpu_print_evs_log_file 
write

step_321_log_file_time = {"pf" & %hex($CPU_CMDAPID_BASE, 2) & "cFE_createtimeseconds"}

if (step_241_log_file_time <> step_321_log_file_time) then
   write "*** Log file times are different:"
else
   write "*** Log file times are the same:"
   ut_setrequirements cEVS3108_32, "F"
   write "     *** Requirement cEVS3108_32 FAILED."
endif
write

write
write "        *** Step 3.4.1 Log File Time: ", step_241_log_file_time
write "        *** Step 4.2.1 Log File Time: ", step_321_log_file_time
write

quickrun:
write ";***********************************************************************"
write "; Step 4.3:  Clear Event Log"
write ";***********************************************************************"
write "; Step 4.3.1: Clear entries from local event log."
write "; 	     Requirement(s): cEVS3013"
write ";***********************************************************************"
;             /$SC_$CPU_EVS_CLRLOG
;             Verify that:
;               p@$SC_$CPU_EVS_LOGFULL = FALSE
;               $SC_$CPU_EVS_LOGOVERFLOWC = 0
;               $SC_$CPU_EVS_LOGMODE = DISCARD (1)
;               $SC_$CPU_EVS_MSGFMTMODE = LONG  
;               No telemetry values changed after clear event log command 
;               issued.
;               cEVS3013

/$SC_$CPU_EVS_CLRLOG
wait 5

write
write "        Message Format Mode: ",  p@$SC_$CPU_EVS_MSGFMTMODE
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_d) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_f) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write 

if ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_f) THEN
  ut_setrequirements cEVS3013, "P"
  write "     *** Requirement cEVS3013 PASSED."
  evs_logoflctr_old = 0
ELSE
  ut_setrequirements cEVS3013, "F"
  write "     *** Requirement cEVS3013 FAILED."
ENDIF
write

write ";***********************************************************************"
write "; Step 4.3.2: Get Local Event Log."
write "; 	     Requirement(s): cEVS3013"
write ";***********************************************************************"
;              Log file dumped containing no entries. 
;              File size is 288 bytes.
;              cEVS3013

local empty_log = TRUE

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_3_32.log", "$cpu")
wait 10

FOR i = 1 to CFE_EVS_LOG_MAX DO
   IF (p@$SC_$CPU_EVS_LOG[i].EVTLOGENTRY.SCID <> "UNK" ) AND (p@$SC_$CPU_EVS_LOG[i].EVTLOGENTRY.PRCID <> "UNK") AND (p@$SC_$CPU_EVS_LOG[i].EVTLOGENTRY.EVTTYPE <> "UNK") THEN 
    empty_log = FALSE
    ut_setrequirements cEVS3013, "F"
    write "     *** Requirement cEVS3013 FAILED."
    write
ENDIF
continue if empty_log = TRUE
ENDDO

IF empty_log = TRUE THEN
  ut_setrequirements cEVS3013, "P"
  write "     *** Requirement cEVS3013 PASSED."
  write
ENDIF

drop empty_log
write

start $sc_$cpu_print_evs_log_file
write


write ";***********************************************************************"
write "; Step 4.4: Fill Event Log while in Discard mode"
write ";***********************************************************************"
write "; Step 4.4.1: Send 15 Event Messages"
write ";***********************************************************************"
;              Send 1<n<CFE_EVS_LOG_MAX event messages
;              Verify that:
;                p@$SC_$CPU_EVS_LOGFULL = FALSE
;                $SC_$CPU_EVS_LOGOVERFLOWC = 0 
;                $SC_$CPU_EVS_LOGMODE = DISCARD (1)
;                $SC_$CPU_EVS_MSGFMTMODE = LONG

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "6" Iters = "15" Milliseconds = 15
wait 16

evs_msg_sent_counter = 15

write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ",$SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ",p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_old) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_d) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_f) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write 

write ";***********************************************************************"
write "*** Step 4.4.1.1: Get Local Event Log."
write ";***********************************************************************"
;                Log file dumped 'n' entries. Page should show 'n' entries in 
;                order sent from top - down.

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_3_411.log", "$cpu")
wait 10

start $sc_$cpu_print_evs_log_file
write

write ";***********************************************************************"
write "; Step 4.4.2: Send 5 or more Event Message(s) for a total of "
write "; 	     CFE_EVS_LOG_MAX"
write ";	     Requirement(s): cEVS3108_1, cEVS3018h"
write ";***********************************************************************"
;               Verify that:
;                 p@$SC_$CPU_EVS_LOGFULL = TRUE
;                 $SC_$CPU_EVS_LOGOVERFLOWC = 0
;               cEVS3108.1
;               cEVS3018h

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "7" Iters = CFE_EVS_LOG_MAX-evs_msg_sent_counter Milliseconds = 15
wait CFE_EVS_LOG_MAX-evs_msg_sent_counter+1

write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ",$SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ",p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_old) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_d) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write 

IF (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
  ut_setrequirements cEVS3108_1, "P"
  write "     *** Requirement cEVS3108_1 PASSED."
  write
  ut_setrequirements cEVS3018h, "P"
  write "     *** Requirement cEVS3018h PASSED."
ELSE
  ut_setrequirements cEVS3108_1, "F"
  write "     *** Requirement cEVS3108_1 FAILED."
  write
  ut_setrequirements cEVS3018h, "F"
  write "     *** Requirement cEVS3018h FAILED."
ENDIF
write

write ";***********************************************************************"
write "; Step 4.4.2.1:  Get Local Event Log."
write ";***********************************************************************"
;                 Log file dumped CFE_EVS_LOG_MAX entries

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_3_421.log", "$cpu")
wait 10

step_3421_log_file_time = {"pf" & %hex($CPU_CMDAPID_BASE, 2) & "cFE_createtimeseconds"}

start $sc_$cpu_print_evs_log_file
write

write ";***********************************************************************"
write "; Step 4.4.3:  Send 1 more event message"
write ";***********************************************************************"
;               Verify that:
;               p@$SC_$CPU_EVS_LOGFULL = TRUE
;               $SC_$CPU_EVS_LOGOVERFLOWC = 1
;               $SC_$CPU_EVS_LOGMODE = DISCARD (1)
;               $SC_$CPU_EVS_MSGFMTMODE = LONG

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "6" Iters = "1" Milliseconds = 15
wait 10
write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ",$SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ",p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_old+1) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_d) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write
evs_logoflctr_old=$SC_$CPU_EVS_LOGOVERFLOWC

write ";***********************************************************************"
write "; Step 4.5.1: Test with command-specified file name."
write ";	     Requirement(s): cEVS3015"
write ";***********************************************************************"
;                 Get Local Event Log.
;                 Log file dumped CFE_EVS_LOG_MAX entries
;                 Test cEVS3015 : command log file write with command-
;                  specified filename.

ut_setrequirements cEVS3015, "A"
write "     *** Requirement cEVS3015 requires ANALYSIS."
write
write "     *****************************************************************"
write "     *** Compare Local Event Log to Event Telemetry to verify that ***"
write "     *** the event messages logged agree with the telemetry.       ***" 
write "     *****************************************************************" 
write              

; Then ftp logfile to workstation file dest_filename.
local remote_dir = "RAM:0"
local src_filename = "cfe_evs_3_5_1.log"
local dest_filename = "$sc_$cpu_" & src_filename
;start get_file_to_cvt (remote_dir, src_filename, dest_filename, "$cpu", "EVS_LOG")

; ====================================================================
; Issue command to write event log contents to command-specified file name.
; ====================================================================
evs_cmdcnt = $sc_$cpu_evs_cmdpc
evs_errcnt = $sc_$cpu_evs_cmdec
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec
write
/$sc_$cpu_EVS_WRITELOG2FILE LOGFILENAME="/ram/cfe_evs_3_5_1.log"
wait until ($sc_$cpu_evs_cmdpc <> evs_cmdcnt) OR ($sc_$cpu_evs_cmdec <> evs_errcnt) timeout 20
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec

if ($sc_$cpu_evs_cmdpc <> evs_cmdcnt + 1) OR ($sc_$cpu_evs_cmdec <> evs_errcnt)  then
   ut_setrequirements cEVS3015, "F"
  write "     *** Requirement cEVS3015 FAILED."
endif

; ===================================
; Issue ftp transfer
; ===================================
start ftp_file("RAM:0", "cfe_evs_3_5_1.log", "$sc_$cpu_cfe_evs_3_5_1.log", "$cpu", "g")

; ===================================
; Test if file has arrived to workstation
; ===================================
local dest_pathname = work & "/image/" & dest_filename
IF NOT file_exists(dest_pathname) THEN
  ut_setrequirements cEVS3015, "F"
  write "     *** Requirement cEVS3015 FAILED."
ENDIF
write

; ================================================
; Generate 'appid' value for FILE_TO_CVT call
; ================================================
local appid, appidkey
local cpu = "$CPU"


; ===================================
; Translate from cpu'x' to 'x'
; ===================================
if (%length(cpu) = "4") then
    cpu = %substring(cpu,4,4)
endif

; ===========================================================
; Get appidkey, appid based on cpu 
; ===========================================================
if (cpu = "1") then
   appidkey = "0"
elseif (cpu = "2") then
  appidkey = "2"
elseif (cpu = "3") then
  appidkey = "4"  
else
  error "CPU"&cpu&" is not VALID !!!"
  return
endif

appid = "P0F" & appidkey & "0"  

; ======================================
; Populate CVT with downloaded event log
; ======================================
;;;;FILE_TO_CVT_BETA %name(dest_filename) %name(appid)
FILE_TO_CVT %name(dest_filename) %name(appid)

; ===================================
; Verify that log write time has updated
; ===================================
step_351_log_file_time = {"pf" & %hex($CPU_CMDAPID_BASE, 2) & "cFE_createtimeseconds"}

write
write "        *** Step 4.4.2.1 Log File Time: ", step_3421_log_file_time
write "        *** Step 4.5.1 Log File Time: ", step_351_log_file_time
write

if (step_3421_log_file_time <> step_351_log_file_time) then
   write "*** Log file times are different:"
else
   write "*** Log file times are the same:"
   ut_setrequirements cEVS3015, "F"
   write "     *** Requirement cEVS3015 FAILED."
endif
write


; ===================================
; Print the log contents
; ===================================
start $sc_$cpu_print_evs_log_file
write

write ";***********************************************************************"
write "; Step 4.5.2:  Test with default file name."
write "; 	      Requirement(s): cEVS3015_1"
write ";***********************************************************************"
;                 Get Local Event Log.
;                 Log file dumped CFE_EVS_LOG_MAX entries
;                 Test cEVS3015_1: write event log to default file name.

ut_setrequirements cEVS3015_1, "A"
write "     *** Requirement cEVS3015_1 requires ANALYSIS."
write
write "     *****************************************************************"
write "     *** Compare Local Event Log to Event Telemetry to verify that ***"
write "     *** the event messages logged agree with the telemetry.       ***" 
write "     *****************************************************************" 
write              

write "*** Send 2 more event messages"
write

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "6" Iters = "2" Milliseconds = 15
wait 10
write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ",$SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ",p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

; ====================================================================
; Issue command to write event log contents to default file name.
; ====================================================================
evs_cmdcnt = $sc_$cpu_evs_cmdpc
evs_errcnt = $sc_$cpu_evs_cmdec
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec
write
/$sc_$cpu_EVS_WRITELOG2FILE LOGFILENAME=""
wait until ($sc_$cpu_evs_cmdpc <> evs_cmdcnt) OR ($sc_$cpu_evs_cmdec <> evs_errcnt) timeout 20
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec


if ($sc_$cpu_evs_cmdpc <> evs_cmdcnt + 1) OR ($sc_$cpu_evs_cmdec <> evs_errcnt)  then
   ut_setrequirements cEVS3015_1, "F"
endif

;src_filename = CFE_EVS_DEFAULT_LOG_FILE  this includes leading /ram/ and causes error.

; ===================================
; Issue ftp transfer
; ===================================
src_filename = "cfe_evs.log"
dest_filename =  "$sc_$cpu_" & "cfe_evs_3_5_2.log"
write "ftp ", src_filename, " to ", dest_filename
start ftp_file("RAM:0", src_filename, dest_filename, "$cpu", "g")

; ===================================
; Test if file has arrived at workstation
; ===================================
dest_pathname = work & "/image/" & dest_filename
IF NOT file_exists(dest_pathname) THEN
  ut_setrequirements cEVS3015_1, "F"
  write "     *** Requirement cEVS3015_1 FAILED."
ENDIF
write

; ======================================
; Populate CVT with downloaded event log
; ======================================
FILE_TO_CVT %name(dest_filename) %name(appid)

; ===================================
; Verify that log write time has updated
; ===================================
step_352_log_file_time = {"pf" & %hex($CPU_CMDAPID_BASE, 2) & "cFE_createtimeseconds"}
write
write "        *** Step 4.5.1 Log File Time: ", step_351_log_file_time
write "        *** Step 4.5.2 Log File Time: ", step_352_log_file_time
write

if (step_351_log_file_time <> step_352_log_file_time) then
   write "*** Log file times are different:"
else
   write "*** Log file times are the same:"
   ut_setrequirements cEVS3015_1, "F"
   write "     *** Requirement cEVS3015_1 FAILED."
endif
write

; ===================================
; Get hardcopy and softcopy of log contents
; ===================================

start $sc_$cpu_print_evs_log_file
write

write ";***********************************************************************"
write "; Step 5.0: Test Event Logging Mode - Return to Overwrite"
write ";***********************************************************************"
write "; Step 5.1: Set Event Logging Mode value to overwrite."
write "; 	   Requirement(s): cEVS3014"
write ";***********************************************************************"
;             Verify that:
;               p@$SC_$CPU_EVS_LOGFULL = TRUE
;               $SC_$CPU_EVS_LOGOVERFLOWC = 3
;               $SC_$CPU_EVS_LOGMODE = OVERWRITE (0)
;               $SC_$CPU_EVS_MSGFMTMODE = LONG
;             cEVS3014

evs_cmdcnt = $sc_$cpu_evs_cmdpc
evs_errcnt = $sc_$cpu_evs_cmdec
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec
/$SC_$CPU_EVS_SETLOGMODE OVERWRITE
wait until ($sc_$cpu_evs_cmdpc <> evs_cmdcnt) OR ($sc_$cpu_evs_cmdec <> evs_errcnt) timeout 20
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec

write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_old+2) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write
evs_logoflctr_old=$SC_$CPU_EVS_LOGOVERFLOWC

if (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND ($sc_$cpu_evs_cmdpc = evs_cmdcnt + 1) AND ($sc_$cpu_evs_cmdec = evs_errcnt)  THEN
   ut_setrequirements cEVS3014 , "P"
   write "     *** Requirement cEVS3014 PASSED."
else
   ut_setrequirements cEVS3014 , "F"
   write "     *** Requirement cEVS3014 FAILED."
endif
write

write ";***********************************************************************"
write "; Step 5.2: Send 9 event messages"
write "; 	   Requirement(s): cEVS3108.1, cEVS3108.2"
write ";***********************************************************************"
;             Verify that:
;               $SC_$CPU_EVS_LOGOVERFLOWC = 3 + n
;             cEVS3108.1
;             cEVS3108.2

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "1" Iters = "4" Milliseconds = 15
wait 5
/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "6" Iters = "5" Milliseconds = 15
wait 6

write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ",$SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ",p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_old+9) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write

IF (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_t) THEN
  ut_setrequirements cEVS3108_1, "P"
  write "     *** Requirement cEVS3108_1 PASSED."
ELSE
  ut_setrequirements cEVS3108_1, "F"
  write "     *** Requirement cEVS3108_1 FAILED."
ENDIF
write

IF ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_old+9) THEN
  ut_setrequirements cEVS3108_2, "P"
  write "     *** Requirement cEVS3108_2 PASSED."
ELSE
  ut_setrequirements cEVS3108_2, "F"
  write "     *** Requirement cEVS3108_2 FAILED."
ENDIF
write
evs_logoflctr_old=$SC_$CPU_EVS_LOGOVERFLOWC


write ";***********************************************************************"
write "; Step 5.3: Test WRITELOG command options in OVERWRITE mode."
write ";***********************************************************************"
write "; Step 5.3.1: Test with command-specified file name."
write "; 	     Requirement(s): cEVS3015"
write ";***********************************************************************"
;                 Get Local Event Log.
;                 Log file dumped CFE_EVS_LOG_MAX entries
;                 Test cEVS3015 : command log file write with command-
;                  specified filename.

write
write "     *****************************************************************"
write "     *** Compare Local Event Log to Event Telemetry to verify that ***"
write "     *** the event messages logged agree with the telemetry.       ***" 
write "     *****************************************************************" 
write              

; Then ftp logfile to workstation file dest_filename.
local remote_dir = "RAM:0"
local src_filename = "cfe_evs_4_3_1.log"
local dest_filename = "$sc_$cpu_" & src_filename
;start get_file_to_cvt (remote_dir, src_filename, dest_filename, "$cpu", "EVS_LOG")

; ====================================================================
; Issue command to write event log contents to command-specified file name.
; ====================================================================
local evs_cmdcnt = $sc_$cpu_evs_cmdpc
local evs_errcnt = $sc_$cpu_evs_cmdec
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec
write
/$sc_$cpu_EVS_WRITELOG2FILE LOGFILENAME="/ram/cfe_evs_4_3_1.log"
wait until ($sc_$cpu_evs_cmdpc <> evs_cmdcnt) OR ($sc_$cpu_evs_cmdec <> evs_errcnt) timeout 20
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec

if ($sc_$cpu_evs_cmdpc <> evs_cmdcnt + 1) OR ($sc_$cpu_evs_cmdec <> evs_errcnt)  then
   ut_setrequirements cEVS3015, "F"
  write "     *** Requirement cEVS3015 FAILED."
endif


; ===================================
; Issue ftp transfer
; ===================================
start ftp_file("RAM:0", "cfe_evs_4_3_1.log", "$sc_$cpu_cfe_evs_4_3_1.log", "$cpu", "g")

; ===================================
; Test if file has arrived to workstation
; ===================================
local dest_pathname = work & "/image/" & dest_filename
IF NOT file_exists(dest_pathname) THEN
  ut_setrequirements cEVS3015, "F"
  write "     *** Requirement cEVS3015 FAILED."
ENDIF
write

; ======================================
; Populate CVT with downloaded event log
; ======================================
FILE_TO_CVT %name(dest_filename) %name(appid)

; ===================================
; Verify that log write time has updated
; ===================================
step_431_log_file_time = {"pf" & %hex($CPU_CMDAPID_BASE, 2) & "cFE_createtimeseconds"}

write
write "        *** Step 5.3.1 Log File Time: ", step_431_log_file_time
write "        *** Step 4.5.2 Log File Time: ", step_352_log_file_time
write

if (step_431_log_file_time <> step_352_log_file_time) then
   write "*** Log file times are different:"
else
   write "*** Log file times are the same:"
   ut_setrequirements cEVS3015, "F"
   write "     *** Requirement cEVS3015 FAILED."
endif
write


; ===================================
; Get hardcopy and softcopy of log contents
; ===================================
start $sc_$cpu_print_evs_log_file
write

write ";***********************************************************************"
write "; Step 5.3.2: Get Local Event Log."
write ";	     Requirement(s): cEVS3015_1"
write ";***********************************************************************"
;                 Get Local Event Log.
;                 Log file dumped CFE_EVS_LOG_MAX entries
;                 Test cEVS3015_1: write event log to default file name.

ut_setrequirements cEVS3015_1, "A"
write "     *** Requirement cEVS3015_1 requires ANALYSIS."
write
write "     *****************************************************************"
write "     *** Compare Local Event Log to Event Telemetry to verify that ***"
write "     *** the event messages logged agree with the telemetry.       ***" 
write "     *****************************************************************" 
write              

write "*** Send 2 more event messages"
write

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "6" Iters = "2" Milliseconds = 15
wait 10
write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ",$SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ",p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

; ====================================================================
; Issue command to write event log contents to default file name.
; ====================================================================
evs_cmdcnt = $sc_$cpu_evs_cmdpc
evs_errcnt = $sc_$cpu_evs_cmdec
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec
write
/$sc_$cpu_EVS_WRITELOG2FILE LOGFILENAME=""
wait until ($sc_$cpu_evs_cmdpc <> evs_cmdcnt) OR ($sc_$cpu_evs_cmdec <> evs_errcnt) timeout 20
write "EVS command counters valid/invalid: ", $sc_$cpu_evs_cmdpc, "/", $sc_$cpu_evs_cmdec

if ($sc_$cpu_evs_cmdpc <> evs_cmdcnt + 1) OR ($sc_$cpu_evs_cmdec <> evs_errcnt)  then
   ut_setrequirements cEVS3015_1, "F"
endif

;src_filename = CFE_EVS_DEFAULT_LOG_FILE  this includes leading /ram/ and causes error.


; ===================================
; Issue ftp transfer
; ===================================
src_filename = "cfe_evs.log"
dest_filename =  "$sc_$cpu_" & "cfe_evs_4_3_2.log"
write "ftp ", src_filename, " to ", dest_filename
start ftp_file("RAM:0", src_filename, dest_filename, "$cpu", "g")

; ===================================
; Test if file has arrived at workstation
; ===================================
dest_pathname = work & "/image/" & dest_filename
IF NOT file_exists(dest_pathname) THEN
  ut_setrequirements cEVS3015_1, "F"
  write "     *** Requirement cEVS3015_1 FAILED."
ENDIF
write

; ======================================
; Populate CVT with downloaded event log
; ======================================
FILE_TO_CVT %name(dest_filename) %name(appid)

; ===================================
; Verify that log write time has updated
; ===================================
step_432_log_file_time = {"pf" & %hex($CPU_CMDAPID_BASE, 2) & "cFE_createtimeseconds"}
write
write "        *** Step 5.3.1 Log File Time: ", step_431_log_file_time
write "        *** Step 5.3.2 Log File Time: ", step_432_log_file_time
write

if (step_431_log_file_time <> step_432_log_file_time) then
   write "*** Log file times are different:"
else
   write "*** Log file times are the same:"
   ut_setrequirements cEVS3015_1, "F"
   write "     *** Requirement cEVS3015_1 FAILED."
endif
write

; ===================================
; Get hardcopy and softcopy of log contents
; ===================================

start $sc_$cpu_print_evs_log_file
write

write ";***********************************************************************"
write "; Step 5.4: Send the WRITELOG2FILE command without a path specification"
write "; 	   for the filename."
write ";***********************************************************************"
ut_setupevents $SC, $CPU, CFE_EVS, CFE_EVS_ERR_CRLOGFILE_EID, ERROR, 1

evs_errcnt = $SC_$CPU_EVS_CMDEC + 1

;; Send the command to the TST_ES application
/$SC_$CPU_EVS_WRITELOG2FILE LOGFILENAME="nopathname"
wait 10

ut_tlmwait $SC_$CPU_EVS_CMDEC, {evs_errcnt}
if (UT_TW_Status = UT_Success) then
  write "<*> Passed - WriteLog command failed as expected."
else
  write "<!> Failed - WriteLog command did not increment the CMDEC."
endif

;; Look for expected event #1
if ($SC_$CPU_num_found_messages = 1) then
  write "<*> Passed - Event Msg ",$SC_$CPU_find_event[1].eventid," Found!"
else
  write "<!> Failed - Expected Event Message ", CFE_EVS_ERR_CRLOGFILE_EID, " not received."
endif

write ";***********************************************************************"
write "; Step 6.0: Test Event Message Format"
write ";***********************************************************************"
write "; Step 6.1: Clear entries from local event log."
write ";***********************************************************************"
;             Verify that:
;               p@$SC_$CPU_EVS_LOGFULL = FALSE
;               $SC_$CPU_EVS_LOGOVERFLOWC = 0
;               $SC_$CPU_EVS_LOGMODE = OVERWRITE (0)
;               $SC_$CPU_EVS_MSGFMTMODE = LONG            

/$SC_$CPU_EVS_CLRLOG
wait 5

write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_f) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write

write ";***********************************************************************"
write "; Step 6.1.1:  Get Local Event Log."
write ";***********************************************************************"
;               Log file dumped containing no entries. File size is 288 bytes.

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_5_11.log", "$cpu")
wait 10
write

start $sc_$cpu_print_evs_log_file
write

write ";***********************************************************************"
write "; Step 6.2: Send 4 event messages"
write ";***********************************************************************"

; Need to capture upcoming messages for cEVS3103.4 test
;;ASK "If there's is no UART window up, open one now"

local eventFmt_Pass=FALSE

FOR i = 1 to 4 DO
  ut_setupevt $SC, $CPU, TST_EVS, 7, INFO
  wait 2
  /$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "7" Iters = "1" Milliseconds = 15
  wait 2
  IF ($SC_$CPU_num_found_messages = 1) THEN
     IF ($SC_$CPU_find_event[1].event_txt <> "") THEN
        eventFmt_Pass=TRUE
        write
        write "Event Message ",i," is in LONG format as expected."
        write
     ELSE
        write
        write "*** ALERT *** Event Message ",i," not in LONG format."
        write
     ENDIF
  ELSE
     write
     write "*** ALERT *** No Event Message Received !!!"
     write
  ENDIF
ENDDO

IF (eventFmt_Pass = FALSE) THEN
  ut_setrequirements cEVS31034, "F"
  write "     *** Requirement cEVS3103.4 FAILED."
ELSE
  ut_setrequirements cEVS31034, "P"
  write "     *** Requirement cEVS3103.4 PASSED."
ENDIF

write ";***********************************************************************"
write "; Step 6.3: Set Event Logging Format value to 'SHORT'"
write "; 	   Requirement(s): cEVS3001"
write ";***********************************************************************"
;             All telemetry values except $SC_$CPU_EVS_MSGFMTMODE retain the 
;             same values
;             Verify that:
;               $SC_$CPU_EVS_MSGFMTMODE = SHORT
;               p@$SC_$CPU_EVS_LOGFULL = FALSE
;               $SC_$CPU_EVS_LOGOVERFLOWC = 0
;               $SC_$CPU_EVS_LOGMODE = OVERWRITE (0)
;             cEVS3001

/$SC_$CPU_EVS_SETEVTFMT SHORT
wait 5


write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_s) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_f) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_s) THEN
  ut_setrequirements cEVS3001, "P"
  write "     *** Requirement cEVS3001 PASSED."
ELSE
  ut_setrequirements cEVS3001, "F"
  write "     *** Requirement cEVS3001 FAILED."
ENDIF
write

write ";***********************************************************************"
write "; Step 6.4: Send 7 event messages"
write "; 	   Requirement(s): cEVS3001; cEVS3103.5"
write ";***********************************************************************"
;             Event messages are in 'SHORT' format


FOR i = 1 to 7 DO
  ut_setupevt $SC, $CPU, TST_EVS, 6, INFO
  wait 2
  /$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "6" Iters = "1" Milliseconds = 15
  wait 2
  IF ($SC_$CPU_num_found_messages = 1) THEN
     IF ($SC_$CPU_find_event[1].event_txt <> "") THEN
        write
        write "*** ALERT *** Event Message ",i," not in SHORT format"
        write
     ELSE
        eventFmt_Pass=TRUE
        write
        write "Event Message ",i," in SHORT format as expected."
        write
     ENDIF
  ELSE
     write
     write "*** ALERT *** No Event Message Received !!!"
     write
  ENDIF
ENDDO

IF (eventFmt_Pass = FALSE) THEN
  ut_setrequirements cEVS3001, "F"
  ut_setrequirements cEVS31035, "F"
  write "     *** Requirement cEVS3001 & cEVS3103.5 FAILED."
ELSE
  ut_setrequirements cEVS3001, "P"
  ut_setrequirements cEVS31035, "P"
  write "     *** Requirement cEVS3001 & cEVS3103.5 PASSED."
ENDIF
write

write ";***********************************************************************"
write "; Step 6.4.1: Get Local Event Log."
write "; 	     Requirement(s): cEVS3108, cEVS3001"
write ";***********************************************************************"
;               Log file dumped containing n entries. Entries are in 'long' 
;               format.

local event_text

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_5_41.log", "$cpu")
wait 10

FOR i = 1 to 11 DO
   IF (p@$SC_$CPU_EVS_LOG[i].EVTMSG <> "") THEN
      event_text = TRUE
   ELSE
      event_text = FALSE
   ENDIF
   continue if event_text = TRUE
ENDDO
     
IF event_text = TRUE THEN
    ut_setrequirements cEVS3108, "P"
    write "     *** Requirement cEVS3108 PASSED."
    write
    ut_setrequirements cEVS3001, "P"
    write "     *** Requirement cEVS3001 PASSED."
ELSE
    ut_setrequirements cEVS3108, "F"
    write "     *** Requirement cEVS3108 FAILED."
    write
    ut_setrequirements cEVS3001, "F"
    write "     *** Requirement cEVS3001 FAILED."
ENDIF
write

start $sc_$cpu_print_evs_log_file
write

drop event_text
write

write ";***********************************************************************"
write "; Step 6.4.2: Analyze the UART Log."
write "; 	     Requirement(s): cEVS3001"
write ";***********************************************************************"
;               Obtain copy of UART log. Verify that entries are in 'long' or
;               'short' format as appropriate.
write
write "     *****************************************************************"
write "     *** Verify in the UART log file that the previous 7 Event     ***"
write "     *** Messages are written in the short format and the 4 Event  ***"
write "     *** above that 7 are written in long format.                  ***"
write "     *****************************************************************" 
write              

ut_setrequirements cEVS3001, "A"
write "     *** Requirement cEVS3001 requires ANALYSIS."
write

start $sc_$cpu_print_evs_log_file
write "Verify the last 11 Event Messages are in short format"
;;ASK "Capture the last 11 Event Messages from the UART window"

write ";***********************************************************************"
write "; Step 7.0: Test Event Message Logging Progression"
write ";***********************************************************************"
write "; Step 7.1: Set Event Logging Format value to 'LONG'"
write "; 	   Requirement(s): cEVS3001"
write ";***********************************************************************"
;             All telemetry values except $SC_$CPU_EVS_MSGFMTMODE retain the 
;             same values
;             Verify that:
;               $SC_$CPU_EVS_MSGFMTMODE = LONG
;               p@$SC_$CPU_EVS_LOGFULL = FALSE
;               $SC_$CPU_EVS_LOGOVERFLOWC = 0
;               $SC_$CPU_EVS_LOGMODE = OVERWRITE (0)

/$SC_$CPU_EVS_SETEVTFMT LONG
wait 5

write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ", $SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ", p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_f) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write
IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) THEN
  ut_setrequirements cEVS3001, "P"
  write "     *** Requirement cEVS3001 PASSED."
ELSE
  ut_setrequirements cEVS3001, "F"
  write "     *** Requirement cEVS3001 FAILED."
ENDIF
write

write ";***********************************************************************"
write "; Step 7.2: Clear entries from local event log."
write ";***********************************************************************"
;            Verify that:
;              p@$SC_$CPU_EVS_LOGFULL = FALSE
;              $SC_$CPU_EVS_LOGOVERFLOWC = 0

/$SC_$CPU_EVS_CLRLOG
wait 5

write
write "        Event Log Full: ", p@$SC_$CPU_EVS_LOGFULL
write "        Local Log Overflow Counter: ",$SC_$CPU_EVS_LOGOVERFLOWC
write "        Local Event Log Mode: ",p@$SC_$CPU_EVS_LOGMODE
write "        Message Format Mode: ", p@$SC_$CPU_EVS_MSGFMTMODE
write

IF (p@$SC_$CPU_EVS_MSGFMTMODE = evs_msgfmtmde_l) AND ($SC_$CPU_EVS_LOGOVERFLOWC = evs_logoflctr_0) AND (p@$SC_$CPU_EVS_LOGMODE = evs_logmode_o) AND (p@$SC_$CPU_EVS_LOGFULL= evs_logfull_f) THEN
    write "     *** EVS Log telemetry values as expected."
ELSE
    write "     *** EVS Log telemetry values NOT as expected."
ENDIF
write

write ";***********************************************************************"
write "; Step 7.2.1: Get Local Event Log"
write ";***********************************************************************"
;              Log file dumped containing no entries. File size is 288 bytes.

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_6_21.log", "$cpu")
wait 10

start $sc_$cpu_print_evs_log_file
write

write ";***********************************************************************"
write "; Step 7.3: Send 7 events."
write ";***********************************************************************"

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "7" Iters = "7" Milliseconds = 15
wait 8

write ";***********************************************************************"
write "; Step 7.4: Set time back"
write ";***********************************************************************"
;            Verify new time earlier than previous time.
;            Make note of set time value.

/$SC_$CPU_TIME_SUBSTCFADJ SECONDS=X'fffffff' MICROSECS=X'0'
wait 5
write "        Time set to:", LAST_PKT_MET
write

write ";***********************************************************************"
write "; Step 7.5: Send some more events"
write ";***********************************************************************"
;            Keep track of event order.

/$SC_$CPU_TST_EVS_SendEvtMsg INFO EventId = "6" Iters = "3" Milliseconds = 15
wait 4

write ";***********************************************************************"
write "; Step 7.5.1: Get Local Event Log."
write "; 	     Requirement(s): cEVS3016"
write ";***********************************************************************"
;          Log file dumped containing n+more events. Events are written to log 
;          in the order sent. Time tag for events goes forward, then goes back 
;          to approximately the value set in step 6.4 and then resumes moving 
;          forward.

ut_setrequirements cEVS3016, "A"
write "     *** Requirement cEVS3016 requires ANALYSIS."
write

start get_file_to_cvt ("RAM:0", "cfe_evs.log", "$sc_$cpu_cfe_evs_6_51.log", "$cpu")
wait 10

start $sc_$cpu_print_evs_log_file
write
;********************************************************************************
#else
;
; _CFE_EVS_LOG_ON_ configuration parameter is NOT defined.
;
    write
    write "*** FSW NOT configured for Local Event Log generation."
    write
    FOR i = 0 to ut_req_array_size DO
       ut_requirement[i] = "N/A"
    ENDDO
#endif

TST_APP_FAILED:

;********************************************************************************
; Requirements Report
;********************************************************************************
REQUIREMENTS:

local cfe_requirements[0 .. ut_req_array_size] = ["cEVS3001", "cEVS3013", "cEVS3014", "cEVS3015", "cEVS3015.1", "cEVS3016", "cEVS3018c", "cEVS3018h", "cEVS3018i", "cEVS3018j", "cEVS3103.4", "cEVS3103.5", "cEVS3108", "cEVS3108.1", "cEVS3108.2", "cEVS3108.31", "cEVS3108.32", "cEVS3301"]

write "**** Requirements Status Reporting"

write
write "Requirement(s) Report"
write "---------------------"

FOR i = 0 to ut_req_array_size DO
  ut_pfindicate {cfe_requirements[i]} {ut_requirement[i]}
ENDDO
write

drop ut_requirement ; needed to clear global variables
drop ut_req_array_size ; needed to clear global variables
write

;  End procedure $sc_$cpu_log
;**********************************************************************
endproc
