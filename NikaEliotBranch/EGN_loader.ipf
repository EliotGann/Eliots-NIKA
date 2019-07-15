#pragma rtGlobals=1		// Use modern global access method.

//This macro loads the Nika 1 set of Igor Pro macros for evaluation of 2D images in small angle scattering

#include "EGN_BeamCenterUtils",version>=2.00
#include "EGN_ConvProc", version>=2.05
#include "EGN_FileLoaders",version>=2.035
#include "EGN_LineProfile", version>=2.00
#include "EGN_main", version>=1.44
#include "EGN_MainPanel", version>=2.14
#include "EGN_mar345", version>=1.0
#include "EGN_mask", version>=1.1
#include "EGN_pix2Dsensitivity",version>=1
#include "EGN_SaveRecallConfig", version>=1.0
#include "EGN_SquareMatrix", version>=1.0
#include "EGN_WinView",version>=1
#include "EGN_DNDCATsupport",version>=1.1
#include "EGN_LineProfCalcs",version>=2.01
#include "EGN_ADE-ALS11012",version>=1.1



#include "IN2_GeneralProcedures", version>=1.41


//1.43, updated FIle loaders to 2.01
//1.44  fixes to adding Q scale to images
