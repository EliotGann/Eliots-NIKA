#pragma rtGlobals=1		// Use modern global access method.



Function EGNA_StoreLoadCurSettingPnl()

	string OldDf=GetDataFolder(1)
	SetDataFolder root:Packages:Convert2Dto1D
	//mini initialization for this panel
	DoWindow EGNA_SaveLoadPanel
	if(!V_Flag)
		Wave/Z/T SaveLoadDataAvailable
		if(!WaveExists(SaveLoadDataAvailable))
			make/O/N=0/T SaveLoadDataAvailable, ConfigFileContent	
		endif
		Execute("EGNA_SaveLoadPanel()")
	else
		DoWindow/F EGNA_SaveLoadPanel
	endif

	setDataFolder OldDf
end

Proc EGNA_SaveLoadPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(236,50,605,338) as "Save and Recall Configurations"
	DoWindow/C EGNA_SaveLoadPanel
	SetDrawLayer UserBack
	SetDrawEnv fsize= 16,fstyle= 3,textrgb= (0,0,65280)
	DrawText 38,22,"Save and Load configuration files"
	Button SelectSaveLoadPath,pos={84,31},size={150,20},proc=EGNA_SaveLoadButtonProc,title="Select data path"
	Button SelectSaveLoadPath,help={"Select path to your configuration files. You can create new folders by typing them in."}
	Button SelectSaveLoadPath,font="Times New Roman"
	ListBox SavedDataList,pos={3,76},size={164,117},proc=EGNA_SaveLoadListBoxProc
	ListBox SavedDataList,listWave=root:Packages:Convert2Dto1D:SaveLoadDataAvailable
	ListBox SavedDataList,mode= 1,selRow= 5
	ListBox ContentOfTheConfigFile,pos={171,77},size={192,116}
	ListBox ContentOfTheConfigFile,font="Times New Roman",fSize=9
	ListBox ContentOfTheConfigFile,listWave=root:Packages:Convert2Dto1D:ConfigFileContent
	Button SaveCurrentConfig,pos={13,242},size={130,20},proc=EGNA_SaveLoadButtonProc,title="Save configuration"
	Button SaveCurrentConfig,help={"Store current configuration into the file"}
	Button SaveCurrentConfig,font="Times New Roman"
	Button LoadConfiguration,pos={185,241},size={130,20},proc=EGNA_SaveLoadButtonProc,title="Load configuration"
	Button LoadConfiguration,help={"Load data from saved configuration file"}
	Button LoadConfiguration,font="Times New Roman"
	SetVariable Convert2Dto1DConfigPath,pos={3,58},size={350,15},disable=2,title="Path:   "
	SetVariable Convert2Dto1DConfigPath,help={"This is currently selected path to configuration files."}
	SetVariable Convert2Dto1DConfigPath,font="Times New Roman",fSize=10,frame=0
	SetVariable Convert2Dto1DConfigPath,limits={-inf,inf,0},value= root:Packages:Convert2Dto1D:ConfigurationDataPath
	SetVariable LastLoadedConfigFile,pos={4,268},size={350,15},disable=2,title="Last loaded config file: "
	SetVariable LastLoadedConfigFile,help={"Name of the last loaded configuration file. It may have been modified by you!!!"}
	SetVariable LastLoadedConfigFile,font="Times New Roman",fSize=10,frame=0
	SetVariable LastLoadedConfigFile,limits={-inf,inf,0},value= root:Packages:Convert2Dto1D:LastLoadedConfigFile
	SetVariable ConfFileUserComment,pos={5,220},size={350,17},title="New Conf file comment:"
	SetVariable ConfFileUserComment,help={"Input new comment for the Configuration file. Keep it short. "}
	SetVariable ConfFileUserComment,font="Times New Roman",fSize=11
	SetVariable ConfFileUserComment,limits={-inf,inf,0},value= root:Packages:Convert2Dto1D:ConfFileUserComment
	SetVariable ConfFileUserName,pos={24,198},size={200,17},title="New Conf file name:"
	SetVariable ConfFileUserName,help={"Input new name for the user file. .dat will be added. SHORT name"}
	SetVariable ConfFileUserName,font="Times New Roman",fSize=11
	SetVariable ConfFileUserName,limits={-inf,inf,0},value= root:Packages:Convert2Dto1D:ConfFileUserName
