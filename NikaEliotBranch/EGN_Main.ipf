#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.44

// version 1.44  fixed bug for adding Q axes in the image
// version 1.43  adds Pilatus loader. Unfinished, need to get test files to check 1M and 2M. 
// version 1.42 adds line profile support - including GISAXS geometry and ellipse.
//date: October 30, 2009 released as final 1.42 version. 
//This is main procedure file for NIKA 1 2-D SAS data conversion package


Menu "SAS 2D"
	"Main panel", EGNA_Convert2Dto1DMainPanel()
	help={"This should call the conversion routines for CCD data"}
	"Beam center and Geometry cor.", EGN_CreateBmCntrFile()
	help={"Tool to create beam center and geometry corrections."}
	"Create mask", NI1M_CreateMask()
	help={"Allows user to create mask based on selected measurement image"}
	"Create flood field", EGN_Create2DSensitivityFile()
	help={"Allows user to create pixel 2 d sensitivity file based on selected measured image"}
	"Image line profile", EGN_CreateImageLineProfileGraph()
	help={"Calls Image line profile (Wavemetrics provided) function"}
	"---"
	"Configure Nika GUI and Uncertainity",EGN_ConfigMain()
	help={"Configure method for uncertainity values for GUI Panels and Graph common items, such as font sizes and font types"}
	Submenu "Instrument configurations"
		"DND CAT", EGN_DNDConfigureNika()
		help={"Support for data from DND CAT (5ID) beamline at APS"}
	end
	"HouseKeeping", EGN_Cleanup2Dto1DFolder()
	help={"Removes large waves from this experiment, makes file much smaller. Resets junk... "}
	"Remove stored images", EGN_RemoveSavedImages()
	help={"Removes stored images - does not remove USED images, makes file much smaller. "}
	"---"
	"Open Nika pdf manual", EGN_OpenNikaManual()
	help={"Opens Nika pdf manual in Acrobat or other system associated pdf reader."}
	"Remove Nika 1 macros", EGN_RemoveEGNikaMac()
	help={"Removes the macros from the current experiment. Macros can be loaded when necessary again"}
	"About", EGN_AboutPanel()
	help={"Get Panel with info about this release of Nika macros"}
//	"---"
//	"Test Marquee", NI1B_Fitto2DGaussian1()
end


Menu "GraphMarquee"
        "Image Expand", EGN_MarExpandContractImage(1)
        "Image Contract", EGN_MarExpandContractImage(0)
End

//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
Function EGN_OpenNikaManual()
	//this function writes batch file and starts the manual.
	//we need to write following batch file: "C:\Program Files\WaveMetrics\Igor Pro Folder\User Procedures\Irena\Irena manual.pdf"
	//on Mac we just fire up the Finder with Mac type path... 
	
	//check where we run...
		string WhereIsManual
		string WhereAreProcedures=RemoveEnding(FunctionPath(""),"EGN_Main.ipf")
		String manualPath = ParseFilePath(5,"Nika manual.pdf","*",0,0)
       	String cmd 
	
	if (stringmatch(IgorInfo(3), "*Macintosh*"))
             //  manualPath = "User Procedures:Irena:Irena manual.pdf"
               sprintf cmd "tell application \"Finder\" to open \"%s\"",WhereAreProcedures+manualPath
               ExecuteScriptText cmd
      		if (strlen(S_value)>2)
//			DoAlert 0, S_value
		endif

	else 
		//manualPath = "User Procedures\Irena\Irena manual.pdf"
		//WhereIsIgor=WhereIsIgor[0,1]+"\\"+EG_N2G_ChangePartsOfString(WhereIsIgor[2,inf],":","\\")
		WhereAreProcedures=ParseFilePath(5,WhereAreProcedures,"*",0,0)
		whereIsManual = "\"" + WhereAreProcedures+manualPath+"\""
		NewNotebook/F=0 /N=NewBatchFile
		Notebook NewBatchFile, text=whereIsManual//+"\r"
		SaveNotebook/O NewBatchFile as SpecialDirPath("Temporary", 0, 1, 0 )+"StartManual.bat"
		DoWindow/K NewBatchFile
		ExecuteScriptText "\""+SpecialDirPath("Temporary", 0, 1, 0 )+"StartManual.bat\""
	endif
