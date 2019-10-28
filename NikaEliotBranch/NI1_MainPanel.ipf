#pragma rtGlobals=1		// Use modern global access method.
#pragma version=2.14		

//version 2.0 adds 2D polarization support, ability to display raw or processed data
//version 2.1 adds GISAXS support	???
//version 2.11 adds compoinents for Pilatus loaders. 
//version 2.12 adds ESRF edf file format 
//version 2.13 adds ability to display image with Q axes
//version 2.14 - added match strings to Sample and empty/dark names 


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1A_Convert2Dto1DMainPanel()
	
	//first initialize 
	NI1A_Initialize2Dto1DConversion()


	DoWindow NI1A_Convert2Dto1DPanel
	if(V_Flag)
		DoWindow/K NI1A_Convert2Dto1DPanel
	endif
	Execute("NI1A_Convert2Dto1DPanel()")
	NI1A_TabProc("nothing",0)
end



//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1A_Initialize2Dto1DConversion()

	string OldDf=GetDataFolder(1)
	variable FirstRun
	if(!DataFolderExists("root:Packages:Convert2Dto1D"))
		FirstRun=1
	endif
	
	NewDataFolder/O root:Packages
	NewDataFolder/O/S root:Packages:Convert2Dto1D

	//internal loaders
	string/g ListOfKnownExtensions=".tif;AUSW;BS_Suitcase_Tiff;GeneralBinary;Pilatus;BrukerCCD;mpa/bin;mpa/asc;mp/bin;mp/asc;BSRC/Gold;DND/txt;RIGK/Raxis;ADSC;WinView spe (Princeton);ASCII;ibw;BSL/SAXS;BSL/WAXS;ascii512x512;ESRFedf;"
	ListOfKnownExtensions+="Fuji/img;.fits;---;"
#if(Exists("ccp4unpack"))	
	ListOfKnownExtensions+="MarIP/xop;"
#endif
	//add Fit2D known types of PC 
	//tif					tif file
	//GeneralBinary		configurable binary loader using GBLoadWave
	//Pilatus 				readers for various Pilatus files. tiff and edf tested, for now 100k Pilatus only. 
	//BrukerCCD			bruker SMART software for CCD
	//mpa				The software is  MPA-NT (or just MPANT),  version 1.48.
						//It is from FAST ComTec, a German company that supplies multi-channel, multiparameter data collection and analysis tools.
						//The hardware I am using is the MPA-3 Dual-parameter multichannel analyzer (from FAST ComTec).
						//That hardware provides the interface to multiwire 2D gas-filled X-ray detector from Molecular Metrology (recently purchased by Rigaku/Osmic).
	//mp/bin				mp binary format. for software producing mpa files above, removed
	//mp/asc				mp ascii format, same as above, removed
	//BSRC/Gold			BESSERC 1536x1536 Gold detector binary format. It has header and 16 bit binary data
	//ASCII 				ASCII data matrix...
	//fits					fits file
	//      note, if the ASCII data matrix has extension mtx, then will try to find same file with extension prn and read header info from there...
 	if(cmpstr(IgorInfo(2),"Windows")==0 || str2num(StringFromList(0, StringByKey("OSVERSION",IgorInfo(3),":",";"),".")+"."+StringFromList(1, StringByKey("OSVERSION",IgorInfo(3),":",";"),"."))<10.5)
		ListOfKnownExtensions+="MarIP/Fit2d;ADSC/Fit2D;Bruker/Fit2D;BSL/Fit2D;Diffract/Fit2D;DIP2000/Fit2D;"		
		ListOfKnownExtensions+="ESRF/Fit2d;Fit2D/Fi2tD;BAS/Fit2D;GAS/Fit2D;HAMA/Fit2D;IMGQ/Fit2D;"		
		ListOfKnownExtensions+="KLORA/Fit2d;MarPck/Fi2tD;PDS/Fit2D;PHOTOM/Fit2D;PMC/Fit2D;PRINC/Fit2D;RIGK/Fit2D;"		
	endif
