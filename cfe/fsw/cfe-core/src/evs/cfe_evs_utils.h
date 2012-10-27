/*
**
**  Filename: cfe_evs_utils.h
**  $Id: cfe_evs_utils.h 1.3 2010/10/25 15:01:43EDT jmdagost Exp  $
**
**
**      Copyright (c) 2004-2012, United States government as represented by the 
**      administrator of the National Aeronautics Space Administration.  
**      All rights reserved. This software(cFE) was created at NASA's Goddard 
**      Space Flight Center pursuant to government contracts.
**
**      This is governed by the NASA Open Source Agreement and may be used, 
**      distributed and modified only pursuant to the terms of that agreement.
**  
**
**  Title:    Event Services Task and API - Utility functions.
**
**  Purpose:
**            Unit specification for the event services utility functions.
**
**  Contents:
**       I.  macro and constant type definitions
**      II.  EVS utility internal structures
**     III.  function prototypes
**
**  Design Notes:
**
**  References:
**     Flight Software Branch C Coding Standard Version 1.0a
**
**
**  $Date: 2010/10/25 15:01:43EDT $
**  $Revision: 1.3 $
**  $Log: cfe_evs_utils.h  $
**  Revision 1.3 2010/10/25 15:01:43EDT jmdagost 
**  Corrected bad apostrophe in prologue.
**  Revision 1.2 2010/10/04 15:27:13EDT jmdagost 
**  Cleaned up copyright symbol.
**  Revision 1.1 2008/04/17 08:05:14EDT ruperera 
**  Initial revision
**  Member added to project c:/MKSDATA/MKS-REPOSITORY/MKS-CFE-PROJECT/fsw/cfe-core/src/evs/project.pj
**  Revision 1.7 2007/03/14 11:55:17EDT njyanchik 
**  This is a check in of EVS's cleanup function for apps
**  Revision 1.6 2006/06/08 14:14:54EDT njyanchik 
**  I added the appropriate legal headers to all of the evs files
**  Revision 1.5 2005/10/06 13:37:22EDT slstrege 
**  Delta code review actions
**  Revision 1.4 2005/09/12 12:38:23EDT sstrege 
**  Fixed "FindEventID" utility function to accept a signed integer
**  Revision 1.3 2005/08/19 16:24:28EDT sstrege 
**  Removed variable length argument passing
**  Revision 1.2 2005/08/02 15:32:49CDT sstrege 
**  Added comments to structures and structure elements
**  Revision 1.1 2005/07/29 19:42:55EDT sstrege 
**  Initial revision
**  Member added to project d:/mksdata/MKS-CFE-REPOSITORY/cfe-core/evs/project.pj
**
*/

#ifndef _cfe_evs_utils_
#define _cfe_evs_utils_

/********************* Include Files  ************************/

#include "cfe_platform_cfg.h"    /* cFE platform configuration definitions */
#include "cfe_evs_task.h"        /* EVS internal definitions */

/* ==============   Section I: Macro and Constant Type Definitions   =========== */

/* ==============   Section II: Internal Structures ============ */     

/* ==============   Section III: Function Prototypes =========== */

int32 EVS_InitCpyApplicationData(uint32 AppID, void *Filters, uint16 NumEventFilters);

int32 EVS_SendEvent(uint32 AppID, CFE_TIME_SysTime_t Time, uint16 EventID, uint16 EventType, char *EventString );

int32 EVS_CheckApplication(uint32 AppID);

int32 EVS_GetApplicationInfo(uint32 *pAppID, char *pAppName);

int32 EVS_UnregisterInternal (const uint32 AppID);

CFE_EVS_EVSBinFilter_t * EVS_FindEventID (const int16 EventID, CFE_EVS_EVSBinFilter_t *FilterArray);

boolean EVS_IsFiltered (const uint32 AppID, const uint16 EventID, const uint16 EventType);

void EVS_EnableTypes(uint8 BitMask, uint32 AppID);

void EVS_DisableTypes(uint8 BitMask, uint32 AppID);     

int32 CFE_EVS_CleanUpApp (uint32 AppId);

#endif  /* _cfe_evs_utils_ */