end
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************


//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************

Function EGN_RemoveEGNikaMac()
		Execute/P "DELETEINCLUDE \"EGN_Loader\""
		SVAR strChagne=root:Packages:EGNika2DSASItem1Str
		strChagne= "Load Nika 1 2D SAS Macros"
		BuildMenu "Macros"
		Execute/P "COMPILEPROCEDURES "
end

//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************

Function EGN_AboutPanel()
	DoWindow About_Nika_1_Macros
	if(V_Flag)
		DoWindow/K About_Nika_1_Macros
	endif

	PauseUpdate; Silent 1		// building window...
	NewPanel/K=1 /W=(173.25,101.75,490,370) as "About_Nika_1_Macros"
	DoWindow/C About_Nika_1_Macros
	SetDrawLayer UserBack
	SetDrawEnv fsize= 20,fstyle= 1,textrgb= (16384,28160,65280)
	DrawText 10,37,"Nika 1 macros Igor Pro (>=6.05)"
	SetDrawEnv fsize= 16,textrgb= (16384,28160,65280)
	DrawText 52,64,"@ Jan Ilavsky, 2009"
	DrawText 49,103,"Release 1.44 from 3/3/2010"
	DrawText 11,136,"To get help please contact: ilavsky@aps.anl.gov"
	DrawText 11,156,"http://usaxs.xor.aps.anl.gov/staff/ilavsky/index.html"

	DrawText 11,190,"Set of macros to convert 2D SAS images"
	DrawText 11,210,"into 1 D data"
	DrawText 11,230,"     "
	DrawText 11,250," "
	DrawText 11,265," Igor 6.10 compatible"
end

//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
Function EGN_RemoveSavedImages()
	
	string OldDf=GetDataFolder(1)
	setDataFolder root:
	NewDataFOlder/S/O SavedImages
	string AllWaves=EG_N2G_CreateListOfItemsInFolder("root:SavedImages", 2)
	variable i
	For(i=0;i<ItemsInList(AllWaves);i+=1)
		Killwaves/Z $(StringFromList(i,AllWaves))
	endfor
	setDataFolder root:
	if(strlen(EG_N2G_CreateListOfItemsInFolder("root:SavedImages", 2))<2)
		KillDataFolder root:SavedImages
	endif
	setDataFolder OldDf
end
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
//*****************************************************************************************************************
Function EGN_Cleanup2Dto1DFolder()

	string OldDf=getDataFolder(1)
	if(!DataFolderExists("root:Packages:Convert2Dto1D" ))
		abort
	endif
	setDataFolder root:Packages:Convert2Dto1D
	
	string ListOfWaves=EG_N2G_ConvertDataDirToList(DataFolderDir(2 ))
	string CurStr
	variable i, imax=ItemsInList(ListOfWaves)
	String ListOfWavesToKill
	ListOfWavesToKill="Rdistribution1D;Radius2DWave;AnglesWave;Qvector_;LUT;HistogramWv;Dspacing;Qvectorwidth;TwoTheta;Q2DWave;RadiusPix2DWave;"
	variable j

	For(i=0;i<imax;i+=1)
		CurStr = stringFromList(i,ListOFWaves)
		For(j=0;j<ItemsInList(ListOfWavesToKill);j+=1)
			if(stringmatch(CurStr, "*"+stringFromList(j,ListOfWavesToKill)+"*"))
				Wave killme=$(CurStr)
				KillWaves/Z killme
			endif
		endfor
	endfor
	KillWaves/Z CCImageToConvert_dis, DarkFieldData_dis,EmptyData_dis, MaskCCDImage, Calibrated2DDataSet, Pixel2DSensitivity_dis
	KillWaves/Z FloodFieldImg, MaxNumPntsLookupWv, MaxNumPntsLookupWvLBL, PixRadius2DWave, fit_BmCntrCCDImg,fit_BmCntrCCDImgX,fit_BmCntrCCDImgY
	KillWaves/Z BmCntrCCDImg,BmCntrDisplayImage, BmCntrDisplayImage, BmCntrCCDImg, xwave, xwaveT, ywave, ywaveT
	
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGN_MarExpandContractImage(isExpand)
        Variable isExpand
        
        String imName= StringFromList(0,ImageNameList("",";"))
        String imInfo= ImageInfo("",imName,0)
        if( strlen(imInfo) == 0 )
                return 0        // no image
        endif
        
        String xa= StringByKey("XAXIS",imInfo)
        String ya= StringByKey("YAXIS",imInfo)
        
        GetMarquee/K $xa,$ya
        Variable x0= V_left, x1= V_right, y0= V_top, y1= V_bottom
        
        GetAxis/Q $xa
        Variable xmin= V_min, xmax= V_max
        GetAxis/Q $ya
        Variable ymin= V_min, ymax= V_max
        
        Variable fract= (x1-x0)/ (xmax-xmin)            // take x expand or contract as the single factor
        
        Variable yc= (y0+y1)/2, xc= (x0+x1)/2
        
        
        if( isExpand )
                x0= xc - fract*(xmax-xmin)/2
                x1= xc + fract*(xmax-xmin)/2
                y0= yc - fract*(ymax-ymin)/2
                y1= yc + fract*(ymax-ymin)/2
        else
                x0= xc -(xmax-xmin)/(2*fract)
                x1= xc +(xmax-xmin)/(2*fract)
                y0= yc -(ymax-ymin)/(2*fract)
                y1= yc +(ymax-ymin)/(2*fract)
                        
        endif
        
        if( xmin > xmax )
                SetAxis/R $xa,x0,x1
        else
                SetAxis $xa,x0,x1
        endif
        if(ymin > ymax )
                SetAxis/R $ya,y0,y1
        else
                SetAxis $ya,y0,y1
        endif
