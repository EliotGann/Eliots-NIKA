#pragma rtGlobals=1		// Use modern global access method.



Function EGN_Create2DSensitivityFile()
	
	EGNA_Initialize2Dto1DConversion()
	EGNA_InitializeCreate2DSensFile()
	EGN_CreateFloodField()

end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGN_CreateFloodField()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	DoWindow EGN_CreateFloodFieldPanel
	if( V_Flag==1 )
		DoWindow/K EGN_CreateFloodFieldPanel
	endif
//FloodFileName
	SVAR FloodFileType=root:Packages:Convert2Dto1D:FloodFileType
	SVAR ColorTableName=root:Packages:Convert2Dto1D:ColorTableName
	NVAR ImageRangeMaxLimit=root:Packages:Convert2Dto1D:ImageRangeMaxLimit
	NVAR ImageRangeMinLimit=root:Packages:Convert2Dto1D:ImageRangeMinLimit
	NVAR AddFlat=root:Packages:Convert2Dto1D:AddFlat
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(22,58,450,560) as "Create FLOOD panel"
	Dowindow/C EGN_CreateFloodFieldPanel
	SetDrawLayer UserBack
	SetDrawEnv fsize= 19,fstyle= 1,textrgb= (0,0,65280)
	DrawText 30,30,"Prepare pix 2D sensitivity (flood) file"
	DrawText 18,92,"Select data set to use:"
	DrawText 10,432,"Processing: pix2D = 2DImage / MaximumValue"
	DrawText 10,449,"or: pix2D = (2DImage + offset) / (MaximumValue + offset)"

	Button SelectPathToData,pos={27,44},size={150,20},proc=EGN_FloodButtonProc,title="Select path to data"
	Button SelectPathToData,help={"Sets path to data where flood image is"}
	PopupMenu FloodFileType,pos={207,44},size={101,21},proc=EGNM_FloodPopMenuProc,title="File type:"
	PopupMenu FloodFileType,help={"Select image type of data to be used"}
	PopupMenu FloodFileType,mode=1,popvalue=FloodFileType,value= #"root:Packages:Convert2Dto1D:ListOfKnownExtensions"

	ListBox CCDDataSelection,pos={17,95},size={300,150}//,proc=EGNM_ListBoxProc
	ListBox CCDDataSelection,help={"Select CCD file for which you want to create mask"}
	ListBox CCDDataSelection,listWave=root:Packages:Convert2Dto1D:ListOfCCDDataInFloodPath
	ListBox CCDDataSelection,row= 0,mode= 1,selRow= 0

	Button CreateROIWorkImage,pos={187,260},size={200,20},proc=EGN_FloodButtonProc,title="Make Image"