//	ADSC		ADSC Detector Format : Keyword-value header and binary data
//	Bruker		Bruker format : Bruker area detector frame data format
//	BSL			BSL format : Daresbury SAXS format, based on Hmaburg format
//	Diffract		Compressed diffraction data : Compressed diffraction data
//	DIP2000		DIP-2000 (Mac science) : 2500*2500 Integer*2 special format
//	ESRF		ESRF Data format : ESRF binary, self describing format
//	Fit2D		Fit2D standard format: Self describing readable binary
//	BAS		FUJI BAS-2000 : Fuji image plate scanners (aslo BAS-1500)
//	GAS		GAS 2-D Detector (ESRF) : Raw format used on the beam-lines
//	HAMA		HAMAMATSU PHOTONICS : C4880 CCD detector format
//	IMGQ		IMAGEQUANT : Imagequant TIFF based format (molecular dynamics)
//	KLORA		KLORA : Simplified sub-set of "EDF" written by Jorg Klora
//	MarIP		MAR RESEARCH FORMAT : "image" format for on-line IP systems
//	MarPck		MAR-PCK FORMAT : Compressed old Mar format
//	MarIP		NEW MAR CODE : Same as MAR RESEARCH FORMAT
//	PDS		PDS FORMAT : Powder diffraction standard format file
//	PHOTOM		PHOTOMETRICS CCD FORMAT : X-ray image intensifier system
//	PMC		PMC Format : Photometrics Compressed XRII/CCD data
//	PRINC		PRINCETON CCD FORMAT :X-ray image intensifier system
//	RIGK		RIGAKU R-AXIS : Riguka image plate scanner format

	string/g ListOfVariables
	string/g ListOfStrings
	
	//here define the lists of variables and strings needed, separate names by ;...
	
	ListOfVariables="BeamCenterX;BeamCenterY;QvectorNumberPoints;QvectorMaxNumPnts;QbinningLogarithmic;SampleToCCDDistance;Wavelength;"
	ListOfVariables+="PixelSizeX;PixelSizeY;StartDataRangeNumber;EndDataRangeNumber;XrayEnergy;HorizontalTilt;VerticalTilt;AzimuthalTilt;"
	ListOfVariables+="SampleThickness;SampleTransmission;UseI0ToCalibrate;SampleI0;EmptyI0;"
	ListOfVariables+="UseSampleThickness;UseSampleTransmission;UseI0ToCalibrate;UseSampleI0;UseEmptyI0;"
	ListOfVariables+="UseCorrectionFactor;UseMask;UseDarkField;UseEmptyField;UseSubtractFixedOffset;SubtractFixedOffset;UseSolidAngle;SilentMode;"
	ListOfVariables+="UseSampleMeasTime;UseEmptyMeasTime;UseDarkMeasTime;UsePixelSensitivity;UseMonitorForEF;"
	ListOfVariables+="SampleMeasurementTime;BackgroundMeasTime;EmptyMeasurementTime;"
	ListOfVariables+="CorrectionFactor;DezingerRatio;DezingerCCDData;DezingerEmpty;DezingerDarkField;DezingerHowManyTimes;"
	ListOfVariables+="DoCircularAverage;StoreDataInIgor;ExportDataOutOfIgor;Use2DdataName;DisplayDataAfterProcessing;"
	ListOfVariables+="DoSectorAverages;NumberOfSectors;SectorsStartAngle;SectorsHalfWidth;SectorsStepInAngle;"
	ListOfVariables+="ImageRangeMin;ImageRangeMax;ImageRangeMinLimit;ImageRangeMaxLimit;ImageDisplayLogScaled;"
	ListOfVariables+="A2DImageRangeMin;A2DImageRangeMax;A2DImageRangeMinLimit;A2DImageRangeMaxLimit;A2DLineoutDisplayLogInt;A2DmaskImage;"
	ListOfVariables+="RemoveFirstNColumns;RemoveLastNColumns;RemoveFirstNRows;RemoveLastNRows;MaskDisplayLogImage;"
	ListOfVariables+="MaskOffLowIntPoints;LowIntToMaskOff;AddToOldMask;"
	ListOfVariables+="OverwriteDataIfExists;SectorsNumSect;SectorsSectWidth;SectorsGraphStartAngle;SectorsGraphEndAngle;SectorsUseRAWData;SectorsUseCorrData;"
	ListOfVariables+="DisplayBeamCenterIn2DGraph;DisplaySectorsIn2DGraph;"
	ListOfVariables+="UseQvector;UseTheta;UseDspacing;"
	ListOfVariables+="UserThetaMin;UserThetaMax;UserDMin;UserDMax;UserQMin;UserQMax;"
	ListOfVariables+="DoGeometryCorrection;DoPolarizationCorrection;Use2DPolarizationCor;Use1DPolarizationCor;StartAngle2DPolCor;InvertImages;SkipBadFiles;MaxIntForBadFile;"
	ListOfVariables+="DisplayRaw2DData;DisplayProcessed2DData;TwoDPolarizFract;"
	//and now the function calls variables
	ListOfVariables+="UseSampleThicknFnct;UseSampleTransmFnct;UseSampleMonitorFnct;UseSampleCorrectFnct;UseSampleMeasTimeFnct;"
	ListOfVariables+="UseEmptyTimeFnct;UseBackgTimeFnct;UseEmptyMonitorFnct;"
	ListOfVariables+="ProcessNImagesAtTime;SaveGSASdata;"
	//errors control
	ListOfVariables+="ErrorCalculationsUseOld;ErrorCalculationsUseStdDev;ErrorCalculationsUseSEM;"

	ListOfVariables+="UseLineProfile;UseSectors;"
	ListOfVariables+="LineProf_UseBothHalfs;LineProf_DistanceFromCenter;LineProf_Width;LineProf_DistanceQ;LineProf_WidthQ;LineProf_SubtractBackground;"
	ListOfVariables+="LineProfileDisplayWithQ;LineProfileDisplayWithQy;LineProfileDisplayWithQz;LineProfileDisplayLogX;LineProfileDisplayLogY;"
	ListOfVariables+="LineProfileUseRAW;LineProfileUseCorrData;LineProf_EllipseAR;LineProf_LineAzAngle;LineProf_GIIncAngle;"
	ListOfVariables+="ReflBeam;Phiangle;UseGrazingIncidence;"
	ListOfVariables+="DisplayQValsOnImage;DisplayQvalsWIthGridsOnImg;"	

	ListOfStrings="CurrentInstrumentGeometry;DataFileType;DataFileExtension;MaskFileExtension;BlankFileExtension;CurrentMaskFileName;"
	ListOfStrings+="CurrentEmptyName;CurrentDarkFieldName;CalibrationFormula;CurrentPixSensFile;OutputDataName;CnvCommandStr;"
	ListOfStrings+="CCDDataPath;CCDfileName;CCDFileExtension;FileNameToLoad;ColorTableName;CurrentMaskFileName;ExportMaskFileName;"
	ListOfStrings+="ConfigurationDataPath;LastLoadedConfigFile;ConfFileUserComment;ConfFileUserName;"
	ListOfStrings+="TempOutputDataname;TempOutputDatanameUserFor;"
	ListOfStrings+="Fit2Dlocation;MainPathInfoStr;"
	ListOfStrings+="SampleThicknFnct;SampleTransmFnct;SampleMonitorFnct;SampleCorrectFnct;SampleMeasTimeFnct;"
	ListOfStrings+="EmptyTimeFnct;BackgTimeFnct;EmptyMonitorFnct;"

	ListOfStrings+="LineProf_CurveType;LineProf_KnownCurveTypes;XAxisPlot;YAxisPlot;"

	ListOfStrings+="SampleNameMatchStr;EmptyDarkNameMatchStr;"

	//now for General Binary Input
	ListOfVariables+="NIGBSkipHeaderBytes;NIGBSkipAfterEndTerm;NIGBUseSearchEndTerm;NIGBNumberOfXPoints;NIGBNumberOfYPoints;NIGBSaveHeaderInWaveNote;"
	ListOfStrings+="NIGBDataType;NIGBSearchEndTermInHeader;NIGBByteOrder;NIGBFloatDataType;"
	string ListOfStringsGB="NIGBDataTypeSelection;NIGBByteOrderSelection;"
	//Pilatus support
	ListOfVariables+="PilatusReadAuxTxtHeader;PilatusSignedData;"
	ListOfStrings+="PilatusType;PilatusFileType;PilatusColorDepth;"
	//ESRF edf support
	ListOfVariables+="ESRFEdf_ExposureTime;ESRFEdf_Center_1;ESRFEdf_Center_2;ESRFEdf_PSize_1;ESRFEdf_PSize_2;ESRFEdf_SampleDistance;ESRFEdf_SampleThickness;ESRFEdf_WaveLength;ESRFEdf_Title;"
	ListOfStrings+=""
	
	Wave/Z/T ListOfCCDDataInCCDPath
	if (!WaveExists(ListOfCCDDataInCCDPath))
		make/O/T/N=0 ListOfCCDDataInCCDPath
	endif
	Wave/Z SelectionsofCCDDataInCCDPath
	if(!WaveExists(SelectionsofCCDDataInCCDPath))
		make/O/N=0 SelectionsofCCDDataInCCDPath
	endif

	variable i
	//and here we create them
	for(i=0;i<itemsInList(ListOfVariables);i+=1)	
		IN2G_CreateItem("variable",StringFromList(i,ListOfVariables))
	endfor		
										
	for(i=0;i<itemsInList(ListOfStrings);i+=1)	
		IN2G_CreateItem("string",StringFromList(i,ListOfStrings))
	endfor	
	for(i=0;i<itemsInList(ListOfStringsGB);i+=1)	
		IN2G_CreateItem("string",StringFromList(i,ListOfStringsGB))
	endfor	
	//and now waves as needed
	Wave/Z/T ListOf2DSampleData
	if (!WaveExists(ListOf2DSampleData))
		make/N=0/T ListOf2DSampleData
	endif
	Wave/Z ListOf2DSampleDataNumbers
	if (!WaveExists(ListOf2DSampleDataNumbers))
		make/N=0 ListOf2DSampleDataNumbers
	endif
	Wave/Z/T ListOf2DMaskData
	if (!WaveExists(ListOf2DMaskData))
		make/N=0/T ListOf2DMaskData
	endif
	Wave/Z ListOf2DMaskDataNumbers
	if (!WaveExists(ListOf2DMaskDataNumbers))
		make/N=0 ListOf2DMaskDataNumbers
	endif
	Wave/Z/T ListOf2DEmptyData
	if (!WaveExists(ListOf2DEmptyData))
		make/N=0/T ListOf2DEmptyData
	endif
	//set starting values

	SVAR PilatusColorDepth
	if(strlen(PilatusColorDepth)<1)
		PilatusColorDepth="32"
	endif
	SVAR PilatusType
	if(strlen(PilatusType)<1)
		PilatusType="Pilatus100k"
	endif
	SVAR NIGBDataTypeSelection
	if (strlen(NIGBDataTypeSelection)<1)
		NIGBDataTypeSelection = "Double Float;Single Float;32 bit signed integer;16 bit signed integer;8 bit signed integer;32 bit unsigned integer;16 bit unsigned integer;8 bit unsigned integer;"
	endif
	SVAR NIGBDataType
	if (strlen(NIGBDataType)<1)
		NIGBDataType = "Double Float"
	endif
	SVAR NIGBByteOrderSelection
	if (strlen(NIGBByteOrderSelection)<1)
		NIGBByteOrderSelection = "High Byte First;Low Byte First;"
	endif
	SVAR NIGBByteOrder
	if (strlen(NIGBByteOrder)<1)
		NIGBByteOrder = "Low Byte First"
	endif
	SVAR NIGBFloatDataType
	if (strlen(NIGBFloatDataType)<1)
		NIGBFloatDataType = "IEEE"
	endif
	SVAR NIGBSearchEndTermInHeader
	if (strlen(NIGBSearchEndTermInHeader)<1)
		NIGBSearchEndTermInHeader = ""
	endif
	NVAR NIGBNumberOfXPoints
	if ((NIGBNumberOfXPoints)<1)
		NIGBNumberOfXPoints = 1024
	endif
	NVAR NIGBNumberOfYPoints
	if ((NIGBNumberOfYPoints)<1)
		NIGBNumberOfYPoints = 1024
	endif


	SVAR DataFileExtension
	if (strlen(DataFileExtension)<1)
		DataFileExtension = ".tif"
	endif
	SVAR MaskFileExtension
	if (strlen(MaskFileExtension)<1)
		MaskFileExtension = ".tif"
	endif
	SVAR BlankFileExtension
	if (strlen(BlankFileExtension)<1)
		BlankFileExtension = ".tif"
	endif
	SVAR ConfigurationDataPath
	if (strlen(ConfigurationDataPath)<1)
		ConfigurationDataPath = ""
	endif
	SVAR LastLoadedConfigFile
	if (strlen(LastLoadedConfigFile)<1)
		LastLoadedConfigFile = ""
	endif
	SVAR ConfFileUserComment
	if (strlen(ConfFileUserComment)<1)
		ConfFileUserComment = ""
	endif
	SVAR ConfFileUserName
	if (strlen(ConfFileUserName)<1)
		ConfFileUserName = ""
	endif
	//Line profile default settings
	NVAR UseLineProfile
	NVAR UseSectors
	SVAR LineProf_CurveType
	SVAR LineProf_KnownCurveTypes
	LineProf_KnownCurveTypes = "---;Vertical line;Horizontal Line;Angle Line;GI_Vertical Line;GI_Horizontal Line;Ellipse;"
	if(strlen(LineProf_CurveType)<1)
		LineProf_CurveType="---"
		UseLineProfile=0
	endif
	
	
	string ListOfVariablesL="BeamCenterX;BeamCenterY;QvectorNumberPoints;SampleToCCDDistance;"
	for(i=0;i<itemsInList(ListOfVariablesL);i+=1)	
		NVAR testVal=$(StringFromList(i,ListOfVariablesL))
		if(testVal==0)
			testVal =500
		endif
	endfor		
	ListOfVariablesL="SectorsNumSect;SectorsGraphEndAngle;"
	for(i=0;i<itemsInList(ListOfVariablesL);i+=1)	
		NVAR testVal=$(StringFromList(i,ListOfVariablesL))
		if(testVal==0)
			testVal =360
		endif
	endfor		
	ListOfVariablesL="DezingerRatio;"
	for(i=0;i<itemsInList(ListOfVariablesL);i+=1)	
		NVAR testVal=$(StringFromList(i,ListOfVariablesL))
		if(testVal==0)
			testVal =1.5
		endif
	endfor		
	ListOfVariablesL="Wavelength;"
	if(FirstRun)
		ListOfVariablesL+="QbinningLogarithmic;"
	endif
	ListOfVariablesL+="PixelSizeX;PixelSizeY;StartDataRangeNumber;EndDataRangeNumber;TwoDPolarizFract;"
	ListOfVariablesL+="SampleThickness;SampleTransmission;SampleI0;EmptyI0;DezingerHowManyTimes;"
	ListOfVariablesL+="SampleMeasurementTime;BackgroundMeasTime;EmptyMeasurementTime;"
	ListOfVariablesL+="CorrectionFactor;SectorsSectWidth;NIGBSaveHeaderInWaveNote;ProcessNImagesAtTime;LineProf_EllipseAR;"
	for(i=0;i<itemsInList(ListOfVariablesL);i+=1)	
		NVAR testVal=$(StringFromList(i,ListOfVariablesL))
		if(testVal==0)
			testVal =1
		endif
	endfor		
	ListOfVariablesL="SectorsHalfWidth;SectorsStepInAngle;"
	for(i=0;i<itemsInList(ListOfVariablesL);i+=1)	
		NVAR testVal=$(StringFromList(i,ListOfVariablesL))
		if(testVal==0)
			testVal =10
		endif
	endfor		
	ListOfVariablesL="NumberOfSectors;"
	for(i=0;i<itemsInList(ListOfVariablesL);i+=1)	
		NVAR testVal=$(StringFromList(i,ListOfVariablesL))
		if(testVal==0)
			testVal =36
		endif
	endfor		
	NVAR Wavelength= root:Packages:Convert2Dto1D:Wavelength
	NVAR XrayEnergy= root:Packages:Convert2Dto1D:XrayEnergy
	XrayEnergy = 12.398424437/Wavelength

	ListOfVariablesL="UseI0ToCalibrate;DezingerCCDData;DezingerEmpty;DezingerDarkField;HorizontalTilt;VerticalTilt;"
	for(i=0;i<itemsInList(ListOfVariablesL);i+=1)	
		NVAR testVal=$(StringFromList(i,ListOfVariablesL))
		if(testVal==0)
			testVal =0
		endif
	endfor		

	NVAR ErrorCalculationsUseOld
	NVAR ErrorCalculationsUseStdDev
	NVAR ErrorCalculationsUseSEM
	if(ErrorCalculationsUseOld+ErrorCalculationsUseStdDev+ErrorCalculationsUseSEM!=1)
		ErrorCalculationsUseOld=0
		ErrorCalculationsUseStdDev=1
		ErrorCalculationsUseSEM=0
	endif

	NVAR LineProfileDisplayWithQ
	NVAR LineProfileDisplayWithQz
	NVAR LineProfileDisplayWithQy
	if(LineProfileDisplayWithQ+LineProfileDisplayWithQz+LineProfileDisplayWithQy!=1)
		LineProfileDisplayWithQ=1
		LineProfileDisplayWithQz=0
		LineProfileDisplayWithQy=0
	endif
	
	NVAR UseQvector
	NVAR UseTheta
	NVAR UseDspacing
	if((UseQvector+UseTheta+UseDspacing)!=1)
		UseQvector=1
		UseTheta=0
		UseDspacing=0
	endif

	NVAR Use2DPolarizationCor
	NVAR Use1DPolarizationCor
	if(Use2DPolarizationCor+Use1DPolarizationCor!=1)
		Use2DPolarizationCor=0
		Use1DPolarizationCor=1
	endif

	NVAR RemoveFirstNColumns
	NVAR RemoveLastNColumns
	NVAR RemoveFirstNRows
	NVAR RemoveLastNRows
	RemoveFirstNColumns=0
	RemoveLastNColumns=0
	RemoveFirstNRows=0
	RemoveLastNRows=0
	
	
	NVAR  DisplayRaw2DData
	NVAR  DisplayProcessed2DData
	if(DisplayRaw2DData+DisplayProcessed2DData!=1)
		DisplayProcessed2DData=0
		DisplayRaw2DData=1
	endif
	SVAR CCDFileExtension
	if(strlen(CCDFileExtension)<2)
		CCDFileExtension="????"
	endif
	SVAR ColorTableName
	if(strlen(ColorTableName)<2)
		ColorTableName="Terrain"
	endif
	
	NVAR SectorsUseRAWData
	NVAR SectorsUseCorrData
	if(SectorsUseRAWData+SectorsUseCorrData!=1)
		SectorsUseRAWData=1
		SectorsUseCorrData=0
	endif
	
	NVAR LineProfileUseRAW
	NVAR LineProfileUseCorrData
	if(LineProfileUseRAW+LineProfileUseCorrData!=1)
		LineProfileUseRAW=1
		LineProfileUseCorrData=0
	endif
	
	//BSL files support...
	//josh add: I added BSL sumoverframes and BSLlog 
	setDataFolder root:Packages
	NewDataFolder/O/S root:Packages:NI1_BSLFiles
	
	variable/g BSLpixels, BSLpixels1, BSLframes, BSLcurrentframe, BSLsumframes, BSLwaxsframes, BSLI1, BSLI2, BSLwaxschannels, BSLAverage, BSLFoundFrames,BSLfromframe,BSLtoframe
	make/o/t/n=10 BSLheadnote,BSLlogfile


	setDataFOlder oldDf