end
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************

//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************

Function EGN_ConfigMain()		//call configuration routine

	//this is main configuration utility... 
	EGN_InitConfigMain()
	DoWindow EGN_MainConfigPanel
	if(!V_Flag)
		Execute ("EGN_MainConfigPanel()")
	else
		DoWindow/F EGN_MainConfigPanel
	endif

end

//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
structure NikaPanelDefaults
	uint32 version					// Preferences structure version number. 100 means 1.00.
//	uchar LegendFontType[50]		//50 characters for legend font name
	uchar PanelFontType[50]		//50 characters for panel font name
	uint32 defaultFontSize			//font size as integer
//	uint32 LegendSize				//font size as integer
//	uint32 TagSize					//font size as integer
//	uint32 AxisLabelSize			//font size as integer
//	int16 LegendUseFolderName		//font size as integer
//	int16 LegendUseWaveName		//font size as integer
	uint32 reserved[100]			// Reserved for future use
	
endstructure

//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************

Function EGN_ReadIrenaGUIPackagePrefs()

	struct  NikaPanelDefaults Defs
	EGN_InitConfigMain()
	SVAR DefaultFontType=root:Packages:NikaConfigFolder:DefaultFontType
	NVAR DefaultFontSize=root:Packages:NikaConfigFolder:DefaultFontSize
//	NVAR LegendSize=root:Packages:IrenaConfigFolder:LegendSize
//	NVAR TagSize=root:Packages:IrenaConfigFolder:TagSize
//	NVAR AxisLabelSize=root:Packages:IrenaConfigFolder:AxisLabelSize
//	NVAR LegendUseFolderName=root:Packages:IrenaConfigFolder:LegendUseFolderName
//	NVAR LegendUseWaveName=root:Packages:IrenaConfigFolder:LegendUseWaveName
//	SVAR FontType=root:Packages:IrenaConfigFolder:FontType
	LoadPackagePreferences /MIS=1   "Nika" , "NikaDefaultPanelControls.bin", 0 , Defs
	if(V_Flag==0)		
		//print Defs
		print "Read Nika Panels preferences from local machine and applied them. "
		print "Note that this may have changed font size and type selection originally saved with the existing experiment."
		print "To change them please use \"Configure default fonts and names\""
		if(Defs.Version==1)		//Lets declare the one we know as 1
			DefaultFontType=Defs.PanelFontType
			DefaultFontSize = Defs.defaultFontSize
			if (stringMatch(IgorInfo(3),"*Windows*"))		//Windows
				DefaultGUIFont /Win   all= {DefaultFontType, DefaultFontSize, 0 }
			else
				DefaultGUIFont /Mac   all= {DefaultFontType, DefaultFontSize, 0 }
			endif
			//and now recover the stored other parameters, no action on these...
