#pragma rtGlobals=1		// Use modern global access method.
#pragma version =1.1




Function NI1M_CreateMask()
	//this function helps user to create mask
	
	NI1A_Initialize2Dto1DConversion()
	
	NI1M_CreateImageROIPanel()

end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1M_CreateImageROIPanel()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	DoWindow NI1M_ImageROIPanel
	if( V_Flag==1 )
		DoWindow/K NI1M_ImageROIPanel
	endif

	SVAR CCDFileExtension=root:Packages:Convert2Dto1D:CCDFileExtension
	SVAR ColorTableName=root:Packages:Convert2Dto1D:ColorTableName
	NVAR ImageRangeMaxLimit=root:Packages:Convert2Dto1D:ImageRangeMaxLimit
	NVAR ImageRangeMinLimit=root:Packages:Convert2Dto1D:ImageRangeMinLimit
	NVAR MaskOffLowIntPoints=root:Packages:Convert2Dto1D:MaskOffLowIntPoints
	NVAR AddToOldMask=root:Packages:Convert2Dto1D:AddToOldMask
	NVAR LowIntToMaskOff=root:Packages:Convert2Dto1D:LowIntToMaskOff
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(22,58,450,560) as "Create MASK panel"
	Dowindow/C NI1M_ImageROIPanel
	SetDrawLayer UserBack
	SetDrawEnv fsize= 19,fstyle= 1,textrgb= (0,0,65280)
	DrawText 62,30,"Prepare mask file"
	DrawText 18,92,"Select data set to use:"

	Button SelectPathToData,pos={27,44},size={150,20},proc=NI1M_RoiDrawButtonProc,title="Select path to data"
	Button SelectPathToData,help={"Adds drawing tools to top image graph. Use rectangle, circle or polygon."}
	PopupMenu CCDFileExtension,pos={207,44},size={101,21},proc=NI1M_MaskPopMenuProc,title="File type:"
	PopupMenu CCDFileExtension,help={"Select image type of data to be used"}
	PopupMenu CCDFileExtension,mode=1,popvalue=CCDFileExtension,value= #"root:Packages:Convert2Dto1D:ListOfKnownExtensions"

	ListBox CCDDataSelection,pos={17,95},size={300,150}//,proc=NI1M_ListBoxProc
	ListBox CCDDataSelection,help={"Select CCD file for which you want to create mask"}
	ListBox CCDDataSelection,listWave=root:Packages:Convert2Dto1D:ListOfCCDDataInCCDPath
	ListBox CCDDataSelection,row= 0,mode= 1,selRow= 0

	Button CreateROIWorkImage,pos={187,260},size={200,20},proc=NI1M_RoiDrawButtonProc,title="Make Image"

	CheckBox MaskDisplayLogImage title="Display log image?",pos={20,260}
	CheckBox MaskDisplayLogImage proc=NI1M_MaskCheckProc,variable=MaskDisplayLogImage
	CheckBox MaskDisplayLogImage help={"Display data in the image as log intensity?"}

	Slider ImageRangeMin,pos={15,288},size={150,16},proc=NI1M_SliderProc
	Slider ImageRangeMin,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0},variable= root:Packages:Convert2Dto1D:ImageRangeMin,live= 0,side= 3,vert= 0,ticks= 0
	Slider ImageRangeMax,pos={15,308},size={150,16},proc=NI1M_SliderProc
	Slider ImageRangeMax,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0},variable= root:Packages:Convert2Dto1D:ImageRangeMax,live= 0,side= 3,vert= 0,ticks= 0
	PopupMenu ColorTablePopup,pos={30,330},size={107,21},proc=NI1M_MaskPopMenuProc,title="Colors"
	PopupMenu ColorTablePopup,mode=1,popvalue=ColorTableName,value= #"\"Grays;Rainbow;YellowHot;BlueHot;BlueRedGreen;RedWhiteBlue;PlanetEarth;Terrain;\""

	Button StartROI,pos={187,300},size={150,20},proc=NI1M_RoiDrawButtonProc,title="Start MASK Draw"
	Button StartROI,help={"Adds drawing tools to top image graph. Use rectangle, circle or polygon."}
	Button FinishROI,pos={187,330},size={150,20},proc=NI1M_RoiDrawButtonProc,title="Finish MASK"
	Button FinishROI,help={"Click after you are finished editing the ROI"}
	Button clearROI,pos={22,470},size={150,20},proc=NI1M_RoiDrawButtonProc,title="Erase MASK"
	Button clearROI,help={"Erases previous ROI. Not undoable."}
	Button saveROICopy,pos={200,470},size={150,20},proc=NI1M_saveRoiCopyProc,title="Save MASK"
	Button saveROICopy,help={"Saves current ROI as file outside Igor and also sets it as current mask"}
	SetVariable ExportMaskFileName,pos={5,445},size={355,16},title="Save as (\"_mask\" will be added) :"
	SetVariable ExportMaskFileName,help={"Name for the new mask file. Will be tiff file in the same place where the source data came from."}
	SetVariable ExportMaskFileName,limits={-Inf,Inf,0},value= root:Packages:Convert2Dto1D:ExportMaskFileName
	SetVariable RemoveFirstNColumns,pos={5,360},size={190,16},proc=NI1M_Mask_SetVarProc,title="Mask first columns :"
	SetVariable RemoveFirstNColumns,help={"Mask first N columns, remove mask manually"}
	SetVariable RemoveFirstNColumns,value= root:Packages:Convert2Dto1D:RemoveFirstNColumns
	SetVariable RemoveLastNColumns,pos={5,385},size={190,16},proc=NI1M_Mask_SetVarProc,title="Mask last columns :"
	SetVariable RemoveLastNColumns,help={"Mask last N columns, remove mask manually"}
	SetVariable RemoveLastNColumns,value= root:Packages:Convert2Dto1D:RemoveLastNColumns
	SetVariable RemoveFirstNRows,pos={206,360},size={190,16},proc=NI1M_Mask_SetVarProc,title="Mask first rows :"
	SetVariable RemoveFirstNRows,help={"Mask first N rows, remove mask manually"}
	SetVariable RemoveFirstNRows,value= root:Packages:Convert2Dto1D:RemoveFirstNRows
	SetVariable RemoveLastNRows,pos={206,385},size={190,16},proc=NI1M_Mask_SetVarProc,title="Mask last rows :"
	SetVariable RemoveLastNRows,help={"Mask last N rows, remove mask manually"}
	SetVariable RemoveLastNRows,value= root:Packages:Convert2Dto1D:RemoveLastNRows

	CheckBox MaskOffLowIntPoints title="Mask low Intensity points?",pos={10,410}
	CheckBox MaskOffLowIntPoints proc=NI1M_MaskCheckProc,variable=MaskOffLowIntPoints
	CheckBox MaskOffLowIntPoints help={"Mask of points with Intensity lower than selected threshold?"}
	CheckBox AddToOldMask title="Add to Old Mask?",pos={180,410}
	CheckBox AddToOldMask proc=NI1M_MaskCheckProc,variable=AddToOldMask
	CheckBox AddToOldMask help={"Add the mask you draw to the Loaded Mask?"}
	SetVariable LowIntToMaskOff,pos={206,410},size={190,16},proc=NI1M_Mask_SetVarProc,title="Threshold Intensity :"
	SetVariable LowIntToMaskOff,help={"Intensity <= this thereshold"}, disable=!(MaskOffLowIntPoints)
	SetVariable LowIntToMaskOff,value= root:Packages:Convert2Dto1D:LowIntToMaskOff
	
	

	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1M_MaskCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D


	if(cmpstr(ctrlName,"MaskDisplayLogImage")==0)
		DoWindow CCDImageForMask
		if(!V_Flag)
			abort
		else
			DoWindow/F CCDImageForMask	
		endif
		NVAR MaskDisplayLogImage=root:Packages:Convert2Dto1D:MaskDisplayLogImage
		wave OriginalCCD=root:Packages:Convert2Dto1D:OriginalCCD
		duplicate/O OriginalCCD, MaskCCDImage
		redimension/S MaskCCDImage
		if(MaskDisplayLogImage)
			MaskCCDImage=log(OriginalCCD)
		else
			MaskCCDImage=OriginalCCD
		endif
		AutoPositionWindow/E/M=0/R=NI1M_ImageROIPanel CCDImageForMask
		
		NVAR ImageRangeMin=root:Packages:Convert2Dto1D:ImageRangeMin
		NVAR ImageRangeMax=root:Packages:Convert2Dto1D:ImageRangeMax
		NVAR ImageRangeMinLimit=root:Packages:Convert2Dto1D:ImageRangeMinLimit
		NVAR ImageRangeMaxLimit=root:Packages:Convert2Dto1D:ImageRangeMaxLimit
	
		wavestats/Q MaskCCDImage
		ImageRangeMin = V_min
		ImageRangeMax = V_max
		ImageRangeMinLimit = V_min
		ImageRangeMaxLimit = V_max
	
		Slider ImageRangeMin,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0}, win=NI1M_ImageROIPanel
		Slider ImageRangeMax,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0}, win=NI1M_ImageROIPanel
		NI1M_MaskUpdateColors()
	
	endif

	if(cmpstr(ctrlName,"MaskOffLowIntPoints")==0)
		DoWindow CCDImageForMask
		if(!V_Flag)
			abort
		else
			DoWindow/F CCDImageForMask	
		endif
		SetVariable LowIntToMaskOff, win=NI1M_ImageROIPanel, disable=!(checked)
		NI1M_MaskUpdateColors()
	endif
	if(cmpstr(ctrlName,"AddToOldMask")==0)
		nvar addtooldmask=root:Packages:Convert2Dto1D:AddToOldMask
		if(AddToOldMask)
			AppendImage/t/W=CCDImageForMask M_ROIMask
			ModifyImage/W=CCDImageForMask M_ROIMask  ctab ={0.2,0.5, Grays}, minRGB=(12000,12000,12000),maxRGB=NaN
		else
			removeimage/Z/W=CCDImageForMask M_ROIMask
		endif
	endif

	setDataFolder OldDf
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1M_saveRoiCopyProc(ctrlName) : ButtonControl
	String ctrlName
	
	string OldDf=GetDataFolder(1)
	setDataFOlder root:Packages:Convert2Dto1D
	WAVE/Z ww=root:Packages:Convert2Dto1D:OriginalCCD
	if(WaveExists(ww)==0)
		Abort "Something is wrong here"
	endif
	nvar addtooldmask=root:Packages:Convert2Dto1D:AddToOldMask
	if(waveexists(M_roimask))
		duplicate/o M_roimask, oldmask
		ImageGenerateROIMask/E=1/I=0 MaskCCDImage
	else
		ImageGenerateROIMask/E=1/I=0 MaskCCDImage
		duplicate/o M_roimask, oldmask
		oldmask = 1
	endif
	Wave/z M_ROIMask,oldmask
	if(addtooldmask && waveexists(oldmask))
		MatrixOP/O M_ROIMask =M_ROIMask * oldmask
	endif
	//SVAR FileNameToLoad
	NVAR MaskOffLowIntPoints=root:Packages:Convert2Dto1D:MaskOffLowIntPoints
	NVAR LowIntToMaskOff=root:Packages:Convert2Dto1D:LowIntToMaskOff
	if(MaskOffLowIntPoints)
		wave MaskCCDImage
		MatrixOP/O M_ROIMask =M_ROIMask * greater(MaskCCDImage, LowIntToMaskOff)
	endif	
	SVAR  CurrentMaskFileName=root:Packages:Convert2Dto1D:CurrentMaskFileName
	SVAR ExportMaskFileName=root:Packages:Convert2Dto1D:ExportMaskFileName
	if (strlen(ExportMaskFileName)==0)
		abort "No name specified"
	endif
	CurrentMaskFileName = ExportMaskFileName+"_mask.tif"
	PathInfo Convert2Dto1DMaskPath
	if(V_Flag==0)
		abort "Mask path does nto exiist, select path first"
	endif
	string ListOfFilesThere
	ListOfFilesThere=IndexedFile(Convert2Dto1DMaskPath,-1,".tif")
	if(stringMatch(ListOfFilesThere,"*"+CurrentMaskFileName+"*"))
		DoAlert 1, "Mask file with this name exists, overwrite?"
		if(V_Flag!=1)
			abort
		endif	
	endif
	//SVAR CCDFileExtension=root:Packages:Convert2Dto1D:CCDFileExtension
	//if(cmpstr(CCDFileExtension,".tif")==0)
	ImageSave/P=Convert2Dto1DMaskPath/D=16/T="TIFF"/O M_ROIMask CurrentMaskFileName
	//else
	//	ABort "Cannot save anything else than tiff files yet"
	//endif
	
	NI1M_UpdateMaskListBox()
	NI1A_UpdateMainMaskListBox()
	SetDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function/S NI1M_GetImageWave(grfName)
	String grfName							// use zero len str to speicfy top graph

	String s= ImageNameList(grfName, ";")
	Variable p1= StrSearch(s,";",0)
	if( p1<0 )
		return ""			// no image in top graph
	endif
	s= s[0,p1-1]
	Wave w= ImageNameToWaveRef(grfName, s)
	return GetWavesDataFolder(w,2)		// full path to wave including name
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1M_MaskCreateImage()

	string OldDf=GetDataFOlder(1)
	setDataFOlder root:Packages:Convert2Dto1D
	Wave/T  ListOfCCDDataInCCDPath=root:Packages:Convert2Dto1D:ListOfCCDDataInCCDPath
	controlInfo /W=NI1M_ImageROIPanel CCDDataSelection
	variable selection = V_Value
	if(selection<0)
		setDataFolder OldDf
		abort
	endif
	DoWindow CCDImageForMask
	if(V_Flag)
		DoWindow/K CCDImageForMask
	endif
	SVAR FileNameToLoad
	FileNameToLoad=ListOfCCDDataInCCDPath[selection]
	SVAR CCDFileExtension=root:Packages:Convert2Dto1D:CCDFileExtension