end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function NI1A_Convert2DTo1D()
		
	string OldDf = GetDataFolder(1)
	setDataFolder root:Packages:Convert2Dto1D

	NVAR UseSectors=root:Packages:Convert2Dto1D:UseSectors		//this is for Sector analysis. Only if set ot 1, sector analysis is reuired by user...
	NVAR UseLineProfile=root:Packages:Convert2Dto1D:UseLineProfile		//this is for Sector analysis. Only if set ot 1, sector analysis is reuired by user...
	variable timer
		string ListOfOrientations=""
		string CurOrient
		variable i
		NVAR DoCircularAverage=root:Packages:Convert2Dto1D:DoCircularAverage
		NVAR DoSectorAverages=root:Packages:Convert2Dto1D:DoSectorAverages
		NVAR NumberOfSectors=root:Packages:Convert2Dto1D:NumberOfSectors
		NVAR SectorsStartAngle=root:Packages:Convert2Dto1D:SectorsStartAngle
		NVAR SectorsHalfWidth=root:Packages:Convert2Dto1D:SectorsHalfWidth
		NVAR SectorsStepInAngle=root:Packages:Convert2Dto1D:SectorsStepInAngle
		NVAR LineProf_DistanceQ=root:Packages:Convert2Dto1D:LineProf_DistanceQ
		NVAR LineProf_WidthQ=root:Packages:Convert2Dto1D:LineProf_WidthQ
		NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength							//in A
		string wavelengths = num2str(round(100*wavelength))
	

	//parameters are set, now process the data as needed..
	//print "1: ", stopmstimer(timer)
	//timer=startmstimer
	NI1A_Check2DConversionData()		//this should check if input data are OK, stuff any necessary consistency checks here...
	
	//print "2: ", stopmstimer(timer)
	//timer=startmstimer
	NI1A_CorrectDataPerUserReq("","")		//here we need to do all of the corrections as user selected...
	
	//print "3: ", stopmstimer(timer)
	//timer=startmstimer
			
	//sector averages are here
	if(UseSectors)		//this is all needed for sector analysis. Will need to move stuff around for line analysis later. 
	
		if (DoCircularAverage)
			ListOfOrientations+="C;"
		endif	
		if (DoSectorAverages)
		
			
			For(i=0;i<NumberOfSectors;i+=1)
				ListOfOrientations+=ReplaceString(".",num2str(IN2G_roundDecimalPlaces(SectorsStartAngle+SectorsStepInAngle*i,1)),"p")+"_"+ReplaceString(".",num2str(IN2G_roundDecimalPlaces(SectorsHalfWidth,1)),"p")+";"
			endfor
			//print "sectors: ", stopmstimer(timer)
			//timer=startmstimer
		endif	
		For(i=0;i<ItemsInList(ListOfOrientations);i+=1)
			CurOrient = stringFromList(i,ListOfOrientations)
			NI1A_FixNumPntsIfNeeded(CurOrient,wavelengths)
			
			//print "NI1A_FixNumPntsIfNeeded: ", stopmstimer(timer)
			//timer=startmstimer
			NI1A_CheckGeometryWaves(CurOrient,wavelengths)			//checks if geometry waves exist and if they are correct, makes them correct if needed
		
			//print "NI1A_CheckGeometryWaves: ", stopmstimer(timer)
			//timer=startmstimer
			NI1A_AverageDataPerUserReq(CurOrient,wavelengths)
			
			//print "NI1A_AverageDataPerUserReq: ", stopmstimer(timer)
			//timer=startmstimer
			NI1A_SaveDataPerUserReq(CurOrient,wavelengths)
			//print "NI1A_SaveDataPerUserReq: ", stopmstimer(timer)
			//timer=startmstimer
			DoUpdate
		endfor
	endif
	//line profile averages are here... 
	if(UseLineProfile)
		NI1A_LineProf_CreateLP()		//thsi creates line profile as user set conditions... 
			//print "NI1A_LineProf_CreateLP: ", stopmstimer(timer)
			//timer=startmstimer
		//note for future. There is a lot of unnecessary calculations here. This could be sped up by better programming. 
		//figure out which Q we analyzed...
		SVAR LineProf_CurveType=root:Packages:Convert2Dto1D:LineProf_CurveType	
		NVAR LineProf_LineAzAngle=root:Packages:Convert2Dto1D:LineProf_LineAzAngle
		string tempStr, tempStr1
		if(stringMatch(LineProf_CurveType,"Horizontal Line"))
			tempStr1="HLp_"
			sprintf tempStr, "%1.2g" LineProf_DistanceQ
		elseif(stringMatch(LineProf_CurveType,"GI_Horizontal line"))
			tempStr1="gH_"
			sprintf tempStr, "%1.2g" LineProf_DistanceQ
		elseif(stringMatch(LineProf_CurveType,"GI_Vertical line"))
			tempStr1="gV_"
			sprintf tempStr, "%1.2g" LineProf_DistanceQ
		elseif(stringMatch(LineProf_CurveType,"Vertical Line"))
			tempStr1="VLp_"
			sprintf tempStr, "%1.2g" LineProf_DistanceQ
		elseif(stringMatch(LineProf_CurveType,"Ellipse"))
			tempStr1="ELp_"
			sprintf tempStr, "%1.2g" LineProf_DistanceQ
		elseif(stringMatch(LineProf_CurveType,"Angle Line"))
			tempStr1="ALp_"
			sprintf tempStr, "%1.2g" LineProf_LineAzAngle
		endif
