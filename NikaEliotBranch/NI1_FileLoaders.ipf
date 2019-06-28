#pragma rtGlobals=1		// Use modern global access method.
#pragma version=2.04

//2.0 updated for Nika 1.42
//2.01 updated ADSCS reader per request from PReichert@lbl.gov on 11/25/09
//2.02 added Pilatus reader per request from PReichert@lbl.com on 1/1/2010
//2.03 added ESRFedf   2/1/2010
//2.031 Eliot & Brian's additions through the multi I0 correction
string/g imagekeys

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1A_UniversalLoader(PathName,FileName,FileType,NewWaveName)
	string PathName,FileName,FileType,NewWaveName
	
	string OldDf=GetDataFOlder(1)
	setDataFOlder root:Packages:Convert2Dto1D
	
	PathInfo $(PathName)
	if(!V_Flag)
		Abort "Path to data set incorrectly" 
	endif
	if(stringmatch(FileName,"*--none--*")||stringmatch(Filetype,"---"))
		Abort 
	endif
	string FileNameToLoad
	string NewNote=""
	string testLine
	variable RefNum, NumBytes
	variable Offset
	string headerStr=""


	if(cmpstr(FileType,".tif")==0 || cmpstr(FileType,"tiff")==0)
		FileNameToLoad= FileName
		if(cmpstr(FileName[strlen(FileName)-4,inf],".tif")!=0 && cmpstr(FileName[strlen(FileName)-5,inf],".tiff")!=0)
			FileNameToLoad= FileName+ ".tif"
		endif
		ImageLoad/P=$(PathName)/T=tiff/O/N=$(NewWaveName) FileNameToLoad
		wave LoadedWvHere=$(NewWaveName)
		Redimension/N=(-1,-1,0) 	LoadedWvHere			//this is fix for 3 layer tiff files...
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+".tif"+";.tiff"+";"
		
	elseif(cmpstr(FileType,"BS_Suitcase_Tiff")==0)
		FileNameToLoad= FileName
		if(cmpstr(FileName[strlen(FileName)-4,inf],".tif")!=0 && cmpstr(FileName[strlen(FileName)-5,inf],".tiff")!=0)
			FileNameToLoad= FileName+ ".tif"
		endif
		ImageLoad/P=$(PathName)/T=tiff/O/N=$(NewWaveName) FileNameToLoad
		string detectortype = ""
		if(stringmatch(FileNameToLoad,"*Small and Wide Angle Synced CCD Detectors_saxs*"))
			detectortype= "Small Angle CCD Detector_"
		else
			detectortype = "Wide Angle CCD Detector_"
		endif
		variable imnum
		string st1
		splitstring /e="([0123456789]*).tif" FileNameToLoad, st1
		imnum = str2num(st1)
		if(imnum*0!=0)
			imnum = 0
		endif
		
		
		string teststring= indexedfile($(PathName),-1,".csv")
		string baselinestring = greplist(teststring,"^"+FileNametoLoad[0,8]+".*baseline")
		newdatafolder /o/s importdata
		LoadWave/Q/O/J/M/U={0,0,1,0}/D/A=wave/K=0/L={0,1,0,0,0}/P=$(PathName)  stringfromlist(0,baselinestring)
		wave /z datawave = $(stringfromlist(0,S_waveNames))
		if(waveexists(datawave))
			teststring = Colwavetostring(datawave)
			nvar pxsizex = root:Packages:Convert2Dto1D:PixelSizeX
			pxsizex = 0.015 * numberbykey(detectortype+ "cam_bin_x",teststring)
			nvar pxsizey = root:Packages:Convert2Dto1D:PixelSizeY
			pxsizey = 0.015 * numberbykey(detectortype+ "cam_bin_x",teststring)
			
			nvar SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
			SampleMeasurementTime = numberbykey(detectortype+ "cam_acquire_time",teststring)
			
			//this is only in case energy is not in the primary scan (it was not scanned), we can get the baseline energy
			nvar xrayenergy = root:Packages:Convert2Dto1D:XrayEnergy 
			xrayenergy = numberbykey("en_energy_setpoint",teststring)/1000
			nvar wavelength = root:Packages:Convert2Dto1D:Wavelength
			wavelength = 1.239/xrayenergy
			
			nvar Sampletransmission = root:Packages:Convert2Dto1D:SampleTransmission
			svar UserFileName=root:Packages:Convert2Dto1D:OutputDataName
			string imagenum
			splitstring /e="^([1234567890]*)-([^-]*)" filenametoload, imagenum,  userfilename
			UserFileName = cleanupname(userfilename,0)+"_"+num2str(round(xrayenergy*100000)/100)+"eV_"+detectortype[0] + "_" + imagenum + "_" + num2str(imnum)
			NewNote += teststring
		endif
		teststring= indexedfile($(PathName),-1,".csv")
		teststring = greplist(teststring,"^"+FileNametoLoad[0,8]+".*primary")
		LoadWave/Q/O/J/D/A/K=0/P=$(PathName)/W  stringfromlist(0,teststring)
		wave /z datawave = $(stringfromlist(0,S_waveNames))
		if(waveexists(datawave))
			nvar SampleI0=root:Packages:Convert2Dto1D:samplei0
			//extract /free datawave, testwave,  datawave*0==0
			//redimension /N=(dimsize(testwave,0)/3,3) testwave
			//matrixop /o colsums = sumcols(testwave)
			//SampleI0 = colsums[1]
			wave /z Izero_Mesh_Drain_Current, en_monoen_readback
			if(waveexists(Izero_Mesh_Drain_Current))
				SampleI0 = Izero_Mesh_Drain_Current[imnum]
			endif
			if(waveexists(en_monoen_readback))
				nvar xrayenergy = root:Packages:Convert2Dto1D:XrayEnergy 
				xrayenergy = en_monoen_readback[imnum]/1000
				nvar wavelength = root:Packages:Convert2Dto1D:Wavelength
				wavelength = 1.239/xrayenergy
			endif
			wave /z RSoXS_Diagnostic_Picoammeter_exposure_time
			if(waveexists(RSoXS_Diagnostic_Picoammeter_exposure_time))
				nvar SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
				samplemeasurementtime = RSoXS_Diagnostic_Picoammeter_exposure_time[imnum]
			endif
		endif
		setdatafolder ::
		killdatafolder /z importdata
		string metadata=""
		teststring= indexedfile($(PathName),-1,".jsonl")
		variable jsonfound=0
		string metadatafilename
		if(strlen(teststring) < 5)
			teststring= indexedfile($(PathName),-1,".json")
			if(strlen(teststring) > 4)
				jsonfound = 1
				metadatafilename = stringfromlist(0,greplist(teststring,"^"+FileNametoLoad[0,8]+".*json"))
			endif
		else
			jsonfound = 1
			metadatafilename = stringfromlist(0,greplist(teststring,"^"+FileNametoLoad[0,8]+".*jsonl"))
		endif
		if(jsonfound)
			metadata = addmetadatafromjson(PathName,"institution",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"project",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"proposal_id",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"sample",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"sample_desc",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"sampleid",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"sampleset",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"user",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"user_id",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"notes",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"uid",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"dim1",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"dim2",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"dim3",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"chemical_formula",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"density",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"project",metadatafilename,metadata)
			metadata = addmetadatafromjson(PathName,"project_desc",metadatafilename,metadata)
		else
			print "Currently can't load metadata json or jsonl file"
		endif	
		NewNote +=metadata+";"
			
		wave LoadedWvHere=$(NewWaveName)
		Redimension/N=(-1,-1,0) 	LoadedWvHere			//this is fix for 3 layer tiff files...
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+".tif"+";.tiff"+";"
	
	elseif(cmpstr(FileType,"AUSW")==0)
		//check if we need to look into XML file (and if XML file is loaded)
		
		string aufsave1 = getdatafolder(1) 
		setdatafolder root:Packages:NikaAUSW
		SVAR AUSW_XMPPath
		NVAR AUSW_XML_Loaded
		NVAR AUSW_Load_Params
		NVAR AUSW_Load_I0
		NVAR AUSW_Load_Exp
		NVAR AUSW_Load_GA
		if(SVAR_exists(AUSW_XMPPath)&&NVAR_exists(AUSW_XML_Loaded)&&NVAR_exists(AUSW_Load_Params)&&NVAR_exists(AUSW_Load_I0)&&NVAR_exists(AUSW_Load_Exp)&&NVAR_exists(AUSW_Load_GA))
			if( (AUSW_Load_Params || AUSW_Load_I0 || AUSW_Load_Exp || AUSW_Load_GA) && AUSW_XML_Loaded )
				//variable xmf = XMLopenfile (AUSW_XMPPath)
				string logvalues
				wave/t logfile
				variable endnum 
				if(waveexists(logfile))
					//AUSW_findimagebyname(xmf,FileName)
					findvalue /text=replacestring(".tif",FileName,"") logfile
					if(v_value<1)
						print "Error, file was found in the XML file, so no variables can be read from the log file"
					else
						logvalues = replacestring(" ",replacestring("\" ",replacestring("= \"",logfile[v_value],":"),";"),"")
						logvalues = replacestring("<LOGLINE ",replacestring("</LOGLINE>",logvalues,""),"")
						//print logvalues
						variable loglinenumber = v_value
						//wave sampleomegas, exposuretimes, I0s, Logfilewave
						SVAR/z AUSW_detectorpropertieslist
						if(AUSW_Load_Params &&svar_exists(AUSW_detectorpropertieslist)>0)
							nvar pxsizex = root:Packages:Convert2Dto1D:PixelSizeX
							nvar pxsizey = root:Packages:Convert2Dto1D:PixelSizeY
							nvar beamx = root:Packages:Convert2Dto1D:BeamCenterX
							nvar beamy = root:Packages:Convert2Dto1D:BeamCenterY
							nvar Horztilt = root:Packages:Convert2Dto1D:HorizontalTilt
							nvar Verttilt = root:Packages:Convert2Dto1D:VerticalTilt
							nvar SAD = root:Packages:Convert2Dto1D:SampleToCCDDistance
							nvar xrayenergy = root:Packages:Convert2Dto1D:XrayEnergy
							nvar wavelength = root:Packages:Convert2Dto1D:Wavelength
							pxsizex = numberbykey("PIXELSIZE",AUSW_detectorpropertieslist,"=",";")
							pxsizey = numberbykey("PIXELSIZE",AUSW_detectorpropertieslist,"=",";")
							beamx = numberbykey("BEAMX",AUSW_detectorpropertieslist,"=",";")
							beamy = numberbykey("YSIZE",AUSW_detectorpropertieslist,"=",";") - numberbykey("BEAMY",AUSW_detectorpropertieslist,"=",";")
							SAD = numberbykey("LENGTH",AUSW_detectorpropertieslist,"=",";")
							wavelength = numberbykey("WAVELENGTH",AUSW_detectorpropertieslist,"=",";")
							xrayenergy = 12.398424437/wavelength
						endif
						if(AUSW_load_I0)
							nvar SampleI0=root:Packages:Convert2Dto1D:samplei0
							samplei0= numberbykey("I0",logvalues)
						endif
						if(AUSW_load_exp)
							nvar SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
							samplemeasurementtime = numberbykey("EXPTIME",logvalues)
						endif
						if(AUSW_Load_GA)
							nvar GA = root:Packages:Convert2Dto1D:LineProf_GIIncAngle
							GA = numberbykey("SampleOmega",logvalues)
						endif
						//xmlclosefile(xmf,0)	
						//make /n=0 /o/t temptextwave
						//grep /e=replacestring("+",filename,"\\+") AUSW_XMPPath as temptextwave
						//logvalues = temptextwave[0]
						//logvalues = replacestring("<LOGLINE ",replacestring("\" ",replacestring("=\"", logvalues,"="),";"),"")
						//endnum = strsearch(logvalues,">",0)
						//logvalues = logvalues[0,endnum]
						NewNote += replacestring(":",logvalues,"=") + ";"
					endif
				else
					make /n=0 /o/t temptextwave
					//grep /e=replacestring("+",filename,"\\+") AUSW_XMPPath as temptextwave
					if(dimsize(temptextwave,0)>0)
						logvalues = temptextwave[0]
						string i0str,omegastr,expstr
						logvalues = replacestring("<LOGLINE ",replacestring("\" ",replacestring(" = \"", logvalues,"="),";"),"")
						endnum = strsearch(logvalues,">",0)
						logvalues = logvalues[0,endnum-1]
						//print logvalues
						string /g logvaluessave = logvalues
						if(AUSW_load_I0)
							nvar SampleI0=root:Packages:Convert2Dto1D:samplei0
							samplei0= NumberByKey("I0", logvalues , "=" , ";" ,0)
						endif
						if(AUSW_load_exp)
							nvar SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
							samplemeasurementtime =  NumberByKey("exptime", logvalues , "=" , ";" ,0)
						endif
						if(AUSW_Load_GA)
							nvar GA = root:Packages:Convert2Dto1D:LineProf_GIIncAngle
							GA =  NumberByKey("SampleOmega", logvalues , "=" , ";" ,0)
						endif
						NewNote += logvalues + ";"
					else
						print "Error : Unable to open XML file - values not read"
					endif
				endif
				svar AUSW_basename
				NVAR AUSW_basenamelen
				NVAR AUSW_basenamestart
				NVAR AUSW_AddTemptoName
				NVAR AUSW_AddGrazingtoName
				NVAR AUSW_AdjustUsername
				if(AUSW_AdjustUsername)
					svar UserFileName=root:Packages:Convert2Dto1D:OutputDataName
					string basestring
					if(cmpstr(AUSW_basename,""))
						basestring = AUSW_basename
					else
						variable strend = max(strsearch(filename, "_", AUSW_basenamelen+AUSW_basenamestart)-1, AUSW_basenamelen+AUSW_basenamestart)
						strend = min(strend,AUSW_basenamestart +AUSW_basenamelen)
						basestring = filename[AUSW_basenamestart,strend]
					endif
					if(AUSW_AddGrazingtoName)
						string angstr
						if(!(strlen(logvalues)>0))
							angstr="nan"
						else
							sprintf angstr, "%05.3f", GA
						endif
						basestring +="_"+replacestring(".",angstr,"p")
					endif
					if(AUSW_AddTemptoName)
						variable temperature = NumberByKey("Temperature1", logvalues)
						string tempstr
						sprintf tempstr, "%05.1f", temperature
						basestring +="_"+replacestring(".",tempstr,"p")
					endif
					userfilename = cleanupname(basestring,1)
				endif
			endif
		endif
		setdatafolder aufsave1
		// load image as tif
		FileNameToLoad= FileName
		if(cmpstr(FileName[strlen(FileName)-4,inf],".tif")!=0)
			FileNameToLoad= FileName+ ".tif"
		endif
		ImageLoad/Q/P=$(PathName)/T=tiff/O/N=$(NewWaveName) FileNameToLoad
		wave LoadedWvHere=$(NewWaveName)
		Redimension/N=(-1,-1,0) 	LoadedWvHere			//this is fix for 3 layer tiff files...
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+".tif"+";"
		
	elseif(cmpstr(FileType,"ESRFedf")==0)	//******************  ESRF edf 
			FileNameToLoad= FileName
			open /R/P=$(PathName) RefNum as FileNameToLoad
			testLine=""
			testLine=PadString (testLine, 40000, 0x20)
			FBinRead RefNum, testLine
			variable headerLength=(strsearch(testLine, "}", 0))
			headerLength = ceil(headerLength/512 ) * 512
			close RefNum
			//read the header and store in string
			open /R/P=$(PathName) RefNum as FileNameToLoad
			headerStr=PadString (headerStr, headerLength, 0x20)
			FBinRead RefNum, headerStr
			close RefNum
			headerStr=ReplaceString("\r\n", headerStr, "")
			headerStr=ReplaceString(" ;", headerStr, ";")
			headerStr=ReplaceString(" = ", headerStr, "=")
			headerStr=ReplaceString("{", headerStr, "")
			headerStr=ReplaceString("}", headerStr, "")
			headerStr=ReplaceString("    ", headerStr, "")
			
		//	print headerStr			
			variable NumPntsX=NumberByKey("Dim_1", headerStr  , "=" , ";")
			variable NumPntsY=NumberByKey("Dim_2", headerStr  , "=" , ";")
			string ESRF_ByteOrder=StringByKey("ByteOrder", headerStr  , "=" , ";")
			string ESRF_DataType=StringByKey("DataType", headerStr  , "=" , ";")
			variable ESRFDataType
			//Double Float;Single Float;32 bit signed integer;16 bit signed integer;8 bit signed integer;32 bit unsigned integer;16 bit unsigned integer;8 bit unsigned integer
			if(cmpstr(ESRF_DataType,"Double Float")==0)
				ESRFDataType=4
			elseif(cmpstr(ESRF_DataType,"FloatValue")==0)		//this one is tested, others NOT
				ESRFDataType=2
			elseif(cmpstr(ESRF_DataType,"32 bit signed integer")==0)
				ESRFDataType=32
			elseif(cmpstr(ESRF_DataType,"16 bit signed integer")==0)
				ESRFDataType=16
			elseif(cmpstr(ESRF_DataType,"8 bit signed integer")==0)
				ESRFDataType=8
			elseif(cmpstr(ESRF_DataType,"32 bit unsigned integer")==0)
				ESRFDataType=32+64
			elseif(cmpstr(ESRF_DataType,"16 bit unsigned integer")==0)
				ESRFDataType=16+64
			elseif(cmpstr(ESRF_DataType,"8 bit unsigned integer")==0)
				ESRFDataType=8+64
			endif
			variable ESRFFLoatType =1
			variable ESRFByteOrderV
			if(cmpstr(ESRF_ByteOrder,"LowByteFirst")==0)
				ESRFByteOrderV=1
			else
				ESRFByteOrderV=0
			endif
			
			if(ESRFDataType<5)	//float numbers
				GBLoadWave/Q/B=(ESRFByteOrderV)/T={ESRFDataType,4}/J=(ESRFFLoatType)/S=(headerLength)/W=1/P=$(PathName)/N=Loadedwave FileNameToLoad
			else
				GBLoadWave/Q/B=(ESRFByteOrderV)/T={ESRFDataType,4}/S=(headerLength)/W=1/P=$(PathName)/N=Loadedwave FileNameToLoad
			endif
		wave Loadedwave0
		Redimension/N=(NumPntsX,NumPntsY) Loadedwave0
		duplicate/O Loadedwave0, $(NewWaveName)
		killwaves Loadedwave0
		//read header...
		NVAR ESRFEdf_ExposureTime=root:Packages:Convert2Dto1D:ESRFEdf_ExposureTime
		NVAR ESRFEdf_Center_1=root:Packages:Convert2Dto1D:ESRFEdf_Center_1
		NVAR ESRFEdf_Center_2=root:Packages:Convert2Dto1D:ESRFEdf_Center_2
		NVAR ESRFEdf_PSize_1=root:Packages:Convert2Dto1D:ESRFEdf_PSize_1
		NVAR ESRFEdf_PSize_2=root:Packages:Convert2Dto1D:ESRFEdf_PSize_2
		NVAR ESRFEdf_SampleDistance=root:Packages:Convert2Dto1D:ESRFEdf_SampleDistance
		NVAR ESRFEdf_SampleThickness=root:Packages:Convert2Dto1D:ESRFEdf_SampleThickness
		NVAR ESRFEdf_WaveLength=root:Packages:Convert2Dto1D:ESRFEdf_WaveLength
		NVAR ESRFEdf_Title=root:Packages:Convert2Dto1D:ESRFEdf_Title
		NVAR BeamCenterX=root:Packages:Convert2Dto1D:BeamCenterX
		NVAR BeamCenterY=root:Packages:Convert2Dto1D:BeamCenterY
		NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
		NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
		NVAR SampleThickness=root:Packages:Convert2Dto1D:SampleThickness
		NVAR SampleI0=root:Packages:Convert2Dto1D:SampleI0
		NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance
		NVAR Wavelength=root:Packages:Convert2Dto1D:Wavelength
		NVAR XrayEnergy=root:Packages:Convert2Dto1D:XrayEnergy
		NVAR SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
		if(ESRFEdf_ExposureTime)
			//print StringByKey("\r\nExposureTime", testLine , " = ",";")
			//print StringFromList(1,StringByKey("\r\nExposureTime", testLine , " = ",";")," ")
			SampleMeasurementTime=str2num(StringFromList(1,StringByKey("\r\nExposureTime", testLine , " = ",";")," "))
		endif
		if(ESRFEdf_Center_1)
			BeamCenterX=str2num(StringFromList(1,StringByKey("\r\nCenter_1", testLine , " = ",";")," "))
		endif
		if(ESRFEdf_Center_2)
			BeamCenterY=str2num(StringFromList(1,StringByKey("\r\nCenter_2", testLine , " = ",";")," "))
		endif
		if(ESRFEdf_PSize_1)
			PixelSizeX=str2num(StringFromList(1,StringByKey("\r\nPSize_1", testLine , " = ",";")," "))*1e3	//convert to mm
		endif
		if(ESRFEdf_PSize_2)
			PixelSizeY=str2num(StringFromList(1,StringByKey("\r\nPSize_2", testLine , " = ",";")," "))*1e3	//convert to mm
		endif
		if(ESRFEdf_SampleDistance)
			SampleToCCDDistance=str2num(StringFromList(1,StringByKey("\r\nSampleDistance", testLine , " = ",";")," "))*1e3	//convert to mm
		endif
		if(ESRFEdf_SampleThickness)
			SampleThickness=str2num(StringFromList(1,StringByKey("\r\nSampleThickness", testLine , " = ",";")," "))	//is in mm
		endif
		if(ESRFEdf_WaveLength)
			Wavelength=str2num(StringFromList(1,StringByKey("\r\nWaveLength", testLine , " = ",";")," "))*1e10	//convert to A
			XrayEnergy =  12.3984 /Wavelength
		endif
		//done reading header....
		if(ESRFEdf_Title)
			NewNote+="DataFileName="+replaceString("= ", StringByKey("\r\nTitle", testLine , " = ",";"),"")+" "+FileNameToLoad+";"
		else
			NewNote+="DataFileName="+FileNameToLoad+";"
		endif
		NewNote+="DataFileType="+"ESFRedf"+";"
		NewNote+=testLine

			
	elseif(cmpstr(FileType,"GeneralBinary")==0)
		NVAR NIGBSkipHeaderBytes=root:Packages:Convert2Dto1D:NIGBSkipHeaderBytes
		NVAR NIGBSkipAfterEndTerm=root:Packages:Convert2Dto1D:NIGBSkipAfterEndTerm
		NVAR NIGBUseSearchEndTerm=root:Packages:Convert2Dto1D:NIGBUseSearchEndTerm
		NVAR NIGBNumberOfXPoints=root:Packages:Convert2Dto1D:NIGBNumberOfXPoints
		NVAR NIGBNumberOfYPoints=root:Packages:Convert2Dto1D:NIGBNumberOfYPoints
		NVAR NIGBSaveHeaderInWaveNote=root:Packages:Convert2Dto1D:NIGBSaveHeaderInWaveNote
	
		SVAR NIGBDataType=root:Packages:Convert2Dto1D:NIGBDataType
		SVAR NIGBSearchEndTermInHeader=root:Packages:Convert2Dto1D:NIGBSearchEndTermInHeader
		SVAR NIGBByteOrder=root:Packages:Convert2Dto1D:NIGBByteOrder
		SVAR NIGBFloatDataType=root:Packages:Convert2Dto1D:NIGBFloatDataType
		
		FileNameToLoad= FileName
		variable skipBytes=0
		if(NIGBUseSearchEndTerm)
			open /R/P=$(PathName) RefNum as FileNameToLoad
			testLine=""
			testLine=PadString (testLine, 40000, 0x20)
			FBinRead RefNum, testLine
			skipBytes=(strsearch(testLine, NIGBSearchEndTermInHeader, 0))+strlen(NIGBSearchEndTermInHeader)+NIGBSkipAfterEndTerm
			close RefNum
		else
			skipBytes=NIGBSkipHeaderBytes
			open /R/P=$(PathName) RefNum as FileNameToLoad
			testLine=""
			testLine=PadString (testLine, skipBytes, 0x20)
			FBinRead RefNum, testLine
			close RefNum
		endif
			testline=testline[0,skipBytes]
			if(stringmatch(testline, "*\r\n*"))
				testLine=ReplaceString("\r\n", testLine, ";" )
			elseif(stringmatch(testline, "*\r*"))
				testLine=ReplaceString("\r", testLine, ";" )
			elseif(stringmatch(testline, "*\n*"))
				testLine=ReplaceString("\n", testLine, ";" )
			endif
		variable LDataType
		//Double Float;Single Float;32 bit signed integer;16 bit signed integer;8 bit signed integer;32 bit unsigned integer;16 bit unsigned integer;8 bit unsigned integer
		if(cmpstr(NIGBDataType,"Double Float")==0)
			LDataType=4
		elseif(cmpstr(NIGBDataType,"Single Float")==0)
			LDataType=2
		elseif(cmpstr(NIGBDataType,"32 bit signed integer")==0)
			LDataType=32
		elseif(cmpstr(NIGBDataType,"16 bit signed integer")==0)
			LDataType=16
		elseif(cmpstr(NIGBDataType,"8 bit signed integer")==0)
			LDataType=8
		elseif(cmpstr(NIGBDataType,"32 bit unsigned integer")==0)
			LDataType=32+64
		elseif(cmpstr(NIGBDataType,"16 bit unsigned integer")==0)
			LDataType=16+64
		elseif(cmpstr(NIGBDataType,"8 bit unsigned integer")==0)
			LDataType=8+64
		endif
		if(LDataType==0)
			Abort "Wrong configuration of General Binary loader. BUG!"
		endif
		variable LByteOrder
		//High Byte First;Low Byte First
		if(cmpstr(NIGBByteOrder,"Low Byte First")==0)
			LByteOrder=1
		else
			LByteOrder=0
		endif
		variable LFloatType
		//NIGBFloatDataType IEEE,VAX
		if(cmpstr(NIGBFloatDataType,"IEEE")==0)
			LFloatType=1
		else
			LFloatType=2
		endif
		killwaves/Z Loadedwave0,Loadedwave1
		if(LDataType<5)	//float numbers, no sense to use Byte order
			GBLoadWave/Q/B=(LByteOrder)/T={LDataType,4}/J=(LFloatType)/S=(skipBytes)/W=1/P=$(PathName)/N=Loadedwave FileNameToLoad
		else
			GBLoadWave/Q/B=(LByteOrder)/T={LDataType,4}/S=(skipBytes)/W=1/P=$(PathName)/N=Loadedwave FileNameToLoad
		endif
		wave Loadedwave0
		Redimension/N=(NIGBNumberOfXPoints,NIGBNumberOfYPoints) Loadedwave0
		duplicate/O Loadedwave0, $(NewWaveName)
		killwaves Loadedwave0
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"GeneralBinary"+";"
		if(NIGBSaveHeaderInWaveNote)
			NewNote+=testLine
		endif
	elseif(cmpstr(FileType,"Pilatus")==0)	//temporaty for Pilatus... 

		//now reading the stuff...
	       //Start Pilatus Load
	       
		SVAR  PilatusType=root:Packages:Convert2Dto1D:PilatusType
		string pilatushilo
		splitstring /e=".*_(hi|lo)_.*" filename, pilatushilo
		if(stringmatch(PilatusType,"Pilatus1M")&&!(cmpstr(pilatushilo,"hi")&&cmpstr(pilatushilo,"lo")))
			// check if the other file exists
			string otherlohi
			if(cmpstr(pilatushilo,"lo"))
				otherlohi = "lo"
			else
				otherlohi = "hi"
			endif
			string otherpilatusname = replacestring(pilatushilo,filename,otherlohi)
			getfilefolderinfo /p=pathname /q /z otherpilatusname
			if(!v_flag)
				print "corresponding tiling file could not be found, using only one image"
				NewNote = pilatusload(PathName,FileName,FileType,NewWaveName,refnum,newnote)
			else
				NewNote = pilatusload(PathName,replacestring(pilatushilo,filename,"hi"),FileType,"pilatuswavehi",refnum,newnote)
				nvar sampleio=root:Packages:Convert2Dto1D:sampleI0
				variable hiio = sampleio
				NewNote = pilatusload(PathName,replacestring(pilatushilo,filename,"lo"),FileType,newwavename,refnum,newnote)
				variable loio = 	sampleio
				wave tilelo = $newwavename
				redimension /d tilelo
				wave tilehi = pilatuswavehi
				redimension/d tilehi