EndMacro

Function EGNA_SaveLoadButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	if(cmpstr(ctrlName,"SelectSaveLoadPath")==0)
		NewPath/C/O/M="Select folder with config. data. Can create folders - just type them in." Convert2Dto1DConfigPath
		SVAR ConfigurationDataPath=root:Packages:Convert2Dto1D:ConfigurationDataPath
		PathInfo Convert2Dto1DConfigPath
		ConfigurationDataPath=S_path
		EGNA_UpdateSaveLoadListBox()
		EGNA_ShowUserConfigContent()
	endif
	if(cmpstr(ctrlName,"SaveCurrentConfig")==0)
		EGNA_CopyConfigurationOut()
		EGNA_UpdateSaveLoadListBox()
	endif
	if(cmpstr(ctrlName,"LoadConfiguration")==0)
		controlInfo/W=EGNA_SaveLoadPanel SavedDataList
		if(V_Value>=0)
			EGNA_LoadSavedConfigContent(V_Value)
		endif
	endif


End


Function EGNA_LoadSavedConfigContent(row)
	variable row
	
	string OldDf=GetDataFolder(1)
	//initialize definitions of variables in case user has old experiment nad new config file..
	EGNA_Initialize2Dto1DConversion()
	SetDataFolder root:Packages:Convert2Dto1D
	Wave/T SaveLoadDataAvailable=root:Packages:Convert2Dto1D:SaveLoadDataAvailable
	string LoadFile=SaveLoadDataAvailable[row]+".dat"
	SVAR LastLoadedConfigFile=root:Packages:Convert2Dto1D:LastLoadedConfigFile
	
	
	LoadWave/J/Q/O/P=Convert2Dto1DConfigPath/K=2/N=ConfigFileContent/V={"\t"," $",0,0} LoadFile
	LastLoadedConfigFile = LoadFile
	Wave/T ConfigFileContent0=root:Packages:Convert2Dto1D:ConfigFileContent0
	string NewConfiguration=ConfigFileContent0[0]
	KillWaves ConfigFileContent0
	EGNA_RecoverStoredToolSetting(NewConfiguration)
	setDataFolder OldDf

end

Function EGNA_CopyConfigurationOut()
	
	setDataFolder root:Packages:Convert2Dto1D
	variable i
	SVAR ConfFileUserComment=root:Packages:Convert2Dto1D:ConfFileUserComment
	SVAR ConfFileUserName=root:Packages:Convert2Dto1D:ConfFileUserName
	string ExportName, Overwrite, testName, NbkNm
	NbkNm = "TestNbk"
//	ExportName="SavedConfig"+time()
//	Prompt ExportName, "Input appropriate export name (20 chars)"
//	DoPrompt "Input needed", ExportName
//	if(V_flag)
//		abort
//	endif
	PathInfo Convert2Dto1DConfigPath
	if(!V_Flag)
		NewPath/M="Select path for the config file"/Q Convert2Dto1DConfigPath 
	endif
	ExportName=ConfFileUserName+".dat"
			//check that notebook does not exist
		close/A
		OpenNotebook /Z/P=Convert2Dto1DConfigPath /V=0 /N=TestNbk ExportName
			if (V_Flag==0)	//notebook opened, therefore it exists
				Prompt Overwrite, "The config file exists, do you want to ovewrite it?", popup, "Yes;No"
				DoPrompt "Overwrite the existing configuration file?", Overwrite
				if (V_Flag)
					abort
				endif
				if (cmpstr(Overwrite,"Yes")==0)
					DoWindow /D/K testNbk
				else
					DoWindow /K testNbk
					ExportName = ExportName[0,strlen(ExportName)-5]
					Prompt ExportName, "Change name of config file being exported"
					DoPrompt "Change name for exported style", ExportName
					if (V_Flag)
						abort
					endif
					ExportName=ExportName+".dat"
				endif
			endif
			
			NewNotebook /F=0 /V=0/N=$NbkNm 
			Notebook $NbkNm selection={endOfFile, endOfFile}
			Notebook $NbkNm text=EGNA_RecordCurrentToolSetting()
			SaveNotebook /S=3/O/P=Convert2Dto1DConfigPath $NbkNm as ExportName
			DoWindow /K testNbk
end