//	if(cmpstr(CCDFileExtension,".tif")==0)
//		ImageLoad/P=Convert2Dto1DMaskPath/T=tiff/O/N=OriginalCCD FileNameToLoad+CCDFileExtension
//	else
//		Abort "Can load only tiff images at this time"
//	endif
	NI1A_UniversalLoader("Convert2Dto1DMaskPath",FileNameToLoad,CCDFileExtension,"OriginalCCD")
	NVAR MaskDisplayLogImage=root:Packages:Convert2Dto1D:MaskDisplayLogImage
	wave OriginalCCD
	//allow user function modification to the image through hook function...
		String infostr = FunctionInfo("ModifyImportedImageHook")
		if (strlen(infostr) >0)
			Execute("ModifyImportedImageHook(OriginalCCD)")
		endif
	//end of allow user modification of imported image through hook function
	duplicate/O OriginalCCD, MaskCCDImage
	redimension/S MaskCCDImage
	if(MaskDisplayLogImage)
		MaskCCDImage=log(OriginalCCD)
	else
		MaskCCDImage=OriginalCCD
	endif
	NVAR InvertImages=root:Packages:Convert2Dto1D:InvertImages
	if(InvertImages)
		NewImage/F/K=1 MaskCCDImage
		ModifyGraph height={Plan,1,left,bottom}
	else	
		NewImage/K=1 MaskCCDImage
		ModifyGraph height={Plan,1,left,top}
	endif
	DoWindow/C CCDImageForMask
	AutoPositionWindow/E/M=0/R=NI1M_ImageROIPanel CCDImageForMask
	SVAR ExportMaskFileName=root:Packages:Convert2Dto1D:ExportMaskFileName
	ExportMaskFileName = FileNameToLoad
	
	NVAR ImageRangeMin=root:Packages:Convert2Dto1D:ImageRangeMin
	NVAR ImageRangeMax=root:Packages:Convert2Dto1D:ImageRangeMax
	NVAR ImageRangeMinLimit=root:Packages:Convert2Dto1D:ImageRangeMinLimit
	NVAR ImageRangeMaxLimit=root:Packages:Convert2Dto1D:ImageRangeMaxLimit

	wavestats/Q MaskCCDImage
	ImageRangeMin = V_min
	ImageRangeMax = V_max
	ImageRangeMinLimit = V_min
	ImageRangeMaxLimit = V_max

	Slider ImageRangeMin,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0}, win=NI1M_ImageROIPanel
	Slider ImageRangeMax,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0}, win=NI1M_ImageROIPanel
	NI1M_MaskUpdateColors()
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function NI1M_UpdateMaskListBox()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

		Wave/T  ListOfCCDDataInCCDPath=root:Packages:Convert2Dto1D:ListOfCCDDataInCCDPath
		Wave SelectionsofCCDDataInCCDPath=root:Packages:Convert2Dto1D:SelectionsofCCDDataInCCDPath
		SVAR CCDFileExtension=root:Packages:Convert2Dto1D:CCDFileExtension
		SVAR EmptyDarkNameMatchStr=root:Packages:Convert2Dto1D:EmptyDarkNameMatchStr
		string RealExtension				//for starnge extensions
		if(cmpstr(CCDFileExtension,".tif")==0)
			RealExtension=CCDFileExtension
		elseif(cmpstr(CCDFileExtension,"ADSC")==0)
			RealExtension=".img"
		elseif(cmpstr(CCDFileExtension,".fits")==0)
			RealExtension=".fits"
		elseif(cmpstr(CCDFileExtension,"AUSW")==0)
			RealExtension=".tif"
		elseif (cmpstr(CCDFileExtension,"Pilatus")==0)
			SVAR PilatusFileType=root:Packages:Convert2Dto1D:PilatusFileType
			if(!cmpstr(PilatusFileType,"edf"))
				RealExtension=".edf"
			elseif(!cmpstr(PilatusFileType,"tiff")||!cmpstr(PilatusFileType,"float-tiff"))
				RealExtension=".tif"
			elseif(!cmpstr(PilatusFileType,"img"))
				RealExtension=".img"
			endif
		elseif(cmpstr(CCDFileExtension,"ibw")==0)
			RealExtension=".ibw"
		else
			RealExtension="????"
		endif
		string ListOfAvailableCompounds
		PathInfo Convert2Dto1DMaskPath
		if(V_Flag==0)
			abort
		endif

		ListOfAvailableCompounds=IndexedFile(Convert2Dto1DMaskPath,-1,RealExtension)
			if(strlen(ListOfAvailableCompounds)<2)	//none found
				ListOfAvailableCompounds="--none--;"
			endif
		redimension/N=(ItemsInList(ListOfAvailableCompounds)) ListOfCCDDataInCCDPath
		redimension/N=(ItemsInList(ListOfAvailableCompounds)) SelectionsofCCDDataInCCDPath
		variable i
		ListOfCCDDataInCCDPath=NI1A_CleanListOfFilesForTypes(ListOfCCDDataInCCDPath,CCDFileExtension, EmptyDarkNameMatchStr)
		For(i=0;i<ItemsInList(ListOfAvailableCompounds);i+=1)
			ListOfCCDDataInCCDPath[i]=StringFromList(i, ListOfAvailableCompounds)
		endfor
		sort ListOfCCDDataInCCDPath, ListOfCCDDataInCCDPath, SelectionsofCCDDataInCCDPath		//, NumbersOfCompoundsOutsideIgor
		SelectionsofCCDDataInCCDPath=0
		
		DoWIndow NI1M_ImageROIPanel
		if(V_Flag)
			ListBox CCDDataSelection win=NI1M_ImageROIPanel,listWave=root:Packages:Convert2Dto1D:ListOfCCDDataInCCDPath
			ListBox CCDDataSelection win=NI1M_ImageROIPanel,row= 0,mode= 1,selRow= 0
			DoUpdate
		endif
	setDataFolder OldDf
