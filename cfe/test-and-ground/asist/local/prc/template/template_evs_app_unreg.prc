PROC $sc_$cpu_evs_app_unreg 
;
;   This sub-proc request the generation of one event message
;   which is registered for filtering and one which is not.
;   Neither event message shall be generated to meet
;   Requirement cEVS3101:
;   Upon receipt of Request, the cFE shall un-register an Application from 
;   using event services, deleting the following Application data:
;   Application Event Message Sent Counter
;   Application Event Service Enable Status 
;   Application Event Type Enable Statuses (one for each Event Type)
;   Application Filtered Event IDs
;   Application Binary Filter Masks (one per registered Event ID)
;   Application Binary Filter Counters (one per registered Event ID) 
;
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
                      ut_setrequirements cEVS3101, "P"
write "cEVS3101 passed " 
                    else
                      ut_setrequirements cEVS3101, "F"
write "cEVS3101 failed " 
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7, DEBUG
                    wait 3

                    /$sc_$cpu_TST_EVS_SendEvtMsg DEBUG EventId = "7" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3101, "P"
write "cEVS3101 passed " 
                    else
                      ut_setrequirements cEVS3101, "F"
write "cEVS3101 failed " 
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
                      ut_setrequirements cEVS3101, "P"
write "cEVS3101 passed " 
                    else
                      ut_setrequirements cEVS3101, "F"
write "cEVS3101 failed " 
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7, INFO
                    wait 3
;
                    /$sc_$cpu_TST_EVS_SendEvtMsg INFO EventId = "7" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3101, "P"
write "cEVS3101 passed " 
                    else
                      ut_setrequirements cEVS3101, "F"
write "cEVS3101 failed " 
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
                      ut_setrequirements cEVS3101, "P"
write "cEVS3101 passed " 
                    else
                      ut_setrequirements cEVS3101, "F"
write "cEVS3101 failed " 
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7, ERROR
                    wait 3

                    /$sc_$cpu_TST_EVS_SendEvtMsg ERROR EventId = "7" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3101, "P"
write "cEVS3101 passed " 
                    else
                      ut_setrequirements cEVS3101, "F"
write "cEVS3101 failed " 
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
                      ut_setrequirements cEVS3101, "P"
write "cEVS3101 passed " 
                    else
                       ut_setrequirements cEVS3101, "F"
write "cEVS3101 failed " 
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7,  CRIT
                    wait 3
;
                    /$sc_$cpu_TST_EVS_SendEvtMsg CRIT EventId = "7" Iters = "1" Milliseconds = "100"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 0) then
                      ut_setrequirements cEVS3101, "P"
write "cEVS3101 passed " 
                    else
                      ut_setrequirements cEVS3101, "F"
write "cEVS3101 failed " 
                    endif             
;
ENDPROC ; $sc_$cpu_evs_app_unreg
