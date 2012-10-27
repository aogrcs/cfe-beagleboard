proc clear_spacecraft_status
;
local logging = %liv(log_procedure)
%liv (log_procedure) = FALSE
;
; ======================================================================
; Purpose: The purpose of this procedure is to clear the 
;          checksum, cFE version, and OS version information in
;          the Spacecraft status block on the ASIST command window.
;
; History:
;
; 03JUN05                 Initial development of this proc.      SMA
; 21OCT09                 Added include statement and modified   WFM
;                         code to generically set values based
;                         upon definitions in the include file
;
;

#include "cfe_utils.h"

; Build the database prefix using SC and CPU definitions from cfe_utils.h
local db_prefix, cpu_prefix

; If SC is set, use it
if (SC <> "") then
  db_prefix = SC
endif

;; Add the CPU definition
db_prefix = db_prefix & CPU_CFG

; Clear Checksum, cFE Version, and OS Version Values for CPU1
; Set the database prefix for CPU1
if (numCPUs > 1) then
  cpu_prefix = db_prefix & "1"
endif

; setup the database mnemonics for CPU1
local cksumItem = cpu_prefix & "_ES_CKSUM"
local cfeMajorVerItem = cpu_prefix & "_ES_CFEMAJORVER"
local cfeMinorVerItem = cpu_prefix & "_ES_CFEMINORVER"
local cfeSubMinorVerItem = cpu_prefix & "_ES_CFESUBMINORVER"
local osMajorVerItem = cpu_prefix & "_ES_OSMAJORVER"
local osMinorVerItem = cpu_prefix & "_ES_OSMINORVER"

gsescstatval11 = ""
gsescstatval21 = ""
gsescstatval31 = ""

{cksumItem} = ""
{cfeMajorVerItem} = ""
{cfeMinorVerItem} = ""
{cfeSubMinorVerItem} = ""
{osMajorVerItem} = ""
{osMinorVerItem} = ""
;;  SCX_CPU1_ES_CKSUM = ""
;;  SCX_CPU1_ES_CFEMAJORVER = ""
;;  SCX_CPU1_ES_CFEMINORVER = ""
;;  SCX_CPU1_ES_OSMAJORVER = ""
;;  SCX_CPU1_ES_OSMINORVER = ""

; If there are multiple CPUs, then clear the appropriate values
if (numCPUs >= 2) then
  ; Set the database prefix for CPU2
  cpu_prefix = db_prefix & "2"

  ; setup the database mnemonics for CPU2
  cksumItem = cpu_prefix & "_ES_CKSUM"
  cfeMajorVerItem = cpu_prefix & "_ES_CFEMAJORVER"
  cfeMinorVerItem = cpu_prefix & "_ES_CFEMINORVER"
  cfeSubMinorVerItem = cpu_prefix & "_ES_CFESUBMINORVER"
  osMajorVerItem = cpu_prefix & "_ES_OSMAJORVER"
  osMinorVerItem = cpu_prefix & "_ES_OSMINORVER"

  ; Clear Checksum, cFE Version, and OS Version Values for CPU2
  gsescstatval12 = ""
  gsescstatval22 = ""
  gsescstatval32 = ""

  {cksumItem} = ""
  {cfeMajorVerItem} = ""
  {cfeMinorVerItem} = ""
  {cfeSubMinorVerItem} = ""
  {osMajorVerItem} = ""
  {osMinorVerItem} = ""
;;  SCX_CPU2_ES_CKSUM = ""
;;  SCX_CPU2_ES_CFEMAJORVER = ""
;;  SCX_CPU2_ES_CFEMINORVER = ""
;;  SCX_CPU2_ES_OSMAJORVER = ""
;;  SCX_CPU2_ES_OSMINORVER = ""
endif

; This proc only supports up to 3 CPUs.
; If there are more than 3, the additional CPUs must be added below
if (numCPUs = 3) then
  ; Set the database prefix for CPU3
  cpu_prefix = db_prefix & "3"

  ; setup the database mnemonics for CPU3
  cksumItem = cpu_prefix & "_ES_CKSUM"
  cfeMajorVerItem = cpu_prefix & "_ES_CFEMAJORVER"
  cfeMinorVerItem = cpu_prefix & "_ES_CFEMINORVER"
  cfeSubMinorVerItem = cpu_prefix & "_ES_CFESUBMINORVER"
  osMajorVerItem = cpu_prefix & "_ES_OSMAJORVER"
  osMinorVerItem = cpu_prefix & "_ES_OSMINORVER"

  ; Clear Checksum, cFE Version, and OS Version Values for CPU3
  gsescstatval13 = ""
  gsescstatval23 = ""
  gsescstatval33 = ""

  {cksumItem} = ""
  {cfeMajorVerItem} = ""
  {cfeMinorVerItem} = ""
  {cfeSubMinorVerItem} = ""
  {osMajorVerItem} = ""
  {osMinorVerItem} = ""
;;  SCX_CPU3_ES_CKSUM = ""
;;  SCX_CPU3_ES_CFEMAJORVER = ""
;;  SCX_CPU3_ES_CFEMINORVER = ""
;;  SCX_CPU3_ES_OSMAJORVER = ""
;;  SCX_CPU3_ES_OSMINORVER = ""
endif

; Set up Commanding CPU label

  gsescstatlbl14 = "Cmd Ctrlr"

%liv (log_procedure) = logging

endproc