end	

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1M_MaskPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	if(cmpstr(ctrlName,"CCDFileExtension")==0)
		//set appropriate extension
		SVAR CCDFileExtension=root:Packages:Convert2Dto1D:CCDFileExtension
//		if (cmpstr(popStr,"tif")==0)
//			CCDFileExtension=".tif"
//		elseif (cmpstr(popStr,"Mar3450")==0)
//			CCDFileExtension=".Mar3450"
//		elseif (cmpstr(popStr,"BrukerCCD")==0)
//			CCDFileExtension="BrukerCCD"
//		elseif (cmpstr(popStr,"any")==0)
//			CCDFileExtension="????"
//		endif
		CCDFileExtension = popStr
		NI1M_UpdateMaskListBox()
		if(cmpstr(popStr,"GeneralBinary")==0)
			NI1_GBLoaderPanelFnct()
		endif
		if(cmpstr(popStr,"Pilatus")==0)
			NI1_PilatusLoaderPanelFnct()
		endif
	endif
	if(cmpstr(ctrlName,"ColorTablePopup")==0)
		SVAR ColorTableName=root:Packages:Convert2Dto1D:ColorTableName
		ColorTableName = popStr
		NI1M_MaskUpdateColors()
	endif
End

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1M_SliderProc(ctrlName,sliderValue,event) //: SliderControl
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved

	if(event %& 0x1)	// bit 0, value set

	endif
	if(cmpstr(ctrlName,"ImageRangeMin")==0)
		NI1M_MaskUpdateColors()
	endif
	if(cmpstr(ctrlName,"ImageRangeMax")==0)
		NI1M_MaskUpdateColors()
	endif
	return 0
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1M_MaskUpdateColors()
	DoWindow CCDImageForMask
	if(V_Flag)
		NVAR ImageRangeMin= root:Packages:Convert2Dto1D:ImageRangeMin
		NVAR ImageRangeMax = root:Packages:Convert2Dto1D:ImageRangeMax
		SVAR ColorTableName=root:Packages:Convert2Dto1D:ColorTableName
		ModifyImage/W=CCDImageForMask MaskCCDImage ctab= {ImageRangeMin,ImageRangeMax,$ColorTableName,0}

		//now deal with the masking of low values... 
		Wave MaskCCDImage=root:Packages:Convert2Dto1D:MaskCCDImage
		NVAR LowIntToMaskOff=root:Packages:Convert2Dto1D:LowIntToMaskOff
		NVAR MaskDisplayLogImage=root:Packages:Convert2Dto1D:MaskDisplayLogImage
		NVAR MaskOffLowIntPoints=root:Packages:Convert2Dto1D:MaskOffLowIntPoints
		
		CheckDisplayed /W=CCDImageForMask  UnderLevelImage
		if(V_Flag)
			removeimage/W=CCDImageForMask UnderLevelImage
		endif
		if(MaskOffLowIntPoints)
			MatrixOp/O UnderLevelImage= MaskCCDImage
			AppendImage/T/W=CCDImageForMask UnderLevelImage
			variable tempLimit=LowIntToMaskOff
			if(tempLimit<1)
				tempLimit=1
			endif
			if(MaskDisplayLogImage)
				tempLimit=log(tempLimit)
			endif
			ModifyImage/W=CCDImageForMask UnderLevelImage ctab= {tempLimit,tempLimit,Terrain,0}
			ModifyImage/W=CCDImageForMask UnderLevelImage minRGB=(65535,65535,65535),maxRGB=NaN
		else
			killWaves /Z  UnderLevelImage
		endif

	endif