//			 LegendSize=Defs.LegendSize
//			 TagSize=Defs.TagSize
//			 AxisLabelSize=Defs.AxisLabelSize
//			 LegendUseFolderName=Defs.LegendUseFolderName
//			 LegendUseWaveName=Defs.LegendUseWaveName
//			 FontType=Defs.LegendFontType
		else
			DoAlert 1, "Old version of GUI and Graph Fonts (font size and type preference) found. Do you want to update them now? These are set once on a computer and can be changed in \"Configure default fonts and names\"" 
			if(V_Flag==1)
				Execute("EGN_MainConfigPanel() ")
			else
			//	SavePackagePreferences /Kill   "Irena" , "IrenaDefaultPanelControls.bin", 0 , Defs	//does not work below 6.10
			endif
		endif
	else 		//problem loading package defaults
		DoAlert 1, "GUI and Graph defaults (font size and type preferences) are not set. Do you want to set them now? These are set once on a computer and can be changed in \"Configure default fonts and names\" dialog" 
		if(V_Flag==1)
			Execute("EGN_MainConfigPanel() ")
		endif	
	endif
end
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
Function EGN_SaveIrenaGUIPackagePrefs(KillThem)
	variable KillThem
	
	struct  NikaPanelDefaults Defs
	EGN_InitConfigMain()
	SVAR DefaultFontType=root:Packages:NikaConfigFolder:DefaultFontType
	NVAR DefaultFontSize=root:Packages:NikaConfigFolder:DefaultFontSize
//	NVAR LegendSize=root:Packages:IrenaConfigFolder:LegendSize
//	NVAR TagSize=root:Packages:IrenaConfigFolder:TagSize
//	NVAR AxisLabelSize=root:Packages:IrenaConfigFolder:AxisLabelSize
//	NVAR LegendUseFolderName=root:Packages:IrenaConfigFolder:LegendUseFolderName
//	NVAR LegendUseWaveName=root:Packages:IrenaConfigFolder:LegendUseWaveName
//	SVAR FontType=root:Packages:IrenaConfigFolder:FontType

	Defs.Version			=		1
	Defs.PanelFontType	 	= 		DefaultFontType
	Defs.defaultFontSize 	= 		DefaultFontSize 
//	Defs.LegendSize 			= 		LegendSize
//	Defs.TagSize 			= 		TagSize
//	Defs.AxisLabelSize 		= 		AxisLabelSize
//	Defs.LegendUseFolderName = 	LegendUseFolderName
//	Defs.LegendUseWaveName = 		LegendUseWaveName
//	Defs.LegendFontType	= 		FontType
	
	if(KillThem)
	//	SavePackagePreferences /Kill   "Irena" , "IrenaDefaultPanelControls.bin", 0 , Defs		//does nto work below 6.10
	//	IR2C_ReadIrenaGUIPackagePrefs()
	else
		SavePackagePreferences /FLSH=1   "Nika" , "NikaDefaultPanelControls.bin", 0 , Defs
	endif
end
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************

Function EGN_InitConfigMain()

	//initialize lookup parameters for user selected items.
	string OldDf=getDataFolder(1)
	SetDataFolder root:
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:NikaConfigFolder
	
	string ListOfVariables
	string ListOfStrings
	//here define the lists of variables and strings needed, separate names by ;...
	ListOfVariables="DefaultFontSize;"
	ListOfStrings="ListOfKnownFontTypes;DefaultFontType;"
	variable i
	//and here we create them
	for(i=0;i<itemsInList(ListOfVariables);i+=1)	
		EG_N2G_CreateItem("variable",StringFromList(i,ListOfVariables))
	endfor		
										
	for(i=0;i<itemsInList(ListOfStrings);i+=1)	
		EG_N2G_CreateItem("string",StringFromList(i,ListOfStrings))
	endfor	
	//Now set default values
