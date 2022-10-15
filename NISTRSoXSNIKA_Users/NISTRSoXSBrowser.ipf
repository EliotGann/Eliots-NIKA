#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "EGN_Loader"

function NRB_Loaddir([update])
	variable update
	update = paramisdefault(update)? 0 : update
// this function loads the current directory, looking for all *primary.csv, listing all the * basenames
// along with the number of files
	svar /z pname = root:Packages:NikaNISTRSoXS:pathname
	if(!svar_Exists(pname))
		//print "no directory"
		return -1
	endif
	string filenames = sortlist(IndexedFile($pname, -1, ".csv"),";",4)
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:NikaNISTRSoXS
	string /g oldcsvs
	if(stringmatch(oldcsvs,filenames))
		setdatafolder currentfolder
		NRB_loadprimary(update=1)
		return -2
	endif
	oldcsvs = filenames
	if(strlen(filenames)<1)
		make /o/n=(0,3) /t scanlist
		setdatafolder currentfolder
		//print "No txt files found in directory"
		return -3
	endif
	filenames = replacestring("-primary.csv",filenames,"")
	variable i
	
	
	
	for(i=itemsinlist(filenames)-1;i>=0;i-=1)
		if(stringmatch(stringfromlist(i,filenames),"*.csv"))
			filenames = removelistitem(i,filenames)
		endif
	endfor
	make /o/n=(itemsinlist(filenames),2) /t scanlist
	scanlist[][0]= stringfromlist(p,filenames)
	string tmppath = getenvironmentVariable("TMP")
	if(strlen(tmppath)<1)
		tmppath = getenvironmentVariable("TMPDIR")
	endif
	STRING tempfilename
	
	if(update==0)
		for(i=dimsize(scanlist,0)-1;i>=0;i-=1)
			newpath /o/q tempfolder, tmppath
			tempfilename = "RSoXSmd"+num2str(round(abs(enoise(100000))))+".csv"
			getfilefolderinfo /q/z /p=tempfolder tempfilename
			copyfile /o/p=$(pname) scanlist[i][0]+"-primary.csv" as tmppath+"\\"+ tempfilename
			LoadWave/Q/O/J/D/A/K=0/M /B="N=wave0;"/P=tempfolder tempfilename
			Variable err = GetRTError(0)
			IF (ERR !=0)
				deletefile /p=tempfolder tempfilename
				DELETEPOINTS /m=0 I,1,SCANLIST
				oldcsvs = REMOVELISTItem(I,oldcsvs)
				err = GetRTError(1)
			ELSE
				deletefile /p=tempfolder tempfilename
				wave wavein = $stringfromlist(0,s_waveNames)
				scanlist[i][1] = num2str(dimsize(wavein,0)-1)
			ENDIF
		endfor
	endif
	ListBox  ScansLB win=NISTRSoXSBrowser, selRow=(dimsize(scanlist,0)-1)
	//Controlupdate /W=NISTRSoXSBrowser ScansLB
	wave /z channellistsel
	channellistsel = 0
	NRB_loadprimary(row = dimsize(scanlist,0)-1)
	setdatafolder currentfolder
	return 1
	//listbox scansLB,selrow=-1
	
	
end

function NRB_loadprimary([update,row])
// when choosing a primary.csv file, populates a list of promary values, a scrollable list of baseline values
// and displays a list of datapoints with their primary motors defining the name
	variable update, row
	Execute "SetIgorOption Str2DoubleMode=0"
	update = paramisdefault(update)? 0 : update
	variable /g scanrow
	if(paramisdefault(row))
		controlInfo scansLB
		scanrow = v_value
	else
		scanrow = row
	endif
	wave /t scanlist = root:Packages:NikaNISTRSoXS:scanlist
	
	if(scanrow<0 || scanrow >= dimsize(scanlist,0))
		return -1
	endif
	
	string basename = scanlist[scanrow][0]
	string basenum
	splitstring /e="^([[:digit:]]*)" basename, basenum
	svar /z pname = root:Packages:NikaNISTRSoXS:pathname
	if(!svar_Exists(pname))
		return -1
	endif
	svar pathtodata = root:Packages:NikaNISTRSoXS:pathtodata
		
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:NikaNISTRSoXS
	string /g basescanname = basename
	string /g pnameimages = "NistRSoXS_Data"
	string /g pnamemd = "NistRSoXS_Metadata"
	newpath /o/q/z $pnameimages, pathtodata + basenum + ":"
	if(v_flag!=0)
		newpath /o/q $pnameimages, pathtodata
		pnamemd = pname
	else
		string listofjsonl = IndexedFile($pnameimages, -1, ".jsonl")
		if(strlen(listofjsonl)>0)
			pnamemd = pname
		else
			listofjsonl = IndexedFile($pnameimages, -1, ".json")
			if(strlen(listofjsonl)>0)
				pnamemd = pnameimages
			else
				pnamemd = pname
			endif
			
		endif
	endif

	killdatafolder /z channels
	newdatafolder /o/s channels
	//close /A
	string tmppath = getenvironmentVariable("TMP")
	if(strlen(tmppath)<1)
		tmppath = getenvironmentVariable("TMPDIR")
	endif
	newpath /o/q tempfolder, tmppath

	string tempfilename = "RSoXS"+num2str(round(abs(enoise(100000))))+".csv"
	getfilefolderinfo /q/z /p=tempfolder tempfilename
	copyfile /o/p=$(pname) basename+"-primary.csv" as tmppath+"\\"+ tempfilename
	LoadWave/q/O/J/D/A/K=0/P=tempfolder/W tempfilename
	deletefile/z /p=tempfolder tempfilename


	wave /z datawave = $(stringfromlist(0,S_waveNames))
	if(!waveexists(datawave))
		setdatafolder currentfolder
		return -1
	endif
	scanlist[scanrow][1] = num2str(dimsize(datawave,0))
	wave /t channellist = root:Packages:NikaNISTRSoXS:channellist
	wave channellistsel = root:Packages:NikaNISTRSoXS:channellistsel
	redimension /n=(itemsinlist(s_wavenames),2) channellist, channellistsel
	channellist[][1] = stringfromlist(p,s_wavenames)
	channellist[][0] = ""
	channellistsel[][0] = 32
	// pick out the channels to use for the sequence display
	wave /z en_energy, RSoXS_Sample_Outboard_Inboard, RSoXS_Sample_Up_Down
	wave /z seq_num
	wave /t steplist = root:Packages:NikaNISTRSoXS:steplist
	wave steplistsel = root:Packages:NikaNISTRSoXS:steplistsel
	variable oldnum = dimsize(steplist,0)
	steplist=""
	variable foundloc = 0
	redimension /n=(dimsize(seq_num,0)) steplist, steplistsel
	steplist[] = num2str(seq_num[p])
	if(whichlistitem("RSoXS_Sample_Outboard_Inboard",s_wavenames)>=0 && whichlistitem("RSoXS_Sample_Up_Down",s_wavenames)>=0)
		//redimension /n=(dimsize(RSoXS_Sample_Up_Down,0)) steplist, steplistsel
		steplist[] += " - ( " + num2str(round(RSoXS_Sample_Outboard_Inboard[p]*100)/100) + " , " + num2str(round(RSoXS_Sample_Up_Down[p]*100)/100) + " )"
		foundloc = 1
	elseif(whichlistitem("en_energy",s_wavenames)>=0)
		
		//redimension /n=(dimsize(en_energy,0)) steplist, steplistsel
		steplist[] += " - " + num2str(round(en_energy[p]*100)/100) + "eV"
	else 
	
		//not an energy scan, need to read something else .. what??
		
		//print "can't find energy"
		//redimension /n=(dimsize(seq_num,0)) steplist, steplistsel
		steplist[] = "image " + num2str(seq_num[p])
	endif
	
	if(whichlistitem("timeW",s_wavenames)>=0)
		wave /z times = timeW
	else
		wave /z times
	endif

	variable i
	if(dimsize(steplist,0)>oldnum && update)
		steplistsel = p>=oldnum ? 1 : steplistsel[p]
	endif	
	string matchingtiffs = IndexedFile($pnameimages, -1, ".tiff")
	
	string tifffilename
	
	variable stepswimages = 0
	for(i=0;i<(dimsize(seq_num,0));i+=1)
		tifffilename = stringfromlist(0,listMatch(matchingtiffs,basenum+"*image*"+num2str(i)+".tiff"))
		if(strlen(tifffilename)<4)
			steplist[i] += " (no image)"
		else
			stepswimages += 1
		endif
	endfor
	if(stepswimages<1)
		redimension /n=(1) steplist, steplistsel
		steplist = "no images"
		steplistsel = 0x80
		Button NRBCopyPos,disable=1
	else
		if(steplistsel[0] == 0x80)
			steplistsel = 0
		endif
	endif
	
	
	
	//monitors
	string mdfiles= indexedfile($(pnamemd),-1,".csv")
	string metadatafilenames = greplist(mdfiles,"^"+basename+".*_monitor[.]csv$")

	string mdfilename
	string monitorname
	duplicate /free times, goodpulse, rises, falls
	goodpulse = 0
	for(i=0;i<itemsinlist(metadatafilenames);i+=1)
		mdfilename = stringfromlist(i,metadatafilenames)
		Splitstring /e="^"+basename+"-(.*)_monitor[.]csv$" mdfilename, monitorname
		//print monitorname
		
		tmppath = getenvironmentVariable("TMP")
		if(strlen(tmppath)<1)
			tmppath = getenvironmentVariable("TMPDIR")
		endif
		newpath /o/q tempfolder, tmppath
		tempfilename = "RSoXSmd"+num2str(round(abs(enoise(100000))))+".csv"
		getfilefolderinfo /q/z /p=tempfolder tempfilename
		copyfile /o/p=$(pnamemd) mdfilename as tmppath+"\\"+ tempfilename
		LoadWave/L={0,1,0,0,2}/Q/O/J/D/n=$cleanupname(monitorname,0)/K=0/P=tempfolder/m tempfilename
		deletefile /p=tempfolder tempfilename
	
		
		
		wave mdwave = $stringfromlist(0,s_wavenames)
		wave newchannelwave = NRB_splitsignal(mdwave,times, rises, falls, goodpulse)
		if(waveexists(newchannelwave))
			insertpoints /M=0 0,1, channellist, channellistsel
			channellist[0][1] = nameofwave(newchannelwave)
			channellist[0][0] = ""
			channellistsel[0][0] = 32
		endif
	endfor
	
	
	if(update)
		// we are essentially done now, we don't need to reload the metadata or baseline info, which hasn't changed
		setdatafolder currentfolder
		NRB_updateimageplot()
		return 1
	endif
	
	//populate the baseline and metadata lists
	
	wave /t mdlist = root:Packages:NikaNISTRSoXS:mdlist
	
	string jsonfiles= indexedfile($(pnamemd),-1,".jsonl")
	string jsonext = ".jsonl"
	if(strlen(jsonfiles)==0)
		jsonfiles= indexedfile($(pnamemd),-1,".json")
		jsonext = ".json"
	endif
	variable jsonfound=0
	string metadatafilename
	string metadata=""
	if(strlen(jsonfiles) < 5)
		
		jsonfiles= indexedfile($(pnamemd),-1,".json")
		//print "Currently can't load metadata json or jsonl file"
		if(strlen(jsonfiles) < 5)
			mdlist = {"could not find metadata jsonl"}
		else
			jsonfound = 1
		endif
	else
		jsonfound = 1
	endif
	if(jsonfound)
		metadatafilename = stringfromlist(0,greplist(jsonfiles,"^"+basename+"*"+jsonext))
		metadata = addmetadatafromjson(pnamemd,"scan_id",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"institution",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"project_name",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"proposal_id",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"sample_name",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"sample_desc",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"sample_id",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"sample_set",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"user_name",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"user_id",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"notes",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"uid",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"dim1",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"dim2",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"dim3",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"chemical_formula",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"density",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"project_desc",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"RSoXS_config",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"RSoXS_Main_DET",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"RSoXS_WAXS_SDD",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"RSoXS_WAXS_BCX",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"RSoXS_WAXS_BCY",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"RSoXS_SAXS_SDD",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"RSoXS_SAXS_BCX",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"RSoXS_SAXS_BCY",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"plan_name",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"master_plan",metadatafilename,metadata)
		metadata = addmetadatafromjson(pnamemd,"plan_history",metadatafilename,metadata)
		variable /g scan_id = numberByKey("scan_id",metadata)
		string det = stringByKey("RSoXS_Main_DET",metadata)
		metadata = replacestring(":",metadata,"  -  ")
		redimension /n=(itemsinlist(metadata)) mdlist
		mdlist[] = stringfromlist(p,metadata)
		
	endif	
	
	//baselines
	getfilefolderinfo /z /q /P=$(pnameimages) basename+"-baseline.csv"
	if(v_flag!=0)
		wave /z /t bllist = root:Packages:NikaNISTRSoXS:bllist
		bllist = {"no baselines found",""}
	else
		LoadWave/Q/O/J/D/n=baseline/K=0/P=$(pnameimages)/m  basename+"-baseline.csv"
		wave /t baselines = $stringfromlist(0,S_waveNames)
		matrixtranspose baselines
		duplicate /o baselines, root:Packages:NikaNISTRSoXS:bllist
	endif
	svar location = root:Packages:NikaNISTRSoXS:location
	if(waveexists(baselines))
		if(foundloc)
			findvalue /TEXT="en energy" baselines
			if(v_value>=0)
				location = baselines[v_value][1]
			else
				location = ""
			endif
		else
			findvalue /TEXT="RSoXS Sample Outboard-Inboard" baselines
			if(v_value>=0)
				location = "("+num2str(round(str2num(baselines[v_value][1])*100)/100) + ","
			else
				location = ""
			endif
			findvalue /TEXT="RSoXS Sample Up-Down" baselines
			if(v_value>=0)
				location += num2str(round(str2num(baselines[v_value][1])*100)/100) + ")"
			else
				location = ""
			endif
			
		endif
	endif
	
	
	
	nvar saxsorwaxs = root:Packages:NIKANISTRSoXS:saxsorwaxs
	
	if(stringmatch(det,"SAXS"))
		saxsorwaxs = 1
		button NRB_SAXSWAXSbut fColor=(0,0,20000),title="SAXS images\r(click to toggle)",valueColor=(65535,65535,65535)
	elseif(stringmatch(det,"WAXS"))
		saxsorwaxs = 0
		button NRB_SAXSWAXSbut fColor=(1,26214,0),title="WAXS images\r(click to toggle)",valueColor=(0,0,0)
	endif
	SLEEP /S 2
	NRB_updateimageplot()
	setdatafolder currentfolder
	
	Execute "SetIgorOption Str2DoubleMode=1"