//AddFlat;FlatValToAdd;MaximumValueFlood
	CheckBox AddFlat title="Add value to each pixel?",pos={20,260}
	CheckBox AddFlat proc=EGNM_FloodCheckProc,variable=AddFlat
	CheckBox AddFlat help={"Add flat offset to all points?"}

	SetVariable FlatValToAdd,pos={22,300},size={300,16},title="Offset to add to each point:            ", disable=!AddFlat
	SetVariable FlatValToAdd,help={"Add 1 to each point (to avoid problems with point with intensity=0)"}
	SetVariable FlatValToAdd,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:FlatValToAdd

	SetVariable MaximumValueFlood,pos={22,330},size={300,16},title="Maximum value found in image      "
	SetVariable MaximumValueFlood,help={"This is maximum value found in your image. Change if needed."}
	SetVariable MaximumValueFlood,limits={-Inf,Inf,0},value= root:Packages:Convert2Dto1D:MaximumValueFlood
	SetVariable MinimumValueFlood,pos={22,360},size={300,16},title="Minimum value found in image      "
	SetVariable MinimumValueFlood,help={"This is minimum value found in your image"}, noedit=1
	SetVariable MinimumValueFlood,limits={-Inf,Inf,0},value= root:Packages:Convert2Dto1D:MinimumValueFlood

	SetVariable ExportFloodFileName,pos={22,390},size={355,16},title="Save as (\"_flood\" will be added) :  "
	SetVariable ExportFloodFileName,help={"Name for the new flood file. Will be tiff file in the same place where the source data came from."}
	SetVariable ExportFloodFileName,limits={-Inf,Inf,0},value= root:Packages:Convert2Dto1D:ExportFloodFileName

	Button saveFloodField,pos={150,460},size={220,20},proc=EGNM_saveFloodCopyProc,title="Save 2D pix sens file (flood)"
	Button saveFloodField,help={"Saves current ROI as file outside Igor and also sets it as current mask"}
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNM_saveFloodCopyProc(ctrlName) : ButtonControl
	String ctrlName
	
	string OldDf=GetDataFolder(1)
	setDataFOlder root:Packages:Convert2Dto1D
	WAVE/Z FloodFieldImg=root:Packages:Convert2Dto1D:FloodFieldImg
	if(WaveExists(FloodFieldImg)==0)
		Abort "Something is wrong here"
	endif
	SVAR  ExportFloodFileName=root:Packages:Convert2Dto1D:ExportFloodFileName
	if (strlen(ExportFloodFileName)==0)
		abort "No name specified"
	endif
	string tempExportFloodFileName
	tempExportFloodFileName = ExportFloodFileName+"_flood.tif"
	PathInfo Convert2Dto1DFloodPath
	if(V_Flag==0)
		abort "Flood path does not exiist, select path first"
	endif
	string ListOfFilesThere
	ListOfFilesThere=IndexedFile(Convert2Dto1DFloodPath,-1,".tif")
	if(stringMatch(ListOfFilesThere,"*"+tempExportFloodFileName+"*"))
		DoAlert 1, "Flood file with this name exists, overwrite?"
		if(V_Flag!=1)
			abort
		endif	
	endif
	
	NVAR AddFlat=root:Packages:Convert2Dto1D:AddFlat
	NVAR FlatValToAdd= root:Packages:Convert2Dto1D:FlatValToAdd
	NVAR MaximumValueFlood= root:Packages:Convert2Dto1D:MaximumValueFlood
	NVAR MinimumValueFlood= root:Packages:Convert2Dto1D:MinimumValueFlood
	variable temp
	Duplicate/O FloodFieldImg, a2DPixSensTemp
	if(AddFlat)
		temp = MaximumValueFlood+FlatValToAdd
		a2DPixSensTemp = (FloodFieldImg + FlatValToAdd)/temp
	else
		a2DPixSensTemp = FloodFieldImg/MaximumValueFlood
	endif

	ImageSave/P=Convert2Dto1DFloodPath/F/T="TIFF"/O a2DPixSensTemp tempExportFloodFileName
	KillWaves a2DPixSensTemp
	
	EGN_UpdateFloodListBox()
	EGNA_UpdateMainMaskListBox()
	SetDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNM_FloodCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	if(cmpstr(ctrlName,"AddFlat")==0)
		NVAR AddFlat=root:Packages:Convert2Dto1D:AddFlat
		SetVariable FlatValToAdd,win=EGN_CreateFloodFieldPanel, disable=!AddFlat
	endif
	setDataFolder OldDf
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNM_FloodPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	if(cmpstr(ctrlName,"FloodFileType")==0)
		//set appropriate extension
		SVAR FloodFileType=root:Packages:Convert2Dto1D:FloodFileType
		FloodFileType = popStr
		if(cmpstr(popStr,"GeneralBinary")==0)
			EGN_GBLoaderPanelFnct()
		endif
		if(cmpstr(popStr,"Pilatus")==0)
			EGN_PilatusLoaderPanelFnct()
		endif
		EGN_UpdateFloodListBox()
	endif
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function EGN_UpdateFloodListBox()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

		Wave/T  ListOfCCDDataInFloodPath=root:Packages:Convert2Dto1D:ListOfCCDDataInFloodPath
		Wave SelectionsofCCDDataInFloodDPath=root:Packages:Convert2Dto1D:SelectionsofCCDDataInFloodDPath
		SVAR FloodFileType=root:Packages:Convert2Dto1D:FloodFileType
		string RealExtension				//for starnge extensions
		if(cmpstr(FloodFileType,".tif")==0)
			RealExtension=FloodFileType
		else
			RealExtension="????"
		endif
		string ListOfAvailableCompounds
		PathInfo Convert2Dto1DFloodPath
		if(V_Flag==0)
			abort
		endif

		ListOfAvailableCompounds=IndexedFile(Convert2Dto1DFloodPath,-1,RealExtension)
		redimension/N=(ItemsInList(ListOfAvailableCompounds)) ListOfCCDDataInFloodPath
		redimension/N=(ItemsInList(ListOfAvailableCompounds)) SelectionsofCCDDataInFloodDPath
		variable i
		ListOfCCDDataInFloodPath=EGNA_CleanListOfFilesForTypes(ListOfCCDDataInFloodPath,FloodFileType,"")
		For(i=0;i<ItemsInList(ListOfAvailableCompounds);i+=1)
			ListOfCCDDataInFloodPath[i]=StringFromList(i, ListOfAvailableCompounds)
		endfor
		sort ListOfCCDDataInFloodPath, ListOfCCDDataInFloodPath, SelectionsofCCDDataInFloodDPath		//, NumbersOfCompoundsOutsideIgor
		SelectionsofCCDDataInFloodDPath=0

		ListBox CCDDataSelection win=EGN_CreateFloodFieldPanel,listWave=root:Packages:Convert2Dto1D:ListOfCCDDataInFloodPath
		ListBox CCDDataSelection win=EGN_CreateFloodFieldPanel ,row= 0,mode= 1,selRow= 0
		DoUpdate
	setDataFolder OldDf