Function EGNA_SaveLoadListBoxProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
					//5=cell select with shift key, 6=begin edit, 7=end

	if(event==2)
		EGNA_ShowUserConfigContent()
	endif
	return 0
End

Function EGNA_ShowUserConfigContent()
	
	string OldDf=GetDataFolder(1)
	SetDataFolder root:Packages:Convert2Dto1D


	Wave/T SaveLoadDataAvailable=root:Packages:Convert2Dto1D:SaveLoadDataAvailable
	Wave/T ConfigFileContent=root:Packages:Convert2Dto1D:ConfigFileContent
	if(numpnts(SaveLoadDataAvailable)<1)
		redimension/N=0 ConfigFileContent
		abort
	endif
	variable row
	controlInfo/W=EGNA_SaveLoadPanel SavedDataList
	row=V_Value
	if(row>=0)
		string LoadFile=SaveLoadDataAvailable[row]+".dat"
		
		LoadWave/J/Q/O/P=Convert2Dto1DConfigPath/K=2/N=ConfigFileContent/V={"\t"," $",0,0} LoadFile
		Wave/T ConfigFileContent0=root:Packages:Convert2Dto1D:ConfigFileContent0
		string NewConfiguration=ConfigFileContent0[0]
		KillWaves ConfigFileContent0
		string NewConfigVars=StringByKey("Variables", NewConfiguration , ">" , "<")
		string NewConfigStrings=StringByKey("Strings", NewConfiguration , ">" , "<")
		variable i, imax=ItemsInList(NewConfigVars,";")+ItemsInList(NewConfigStrings,";")+2
		redimension/N=(imax) ConfigFileContent
		ConfigFileContent[0]=StringByKey("UserComment", NewConfiguration , ">" , "<")
		For(i=1;i<ItemsInList(NewConfigVars,";")+1;i+=1)
			ConfigFileContent[i]=StringFromList(i-1,NewConfigVars,";")
		endfor
		For(i=ItemsInList(NewConfigVars,";")+1;i<imax;i+=1)
			ConfigFileContent[i]=StringFromList(i-ItemsInList(NewConfigVars,";")-1,NewConfigStrings,";")
		endfor
	else
		ConfigFileContent=""
	endif

	setDataFolder OldDf

end


Function EGNA_UpdateSaveLoadListBox()

		Wave/T  SaveLoadDataAvailable=root:Packages:Convert2Dto1D:SaveLoadDataAvailable
		string ListOfAvailableConfigs
		PathInfo Convert2Dto1DConfigPath
		if(V_Flag==0)
			abort
		endif
		ListOfAvailableConfigs=IndexedFile(Convert2Dto1DConfigPath,-1,".dat")
		redimension/N=(ItemsInList(ListOfAvailableConfigs)) SaveLoadDataAvailable
		variable i
		For(i=0;i<ItemsInList(ListOfAvailableConfigs);i+=1)
			SaveLoadDataAvailable[i]=StringFromList(0,StringFromList(i, ListOfAvailableConfigs),".")
		endfor
		sort SaveLoadDataAvailable, SaveLoadDataAvailable
end	

Function/S EGNA_RecordCurrentToolSetting()
	//returns string with the current tool setting.

	string OldDf=GetDataFolder(1)
	SetDataFolder root:Packages:Convert2Dto1D

	string SettingStr=""
	SVAR ListOfVariables
	SVAR ListOfStrings
	SVAR/Z ListOfVariablesBC
	SVAR/Z ListOfStringsBC
	
	string ListOfVarsToLoad
	string ListOfStringsToLoad
	
	if(SVAR_exists(ListOfVariablesBC))
		ListOfVarsToLoad=ListOfVariables+ListOfVariablesBC
		ListOfStringsToLoad= ListOfStrings+ListOfStringsBC
	else
		ListOfVarsToLoad=ListOfVariables
		ListOfStringsToLoad= ListOfStrings
	endif