end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1M_Mask_SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	wave OriginalCCD=root:Packages:Convert2Dto1D:OriginalCCD
	String iminfo
	String xax
	String yax
	
	if(cmpstr("RemoveFirstNColumns",ctrlName)==0)
		SetDrawLayer/W=CCDImageForMask ProgFront
		Wave w= $NI1M_GetImageWave("CCDImageForMask")		// the target matrix
		iminfo= ImageInfo("CCDImageForMask", NameOfWave(w), 0)
		xax= StringByKey("XAXIS",iminfo)
		yax= StringByKey("YAXIS",iminfo)
		SetDrawEnv/W=CCDImageForMask linefgc= (3,52428,1),fillpat= 5,fillfgc= (0,0,0),xcoord=$xax,ycoord=$yax,save
		DrawRect /W=CCDImageForMask 0, 0, varNum, DimSize(OriginalCCD, 1 )
	endif
	if(cmpstr("RemoveLastNColumns",ctrlName)==0)
		SetDrawLayer/W=CCDImageForMask ProgFront
		Wave w= $NI1M_GetImageWave("CCDImageForMask")		// the target matrix
		iminfo= ImageInfo("CCDImageForMask", NameOfWave(w), 0)
		xax= StringByKey("XAXIS",iminfo)
		yax= StringByKey("YAXIS",iminfo)
		SetDrawEnv/W=CCDImageForMask linefgc= (3,52428,1),fillpat= 5,fillfgc= (0,0,0),xcoord=$xax,ycoord=$yax,save
		DrawRect /W=CCDImageForMask (DimSize(OriginalCCD, 0)-varNum),0,DimSize(OriginalCCD, 0), DimSize(OriginalCCD, 1 )
	endif
	if(cmpstr("RemoveFirstNrows",ctrlName)==0)
		SetDrawLayer/W=CCDImageForMask ProgFront
		Wave w= $NI1M_GetImageWave("CCDImageForMask")		// the target matrix
		iminfo= ImageInfo("CCDImageForMask", NameOfWave(w), 0)
		xax= StringByKey("XAXIS",iminfo)
		yax= StringByKey("YAXIS",iminfo)
		SetDrawEnv/W=CCDImageForMask linefgc= (3,52428,1),fillpat= 5,fillfgc= (0,0,0),xcoord=$xax,ycoord=$yax,save
		DrawRect /W=CCDImageForMask 0, 0, DimSize(OriginalCCD, 0 ), varNum
	endif
	if(cmpstr("RemoveLastNRows",ctrlName)==0)
		SetDrawLayer/W=CCDImageForMask ProgFront
		Wave w= $NI1M_GetImageWave("CCDImageForMask")		// the target matrix
		iminfo= ImageInfo("CCDImageForMask", NameOfWave(w), 0)
		xax= StringByKey("XAXIS",iminfo)
		yax= StringByKey("YAXIS",iminfo)
		SetDrawEnv/W=CCDImageForMask linefgc= (3,52428,1),fillpat= 5,fillfgc= (0,0,0),xcoord=$xax,ycoord=$yax,save
		DrawRect /W=CCDImageForMask 0,(DimSize(OriginalCCD, 1)-varNum),DimSize(OriginalCCD, 0), DimSize(OriginalCCD, 1 )
	endif
	
	if(cmpstr("LowIntToMaskOff",ctrlName)==0)
		NI1M_MaskUpdateColors()
	endif
	setDataFolder OldDf
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function NI1M_RoiDrawButtonProc(ctrlName) : ButtonControl
	String ctrlName

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	if( CmpStr(ctrlName,"CreateROIWorkImage") == 0 )
		//create image for working here...
		nvar AddToOldMask
		addtooldmask = 0
		NI1M_MaskCreateImage()
	endif
	if( CmpStr(ctrlName,"SelectPathToData") == 0 )
		NewPath/C/O/M="Select path to your data, MASK will be saved there too" Convert2Dto1DMaskPath
		NI1M_UpdateMaskListBox()
	endif
	//following function happen only when graph exists...
	DoWindow CCDImageForMask
	if( V_Flag == 0 )
		return 0
	endif
	if( CmpStr(ctrlName,"StartROI") == 0 )
		ShowTools/W=CCDImageForMask/A poly
		SetDrawLayer/W=CCDImageForMask ProgFront
		Wave w= $NI1M_GetImageWave("CCDImageForMask")		// the target matrix
		String iminfo= ImageInfo("CCDImageForMask", NameOfWave(w), 0)
		String xax= StringByKey("XAXIS",iminfo)
		String yax= StringByKey("YAXIS",iminfo)
		SetDrawEnv/W=CCDImageForMask linefgc= (3,52428,1),fillpat= 5,fillfgc= (0,0,0),xcoord=$xax,ycoord=$yax,save
		DoWindow/F  CCDImageForMask 
	endif
	if( CmpStr(ctrlName,"FinishROI") == 0 )
		GraphNormal/W=CCDImageForMask
		HideTools/W=CCDImageForMask/A
		SetDrawLayer/W=CCDImageForMask UserFront
		DoWindow/F NI1M_ImageROIPanel
	endif
	if( CmpStr(ctrlName,"clearROI") == 0 )
		GraphNormal/W=CCDImageForMask
		SetDrawLayer/W=CCDImageForMask/K ProgFront
		SetDrawLayer/W=CCDImageForMask UserFront
		DoWindow/F NI1M_ImageROIPanel
	endif
	
	setDataFolder OldDf
End