end	


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGN_FloodButtonProc(ctrlName) : ButtonControl
	String ctrlName

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	if( CmpStr(ctrlName,"CreateROIWorkImage") == 0 )
		//create image for working here...
		EGN_FloodCreateImage()
	endif
	if( CmpStr(ctrlName,"SelectPathToData") == 0 )
		NewPath/C/O/M="Select path to your data, FLOOD will be saved there too" Convert2Dto1DFloodPath
		EGN_UpdateFloodListBox()
	endif
	//following function happen only when graph exists...
//	DoWindow CCDImageForMask
//	if( V_Flag == 0 )
//		return 0
//	endif
//	if( CmpStr(ctrlName,"StartROI") == 0 )
//		ShowTools/W=CCDImageForMask/A rect
//		SetDrawLayer/W=CCDImageForMask ProgFront
//		Wave w= $EGNM_GetImageWave("CCDImageForMask")		// the target matrix
//		String iminfo= ImageInfo("CCDImageForMask", NameOfWave(w), 0)
//		String xax= StringByKey("XAXIS",iminfo)
//		String yax= StringByKey("YAXIS",iminfo)
//		SetDrawEnv/W=CCDImageForMask linefgc= (3,52428,1),fillpat= 5,fillfgc= (0,0,0),xcoord=$xax,ycoord=$yax,save
//	endif
	
	setDataFolder OldDf
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGN_FloodCreateImage()

	string OldDf=GetDataFOlder(1)
	setDataFOlder root:Packages:Convert2Dto1D
	Wave/T  ListOfCCDDataInFloodPath=root:Packages:Convert2Dto1D:ListOfCCDDataInFloodPath
	controlInfo /W=EGN_CreateFloodFieldPanel CCDDataSelection
	variable selection = V_Value
	if(selection<0)
		setDataFolder OldDf
		abort
	endif
	DoWindow CCDImageForFlood
	if(V_Flag)
		DoWindow/K CCDImageForFlood
	endif
	SVAR FileNameToLoad
	FileNameToLoad=ListOfCCDDataInFloodPath[selection]
	SVAR FloodFileType=root:Packages:Convert2Dto1D:FloodFileType
	EGNA_UniversalLoader("Convert2Dto1DFloodPath",FileNameToLoad,FloodFileType,"FloodFieldImg")