//	String VariablesDefaultValues
//	String StringsDefaultValues
//	if (stringMatch(IgorInfo(3),"*Windows*"))		//Windows
//		VariablesDefaultValues="LegendSize:8;TagSize:8;AxisLabelSize:8;LegendUseFolderName:0;LegendUseWaveName:0;"
//	else
//		VariablesDefaultValues="LegendSize:10;TagSize:10;AxisLabelSize:10;LegendUseFolderName:0;LegendUseWaveName:0;"
//	endif
//	StringsDefaultValues="FontType:"+StringFromList(0, IR2C_CreateUsefulFontList() ) +";"
//
//	variable CurVarVal
//	string CurVar, CurStr, CurStrVal
//	For(i=0;i<ItemsInList(VariablesDefaultValues);i+=1)
//		CurVar = StringFromList(0,StringFromList(i, VariablesDefaultValues),":")
//		CurVarVal = numberByKey(CurVar, VariablesDefaultValues)
//		NVAR temp=$(CurVar)
//		if(temp==0)
//			temp = CurVarVal
//		endif
//	endfor
//	For(i=0;i<ItemsInList(StringsDefaultValues);i+=1)
//		CurStr = StringFromList(0,StringFromList(i, StringsDefaultValues),":")
//		CurStrVal = stringByKey(CurStr, StringsDefaultValues)
//		SVAR tempS=$(CurStr)
//		if(strlen(tempS)<1)
//			tempS = CurStrVal
//		endif
//	endfor
	
	SVAR ListOfKnownFontTypes=ListOfKnownFontTypes
	ListOfKnownFontTypes=EGN_CreateUsefulFontList()
	setDataFolder OldDf
end

//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
Function EGN_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
//	if (cmpstr(ctrlName,"LegendSize")==0)
//		NVAR LegendSize=root:Packages:IrenaConfigFolder:LegendSize
//		LegendSize = str2num(popStr)
//	endif
//	if (cmpstr(ctrlName,"TagSize")==0)
//		NVAR TagSize=root:Packages:IrenaConfigFolder:TagSize
//		TagSize = str2num(popStr)
//	endif
//	if (cmpstr(ctrlName,"AxisLabelSize")==0)
//		NVAR AxisLabelSize=root:Packages:IrenaConfigFolder:AxisLabelSize
//		AxisLabelSize = str2num(popStr)
//	endif
//	if (cmpstr(ctrlName,"FontType")==0)
//		SVAR FontType=root:Packages:IrenaConfigFolder:FontType
//		FontType = popStr
//	endif
	if (cmpstr(ctrlName,"DefaultFontType")==0)
		SVAR DefaultFontType=root:Packages:NikaConfigFolder:DefaultFontType
		DefaultFontType = popStr
		EGN_ChangePanelCOntrolsStyle()
	endif
	if (cmpstr(ctrlName,"DefaultFontSize")==0)
		NVAR DefaultFontSize=root:Packages:NikaConfigFolder:DefaultFontSize
		DefaultFontSize = str2num(popStr)
		EGN_ChangePanelCOntrolsStyle()
	endif
	EGN_SaveIrenaGUIPackagePrefs(0)
End
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
Function EGN_KillPrefsButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if(stringmatch(ba.ctrlName,"OKBUtton"))
				DoWIndow/K EGN_MainConfigPanel
			elseif(stringmatch(ba.ctrlName,"DefaultValues"))
				string defFnt
				variable defFntSize
				if (stringMatch(IgorInfo(3),"*Windows*"))		//Windows
					defFnt="Tahoma"
					defFntSize=12
				else
					defFnt="Geneva"
					defFntSize=9
				endif
				SVAR ListOfKnownFontTypes=root:Packages:NikaConfigFolder:ListOfKnownFontTypes
				SVAR DefaultFontType=root:Packages:NikaConfigFolder:DefaultFontType
				DefaultFontType = defFnt
				NVAR DefaultFontSize=root:Packages:NikaConfigFolder:DefaultFontSize
				DefaultFontSize = defFntSize
				EGN_ChangePanelCOntrolsStyle()
				EGN_SaveIrenaGUIPackagePrefs(0)
				PopupMenu DefaultFontType,win=EGN_MainConfigPanel, mode=(1+WhichListItem(defFnt, ListOfKnownFontTypes))
				PopupMenu DefaultFontSize,win=EGN_MainConfigPanel, mode=(1+WhichListItem(num2str(defFntSize), "8;9;10;11;12;14;16;18;20;24;26;30;"))
			endif
			break
	endswitch
	return 0
End

//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************