//				//Normalize the images
				tilelo/=  loio
				tilehi/= hiio

				//  193 - 213    405 - 425   617 - 637  829 - 849 
				
//Collins Code Additions ------------------------------------------------------------------------------------
				duplicate/o tilelo TileRatio TileRatio2
				TileRatio= tilelo[p][q]/tilehi[p][q+30]
				//get rid of blank areas
				TileRatio= TileRatio[p][q]==0 ? nan : TileRatio
				TileRatio= TileRatio[p][q]==inf ? nan : TileRatio
				//don't use area near the beamstop or horizon
				TileRatio= q>800 ? nan : TileRatio
				//don't use area where there is naturally low statistics
				TileRatio= p>800 ? nan : TileRatio
				//Work in Log space because it's symmetric about 1
				TileRatio=Log(tileRatio)
				//Get rid of outliers due to poor statistics
				TileRatio= TileRatio[p][q]>.6 ? nan : TileRatio
				TileRatio= TileRatio[p][q]<-.6 ? nan : TileRatio
				TileRatio=TileRatio
				WaveStats/Q TileRatio
				print "AvgRatio=",10^V_avg
				
				// replacing only the blank parts
				tilelo =  mod(q-3,212)<189? tilelo[p][q] : tilehi[p][q+30]
				tilehi = mod(q-3,212)<189? tilehi[p][q] : tilelo[p][q-30]/10^V_Avg //here's how it all works into the existing code!!!
				
				//loading exposure time from the data header
				NVAR Dwell = root:Packages:Convert2Dto1D:SampleMeasurementTime
				variable strPos=strsearch(newnote,"count_time", 0)
				strPos=strsearch(newnote,"=",strPos)
				Dwell=str2num(newnote[strPos+2,strPos+6])
				If( Dwell*0!=0 )
					dwell=1
					print "Error reading dwell time!"
				endif
//End Collins Code Additions -------------------------------------------------------------------------------------
				duplicate/o tilelo, PilatusImageLo
				duplicate/o tilehi , PilatusImageHi

				duplicate/o tilehi, PilatusImageAvg
				redimension /d /n=(dimsize(PilatusImageAvg,0),dimsize(PilatusImageAvg,1)+27) PilatusImageAvg
//				PilatusImageAvg =q>30 &&q<dimsize(tilelo,1)? (tilelo[p][q-30]+tilehi[p][q])/2 : PilatusImageAvg[p][q]
				//dezingering
//				variable row
//				for(row=30;row<=dimsize(tilelo,1);row+=1)
//					PilatusImageAvg[][row] = abs(tilelo[p][row-30]-tilehi[p][row])/(tilelo[p][row-30]-tilehi[p][row])<3*sqrt(tilelo[p][row-30]+tilehi[p][row]) ? min(tilelo[p][row-30],tilehi[p][row]) : (tilelo[p][row-30]+tilehi[p][row])/2
//				endfor
				PilatusImageAvg =q>dimsize(tilelo,1) ? tilelo[p][q-30] : PilatusImageAvg[p][q]
				//Normalizing back to raw numbers (or equivalents)
				PilatusImageAvg*= hiio