//	NVAR MaskDisplayLogImage=root:Packages:Convert2Dto1D:MaskDisplayLogImage
	wave FloodFieldImg
	//allow user function modification to the image through hook function...
		String infostr = FunctionInfo("ModifyImportedImageHook")
		if (strlen(infostr) >0)
			Execute("ModifyImportedImageHook(FloodFieldImg)")
		endif
	//end of allow user modification of imported image through hook function
	redimension/S FloodFieldImg
//	if(MaskDisplayLogImage)
//		MaskCCDImage=log(OriginalCCD)
//	else
//		MaskCCDImage=OriginalCCD
//	endif
	NVAR InvertImages=root:Packages:Convert2Dto1D:InvertImages
	if(InvertImages)
		NewImage/F/K=1 FloodFieldImg
		ModifyGraph height={Plan,1,left,bottom}
	else	
		NewImage/K=1 FloodFieldImg
		ModifyGraph height={Plan,1,left,top}
	endif
	DoWindow/C CCDImageForFlood
	AutoPositionWindow/E/M=0/R=EGN_CreateFloodFieldPanel CCDImageForFlood

	wavestats/Q FloodFieldImg
	
	NVAR MaximumValueFlood=root:Packages:Convert2Dto1D:MaximumValueFlood
	MaximumValueFlood=V_max
	NVAR MinimumValueFlood=root:Packages:Convert2Dto1D:MinimumValueFlood
	MinimumValueFlood=V_min
	NVAR AddFlat=root:Packages:Convert2Dto1D:AddFlat
	NVAR FlatValToAdd= root:Packages:Convert2Dto1D:FlatValToAdd
	if(MinimumValueFlood<=0)
		AddFlat=1
		FlatValToAdd=1
	else
		AddFlat=0
		FlatValToAdd=0	
	endif
	EGNM_FloodCheckProc("AddFlat",AddFlat)
	SVAR ExportFloodFileName=root:Packages:Convert2Dto1D:ExportFloodFileName
	ExportFloodFileName = FileNameToLoad

	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_InitializeCreate2DSensFile()

	string OldDf=GetDataFolder(1)
	NewDataFolder/O root:Packages
	NewDataFolder/O/S root:Packages:Convert2Dto1D

	string ListOfVariables
	string ListOfStrings
	
	//here define the lists of variables and strings needed, separate names by ;...
	
	ListOfVariables="AddFlat;FlatValToAdd;MaximumValueFlood;MinimumValueFlood;"

	ListOfStrings="FloodFileName;FloodFileType;ExportFloodFileName;"
	
	Wave/Z/T ListOfCCDDataInFloodPath
	if (!WaveExists(ListOfCCDDataInFloodPath))
		make/O/T/N=0 ListOfCCDDataInFloodPath
	endif
	Wave/Z SelectionsofCCDDataInFloodDPath
	if(!WaveExists(SelectionsofCCDDataInFloodDPath))
		make/O/N=0 SelectionsofCCDDataInFloodDPath
	endif

	variable i
	//and here we create them
	for(i=0;i<itemsInList(ListOfVariables);i+=1)	
		IN2G_CreateItem("variable",StringFromList(i,ListOfVariables))
	endfor		
										
	for(i=0;i<itemsInList(ListOfStrings);i+=1)	
		IN2G_CreateItem("string",StringFromList(i,ListOfStrings))
	endfor	

	SVAR FloodFileType=root:Packages:Convert2Dto1D:FloodFileType
	IF (STRLEN(FloodFileType)<1)
		FloodFileType=".tif"
	endif

end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
