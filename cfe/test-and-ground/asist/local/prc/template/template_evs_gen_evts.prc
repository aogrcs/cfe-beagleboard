PROC $sc_$cpu_evs_gen_evts
;
;  Purpose: 
;           This is a sub-procedure  
;           To request generation of event messages of every evt msg type:
;           These events shall be generated because they are requested
;           upon verification of the conditions set in requirement cEVS3103
;
;           One of these event msgs is registered for filtering
;           and the other event msg is not. 
;           
;           The succesful generation of these event messages also
;           verifies requirement cEVS3102 which stipulates:
;           That cFE shall support the following Event Message Types:
;             Debug, Informational, Error and Critical
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

                    /$sc_$cpu_TST_EVS_SendEvtMsg DEBUG EventId = "1" Iters = "1" Milliseconds = "150"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 1) then
                      ut_setrequirements cEVS3102, "P"
                      write" cEVS3102 passed"
                      ut_setrequirements cEVS3103, "P"
                      write" cEVS3103 passed"
                      wait 2
                    else
                      ut_setrequirements cEVS3102, "F"
                      write" cEVS3102 failed"
                      ut_setrequirements cEVS3103, "F"
                      write" cEVS3103 failed"
                      wait 2
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7, DEBUG
                    wait 3

                    /$sc_$cpu_TST_EVS_SendEvtMsg DEBUG EventId = "7" Iters = "1" Milliseconds = "150"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 1) then
                      ut_setrequirements cEVS3102, "P"
                      write" cEVS3102 passed"
                      ut_setrequirements cEVS3103, "P"
                      write" cEVS3103 passed"
                      wait 2
                    else
                      ut_setrequirements cEVS3102, "F"
                      write" cEVS3102 failed"
                      ut_setrequirements cEVS3103, "F"
                      write" cEVS3103 failed"
                      wait 2
                    endif             
;
write"*************************************************************"

write"  _________"
write   "        |  Request generation of INFO type event messages"
;
                    ut_setupevt $sc, $cpu, TST_EVS, 1, INFO
                    wait 3
;                
                    /$sc_$cpu_TST_EVS_SendEvtMsg INFO  EventId = "1" Iters = "1" Milliseconds = "150"
                    wait 4
;                
                    if ($sc_$cpu_num_found_messages = 1) then
                      ut_setrequirements cEVS3102, "P"
                      write" cEVS3102 passed"
                      ut_setrequirements cEVS3103, "P"
                      write" cEVS3103 passed"
                      wait 2
                    else
                      ut_setrequirements cEVS3102, "F"
                      write" cEVS3102 failed"
                      ut_setrequirements cEVS3103, "F"
                      write" cEVS3103 failed"
                      wait 2
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7, INFO
                    wait 3
;
                    /$sc_$cpu_TST_EVS_SendEvtMsg INFO EventId = "7" Iters = "1" Milliseconds = "150"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 1) then
                      ut_setrequirements cEVS3102, "P"
                      write" cEVS3102 passed"
                      ut_setrequirements cEVS3103, "P"
                      write" cEVS3103 passed"
                      wait 2
                    else
                      ut_setrequirements cEVS3102, "F"
                      write" cEVS3102 failed"
                      ut_setrequirements cEVS3103, "F"
                      write" cEVS3103 failed"
                      wait 2
                    endif             
;
write"*************************************************************"
;
write"  _________"   
write   "        |  Request generation of ERROR type event messages"
;
                    ut_setupevt $sc, $cpu, TST_EVS, 1, ERROR
                    wait 3

                    /$sc_$cpu_TST_EVS_SendEvtMsg ERROR EventId = "1" Iters = "1" Milliseconds = "150"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 1) then
                      ut_setrequirements cEVS3102, "P"
                      write" cEVS3102 passed"
                      ut_setrequirements cEVS3103, "P"
                      write" cEVS3103 passed"
                      wait 2
                    else
                      ut_setrequirements cEVS3102, "F"
                      write" cEVS3102 failed"
                      ut_setrequirements cEVS3103, "F"
                      wait 2
                      write" cEVS3103 failed"
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7, ERROR
                    wait 3

                    /$sc_$cpu_TST_EVS_SendEvtMsg ERROR EventId = "7" Iters = "1" Milliseconds = "150"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 1) then
                      ut_setrequirements cEVS3102, "P"
                      write" cEVS3102 passed"
                      ut_setrequirements cEVS3103, "P"
                      write" cEVS3103 passed"
                      wait 2
                    else
                      ut_setrequirements cEVS3102, "F"
                      write" cEVS3102 failed"
                      ut_setrequirements cEVS3103, "F"
                      write" cEVS3103 failed"
                      wait 2
                    endif             
;
write"*************************************************************"
;
write"  _________"
write   "        |  Request generation of CRITICAL type event messages"
;
                    ut_setupevt $sc, $cpu, TST_EVS, 1, CRITICAL
                    wait 3
;
                    /$sc_$cpu_TST_EVS_SendEvtMsg CRIT EventId = "1" Iters = "1" Milliseconds = "150"
                    wait 4
;
                    if ($sc_$cpu_num_found_messages = 1) then
                      ut_setrequirements cEVS3102, "P"
                      write" cEVS3102 passed"
                      ut_setrequirements cEVS3103, "P"
                      write" cEVS3103 passed"
                      wait 2
                    else
                      ut_setrequirements cEVS3102, "F"
                      write" cEVS3102 failed"
                      ut_setrequirements cEVS3103, "F"
                      write" cEVS3103 failed"
                      wait 2
                    endif             
;
                    ut_setupevt $sc, $cpu, TST_EVS, 7, CRITICAL
                    wait 3
;
                    /$sc_$cpu_TST_EVS_SendEvtMsg CRIT EventId = "7" Iters = "1" Milliseconds = "150"
                    wait 6
;
                    if ($sc_$cpu_num_found_messages = 1) then
                      ut_setrequirements cEVS3102, "P"
                      write" cEVS3102 passed"
                      ut_setrequirements cEVS3103, "P"
                      write" cEVS3103 passed"
                      wait 2
                    else
                      ut_setrequirements cEVS3102, "F"
                      write" cEVS3102 failed"
                      ut_setrequirements cEVS3103, "F"
                      write" cEVS3103 failed"
                      wait 2
                    endif             
;
ENDPROC ; $sc_$cpu_evs_gen_evts