//		nvar supexchar = root:Packages:Nika1101:SupExChar
//		if(supexchar)
//			NI1A_SaveDataPerUserReq(tempStr1,wavelengths)
//		else
			NI1A_SaveDataPerUserReq(tempStr1+tempStr,wavelengths)
			
			//print "NI1A_SaveDataPerUserReq: ", stopmstimer(timer)
			//timer=startmstimer
//		endif
		doUpdate
	endif
	
	
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1A_FixNumPntsIfNeeded(CurOrient,wavelengths)
	string CurOrient,wavelengths
	
	//here we fix the num pnts to max number if requested by user
	string OldDf = GetDataFolder(1)
	setDataFolder root:Packages:Convert2Dto1D
	
	NVAR QvectorNumberPoints=root:Packages:Convert2Dto1D:QvectorNumberPoints
	NVAR QvectorMaxNumPnts=root:Packages:Convert2Dto1D:QvectorMaxNumPnts
	NVAR QbinningLogarithmic=root:Packages:Convert2Dto1D:QbinningLogarithmic
	
	if(QvectorMaxNumPnts)	//user wants 1 point = 1 pixel (max num points)... Need to fix the num pnts....
		QbinningLogarithmic=0		//cannot be log binning... 
		//first lets check lookup table, so we do not have to calculate this always
		Wave/Z MaxNumPntsLookupWv= root:Packages:Convert2Dto1D:MaxNumPntsLookupWv
		Wave/T/Z MaxNumPntsLookupWvLBL= root:Packages:Convert2Dto1D:MaxNumPntsLookupWvLBL
		if(!WaveExists(MaxNumPntsLookupWv))
			Make /N=0 MaxNumPntsLookupWv
			Make/T /N=0 MaxNumPntsLookupWvLBL
		endif
		//OK lookup table now exists, next check the wave note to make sure it si up to date
		string OldNote=note(MaxNumPntsLookupWv)
		NVAR BeamCenterX=root:Packages:Convert2Dto1D:BeamCenterX
		//NVAR BeamCenterY=root:Packages:Convert2Dto1D:BeamCenterY
		
		
		NVAR beamycenter=root:Packages:Convert2Dto1D:BeamCenterY
		nvar effectiveycenter = root:Packages:Convert2Dto1D:effBCY
		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		variable BeamCenterY
		if(nvar_exists(effectiveycenter) && UseGrazingIncidence)
			BeamCenterY = effectiveycenter
		else
			BeamCenterY = beamycenter
		endif
		
		
		
		SVAR CurrentMaskFileName=root:Packages:Convert2Dto1D:CurrentMaskFileName
		Wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
		NVAR UseMask=root:Packages:Convert2Dto1D:UseMask
		string OldCntrX, OldCntrY
		variable MaskNameNotSame, OldUseMask, OldDim0, OldDim1
		OldCntrX=StringByKey("BeamCenterX", OldNote  , "=")
		OldCntrY=StringByKey("BeamCenterY", OldNote  , "=")
		OldDim0=NumberByKey("WvDimension0", OldNote  , "=")
		OldDim1=NumberByKey("WvDimension1", OldNote  , "=")
		OldUseMask=NumberByKey("UseMask", OldNote  , "=")
		if(UseMask)
			MaskNameNotSame= abs(cmpstr(CurrentMaskFileName,stringByKey("MaskName", OldNote,"=")))
		else
			MaskNameNotSame=0
		endif
		if(cmpstr(OldCntrX,num2str(BeamCenterX))!=0 || cmpstr(OldCntrY, num2str(BeamCenterY))!=0 || OldDim0!=DimSize(CCDImageToConvert, 0 ) || OldDim1!=DimSize(CCDImageToConvert, 1) || MaskNameNotSame || OldUseMask!=UseMask)
			redimension/N=0 MaxNumPntsLookupWv
			redimension/N=0 MaxNumPntsLookupWvLBL
		endif
		variable i
		For(i=0;i<numpnts(MaxNumPntsLookupWv);i+=1)
			if(cmpstr(MaxNumPntsLookupWvLBL[i],CurOrient)==0)
				QvectorNumberPoints=MaxNumPntsLookupWv[i]
			//	print "Right number of points found in LUT"
				return 1
			endif
		endfor
		//OK, if we are here, we did not find the right value in the lookup table
		//fix the note
		note /k MaxNumPntsLookupWv
		string newNote="BeamCenterX="+num2str(BeamCenterX)+";"
		newNote+="BeamCenterY="+num2str(BeamCenterY)+";"
		newNote+="WvDimension0="+num2str(DimSize(CCDImageToConvert, 0 ))+";"
		newNote+="WvDimension1="+num2str(DimSize(CCDImageToConvert, 1))+";"
		newNote+="UseMask="+num2str(UseMask)+";"
		newNote+="MaskName="+CurrentMaskFileName+";"
		note MaxNumPntsLookupWv, newNote
		//and now find the right number... This is the most difficult part...
		NVAR PixelSizeX = root:Packages:Convert2Dto1D:PixelSizeX								//in millimeters
		NVAR PixelSizeY = root:Packages:Convert2Dto1D:PixelSizeY								//in millimeters
		NVAR HorizontalTilt = root:Packages:Convert2Dto1D:HorizontalTilt								//in degrees
		NVAR VerticalTilt = root:Packages:Convert2Dto1D:VerticalTilt								//in degrees
		Wave/Z PixRadius2DWave=root:Packages:Convert2Dto1D:PixRadius2DWave		//note, this is distance in pixles, not in radii
		if(WaveExists(PixRadius2DWave))
			OldNote = note(PixRadius2DWave)
			OldCntrX=stringByKey("BeamCenterX",OldNote,"=")
			OldCntrY=stringByKey("BeamCenterY",OldNote,"=")
			variable OldPixX=numberByKey("PixelSizeX",OldNote,"=")
			variable OldPixY=numberByKey("PixelSizeY",OldNote,"=")
			//variable OldHorizontalTilt=numberByKey("HorizontalTilt",OldNote,"=")
			//variable OldVerticalTilt=numberByKey("VerticalTilt",OldNote,"=")
			if(cmpstr(OldCntrX, num2str(BeamCenterX))!=0 || cmpstr(OldCntrY,num2str(BeamCenterY))!=0 || OldPixX!=PixelSizeX || OldPixY!=PixelSizeY)///|| OldHorizontalTilt!=HorizontalTilt || OldVerticalTilt!=VerticalTilt) lets not worry here about the tilt
				NI1A_Create2DPixRadiusWave(CCDImageToConvert)
				NI1A_Create2DAngleWave(CCDImageToConvert)
			endif
		else
			NI1A_Create2DPixRadiusWave(CCDImageToConvert)
			NI1A_Create2DAngleWave(CCDImageToConvert)
		endif
		//Ok, now the 2DRadiusWave must exist... and be correct.

		wave PixRadius2DWave=root:Packages:Convert2Dto1D:PixRadius2DWave
		Wave AnglesWave=root:Packages:Convert2Dto1D:AnglesWave
		NVAR UseMask=root:Packages:Convert2Dto1D:UseMask
		NVAR DoSectorAverages=root:Packages:Convert2Dto1D:DoSectorAverages