//				PilatusImageHi *=hiio
//				PilatusImageLo*=hiio
				// Choose which image to copy to output for Nika (which is tilelo here)
				duplicate/o PilatusimageAvg,tilelo
				//kill the temporary waves
				killwaves tilehi
			endif
		else
			NewNote = pilatusload(PathName,FileName,FileType,NewWaveName,refnum,newnote)
		endif
		filenametoload = filename
         //     Loadedwave0[12][162] /= 100.0


	elseif(cmpstr(FileType,"RIGK/Raxis")==0)
		FileNameToLoad= FileName
		string RigakuHeader = NI1A_ReadRigakuUsingStructure(PathName, FileNameToLoad)
		//variable offsetFile = NI1A_FindFirstNonZeroChar(PathName, FileNameToLoad)
		variable offsetFile = NumberByKey("RecordLengthByte", RigakuHeader )
		print "Found offset in the file to be: "+num2str(offsetFile)
		variable 	RigNumOfXPoint=NumberByKey("xDirectionPixNumber", RigakuHeader)
		variable 	RigNumOfYPoint=NumberByKey("yDirectionPixNumber", RigakuHeader)
		if (numtype(offsetFile)!=0 || offsetFile<250)		//check for meaningful offset
			//if not meaningful, caclualte offset from RigNumOfXPoint
			offsetFile = RigNumOfXPoint*2
			Print "Bad offset in the file header, assume offset is given (as should be) by x dimension of the image. Offset set to : "+num2str(offsetFile)
		endif
		killwaves/Z Loadedwave0,Loadedwave1
	//	GBLoadWave/B=0/T={16,4}/S=2048/W=1/P=$(PathName)/q=1/N=Loadedwave FileNameToLoad	//works for 1kx1k
	//	GBLoadWave/B=0/T={16,4}/S=3024/W=1/P=$(PathName)/q=1/N=Loadedwave FileNameToLoad	//works for 1.5k x 1.5k
		//fix for 1.5k x 1.5k images... In the test example I have seems to be offset 3000 bytes, but 
		GBLoadWave/B=0/T={16,4}/S=(offsetFile)/W=1/P=$(PathName)/q=1/N=Loadedwave FileNameToLoad
		//changed on 7/20/2007... Looking for offset as first non 0 value. WOrks on 1kx1k and 1.5k x 1.5k images provided... 
		//11/2008 - the offset is given by one column length, per Rigaku file description. Set as that. BTW: Fit2D uses the same assumption. 
		wave Loadedwave0
		Redimension/N=(RigNumOfXPoint,RigNumOfYPoint) Loadedwave0
		duplicate/O Loadedwave0, $(NewWaveName)
		killwaves Loadedwave0
		wave w=$(NewWaveName)
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"RIGK/Raxis"+";"
		NewNote+=RigakuHeader
		//the header contains useful data, let's parse them in....
		NVAR Wavelength=root:Packages:Convert2Dto1D:Wavelength
		NVAR XrayEnergy=root:Packages:Convert2Dto1D:XrayEnergy
		NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
		NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
		PixelSizeX = NumberByKey("xDirectionPixelSizeMM", RigakuHeader)
		PixelSizeY = NumberByKey("yDirectionPixelSizeMM", RigakuHeader)
		Wavelength = NumberByKey("Wavelength", RigakuHeader)
		XrayEnergy = 12.398424437/Wavelength
		//now check if we need to convert negative values to high intensities...
		variable OutPutRatioHighLow
		OutPutRatioHighLow=NumberByKey("OutPutRatioHighLow", RigakuHeader)			//conversion factor, 0 if no conversion needed
		//seems to fail.. Lets default to 8 when not set...
		//most Rigaku instruments use multiplier of 8, assume that it is correct, but note, there are two which use 32. Life would be too easy without exceptions... 
		if(OutPutRatioHighLow==0)
			OutPutRatioHighLow=8
		endif
		wavestats/Q w
		if(V_min>=0)
			//nothing needed, let's not worry...
		elseif(OutPutRatioHighLow>0 && V_min<0)
			//fix the negative values...
			NI1A_RigakuFixNegValues(w,OutPutRatioHighLow)
		else
			Abort "Problem loading the Rigaku file format. Header and values do not agree... Please contact author (ilavsky@aps.anl.gov) and send the offending file with as much info as possible for evaluation"
		endif
		//now let's print the few parameters user shoudl need...
		print "**************************************************"
		print "***  Rigaku R axis file format header info  **"
		print "Camera length in the file is [mm] ="+StringByKey("CameraLength_mm", RigakuHeader)
		print "Beam center X position in the file is [pixel] ="+StringByKey("DirectBeamPositionX", RigakuHeader)
		print "Beam center Y position in the file is [pixel] ="+StringByKey("DirectBeamPositionY", RigakuHeader)
		print "**************************************************"
		print "**************************************************"
	elseif(cmpstr(FileType,"ibw")==0)
   	     PathInfo $(PathName)
   	     KillWaves/z $(NewWaveName)
  	     FileNameToLoad=   FileName
   	     LoadWave /P=$(PathName)/H/O  FileNameToLoad

   	     string LoadedName=StringFromList(0,S_waveNames)
   	     Wave CurLdWv=$(LoadedName)
   	     Rename CurLdWv, $(NewWaveName)
 //  	     //eliot adding this
   	     nvar xrayenergy = root:Packages:Convert2Dto1D:XrayEnergy
   	     nvar wavelength = root:Packages:Convert2Dto1D:Wavelength
   	     string energy
   	     splitstring /e="^[^_]*_([1234567890.]{3,6})\.ibw$" filename,energy
   	     if(strlen(energy)>2)
   	     		xrayenergy = round(10*str2num(energy))/10000
   	     		wavelength = 12.398424437/xrayenergy
   	     endif
  //	     nvar subtractfixedoffset
  // 	     subtractfixedoffset = backgroundsubtract(NewWaveName)
  // 	     //eliot done
	elseif(cmpstr(FileType,".fits")==0)
   	     PathInfo $(PathName)
   	     KillWaves/z $(NewWaveName)
  	     FileNameToLoad=   FileName
	     newnote = LoadFitsfileNika(filename,PathName,refnum,NewWaveName)
	     newnote +=";datafilename="+filename+";"
	elseif(cmpstr(FileType,"BSL/SAXS")==0 || cmpstr(FileType,"BSL/WAXS")==0)
   	     //Josh add
   	     NVAR BSLsumframes=$("root:Packages:NI1_BSLFiles:BSLsumframes")
   	     NVAR BSLfromframe=$("root:Packages:NI1_BSLFiles:BSLfromframe")
   	     NVAR BSLtoframe=$("root:Packages:NI1_BSLFiles:BSLtoframe")
   	     
   	     PathInfo $(PathName)
   	     KillWaves/Z $(NewWaveName)
  	     FileNameToLoad=   FileName
   	     variable AveragedFrame=NI1_LoadBSLFiles(FileNameToLoad)
 		Wave temp2DWave = $("root:Packages:NI1_BSLFiles:temp2DWave")
		duplicate/O temp2DWave, $(NewWaveName)
		string AveFrame=""
		if(AveragedFrame==0)
			AveFrame="Averaged"
		elseif(BSLsumframes==1)
			AveFrame="summed frame "+num2str(BSLfromframe)+" to "+" frame "+num2str(BSLtoframe)
		else
			AveFrame="frame"+num2str(AveragedFrame)
		endif
		NewNote+="DataFileName="+FileNameToLoad+"_"+AveFrame+";"
		NewNote+="DataFileType="+FileType+";"
	elseif(cmpstr(FileType,"Fuji/img")==0)
		string FujiHeader
      		FileNameToLoad=   FileName
		FujiHeader = NI1_ReadFujiImgHeader(PathName, FileNameToLoad)
		NI1_ReadFujiImgFile(PathName, FileNameToLoad, FujiHeader)
		Wave Loadedwave0
		duplicate/O Loadedwave0, $(NewWaveName)
		killwaves Loadedwave0
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"mp/bin"+";"
		NewNote+=FujiHeader
	elseif(cmpstr(FileType,"mp/bin")==0)
		FileNameToLoad= FileName
		open /R/P=$(PathName) RefNum as FileNameToLoad
		FreadLine/N=1024 /T=";" RefNum, testLine
		Offset=(strsearch(testLine, "]", strsearch(testLine,"CDAT",0)))+7
		testLine=ReplaceString("\r\n", testLine, ";" )
		numBytes=NumberByKey("range", testLine , "=" , ";")
		close RefNum
		killwaves/Z Loadedwave0,Loadedwave1
		GBLoadWave/B/T={96,4}/S=(Offset)/W=1/P=$(PathName)/N=Loadedwave FileNameToLoad
		wave Loadedwave0
		Redimension/N=(sqrt(numBytes),sqrt(numBytes)) Loadedwave0
		duplicate/O Loadedwave0, $(NewWaveName)
		killwaves Loadedwave0
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"mp/bin"+";"
	elseif(cmpstr(FileType,"mpa/bin")==0)
		FileNameToLoad= FileName
		open /R/P=$(PathName) RefNum as FileNameToLoad
		testLine=""
		testLine=PadString (testLine, 20000, 0x20)
		FBinRead RefNum, testLine
		Offset=(strsearch(testLine, "[CDAT0,1048576 ]", 0))+22
		testLine=ReplaceString("\r\n", testLine, ";" )
		numBytes=NumberByKey("range", testLine , "=" , ";")
		close RefNum
		killwaves/Z Loadedwave0,Loadedwave1
		GBLoadWave/B/T={96,4}/S=(Offset)/W=1/P=$(PathName)/N=Loadedwave FileNameToLoad
		wave Loadedwave0
		Redimension/N=(1024,1024) Loadedwave0
		duplicate/O Loadedwave0, $(NewWaveName)
		killwaves Loadedwave0
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"mpa/bin"+";"
		Offset=(strsearch(testLine, "[DATA0,1024 ]", 0))-1
		testLine=testLine[0,offset]
		NewNote+=testLine
	elseif(cmpstr(FileType,"mpa/asc")==0)
		FileNameToLoad= FileName
		killwaves/Z Loadedwave0,Loadedwave1,Loadedwave2,Loadedwave3
		LoadWave/G/P=$(PathName)/A=Loadedwave FileNameToLoad
		wave Loadedwave0
		Redimension/N=(sqrt(numpnts(Loadedwave0)),sqrt(numpnts(Loadedwave0))) Loadedwave0
		duplicate/O Loadedwave0, $(NewWaveName)
		killwaves Loadedwave0
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"mpa/asc"+";"
	elseif(cmpstr(FileType,"ascii512x512")==0)
		killwaves/Z Loadedwave0,Loadedwave1,Loadedwave2,Loadedwave3
		loadwave/P=$(PathName)/J/O/M/N=Loadedwave FileName
		FileNameToLoad=FileName
		wave Loadedwave0
		make/d/o/n=(512,512) $(NewWaveName)
		wave tempp=$(NewWaveName)
		tempp=Loadedwave0
		KillWaves Loadedwave0
	elseif(cmpstr(FileType,"DND/txt")==0)
		FileNameToLoad= FileName
		open /R/P=$(PathName) RefNum as FileNameToLoad
		HeaderStr=NI1_ReadDNDHeader(RefNum)		//read the header from the text file
		close RefNum
		//header string contains now all information from the text file... Now need to open the tiff file
		string tiffFilename=NI1_FineDNDTifFile(PathName,FileName,HeaderStr)
		//and also established data path "DNDDataPath" where teh data are
		NI1A_UniversalLoader("DNDDataPath",tiffFilename,".tif",NewWaveName)
		//append wave note...
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"DND/txt"+";"
		NewNote+=HeaderStr
		//parse the header for DND CAT stuff to separate folder for use in data reduction
		NI1_ParseDNDHeader(HeaderStr, FileNameToLoad)
	elseif(cmpstr(FileType,"ASCII")==0)
		//LoadWave/G/M/D/N=junk/P=LinusPath theFile
		FileNameToLoad= FileName
		killwaves/Z Loadedwave0,Loadedwave1,Loadedwave2,Loadedwave3
		LoadWave/G/M/D/P=$(PathName)/A=Loadedwave FileNameToLoad
		wave Loadedwave0
		duplicate/O Loadedwave0, $(NewWaveName)
		killwaves Loadedwave0
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"ASCII"+";"
		//now, if this was file with extension mtx then look for file with extension prm and load parameters from there
		if(stringmatch(FileName, "*.mtx" ))
			string NewFlNm = FileName[0,strlen(FileName)-5]+".prm"
			string templine
			variable tempFilNmNum, ii
			open/R/Z=1/P=$(PathName) tempFilNmNum as NewFlNm
			if(V_Flag==0)
				For(ii=0;ii<100;ii+=1)
					FreadLine tempFilNmNum, templine
					if(strlen(templine)<1)
						ii=101
					else
						templine = IN2G_ChangePartsOfString(templine,"  ","")
						templine = IN2G_ChangePartsOfString(templine,"\r","")
						templine = IN2G_ChangePartsOfString(templine,":","=")
						if(strlen(templine)>3)
							NewNote+=templine+";"
						endif
					endif
				endfor
				NVAR Wavelength=root:Packages:Convert2Dto1D:Wavelength
				NVAR XrayEnergy = root:Packages:Convert2Dto1D:XrayEnergy
				//12.398424437 
				//SampletoDetectorDistance=5419mm
				NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance
			//	SampleToCCDDistance = NumberByKey("SampletoDetectorDistance", NewNote  , "=", ";")
				//string tempstr=stringByKey("Sample to Detector Distance", NewNote  , "=", ";")
				SampleToCCDDistance = NumberByKey("Sample to Detector Distance", NewNote  , "=", ";") 
				//SampleToCCDDistance = str2num(tempstr[0,strlen(tempstr)-3])
				//TotalLiveTime=1800.000000seconds
				NVAR SampleI0 = root:Packages:Convert2Dto1D:SampleI0
				SampleI0 = NumberByKey("Total Monitor Counts", NewNote  , "=", ";") //TotalMonitorCounts
				NVAR SampleMeasurementTime = root:Packages:Convert2Dto1D:SampleMeasurementTime
			//	SampleMeasurementTime = str2num(stringByKey("Total Live Time", NewNote  , "=", ";")[0,11])
				SampleMeasurementTime = NumberByKey("Total Live Time", NewNote  , "=", ";") 

			endif
			close tempFilNmNum
		endif
		//end of special section for case or parameter file... This al section should be skipped for any other ASCIi files. 
	elseif(cmpstr(FileType,"mp/asc")==0)
		FileNameToLoad= FileName
		killwaves/Z Loadedwave0,Loadedwave1
		LoadWave/G/P=$(PathName)/A=Loadedwave FileNameToLoad
		wave Loadedwave0
		Redimension/N=(sqrt(numpnts(Loadedwave0)),sqrt(numpnts(Loadedwave0))) Loadedwave0
		duplicate/O Loadedwave0, $(NewWaveName)
		killwaves Loadedwave0
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"mp/asc"+";"
	elseif(cmpstr(FileType,"BSRC/Gold")==0)
		FileNameToLoad= FileName
		killwaves/Z Loadedwave0,Loadedwave1
		GBLoadWave/J=2/T={80,80}/S=5632/W=1/U=2359296 /P=$(PathName)/N=Loadedwave FileNameToLoad
		//GBLoadWave/B/T={96,4}/S=430/W=1/U=(numBytes)/P=$(PathName)/N=Loadedwave FileNameToLoad
		wave Loadedwave0
		Redimension/N=(1536,1536) Loadedwave0
		//Redimension/N=(sqrt(numBytes),sqrt(numBytes)) Loadedwave0
		duplicate/O Loadedwave0, $(NewWaveName)
		killwaves Loadedwave0
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"BSRC/Gold"+";"
	elseif(stringMatch(FileType,"*/Fit2D"))
		PathInfo $(PathName)
//		if(cmpstr(IgorInfo(2),"Windows")!=0)
//			Abort "This import tool works only on WIndows for now"
//		endif
		FileNameToLoad=  S_path + FileName
		ReadMAR345UsingFit2D(FileNameToLoad, NewWaveName,FileType,PathName)
		//string temp=StringFromList(ItemsInList(FileNameToLoad,":")-1,FileNameToLoad,":")
		NewNote+="DataFileName="+StringFromList(ItemsInList(FileNameToLoad,":")-1,FileNameToLoad,":")+";"
		NewNote+="DataFileType="+"marIP/Fit2D"+";"
//	elseif(cmpstr(FileType,"Mar")==0)
//		PathInfo $(PathName)
//		FileNameToLoad=  S_path + FileName
//		DoReadMAR345(FileNameToLoad, NewWaveName)
//		NewNote+="DataFileName="+FileNameToLoad+";"
//		NewNote+="DataFileType="+"Mar"+";"
//	elseif(cmpstr(FileType,"RigakuRaxis/xop")==0)
//		PathInfo $(PathName)
//		FileNameToLoad=  S_path + FileName
//#if(Exists("RigakuRaxisReader"))	
//		 RigakuRaxisReader FileNameToLoad
//		 //NewWaveName
//		abort
//#endif
//		NewNote+="DataFileName="+FileNameToLoad+";"
//		NewNote+="DataFileType="+"Rigaku Raxis"+";"
	elseif(cmpstr(FileType,"MarIP/xop")==0)		//added 9/16/2008, needs ccp4xop ... 
		PathInfo $(PathName)
		FileNameToLoad=  S_path + FileName
//		FileNameToLoad=  FileName
#if(Exists("ccp4unpack"))	
		ccp4unpack/M /N=$(NewWaveName)/O  FileNameToLoad		//note: Fails for names too long... 
//		ccp4unpack/M /N=$(NewWaveName)/P=$(PathName) /O  FileNameToLoad
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"MarIP/xop"+";"
		Wave tempWnNm=$(NewWaveName)		//here we fix the damn header from Mar IP file format... 
		string OldNote1234=note(tempWnNm)
		OldNote1234 = ReplaceString("\n", OldNote1234, ";")
		OldNote1234 = ReplaceString("     ", OldNote1234, ":")
		OldNote1234 = ReplaceString(" ", OldNote1234, "")
		variable iiii
		For(iiii=0;iiii<10;iiii+=1)
			OldNote1234 = ReplaceString("::", OldNote1234, ":")		
		endfor
		OldNote1234 = ReplaceString(";:;", OldNote1234, ";")
		OldNote1234 = ReplaceString(":;", OldNote1234, ";")
		note/K tempWnNm
		Note  tempWnNm ,OldNote1234
#endif
	elseif(cmpstr(FileType,"BrukerCCD")==0)
		PathInfo $(PathName)
		FileNameToLoad=  S_path + FileName
		//GBLoadWave/B/T={80,80}/S=7680/W=1/O/N=TempLoadWave FileNameToLoad
		ReadBrukerCCD_SMARTFile(FileNameToLoad, NewWaveName)
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"BrukerCCD"+";"
	elseif(cmpstr(FileType,"WinView spe (Princeton)")==0)
		PathInfo $(PathName)
		FileNameToLoad=  S_path + FileName
		NI1_LoadWinViewFile(FileNameToLoad, NewWaveName)
		NewNote+="DataFileName="+FileNameToLoad+";"
		NewNote+="DataFileType="+"WinView spe (Princeton)"+";"
	elseif(cmpstr(FileType,"ADSC")==0)
	//replaced with new version 11/25/09