Function EGN_ChangePanelControlsStyle()

	SVAR DefaultFontType=root:Packages:NikaConfigFolder:DefaultFontType
	NVAR DefaultFontSize=root:Packages:NikaConfigFolder:DefaultFontSize

	if (stringMatch(IgorInfo(3),"*Windows*"))		//Windows
		DefaultGUIFont /Win   all= {DefaultFontType, DefaultFontSize, 0 }
	else
		DefaultGUIFont /Mac   all= {DefaultFontType, DefaultFontSize, 0 }
	endif

end
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************

Proc EGN_MainConfigPanel() 
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(282,48,707,270) as "Configure Nika controls & Errors"
	DoWindow /C EGN_MainConfigPanel
	SetDrawLayer UserBack
	SetDrawEnv fsize= 14,fstyle= 1,textrgb= (0,0,52224)
	DrawText 10,25,"Nika panels default fonts and names"
	SetDrawEnv fsize= 14,fstyle= 3, textrgb= (63500,4369,4369)
	DrawText 30,53,"Panel and controls font type & size (preference)"
//	SetDrawEnv fsize= 14,fstyle= 3,textrgb= (63500,4369,4369)
//	DrawText 30,150,"Graph text elements"
//	SVAR ListOfKnownFontTypes=root:Packages:IrenaConfigFolder:ListOfKnownFontTypes

	PopupMenu DefaultFontType,pos={35,65},size={113,21},proc=EGN_PopMenuProc,title="Panel Controls Font"
	PopupMenu DefaultFontType,mode=(1+WhichListItem(root:Packages:NikaConfigFolder:DefaultFontType, root:Packages:NikaConfigFolder:ListOfKnownFontTypes))
	PopupMenu DefaultFontType, popvalue=root:Packages:NikaConfigFolder:DefaultFontType,value= #"EGN_CreateUsefulFontList()"
	PopupMenu DefaultFontSize,pos={35,100},size={113,21},proc=EGN_PopMenuProc,title="Panel Controls Font Size"
	PopupMenu DefaultFontSize,mode=(1+WhichListItem(num2str(root:Packages:NikaConfigFolder:DefaultFontSize), "8;9;10;11;12;14;16;18;20;24;26;30;"))
	PopupMenu DefaultFontSize popvalue=num2str(root:Packages:NikaConfigFolder:DefaultFontSize),value= #"\"8;9;10;11;12;14;16;18;20;24;26;30;\""
	Button DefaultValues title="Default",pos={290,60},size={120,20}
	Button DefaultValues proc=EGN_KillPrefsButtonProc