//	NVAR NumberOfSectors=root:Packages:Convert2Dto1D:NumberOfSectors
//	NVAR SectorsStartAngle=root:Packages:Convert2Dto1D:SectorsStartAngle
///	NVAR SectorsHalfWidth=root:Packages:Convert2Dto1D:SectorsHalfWidth
//	NVAR SectorsStepInAngle=root:Packages:Convert2Dto1D:SectorsStepInAngle
//	SVAR CurrentMaskFileName=root:Packages:Convert2Dto1D:CurrentMaskFileName
		variable centerAngleRad, WidthAngleRad, startAngleFIxed, endAgleFixed
		//apply mask, if selected
		duplicate/O PixRadius2DWave, MaskedRadius2DWave
		redimension/S MaskedRadius2DWave
		if(UseMask)
			wave M_ROIMask=root:Packages:Convert2Dto1D:M_ROIMask
			MatrixOp/O MaskedRadius2DWave = PixRadius2DWave * M_ROIMask
		endif
		if(cmpstr(CurOrient,"C")!=0)
			duplicate/O AnglesWave,tempAnglesMask
			centerAngleRad= (pi/180)*str2num(StringFromList(0, CurOrient,  "_"))
			WidthAngleRad= (pi/180)*str2num(StringFromList(1, CurOrient,  "_"))
			
			startAngleFixed = centerAngleRad-WidthAngleRad
			endAgleFixed = centerAngleRad+WidthAngleRad
	
			if(startAngleFixed<0)
				tempAnglesMask = ((AnglesWave[p][q] > (2*pi+startAngleFixed) || AnglesWave[p][q] <endAgleFixed))? 1 : 0
			elseif(endAgleFixed>(2*pi))
				tempAnglesMask = (AnglesWave[p][q] > startAngleFixed || AnglesWave[p][q] <(endAgleFixed-2*pi))? 1 : 0
			else
				tempAnglesMask = (AnglesWave[p][q] > startAngleFixed && AnglesWave[p][q] <endAgleFixed)? 1 : 0
			endif
			
			MatrixOp/O MaskedRadius2DWave = MaskedRadius2DWave * tempAnglesMask
			killwaves tempAnglesMask
		endif
		//radius data are masked now 

		wavestats/Q MaskedRadius2DWave
		killwaves MaskedRadius2DWave
		QvectorNumberPoints=floor((V_max-V_min))
		redimension/N=(numpnts(MaxNumPntsLookupWv)+1) MaxNumPntsLookupWvLBL, MaxNumPntsLookupWv
		
		MaxNumPntsLookupWvLBL[numpnts(MaxNumPntsLookupWv)]= CurOrient
		MaxNumPntsLookupWv[numpnts(MaxNumPntsLookupWv)]= QvectorNumberPoints
		
		print "Recalcaulted the right number of points LUT"

		return 2
	endif
	setDataFolder OldDf
	
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1A_Create2DPixRadiusWave(DataWave)
	wave DataWave

	

	string OldDf=GetDataFolder(1)
	setDataFolder root:Packages:Convert2Dto1D
	
	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance		//in millimeters
	NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength							//in A
	NVAR PixelSizeX = root:Packages:Convert2Dto1D:PixelSizeX								//in millimeters
	NVAR PixelSizeY = root:Packages:Convert2Dto1D:PixelSizeY								//in millimeters
	NVAR beamCenterX=root:Packages:Convert2Dto1D:beamCenterX
	//NVAR beamCenterY=root:Packages:Convert2Dto1D:beamCenterY
	
	
		NVAR beamycenter=root:Packages:Convert2Dto1D:BeamCenterY
		nvar effectiveycenter = root:Packages:Convert2Dto1D:effBCY
		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		variable beamCenterY
		if(nvar_exists(effectiveycenter) && UseGrazingIncidence)
			beamCenterY = effectiveycenter
		else
			beamCenterY = beamycenter
		endif
	
	
	
	NVAR HorizontalTilt=root:Packages:Convert2Dto1D:HorizontalTilt							//tilt in degrees
	NVAR VerticalTilt=root:Packages:Convert2Dto1D:VerticalTilt								//tilt in degrees
	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance		//distance to sample in mm 

	//wavelength=12.398424437/EnergyInKeV
	//OK, existing radius wave was not correct or did not exist, make the right one... 
	print "Creating Pix Radius wave"
	
	variable XSaDetDitsInPix=SampleToCCDDistance / PixelSizeX
	variable YSaDetDitsInPix=SampleToCCDDistance / PixelSizeY
	//Create wave for q distribution
	Duplicate/O DataWave, PixRadius2DWave
	Redimension/S PixRadius2DWave
	//PixRadius2DWave = sqrt((cos(HorizontalTilt*pi/180)*(p-BeamCenterX))^2 + (cos(VerticalTilt*pi/180)*(q-BeamCenterY))^2)
//	need to use new function... NI1T_TiltedToCorrectedR(TiltedR,SaDetDistance,alpha)
//	tilts added again 6/22/2005
//	variable tm=ticks
//	if(HorizontalTilt!=0 || VerticalTilt!=0)
//		PixRadius2DWave = sqrt((NI1T_TiltedToCorrectedR(p-BeamCenterX,XSaDetDitsInPix,HorizontalTilt))^2 + (NI1T_TiltedToCorrectedR(q-BeamCenterY,YSaDetDitsInPix,VerticalTilt))^2)
//	else
	//Note, I do not think this wave needs to be fixed for tilts. All we use it for is to get max number of pixels for any particular direction... 
		PixRadius2DWave = sqrt((cos(HorizontalTilt*pi/180)*(p-BeamCenterX))^2 + (cos(VerticalTilt*pi/180)*(q-BeamCenterY))^2)
//	endif
//	print (ticks-tm)/60
	PixRadius2DWave[beamCenterX][beamCenterY] = NaN
	//record for which geometry this Radius vector wave was created
	string NoteStr
	NoteStr = note(DataWave)
	NoteStr+="BeamCenterX="+num2str(BeamCenterX)+";"
	NoteStr+="BeamCenterY="+num2str(BeamCenterY)+";"
	NoteStr+="PixelSizeX="+num2str(PixelSizeX)+";"
	NoteStr+="PixelSizeY="+num2str(PixelSizeY)+";"
	NoteStr+="HorizontalTilt="+num2str(HorizontalTilt)+";"
	NoteStr+="VerticalTilt="+num2str(VerticalTilt)+";"
	note PixRadius2DWave, NoteStr
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//Function NI1A_CalcTiltedDetDistance(DistOnDetector, TiltAngle, SaDetDistInPix)
//	variable DistOnDetector, TiltAngle, SaDetDistInPix
//	
//	variable Alpha = TiltAngle * pi /180
//	variable Pi2MinusAplha= pi/2 - alpha
//	//here we correct for tilt the distance - done in each X/Y direction separately
//	//Calucalte two parts. 
//	//Project impact pixel on detector to plane perpendicular to beam direction first
//	variable PerpProj = DistOnDetector * cos(Alpha)
//	//Next add to this the effect of cutting the cone earlier or later
//	//need theta first 
//	variable SampleToDetImpactPoint = sqrt(DistOnDetector^2 + SaDetDistInPix^2 - 2 * SaDetDistInPix * DistOnDetector * cos(Pi2MinusAplha) )
//	variable theta = asin((DistOnDetector/SampleToDetImpactPoint) * sin(Pi2MinusAplha))
//	variable ConeAdition = SaDetDistInPix + sin(Alpha) * tan(theta)
//	
//	return PerpProj+ConeAdition
//end

//following code added 6 22 2005 to finish the tilts...

Function NI1T_TiltedToCorrectedR(TiltedR,SaDetDistance,alpha)			
	variable TiltedR,SaDetDistance,alpha
	//this function returns distance from beam center corrected for the effect of tilt
	//Definitions:
	//TiltedR is measured distance on detector (in same units as SaDetDistance) in either x or y directions. 
	//	Note, it is positive if the measured x is larger than x of beamstop (or same for y)
	//SaDetDistance is distance between the sample and the beam center position on thte detector Use same units as for TiltedR
	//alpha is tilt angle in particular plane. It is positive when the detector is tilted forward for X (or y) positive. It is in degrees
	 variable alphaRad=(alpha*pi/180)
	return TiltedR*cos(alphaRad) + TiltedR*sin(alphaRad)*tan(NI1T_CalcThetaForTiltToTheor(TiltedR,SaDetDistance,alphaRad))
	
end

Function NI1T_CalcThetaForTiltToTheor(radius,Distance,alphaRad)
		variable radius,Distance,alphaRad
		
		variable temp =radius * abs(cos(alphaRad))
		temp=temp/sqrt(distance^2 + radius^2 - 2*Distance*radius*sin(alphaRad))
		return asin(temp)
end

Function NI1T_TheoreticalToTilted(TheoreticalR,SaDetDistance,alpha)
		variable TheoreticalR,SaDetDistance,alpha
		//this function returns distance on tilted detector compared to theoretical distacne in perpendicular plane
		//for either x or y directions
		//definitions
		// TheoreticalR is distance in either positive or negative direction in perpendicular plane to Sa-det line
		//	use same units as for SapleToDetector distance
		//	it is positive if caclualte x is larger than beam center x (or fsame for y)
		//SaDetDistance is distnace between sample and detector...
		//alpha is tilt angle. It is positive if for positive TheoreticalR the detector is tilted forward (making the calculated distacne smaller at least for small alphas
		//	alpha is in degrees
		variable betaAngle = atan(SaDetDistance/TheoreticalR)
		variable alphaRad=alpha/(2*pi)
		variable res = sin(pi/2-alphaRad) * TheoreticalR*(sin(betaAngle)/(sin(pi - alphaRad - betaAngle)))
		return res

end
Function NI1BC_CalculatePathWvs(dspacing, wvX,wvY)
	wave wvX, wvY
	variable dspacing

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	variable pixelDist
	variable pixelDistXleft, pixelDistXright, pixelDistYtop, pixelDistYbot
	NVAR Wavelength
	NVAR SampleToCCDDistance
	NVAR PixelSizeX
	NVAR PixelSizeY
	NVAR XrayEnergy
	NVAR HorizontalTilt
	NVAR VerticalTilt
	//NVAR ycenter=root:Packages:Convert2Dto1D:BeamCenterY
	
	
		NVAR beamycenter=root:Packages:Convert2Dto1D:BeamCenterY
		nvar effectiveycenter = root:Packages:Convert2Dto1D:effBCY
		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		variable ycenter
		if(nvar_exists(effectiveycenter) && UseGrazingIncidence)
			ycenter = effectiveycenter
		else
			ycenter = beamycenter
		endif
	
	
	NVAR xcenter=root:Packages:Convert2Dto1D:BeamCenterX
	//Ok, this should just return simple Bragg law with little trigonometry, NO tilts yet
	variable radX = NI1BC_GetPixelFromDSpacing(dspacing, "X")
	variable radY = NI1BC_GetPixelFromDSpacing(dspacing, "Y")
 	pixelDist = SampleToCCDDistance *tan(2* asin( Wavelength /(2* dspacing) )  )