//             FileNameToLoad= FileName
//               variable i
//    //           variable skipBytes
//               LDataType=16+64
//               LByteOrder=1
//               LFloatType=1
//               NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
//               NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
//               NVAR NIGBNumberOfXPoints=root:Packages:Convert2Dto1D:NIGBNumberOfXPoints
//               NVAR NIGBNumberOfYPoints=root:Packages:Convert2Dto1D:NIGBNumberOfYPoints
//               NVAR Wavelength=root:Packages:Convert2Dto1D:Wavelength
//               NVAR XrayEnergy=root:Packages:Convert2Dto1D:XrayEnergy
//
//		KillWaves/Z header0
//               Make/T /O textWave
//               Make/T /O header0
//               LoadWave/J /P=$(PathName) /N=header /L={0,0,35,0,0}/B="F=-2;" ,FileNameToLoad
//               skipBytes = NumberByKey("HEADER_BYTES",(header0[1]),"=")
//               variable dummy
//               for(i = 0; i <= 35;i=i+1)
//                       dummy = NumberByKey("SIZE1",(header0[i]),"=")
//                       if(dummy)
//                       NIGBNumberOfXPoints = dummy
//                       NIGBNumberOfYPoints = dummy
//                       endif
//                       dummy = NumberByKey("PIXEL_SIZE",(header0[i]),"=")
//                       if(dummy)
//                       PixelSizeX =  dummy
//                       PixelSizeY =  dummy
//                       endif
//                       dummy = NumberByKey("HEADER_BYTES",(header0[i]),"=")
//                       if(dummy)
//                       skipBytes = dummy
//                       endif
//			   dummy = NumberByKey("WAVELENGTH",(header0[i]),"=")
//                       if(dummy)
//                       Wavelength =  dummy*10
//                       XrayEnergy = 12.398424437/Wavelength
//                       endif
//             endfor
//               Print NIGBNumberOfYPoints
//               killwaves/Z Loadedwave0,Loadedwave1
//               GBLoadWave/Q/B=(LByteOrder)/T={LDataType,4}/S=(skipBytes)/W=1/P=$(PathName)/N=Loadedwave FileNameToLoad
//               Wave LoadedWave0
//               Redimension/N=(NIGBNumberOfXPoints,NIGBNumberOfYPoints) Loadedwave0
//               duplicate/O Loadedwave0, $(NewWaveName)
//               killwaves Loadedwave0
//               NewNote+="DataFileName="+FileNameToLoad+";"
//               NewNote+="DataFileType="+"ADSC"+";"
	//new version sent by Peter : PReichert@lbl.gov. Modified to read Io and other parameters from hteir ADSC file format. 
	             FileNameToLoad= FileName
	               variable i
	               variable dummy_i0
	               wave IonChamber_1, IonChamber_0, I1_I0
	               variable dummy_i1_1,dummy_i1,dummy_i1_2, dummy_time,Ring,wave0
	               LDataType=16+64
	               LByteOrder=1
	               LFloatType=1
	               NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
	               NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
	               NVAR NIGBNumberOfXPoints=root:Packages:Convert2Dto1D:NIGBNumberOfXPoints
	               NVAR NIGBNumberOfYPoints=root:Packages:Convert2Dto1D:NIGBNumberOfYPoints
	               NVAR Wavelength=root:Packages:Convert2Dto1D:Wavelength
	               NVAR XrayEnergy=root:Packages:Convert2Dto1D:XrayEnergy
			  NVAR SampleI0 = root:Packages:Convert2Dto1D:SampleI0
			//ELIOT ADDED FOR RENAMING LONG FILES
			  svar UserFileName=root:Packages:Convert2Dto1D:OutputDataName
			  if(strlen(filename)>16)
			  	string s1, s2, s3
			  	splitstring /e="[^_]{2,6}__?([^_^-]{5,12})[^_^-]*?[-_]([1234567890p]{3,6})_2?_?w.img$" filename,s1,s2
			  	s3 = s1+"_"+s2
			  	UserFileName = s3
			  endif
			  //Eliot done
	               Make/T /O textWave
	               Make/T /O header0
	               LoadWave/J /P=$(PathName) /N=header /L={0,0,39,0,0}/B="F=-2;" ,FileNameToLoad
	               skipBytes = NumberByKey("HEADER_BYTES",(header0[1]),"=")
	               variable dummy
	                for(i = 0; i <= 45;i=i+1)
	                       dummy = NumberByKey("SIZE2",(header0[i]),"=")
	                       if(dummy)
	                       NIGBNumberOfXPoints = dummy
	                       NIGBNumberOfYPoints = dummy
	                       endif
	                       dummy = NumberByKey("PIXEL_SIZE",(header0[i]),"=")
	                       if(dummy)
	                       PixelSizeX =  dummy
	                       PixelSizeY =  dummy
	                       endif
	                       dummy = NumberByKey("HEADER_BYTES",(header0[i]),"=")
	                       if(dummy)
	                       skipBytes = dummy
	                       endif
	                        dummy = NumberByKey("RING_CURRENT",(header0[i]),"=")
	                       if(dummy)
	                       Ring = dummy
	                       endif
	                       dummy = NumberByKey("I1",(header0[i]),"=")
	                       if(dummy)
	                       dummy_i1  = dummy
	                       endif
	                       dummy = NumberByKey("I0",(header0[i]),"=")
	                       if(dummy)
	                       dummy_i0  = dummy
	                       endif
	                        dummy = NumberByKey("I1_1",(header0[i]),"=")
	                       if(dummy)
	                       dummy_i1_1  = dummy
	                       endif
	                        dummy = NumberByKey("I1_2",(header0[i]),"=")
	                       if(dummy)
	                       dummy_i1_2  = dummy
	                       endif
	                       dummy = NumberByKey("I0_1",(header0[i]),"=")
	                       if(dummy)
	                       dummy_i0  = dummy
	                       endif
				   dummy = NumberByKey("WAVELENGTH",(header0[i]),"=")
	                       if(dummy)
	                       Wavelength =  dummy*10
	                       XrayEnergy = 12.398424437/Wavelength
	                       endif
	             endfor
	               // NIGBNumberOfXPoints = 2304
	               // NIGBNumberOfYPoints = 2304
	             if (dummy_i1_1 > 1)
	              	if(dummy_i1_2 >1)
	              		dummy_i1 = (dummy_i1_1+dummy_i1_2)/2.0
	              	else
	              		dummy_i1 = dummy_i1_1
	              	endif
	              elseif (dummy_i1 >1)
	              else 
	              	dummy_i1 = 1
	              endif
	              Print dummy_i1
	              SampleI0 = dummy_i1
	                SampleI0 = dummy_i1;
	               Print NIGBNumberOfYPoints
	               killwaves/Z Loadedwave0,Loadedwave1
	               GBLoadWave/Q/B=(LByteOrder)/T={LDataType,4}/S=(skipBytes)/W=1/P=$(PathName)/N=Loadedwave FileNameToLoad
	               Wave LoadedWave0
	               Redimension/N=(NIGBNumberOfXPoints,NIGBNumberOfYPoints) Loadedwave0
	               duplicate/O Loadedwave0, $(NewWaveName)
	               //slicing (Loadedwave0)
	               killwaves Loadedwave0
	               NewNote+="DataFileName="+FileNameToLoad+";"
	               NewNote+="DataFileType="+"ADSC"+";"
	 	 
	else
		Abort "Uknown CCD image to load..."
	endif
	pathInfo $(PathName)
	wave loadedwv=$(NewWaveName)
	NewNote+=";"+"DataFilePath="+S_path+";"+note(loadedwv)+";"
	print "Loaded file   " +FileNameToLoad
	wave NewWv=$(NewWaveName)
	note/K NewWv
	note NewWv, newnote
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1_GBLoaderCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	if(cmpstr(ctrlName,"UseSearchEndTerm")==0)
		SetVariable SkipHeaderBytes,win=NI_GBLoaderPanel, disable=checked
		SetVariable NIGBSearchEndTermInHeader,win=NI_GBLoaderPanel, disable=!checked
		SetVariable NIGBSkipAfterEndTerm,win=NI_GBLoaderPanel, disable=!checked
	endif

End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1_GBLoadSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	if(cmpstr(ctrlName,"SkipHeaderBytes")==0)
	
	endif

End

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function NI1_GBPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	if(cmpstr(ctrlName,"NIGBImageType")==0)
		SVAR NIGBDataType=root:Packages:Convert2Dto1D:NIGBDataType
		NIGBDataType=popStr
		variable WhichDataType
		if(cmpstr(NIGBDataType,"Double Float")==0 || cmpstr(NIGBDataType,"Single Float")==0)
			WhichDataType=1
		else
			WhichDataType=0
		endif
	//	PopupMenu NIGBByteOrder,win=NI_GBLoaderPanel, disable=WhichDataType
		PopupMenu NIGBFloatDataType,win=NI_GBLoaderPanel, disable=!WhichDataType
	endif
	
	if(cmpstr(ctrlName,"NIGBByteOrder")==0)
		SVAR NIGBByteOrder=root:Packages:Convert2Dto1D:NIGBByteOrder
		NIGBByteOrder=popStr
	endif

End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1_GBLoaderPanelFnct() : Panel
	
	DoWindow  NI_GBLoaderPanel
	if(V_Flag)
		DoWindow/F NI_GBLoaderPanel
	else
		variable WhichDataType
		SVAR NIGBDataType=root:Packages:Convert2Dto1D:NIGBDataType
//		if(cmpstr(NIGBDataType,"Double Float")==0 || cmpstr(NIGBDataType,"Single Float")==0)
//			WhichDataType=1
//		else
//			WhichDataType=0
//		endif
		NVAR NIGBUseSearchEndTerm=root:Packages:Convert2Dto1D:NIGBUseSearchEndTerm
		SVAR NIGBDataType=root:Packages:Convert2Dto1D:NIGBDataType
		SVAR NIGBByteOrder=root:Packages:Convert2Dto1D:NIGBByteOrder
		SVAR NIGBFloatDataType=root:Packages:Convert2Dto1D:NIGBFloatDataType
		PauseUpdate; Silent 1		// building window...
		NewPanel/K=1 /W=(240,98,644,414) as "General Binary loader config panel"
		DoWindow/C NI_GBLoaderPanel
		SetDrawLayer UserBack
		SetDrawEnv fsize= 18,fstyle= 3,textrgb= (0,0,65280)
		DrawText 28,36,"Nika General Binary Loader Config"
		SetDrawEnv fsize= 16,fstyle= 1,textrgb= (0,0,65280)
		DrawText 141,156,"Image type:"
		CheckBox UseSearchEndTerm,pos={234,54},size={158,14},proc=NI1_GBLoaderCheckProc,title="Use ASCII header terminator?"
		CheckBox UseSearchEndTerm,variable= root:Packages:Convert2Dto1D:NIGBUseSearchEndTerm, help={"Selectm if yo want to search for ASCII terminator of header. 40k of file searched!"}
		SetVariable SkipHeaderBytes,pos={16,53},size={200,16},proc=NI1_GBLoadSetVarProc,title="Skip Bytes :         ", help={"Number of bytes to skip"}
		SetVariable SkipHeaderBytes,value= root:Packages:Convert2Dto1D:NIGBSkipHeaderBytes, disable=NIGBUseSearchEndTerm
		SetVariable NIGBSearchEndTermInHeader,pos={12,86},size={330,16},title="Header terminator ", disable=!NIGBUseSearchEndTerm
		SetVariable NIGBSearchEndTermInHeader,help={"Input ASCII text which ends the ASCII header"}
		SetVariable NIGBSearchEndTermInHeader,value= root:Packages:Convert2Dto1D:NIGBSearchEndTermInHeader
		SetVariable NIGBSkipAfterEndTerm,pos={10,109},size={330,16},title="Skip another bytes after terminator?       "
		SetVariable NIGBSkipAfterEndTerm,value= root:Packages:Convert2Dto1D:NIGBSkipAfterEndTerm, disable=!NIGBUseSearchEndTerm
		SetVariable NIGBNumberOfXPoints,pos={40,164},size={250,16},title="X number of points    ", help={"Size of the data file to load in in X direction"}
		SetVariable NIGBNumberOfXPoints,value= root:Packages:Convert2Dto1D:NIGBNumberOfXPoints
		SetVariable NIGBNumberOfYPoints,pos={40,188},size={250,16},title="Y number of points    ", help={"Size of the data file to load in Y direction"}
		SetVariable NIGBNumberOfYPoints,value= root:Packages:Convert2Dto1D:NIGBNumberOfYPoints
		PopupMenu NIGBImageType,pos={77,213},size={122,21},proc=NI1_GBPopMenuProc,title="Data Type :  "
		PopupMenu NIGBImageType,help={"Select data type :"}
		PopupMenu NIGBImageType,mode=1,popvalue=NIGBDataType,value= #"\"Double Float;Single Float;32 bit signed integer;16 bit signed integer;8 bit signed integer;32 bit unsigned integer;16 bit unsigned integer;8 bit unsigned integer;\""
		PopupMenu NIGBByteOrder,pos={82,240},size={117,21},proc=NI1_GBPopMenuProc,title="Byte order : ", help={"Byte orider - high byte default (Motorola), or low byte first (Intel)"}
		PopupMenu NIGBByteOrder,mode=1,popvalue=NIGBByteOrder,value= #"\"High Byte First;Low Byte First;\""
		PopupMenu NIGBFloatDataType,pos={82,268},size={117,21},proc=NI1_GBPopMenuProc,title="Float type : "//, disable=!WhichDataType
		PopupMenu NIGBFloatDataType,mode=1,popvalue=NIGBFloatDataType,value= #"\"IEEE;VAX;\"", help={"IEEE Floating point or VAX floating point"}
		CheckBox NIGBSaveHeaderInWaveNote,pos={48,292},size={157,14},title="Save Header in Wave note? "
		CheckBox NIGBSaveHeaderInWaveNote,help={"Save all of the ASCII header in wave note?"}
		CheckBox NIGBSaveHeaderInWaveNote,variable= root:Packages:Convert2Dto1D:NIGBSaveHeaderInWaveNote
	endif
EndMacro


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function NI1_PilatusLoaderPanelFnct() : Panel
	
	DoWindow  NI_PilatusLoaderPanel
	if(V_Flag)
		DoWindow/F NI_PilatusLoaderPanel
	else
		SVAR PilatusType=root:Packages:Convert2Dto1D:PilatusType
		SVAR PilatusFileType=root:Packages:Convert2Dto1D:PilatusFileType
		SVAR PilatusColorDepth=root:Packages:Convert2Dto1D:PilatusColorDepth
		PauseUpdate; Silent 1		// building window...
		NewPanel/K=1 /W=(240,98,644,414) as "Pilatus loader config panel"
		DoWindow/C NI_PilatusLoaderPanel
		SetDrawLayer UserBack
		SetDrawEnv fsize= 18,fstyle= 3,textrgb= (0,0,65280)
		DrawText 28,36,"Nika Pilatus Loader Config"
//		SetDrawEnv fsize= 16,fstyle= 1,textrgb= (0,0,65280)
		DrawText 10,250,"Use hook function :  "
		DrawText 10,265,"             PilatusHookFunction(FileNameToLoad)"
		DrawText 10,280,"to add functionality.  Called after loading the file."
		PopupMenu PilatusType,pos={15,70},size={122,21},proc=NI1_PilatusPopMenuProc,title="Detector Type :  "
		PopupMenu PilatusType,help={"Select detector type :"}
		PopupMenu PilatusType,mode=1,popvalue=PilatusType,value= #"\"Pilatus100k;Pilatus1M;Pilatus2M;\""

		PopupMenu PilatusFileType,pos={15,100},size={122,21},proc=NI1_PilatusPopMenuProc,title="File Type :  "
		PopupMenu PilatusFileType,help={"Select file type :"}
		PopupMenu PilatusFileType,mode=1,popvalue=PilatusFileType,value= #"\"tiff;edf;img;float-tiff;\""

		PopupMenu PilatusColorDepth,pos={15,130},size={122,21},proc=NI1_PilatusPopMenuProc,title="Color depth :  "
		PopupMenu PilatusColorDepth,help={"Color depth (likely 32) :"}
		PopupMenu PilatusColorDepth,mode=1,popvalue=PilatusColorDepth,value= #"\"8;16;32;64;\""


		CheckBox PilatusSignedData,pos={220,134},size={158,14},noproc,title="UnSigned integers?"
		CheckBox PilatusSignedData,variable= root:Packages:Convert2Dto1D:PilatusSignedData, help={"Are the stored data signed integer? "}
		CheckBox PilatusReadAuxTxtHeader,pos={15,190},size={158,14},noproc,title="Read Auxiliary txt file (ALS)?"
		CheckBox PilatusReadAuxTxtHeader,variable= root:Packages:Convert2Dto1D:PilatusReadAuxTxtHeader, help={"For ALS, try to read data from auxiliarty txt file "}
	endif
EndMacro

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function NI1_PilatusPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	if(cmpstr(ctrlName,"PilatusType")==0)
		SVAR PilatusType=root:Packages:Convert2Dto1D:PilatusType
		PilatusType=popStr
	endif
	if(cmpstr(ctrlName,"PilatusFileType")==0)
		SVAR PilatusFileType=root:Packages:Convert2Dto1D:PilatusFileType
		PilatusFileType=popStr
	endif
	if(cmpstr(ctrlName,"PilatusColorDepth")==0)
		SVAR PilatusColorDepth=root:Packages:Convert2Dto1D:PilatusColorDepth
		if(stringmatch("64",popstr))
			Abort "64 bit color depth is not supported on Igor, please contact author and provide example data to test"
		endif
		PilatusColorDepth=popStr
	endif
End


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function ReadBrukerCCD_SMARTFile(FileToOpen, NewWaveName)	//returns wave with image in the current data folder, temp folder is deleted
	String FileToOpen
	String NewWaveName		
	
	//this is loader for Bruker (Siemens) CCD files produced by SMART program
	//modified from code provided by Jeff Grothaus-JT/PGI@PGI, grothaus.jt@pg.com  8/2004
	//Jan Ilavsky, 8/2004
	//The file format is following:
	// 1	ASCII header with a lot of information rarely used, read size (n x n) and number of bytes used
	// 2 	Binary data in either 8 or 16 bit size for n x n pixles 
	// 3 	overfolow pixles table - contains intensity and addresses for pixles, whose intensity was higher than fit in the 8 or 16 bits binary data

	if(strlen(NewWaveName)==0)
		Abort "Bad NewWaveName passed to ReadBrukerCCD_SmartFile routine"
	endif
	String DescriptionFromInput=""

	string OldDf=GetDataFolder(1)
	setDataFolder root:
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:BrukerImport 
	
	Variable fileID
	String FileData
	Variable StartOfImage			//header padded to multiple of 512 bytes: HDRBLKS * 512
	Variable SizeOfImage 			//in the real thing get this from the header ncols * nrows
	Variable StartOfOverflowTable 		//=SizeOfImage + Size of header
	Variable NumberOfOverflows    		//NOVERFL
	Variable SizeOfOverflowTable 		//noverfl * 16 chars per entry + 1
	Variable BytesPerPixel 			//get from NPIXELB
	Variable Timer
	Variable ElapsedTime
	String Center
	Variable pos
	Variable NumHeaderBlocks
	Variable NumHeaderElements	
	String CheckString
	String msgStr
	String DataName
	String XYDataName
	String NewFolderPath		//new data folder for this data set
	Variable NumCols
	Variable NumRows
	Variable SampDetDist		//DISTANC sample to detector in cm
	Variable Xcenter
	Variable Ycenter
	Variable BinFactor = 1
	String Description					//First line named TITLE
	String CreateDate		//CREATED, date & time file was created
	String FileType = "Bruker/Siemens SMART"
	
//Set description to input description
	Description = DescriptionFromInput

	Open /R /T="????" fileID  as FileToOpen
	FStatus fileID
//make sure file exists, it ought to...
	If(!V_Flag)
		print "File: " + S_Path + S_fileName + " doesn't exist."
			setDataFolder OldDf
			abort
	EndIf
//make sure that this really is a Siemens file.  Seems like first 18 bytes of file should read FORMAT:  86.
	FSetPos FileID, 0
	FReadLine /N=18 FileID, CheckString
//may be necessary to add code (and another input variable to function definition) so that this message
//does not choke a multifile open operation.  If multifile open is in progress write message to history area 
//and continue.
	If(!Stringmatch(CheckString, "FORMAT :        86"))		//8 spaces between colon and 86
		msgStr = "The first character in the file does not seem correct for a Siemens 2D data file. ... 'Yes' to continue or 'No' to quit."
		DoAlert 1, msgStr
		If (V_Flag == 2) 	//DoAlert sets V_flag, = 2 quit; = 1 continue
			setDataFolder OldDf
			abort
		EndIf
	EndIf

//get number of entrees in header.  The third header element, HDRBLKS indicates the  
//number of 512 byte blocks in header.  As of 5/1999 this is 15 blocks which is 96 header
//elements: 15 * 512 / 80.  If this routine fails, a default of 15 blocks is used.
	FSetPos FileID, 160		//third element in header starts here
	FReadLine /N=18 FileID, CheckString
	pos = strsearch(CheckString, "HDRBLKS:", 0)
	If(pos >= 0)
		CheckString = CheckString[pos + 8, strlen(CheckString)] 	//remove characters
		NumHeaderBlocks = str2num(CheckString)
	Else
		NumHeaderBlocks = 15		//default, this is the current standard 5/1999.
	EndIf
	NumHeaderElements = floor(NumHeaderBlocks * 512 / 80) 	//convert to number of header lines, 96 as of 5/1999
	DataName = NewWaveName
	Make /O /T /N=(NumHeaderElements, 2) SiemensHeader
	SiemensHeader = ""

	Variable HeaderLine = 0
	FSetPos FileID, 0
	Do
		FReadLine /N=80 fileID, FileData
		If(char2num(FileData) == 26)	//control-z, end of header marker
			break
		EndIf
		SiemensHeader[HeaderLine][0] = FileData[0,6]		//Variable Name
		SiemensHeader[HeaderLine][1] = FileData[8,79]		//Variable Contents
		HeaderLine += 1
	While (HeaderLine < NumHeaderElements)