//	PopupMenu LegendSize,pos={35,165},size={113,21},proc=IR2C_PopMenuProc,title="Legend Size"
//	PopupMenu LegendSize,mode=(1+WhichListItem(num2str(root:Packages:IrenaConfigFolder:LegendSize), "8;9;10;11;12;14;16;18;20;24;26;30;"))
//	PopupMenu LegendSize, popvalue=num2str(root:Packages:IrenaConfigFolder:LegendSize),value= #"\"8;9;10;11;12;14;16;18;20;24;26;30;\""
////LegendUseFolderName:1;LegendUseWaveName
//	CheckBox LegendUseFolderName,pos={195,165},size={25,16},noproc,title="Legend use Folder Names?"
//	CheckBox LegendUseFolderName,variable= root:Packages:IrenaConfigFolder:LegendUseFolderName, help={"Check to use folder names in legends?"}
//	CheckBox LegendUseWaveName,pos={195,205},size={25,16},noproc,title="Legend use Wave Names?"
//	CheckBox LegendUseWaveName,variable= root:Packages:IrenaConfigFolder:LegendUseWaveName, help={"Check to use wave names in legends?"}
//	PopupMenu TagSize,pos={49,195},size={96,21},proc=IR2C_PopMenuProc,title="Tag Size"
//	PopupMenu TagSize,mode=(1+WhichListItem(num2str(root:Packages:IrenaConfigFolder:TagSize), "8;9;10;11;12;14;16;18;20;24;26;30;"))
//	PopupMenu TagSize,popvalue=num2str(root:Packages:IrenaConfigFolder:TagSize),value= #"\"8;9;10;11;12;14;16;18;20;24;26;30;\""
//	PopupMenu AxisLabelSize,pos={46,225},size={103,21},proc=IR2C_PopMenuProc,title="Label Size"
//	PopupMenu AxisLabelSize,mode=(1+WhichListItem(num2str(root:Packages:IrenaConfigFolder:AxisLabelSize), "8;9;10;11;12;14;16;18;20;24;26;30;"))
//	PopupMenu AxisLabelSize,popvalue=num2str(root:Packages:IrenaConfigFolder:AxisLabelSize),value= #"\"8;9;10;11;12;14;16;18;20;24;26;30;\""
//	PopupMenu FontType,pos={48,255},size={114,21},proc=IR2C_PopMenuProc,title="Font type"
//	PopupMenu FontType,mode=(1+WhichListItem(root:Packages:IrenaConfigFolder:FontType, root:Packages:IrenaConfigFolder:ListOfKnownFontTypes))
//	PopupMenu FontType,popvalue=root:Packages:IrenaConfigFolder:FontType,value= #"root:Packages:IrenaConfigFolder:ListOfKnownFontTypes"
	Button OKButton title="OK",pos={290,100},size={120,20}
	Button OKButton proc=EGN_KillPrefsButtonProc

	CheckBox ErrorCalculationsUseOld,pos={10,140},size={80,16},proc=EGN_ConfigErrorsCheckProc,title="Use Old Uncertainity ?", mode=1
	CheckBox ErrorCalculationsUseOld,variable= root:Packages:Convert2Dto1D:ErrorCalculationsUseOld, help={"Check to use Error estimates for before version 1.42?"}
	CheckBox ErrorCalculationsUseStdDev,pos={10,160},size={80,16},proc=EGN_ConfigErrorsCheckProc,title="Use Std Devfor Uncertainity?", mode=1
	CheckBox ErrorCalculationsUseStdDev,variable= root:Packages:Convert2Dto1D:ErrorCalculationsUseStdDev, help={"Check to use Standard deviation for Error estimates "}
	CheckBox ErrorCalculationsUseSEM,pos={10,180},size={80,16},proc=EGN_ConfigErrorsCheckProc,title="Use SEM for Uncertainity?", mode=1
	CheckBox ErrorCalculationsUseSEM,variable= root:Packages:Convert2Dto1D:ErrorCalculationsUseSEM, help={"Check to use Standard error of mean for Error estimates"}


EndMacro
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
Function EGN_ConfigErrorsCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	NVAR ErrorCalculationsUseOld=root:Packages:Convert2Dto1D:ErrorCalculationsUseOld
	NVAR ErrorCalculationsUseStdDev=root:Packages:Convert2Dto1D:ErrorCalculationsUseStdDev
	NVAR ErrorCalculationsUseSEM=root:Packages:Convert2Dto1D:ErrorCalculationsUseSEM

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(stringmatch(cba.ctrlName,"ErrorCalculationsUseOld"))
				ErrorCalculationsUseOld = checked
				ErrorCalculationsUseStdDev=!checked
				ErrorCalculationsUseSEM=!checked
			endif
			if(stringmatch(cba.ctrlName,"ErrorCalculationsUseStdDev"))
				ErrorCalculationsUseOld = !checked
				ErrorCalculationsUseStdDev=checked
				ErrorCalculationsUseSEM=!checked
			endif
			if(stringmatch(cba.ctrlName,"ErrorCalculationsUseSEM"))
				ErrorCalculationsUseOld = !checked
				ErrorCalculationsUseStdDev=!checked
				ErrorCalculationsUseSEM=checked
			endif
			break
	endswitch

	return 0
End
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************

Function/S EGN_CreateUsefulFontList()

	string SystemFontList=FontList(";")
	string PreferredFontList="Times;Arial;Geneva;Palatino;Times New Roman;TImes Roman;Book Antiqua;"
	PreferredFontList+="Courier;Lucida;Vardana;Monaco;Courier CE;Courier;"
	
	variable i
	string UsefulList="", tempList=""
	For(i=0;i<ItemsInList(PreferredFontList);i+=1)
		tempList=stringFromList(i,PreferredFontList)
		if(stringmatch(SystemFOntList, "*"+tempList+";*" ))
			UsefulList+=tempList+";"
		endif
	endfor
	return UsefulList
end

//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
//***********************************************************