//			pixelDist = NI1T_TheoreticalToTilted(pixelDist,SampleToCCDDistance,HorizontalTilt) / PixelSizeX 
	pixelDistXleft = NI1T_TheoreticalToTilted(pixelDist,SampleToCCDDistance,HorizontalTilt) / PixelSizeX
	pixelDistXright = NI1T_TheoreticalToTilted(pixelDist,SampleToCCDDistance,-1*HorizontalTilt) / PixelSizeX
	pixelDistYtop = NI1T_TheoreticalToTilted(pixelDist,SampleToCCDDistance,VerticalTilt) / PixelSizeY
	pixelDistYbot = NI1T_TheoreticalToTilted(pixelDist,SampleToCCDDistance,-1*VerticalTilt) / PixelSizeY
	redimension/N=360 wvX, wvY
	SetScale/I x 0,(2*pi),"", wvX, wvY
	wvX = ((x>=pi/2)&&(x<3*pi/2))? (xcenter+pixelDistXright*cos(x)) : (xcenter+pixelDistXleft*cos(x))
	wvY = ((x>=0)&&(x<pi))? (ycenter+pixelDistYtop*sin(x)) : (ycenter+pixelDistYbot*sin(x))
  	setDataFolder OldDf	
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1A_RemoveInfNaNsFrom8Waves(Wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8)							//removes NaNs from 3 waves
	Wave Wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8					//assume same number of points in the waves
	
	variable i=0, imax=numpnts(Wv1)
	For(i=imax;i>=0;i-=1)
			if (numtype(Wv1[i])!=0)
				Deletepoints i, 1, Wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8
			endif
			if (numtype(Wv2[i])!=0)
				Deletepoints i, 1, Wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8
			endif
			if (numtype(Wv3[i])!=0)
				Deletepoints i, 1, Wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8
			endif
			if (numtype(Wv4[i])!=0)
				Deletepoints i, 1, Wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8
			endif
			if (numtype(Wv5[i])!=0)
				Deletepoints i, 1, Wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8
			endif
			if (numtype(Wv6[i])!=0)
				Deletepoints i, 1, Wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8
			endif
			if (numtype(Wv7[i])!=0)
				Deletepoints i, 1, Wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8
			endif
			if (numtype(Wv8[i])!=0)
				Deletepoints i, 1, Wv1,wv2,wv3,wv4,wv5,wv6,wv7,wv8
			endif
	endfor
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1A_SaveDataPerUserReq(CurOrient,wavelengths)
	string CurOrient,wavelengths

	string OldDf=getDataFOlder(1)
	if(stringmatch(CurOrient, "*Lp*") || stringmatch(CurOrient, "*GH*")  ||stringmatch(CurOrient, "*GV*") )
		Wave/Z LineProfileIntensity=root:Packages:Convert2Dto1D:LineProfileIntensity
		Wave/Z LineProfileError=root:Packages:Convert2Dto1D:LineProfileIntSdev
		Wave/Z LineProfileQ=root:Packages:Convert2Dto1D:LineProfileQvalues
		Wave/Z LineProfileQx=root:Packages:Convert2Dto1D:LineProfileQx
		Wave/Z LineProfileQy=root:Packages:Convert2Dto1D:LineProfileQy
		Wave/Z LineProfileQz=root:Packages:Convert2Dto1D:LineProfileQz
		Wave/Z LineProfileQxy=root:Packages:Convert2Dto1D:LineProfileQxy
		Wave/Z LineProfileQxz=root:Packages:Convert2Dto1D:LineProfileQxz
		Wave/Z LineProfileXi=root:Packages:Convert2Dto1D:LineProfileXi
		Wave/Z LineProfileTh=root:Packages:Convert2Dto1D:LineProfileTh
		//Wave/Z LineProfileYValsPix=root:Packages:Convert2Dto1D:LineProfileYValsPix
		Wave/Z LineProfileQz=root:Packages:Convert2Dto1D:LineProfileQz
		//Wave/Z LineProfileZValsPix=root:Packages:Convert2Dto1D:LineProfileZValsPix
		if(!WaveExists(LineProfileQx)||numpnts(LineProfileQx)!=numpnts(LineProfileQy))
			Duplicate/O LineProfileQy, LineProfileQx
		endif
		//Duplicate/O LineProfileZValsPix tempWv1234
	else
		wave/Z Qvector=root:Packages:Convert2Dto1D:Qvector
		wave/Z Dspacing=root:Packages:Convert2Dto1D:Dspacing
		wave/Z TwoTheta=root:Packages:Convert2Dto1D:TwoTheta
		wave/Z TwoThetaWidth=root:Packages:Convert2Dto1D:TwoThetaWidth
		wave/Z DspacingWidth=root:Packages:Convert2Dto1D:DspacingWidth
		wave/Z Intensity=root:Packages:Convert2Dto1D:Intensity
		wave/Z Error=root:Packages:Convert2Dto1D:Error
		wave/Z Qsmearing=root:Packages:Convert2Dto1D:Qsmearing
	endif
	
	SVAR LoadedFile=root:Packages:Convert2Dto1D:FileNameToLoad
	SVAR UserFileName=root:Packages:Convert2Dto1D:OutputDataName
	SVAR TempOutputDataname=root:Packages:Convert2Dto1D:TempOutputDataname
	SVAR TempOutputDatanameUserFor=root:Packages:Convert2Dto1D:TempOutputDatanameUserFor
	NVAR ExportDataOutOfIgor=root:Packages:Convert2Dto1D:ExportDataOutOfIgor
	NVAR StoreDataInIgor=root:Packages:Convert2Dto1D:StoreDataInIgor
	NVAR Use2DdataName=root:Packages:Convert2Dto1D:Use2DdataName
	NVAR DisplayDataAfterProcessing=root:Packages:Convert2Dto1D:DisplayDataAfterProcessing
	NVAR OverwriteDataIfExists=root:Packages:Convert2Dto1D:OverwriteDataIfExists
	NVAR UseQvector=root:Packages:Convert2Dto1D:UseQvector
	NVAR UseTheta=root:Packages:Convert2Dto1D:UseTheta
	NVAR UseDspacing=root:Packages:Convert2Dto1D:UseDspacing
	NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
	
	
	variable ItemsInLst, i
	string OldNote
	string LocalUserFileName
	string UseName
	string LongUseName
	if (Use2DdataName)
		controlinfo/W=NI1A_Convert2Dto1Dpanel Select2DDataType
		//JOSH ADD....
		if(cmpstr(S_Value,"BSL/SAXS")==0)
		//JOSH ADD....
			NVAR BSLcurrentframe=$("root:Packages:NI1_BSLFiles:BSLcurrentframe")
			NVAR BSLfromframe=$("root:Packages:NI1_BSLFiles:BSLfromframe")
			NVAR BSLtoframe=$("root:Packages:NI1_BSLFiles:BSLtoframe")
			NVAR BSLaverage=$("root:Packages:NI1_BSLFiles:BSLaverage")
			NVAR BSLsumframes=$("root:Packages:NI1_BSLFiles:BSLsumframes")
			if(BSLaverage)
			UseName=LoadedFile[0,9]+"_Average_"+CurOrient
			elseif(BSLsumframes)
			UseName=LoadedFile[0,9]+"_"+num2str(BSLfromframe)+"-"+num2str(BSLtoframe)+"_"+CurOrient
			else
			UseName=LoadedFile[0,9]+"_"+num2str(BSLcurrentframe)+"_"+CurOrient
			endif
		else
			variable tempEnd=26-strlen(CurOrient)
			UseName=LoadedFile[0,tempEnd]+"_"+CurOrient
		endif
	else
		if(strlen(UserFileName)<1)	//user did nto set the file name
			if(cmpstr(TempOutputDatanameUserFor,LoadedFile)==0 && strlen(TempOutputDataname)>0)		//this file output was already asked for user
				LocalUserFileName = TempOutputDataname
			else
				Prompt LocalUserFileName, "No name for this sample selected, data name is "+ LoadedFile
				DoPrompt /HELP="Input name for the data to be stored, max 20 characters" "Input name for the 1D data", LocalUserFileName
				if(V_Flag)
					abort
				endif
				TempOutputDataname = LocalUserFileName
				TempOutputDatanameUserFor = LoadedFile
			endif
			if(exists("root:Packages:Nika1101:SupExChar"))
				nvar supexchar = root:Packages:Nika1101:SupExChar
				if(supexchar)
					UseName=LocalUserFileName[0,25]
				else
					UseName=LocalUserFileName[0,18]+"_"+CurOrient
				endif
			else
				UseName=LocalUserFileName[0,18]+"_"+CurOrient
			endif
		else
			if(exists("root:Packages:Nika1101:SupExChar"))
				nvar supexchar = root:Packages:Nika1101:SupExChar
				if(supexchar)
					UseName=UserFileName[0,25]
				else
					UseName=UserFileName[0,22]+"_"+CurOrient[0,5]
				endif
			else
				UseName=UserFileName[0,22]+"_"+CurOrient[0,5]
			endif
		endif
	endif
	UseName=cleanupName(UseName, 1 )
	LongUseName="root:SAS:"+possiblyQuoteName(UseName)
	
	//split for code for line profile and sectors...
	if(stringmatch(CurOrient, "*LP*") || stringmatch(CurOrient, "*GH*") || stringmatch(CurOrient, "*GV*")  )		//Line profile code goes here...***************
		//NI1A_RemoveInfNaNsFrom8Waves(LineProfileIntensity,LineProfileError,LineProfileQ,LineProfileQy,LineProfileYValsPix,LineProfileQz,LineProfileQx,tempWv1234 )
		// replaced antiquated function with following for loop  (Eliot)
		variable j, imax = numpnts(LineProfileIntensity)
		for(j=imax-1;j>=0;j-=1)
			if(LineProfileIntensity[j]*LineProfileError[j]*LineProfileQ[j]*LineProfileQx[j]*LineProfileQy[j]*LineProfileQz[j]*LineProfileQxy[j]*LineProfileXi[j]*LineProfileTh[j]*0 != 0) //*LineProfileZValsPix[j]*LineProfileYValsPix[j]*tempWv1234[j]
				Deletepoints j, 1, LineProfileIntensity,LineProfileError,LineProfileQ,LineProfileQx,LineProfileQy,LineProfileQz,LineProfileQxy,LineProfileXi,LineProfileTh //,LineProfileZValsPix,LineProfileYValsPix,tempWv1234
			endif
		endfor
		
		
		
		
		SVAR LineProf_CurveType=root:Packages:Convert2Dto1D:LineProf_CurveType	
		if(StoreDataInIgor)
				NewDataFolder/O/S root:SAS
				if(DataFolderExists(LongUseName) && !OverwriteDataIfExists)
					DoALert 1, "This data folder exists, overwrite?"
					if (V_Flag==2)
						Abort
					endif
				endif
				NewDataFolder/S/O $(LongUseName)
				Duplicate/O LineProfileIntensity, $cleanupname("r_"+UseName,1)
				Duplicate/O LineProfileQ, $cleanupname("q_"+UseName,1)
				Duplicate/O LineProfileError, $cleanupname("s_"+UseName,1)
				Duplicate/O LineProfileQy, $cleanupname("qy_"+UseName,1)
				Duplicate/O LineProfileQz, $cleanupname("qz_"+UseName,1)
				Duplicate/O LineProfileQx, $cleanupname("qx_"+UseName,1)
				Duplicate/O LineProfileQxy, $cleanupname("xy_"+UseName,1)
				Duplicate/O LineProfileXi, $cleanupname("Xi_"+UseName,1)
				Duplicate/O LineProfileTh, $cleanupname("Th_"+UseName,1)
				if(stringmatch(LineProf_CurveType, "El*"))
					duplicate /o lineProfileQ, $cleanupname("Ph_"+UseName,0)
					wave anglewave = $cleanupname("Ph_"+UseName,0)
					anglewave = acos(lineProfileQz/LineProfileQ)
					//ChangetoaddANGLE Eliot
				endif