//	ListOfVariables="BeamCenterX;BeamCenterY;QvectorNumberPoints;QvectorMaxNumPnts;QbinningLogarithmic;SampleToCCDDistance;Wavelength;"
//	ListOfVariables+="PixelSizeX;PixelSizeY;StartDataRangeNumber;EndDataRangeNumber;XrayEnergy;"
//	ListOfVariables+="SampleThickness;SampleTransmission;UseI0ToCalibrate;SampleI0;EmptyI0;"
//	ListOfVariables+="UseSampleThickness;UseSampleTransmission;UseI0ToCalibrate;UseSampleI0;UseEmptyI0;"
//	ListOfVariables+="UseCorrectionFactor;UseMask;UseDarkField;UseEmptyField;UseSubtractFixedOffset;SubtractFixedOffset;"
//	ListOfVariables+="UseSampleMeasTime;UseEmptyMeasTime;UseDarkMeasTime;UsePixelSensitivity;UseMonitorForEF;"
//	ListOfVariables+="SampleMeasurementTime;BackgroundMeasTime;EmptyMeasurementTime;"
//	ListOfVariables+="CorrectionFactor;DezingerRatio;DezingerCCDData;DezingerEmpty;DezingerDarkField;DezingerHowManyTimes;"
//	ListOfVariables+="DoCircularAverage;StoreDataInIgor;ExportDataOutOfIgor;Use2DdataName;DisplayDataAfterProcessing;"
//	ListOfVariables+="DoSectorAverages;NumberOfSectors;SectorsStartAngle;SectorsHalfWidth;SectorsStepInAngle;"
//	ListOfVariables+="ImageRangeMin;ImageRangeMax;ImageRangeMinLimit;ImageRangeMaxLimit;ImageDisplayLogScaled;"
//	ListOfVariables+="A2DImageRangeMin;A2DImageRangeMax;A2DImageRangeMinLimit;A2DImageRangeMaxLimit;A2DLineoutDisplayLogInt;A2DmaskImage;"
//	ListOfVariables+="RemoveFirstNColumns;RemoveLastNColumns;RemoveFirstNRows;RemoveLastNRows;MaskDisplayLogImage;"
//	ListOfVariables+="OverwriteDataIfExists;SectorsNumSect;SectorsSectWidth;SectorsGraphStartAngle;SectorsGraphEndAngle;"
//	ListOfVariables+="DisplayBeamCenterEG_N2DGraph;DisplaySectorsEG_N2DGraph;"
//	ListOfVariables+="UseQvector;UseTheta;UseDspacing;"
//	ListOfVariables+="UserThetaMin;UserThetaMax;UserDMin;UserDMax;UserQMin;UserQMax;"
//	ListOfVariables+="DoGeometryCorrection;InvertImages;"
//	//and now the function calls variables
//	ListOfVariables+="UseSampleThicknFnct;UseSampleTransmFnct;UseSampleMonitorFnct;UseSampleCorrectFnct;UseSampleMeasTimeFnct;"
//	ListOfVariables+="UseEmptyTimeFnct;UseBackgTimeFnct;UseEmptyMonitorFnct;"
//	
//
//	ListOfStrings="CurrentInstrumentGeometry;DataFileType;DataFileExtension;MaskFileExtension;BlankFileExtension;CurrentMaskFileName;"
//	ListOfStrings+="CurrentEmptyName;CurrentDarkFieldName;CalibrationFormula;CurrentPixSensFile;OutputDataName;"
//	ListOfStrings+="CCDDataPath;CCDfileName;CCDFileExtension;FileNameToLoad;ColorTableName;CurrentMaskFileName;ExportMaskFileName;"
//	ListOfStrings+="ConfigurationDataPath;LastLoadedConfigFile;ConfFileUserComment;ConfFileUserName;"
//	ListOfStrings+="TempOutputDataname;TempOutputDatanameUserFor;"
//	ListOfStrings+="Fit2Dlocation;MainPathInfoStr;"
//	ListOfStrings+="SampleThicknFnct;SampleTransmFnct;SampleMonitorFnct;SampleCorrectFnct;SampleMeasTimeFnct;"
//	ListOfStrings+="EmptyTimeFnct;BackgTimeFnct;EmptyMonitorFnct;"
	SVAR ConfFileUserComment=root:Packages:Convert2Dto1D:ConfFileUserComment

	variable i
	string TempStr=""
	string settingStrVars=""
	string settingStrStrings=""
	For(i=0;i<ItemsInList(ListOfVarsToLoad);i+=1)
		TempStr=StringFromList(i, ListOfVarsToLoad)
		NVAR CurVal=$(TempStr)
		settingStrVars=ReplaceStringByKey(TempStr, settingStrVars, num2str(CurVal) , "=" , ";")
	endfor
	For(i=0;i<ItemsInList(ListOfStringsToLoad);i+=1)
		TempStr=StringFromList(i, ListOfStringsToLoad)
		SVAR CurValStr=$(TempStr)
		settingStrStrings=ReplaceStringByKey(TempStr, settingStrStrings, CurValStr , "=" , ";")
	endfor
	settingStr="UserComment>Comment="+ConfFileUserComment+"<Variables>"+settingStrVars+"<Strings>"+settingStrStrings+"<"
	return SettingStr
	setDataFolder OldDf