//Load variables from header:
	NumRows = str2num(NI1_GetHeaderVal("NROWS", SiemensHeader))		//Number of rows
	NumCols = str2num(NI1_GetHeaderVal("NCOLS", SiemensHeader))			//Number of columns
	BytesPerPixel = str2num(NI1_GetHeaderVal("NPIXELB", SiemensHeader))	//Number of bytes per pixel
	CreateDate = (NI1_GetHeaderVal("CREATED", SiemensHeader))
	SampDetDist  = str2num(NI1_GetHeaderVal("DISTANC", SiemensHeader))
	Center = (NI1_GetHeaderVal("CENTER", SiemensHeader))
	Xcenter = str2num(Center)
	Ycenter = NumCols - str2num(Center[17,strlen(Center)])	//Siemens refs vs lower left, we do upper left corner
	NumberOfOverflows = str2num(NI1_GetHeaderVal("NOVERFL", SiemensHeader))	//Number of pixel overflows
	SizeOfOverflowTable = NumberOfOverflows * 16 + 1		//noverfl * 16 chars per entry
//Now only use description passed through DescriptionFromInput
	StartOfImage = NumHeaderBlocks * 512	//512 bytes per header block.
	SizeOfImage = NumRows * NumCols

//get image data
	Make /O /N=(SizeOfImage) ImageData
	ImageData = 0
	FSetPos FileID, StartOfImage
	Variable ImagePixel = 0
	Variable ImageDataPixel
	FBinRead /F=(BytesPerPixel) /U FileID, ImageData

//--------------------------------overflow table routine-----------------------------------
//if NumberOfOverflows is greater than zero, then load overflow table and add back to data
//otherwise skip this and continue with cleanup
	If(NumberOfOverflows > 0)
		StartOfOverflowTable = StartOfImage + SizeOfImage*BytesPerPixel
		FSetPos FileID, StartOfOverflowTable
	
		make /O/N=(NumberOfOverflows,2)  OverflowTable
		OverflowTable = 0
		variable oftInc = 0
		Do
			FReadLine /N=9 fileID, FileData
			OverflowTable[oftInc][0] = str2num(FileData)
			FReadLine /N=7 fileID, FileData
			OverflowTable[oftInc][1] = str2num(FileData)
			oftInc += 1
		While (oftInc <NumberOfOverflows)
		//add back overflow table
		oftInc = 0
		make /O /N=(NumberOfOverflows,3) oftcheck
		oftcheck = 0
		Variable DataPixel
	Do
		DataPixel = OverflowTable[oftInc][1]
		oftcheck[oftInc][0] = DataPixel
		oftcheck[oftInc][1] =  OverflowTable[oftInc][0]
		oftcheck[oftInc][2] = ImageData[DataPixel]
		ImageData[DataPixel] = OverflowTable[oftInc][0]
		oftInc += 1
		While (oftInc < NumberOfOverflows)
	EndIf
//--------------------------------overflow table routine-----------------------------------

//now that overflows have been added into the data set, convert image data to 2dim data set
	Redimension /U /N=(NumCols,NumRows) ImageData
	
	Close fileID
	string NewWaveNote=""
	NewWaveNote+="NumCols:"+num2str(NumCols)+";"
	NewWaveNote+="NumRows:"+num2str(NumRows)+";"
	NewWaveNote+="Xcenter:"+num2str(Xcenter)+";"
	NewWaveNote+="Ycenter:"+num2str(Ycenter)+";"
	NewWaveNote+="SampDetDist:"+num2str(SampDetDist)+";"
	NewWaveNote+="BinFactor:"+num2str(BinFactor)+";"
	NewWaveNote+="Description:"+Description+";"
	NewWaveNote+="CreateDate:"+CreateDate+";"
	NewWaveNote+="FileType:"+FileType+";"
	variable i
	For(i=0;i<numpnts(SiemensHeader);i+=1)
		NewWaveNote=ReplaceStringByKey(NI1_RemoveLeadTermSpaces(SiemensHeader[0][i]), NewWaveNote, NI1_RemoveLeadTermSpaces(SiemensHeader[1][i]), ":", ";")
	endfor
	note ImageData, NewWaveNote
	setDataFolder OldDf
	Duplicate/O 	ImageData, $(NewWaveName)
	KillWaves /Z OverflowTable, oftCheck, ImageData, SiemensHeader
	KillDataFolder root:Packages:BrukerImport
	
	return 1
	
End


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


static Function/S NI1_GetHeaderVal(HeadVar, SiemensHeader)
	String HeadVar
	Wave /T SiemensHeader
	Variable NumEntries = DimSize(SiemensHeader, 0)
	
	Variable inc = 0
	Variable pos
	Do
		pos = strsearch(SiemensHeader[inc][0], HeadVar, 0)
		If (pos >= 0)
			return SiemensHeader[inc][1]
		EndIf
		inc += 1
	While (inc < NumEntries)
	
End

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


static Function/S NI1_RemoveLeadTermSpaces(InputStr)	//removes leading and terminating spaces from string
	String InputStr
	
	string OutputStr=InputStr
	variable i
	for(i=strlen(OutputStr)-1;i>0;i-=1)	//removes terminating spaces
		if(cmpstr(OutputStr[i]," ")==0)
			OutputStr=OutputStr[0,i-1]
		else
			break	
		endif
	endfor
	if((cmpstr(OutputStr[0]," ")==0))
		Do
			OutputStr = OutputStr[1,inf]
		while (cmpstr(OutputStr[0]," ")==0)
	endif

	return OutputStr	
End


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************



structure  RigakuHeader
	char DeviceName[10]
	char Version[10]
	char CrystalName[20]
	char CrystalSystem[12]
	float LatticeA  
	float LatticeB 
	float LatticeC  
	float LatticeAlpha  
	float LatticeBeta 
	float LatticeGamma  
	char SpaceGroup[12]
	float MosaicSpread  
	char Memo[80]
	char Reserve[84]

	char Date_[12]
	char MeasurePerson[20]
	char Xraytarget[4]
	float Wavelength  
	char Monochromator[20]
	float MonocromatorDq  
	char Collimator[20]
	char Filter[4]
	float CameraLength_mm  
	float XrayTubeVoltage  
	float XrayTubeCurrent
	char XrayFocus[12]
	char XrayOptics[80]
	int32 CameraShape	
	float WeissenbergOscillation
	char Reserve2[56]

	char MountAxis[4]
	char BeamAxis[4]
	float something7
	float StartSomething 
	float EndSomething
	int32 TimesOfOscillation
	float ExposureTime
	float DirectBeamPositionX
	float DirectBeamPositionY
	float Something8 
	float Something9
	float Something10
	float Something11
	char Reserve3[100]
	char Reserve3a[100]
	char Reserve3b[4]

	int32 xDirectionPixNumber
	int32 yDirectionPixNumber
	float xDirectionPixelSizeMM
	float yDirectionPixelSizeMM
	int32 RecordLengthByte
	int32 NumberOfRecord
	int32 ReadStartLine
	int32 IPNumber
	float OutPutRatioHighLow
	float FadingTime1
	float FadingTime2
	char HostComputerClass[10]
	char IPClass[10]
	int32 DataDirectionHorizontal
	int32 DataDirectionVertical
	int32 DataDirectionFrontBack

	float shft	//;         /* pixel shift, R-AXIS V */
	float ineo	//;         /* intensity ratio E/O R-AXIS V */
	int32  majc	//;         /* magic number to indicate next values are legit */
       int32  naxs	//;         /* Number of goniometer axes */
	float gvec1[5]//;   /* Goniometer axis vectors */
	float gvec2[5]//;   /* Goniometer axis vectors */
	float gvec3[5]//;   /* Goniometer axis vectors */
	float gst[5]//;       /* Start angles for each of 5 axes */
       float gend[5]//;      /* End angles for each of 5 axes */
       float goff[5]//;      /* Offset values for each of 5 axes */ 
       int32  saxs//;         /* Which axis is the scan axis? */
	char  gnom[40]//;     /* Names of the axes (space or comma separated?) */
//
///*
// * Most of below is program dependent.  Different programs use
// * this part of the header for different things.  So it is essentially 
// * a big "common block" area for dumping transient information.
// */
   char  file[16]//;     /* */
   char  cmnt[20]//;     /* */
   char  smpl[20]//;     /* */
   int32  iext//;         /* */
   int32  reso//;         /* */
   int32  save_//;         /* */
   int32  dint//;         /* */
   int32  byte//;         /* */
   int32  init//;         /* */
   int32  ipus//;         /* */
   int32  dexp//;         /* */
   int32  expn//;         /* */
   int32  posx[20]//;     /* */
   int32  posy[20]//;     /* */
   int16   xray//;         /* */
   char  res51[100]//;    /* reserved space for future use */
   char  res52[100]//;    /* reserved space for future use */
   char  res53[100]//;    /* reserved space for future use */
   char  res54[100]//;    /* reserved space for future use */
   char  res55[100]//;    /* reserved space for future use */
   char  res56[100]//;    /* reserved space for future use */
   char  res57[100]//;    /* reserved space for future use */
   char  res58[68]//;    /* reserved space for future use */
//
	
endstructure


structure  RigakuHeaderOld	//this is header acording to older document. It seems like Rigaku itself has no sense in this... 
	char DeviceName[10]
	char Version[10]
	char CrystalName[20]
	char CrystalSystem[12]
	float LatticeA  
	float LatticeB 
	float LatticeC  
	float LatticeAlpha  
	float LatticeBeta 
	float LatticeGamma  
	char SpaceGroup[12]
	float MosaicSpread  
	char Memo[80]
	char Reserve[84]

	char Date_[12]
	char MeasurePerson[20]
	char Xraytarget[4]
	float Wavelength  
	char Monochromator[20]
	float MonocromatorDq  
	char Collimator[20]
	char Filter[4]
	float CameraLength_mm  
	float XrayTubeVoltage  
	float XrayTubeCurrent
	char XrayFocus[10]			//note, first change between Rigaku header and RigakuheaderOld 
	char XrayOptics[80]
//	int32 CameraShape	
//	float WeissenbergOscillation
//	char Reserve2[56]
	char Reserve2[66]

	char MountAxis[4]
	char BeamAxis[4]
	float something7
	float StartSomething 
	float EndSomething
	int32 TimesOfOscillation
	float ExposureTime
	float DirectBeamPositionX
	float DirectBeamPositionY
	float Something8 
	float Something9
	float Something10
	float Something11
	char Reserve3[100]
	char Reserve3a[100]
	char Reserve3b[4]

	int32 xDirectionPixNumber
	int32 yDirectionPixNumber
	float xDirectionPixelSizeMM
	float yDirectionPixelSizeMM
	int32 RecordLengthByte				
	int32 NumberOfRecord
	int32 ReadStartLine
	int32 IPNumber
	float OutPutRatioHighLow
	float FadingTime1
	float FadingTime2
	char HostComputerClass[10]
	char IPClass[10]
	int32 DataDirectionHorizontal
	int32 DataDirectionVertical
	int32 DataDirectionFrontBack

	char   reserve4[100]
	char   reserve4a[80]
	//and these were created in the reserve?
//	float shft	//;         /* pixel shift, R-AXIS V */
//	float ineo	//;         /* intensity ratio E/O R-AXIS V */
//	int32  majc	//;         /* magic number to indicate next values are legit */
//       int32  naxs	//;         /* Number of goniometer axes */
//	float gvec1[5]//;   /* Goniometer axis vectors */
//	float gvec2[5]//;   /* Goniometer axis vectors */
//	float gvec3[5]//;   /* Goniometer axis vectors */
//	float gst[5]//;       /* Start angles for each of 5 axes */
//       float gend[5]//;      /* End angles for each of 5 axes */
//       float goff[5]//;      /* Offset values for each of 5 axes */ 
//       int32  saxs//;         /* Which axis is the scan axis? */
//	char  gnom[40]//;     /* Names of the axes (space or comma separated?) */
//
///*
// * Most of below is program dependent.  Different programs use
// * this part of the header for different things.  So it is essentially 
// * a big "common block" area for dumping transient information.
// */
   char  file[16]//;     /* */
//   char  cmnt[20]//;     /* */
//  char  smpl[20]//;     /* */
   int32  iext//;         /* */
   int32  reso//;         /* */
   int32  save_//;         /* */
   int32  dint//;         /* */
   int32  byte//;         /* */
//   int32  init//;         /* */
//   int32  ipus//;         /* */
//   int32  dexp//;         /* */
//   int32  expn//;         /* */
//   int32  posx[20]//;     /* */
//   int32  posy[20]//;     /* */
//   int16   xray//;         /* */
   char  res51[100]//;    /* reserved space for future use */
   char  res52[100]//;    /* reserved space for future use */
   char  res53[100]//;    /* reserved space for future use */
   char  res54[100]//;    /* reserved space for future use */
   char  res55[100]//;    /* reserved space for future use */
   char  res56[100]//;    /* reserved space for future use */
   char  res57[100]//;    /* reserved space for future use */
   char  res58[100]//;    /* reserved space for future use */
   char  res59[100]//;    /* reserved space for future use */
   char  res60[56]//;    /* reserved space for future use */
//
	
endstructure


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


static Function/T NI1A_ReadRigakuUsingStructure(PathName, FileNameToLoad)
		string PathName, FileNameToLoad
		
		string Headerline

		variable RefNum
		string testline
		variable testvar
		STRUCT RigakuHeader RH
		STRUCT RigakuHeaderOld RHOld
		open /R/P=$(PathName) RefNum as FileNameToLoad
		FBinRead/b=2 RefNum, RH
		close RefNum
		
	string NewKWList=""
//1 	Device Name 	Character 	10 	10
	NewKWList+= "Device Name:"+RH.DeviceName +";" 
////2 	Version 	Character 	10 	20
	NewKWList+= "Version:"+RH.Version+";" //	char Version[10]
////3 	Crystal name 	Character 	20 	40
	NewKWList+= "CrystalName:"+RH.CrystalName+";"//	char CrystalName[20]
////4 	Crystal system 	Character 	12 	52
	NewKWList+= "CrystalSystem:"+RH.CrystalSystem+";"//	char CrystalSystem[12]
////5 	ａ（Å） 	Real Number 	4 	56
	NewKWList+= "LatticeA:"+num2str(RH.LatticeA)+";"//	float LatticeA  
////6 	ｂ（Å） 	Real Number 	4 	60
	NewKWList+= "LatticeB:"+num2str(RH.LatticeB)+";"//	float LatticeB 
///////7 	ｃ（Å） 	Real Number 	4 	64
	NewKWList+= "LatticeC:"+num2str(RH.LatticeC)+";"//	float LatticeC  
//////8 	α 	Real Number 	4 	68
	NewKWList+= "LatticeAlpha:"+num2str(RH.LatticeAlpha)+";"//	float LatticeAlpha  
////////9 	β 	Real Number 	4 	72
	NewKWList+= "LatticeBeta:"+num2str(RH.LatticeBeta)+";"//	float LatticeBeta  
//////10 	γ 	Real Number 	4 	76
	NewKWList+= "LatticeGamma:"+num2str(RH.LatticeGamma)+";"//	float LatticeGamma  
//////11 	Space group 	Character 	12 	88
	NewKWList+= "SpaceGroup:"+RH.SpaceGroup+";"//	char SpaceGroup[12]
//////12 	Mosaic spread 	Real Number 	4 	92
	NewKWList+= "MosaicSpread:"+num2str(RH.MosaicSpread)+";"//	float MosaicSpread  
//////13 	Memo 	Character 	80 	172

	NewKWList+= "Memo:"+RH.Memo+";"//	char Memo[80]
//////14 	Reserve 	Character 	84 	256
//	char Reserve[84]
//////15 	Date 	Character 	12 	268
	NewKWList+= "Date:"+RH.Date_+";"//	char Date_[12]
//////16 	Measure Person 	Character 	20 	288
	NewKWList+= "MeasurePerson:"+RH.MeasurePerson+";"//	char MeasurePerson[20]
//////17 	X-ray Target 	Character 	4 	292
	NewKWList+= "Xraytarget:"+RH.Xraytarget+";"//	char Xraytarget[4]
//////18 	Wavelength 	Real Number 	4 	296
	NewKWList+= "Wavelength:"+num2str(RH.Wavelength)+";"//	float Wavelength  
//////19 	Monochrometer 　　 	Character 	20 	316
	NewKWList+= "Monochromator:"+RH.Monochromator+";"//	char Monochromator[20]
//////20 	Monochrome２θ（°） 	Real Number 	4 	320
	NewKWList+= "MonocromatorDq:"+num2str(RH.MonocromatorDq)+";"//	float MonocromatorDq  
//////21 	Collimeter 	Character 	20 	340
	NewKWList+= "Collimator:"+RH.Collimator+";"//	char Collimator[20]
//////22 	Ｋβ Filter 	Character 	4 	344
	NewKWList+= "v:"+RH.Filter+";"//	char Filter[4]
//////23 	Camera Length (mm) 	Real Number 	4 	348
	NewKWList+= "CameraLength_mm:"+num2str(RH.CameraLength_mm)+";"//	float CameraLength_mm  
//////24 	X-ray Pipe Volgage　 	Real Number 	4 	352
	NewKWList+= "XrayTubeVoltage:"+num2str(RH.XrayTubeVoltage)+";"//	float XrayTubeVoltage  
//////25 	X-ray  Electric Current 	Real Number 	4 	356
	NewKWList+= "XrayTubeCurrent:"+num2str(RH.XrayTubeCurrent)+";"//	float XrayTubeCurrent
//////26 	X-ray Focus 	Character 	12 	368
	NewKWList+= "XrayFocus:"+RH.XrayFocus+";"//	char XrayFocus[12]
//////27 	X-ray Optics 	Character 	80 	448
	NewKWList+= "XrayOptics:"+RH.XrayOptics+";"//	char XrayOptics[80]
//////28 	Camera Shape 	Integer 	4 	0:flat   452
	NewKWList+= "CameraShape:"+num2str(RH.CameraShape)+";"//	int32 CameraShape	
//////29 	Weissenberg Oscillation 	Real Number 	4   456	
	NewKWList+= "WeissenbergOscillation:"+num2str(RH.WeissenbergOscillation)+";"//	float WeissenbergOscillation
//////30 	Reserve 	Character 	56 	512
//	char Reserve2[56]
//////31 	Mount Axis 	Character 	4 	±reciprocal lattice axis		516
	NewKWList+= "MountAxis:"+RH.MountAxis+";"//	char MountAxis[4]