//				if(stringmatch(LineProf_CurveType, "GI*"))
//					Duplicate/O LineProfileQx, $("qx_"+UseName)	
//				endif		
		endif
		if(ExportDataOutOfIgor)
			OldNote=note(LineProfileIntensity)
			ItemsInLst=ItemsInList(OldNote)
	
			make/T/O/N=(ItemsInLst) TextWv 		
			For (i=0;i<ItemsInLst;i+=1)
				TextWv[i]="#   "+stringFromList(i,OldNote)
			endfor
			Duplicate/O LineProfileQ, LineProfQ
			Duplicate/O LineProfileQx, LineProfQx
			Duplicate/O LineProfileQy, LineProfQy
			Duplicate/O LineProfileQz, LineProfQz
			Duplicate/O LineProfileQxy, LineProfQxy
			Duplicate/O LineProfileQxz, LineProfQxz
			Duplicate/O LineProfileXi, LineProfXi
			Duplicate/O LineProfileXi, LineProfTh
//			if(stringmatch(LineProf_CurveType, "GI*"))
//				Duplicate/O LineProfileQx, LineProfQx
//				redimension/S LineProfQx
//			endif
			Duplicate/O LineProfileIntensity,LineProfIntensity
			Duplicate/O LineProfileError,LineProfError
			Redimension/S LineProfQ, LineProfQx,LineProfQy, LineProfQz, LineProfQxy,LineProfQxz,LineProfXi,LineProfTh, LineProfIntensity, LineProfError
						
			Save/G/O/M="\r\n"/P=Convert2Dto1DOutputPath TextWv as (UseName+".dat")
//			if(stringmatch(LineProf_CurveType, "GI*"))
			Save/A/W/J/M="\r\n"/P=Convert2Dto1DOutputPath LineProfQ, LineProfQx, LineProfQy, LineProfQz, LineProfQxy, LineProfQxz, LineProfXi, LineProfTh, LineProfIntensity, LineProfError as (UseName+".dat")			
//			else
//				Save/A/W/J/M="\r\n"/P=Convert2Dto1DOutputPath LineProfQ, LineProfQy, LineProfQz, LineProfIntensity, LineProfError as (UseName+".dat")			
//			endif		
			KillWaves/Z TextWv, LineProfQ, LineProfQy,LineProfQx, LineProfQz,LineProfQxy ,LineProfQxz ,LineProfXi, LineProfIntensity, LineProfError, LineProfTh
		endif

		if(DisplayDataAfterProcessing)
			SVAR LineProf_CurveType = root:Packages:Convert2Dto1D:LineProf_CurveType
			
			if(stringmatch(LineProf_CurveType,"Horizontal Line"))
				Wave Int=$cleanupname("r_"+UseName,1)
				Wave Qvec=$cleanupname("qy_"+UseName,1)
				Wave err=$cleanupname("s_"+UseName,1)
				NI1A_DisplayLineoutAfterProc(int,Qvec,Err,1,1)			
			elseif(stringmatch(LineProf_CurveType,"GI_Horizontal Line"))
				Wave Int=$cleanupname("r_"+UseName,1)
				Wave Qvec=$cleanupname("xy_"+UseName,1)
				Wave err=$cleanupname("s_"+UseName,1)
				NI1A_DisplayLineoutAfterProc(int,Qvec,Err,1,1)
			elseif(stringmatch(LineProf_CurveType,"Vertical Line")||stringmatch(LineProf_CurveType,"GI_Vertical Line"))
				Wave Int=$cleanupname("r_"+UseName,1)
				Wave Qvec=$cleanupname("qz_"+UseName,1)
				Wave err=$cleanupname("s_"+UseName,1)
				NI1A_DisplayLineoutAfterProc(int,Qvec,Err,1,1)
			elseif(stringmatch(LineProf_CurveType,"Ellipse"))
				Wave Int=$cleanupname("r_"+UseName,1)
				if(UseGrazingIncidence)
					Wave Avec=$cleanupname("Xi_"+UseName,1)
				else
					Wave Avec=$cleanupname("Th_"+UseName,1)
				endif
				Wave err=$cleanupname("s_"+UseName,1)
				NI1A_DisplayLineoutAfterProc(int,Avec,Err,1,4)
			else
				Wave Int=$cleanupname("r_"+UseName,1)
				Wave Qvec=$cleanupname("qy_"+UseName,1)
				Wave err=$cleanupname("s_"+UseName,1)
				NI1A_DisplayLineoutAfterProc(int,Qvec,Err,1,1)
			endif
		endif
		KillWaves/Z tempWv1234
	else		//sectors profiles goes here. *****************
		NI1A_RemoveInfNaNsFrom8Waves(Intensity,Qvector,Error,Qsmearing,TwoTheta,TwoThetaWidth,Dspacing,DspacingWidth )	
		if(StoreDataInIgor)
			NewDataFolder/O/S root:SAS
			if(DataFolderExists(LongUseName) && !OverwriteDataIfExists)
				DoALert 1, "This data folder exists, overwrite?"
				if (V_Flag==2)
					Abort
				endif
			endif
			NewDataFolder/S/O $(LongUseName)
			if (UseQvector)
				Duplicate/O Intensity, $cleanupname("r_"+UseName,1)
				Duplicate/O Qvector, $cleanupname("q_"+UseName,1)
				Duplicate/O Error, $cleanupname("s_"+UseName,1)
				Duplicate/O Qsmearing, $cleanupname("w_"+UseName,1)
			elseif(UseTheta)
				Duplicate/O Intensity, $("r_"+UseName)
				Duplicate/O TwoTheta, $("t_"+UseName)
				Duplicate/O Error, $("s_"+UseName)
				Duplicate/O TwoThetaWidth, $("w_"+UseName)
			elseif(UseDspacing)
				Duplicate/O Intensity, $("r_"+UseName)
				Duplicate/O Dspacing, $("d_"+UseName)
				Duplicate/O Error, $("s_"+UseName)
				Duplicate/O DspacingWidth, $("w_"+UseName)		
			else
				abort "Error - no output type selected"
			endif
			
		endif
		//Convert2Dto1DOutputPath
		if(ExportDataOutOfIgor)
			OldNote=note(Intensity)
			ItemsInLst=ItemsInList(OldNote)
			NVAR/Z SaveGSASdata=root:Packages:Convert2Dto1D:SaveGSASdata
			if(!NVAR_Exists(SaveGSASdata))
				variable/g SaveGSASdata=0
			endif
			
	
			make/T/O/N=(ItemsInLst) TextWv 		
			if(!(UseTheta && SaveGSASdata))
				For (i=0;i<ItemsInLst;i+=1)
					TextWv[i]="#   "+stringFromList(i,OldNote)
				endfor
				Save/G/O/M="\r\n"/P=Convert2Dto1DOutputPath TextWv as (UseName+".dat")
			endif
			if (UseQvector)
				Save/A/G/M="\r\n"/P=Convert2Dto1DOutputPath Qvector,Intensity,Error,Qsmearing as (UseName+".dat")
			elseif(UseTheta)
				if(SaveGSASdata)
					//first create header...
					Redimension/N=2 TextWV
					Duplicate/O TwoTheta, TwoThetaCentidegrees
					TwoThetaCentidegrees*=100
					//create the text header... 
					String Header1="BANK 1 "+num2str(numpnts(TwoTheta))+" "+num2str(numpnts(TwoTheta))+" CONS "
					variable StarANgle=TwoThetaCentidegrees[0]
					variable StepSize=(TwoThetaCentidegrees(numpnts(TwoTheta)-1) - TwoThetaCentidegrees[0])/(numpnts(TwoTheta)-1)
					string TempHeader
					sprintf TempHeader, "%E %E", StarANgle, StepSize
					Header1+=TempHeader
					Header1+=" 0 0 FXYE"
					TextWv[0]=stringFromList(0,OldNote)+";"+stringFromList(1,OldNote)
					TextWV[1]=Header1
					Save/G/O/M="\r\n"/P=Convert2Dto1DOutputPath TextWv as (UseName+".GSA")
					Save/A=2/G/M="\r\n"/P=Convert2Dto1DOutputPath TwoThetaCentidegrees,Intensity,Error as (UseName+".GSA")
					KillWaves TwoThetaCentidegrees
				else
					Save/A/G/M="\r\n"/P=Convert2Dto1DOutputPath TwoTheta,Intensity,Error,TwoThetaWidth as (UseName+".dat")
				endif		
			elseif(UseDspacing)
				Save/A/G/M="\r\n"/P=Convert2Dto1DOutputPath Dspacing,Intensity,Error,DspacingWidth as (UseName+".dat")
			else
				abort "Error - no output type selected"
			endif
			KillWaves TextWv
		endif
		
		if(DisplayDataAfterProcessing)
			if (UseQvector)
				Wave Int=$("r_"+UseName)
				Wave Qvec=$("q_"+UseName)
				Wave err=$("s_"+UseName)
				NI1A_DisplayLineoutAfterProc(int,Qvec,Err,1,1)
			elseif(UseTheta)
				Wave Int=$("r_"+UseName)
				Wave TwoTheta=$("t_"+UseName)
				Wave err=$("s_"+UseName)
				NI1A_DisplayLineoutAfterProc(int,TwoTheta,Err,1,3)
			elseif(UseDspacing)
				Wave Int=$("r_"+UseName)
				Wave Dspacing=$("d_"+UseName)
				Wave err=$("s_"+UseName)
				NI1A_DisplayLineoutAfterProc(int,Dspacing,Err,1,2)
			else
				abort "Error - no output type selected"
			endif
		endif
	endif		//end of sectors part...
	setDataFolder OldDf