end

Function EGNA_RecoverStoredToolSetting(StoredSettings)
	string StoredSettings
	//recovers setting of the tool from stored in string.

	string OldDf=GetDataFolder(1)
	SetDataFolder root:Packages:Convert2Dto1D

	variable i
	string TempStr=""
	string settingStrVars=""
	string settingStrStrings=""
	settingStrVars=StringByKey("Variables", StoredSettings , ">" ,"<")
	settingStrStrings=StringByKey("Strings", StoredSettings , ">" ,"<")

	For(i=0;i<ItemsInList(settingStrVars,";");i+=1)
		TempStr=StringFromList(0, StringFromList(i,settingStrVars,";"),"=")
		NVAR/Z CurVal=$(TempStr)
			if(NVAR_Exists(CurVal))
				CurVal=NumberByKey(TempStr, settingStrVars, "=" , ";")
			endif
		endfor
	For(i=0;i<ItemsInList(settingStrStrings,";");i+=1)
		TempStr=StringFromList(0, StringFromList(i,settingStrStrings,";"),"=")
		SVAR/Z CurValStr=$(TempStr)
		if(SVAR_Exists(CurValStr))
			CurValStr=StringByKey(TempStr, settingStrStrings, "=" , ";")
		endif
	endfor
	//Now need to set all popus used - if they exist so they are in sync with the tool...
	DoWindow EGNA_Convert2Dto1DPanel
	if(V_Flag)
		Execute("PopupMenu Select2DDataType, win=EGNA_Convert2Dto1DPanel, mode=2,popvalue=root:Packages:Convert2Dto1D:DataFileExtension,value= #root:Packages:Convert2Dto1D:ListOfKnownExtensions")
		Execute("PopupMenu SelectBlank2DDataType, win=EGNA_Convert2Dto1DPanel, mode=2, popvalue=root:Packages:Convert2Dto1D:DataFileExtension")
		//now update textboxes... 
		SVAR MainPathInfoStr=root:Packages:Convert2Dto1D:MainPathInfoStr
		NewPath/C/O Convert2Dto1DDataPath, MainPathInfoStr
		EGNA_UpdateDataListBox()	
		ControlInfo/W=EGNA_Convert2Dto1DPanel Convert2Dto1DTab
		EGNA_TabProc("bla",V_Value)
	endif
	
	DoWindow EGN_CreateBmCntrFieldPanel
	if(V_Flag)
		Execute("PopupMenu BmCntrFileType, win=EGN_CreateBmCntrFieldPanel, mode=2, popvalue=root:Packages:Convert2Dto1D:DataFileExtension")
		Execute("PopupMenu BmCntrFileType, win=EGN_CreateBmCntrFieldPanel, mode=2, popvalue=root:Packages:Convert2Dto1D:BmCntrFileType")
		Execute("PopupMenu BmCalibrantName, win=EGN_CreateBmCntrFieldPanel, mode=2, popvalue=root:Packages:Convert2Dto1D:BmCalibrantName")
		Execute("PopupMenu BMFunctionName, win=EGN_CreateBmCntrFieldPanel, mode=2, popvalue=root:Packages:Convert2Dto1D:BMFunctionName")
		//now update textboxes... 
		SVAR BCPathInfoStr=root:Packages:Convert2Dto1D:BCPathInfoStr
		NewPath/C/O Convert2Dto1DBmCntrPath, BCPathInfoStr
		NI1BC_UpdateBmCntrListBox()
		ControlInfo/W=EGN_CreateBmCntrFieldPanel BmCntrTab
		NI1BC_TabProc("",V_Value)
	endif
	setDataFolder OldDf
end