//////32 	Beam Axis 	Character 	4 	±lattice axis					520
	NewKWList+= "BeamAxis:"+RH.BeamAxis+";"//	char BeamAxis[4]
//////33 	φ0 	Real Number 	4 								524
//	float something7
////34 	φ Start 	Real Number 	4 			528
//	float StartSomething 
////35 	φ End 	Real Number 	4 	
//	float EndSomething
////36 	Times of Oscillation 	Integer 	4 	
//	int32 TimesOfOscillation
////37 	Exposure Time (minutes) 	Real Number 	4 	
	NewKWList+= "ExposureTime:"+num2str(RH.ExposureTime)+";"//	float ExposureTime
////38 	Direct Beam Position (x) 	Real Number 	4 	
	NewKWList+= "DirectBeamPositionX:"+num2str(RH.DirectBeamPositionX)+";"//	float DirectBeamPositionX
////39 	Direct Beam Position (y) 	Real Number 	4 	
	NewKWList+= "DirectBeamPositionY:"+num2str(RH.DirectBeamPositionY)+";"//	float DirectBeamPositionY
////40 	ω（θ） 	Real Number 	4 	
//	float Something8 
////41 	χ 	Real Number 	4 	
//	float Something9
////42 	２θ 	Real Number 	4 	
//	float Something10
////43 	μ 	Real Number 	4 	
//	float Something11
////44 	Reserve 	Character 	180 	
//	char Reserve3[100]
//	char Reserve3a[80]
////45 	x Direction Pixel Number 	Integer 	4 	
	NewKWList+= "xDirectionPixNumber:"+num2str(RH.xDirectionPixNumber)+";"//	int32 xDirectionPixNumber
////46 	y Direction Pixel Number 	Integer 	4 	
	NewKWList+= "yDirectionPixNumber:"+num2str(RH.yDirectionPixNumber)+";"//	int32 yDirectionPixNumber
////47 	x Direction Pixel Size (mm) 	Real Number 	4 	
	NewKWList+= "xDirectionPixelSizeMM:"+num2str(RH.xDirectionPixelSizeMM)+";"//	float xDirectionPixelSizeMM
////48 	y Direction Pixel Size (mm) 	Real Number 	4 	
	NewKWList+= "yDirectionPixelSizeMM:"+num2str(RH.yDirectionPixelSizeMM)+";"//	float yDirectionPixelSizeMM
////49 	Record Length (Byte) 	Integer 	4 	
	NewKWList+= "RecordLengthByte:"+num2str(RH.RecordLengthByte)+";"//	int32 RecrodLengthByte
////50 	Number of Record 	Integer 	4 	
	NewKWList+= "NumberOfRecord:"+num2str(RH.NumberOfRecord)+";"//	int32 NumberOfRecord
////51 	Read Start Line 	Integer 	4 	
	NewKWList+= "ReadStartLine:"+num2str(RH.ReadStartLine)+";"//	int32 ReadStartLine
////52 	IP Number 	Integer 	4 	
	NewKWList+= "IPNumber:"+num2str(RH.IPNumber)+";"//	int32 IPNumber
////53 	Output Ratio (High/Low) 	Real Number 	4 	
	NewKWList+= "OutPutRatioHighLow:"+num2str(RH.OutPutRatioHighLow)+";"//	float OutPutRatioHighLow
////54 	Fading Time 1 	Real Number 	4 	Time to exposure completion to Read Start
	NewKWList+= "FadingTime1:"+num2str(RH.FadingTime1)+";"//	float FadingTime1
////55 	Fading Time 2 	Real Number 	4 	Time to exposure completion to Read End
	NewKWList+= "FadingTime2:"+num2str(RH.FadingTime2)+";"//	float FadingTime2
////56 	Host Computer Classification	Character 	10 	
	NewKWList+= "HostComputerClass:"+RH.HostComputerClass+";"//	char HostComputerClass[10]
////57 	IP Classification 	Character 	10 	
	NewKWList+= "IPClass:"+RH.IPClass+";"//	char IPClass[10]
////58 	Data Direction (horizontal direction) 	Integer 	4 	0: From Left to Right, 1: From Right to Left
	NewKWList+= "DataDirectionHorizontal:"+num2str(RH.DataDirectionHorizontal)+";"//	int32 DataDirectionHorizontal
////59 	Data Direction (vertical direction) 	Integer 	4 	0: From Down to Up,1: Up to Down
	NewKWList+= "DataDirectionVertical:"+num2str(RH.DataDirectionVertical)+";"//	int32 DataDirectionVertical
////60 	Data Direction (front and back) 	Integer 	4 	0:Front1:Back
	NewKWList+= "DataDirectionFrontBack:"+num2str(RH.DataDirectionFrontBack)+";"//	int32 DataDirectionFrontBack
////61 	Reserve 	Character 	10 	
	NewKWList+= "Byte:"+num2str(RH.byte)+";"//	int32 byte = is this endiness???
//	char Reserve4[10]
//
//print "NewRigakuHeader"
	variable newRecordLengt =  RH.RecordLengthByte
	variable NewOutputRatioHighLow =  RH.OutputRatioHighLow
		open /R/P=$(PathName) RefNum as FileNameToLoad
		FBinRead/b=2 RefNum, RHOld
		close RefNum
//print "OldRigakuHeader"
	variable oldRecordLengt =   RHOld.RecordLengthByte
	variable oldOutputRatioHighLow =   RHOld.OutputRatioHighLow

	if(newRecordLengt!=oldRecordLengt || NewOutputRatioHighLow!=oldOutputRatioHighLow)
		NVAR/Z RigakuRaxisHeaderWarning
		if(!NVAR_Exists (RigakuRaxisHeaderWarning))
			variable/g RigakuRaxisHeaderWarning
			DoAlert 0, "This Rigaku file has problem with header parameters reading, please send example of this file to author with some meaningful descrition"
		endif
	endif
	if(Rh.byte>0 || RHold.byte>0 )
		NVAR/Z RigakuRaxisHeaderWarning2
		if(!NVAR_Exists (RigakuRaxisHeaderWarning2))
			variable/g RigakuRaxisHeaderWarning2
			DoAlert 0, "This Rigaku file has byte set in the header. It may have different endiness. Please, send example to author and include descrition of file source"
		endif
	endif
	
	
	return NewKWList
end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


static Function NI1A_RigakuFixNegValues(w,ratio)
	wave w
	variable ratio
	
	//string tempName=NameOfWave(w)
	w = w[p][q]>0? w[p][q] : abs(W[p][q]) * ratio

end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

structure  RigakuReadByte
	int32 TestByte
endstructure

Function NI1A_FindFirstNonZeroChar(PathName, FileNameToLoad)
	string PathName, FileNameToLoad

		STRUCT RigakuReadByte RH
		variable RefNum
		open /R/P=$(PathName) RefNum as FileNameToLoad
		FsetPos  RefNum, 2000
//		FsetPos  RefNum, 0
		
		Do
			FBinRead/b=2 RefNum, RH
		while (RH.TestByte <=0)
		FStatus RefNum
		close RefNum
		return V_filePos

end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function/S NI1_LoadWinViewFile(fName, NewWaveName)
	String fName											// fully qualified name of file to open
	String NewWaveName		

//	Variable refNum
//	if (strlen((OnlyWinFileName(fName)))<1)				// call dialog if no file name passed
//		Open /D/M=".spe file"/R/T="????" refNum		// use /D to get full path name
//		fName = S_filename
//	endif
//	if (strlen(fName)<1)									// no file name, quit
//		return ""
//	endif

	String wName = NI1_WinViewReadROI(fName,0,-1,0,-1)	// load file into wName
	if (strlen(wName)<1)
		return ""
	endif
	Wave image = $wName
//	if (ItemsInList(GetRTStackInfo(0))<=1)
		String wnote = note(image)
		Variable xdim=NumberByKey("xdim", wnote,"=")
		Variable ydim=NumberByKey("ydim", wnote,"=")
		String bkgFile = StringByKey("bkgFile", wnote,"=")
		printf "for file '"+fName+"'"
		if (strlen(bkgFile)>0)
			printf ",             background file = '%s'",  bkgFile
		endif
		printf "\r"
		printf "total length = %d x %d  = %d points\r", xdim,ydim,xdim*ydim
		print "number type is  '"+NI1_WinViewFileTypeString(NumberByKey("numType", wnote,"="))+"'"
//		print "Created a 2-d wave    '"+wName+"'"
//		DoAlert 1, "Display this image"
//		if (V_Flag==1)
//			Graph_imageMake(image,NaN)
//		endif
		duplicate/O image, $(NewWaveName)
		killwaves image
//	endif
//	return GetWavesDataFolder(image,2)
End



//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


proc NI1_BSLWindow()

	string DF
	DF=getdatafolder(1)
	setdatafolder root:Packages:

	DoWindow NI1_BSLpanel
	if(V_flag)
		DoWindow/F NI1_BSLpanel
		setvariable bslcurrentframes, win=NI1_BSLpanel, limits={1,root:Packages:NI1_BSLFiles:BSLFrames,1}
	else
	//Josh add:  o.k., we need to add a way to sum over a few selected frames.  this is prolly something that 
	//only I will use, but still
		SetDataFolder root:Packages:NI1_BSLFiles
		if(BSLcurrentframe==0)
			root:Packages:NI1_BSLFiles:BSLAverage=1
		endif
		NewPanel/K=1/W=(200,100,550,400)/N=NI1_BSLpanel
		
		setvariable pixels, win=NI1_BSLpanel, title="pixels count", value=root:Packages:NI1_BSLFiles:BSLpixels, pos={10,10}, size={120,20}, noedit=1
		setvariable bypixels, win=NI1_BSLpanel, title="by", value=root:Packages:NI1_BSLFiles:BSLpixels1, pos={140,10}, size={120,20},noedit=1
//		setvariable BSLFoundFrames, win=NI1_BSLpanel, title="Found frames", value=root:Packages:NI1_BSLFiles:BSLFoundFrames, pos={10,30}, size={120,20}, noedit=1
		setvariable bslframes, win=NI1_BSLpanel, title="Found Frames :", value=root:Packages:NI1_BSLFiles:BSLframes, pos={10,30}, size={160,20}, noedit=1
		setvariable bslcurrentframes, win=NI1_BSLpanel, title="Selected frame", value=root:Packages:NI1_BSLFiles:BSLcurrentframe, pos={10,50}, size={150,20}, limits={1,root:Packages:NI1_BSLFiles:BSLFoundFrames,1}
		checkbox Average, win=NI1_BSLpanel, title="or - Average all frames?", variable=root:Packages:NI1_BSLFiles:BSLAverage, pos={170,50}, size={100,20} , proc=NI1_BSLCheckProc
		setvariable BSLIo, win=NI1_BSLpanel, title="Io", value=root:Packages:NI1_BSLFiles:BSLI1, pos={10,70}, size={120,20}
		setvariable BLSIs, win=NI1_BSLpanel, title="Is", value=root:Packages:NI1_BSLFiles:BSLI2, pos={160,70}, size={120,20}
		 listbox saxsnote, win=NI1_BSLpanel, listwave=root:Packages:NI1_BSLFiles:BSLheadnote, pos={5,105}, size={295,85}
		// josh add
		checkbox sumoverframes,win=NI1_BSLpanel,title="sum over selected frames",variable=root:Packages:NI1_BSLFiles:BSLsumframes,pos={5,200},proc=NI1_BSLCheckProc
		button displaylog, win=NI1_BSLpanel,title="show the log file",pos={5,230},size={200,20},proc=NI1_BSLbuttonProc
		setvariable fromframe, win=NI1_BSLpanel,title="from frame",pos={5,260},size={180,20},variable=root:Packages:NI1_BSLFiles:BSLfromframe,disable=1
		setvariable toframe, win=NI1_BSLpanel,title="to frame",pos={200,260},size={180,20},variable=root:Packages:NI1_BSLFiles:BSLtoframe,disable=1
	endif
	setDataFolder Df
endmacro


Function BSL_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
//				controlInfo /W=NI1A_Convert2Dto1DPanel Select2DInputWave
//				Wave/T ListOf2DSampleData = root:Packages:Convert2Dto1D:ListOf2DSampleData
//				NI1_BSLloadbslinfo(ListOf2DSampleData[V_Value])
		case 2: // Enter key
				controlInfo /W=NI1A_Convert2Dto1DPanel Select2DInputWave
				Wave/T ListOf2DSampleData = root:Packages:Convert2Dto1D:ListOf2DSampleData
				NI1_BSLloadbslinfo(ListOf2DSampleData[V_Value])
				break
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
	endswitch

	return 0
End


//NI1_BSLloadbslinfo(SelectedWv, resetCounter)
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function NI1_BSLCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
		//josh add the code for the sumover frames checkbox to enable/disable the from and to variable.
			
			Variable checked = cba.checked
			if(cmpstr(cba.ctrlname,"Average")==0)
				NVAR BSLcurrentframe = root:Packages:NI1_BSLFiles:BSLcurrentframe
				if(checked)
					BSLcurrentframe=0
				else
					BSLcurrentframe=1
				endif
				elseif(cmpstr(cba.ctrlname,"sumoverframes")==0)
					if(checked)
					setvariable fromframe, win=NI1_BSLpanel,disable=0
					setvariable toframe, win=NI1_BSLpanel,disable=0
					else
					setvariable fromframe, win=NI1_BSLpanel,disable=1
					setvariable toframe, win=NI1_BSLpanel,disable=1
					endif
				endif
				break
	endswitch

	return 0
End

function NI1_BSLbuttonProc(ctrlname):buttoncontrol
string ctrlname
if(cmpstr(ctrlname,"displaylog")==0)
wave/t Listof2DSampleData=$("root:Packages:Convert2Dto1D:ListOf2DSampleData")
wave Listof2DSampleDataNumbers=$("root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers")
variable i
string logfile
for(i=0;i<(dimsize(Listof2DSampleData,0));i+=1)
	if(Listof2DSampleDataNumbers[i])
	logfile=Listof2DSampleData[i]
	logfile=logfile[0,2]+"LOG."+stringfromlist(1,logfile,".")
	break
	endif
endfor
	loadwave/J/M/L={0,29,0,1,0}/V={" ","$",0,0}/N=timseq/P=$("Convert2Dto1DDataPath") logfile
	wave timseq0
	variable ,j,n
	n=-1
	for(i=0;i<dimsize(timseq0,0);i+=1)

		for(j=0;j<timseq0[i][0];j+=1)
		n+=1
		make/o/d/n=(n+1) Timeseq
		Timeseq[n]=0
		Timeseq[n]=timseq0[i][4]+timseq0[i][1]
		endfor
	endfor
	DoWindow Frames0
	if(V_flag)
	killwindow Frames0
	endif
	edit/k=1/N=Frames Timeseq



endif
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************



Function NI1_MainListBoxProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
					//5=cell select with shift key, 6=begin edit, 7=end
	Variable i
	if(cmpstr(ctrlName,"Select2DInputWave")==0)
		wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
		wave/t ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
	if(event==4)
		controlinfo/W=NI1A_Convert2Dto1Dpanel Select2DDataType
		if(cmpstr(S_Value,"BSL/SAXS")==0 || cmpstr(S_Value,"BSL/WAXS")==0)
			
			for(i=0;i<(dimsize(ListOf2DSampleDataNumbers,0));i+=1)
				if(ListOf2DSampleDataNumbers[i]==1)
					NI1_BSLloadbslinfo(ListOf2DSampleData[i])
					break //just display fist selected file
				endif
			endfor
			execute "NI1_BSLWindow()"
		endif
	endif
	endif
	return 0
End

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//***************************************** **************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


static function NI1_BSLloadbslinfo(SelectedWv)
		string SelectedWv
		
		string OldDf=GetDataFolder(1)
		setdatafolder root:Packages:Convert2Dto1D:
		string filebeg
		string fileext
		string head1
		variable i
	//	wave ListOf2DSampleDataNumbers
	//	wave/t ListOf2DSampleData
	//	for(i=0;i<(dimsize(ListOf2DSampleData,0));i+=1)
	//		if(ListOf2DSampleDataNumbers[i]==1)
				filebeg=stringfromlist(0,SelectedWv,".")
				fileext=stringfromlist(1,SelectedWv,".")//ext for all
				head1=filebeg[0]+filebeg[1]+filebeg[2]
				//now we have first three characters i.e. A01
				string filewaxs, filesaxs, filecal, fileInfo
				fileInfo=head1+"000."+fileext
				filewaxs=head1+"003."+fileext
				filesaxs=head1+"001."+fileext
				filecal=head1+"002."+fileext
		             loadwave/N=header/J/K=1/M/L={0,2,0,0,8}/V={" ","$",0,1}/P=$("Convert2Dto1DDataPath") fileInfo
				wave header0
				
				NVAR waxschannels=$("root:Packages:NI1_BSLFiles:BSLwaxschannels")
				NVAR waxsframe=$("root:Packages:NI1_BSLFiles:BSLwaxsframes")
				NVAR saxsframe=$("root:Packages:NI1_BSLFiles:BSLframes")
				NVAR pixel=$("root:Packages:NI1_BSLFiles:BSLpixels")
				NVAR pixel1=$("root:Packages:NI1_BSLFiles:BSLpixels1")
				wave/t headnote=$("root:Packages:NI1_BSLFiles:BSLheadnote")
				NVAR currentframe=$("root:Packages:NI1_BSLFiles:BSLcurrentframe")
				NVAR fromframe=$("root:Packages:NI1_BSLFiles:BSLfromframe")
				NVAR toframe=$("root:Packages:NI1_BSLFiles:BSLtoframe")
				NVAR sumframes=$("root:Packages:NI1_BSLFiles:BSLsumframes")
				NVAR Average=$("root:Packages:NI1_BSLFiles:BSLaverage")

				waxschannels=header0[4][1]
				waxsframe=header0[4][2]
				saxsframe=header0[0][3]
				pixel=header0[0][1]
				pixel1=header0[0][2]
				//currentframe=1//reset current frame to 1
				//load the header notes
		
				loadwave/N=headernote/J/K=2/M/P=$("Convert2Dto1DDataPath") fileInfo
				wave/t headernote0
				
				headnote=headernote0
				//load calibration file
				
				GBLoadWave/O/Q/N=cal/T={2,96}/W=1/P=$("Convert2Dto1DDataPath") filecal
				wave cal0
		
				if(cal0[1]<1)
					GBLoadWave/O/Q/b=1/N=cal/T={2,96}/W=1/P=$("Convert2Dto1DDataPath") filecal
				endif
				NVAR I1=$("root:Packages:NI1_BSLFiles:BSLI1")
				NVAR I2=$("root:Packages:NI1_BSLFiles:BSLI2")
				I1=cal0[currentframe-1]
				I2=cal0[saxsframe+currentframe-1]
				//JOSH ADD.............
				if(sumframes)
					I1=sum(cal0,	(fromframe-1),(toframe-1))
					I2=sum(cal0,(saxsframe-fromframe-1),(saxsframe-toframe-1))
				elseif(average)
					I1=sum(cal0,0,(saxsframe-1))/(saxsframe)
					I2=sum(cal0,(saxsframe),(saxsframe*2-1))/(saxsframe)
				endif
				NVAR SampleI0 = root:Packages:Convert2Dto1D:SampleI0
				SampleI0=I1