end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1A_DisplayLineoutAfterProc(int,Qvec,Err,NumOfWavesToKeep,typeGraph)
	wave int,Qvec,Err
	variable NumOfWavesToKeep
	variable typeGraph	//1 for q, 2 for d, and 3 for twoTheta
	NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
	
	if(typeGraph==1)
		DoWindow LineuotDisplayPlot_Q
		if(V_Flag)
			DoWindow/F LineuotDisplayPlot_Q
			appendToGraph Int vs Qvec 
		else
			Display/K=1 /W=(348,368,828,587.75) Int vs Qvec as "LineoutDisplayPlot_Q"	
			DoWIndow/C LineuotDisplayPlot_Q
			ModifyGraph log=1
			Label left "Intensity"
			Label bottom "Q vector [A\\S-1\\M]"
			Doupdate
		endif		
	elseif(typeGraph==2)
		DoWindow LineuotDisplayPlot_D
		if(V_Flag)
			DoWindow/F LineuotDisplayPlot_D
			appendToGraph Int vs Qvec 
		else
			Display/K=1 /W=(348,368,828,587.75) Int vs Qvec as "LineoutDisplayPlot_D"	
			DoWIndow/C LineuotDisplayPlot_D
			ModifyGraph log=0
			Label left "Intensity"
			Label bottom "d spacing [A]"
			Doupdate
		endif		
	elseif(typeGraph==3)
		DoWindow LineuotDisplayPlot_T
		if(V_Flag)
			DoWindow/F LineuotDisplayPlot_T
			appendToGraph Int vs Qvec 
		else
			Display/K=1 /W=(348,368,828,587.75) Int vs Qvec as "LineoutDisplayPlot_T"	
			DoWIndow/C LineuotDisplayPlot_T
			ModifyGraph log=0
			Label left "Intensity"
			Label bottom "Two theta [degrees]"
			Doupdate
		endif		
	elseif(typeGraph==4)
		DoWindow LineuotDisplayPlot_X
		if(V_Flag)
			DoWindow/F LineuotDisplayPlot_X
			appendToGraph Int vs Qvec 
		else
			Display/K=1 /W=(10.5,233,1116.75,684.5) Int vs Qvec as "LineoutDisplayPlot_X"	
			DoWIndow/C LineuotDisplayPlot_X
			ModifyGraph log=0
			Label left "Intensity"
			if(Usegrazingincidence)
				Label bottom "Chi (pole figure) [degrees]"
			else
				Label bottom "Phi (azimuthal angle) [degrees]"
			endif
			Doupdate
		endif		
	else
		Abort "error in NI1A_DisplayLineoutAfterProc"
	endif
		//ModifyGraph/Z rgb[0]=(0,0,0), rgb[1]=(65280,0,0), rgb[2]=(0,65280,0),rgb[3]=(0,0,65280), rgb[4]=(52224,0,41728), rgb[5]=(52224,52224,0), rgb[6]=(0,0,39168)
		colorlines("SpectrumBlack")
		//Legend/C/N=text0/A=RT
		ModifyGraph mirror=1,grid=1,tick=2,minor=1,sep=10,standoff=0,gridStyle=3,lsize=1.5,margin(left)=57,gfSize=12
End

//end
//Function NI1A_DoCircularAveraging(DataWave,QvectorWave,MaskWave,imin, imax, jmin, jmax)
//	wave DataWave, QvectorWave, MaskWave
//	variable imin, imax, jmin, jmax
//	
//	string OldDf=GetDataFolder(1)
//	setDataFolder root:Packages:Convert2Dto1D
//	Wave Intensity, SqIntensity, NumberOfPoints, Error, QvectorLimits
//	Intensity=0
//	SqIntensity=0
//	NumberOfPoints=0
//	Error=0
//	variable Qpoint, i, j
// //variable StartT=ticks
//// variable calculations=0
//	For(i=0;i<imax;i+=1)
//		For(j=0;j<jmax;j+=1)
//                       // calculations+=1
//			if (MaskWave[i][j])						//Mask wave contains 1s for points to be counted
//				Qpoint = BinarySearch(QvectorLimits, QvectorWave[i][j])
//				Intensity[Qpoint]+=DataWave[i][j]
//				SqIntensity[Qpoint]+=DataWave[i][j] * DataWave[i][j]
//				NumberOfPoints[Qpoint]+=1
//			endif
//		endfor
//	endfor
////print (ticks - startT)/60
////print calculations
//	Intensity = Intensity/NumberOfPoints
//	Error = sqrt(SqIntensity[p] - NumberOfPoints[p] * Intensity[p] * Intensity[p]) / (NumberOfPoints[p] -1)
//	//Swave=sqrt((Rsquaredwave - Nwave*Rwave*Rwave)/(Nwave-1))
//	setDataFolder OldDf
//end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1A_CCD21D_SetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

		if(cmpstr(ctrlName,"SampleToCCDdistance")==0)
				//here goes what happens
		endif


End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1A_setupData(updateLUT)
		variable updateLUT

		wave QVectorWave=root:Packages:Convert2Dto1D:QVectorWave
		wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
		wave M_ROIMask=root:Packages:Convert2Dto1D:M_ROIMask
		wave EmptyData=root:Packages:Convert2Dto1D:EmptyData
		wave DarkCurrentWave=root:Packages:Convert2Dto1D:DarkField

		Duplicate/O CCDImageToConvert, CorrectedDataWave
		Redimension/S CorrectedDataWave
		variable transmission=0.991
		CorrectedDataWave=(1/transmission)*(CCDImageToConvert-DarkCurrentWave) - (EmptyData-DarkCurrentWave)

		NI1A_CreateConversionLUT(updateLUT, QVectorWave, CorrectedDataWave,M_ROIMask )
		killwaves/Z temp2D, CorrectedDataWave
end


Function NI1A_CreateConversionLUT(updateLUT, QVectorWave, CCDImageToConvert,M_ROIMask )
		variable updateLUT
		wave QVectorWave, CCDImageToConvert,M_ROIMask
		
	string OldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	nvar wavelength
	string wavelengths = num2str(round(100*wavelength))
	if(updateLUT)
		NI1A_CreateLUT("C",wavelengths)
	endif
		Wave LUT=root:Packages:Convert2Dto1D:LUT
		Wave HistWave=root:Packages:Convert2Dto1D:HistWave
		variable NumberOfPoints=200  //this is number of points in Q
	make/O/N=(NumberOfPoints) NewQwave, NewIntWave, NewIntErrorWave
	NewQwave=p*0.001
	NewIntWave=0
	NewIntErrorWave=0
	
	variable i, j, counter, numbins
	Duplicate/O LUT, tempInt
	tempInt = CCDImageToConvert
	IndexSort LUT, tempInt
	Duplicate/O tempInt, TempIntSqt
	TempIntSqt = tempInt^2
	counter = HistWave[0]
	For(j=1;j<NumberOfPoints;j+=1)
		numbins = HistWave[j]
		NewIntWave[j] = sum(tempInt, pnt2x(tempInt,Counter), pnt2x(tempInt,Counter+numbins))
		NewIntErrorWave[j] = sum(TempIntSqt, pnt2x(tempInt,Counter), pnt2x(tempInt,Counter+numbins))
		Counter+=numbins
	endfor
	NewIntWave/=HistWave
	NewIntErrorWave=sqrt(NewIntErrorWave-HistWave*NewIntWave*NewIntWave)/(HistWave-1)
	killwaves/Z tempInt, TempIntSqt, temp2D, tempQ, NewQwave
end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

