PROC $sc_$cpu_evs_dflt_chk
; Sub-procedure to set up requirements
; upon initial power on default values verification
; Called by evs reset test
; Written on May-30-2006 by Eva I. Stattel
; 
#include "ut_statusdefs.h"       
#include "cfe_platform_cfg.h"
#include "cfe_mission_cfg.h" 

;; NOTE: CFE_EVS_PORT_DEFAULT define is not recognized by STOL 
;;       as a valid hex value resulting in a syntax error
;;  if ($sc_$cpu_EVS_OUTPUTPORT = CFE_EVS_PORT_DEFAULT) then
  if ($sc_$cpu_EVS_OUTPUTPORT = 1) then
    ut_setrequirements cEVS3200, "P"
  else
    ut_setrequirements cEVS3200, "F"
    write " ALERT: cEVS3200 failed when checking default value for evt port enabled"
  endif
    write " Output Ports Enabled ", %bin($sc_$cpu_EVS_OUTPUTPORT, 4) 
;
  if (p@$sc_$cpu_EVS_LOGFULL = "FALSE") then 
    ut_setrequirements cEVS3202, "P"
  else
    write " ALERT: cEVS3202 is tested outside of this proc"
  endif
    write " Local event log full flag = ", p@$sc_$cpu_EVS_LOGFULL 
;
  if (p@$sc_$cpu_EVS_MSGFMTMODE = "LONG") then
    ut_setrequirements cEVS3201, "P"
  else
    ut_setrequirements cEVS3201, "F"
    write " ALERT: cEVS3201 failed when checking default value for evt msg format"
  endif
    write " Event Msg Format = ", p@$sc_$cpu_EVS_MSGFMTMODE
;
  if ($sc_$cpu_EVS_LOGMODE = CFE_EVS_DEFAULT_LOG_MODE) then
    ut_setrequirements cEVS3203, "P"
  else
    ut_setrequirements cEVS3203, "P"
    write " ALERT: cEVS3203 failed when checking default value for logging mode"
  endif
    write " Logging Mode = ", $sc_$cpu_EVS_LOGMODE 
;
ENDPROC