//				break
//			endif		
//		endfor
		setDataFolder OldDf
end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function NI1_LoadBSLFiles(SelectedFileToLoad)
	string SelectedFileToLoad

	string OldDf
	OldDf=getdatafolder(1)
	setdatafolder root:Packages:
	SetDataFolder root:Packages:NI1_BSLFiles

	//PathInfo $("Convert2Dto1DDataPath")
			
	getfilefolderinfo/P=$("Convert2Dto1DDataPath") SelectedFileToLoad
			
	NVAR BSLpixels=$("root:Packages:NI1_BSLFiles:BSLpixels1")
	NVAR BSLpixels1=$("root:Packages:NI1_BSLFiles:BSLpixels")
	NVAR BSLframes=$("root:Packages:NI1_BSLFiles:BSLframes")
	NVAR BSLcurrentframe=$("root:Packages:NI1_BSLFiles:BSLcurrentframe")
	NVAR BSLAverage = $("root:Packages:NI1_BSLFiles:BSLAverage")
	NVAR BSLsumframes = $("root:Packages:NI1_BSLFiles:BSLsumframes")
	NVAR BSLfromframe = $("root:Packages:NI1_BSLFiles:BSLfromframe")
	NVAR BSLtoframe = $("root:Packages:NI1_BSLFiles:BSLtoframe")
	BSLframes=V_logEOF/4/(BSLpixels*BSLpixels1)
	variable bsli
	if(BSLframes>=1)			
	//it is easier to load the file here they can be very large, that way it only loads once
		GBLoadWave/W=(BSLframes)/Q/T={2,4}/J=1/S=0/U=(BSLpixels*BSLpixels1)/N=saxs/P=$("Convert2Dto1DDataPath") SelectedFileToLoad
		
		if(BSLAverage)	
			wave FirstFrame=saxs0
			Duplicate/O FirstFrame, saxs_average
			for(bsli=0;bsli<BSLframes;bsli+=1)
				wave saxs=$("saxs"+num2str(bsli))
				saxs_average+= saxs
			endfor
			saxs_average/=BSLframes
			BSLcurrentframe=0
			//josh add sumover frames
		elseif(BSLsumframes)
		///check this........................
			wave SelFrame=$("saxs"+num2str(BSLfromframe-1))		//use numbering from 1 not from 0. It should be more user friendly. 
			Duplicate/O SelFrame, saxs_average
			for(bsli=(BSLfromframe);bsli<(BSLtoframe);bsli+=1)
			wave saxs=$("saxs"+num2str(bsli))
			saxs_average+=saxs
			endfor
		else
			wave SelFrame=$("saxs"+num2str(BSLcurrentframe-1))		//use numbering from 1 not from 0. It should be more user friendly. 
			Duplicate/O SelFrame, saxs_average
		endif
		redimension /N=(BSLpixels,BSLpixels1) saxs_average
	else
		Make/O/N=(100,100) saxs_average
		saxs_average = 0
		DoAlert  0, "No data in this BSL data file"
	endif
	Duplicate/O saxs_average, temp2DWave
	//attach wave note: use the wave BSLheadNote, but update it first in case we are processing larger number of files. 
	NI1_BSLloadbslinfo(SelectedFileToLoad)
	wave/t headnote=$("root:Packages:NI1_BSLFiles:BSLheadnote")
	variable i
	string tempNote=""
	For(i=0;i<numpnts(headnote);i+=1)
		tempNote+=headnote[i]+";"
	endfor
	note temp2DWave, tempNote
	setDataFolder OldDf
	return BSLcurrentframe
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

static Function/S NI1_ReadFujiImgHeader(PathName, filename)
	string PathName, filename
	
	string infFilename=filename[0,strlen(filename)-5]+".inf"
	variable FnVar
	open /P=$(PathName)/R/Z FnVar as infFilename
	//if(Z!=0)
	//	Abort "Inf file does not exist, cannot load Fuji image file"
	//endif
	string Informations=""
	string tempstr, tempstr1, tempstr2
	freadline FnVar, tempstr
	Informations+="Header:"+tempstr+";"
	freadline FnVar, tempstr
	Informations+="OriginalFileName:"+tempstr+";"
	freadline FnVar, tempstr
	Informations+="PlateSize:"+tempstr+";"
	freadline FnVar, tempstr
	Informations+="PixelSizeX:"+tempstr+";"
	//BAS2000 can do either 100 or 200 micron sizes
	//BAS2500 50, 100 or 200 micron
	freadline FnVar, tempstr
	Informations+="PixelSizeY:"+tempstr+";"
	freadline FnVar, tempstr
	Informations+="BitsPerPixel:"+tempstr+";"
	//BAS2000 can do either 8 or 10 bits/pixel
	//BAS2500 8 or 16
	freadline FnVar, tempstr
	Informations+="PixelsInRaster:"+tempstr+";"
	freadline FnVar, tempstr
	Informations+="NumberOfRasters:"+tempstr+";"
	freadline FnVar, tempstr
	Informations+="Sensitivity:"+tempstr+";"
	//BAS2000 can be 400, 1000, 4000 or 10000 but user defined any value in this range is possible... 
	// BAS2500 For latitude 4, you may select sensitivity 1000, 4000 or 10000. For  latitude 5, sensitivity may be set to 4000, 10000 or 30000
	freadline FnVar, tempstr
	Informations+="Latitude:"+tempstr+";"
	//BAS2000 can do Latitude 1, 2, 3, or 4
	//BAS2500 can do 4 and 5
	freadline FnVar, tempstr
	Informations+="DateAndTime:"+tempstr+";"
	freadline FnVar, tempstr
	Informations+="NumberOfBytesInFile:"+tempstr+";"
	//from here the file format is different for BAS2000 and BAS2500
	freadline FnVar, tempstr1
	freadline FnVar, tempstr2
	if(stringmatch(tempstr2, "*IPR2500*" ))		//IPR2500
		Informations+="ImagePlateType:"+"IPR2500"+";"
		freadline FnVar, tempstr
		Informations+="ImageReaderType:"+"BAS2500"+";"
		//I do nto have BAS2500 file to test what else is in the inf file... 
	else			//BAS2000
		Informations+="NumberOfOverflowPixels:"+tempstr1+";"
		freadline FnVar, tempstr
		freadline FnVar, tempstr		
		Informations+="UserDescription:"+tempstr+";"
		freadline FnVar, tempstr
		Informations+="ImageSize:"+tempstr+";"
		freadline FnVar, tempstr
		Informations+="ImagePlateType:"+tempstr+";"
		freadline FnVar, tempstr
		Informations+="ImageReaderType:"+tempstr+";"
		freadline FnVar, tempstr
		Informations+="SomeKindOfComment:"+tempstr+";"
	endif
	
	Informations =ReplaceString("\r", Informations, "" )
	return Informations
	
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1_FujiBASChangeEndiness()
			NVAR/Z FujiEndinessSetting = root:Packages:Convert2Dto1D:FujiEndinessSetting
			if(!NVAR_Exists(FujiEndinessSetting))
				variable/g root:Packages:Convert2Dto1D:FujiEndinessSetting
				NVAR FujiEndinessSetting = root:Packages:Convert2Dto1D:FujiEndinessSetting
				FujiEndinessSetting=0
			else
				FujiEndinessSetting=!FujiEndinessSetting
			endif
			

end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

static Function NI1_ReadFujiImgFile(PathName, filename, FujiFileHeader)
	string PathName, filename, FujiFileHeader

		//first - there can be 8, 10,  or 16 bits in the file per point and 
		// 16 bits can be byte swapped (little/big endian). Need to deal with them separately...
		variable BitsPerPixel
		BitsPerPixel=NumberByKey("BitsPerPixel", FujiFileHeader  , ":", ";")
		if(BitsPerPixel==8)
			//GBLoadWave/Q/B=1/T={8,4}/W=1/P=$(PathName)/N=Loadedwave filename
			//this does not look like signed 8 bit word, it is unsigned 8 bit word... 
			GBLoadWave/Q/B=1/T={72,4}/W=1/P=$(PathName)/N=Loadedwave filename
		elseif(BitsPerPixel==16)
		//	Abort "Only 8 bit image depth has been tested. Please, send details and case examples on this higher-buit depth images to Author (ilavsky@aps.anl.gov) to improve the reader"
			NVAR/Z FujiEndinessSetting = root:Packages:Convert2Dto1D:FujiEndinessSetting
			if(!NVAR_Exists(FujiEndinessSetting))
				variable/g root:Packages:Convert2Dto1D:FujiEndinessSetting
				NVAR FujiEndinessSetting = root:Packages:Convert2Dto1D:FujiEndinessSetting
				FujiEndinessSetting=0
			endif
			if(FujiEndinessSetting)
				GBLoadWave/T={16,16}/W=1 /P=$(PathName)/N=Loadedwave filename
				print "Fuji Image file reader read with high-byte first (Motorolla, little endian). If it is incorrect, issue following command from command line:   NI1_FujiBASChangeEndiness()  "
			else
//			//    low byte first:
				GBLoadWave/B/T={16,16}/W=1 /P=$(PathName)/N=Loadedwave filename	
				print "Fuji Image file reader read with low-byte first (Intel, big endian). If it is incorrect, issue following command from command line:   NI1_FujiBASChangeEndiness()  "
			endif
		else
			Abort "Seems like you have 10 bit image. This type of image is not yet supported. Please sedn test files to author"	
		endif
		variable NumPntsX=NumberByKey("PixelsInRaster", FujiFileHeader , ":", ";")
		variable NumPntsY=NumberByKey("NumberOfRasters", FujiFileHeader , ":", ";")
		Wave Loadedwave0
		redimension/D Loadedwave0
		variable Gval
		if(BitsPerPixel==8)		//thsi is binning of the image depth. 8 bits here
			Gval=(2^8)-1
		elseif(BitsPerPixel==10)	//10 bits here
			Gval=(2^10)-1
		else							//assume 16 bits...
			Gval=(2^16)-1
		endif

		//fix overflow pixels, hopefully this fixes them...  This followds IDL code by Heinz
		if(BitsPerPixel==8)
		
		elseif(BitsPerPixel==16)			//this should be signed integer, so we need to deal with this... 
			Loadedwave0 = (Loadedwave0[p]<0) ? (Loadedwave0[p]+ Gval) : Loadedwave0[p]
		endif
		//This is from H.Amenitsch, clearly he assumes only 16 bit depth
		//		  G =  2.^16										
		//		  raw =  10^(5*(raw/G)-0.5)						do the calculations
		//		  raw =  (float(pixelsizex)/100.)^2*raw
		// Mark Rivers description:
		//; PROCEDURE:
		//;   This function converts values measured by the BAS2000 scanner into
		//;   actual x-ray intensities according to the equation:
		//;
		//;       PSL = (4000/S)*10^(L*QSL)/1023 - 0.5)
		//;   where
		//;       PSL = x-ray intensity
		//;       S   = sensitivity setting
		//;       L   = latitude setting
		//;       QSL = measured value from BAS2000
		//;
		//;   This equation appears somewhere in the BAS2000 documentation?
		//This is Tom Irving... 
		//#define CONVERT	256
		//#define MAXPIXVALUE 1024
		//
		///*	Conversion for all Fuji scans is take pixel value, multiply by
		//	latitude (4 or 5 for 4 or 5 orders of magnitude) and divide by
		//	2^bitdepth where bitdepth is 10 or 16 for bas2000 and bas2500
		//	respectively and then take base 10 antilog. So to lineralize
		//	data you divide the input value which can be at most
		//	 MAXPIXVALUE =2^bitdepth by CONVERT and then take the
		//	 base 10 antilog
		//
		//        cooment JIL - I suspect that the formula should be:
		//;       PSL = (MaxSensitivity/Sensitivity)*10^(Latitude*(MeasuredData/BitDepth) - 0.5)


		variable Sensitivity=NumberByKey("Sensitivity", FujiFileHeader , ":", ";")
		variable Latitude=NumberByKey("Latitude", FujiFileHeader , ":", ";")
		
		variable MaxSensitivity=10000
		if(stringmatch(stringByKey("ImageReaderType:",FujiFileHeader , ":", ";"), "*BAS2000*"))
			MaxSensitivity=10000
		else		//assume BAS2500
			if (stringmatch(stringByKey("Latitude:",FujiFileHeader , ":", ";"), "*4*") )
				MaxSensitivity=10000
			else //latitude 5
				MaxSensitivity=30000
			endif
		endif
		variable FudgeToFit2D=2.3625
		//scale data to max sensitivity of the reader, so data from same instrument with different sensitivity can be compared... 
		variable tempVar = (MaxSensitivity/Sensitivity)/FudgeToFit2D
		//Loadedwave0 =  tempVar *10^(Latitude*(Loadedwave0[p]/Gval) - 0.5)
		MatrixOp/O Loadedwave0 =  tempVar *powR(10,(Latitude*(Loadedwave0/Gval) - 0.5))

		//Now, Heinz has this normalized somehow by area of pixel... Weird, I would assume I need to divide by area, not multiply. Leave it out for now... 
	//	variable pixelSizeX = NumberByKey("PixelSizeX", FujiFileHeader , ":", ";")
	//	variable pixelSizeY = NumberByKey("PixelSizeY", FujiFileHeader , ":", ";")
	//	variable MultConst = (pixelSizeX/100)*(pixelSizeY/100)
	//	Loadedwave0 = MultConst*Loadedwave0 
		redimension/N=(NumPntsX,NumPntsY) Loadedwave0

end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************




Function NI1_ESRFEdfLoaderPanelFnct() : Panel
	
	DoWindow  NI1_ESRFEdfLoaderPanel
	if(V_Flag)
		DoWindow/F NI1_ESRFEdfLoaderPanel
	else
		NVAR ESRFEdf_ExposureTime=root:Packages:Convert2Dto1D:ESRFEdf_ExposureTime
		NVAR ESRFEdf_Center_1=root:Packages:Convert2Dto1D:ESRFEdf_Center_1
		NVAR ESRFEdf_Center_2=root:Packages:Convert2Dto1D:ESRFEdf_Center_2
		NVAR ESRFEdf_PSize_1=root:Packages:Convert2Dto1D:ESRFEdf_PSize_1
		NVAR ESRFEdf_PSize_2=root:Packages:Convert2Dto1D:ESRFEdf_PSize_2
		NVAR ESRFEdf_SampleDistance=root:Packages:Convert2Dto1D:ESRFEdf_SampleDistance
		NVAR ESRFEdf_SampleThickness=root:Packages:Convert2Dto1D:ESRFEdf_SampleThickness
		NVAR ESRFEdf_WaveLength=root:Packages:Convert2Dto1D:ESRFEdf_WaveLength
		NVAR ESRFEdf_Title=root:Packages:Convert2Dto1D:ESRFEdf_Title
		PauseUpdate; Silent 1		// building window...
		NewPanel/K=1 /W=(240,98,600,300) as "ESRF EDF loader config panel"
		DoWindow/C NI1_ESRFEdfLoaderPanel
		SetDrawLayer UserBack
		SetDrawEnv fsize= 18,fstyle= 3,textrgb= (0,0,65280)
		DrawText 28,36,"Nika ESRF edf Loader Config"

		Checkbox ESRFEdf_Title,pos={15,70},size={122,21},noproc,title="Read Sample name? "
		Checkbox  ESRFEdf_Title,help={"Select if you want to read sample name from EDF file"}, variable=root:Packages:Convert2Dto1D:ESRFEdf_Title
		Checkbox ESRFEdf_ExposureTime,pos={15,85},size={122,21},noproc,title="Read Exposure time? "
		Checkbox  ESRFEdf_ExposureTime,help={"Select if you want to read exposure time from EDF file"}, variable=root:Packages:Convert2Dto1D:ESRFEdf_ExposureTime
		Checkbox ESRFEdf_SampleThickness,pos={15,100},size={122,21},noproc,title="Read Sample thickness? "
		Checkbox  ESRFEdf_SampleThickness,help={"Select if you want to read sample thickness from EDF file"}, variable=root:Packages:Convert2Dto1D:ESRFEdf_SampleThickness

	
		Checkbox ESRFEdf_SampleDistance,pos={195,70},size={122,21},noproc,title="Read SDD? "
		Checkbox  ESRFEdf_SampleDistance,help={"Select if you want to read sample to detector distance from EDF file"}, variable=root:Packages:Convert2Dto1D:ESRFEdf_SampleDistance
		Checkbox ESRFEdf_WaveLength,pos={195,85},size={122,21},noproc,title="Read Wavelength? "
		Checkbox  ESRFEdf_WaveLength,help={"Select if you want to read wavelength from EDF file"}, variable=root:Packages:Convert2Dto1D:ESRFEdf_WaveLength


		Checkbox ESRFEdf_PSize_1,pos={195,100},size={122,21},noproc,title="Read Pixel size X? "
		Checkbox  ESRFEdf_PSize_1,help={"Select if you want to read pixel size X from EDF file"}, variable=root:Packages:Convert2Dto1D:ESRFEdf_PSize_1
		Checkbox ESRFEdf_PSize_2,pos={195,115},size={122,21},noproc,title="Read Pixel size Y? "
		Checkbox  ESRFEdf_PSize_2,help={"Select if you want to read pixel size Y from EDF file"}, variable=root:Packages:Convert2Dto1D:ESRFEdf_PSize_2
	
		Checkbox ESRFEdf_Center_1,pos={195,130},size={122,21},noproc,title="Read beam center X? "
		Checkbox  ESRFEdf_Center_1,help={"Select if you want to read beam center X from EDF file"}, variable=root:Packages:Convert2Dto1D:ESRFEdf_Center_1
		Checkbox ESRFEdf_Center_2,pos={195,145},size={122,21},noproc,title="Read beam center Y? "
		Checkbox  ESRFEdf_Center_2,help={"Select if you want to read beam center Y from EDF file"}, variable=root:Packages:Convert2Dto1D:ESRFEdf_Center_2

	endif