end


Function NRB_MetaBaseProc(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
			if(tab==0)
				ListBox MetadataLB,disable=0
				ListBox baselineLB,disable=1
			elseif(tab==1)
				ListBox MetadataLB,disable=1
				ListBox baselineLB,disable=0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function NRB_datadispProc(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
			if(tab==0)
				setwindow NISTRSoXSBrowser#Graph2D,HIDE=1
				setwindow NISTRSoXSBrowser#Profiles,HIDE=1
				setwindow NISTRSoXSBrowser#Graph1D,HIDE=0
				SetVariable NRB_Mindisp,disable=1
				SetVariable NRB_Maxdisp,disable=1
				PopupMenu NRB_Colorpop,disable=1
				CheckBox NRB_logimg,disable=1
				Button NRB_Autoscale,disable=1
				Slider NRB_OffsetSLRD, disable=1
				Button NRB_popprofilebut, disable=1
				TitleBox NRB_Offset_Slider_Text, disable=1
			elseif(tab==1)
				setwindow NISTRSoXSBrowser#Graph2D,HIDE=0
				setwindow NISTRSoXSBrowser#Profiles,HIDE=1
				setwindow NISTRSoXSBrowser#Graph1D,HIDE=1
				SetVariable NRB_Mindisp,disable=0
				SetVariable NRB_Maxdisp,disable=0
				PopupMenu NRB_Colorpop,disable=0
				CheckBox NRB_logimg,disable=0
				Button NRB_Autoscale,disable=0
				Slider NRB_OffsetSLRD, disable=1
				Button NRB_popprofilebut, disable=1
				TitleBox NRB_Offset_Slider_Text, disable=1
			elseif(tab==2)
				setwindow NISTRSoXSBrowser#Graph2D,HIDE=1
				setwindow NISTRSoXSBrowser#Profiles,HIDE=0
				setwindow NISTRSoXSBrowser#Graph1D,HIDE=1
				SetVariable NRB_Mindisp,disable=1
				SetVariable NRB_Maxdisp,disable=1
				PopupMenu NRB_Colorpop,disable=1
				CheckBox NRB_logimg,disable=1
				Button NRB_Autoscale,disable=1
				Slider NRB_OffsetSLRD, disable=0
				Button NRB_popprofilebut, disable=0
				TitleBox NRB_Offset_Slider_Text, disable=0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function NRB_InitNISTRSoXS()
	dowindow /k NISTRSoXSBrowser
	NewPanel /W=(317,66,1673,931) /k=1 /N=NISTRSoXSBrowser as "NIST RSoXS data Browser"
	SetDrawLayer UserBack
	String CurrentFolder=GetDataFolder(1)
	setdatafolder root:
	newdatafolder /o/s Packages
	newdatafolder /o/s NikaNISTRSoXS		
	string /g pathtodata, colortab, location
	if(strlen(colortab)<3)
		colortab = "Terrain"
	endif
	variable /g minval = -500, maxval = 20000, logimage =0, leftmin=0, leftmax=1000, botmin=0, botmax=1000, darkview=0, saxsorwaxs=1
	variable /g profileoffset = 0
	
	
	variable /g bkgrunning = 1
	variable /g bkglastRunTicks = ticks
	variable /g bkgrunNumber = 0
	variable /g autoConvert = 0
	
	
	
	nvar /z scanrow
	if(!nvar_exists(scanrow))
		variable /g scanrow = -1
	endif
	wave /z/t scanlist, channellist, steplist, mdlist, bllist
	wave /z steplistsel, channellistsel
	if(!waveexists(scanlist))
		make /n=0/t scanlist
	endif
	if(!waveexists(steplist))
		make /n=0/t steplist
	endif
	if(!waveexists(channellist))
		make /n=0/t channellist
	endif
	if(!waveexists(channellistsel))
		make /n=0 channellistsel
	endif
	if(!waveexists(steplistsel))
		make /n=0 steplistsel
	endif
	if(!waveexists(mdlist))
		make /n=0/t mdlist
	endif
	if(!waveexists(bllist))
		make /n=0/t bllist
	endif
	make /o/n=2 /t scanlistboxcolumns = {"filenames","datapoints"}
	
	SetDataFolder $CurrentFolder
	
	ListBox ScansLB,pos={1.00,67.00},size={208.00,519.00},proc=NRB_ScanListBoxProc
	ListBox ScansLB,listWave=root:Packages:NikaNISTRSoXS:scanlist,row= 7,mode= 1
	ListBox ScansLB,selRow= 28,widths={124,60},userColumnResize= 1
	ListBox ChannelLB,pos={217.00,114.00},size={251.00,139.00}
	ListBox ChannelLB,listWave=root:Packages:NikaNISTRSoXS:channellist,widths={15,250}
	ListBox ChannelLB,selWave=root:Packages:NikaNISTRSoXS:channellistsel,mode= 4,proc=NRB_ChannelLBproc
	ListBox ScanStepLB,pos={217.00,272.00},size={251.00,340.00},proc=NRB_ScanStepLBproc
	ListBox ScanStepLB,listWave=root:Packages:NikaNISTRSoXS:steplist
	ListBox ScanStepLB,selWave=root:Packages:NikaNISTRSoXS:steplistsel,row=scanrow
	ListBox ScanStepLB,mode= 9
	GroupBox group0,pos={214.00,258.00},size={259.00,397.00},title="Scan Steps"
	GroupBox group1,pos={214.00,52.00},size={259.00,207.00},title="Channels (check X-axis)"
	GroupBox scangroupo,pos={0.00,52.00},size={213.00,538.00},title="Scans"
	TabControl metabase,pos={1.00,591.00},size={207.00,270.00},proc=NRB_MetaBaseProc
	TabControl metabase,tabLabel(0)="Metadata",tabLabel(1)="Baseline",value= 1
	ListBox MetadataLB,pos={4.00,617.00},size={198.00,239.00},disable=1
	ListBox MetadataLB,listWave=root:Packages:NikaNISTRSoXS:mdlist,row= 4,mode= 1
	ListBox MetadataLB,selRow=0
	ListBox baselineLB,pos={4.00,617.00},size={198.00,239.00}
	ListBox baselineLB,listWave=root:Packages:NikaNISTRSoXS:bllist
	ListBox baselineLB,widths={124,60,60},userColumnResize= 1
	Button Browsebut,pos={3.00,4.00},size={54.00,37.00},proc=NRB_Browsebutfunc,title="Browse"
	TitleBox Pathdisp,pos={63.00,4.00},size={387.00,20.00},fSize=10,frame=5
	TitleBox Pathdisp,variable= root:Packages:NikaNISTRSoXS:pathtodata
	TabControl datadisp,pos={474.00,4.00},size={875.00,860.00},proc=NRB_datadispProc
	TabControl datadisp,tabLabel(0)="1D data",tabLabel(1)="Images",tabLabel(2)="Profiles",value= 1
	Button LoadDarkBut,pos={216.00,720.00},size={55.00,32.00},proc=NRB_NIKADarkbut,title="Load as\r Dark(s)"
	Button LoadDarkBut1,pos={276.00,721.00},size={55.00,32.00},proc=NRB_setupNIKA_but,title="(re)setup\rNIKA"
	Button OpenMaskBut,pos={216.00,682.00},size={125.00,34.00},proc=NRB_NIKAMaskbut,title="Open for Mask"
	Button BeamCenterBu,pos={344.00,682.00},size={125.00,34.00},proc=NRB_NIKABCbut,title="Open for\rBeam Geometry"
	Button ConvSelBut,pos={344.00,721.00},size={125.00,34.00},proc=NRB_NIKAbut,title="Convert Selection"
	Button QANTimportbut,pos={217.00,69.00},size={246.00,42.00},title="Import channels to\r QANT for analysis"
	GroupBox NIKAgroup,pos={214.00,662.00},size={259.00,98.00},title="NIKA Integration"
	Button NRB_SAXSWAXSbut,pos={235.00,767.00},size={206.00,39.00},proc=NRB_SWbutproc,title="SAXS images\r(click to toggle)"
	Button NRB_SAXSWAXSbut,labelBack=(65535,65535,65535),fStyle=1,fColor=(0,0,20000)
	Button NRB_SAXSWAXSbut,valueColor=(65535,65535,65535)
	Button NRB_SelectAll_but,pos={397.00,815.00},size={55.00,32.00},proc=NRB_SelectAll,title="Select All"
	SetVariable NRB_Mindisp,pos={639.00,41.00},size={80.00,18.00},bodyWidth=60,proc=NRB_ImageRangeChange,title="Min"
	SetVariable NRB_Mindisp,limits={-5000,500000,1},value=minval
	SetVariable NRB_Maxdisp,pos={737.00,41.00},size={80.00,18.00},bodyWidth=60,proc=NRB_ImageRangeChange,title="Max"
	SetVariable NRB_Maxdisp,limits={-5000,500000,1},value=maxval
	PopupMenu NRB_Colorpop,pos={831.00,42.00},size={200.00,19.00},proc=NRB_colorpopproc
	PopupMenu NRB_Colorpop,mode=8,value= #"\"*COLORTABLEPOPNONAMES*\""	
	CheckBox NRB_logimg,pos={1041.00,42.00},size={33.00,15.00},title="log",value=logimage,proc=NRB_logimagebutproc,variable=logimage
	Button NRB_Autoscale,pos={1098.00,42.00},size={68.00,15.00},proc=NRB_autoscalebut,title="Autoscale"
	CheckBox NRB_autocheck,pos={67.00,34.00},size={130.00,15.00},proc=NRB_autocheckproc,title="Refresh automatically"
	CheckBox NRB_autocheck,value= 0
	CheckBox NRB_Darkscheck,pos={292.00,816.00},size={73.00,15.00},proc=NRP_Viewdarks_butproc,title="View Darks"
	CheckBox NRB_Darkscheck,value= 0
	TitleBox Location,pos={1236.00,1.00},size={254.00,23.00}
	TitleBox Location,variable= root:Packages:NikaNISTRSoXS:location
	Button NRBCopyPos,pos={220.00,619.00},size={226.00,24.00},title="Copy Location for Spreadsheet",proc=NRB_copylocbut
	Slider NRB_OffsetSLRD,pos={506.00,52.00},size={200.00,22.00},proc=NRB_profileslider
	Slider NRB_OffsetSLRD,help={"Change the offset between profiels"}
	Slider NRB_OffsetSLRD,limits={0,100,1},value= 26,vert= 0,ticks= 0,disable=1,variable= root:Packages:NikaNISTRSoXS:profileoffset
	Button NRB_popprofilebut,pos={1152.00,47.00},size={156.00,33.00},proc=NRB_pop_Profilebut,title="Pop out for comparison",disable=1
	TitleBox NRB_Offset_Slider_Text,pos={557.00,39.00},size={74.00,15.00},title="Offset Profiles"
	TitleBox NRB_Offset_Slider_Text,frame=0,disable=1
	CheckBox NRB_autoconvert,pos={250.00,30.00},size={133.00,15.00},variable=root:Packages:NikaNISTRSoXS:autoConvert,title="Convert automatically"
	CheckBox NRB_autoconvert,value= 0,disable=0
	
	
	SetWindow kwTopWin,hook(syncaxes)=NRB_axishook
	Display/W=(481,28,1344,860)/HOST=# /HIDE=1 
	RenameWindow #,Graph1D
	SetActiveSubwindow ##
	Display/W=(481,74,1344,860)/HOST=# 
	RenameWindow #,Graph2D
	SetActiveSubwindow ##
	Display/W=(481,98,1344,857)/HOST=# /HIDE=1 
	RenameWindow #,Profiles
	SetActiveSubwindow ##
	
End

Function NRB_autocheckproc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				CtrlNamedBackground NRB_BG, burst=0, proc=NRB_BGTask, period=	10, dialogsOK=1, kill=0, start
			else
				CtrlNamedBackground NRB_BG, stop, kill=1
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function NRB_Browsebutfunc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			NRB_browse()
			if(NRB_Loaddir()>=0)
				NRB_loadprimary()
			endif
			break
	endswitch
	return 0
End

function NRB_browse()
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:NikaNISTRSoXS
	svar pathtodata
	pathinfo Path_NISTRSoXS
	NewPath/q/z/O/m="path for txt files" Path_NISTRSoXS		// This will put up a dialog
	if (V_flag == 0)
		string /g pathname
		pathname = "Path_NISTRSoXS"
		PathInfo Path_NISTRSoXS
		pathtodata = s_path
	endif
	make/n=0/t/o conwave
	SetDataFolder $CurrentFolder
	
	
end


Function NRB_ScanListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	switch( lba.eventCode )
		case 4: // cell selection
		case 5: // cell selection plus shift key
			NRB_loadprimary()
			break
		case 3:
			NRB_Loaddir()
			break
	endswitch
	return 0
End



Function NRB_SWbutproc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			string currentdatafolder = getdatafolder(1)
			setdatafolder root:Packages:NIKANISTRSoXS
			variable /g saxsorwaxs 
			saxsorwaxs = abs(saxsorwaxs-1)
			if(saxsorwaxs)
				button NRB_SAXSWAXSbut fColor=(0,0,20000),title="SAXS images\r(click to toggle)",valueColor=(65535,65535,65535)
			else
				button NRB_SAXSWAXSbut fColor=(1,26214,0),title="WAXS images\r(click to toggle)",valueColor=(0,0,0)
			endif
			NRB_updateimageplot()
			setdatafolder currentdatafolder
		case -1: // control being killed
			break
	endswitch

	return 0
End

function NRB_updateimageplot([autoscale])
	variable autoscale
	autoscale = paramisDefault(autoscale)? 0 : autoscale
	wave selwave = root:Packages:NikaNISTRSoXS:steplistsel
	variable i, num 
	duplicate /free selwave, tempwave
	tempwave = selwave[p]&1 || selwave[p]&8? 1 : 0
	num = sum(tempwave)
	NRB_MakeImagePlots(num)
	string listofsteps = ""
	for(i=0;i<dimsize(selwave,0);i+=1)
		if(selwave[i]&1 || selwave[i]&8)
			listofsteps = addlistitem(num2str(i),listofsteps)
		endif
	endfor
	if(num==1)
		Button NRBCopyPos,disable=0
	else
		Button NRBCopyPos,disable=1
	endif
	
	NRB_loadimages(listofsteps, autoscale=autoscale)
	NRB_loadprofiles(listofsteps)
end

function NRB_MakeImagePlots(num)
	variable num
	variable numx, numy
	//481,28,1344,860
	//863,832
	string currentfolder = getdatafolder(1)
	setdatafolder root:Packages:NIKANISTRSoXS
	wave /z/t imagenames
	variable i
	if(waveexists(imagenames))
		for(i=0;i<dimsize(imagenames,0);i+=1)
			killwindow /z NISTRSoXSBrowser#Graph2D#$imagenames[i]
		endfor
	endif
	make /o/n=(num) /t imagenames
	
	
	numy = floor(.5+sqrt(num-.75))
	numx = ceil(num/numy)
	
	variable sizex, sizey
	sizex = floor(863 / numx)
	sizey = floor(786 / numy)
	
	variable xloc=0, yloc=0
	variable imnum = 0
	imagenames = "NRB_image"+num2str(p)
	for(yloc=0;yloc<numy;yloc+=1)
		for(xloc=0;xloc<numx;xloc+=1)
			Display/W=(sizex*xloc,sizey*yloc,sizex*(xloc+1),sizey*(yloc+1))/HOST=NISTRSoXSBrowser#Graph2D /n=$imagenames[imnum]
			imnum+=1
			if(imnum>=num)
				break
			endif
		endfor
		if(imnum>=num)
			break
		endif
	endfor
	
	
end

Function NRB_ScanStepLBproc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			NRB_updateimageplot()
			//NRB_updateimageplot(autoscale=1)
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 12: // keystroke
			NRB_Loaddir()
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End

function NRB_loadimages(listofsteps,[autoscale])
	string listofsteps
	variable autoscale
	autoscale = paramisDefault(autoscale)? 0 : autoscale
	listofsteps = sortlist(listofsteps,";",2)
	string currentfolder =getdatafolder(1)
	setdatafolder root:Packages:NIKANISTRSoXS
	svar basescanname
	svar /z colortab
	nvar /z saxsorwaxs
	nvar /z darkview
	nvar /z leftmin
	nvar /z leftmax
	nvar /z botmin
	nvar /z botmax
	nvar /z logimage
	svar /z pname = root:Packages:NikaNISTRSoXS:pnameimages
	wave /t imagenames
	wave /t steplist
	killdatafolder /z images
	newdatafolder /o/s images
	string tiffnames = IndexedFile($pname, -1, ".tiff")
	string matchingtiffs = listMatch(tiffnames,basescanname+"*")
	string tifffilename
	
	nvar /z minval = root:Packages:NikaNISTRSoXS:minval
	nvar /z maxval = root:Packages:NikaNISTRSoXS:maxval
	
	variable minv, maxv, totmaxv = -5000, totminv = 5e10
	variable i
	make /free /n=(itemsinlist(listofsteps)) success=0
	
	string primeordark
	if(darkview)
		primeordark = "*dark-"
	else
		primeordark = "*primary-"
	endif
	for(i=0;i<itemsinlist(listofsteps);i+=1)

		if(saxsorwaxs)
			tifffilename = stringfromlist(0,listMatch(matchingtiffs,primeordark + "*saxs*-"+stringfromlist(i,listofsteps)+".tiff"))
			if(strlen(tifffilename)<3)
				tifffilename = stringfromlist(0,listMatch(matchingtiffs,primeordark + "*Small*-"+stringfromlist(i,listofsteps)+".tiff"))
			endif
		else
			tifffilename = stringfromlist(0,listMatch(matchingtiffs,primeordark + "*waxs*-"+stringfromlist(i,listofsteps)+".tiff"))
			if(strlen(tifffilename)<3)
				tifffilename = stringfromlist(0,listMatch(matchingtiffs,primeordark + "*Wide*-"+stringfromlist(i,listofsteps)+".tiff"))
			endif
		endif
		if(strlen(tifffilename)<4)
			success[i] = 0 
			//print "Could not find image to display"
			
		else
			ImageLoad/q/P=$(pname)/T=tiff/O/N=$("image"+num2str(i)) tifffilename
			wave image = $("image"+num2str(i))
			redimension /i image
			histogram /B=3 image
			imageinterpolate /dest=$("imagesm"+num2str(i)) /pxsz={floor(sqrt(itemsinlist(listofsteps))),floor(sqrt(itemsinlist(listofsteps)))} pixelate image
			wave imagesm = $("imagesm"+num2str(i))
			killwaves /z image
			appendimage /w=NISTRSoXSBrowser#Graph2D#$imagenames[i] imagesm
			ModifyGraph /w=NISTRSoXSBrowser#Graph2D#$imagenames[i] margin=1,nticks=0,standoff=0
			ModifyImage /w=NISTRSoXSBrowser#Graph2D#$imagenames[i] ''#0 log=logimage,ctab= {minval,maxval,$colortab,0}
			TextBox /w=NISTRSoXSBrowser#Graph2D#$imagenames[i]/S=0/F=0/A=LT steplist[str2num(stringfromlist(i,listofsteps))]
			minv = wavemin(imagesm)
			maxv = wavemax(imagesm)
			if(minv<totminv)
				totminv = minv
			endif
			if(maxv>totmaxv)
				totmaxv = maxv
			endif
			success[i] = 1
			
			// at this point I have s_path, s_filename, imagename[i] (panel name where the image is), steplist[str2num(stringfromlist(i,listofsteps))] (text in textbox)
			// I would like to have the UID, imagenumber = str2num(stringfromlist(i,listofsteps))
			wave /t mdlist = root:Packages:NikaNISTRSoXS:mdlist
			findvalue /text="uid" mdlist
			string uid = replacestring("uid  -  ",mdlist[v_value],"")
			string imagenumber = stringfromlist(i,listofsteps)
			string tbtext = steplist[str2num(stringfromlist(i,listofsteps))]
			string panelname = "NISTRSoXSBrowser#Graph2D#"+imagenames[i]
			string path = s_path
			string filename = s_filename
		endif
	endfor
	if(autoscale)
		setaxis /A /w=NISTRSoXSBrowser#Graph2D#$imagenames[0]
		doupdate
		getaxis /q/w=NISTRSoXSBrowser#Graph2D#$imagenames[0] left
		leftmin = v_min
		leftmax = v_max
		getaxis /q/w=NISTRSoXSBrowser#Graph2D#$imagenames[0] bottom
		botmin = v_min
		botmax = v_max
		minval = totminv
		maxval = totmaxv
	else

	endif
	for(i=0;i<itemsinlist(listofsteps);i+=1)
		if(success[i])
			variable realminval = logimage? max(1,minval) : minval
			ModifyImage /w=NISTRSoXSBrowser#Graph2D#$imagenames[i] ''#0 log=logimage,ctab= {realminval,maxval,$colortab,0}
		endif
	endfor
	setwindow NISTRSoXSBrowser,hook(syncaxes)=NRB_axishook
	
	
	setdatafolder currentfolder
end

Function NRB_ImageRangeChange(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			NRB_updateimages()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function NRB_colorpopproc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			svar /z colortab = root:Packages:NikaNISTRSoXS:colortab
			if(svar_exists(colortab))
				colortab = popStr
				NRB_updateimages()
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function NRB_updateimages()
	svar /z colortab = root:Packages:NikaNISTRSoXS:colortab
	nvar /z minval = root:Packages:NikaNISTRSoXS:minval
	nvar /z maxval = root:Packages:NikaNISTRSoXS:maxval
	nvar /z logimage = root:Packages:NikaNISTRSoXS:logimage
	nvar /z leftmin = root:Packages:NikaNISTRSoXS:leftmin
	nvar /z leftmax = root:Packages:NikaNISTRSoXS:leftmax
	nvar /z botmin = root:Packages:NikaNISTRSoXS:botmin
	nvar /z botmax = root:Packages:NikaNISTRSoXS:botmax
	wave /z/t imagenames  = root:Packages:NikaNISTRSoXS:imagenames
	setwindow NISTRSoXSBrowser,hook(syncaxes)=$"" 
	if(waveexists(imagenames) && svar_exists(colortab) && nvar_exists(minval) && nvar_exists(maxval) && nvar_exists(logimage))
		variable i
		for(i=0;i<dimsize(imagenames,0);i+=1)
			
			ModifyImage /z/w=NISTRSoXSBrowser#Graph2D#$imagenames[i] ''#0 log=(logimage),ctab= {minval,maxval,$colortab,0}
			setaxis /z/w=NISTRSoXSBrowser#Graph2D#$imagenames[i] left, leftmin, leftmax
			setaxis /z/w=NISTRSoXSBrowser#Graph2D#$imagenames[i] bottom, botmin, botmax
			
		endfor
	endif
	setwindow NISTRSoXSBrowser,hook(syncaxes)=NRB_axishook
end
	

Function NRB_logimagebutproc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			NRB_updateimageplot()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function NRB_axishook(s)
	STRUCT WMWinHookStruct &s
	Variable hookResult = 0
	//print s.eventCode
	switch(s.eventCode)
		case 4:
			break
		case 11:
			GetWindow $s.winName activeSW
			if(!stringmatch(s_value,"*NRB_image*"))
				break
			endif
		case 6:
		case 8: // modified
			nvar /z leftmin = root:Packages:NikaNISTRSoXS:leftmin
			nvar /z leftmax = root:Packages:NikaNISTRSoXS:leftmax
			nvar /z botmin = root:Packages:NikaNISTRSoXS:botmin
			nvar /z botmax = root:Packages:NikaNISTRSoXS:botmax
			GetWindow $s.winName activeSW
			string subwindow = s_value
			//print subwindow
			getaxis /q/w=$(subwindow) left ;variable err = GetRTError(1)
			if(err)
				break
			endif
			leftmin = v_min
			leftmax = v_max
			getaxis /q/w=$(subwindow) bottom
			botmin = v_min
			botmax = v_max
			NRB_updateimages()
			hookresult = 1
			break
		case 2:
			NVAR running= root:Packages:NikaNISTRSoXS:bkgrunning
			running = 0
			CtrlNamedBackground NRB_BG, stop
			break
		default:
			//print s.eventcode	
	endswitch
	return hookResult // 0 if nothing done, else 1
End

Function NRB_autoscalebut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NRB_updateimageplot(autoscale=1)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function NRB_ChannelLBproc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			NRB_plotchannels()
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			string x_axis
			if(selwave[row] & 16)
				//checkbox on
				x_axis = listwave[row][1]
				variable i
				for(i=0;i<dimsize(selwave,0);i+=1)
					if(i!=row && selwave[i] & 16)
						selwave[i] -=16
					endif
				endfor
			else
				for(i=0;i<dimsize(selwave,0);i+=1)
					if(i!=0 && selwave[i] & 16)
						selwave[i] -=16
					endif
					if(!(selwave[0] & 16))
						selwave[0] += 16
					endif
				endfor
				x_axis = listwave[0][1]
			endif
			string currenfolder = getdatafolder(1)
			setdatafolder root:Packages:NikaNISTRSoXS:
			string /g x_axisname = x_axis
			NRB_plotchannels(fresh=1)
			break
	endswitch

	return 0
End


function NRB_plotchannels([fresh])
	variable fresh
	fresh = paramisdefault(fresh)? 0 : fresh
	wave /t listwave = root:Packages:NikaNISTRSoXS:channellist
	wave selwave = root:Packages:NikaNISTRSoXS:channellistsel
	
	make /free /n=(dimsize(selwave,0)) selected
	selected = selwave[p] & 1
	variable num = sum(selected)
	string channels2plot = ""
	variable j
	for(j=0;j<dimsize(selwave,0);j+=1)
		if(selected[j])
			channels2plot = addlistitem(listwave[j][1],channels2plot)
		endif
	endfor
	
	string plottedchannels = tracenamelist("NISTRSoXSBrowser#Graph1D",";",1)
	string channeltoplot
	string plottedchannel
	svar /z x_axisname = root:Packages:NikaNISTRSoXS:x_axisname
	if(!svar_exists(x_axisname))
		print "Cannot plot anything until an X-axis is chosen"
		return 0
	endif
	
	variable i
	for(i=itemsinlist(plottedchannels)-1;i>=0;i-=1)
		plottedchannel = stringfromlist(i,plottedchannels)
		if(fresh || (whichlistitem(plottedchannel,channels2plot)<0))
			removefromgraph /z /w=NISTRSoXSBrowser#Graph1D $plottedchannel
		endif
	endfor
	
	plottedchannels = tracenamelist("NISTRSoXSBrowser#Graph1D",";",1)
	
	
	wave xwave = root:Packages:NikaNISTRSoXS:channels:$x_axisname
	for(i=0;i<itemsinlist(channels2plot);i+=1)
		channeltoplot = stringfromlist(i,channels2plot)
		if(stringmatch(channeltoplot,x_axisname) || whichlistitem(channeltoplot,plottedchannels)>=0)
			continue
		endif
		wave channel = root:Packages:NikaNISTRSoXS:channels:$channeltoplot
		wave /z errorwave = root:Packages:NikaNISTRSoXS:channels:$replacestring("m_",channeltoplot,"s_",1,1)
		appendtograph /w=NISTRSoXSBrowser#Graph1D channel vs xwave
		if(waveexists(errorwave) && stringmatch(channeltoplot,"m_*"))
			ErrorBars /w=NISTRSoXSBrowser#Graph1D $nameofwave(channel) SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=(errorwave,errorwave)
		endif
	endfor
	NRB_ColorTraces("SpectrumBlack","NISTRSoXSBrowser#Graph1D")
end

function NRB_ColorTraces(Colortabname,Graphname)
	string colortabname, graphname
	
	if(cmpstr(graphName,"")==0)
		graphname = WinName(0, 1)
	endif
	if (strlen(graphName) == 0)
		return -1
	endif

	Variable numTraces =itemsinlist(TraceNameList(graphName,";",1))
	if (numTraces <= 0)
		return -1
	endif
	variable numtracesden=numtraces
	if( numTraces < 2 )
		numTracesden= 2	// avoid divide by zero, use just the first color for 1 trace
	endif

	ColorTab2Wave $colortabname
	wave RGB = M_colors
	Variable numRows= DimSize(rgb,0)
	Variable red, green, blue
	Variable i, index
	for(i=0; i<numTraces; i+=1)
		index = round(i/(numTracesden-1) * (numRows*2/3-1))	// spread entire color range over all traces.
		ModifyGraph/w=$graphName rgb[i]=(rgb[index][0], rgb[index][1], rgb[index][2])
	endfor
end




function NRB_convertpathtonika([main,mask,dark,beamcenter])
	variable mask,dark,beamcenter,main
	svar /z pname = root:Packages:NikaNISTRSoXS:pnameimages
	PathInfo $pname
	if(main)
		EGNA_Convert2Dto1DMainPanel()
		svar SampleNameMatchStr = root:Packages:Convert2Dto1D:SampleNameMatchStr
		SampleNameMatchStr = ""
		popupmenu Select2DDataType win=EGNA_Convert2Dto1DPanel, popmatch="BS_Suitcase_Tiff"
		newpath /O/Q/Z Convert2Dto1DDataPath S_path
		SVAR MainPathInfoStr=root:Packages:Convert2Dto1D:MainPathInfoStr
		MainPathInfoStr=S_path
		TitleBox PathInfoStrt, win =EGNA_Convert2Dto1DPanel, variable=MainPathInfoStr
		SVAR DataFileExtension=root:Packages:Convert2Dto1D:DataFileExtension
		DataFileExtension = "BS_Suitcase_Tiff"
		EGNA_UpdateDataListBox()	
	endif
	if(mask)
		NI1M_CreateMask()
		newpath /O/Q/Z Convert2Dto1DMaskPath S_path
		popupmenu CCDFileExtension win=NI1M_ImageROIPanel, popmatch="BS_Suitcase_Tiff"
		SVAR CCDFileExtension=root:Packages:Convert2Dto1D:CCDFileExtension
		CCDFileExtension = "BS_Suitcase_Tiff"
		NI1M_UpdateMaskListBox()
	endif
	if(dark)
		EGNA_Convert2Dto1DMainPanel()
		newpath /O/Q/Z Convert2Dto1DEmptyDarkPath S_path
		popupmenu SelectBlank2DDataType win=EGNA_Convert2Dto1DPanel, popmatch="BS_Suitcase_Tiff"
		nVAR usedarkfield=root:Packages:Convert2Dto1D:UseDarkField
		usedarkfield=1
		SVAR BlankFileExtension=root:Packages:Convert2Dto1D:BlankFileExtension
		BlankFileExtension = "BS_Suitcase_Tiff"
		SVAR DataFileExtension=root:Packages:Convert2Dto1D:DataFileExtension
		DataFileExtension = "BS_Suitcase_Tiff"
		svar EmptyDarkNameMatchStr = root:Packages:Convert2Dto1D:EmptyDarkNameMatchStr
		EmptyDarkNameMatchStr = ""
		EGNA_UpdateEmptyDarkListBox()	
	endif
	if(beamcenter)
		EGN_CreateBmCntrFile()
		newpath /O/Q/Z Convert2Dto1DBmCntrPath S_path
		popupmenu BmCntrFileType win=EGN_CreateBmCntrFieldPanel, popmatch="BS_Suitcase_Tiff"
		SVAR BmCntrFileType=root:Packages:Convert2Dto1D:BmCntrFileType
		BmCntrFileType = "BS_Suitcase_Tiff"
		SVAR BCPathInfoStr=root:Packages:Convert2Dto1D:BCPathInfoStr
		BCPathInfoStr=S_Path
		NI1BC_UpdateBmCntrListBox()
	endif
end


function /t NRB_getfilenames()
	string currentfolder =getdatafolder(1)
	setdatafolder root:Packages:NIKANISTRSoXS
	wave selwave = root:Packages:NikaNISTRSoXS:steplistsel
	variable i
	string /g listofsteps = ""
	for(i=0;i<dimsize(selwave,0);i+=1)
		if(selwave[i])
			listofsteps = addlistitem(num2str(i),listofsteps)
		endif
	endfor

	svar basescanname
	nvar saxsorwaxs, darkview
	svar /z pname = root:Packages:NikaNISTRSoXS:pnameimages
	wave /t steplist
	killdatafolder /z images
	newdatafolder /o/s images
	string tiffnames = IndexedFile($pname, -1, ".tiff")
	string matchingtiffs = listMatch(tiffnames,basescanname+"*")
	string filenames = ""
	string tifffilename = ""
	
	string primeordark
	if(darkview)
		primeordark = "*dark-"
	else
		primeordark = "*primary-"
	endif
	for(i=0;i<itemsinlist(listofsteps);i+=1)
		if(saxsorwaxs)
			tifffilename = stringfromlist(0,listMatch(tiffnames,basescanname + primeordark + "*saxs*-"+stringfromlist(i,listofsteps)+".tiff"))
			if(strlen(tifffilename)<3)
				tifffilename = stringfromlist(0,listMatch(tiffnames,basescanname + primeordark + "*Small*-"+stringfromlist(i,listofsteps)+".tiff"))
			endif
		else
			tifffilename = stringfromlist(0,listMatch(tiffnames,basescanname + primeordark + "*waxs*-"+stringfromlist(i,listofsteps)+".tiff"))
			if(strlen(tifffilename)<3)
				tifffilename = stringfromlist(0,listMatch(tiffnames,basescanname + primeordark + "*Wide*-"+stringfromlist(i,listofsteps)+".tiff"))
			endif
		endif
		filenames = addlistitem(tifffilename,filenames)
	endfor
	return filenames
	
end

function /t NRB_scansteps()
	string currentfolder =getdatafolder(1)
	setdatafolder root:Packages:NIKANISTRSoXS
	wave selwave = root:Packages:NikaNISTRSoXS:steplistsel
	variable i
	string listofsteps = ""
	for(i=0;i<dimsize(selwave,0);i+=1)
		if(selwave[i])
			listofsteps = addlistitem(num2str(i),listofsteps)
		endif
	endfor

	svar basescanname
	nvar saxsorwaxs, darkview
	svar /z pname = root:Packages:NikaNISTRSoXS:pnameimages
	wave /t steplist
	killdatafolder /z images
	newdatafolder /o/s images
	string tiffnames = IndexedFile($pname, -1, ".tiff")
	string matchingtiffs = listMatch(tiffnames,basescanname+"*")
	string filenames = ""
	string tifffilename = ""
	
	string primeordark
	if(darkview)
		primeordark = "*dark-"
	else
		primeordark = "*primary-"
	endif
	for(i=0;i<itemsinlist(listofsteps);i+=1)
		if(saxsorwaxs)
			tifffilename = stringfromlist(0,listMatch(tiffnames,basescanname + primeordark + "*saxs*-"+stringfromlist(i,listofsteps)+".tiff"))
			if(strlen(tifffilename)<3)
				tifffilename = stringfromlist(0,listMatch(tiffnames,basescanname + primeordark + "*Small*-"+stringfromlist(i,listofsteps)+".tiff"))
			endif
		else
			tifffilename = stringfromlist(0,listMatch(tiffnames,basescanname + primeordark + "*waxs*-"+stringfromlist(i,listofsteps)+".tiff"))
			if(strlen(tifffilename)<3)
				tifffilename = stringfromlist(0,listMatch(tiffnames,basescanname + primeordark + "*Wide*-"+stringfromlist(i,listofsteps)+".tiff"))
			endif
		endif
		filenames = addlistitem(tifffilename,filenames)
	endfor
	return filenames
	
end

Function NRB_NIKABCbut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up			
			string filelist = NRB_getfilenames()
			NRB_loadforbeamcenteringinNIKA(stringfromlist(0,filelist))
			break
	endswitch
	return 0
End
Function NRB_NIKADarkbut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string filelist = NRB_getfilenames()
			NRB_loadasdarkinnika(filelist)
			break
	endswitch
	return 0
End
Function NRB_NIKAMaskbut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string filelist = NRB_getfilenames()
			NRB_loadformaskinnika(stringfromlist(0,filelist))
			break
	endswitch

	return 0
End

Function NRB_NIKAbut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NRB_Convertifneeded()
			//string filelist = NRB_getfilenames()
			//NRB_convertnikafilelistsel(filelist)
			break
	endswitch

	return 0
End


function NRB_loadasdarkinnika(filenamelist)
	string filenamelist
	string filename
	NRB_convertpathtonika(dark=1)
	doupdate
	Wave/T  ListOffilenames=root:Packages:Convert2Dto1D:ListOf2DEmptyData
	variable i=0
	for(i=0;i<itemsinlist(filenamelist);i+=1)
		filename = stringfromlist(i,filenamelist)
		FindValue /TEXT=filename /TXOP=6 /Z ListOffilenames
		if(v_value>=0)
			listbox Select2DMaskDarkWave win=EGNA_Convert2Dto1DPanel, selrow=v_value 
			doupdate
			EGNA_LoadEmptyOrDark("Dark")
		endif
	endfor
end

function NRB_loadformaskinnika(filename)
	string filename
	NRB_convertpathtonika(mask=1)
	doupdate
	Wave/T  ListOffilenames=root:Packages:Convert2Dto1D:ListOfCCDDataInCCDPath
	variable i
	FindValue /TEXT=filename /TXOP=6 /Z ListOffilenames
	if(v_value>=0)
		listbox CCDDataSelection win=NI1M_ImageROIPanel, selrow=v_value 
		doupdate
		NI1M_MaskCreateImage() 
	endif
end

function NRB_loadforbeamcenteringinNIKA(filename)
	string filename
	NRB_convertpathtonika(beamcenter=1)
	doupdate
	Wave/T  ListOffilenames=root:Packages:Convert2Dto1D:ListOfCCDDataInBmCntrPath
	FindValue /TEXT=filename /TXOP=6 /Z ListOffilenames
	if(v_value>=0)
		listbox CCDDataSelection win=EGN_CreateBmCntrFieldPanel, selrow=v_value 
		doupdate
		NI1BC_BmCntrCreateImage()
		NVAR BMMaxCircleRadius=root:Packages:Convert2Dto1D:BMMaxCircleRadius
		Wave BmCntrFieldImg=root:Packages:Convert2Dto1D:BmCntrCCDImg 
		BMMaxCircleRadius=sqrt(DimSize(BmCntrFieldImg, 0 )^2 + DimSize(BmCntrFieldImg, 1 )^2)
		Slider BMHelpCircleRadius,limits={1,BMMaxCircleRadius,0}, win=EGN_CreateBmCntrFieldPanel
		SetVariable BMHelpCircleRadiusV,limits={1,BMMaxCircleRadius,0}, win=EGN_CreateBmCntrFieldPanel
		NVAR BMImageRangeMinLimit= root:Packages:Convert2Dto1D:BMImageRangeMinLimit
		NVAR BMImageRangeMaxLimit = root:Packages:Convert2Dto1D:BMImageRangeMaxLimit
		Slider ImageRangeMin,limits={BMImageRangeMinLimit,BMImageRangeMaxLimit,0}, win=EGN_CreateBmCntrFieldPanel
		Slider ImageRangeMax,limits={BMImageRangeMinLimit,BMImageRangeMaxLimit,0}, win=EGN_CreateBmCntrFieldPanel
		NI1BC_DisplayHelpCircle()
		NI1BC_DisplayMask()
		TabControl BmCntrTab, value=0, win=EGN_CreateBmCntrFieldPanel
		showinfo /w=CCDImageForBmCntr
	endif
	
end

function NRB_convertnikafilelistsel(filenamelist)
	string filenamelist
	NRB_convertpathtonika(main=1)
	setup_NIKA_sectors()
	doupdate
	nvar invert = root:Packages:Convert2Dto1D:InvertImages
	invert = 1
	Wave/T  ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
	Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
	ListOf2DSampleDataNumbers = 0
	string filename = stringfromlist(0,filenamelist)
	variable i
	for(i=0;i<itemsinlist(filenamelist);i+=1)
		filename = stringfromlist(i,filenamelist)
		FindValue /TEXT=filename /TXOP=6 /Z ListOf2DSampleData
		if(v_value>=0)
			ListOf2DSampleDataNumbers[v_value] = 1
		endif
	endfor
	doupdate
	EGNA_CheckParametersForConv()
	//set selections for using RAW/Converted data...
	NVAR LineProfileUseRAW=root:Packages:Convert2Dto1D:LineProfileUseRAW
	NVAR LineProfileUseCorrData=root:Packages:Convert2Dto1D:LineProfileUseCorrData
	NVAR SectorsUseRAWData=root:Packages:Convert2Dto1D:SectorsUseRAWData
	NVAR SectorsUseCorrData=root:Packages:Convert2Dto1D:SectorsUseCorrData
	LineProfileUseRAW=0
	LineProfileUseCorrData=1
	SectorsUseRAWData=0
	SectorsUseCorrData=1
	//selection done
	EGNA_LoadManyDataSetsForConv()
end

Function NRB_BGTask(s)
	STRUCT WMBackgroundStruct &s
	NVAR running= root:Packages:NikaNISTRSoXS:bkgrunning
	if( running == 0 )
		return 0 // not running -- wait for user
	endif
	NVAR lastRunTicks= root:Packages:NikaNISTRSoXS:bkglastRunTicks
	if( (lastRunTicks+120) >= ticks )
		return 0 // not time yet, wait
	endif
	NVAR runNumber= root:Packages:NikaNISTRSoXS:bkgrunNumber
	runNumber += 1
	NRB_Loaddir()
	nvar autoconvert = root:Packages:NikaNISTRSoXS:autoConvert
	if(autoconvert)
		NRB_Convertifneeded()
	endif
	doupdate
	lastRunTicks= ticks
	return 0
End

Function NRP_Viewdarks_butproc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			string currentdatafolder = getdatafolder(1)
			setdatafolder root:Packages:NIKANISTRSoXS
			variable /g darkview 
			darkview = checked
			NRB_updateimageplot()
			setdatafolder currentdatafolder
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function /wave NRB_splitsignal(wavein,times, rises, falls, goodpulse)
	wave wavein,times, rises, falls,goodpulse
	
	make /free /n=(dimsize(wavein,0)) /d timesin = wavein[p][0], datain = wavein[p][1]
	
	string name = nameofwave(wavein)
	wave /z waveout = $("_"+name)
	if(numpnts(wavein)<2* numpnts(times))
		//print "not valid waves"
		return waveout
	endif
	make /o/n=(dimsize(times,0)) $("m_"+name), $("s_"+name), $("f_"+name)
	wave waveout = $("m_"+name), stdwave = $("s_"+name), fncwave = $("f_"+name)
	make /n=(dimsize(times,0)) /free pntlower, pntupper
	pntupper = binarysearch(timesin,times[p])
	pntupper = pntupper[p]==-2 ? numpnts(timesin)-1 : pntupper[p]
	duplicate /o /free pntupper, pntlower, pntlower1
	pntlower1 = binarysearch(timesin,times[p]-1.5)
	insertpoints /v=0 0,1,pntlower
	make /free temprises, tempfalls
	waveout = median(datain,pntlower1[p]+10,pntupper[p]-0)
	stdwave = sqrt(variance(datain,pntlower1[p]+2,pntupper[p]-0))
	variable i, meanvalue, alreadygood, err
	for(i=0;i<dimsize(times,0);i+=1)
		if(pntupper[i] - pntlower[i] < 3)
			continue
		endif
		//meanvalue = mean(datain,pntlower[i],pntupper[i])
		meanvalue = (6/10) *(wavemin(datain,pntlower[i],pntupper[i]) + wavemax(datain,pntlower[i],pntupper[i]))
		try
			findlevels /B=3/EDGE=1 /Q /P /D=temprises /R=[max(0,pntlower[i]),min(numpnts(datain)-1,pntupper[i])] datain, meanvalue;AbortonRTE // look for rising and falling edges
			findlevels /B=3/EDGE=2 /Q /P /D=tempfalls /R=[max(0,pntlower[i]),min(numpnts(datain)-1,pntupper[i])] datain, meanvalue;AbortonRTE
		catch
			err = getRTError(1)
			//print getErrMessage(err)
			goodpulse[i]=0
			break
		endtry
		if(dimsize(temprises,0) == 1 && dimsize(tempfalls,0)== 1 ) // did we find a single pulse?
			alreadygood = goodpulse[i]
			rises[i] = timesin(temprises[0]) // if so, change them to times (so they work for all channels)
			falls[i] = timesin(tempfalls[0])
			waveout[i] = median(datain,binarysearchinterp(timesin,rises[i])+1,binarysearchinterp(timesin,falls[i])-1)
			stdwave[i] = sqrt(variance(datain,binarysearchinterp(timesin,rises[i])+1,binarysearchinterp(timesin,falls[i])-1))
			goodpulse[i]=1
		else
			if(alreadygood) // have we already found the rising and falling times?
				waveout[i] = median(datain,binarysearch(timesin,rises[i])+0,binarysearch(timesin,falls[i]))
				stdwave[i] = sqrt(variance(datain,binarysearch(timesin,rises[i])+0,binarysearch(timesin,falls[i])))
			else
				goodpulse[i]=0
			endif
		endif
	endfor
	
	//curvefit
	return waveout
end

Function NRB_setupNIKA_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			NRB_convertpathtonika(main=1)
			setup_NIKA_sectors(redosetup=1)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function setup_NIKA_sectors([redosetup])
	variable redosetup
	redosetup = paramisdefault(redosetup)? 0 : redosetup // don't redo the setup unless it's requested
	string foldersave = getdatafolder(1)
	setdatafolder root:packages:NIKANISTRSoXS:
	VARIABLE /G NIKAsetup
	if(NIKAsetup && !redosetup)
		return 0 // don't setup NIKA again, unless it's specifically asked for
	else
		NIKAsetup=1// set it so that NIKA setup is now 1 if it wasn't before
		// either NIKA wasn't setup yet, or it was but a new setup has been requested
	endif

	nvar UseSectors = root:Packages:Convert2Dto1D:UseSectors
	nvar UseMask = root:Packages:Convert2Dto1D:UseMask
	nvar QbinningLogarithmic = root:Packages:Convert2Dto1D:QbinningLogarithmic
	nvar DoCircularAverage = root:Packages:Convert2Dto1D:DoCircularAverage
	nvar UseQvector = root:Packages:Convert2Dto1D:UseQvector
	nvar QvectorNumberPoints = root:Packages:Convert2Dto1D:QvectorNumberPoints
	nvar DoSectorAverages = root:Packages:Convert2Dto1D:DoSectorAverages
	nvar DisplayDataAfterProcessing = root:Packages:Convert2Dto1D:DisplayDataAfterProcessing
	nvar StoreDataInIgor = root:Packages:Convert2Dto1D:StoreDataInIgor
	nvar OverwriteDataIfExists = root:Packages:Convert2Dto1D:OverwriteDataIfExists
	nvar Use2DdataName = root:Packages:Convert2Dto1D:Use2DdataName
	nvar NumberOfSectors = root:Packages:Convert2Dto1D:NumberOfSectors
	nvar SectorsHalfWidth = root:Packages:Convert2Dto1D:SectorsHalfWidth
	nvar SectorsStartAngle = root:Packages:Convert2Dto1D:SectorsStartAngle
	nvar SectorsStepInAngle = root:Packages:Convert2Dto1D:SectorsStepInAngle
	nvar DisplaySectorsEG_N2DGraph = root:Packages:Convert2Dto1D:DisplaySectorsEG_N2DGraph
	nvar DisplayBeamCenterEG_N2DGraph = root:Packages:Convert2Dto1D:DisplayBeamCenterEG_N2DGraph
	nvar SilentMode = root:Packages:Convert2Dto1D:SilentMode
	svar commandstr = root:Packages:Convert2Dto1D:CnvCommandStr
	nvar UseSubtractFixedOffset = root:Packages:Convert2Dto1D:UseSubtractFixedOffset
	nvar UseSolidAngle = root:Packages:Convert2Dto1D:UseSolidAngle
	nvar UseSampleMeasTime = root:Packages:Convert2Dto1D:UseSampleMeasTime
	nvar SubtractFixedOffset = root:Packages:Convert2Dto1D:SubtractFixedOffset
	
	

	UseSectors = 1
	UseMask = 1
	QbinningLogarithmic = 1
	DoCircularAverage = 1
	UseQvector = 1
	QvectorNumberPoints = 200
	DoSectorAverages = 1
	DisplayDataAfterProcessing = 0
	StoreDataInIgor = 1
	OverwriteDataIfExists = 1
	Use2DdataName = 0
	NumberOfSectors = 4
	SectorsHalfWidth = 10
	SectorsStartAngle = 0
	SectorsStepInAngle = 90
	DisplaySectorsEG_N2DGraph = 1
	DisplayBeamCenterEG_N2DGraph = 1
	silentmode = 1
	commandstr = "NRB_updateimageplot()"
	UseSubtractFixedOffset = 1
	UseSolidAngle = 1
	UseSampleMeasTime = 1
	SubtractFixedOffset = 100
	StartSwitchNika()
	wave /t listwave = root:Packages:SwitchNIKA:listwave
	listwave[0][0]= {"SAXS 11 16 2020","SAXS 12 01 2020","WAXS 12 01 2020","WAXS 12 11 2020","WAXS 2021"}
	listwave[0][1]= {"371.52","489.86","400.46","400.46","397"}
	listwave[0][2]= {"491.17","490.75","530.99","530.99","535.6"}
	listwave[0][3]= {"512.12","521.8","38.745","38.745","36.7"}
	listwave[0][4]= {"20405-PS300-primary-Small Angle CCD Detector_image-0.tiff_mask.tif","21476-PS300-primary-Small Angle CCD Detector_image-48.tiff_mask.tif","21143-JDM_103-primary-Wide Angle CCD Detector_image-0.tiff_mask.tif"}
	listwave[3][4]= {"21965-an_PF6_3-primary-Wide Angle CCD Detector_image-10.tiff_mask.tif",""}
	listwave[0][5]= {"D:RSoXS Documents:images:masks:","D:RSoXS Documents:images:masks:","D:RSoXS Documents:images:masks:","D:RSoXS Documents:images:masks:",""}
	listwave[0][6]= {"NaN","NaN","NaN","NaN","NaN"}
	listwave[0][7]= {"NaN","NaN","NaN","NaN","NaN"}
	listwave[0][8]= {"0.0009","0.00075","*","-93.999","NaN"}
	listwave[0][9]= {"67","67.7","*","67.7","*"}
	listwave[0][10]= {"0.4262","-94","-9.9995","-9.9997","-10"}
	listwave[0][11]= {"3","3","68.4","71.4","71.4"}
	listwave[0][12]= {"*","*","*","*","*"}
	nvar AutoPickQ = root:Packages:SwitchNIKA:AutoPickQ
	AutoPickQ=0
end



Function NRB_LoadQANT(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Execute/P "INSERTINCLUDE \"QANT\""
			Execute/P "COMPILEPROCEDURES "
			Execute/P/Q/Z "QANT_Loaderfunc()"
			svar /z directory = root:NEXAFS:directory
			if(!svar_exists(directory))
				print "QANT failed to load"
				break
			endif
			svar /z pathtodata = root:Packages:NikaNISTRSoXS:pathtodata
			directory = pathtodata
			newpath/o/q/z NEXAFSPath, pathtodata
			svar /z FileType = root:NEXAFS:FileType
			fileType = "bluesky"
			Execute/P/Q "QANT_CheckFulldir()"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function NRB_Copylocbut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NRB_Copyloc()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function NRB_Copyloc()
	wave selwave = root:Packages:NikaNISTRSoXS:steplistsel
	variable i, num 
	duplicate /free selwave, tempwave
	tempwave = selwave[p]&1? 1 : 0
	num = sum(tempwave)
//	NRB_MakeImagePlots(num)
	variable step = -1
	if(num==1)
		for(i=0;i<dimsize(selwave,0);i+=1)
			if(selwave[i]&1)	
				step = i
				break
			endif
		endfor
	endif
	if(step>=0)
		string foldersave = getdatafolder(1)
		setdatafolder root:Packages:NikaNISTRSoXS:Channels
		variable x = nan
		variable y = nan
		variable z = nan
		variable th = nan
		// try to use the waves!
		wave /z rsoxsx = RSoXS_Sample_Outboard_Inboard
		if(waveexists(rsoxsx))
			x = rsoxsx[step]
		endif
		wave /z rsoxsy = RSoXS_Sample_Up_Down
		if(waveexists(rsoxsy))
			y = rsoxsy[step]
		endif
		wave /z rsoxsz = RSoXS_Sample_Downstream_Upstream
		if(waveexists(rsoxsz))
			z = rsoxsz[step]
		endif
		wave /z rsoxsth = RSoXS_Sample_Rotation
		if(waveexists(rsoxsth))
			th = rsoxsth[step]
		endif
	
	
	
		// use baseline instead
		wave/z /t baseline0
		if(!waveexists(baseline0))
			setdatafolder foldersave
			return 0
		endif
		findvalue /text="RSoXS Sample Outboard-Inboard" baseline0
		x =x*0!=0? round(100*str2num(baseline0[V_value][1]))/100 : x
		findvalue /text="RSoXS Sample Up-Down" baseline0
		y =y*0!=0?  round(100*str2num(baseline0[V_value][1]))/100 : y
		findvalue /text="RSoXS Sample Downstream-Upstream" baseline0
		z =z*0!=0?  round(100*str2num(baseline0[V_value][1]))/100 : z
		findvalue /text="RSoXS Sample Rotation" baseline0
		th =th*0!=0?  round(100*str2num(baseline0[V_value][1]))/100 : th
		
		string output = "[{'motor': 'x', 'position': " + num2str(x)
		output +="}, {'motor': 'y', 'position': " + num2str(y)
		output +="}, {'motor': 'z', 'position': " + num2str(z)
		output +="}, {'motor': 'th', 'position': " + num2str(th) + "}]"
		putscrapText output
				
		setdatafolder foldersave
	endif
end

function NRB_find_and_aniso_scan(variable scan_id, variable num, string name,variable color_red,variable color_green,variable color_blue, variable offset)
	
	wave waves = NRB_findscan(scan_id , num)
	if(waveexists(waves))
		wave anisowaves = NRB_calc_aniso(waves, scan_id, num)
		NRB_graph_aniso(anisowaves,name,color_red,color_green,color_blue, offset)
	endif

end



function /wave NRB_findscan(variable scan_id, variable num)
	dfref foldersave = getdatafolderdfr()
	if(!datafolderExists("root:SAS"))
		wave /z nothing
		//print "No Conversion have been done yet"
		return nothing
	endif
	setdatafolder root:SAS
	variable i = 0
	string foldername = getindexedobjnamedfr(getdatafolderdfr(),4,i)
	string matchstr = "DataFileName=" + num2str(scan_id) + ".*-" + num2str(num) + ".tiff"
	string match
	do
		setdatafolder foldername
		wave rwave = $stringfromlist(0,wavelist("r_*_C",";",""))
		wave qwave = $stringfromlist(0,wavelist("q_*_C",";",""))
		if(waveexists(rwave) && waveexists(qwave))
			match = greplist(note(rwave),matchstr,0,";")
			if(strlen(match)>2)
				setdatafolder ::
				setdatafolder replacestring("_C", foldername, "_0_10")
				wave rwave0 = $stringfromlist(0,wavelist("r_*",";",""))
				wave qwave0 = $stringfromlist(0,wavelist("q_*",";",""))
				setdatafolder ::
				setdatafolder replacestring("_C", foldername, "_90_10")
				wave rwave90 = $stringfromlist(0,wavelist("r_*",";",""))
				wave qwave90 = $stringfromlist(0,wavelist("q_*",";",""))
				setdatafolder ::
				setdatafolder replacestring("_C", foldername, "_180_10")
				wave rwave180 = $stringfromlist(0,wavelist("r_*",";",""))
				wave qwave180 = $stringfromlist(0,wavelist("q_*",";",""))
				setdatafolder ::
				setdatafolder replacestring("_C", foldername, "_270_10")
				wave rwave270 = $stringfromlist(0,wavelist("r_*",";",""))
				wave qwave270 = $stringfromlist(0,wavelist("q_*",";",""))
				break
			endif
		endif
		i++
		setdatafolder root:SAS
		foldername =  getindexedobjnamedfr(getdatafolderdfr(),4,i)
	while(strlen(foldername)>0)
	if(strlen(match)>2)
		make /wave /n=10 /free wavewave
		wavewave[0] = rwave
		wavewave[1] = qwave
		wavewave[2] = rwave0
		wavewave[3] = qwave0
		wavewave[4] = rwave90
		wavewave[5] = qwave90
		wavewave[6] = rwave180
		wavewave[7] = qwave180
		wavewave[8] = rwave270
		wavewave[9] = qwave270
		setdatafolder foldersave
		return wavewave
	else
		//		no conversion
		//print("can't find conversion")
		wave /z nullwave
		setdatafolder foldersave
		return nullwave
	endif	
end

function NRB_Convertifneeded()
	EGN_BSLoaderPanelFnct()
	string filelist = NRB_getfilenames()
	string storefilelist = filelist
	svar steplist = root:Packages:NikaNISTRSoXS:listofsteps
	nvar scanid =  root:Packages:NikaNISTRSoXS:channels:scan_id
	variable i,count,countdone
	for(i=itemsinlist(steplist)-1;i>=0;i--)
		wave testwave = NRB_findscan(scanid,str2num(stringfromlist(i,steplist)))
		if(waveexists(testwave))
			filelist = removelistitem(i,filelist)
		endif
	endfor
	if(itemsinlist(filelist)==0) // all files were done previously, but user is asking for conversion, so give it to them!
		NRB_convertnikafilelistsel(storefilelist)
	else
		NRB_convertnikafilelistsel(filelist)
	endif
end


function /wave NRB_calc_aniso(wave /wave wavewave, variable scan_id, variable num)
	wave rwave = wavewave[0]
	wave qwave = wavewave[1]
	wave rwave0 = wavewave[2]
	wave qwave0 = wavewave[3]
	wave rwave90 = wavewave[4]
	wave qwave90 = wavewave[5]
	wave rwave180 = wavewave[6]
	wave qwave180 = wavewave[7]
	wave rwave270 = wavewave[8]
	wave qwave270 = wavewave[9]
	dfref foldersave = getdatafolderdfr()
	setdatafolder root:SAS
	
	setdatafolder root:
	newdatafolder /o/s NRBdata
	newdatafolder /o/s $("scan"+num2str(scan_id))
	newdatafolder /o/s $("img"+num2str(num))
	duplicate /o rwave, $nameofwave(rwave)
	duplicate /o qwave, $nameofwave(qwave)
	wave newrwave = $nameofwave(rwave)
	wave newqwave = $nameofwave(qwave)
	variable minq = max(max(wavemin(qwave0),wavemin(qwave90)),max(wavemin(qwave180),wavemin(qwave270)))
	variable maxq = min(min(wavemax(qwave0),wavemax(qwave90)),min(wavemax(qwave180),wavemax(qwave270)))
	make /o/n=200 anisoq, anisor, parar, perpr
	setscale /i x,ln(minq),ln(maxq), anisoq
	anisoq = exp(x)
	parar = ( interp(anisoq,qwave0,rwave0) + interp(anisoq,qwave180,rwave180) )/2
	perpr = ( interp(anisoq,qwave90,rwave90) + interp(anisoq,qwave270,rwave270) )/2
	anisor = (parar-perpr) / (parar + perpr)
	make /free/wave/n=6 aniso_waves
	aniso_waves[0] = parar
	aniso_waves[1] = perpr
	aniso_waves[2] = anisor
	aniso_waves[3] = anisoq
	aniso_waves[4] = rwave
	aniso_waves[5] = qwave
	setdatafolder foldersave
	return aniso_waves
end

function NRB_graph_aniso(wave /wave anisowaves,string name,variable color_red,variable color_green,variable color_blue,variable offset)
	wave parar = anisowaves[0]
	wave perpr = anisowaves[1]
	wave anisor = anisowaves[2]
	wave anisoq = anisowaves[3]
	wave rwave = anisowaves[4]
	wave qwave = anisowaves[5]
	
	appendtograph /w=NISTRSoXSBrowser#profiles parar /TN=$(Name+"pe"), perpr /TN=$(Name+"pa") vs anisoq
	appendtograph /w=NISTRSoXSBrowser#profiles rwave /TN=$(Name+"r") vs qwave
	ModifyGraph /w=NISTRSoXSBrowser#profiles log=1
	ModifyGraph /w=NISTRSoXSBrowser#profiles mode($(Name+"pe"))=7,hbFill($(Name+"pe"))=5,useNegPat($(Name+"pe"))=1,hBarNegFill($(Name+"pe"))=3,toMode($(Name+"pe"))=1
	modifygraph /w=NISTRSoXSBrowser#profiles rgb($(Name+"pa")) = (color_red,color_green,color_blue)
	modifygraph /w=NISTRSoXSBrowser#profiles rgb($(Name+"pe")) = (color_red,color_green,color_blue)
	modifygraph /w=NISTRSoXSBrowser#profiles rgb($(Name+"r")) = (color_red,color_green,color_blue)
	modifygraph /w=NISTRSoXSBrowser#profiles muloffset($(Name+"pa"))={0,offset}
	modifygraph /w=NISTRSoXSBrowser#profiles muloffset($(Name+"pe"))={0,offset}
	modifygraph /w=NISTRSoXSBrowser#profiles muloffset($(Name+"r"))={0,offset}
end

function NRB_loadprofiles(string list)
	nvar scan_id =  root:Packages:NikaNISTRSoXS:channels:scan_id
	variable i
	string stepbase, name
	string traces = traceNameList("NISTRSoXSBrowser#profiles",";",1)
	for(i=itemsinlist(traces)-1;i>=0;i--)
		RemoveFromGraph /W=NISTRSoXSBrowser#profiles /Z $stringfromlist(i,traces)
	endfor
	wave /t scans = root:Packages:NikaNISTRSoXS:scanlist
	wave /t steps = root:Packages:NikaNISTRSoXS:steplist
	
	nvar offsetnum = root:Packages:NikaNISTRSoXS:profileoffset
	
	variable offset = 1
	variable offsetstep = offsetnum * .1
	
	
	Variable numTraces =itemsinlist(list)
	if (numTraces <= 0)
		return -1
	endif
	variable numtracesden=numtraces
	if( numTraces < 2 )
		numTracesden= 2	// avoid divide by zero, use just the first color for 1 trace
	endif
	ColorTab2Wave YellowHot
	wave RGB = M_colors
	Variable numRows= DimSize(rgb,0)
	Variable red, green, blue
	Variable index
	for(i=0; i<numTraces; i+=1)
		index = round(i/(numTracesden-1) * (numRows*2/3-1))	// spread entire color range over all traces.
		red = rgb[index][0]
		green = rgb[index][1]
		blue =  rgb[index][2]
		splitstring /e="[0-9|step]* - (.*)" steps[str2num(stringfromlist(i,list))], stepbase
		name = cleanupname("s"+num2str(scan_id)+"_"+stepbase,0)
		
		NRB_find_and_aniso_scan(scan_id, str2num(stringfromlist(i,list)),name,red, green, blue, 2^offset)
		offset += offsetstep
	endfor
	
end

Function NRB_profileslider(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				NRB_updateimageplot()
			endif
			break
	endswitch

	return 0
End


Function NRB_pop_Profilebut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function NRB_SelectAll(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			wave stepsel = root:Packages:NikaNISTRSoXS:steplistsel
			stepsel = 8
			NRB_updateimageplot()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End