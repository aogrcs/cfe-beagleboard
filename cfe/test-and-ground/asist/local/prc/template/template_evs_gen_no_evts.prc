PROC $sc_$cpu_evs_gen_no_evts
;
;  Purpose: 
;           This is a sub-procedure  
;           To request generation of event messages of every evt msg type:
;
;           One of these event msgs is registered for filtering
;           and the other event msg is not. 
;           
;           Requirement cEVS3103 
;           Upon receipt of a Request to send an Event Message, the cFE shall
;           create a Short or Long Event Message, as specified by the SB Event
;           Format Mode, ONLY if the following cFE conditions are met:
;           The requesting Application's Event Service Enable Status is Enabled.
;           The requesting Application's registered message filtering algorithm 
;           indicates the message should be sent.
;           The requesting Application's Event Type Enable Status is Enabled 
;           for the Event Type of the request-specified Event Message. 
;
;           These events shall NOT be generated because they are requested
;           upon verification of the conditions set in requirement cEVS3103
;           and this event message generation request is made upon DISABLING
;           the Event Message Generation for the Test Application (this also
;           satisties requirement cEVS3008).
;
;           Requirement cEVS3008 
;           Upon receipt of Command the cFE shall enable/disable, as specified
;           in the Command, the future generation of Event Messages for the 
;           Command-specified Application and Event Type.
; 
write"*************************************************************"
;
#include "cfe_evs_gen_reqts.h"
; 
FOR i = 0 to ut_req_array_size DO
write "Requirement at [",i,"] = ", ut_requirement[i] 
ENDDO 
;
write"  _________"   
write   "        |  Request generation of DEBUG type event messages"
;
                    ut_setupevt $sc, $cpu, TST_EVS, 1, DEBUG
                    wait 3

                    /$sc_$cpu_TST_EVS_SendEvtMsg DEBUG EventId = "1" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3008, "P"
                      write "cEVS3008 passed "
                      ut_setrequirements cEVS3103, "P"
                      write "cEVS3103 passed "
                    else
                      ut_setrequirements cEVS3008, "F"
                      write "cEVS3008 failed "
                      ut_setrequirements cEVS3103, "F"
                      write "cEVS3103 failed  "
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7, DEBUG
                    wait 3

                    /$sc_$cpu_TST_EVS_SendEvtMsg DEBUG EventId = "7" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3008, "P"
                      write "cEVS3008 passed "
                      ut_setrequirements cEVS3103, "P"
                      write "cEVS3103 passed "
                    else
                      ut_setrequirements cEVS3008, "F"
                      write "cEVS3008 failed "
                      ut_setrequirements cEVS3103, "F"
                      write "cEVS3103 failed "
                    endif             
;
write"*************************************************************"

write"  _________"
write   "        |  Request generation of INFO type event messages"
;
                    ut_setupevt $sc, $cpu, TST_EVS, 1, INFO
                    wait 3
;                
                    /$sc_$cpu_TST_EVS_SendEvtMsg INFO  EventId = "1" Iters = "1" Milliseconds = "100"
                    wait 4
;                
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3008, "P"
                      write "cEVS3008 passed "
                      ut_setrequirements cEVS3103, "P"
                      write "cEVS3103 passed "
                    else
                      ut_setrequirements cEVS3008, "F"
                      write "cEVS3008 failed "
                      ut_setrequirements cEVS3103, "F"
                      write "cEVS3103 failed "
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7, INFO
                    wait 3
;
                    /$sc_$cpu_TST_EVS_SendEvtMsg INFO EventId = "7" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3008, "P"
                      write "cEVS3008 passed "
                      ut_setrequirements cEVS3103, "P"
                      write "cEVS3103 passed "
                    else
                      ut_setrequirements cEVS3008, "F"
                      write "cEVS3008 failed "
                      ut_setrequirements cEVS3103, "F"
                      write "cEVS3103 failed "
                    endif             
;
write"*************************************************************"
;
write"  _________"   
write   "        |  Request generation of ERROR type event messages"
;
                    ut_setupevt $sc, $cpu, TST_EVS, 1, ERROR
                    wait 3

                    /$sc_$cpu_TST_EVS_SendEvtMsg ERROR EventId = "1" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3008, "P"
                      write "cEVS3008 passed "
                      ut_setrequirements cEVS3103, "P"
                      write "cEVS3103 passed "
                    else
                      ut_setrequirements cEVS3008, "F"
                      write "cEVS3008 failed "
                      ut_setrequirements cEVS3103, "F"
                      write "cEVS3103 failed "
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7, ERROR
                    wait 3

                    /$sc_$cpu_TST_EVS_SendEvtMsg ERROR EventId = "7" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3008, "P"
                      write "cEVS3008 passed "
                      ut_setrequirements cEVS3103, "P"
                      write "cEVS3103 passed "
                    else
                      ut_setrequirements cEVS3008, "F"
                      write "cEVS3008 failed "
                      ut_setrequirements cEVS3103, "F"
                      write "cEVS3103 failed "
                    endif             
;
write"*************************************************************"
;
write"  _________"
write   "        |  Request generation of CRITICAL type event messages"
;
                    ut_setupevt $sc, $cpu, TST_EVS, 1,  CRIT
                    wait 3
;
                    /$sc_$cpu_TST_EVS_SendEvtMsg CRIT EventId = "1" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3008, "P"
                      write "cEVS3008 passed "
                      ut_setrequirements cEVS3103, "P"
                      write "cEVS3103 passed "
                    else
                      ut_setrequirements cEVS3008, "F"
                      write "cEVS3008 failed "
                      ut_setrequirements cEVS3103, "F"
                      write "cEVS3103 failed "
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7,  CRIT
                    wait 3
;
                    /$sc_$cpu_TST_EVS_SendEvtMsg CRIT EventId = "7" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3008, "P"
                      write "cEVS3008 passed "
                      ut_setrequirements cEVS3103, "P"
                      write "cEVS3103 passed "
                    else
                      ut_setrequirements cEVS3008, "F"
                      write "cEVS3008 failed "
                      ut_setrequirements cEVS3103, "F"
                      write "cEVS3103 failed "
                    endif             
;
ENDPROC ; $sc_$cpu_evs_gen_no_evts