EndMacro

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
function /s pilatusload(PathName,FileName,FileType,NewWaveName,refnum,newnote)
	variable refnum
	string filename,pathname,filetype,newwavename,newnote
	string filenametoload = filename
	string testline
	       //Pilatus parameters
	NVAR PilatusReadAuxTxtHeader=root:Packages:Convert2Dto1D:PilatusReadAuxTxtHeader
	SVAR PilatusFileType=root:Packages:Convert2Dto1D:PilatusFileType
	SVAR  PilatusType=root:Packages:Convert2Dto1D:PilatusType
	SVAR PilatusColorDepth=root:Packages:Convert2Dto1D:PilatusColorDepth
	NVAR PilatusSignedData=root:Packages:Convert2Dto1D:PilatusSignedData
	       //read TXT header file, available at ALS... 
	if(PilatusReadAuxTxtHeader)
		Print FileName
		Make/T /O headertxt0
		String txtFile
		txtFile = FileNameToLoad 
		txtFile =  ReplaceString("edf", FileNameToLoad, "txt")
		NVAR SampleI0 = root:Packages:Convert2Dto1D:SampleI0
		NVAR EmptyI0 = root:Packages:Convert2Dto1D:EmptyI0
		LoadWave/J /P=$(PathName) /N=headertxt /L={0,0,35,0,0}/B="F=-2;" ,txtFile
		if(cmpstr(NewWaveName, "EmptyData")==0)
			EmptyI0 = str2num(headertxt0[1])
		else
			SampleI0 = str2num(headertxt0[1])
			Print SampleI0
		endif
		nvar alphaangle = root:Packages:Convert2Dto1D:LineProf_GIIncAngle
		variable i
		string alpha=""
		for(i=0;i<numpnts(headertxt0);i+=1)
			splitstring /e="^Alpha=(.*)$" headertxt0[i] , alpha
			if(cmpstr(alpha,""))
				alphaangle=str2num(alpha)
				break
			endif
		endfor
		nvar px=root:Packages:Convert2Dto1D:PixelSizeX
		nvar py=root:Packages:Convert2Dto1D:PixelSizeX
		nvar energy =root:Packages:Convert2Dto1D:XrayEnergy
		nvar wavelength=root:Packages:Convert2Dto1D:Wavelength
		energy=10
		wavelength = 12.42/(energy)	
		px=.172
		py=.172
		
	endif
	
	//  read header in teh file... , available ONLY for Tiff (4096 bytes) and edf (1024 bytes)
	variable PilskipBytes
	if(stringmatch(FileNameToLoad, "*.edf" ))
		PilskipBytes=1024
	elseif(stringmatch(FileNameToLoad, "*.tif" )||stringmatch(FileNameToLoad, "*.tiff" ))
		PilskipBytes=4096
	else
		PilskipBytes=0
	endif
	if(PilskipBytes>0)
		open /R/P=$(PathName) RefNum as FileNameToLoad
		testLine=""
		testLine=PadString (testLine, PilskipBytes, 0x20)
		FBinRead RefNum, testLine
		close RefNum
	else
		testLine=""
	endif
	//end read header
	
	
	//read the Pilatus file itself
	variable PilatusColorDepthVar=str2num(PilatusColorDepth)
	//color depth can be 8, 16, or 32 unsigned integers or unsigned integer 64, but that is not supported by Igor, to denote them in Igor as unnsigned, need to add 64 ...
	if(PilatusColorDepthVar<64 && PilatusSignedData)   //PilatusSignedData=1 when unsigned integers, default signed integers
		PilatusColorDepthVar+=64		//now we have proper 8, 16, or 32 unsigned integers for Igor... 
	endif

	killwaves/Z Loadedwave0,Loadedwave1
	if(stringMatch(PilatusFileType,"edf"))
		GBLoadWave/B/T={PilatusColorDepthVar,PilatusColorDepthVar}/S=1024/W=1 /P=$(PathName)/N=Loadedwave FileNameToLoad
	elseif(stringMatch(PilatusFileType,"tiff")||stringMatch(PilatusFileType,"tif"))
		GBLoadWave/B=(1)/T={PilatusColorDepthVar,PilatusColorDepthVar}/S=4096/W=1 /P=$(PathName)/N=Loadedwave FileNameToLoad
	elseif(stringMatch(PilatusFileType,"float-tiff"))
		GBLoadWave/B=(1)/T={4,4}/S=4096/W=1 /P=$(PathName)/N=Loadedwave FileNameToLoad
	elseif(stringMatch(PilatusFileType,"img"))
		GBLoadWave/B=(1)/T={PilatusColorDepthVar,PilatusColorDepthVar}/W=1 /P=$(PathName)/N=Loadedwave FileNameToLoad
	endif
	Wave LoadedWave0
	if(stringmatch(PilatusType,"Pilatus100k"))
		Redimension/N=(487,195) Loadedwave0
	elseif(stringmatch(PilatusType,"Pilatus1M"))
		Redimension/N=(981,1043) Loadedwave0
	elseif(stringmatch(PilatusType,"Pilatus2M"))
		Redimension/N=(1475,1679) Loadedwave0
	else
		Abort "Unknown Pilatus Type"
	endif
	duplicate/O Loadedwave0, $(NewWaveName)
	#if(exists("PilatusHookFunction")==3)
		PilatusHookFunction(FileNameToLoad)
	#endif             
	killwaves Loadedwave0
	NewNote+="DataFileName="+FileNameToLoad+";"
	NewNote+="DataFileType="+PilatusType+";"
	NewNote+=testLine+";"
	return newnote
 end
 
 
 function /wave AUSW_loadxml(xmlfile)
	variable xmlfile
	XMLlistXpath(xmlfile,"//LOGLINE","")
	wave m_listxPath
	variable num = dimsize(M_listXPath,0)
	XMLelemlist(xmlfile)
	wave w_elementlist
	DeletePoints/M=1 0,2, W_ElementList
	DeletePoints/M=1 1,1, W_ElementList
	duplicate /o w_elementlist, root:Packages:NikaAuSW:logfile
	//make /o/n=(num) /t root:Packages:NikaAuSW:filenames
	//wave /t filenames = root:Packages:NikaAuSW:filenames
	//filenames = replacestring(" ",(ParseFilePath(0,XMLstrFmXpath(xmlfile,"//LOGLINE["+num2str(p+1)+"]/text()","",""), "/", 1, 0)),"")
	xmllistattr(xmlfile,"//CAMERADEFS | //DETECTORDEF","title")
	string /g root:Packages:NikaAuSW:AUSW_detectorpropertieslist
	svar AUSW_detectorpropertieslist=root:Packages:NikaAuSW:AUSW_detectorpropertieslist
	wave /t M_listATTR
	variable j
	for(j=0;j<=dimsize(M_listattr,0);j+=1)
		AUSW_detectorpropertieslist += M_listattr[j][1] + "=" + M_listattr[j][2] + ";"
	endfor
	return logfile
end

 function /wave AUSW_loadlog(logfilewave)
	wave/t logfilewave
	duplicate/o logfilewave, root:Packages:NikaAuSW:logfile
	wave/t logfile = root:Packages:NikaAuSW:logfile
	logfile = replacestring(">/data/",replacestring("</LOGLINE>",replacestring("=",replacestring("<LOGLINE ",replacestring("\" ",replacestring(" = \"", logfile[p],"="),";"),""),":"),""),"FileName:")
	
end

function AUSW_findimagebyname(xmf,name)
	variable xmf
	string name
	wave /T files = root:Packages:NikaAuSW:filenames// = AUSW_getimagenamesfromxml(xmf)
	make/o/d /n=5000 sampleomegas, exposuretimes, I0s
	make/o /t/n=5000 matchingnames
	FindValue /TEXT=name /Z files
	variable j=0,logv
	if(v_value>=0)
		do
			XMLlistAttr(xmf,"//LOGLINE["+num2str(v_value+1)+"]","")
			wave/T M_listAttr
			duplicate M_listAttr, Logfilewave
			logv=v_value
			findvalue /TEXT="SampleOmega" /Z M_listAttr
			sampleomegas[j]=str2num( M_listAttr[mod(v_value,dimsize(M_listAttr,0))][2] )
			findvalue /TEXT="EXPTIME" /Z M_listAttr
			exposuretimes[j] = str2num(M_listAttr[mod(v_value,dimsize(M_listAttr,0))][2])
			findvalue /TEXT="I0" /Z M_listAttr
			I0s[j] = str2num(M_listAttr[mod(v_value,dimsize(M_listAttr,0))][2])
			matchingnames[j] = files[logv]
			
			FindValue /TEXT=name /S=(logv+1) /Z files
			j+=1
		while(v_value >=0 && j<5000)
	endif
	redimension /n=(j) sampleomegas, exposuretimes, I0s,matchingnames
	xmllistattr(xmf,"//CAMERADEFS | //DETECTORDEF","title")
	string /g AUSW_detectorpropertieslist
	wave /t M_listATTR
	for(j=0;j<=dimsize(M_listattr,0);j+=1)
		AUSW_detectorpropertieslist += M_listattr[j][1] + "=" + M_listattr[j][2] + ";"
	endfor
end

function AUSW_Loaderf()
	PauseUpdate; Silent 1		// building window...
	dowindow /k AUSW_Loader
	string foldersave = getdatafolder(1)
	newdatafolder /o/s root:Packages
	newdatafolder /o/s NikaAUSW
	NVAR/z AUSW_AdjustUsername
	if(NVAR_exists(AUSW_AdjustUsername)!=2)
		string/G AUSW_XMPPath
		Variable/G AUSW_XML_Loaded=0
		Variable/G AUSW_Load_Params=1
		Variable/G AUSW_Load_I0=1
		Variable/G AUSW_Load_Exp=1
		Variable/G AUSW_Load_GA=1
		Variable/G  AUSW_basenamelen=9
		Variable/G  AUSW_basenamestart=0
		Variable/G  AUSW_AddTemptoName=0
		Variable/G  AUSW_AddGrazingtoName=1
		string/G  AUSW_basename=""
		
		Variable/G AUSW_AdjustUsername
	else
		NVAR AUSW_XML_Loaded
		NVAR AUSW_Load_Params
		NVAR AUSW_Load_I0
		NVAR AUSW_Load_Exp
		NVAR AUSW_Load_GA
		NVAR AUSW_basenamelen
		NVAR AUSW_basenamestart
		NVAR AUSW_AddTemptoName
		NVAR AUSW_AddGrazingtoName
		SVAR AUSW_basename
		nvar AUSW_AdjustUsername
	endif
	NewPanel /k=1/n=AUSW_Loader/W=(1207,77,1674,233) as "Au SAXS-WAXS Loader"
	SetDrawLayer UserBack
	DrawText 70,29,"Path to XML File"
	TitleBox AUSW_XML_Path_Disp,pos={7,34},size={249,22},help={"Path to XML File"}
	TitleBox AUSW_XML_Path_Disp,labelBack=(48896,65280,48896)
	TitleBox AUSW_XML_Path_Disp,variable= root:Packages:NikaAUSW:AUSW_XMPPath,fixedSize=1
	Button XML_Path_Browse,pos={10,10},size={50,20},title="Browse",proc=AUSW_Browse_but
	CheckBox AUSW_XMLParams_Pop,proc=AUSW_CheckProc,pos={12,57},size={234,26},title="Load Parameters from XML File on image load\r (overwrite existing values)"
	CheckBox AUSW_XMLParams_Pop,variable= root:Packages:NikaAUSW:AUSW_Load_Params
	CheckBox AUSW_XMLEXP_Pop,proc=AUSW_CheckProc,pos={12,112},size={182,14},title="Load Exposure Time from XML File"
	CheckBox AUSW_XMLEXP_Pop,variable= root:Packages:NikaAUSW:AUSW_Load_Exp
	CheckBox AUSW_XMLI0_Pop,proc=AUSW_CheckProc,pos={12,89},size={121,14},title="Load I0 from XML File"
	CheckBox AUSW_XMLI0_Pop,variable= root:Packages:NikaAUSW:AUSW_Load_I0
	CheckBox AUSW_XMLGA_Pop,proc=AUSW_CheckProc,pos={12,135},size={178,14},title="Load Grazing Angle from XML File"
	CheckBox AUSW_XMLGA_Pop,variable= root:Packages:NikaAUSW:AUSW_Load_GA
	TitleBox title0,pos={165,10},size={50,17},title="LOADED",font="Arial Black",frame=0
	CheckBox AUSW_addgrazingcheck,pos={294,112},size={152,14},proc=AUSW_CheckProc,title="Add Grazing Angle to Name"
	CheckBox AUSW_addgrazingcheck,variable= root:Packages:NikaAUSW:AUSW_AddGrazingtoName
	CheckBox AUSW_addtempcheck,pos={294,136},size={144,14},proc=AUSW_CheckProc,title="Add Temperature to Name"
	CheckBox AUSW_addtempcheck,variable= root:Packages:NikaAUSW:AUSW_AddTemptoName
	SetVariable AUSW_var_basenamestart,pos={304,41},size={145,18},bodyWidth=52,title="Start of basename"
	SetVariable AUSW_var_basenamestart,value= root:Packages:NikaAUSW:AUSW_basenamestart
	SetVariable AUSW_var_basenamelen,pos={287,61},size={162,18},bodyWidth=51,title="Number of Characters"
	SetVariable AUSW_var_basenamelen,value= root:Packages:NikaAUSW:AUSW_basenamelen
	SetVariable AUSW_var_basename,pos={292,81},size={157,18},bodyWidth=57,title="OR enter basename"
	SetVariable AUSW_var_basename,value= root:Packages:NikaAUSW:AUSW_basename
	CheckBox AUSW_adjustUsername_check,pos={282,17},size={171,14},proc=AUSW_CheckProc,title="Adjust Input name from Filename"
	CheckBox AUSW_adjustUsername_check,variable= root:Packages:NikaAUSW:AUSW_AdjustUsername
	AUSW_Update()
	setdatafolder foldersave
End

function AUSW_update()
	string foldersave = getdatafolder(1)
	setdatafolder root:Packages:NikaAuSW
	NVAR AUSW_XML_Loaded
	NVAR AUSW_Load_Params
	NVAR AUSW_Load_I0
	NVAR AUSW_Load_Exp
	NVAR AUSW_Load_GA
	NVAR AUSW_AdjustUsername
	if(AUSW_XML_Loaded==1)
		TitleBox AUSW_XML_Path_Disp win=AUSW_Loader,labelBack=(48896,65280,48896)
		TitleBox title0  win=AUSW_Loader,title="LOADED"
	else
		if(AUSW_Load_Params + AUSW_Load_I0 + AUSW_Load_Exp + AUSW_Load_GA == 0)
			TitleBox AUSW_XML_Path_Disp win=AUSW_Loader,labelBack=(0,0,0)
			TitleBox title0  win=AUSW_Loader,title="not needed"
		else
			TitleBox AUSW_XML_Path_Disp win=AUSW_Loader,labelBack=(65280,48896,48896)
			TitleBox title0  win=AUSW_Loader,title="NOT LOADED"
		endif
	endif
	if(!AUSW_AdjustUsername)
		CheckBox AUSW_addgrazingcheck, disable=1
		CheckBox AUSW_addtempcheck, disable=1
		SetVariable AUSW_var_basenamestart, disable=1
		SetVariable AUSW_var_basenamelen, disable=1
		SetVariable AUSW_var_basename, disable=1
	else
		CheckBox AUSW_addgrazingcheck, disable=0
		CheckBox AUSW_addtempcheck, disable=0
		SetVariable AUSW_var_basenamestart, disable=0
		SetVariable AUSW_var_basenamelen, disable=0
		SetVariable AUSW_var_basename, disable=0
	endif
	setdatafolder foldersave
end



Function AUSW_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			AUSW_update()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function AUSW_Browse_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			variable tempxmf
			nvar loaded = root:Packages:NikaAuSW:AUSW_XML_Loaded
			SVAR spath = root:Packages:NikaAuSW:AUSW_XMPPath
			open /D /R /F="XML files (*.xml,*.log):.xml,.log;" /M="Choose XML file for this data" /Z=2 tempxmf
			if(strlen(S_filename)>2)
				variable xmf = xmlopenfile(S_filename)
				if(xmf>0)
					xmllistattr(xmf,"//CAMERADEFS | //DETECTORDEF","title")
					wave M_listAttr
					if(dimsize(M_listAttr,0)>0)
						
						spath = S_filename
						
						loaded = 1
					endif
					AUSW_loadxml(xmf)
					xmlclosefile(xmf,0)
				else //  try to open it as a logfile, (ie no parameters, but just I0 for live updates
					make /n=0 /t/o temptextwave
					grep /e="LOGLINE" s_filename as temptextwave
					if(dimsize(temptextwave,0)>0)
						spath = S_filename
						AUSW_loadlog(temptextwave)
						loaded = 1
					endif
				endif
			endif
			AUSW_update()
			
			killwaves /z m_listattr, temptextwave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
function /s Colwavetostring(wavein)
	wave wavein
	variable col, colvalue
	string stringout="", dimlabel=""
	matrixop /o/free colsum = sumcols(wavein)
	for(col=0;col<dimsize(wavein,1);col+=1)
		dimlabel = getdimlabel(wavein,1,col)
		colvalue = colsum(col)/2
		stringout = addlistitem(dimlabel +":"+num2str(colvalue),stringout) 	
	endfor
	return stringout
end


function /s addmetadatafromjson(path, key, filename, metadatalist)
	string path, key, filename, metadatalist
	string kvalue
	grep /LIST/q/e="\"" + key+ "\": \"([^\"]*)\""/P=$(path) filename
	splitstring /e="\"" + key+ "\": \"([^\"]*)\"" s_value, kvalue
	metadatalist = addlistitem(key+":"+kvalue,metadatalist)
	return metadatalist
end