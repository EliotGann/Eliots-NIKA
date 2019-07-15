#pragma rtGlobals=1		// Use modern global access method.
#include "EGN_ADE-ALS11012"
#include "EGN_Loader"
function initialize1101panel()
	String CurrentFolder=GetDataFolder(1)
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:Nika1101
	string /g pathtodata,pathname,ccdpath,loadeddatadir,header,imagekeys,imagevalue,filebasename,imagekeypick,test123123
	variable /g ckautoshow=1,logimage=1,normI0,indexrow,n2save,showmask,endplotrun,plotrunsp,plotrunst,plotrunend,normalizedata=0,maxslider=4,minslider=0,writedata=0
	make /t /o /n=5000 basenames,motors,scans,scantypes,times,files, motor1pos,motor2pos,motor3pos,motor4pos,motor5pos,darkpos,I0s, samplenames
	make /t /o /n=5000 m1wave,m2wave,avgwave
	make /o /n=5000 frames,nmotors,scanNum, FSindex
	make /d /o /n=(2048,2048) data_disp, datax,datay
	make /b/u/o /n=(2048,2048) avg_Mask=1, data_mask
	make /o /t /n=0 files,filedisc
	make /o /n=0 filesel
	scans=""
	execute "DataReduction()"
	STRUCT WMButtonAction ba
	ba.eventCode=2
	browse(ba)
	SetDataFolder $CurrentFolder
end

function realfitsloader(filename,path,dataname,datasave)
	string filename, path, dataname
	variable datasave
	datasave=0 // this value is depricated, and breaks the code
	variable refnum
	string /g lineread 
	string header,key,value,comment
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	svar loadeddatadir
	PathInfo $path
	if(v_flag==0)
		newpath fitspath
		if(V_flag==0)
			path = "fitspath"
		else
			return 0
		endif
	endif
	GetFileFolderInfo /P=$path /q /Z filename
	if(v_flag==0 && cmpstr(filename,""))
		open/Z /R /T="BINA" /p=$path refnum as filename
	else
		refnum = -1
		open /F="FITS Files (*.fits):.fits;" /D=1 /R /p=$path /T="BINA" refnum as filename
		if(refnum==-1)
			print "file not opened"
			return 0
			endif
	endif
	Fstatus refnum
	if(refnum==0)
		print "File was not opened"
		return 0
	endif
//Read Header
	header = ""
	for(lineread = "";!stringmatch(lineread,"END*");)
		FReadline /N=80 refnum,lineread
		splitstring /e="^(\\s*?HIERARCH\\s*?)?(.*?)\\s*=\\s*'?([^'\r\n]{1,})'?\\s*/\\s*([^'\r\n]*)\\s*$" lineread,key,key,value,comment
		if(cmpstr(key,""))
			key = ReplaceString(" ",key,"")
			header+=key +":"+ value+";"
		endif
	endfor
	
//	for(lineread = "";!stringmatch(lineread,"END*");)
//		FReadline /N=80 refnum,lineread
//		splitstring /e="^(\\s*?HIERARCH\\s*?)?(.*?)\\s*?=\\s*'?([^'\r\n]{0,})'?\\s*/\\s*([^'\r\n]*)\\s*$" lineread,key,key,value,comment
//		if(cmpstr(key,""))
//			key = ReplaceString(" ",key,"")
//			header+=key +":"+ value+";"
//		endif
//	endfor

	//read the next big chunck of file and search for xtensions
	variable testline=0
	variable findextension=0	
	variable lastextfpos=0
	variable imageextfpos=0
	variable imagefpos=0
	for(testline=0;testline<2000 &&!stringmatch(lineread,"*END*");testline+=1) // catch all the normal (non-xtension) header items until the first "END"
		FReadline /N=80 refnum,lineread
		splitstring /e="^(\\s*?HIERARCH\\s*?)?(.*?)\\s*=\\s*'?([^'\r\n]{1,})'?\\s*/\\s*([^'\r\n]*)\\s*$" lineread,key,key,value,comment
		if(cmpstr(key,""))
			key = ReplaceString(" ",key,"")
			header+=key +":"+ value+";"
		endif
	endfor
	Do
		FStatus refnum
		variable fpos=V_filePos //remember this place in the file in case there are no more xtensions
		//Look for xtension if there is any
		for(testline=0;testline<800;testline+=1)
			if(strlen(lineread)>12 || testline==0)
				fsetpos refnum,fpos-12
			endif
			FReadline /T=(num2char(61)) refnum,lineread
			FStatus refnum
			fpos=V_filePos
			if(grepstring(lineread,"XTENSION\\s*?=") )//the xtension is in this chunk somehow
				fstatus refnum
				fsetpos refnum,(v_filepos + strsearch(lineread,"XTENSION",inf,3)-strlen(lineread))
				fstatus refnum
				lastextfpos=v_filepos
				FReadline /n=80 refnum,lineread
				splitstring /e=".*(XTENSION)\\s*?=\\s*'?([^'\r\n]{0,})'?\\s*/\\s*([^'\r\n]*)\\s*.*" lineread,key,value,comment
//				byteoffset = mod(v_filepos,80)
				findextension =1
				break
			else
				findextension=0
			endif
		endfor
		if(findextension)
			string extension = ReplaceString(" ",value,"") //set the extension to the value of the previous read, which should be the xtension=line
			for(lineread = "";!stringmatch(lineread,"*END*");)
				FReadline /N=80 refnum,lineread
				splitstring /e="^(\\s*?HIERARCH\\s*?)?(.*?)\\s*?=\\s*'?([^'\r\n]{0,})'?\\s*/\\s*([^'\r\n]*)\\s*$" lineread,key,key,value,comment
				if(cmpstr(key,""))
					key = ReplaceString(" ",key,"")
					header+=extension+"-"+key +":"+ value+";"
				endif
			endfor
			fstatus refnum
			if(!cmpstr(extension,"IMAGE"))
				imageextfpos=V_filePos
				imagefpos = lastextfpos
			endif
		else
			break
		endif
	While(1)
	Fsetpos refnum,fpos
	//Grab a few variables we will need from the header
	variable expose = str2num(stringbykey("Exposure",header))
	string energy1 = stringbykey("BeamlineEnergy",header,":",";")
	//variable i0 =str2num(stringbykey("Izero",header))
	variable i0 =str2num(stringbykey("AI6Beamstop",header))
	variable Izero = str2num(stringbykey("AI3Izero",header))
	variable en=str2num(stringbykey("BeamlineEnergy",header))
	variable pol=str2num(stringbykey("EPUPolarization",header))
	variable os=str2num(stringbykey("HigherOrderSuppressor",header))
	variable bzero = str2num(stringbykey("IMAGE-BZERO",header,":",";"))
	if(bzero*0!=0)
		bzero = str2num(stringbykey("BZERO",header,":",";"))
	endif
	variable xdim = str2num(stringbykey("IMAGE-NAxis1",header,":",";"))
	if(xdim*0!=0)
		xdim = str2num(stringbykey("Naxis1",header,":",";"))
	endif
	variable ydim = str2num(stringbykey("IMAGE-NAxis2",header,":",";"))
	if(ydim*0!=0)
		ydim = str2num(stringbykey("Naxis2",header,":",";"))
	endif
	if(xdim*ydim*bzero*0!=0)
		print "Fits file does not meet requirements of having dimensions of image, please load a different file"
		return 0
	endif
	variable CCDx  = str2num(stringbykey("CCDX",header))
	variable CCDTheta  = str2num(stringbykey("CCDTheta",header))
	variable bitpix  = str2num(stringbykey("IMAGE-BITPIX",header))
	if(bitpix*0!=0)
		bitpix=16
	endif
	if(xdim==nan ||ydim==nan)
		print "cannot get dimensions from the file header"
		close refnum
		return 0
	endif
	//Write header to a few locations so it is available
	string /g root:packages:nika1101:headerinfo = header
	//string /g root:headerinfo = header
//Read Data
	Fstatus refnum
	variable imagesize=0
	if(imageextfpos>0)
		FSetPos refNum, imagefpos+ (2880*ceil((imageextfpos-imagefpos)/2880)) // set position in in the header to next multiple of 2880
		imagesize = imagefpos + (2880*ceil((imageextfpos-imagefpos)/2880))+bitpix*xdim*ydim/8
	else
		FSetPos refNum, lastextfpos+(2880*ceil((V_filePos-lastextfpos)/2880)) // set position in in the header to next multiple of 2880
		imagesize = lastextfpos+(2880*ceil((V_filePos-lastextfpos)/2880))+bitpix*xdim*ydim/8
	endif
	switch (chkwaitfile(filename,imagesize,path)) 	//check if filename is the right size in loop sleep .1 second between reads
		case -2:
			print "file could not be opened at all"
			String/G root:Packages:Nika1101:bkg:message="file could not be opened even to check the size"
			return -1
		case -1:
			print "timed out waiting for file to be written"
			String/G root:Packages:Nika1101:bkg:message="timed out waiting for file to be written"
			return -1
	endswitch
	if(datasave)
		newdatafolder /s /o root:Packages:Nika1101:$dataname
		make/o /d /n=(xdim,ydim) $dataname
		FBinRead /B=2 /F=2 /u refNum, $dataname
		loadeddatadir = "root:" + dataname + ":" + dataname
	else
		make/o /d /n=(xdim,ydim) root:Packages:Nika1101:data
		FBinRead /B=2 /F=2 /u refNum, root:Packages:Nika1101:data
		loadeddatadir = "root:Packages:Nika1101:data"
	endif
	wave data = $loadeddatadir
	imagetransform flipCols data
	//string /g headerinfo = header
	string /g root:Packages:Nika1101:headerinfo = header
	redimension /d data
//Correct DATA as needed
	//Correct data from BZERO (an offset because Fits files are only Signed, where as the data is unsigned)
	data-=bzero
	//Flatten or at least subtract the background offset from the image
	nvar chkflatten = root:Packages:Nika1101:chkflatten,flatten_line = root:Packages:Nika1101:flatten_line,flatten_width = root:Packages:Nika1101:flatten_width
	if(chkflatten)
		//gatherstatsandflatten(data,flatten_line,flatten_width)
		flattenimage(data,flatten_line,flatten_width)
		data+=0//set arbitrarily
	else
		if(!waveexists(data_mask)||dimsize(data_mask,1)!=dimsize(data,1)||wavetype(data_mask)!=0x48)
			make /o/n=(dimsize(data,0),dimsize(data,1)) data_mask
			redimension /b/u data_mask
			data_mask = ((p+50>dimsize(data_mask,0))&&(q+50>dimsize(data_mask,1))) ? 0 : nan
		endif
		imagestats /R=data_mask data
		data-=v_avg-100
	endif
	//Calculate the corrected I0 if necessary (number of incident photons incident)
//	nvar AI3izero = root:Packages:Nika1101:AI3izero
//	if(AI3izero)
//		i0 = correcti0(izero,en,pol,os) // should return photons that this izero corresponds to
////.		print "Using Photodiode Beamstop value for I0 correction.  Value = " + num2str(i0)
//	else
//		i0 = correcti0(i0,en,pol,os)
//	endif
//	//Divide the image by the exposure time if requested
//      data/=i0
//	nvar Exposecorr = root:Packages:Nika1101:Exposecorr
//	if(exposecorr)
//		data /= Expose
//		print "Data corrected for " + num2str(Expose) + " second exposure"
//	endif	
//	//Correct Image to Number of photons rather than ADUs
//	nvar correctionfactor = root:Packages:Convert2Dto1D:correctionfactor
//	correctionfactor = 1/(str2num(energy1) / 10.0) // this is the quantum efficiency of the 
//	print "Sample correction factor set to " + num2str(str2num(energy1) / 10.0) + " ADUs / Photon"
//	
//wavenote for data
	string wnote = replacestring(":",header,"=")
	
	note data,wnote 
//	wavestats/g $loadeddatadir
//	Fstatus refnum
	close refnum
	setdatafolder $currentFolder
//	print header
end

function openfits(filename, path)
	string filename,path
	string captionstring
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	svar loadeddatadir
	variable refnum
	nvar ckautoshow,logimage,writedata,minslider,maxslider
	//print path
	//print filename
	string dataname,basenamecut,midnamecut,endname,pngname
	Splitstring /E="^(.{2,7}).*?(....)-?(...)\.fits$" filename,basenamecut,midnamecut,endname
	dataname=basenamecut+"_"+midnamecut+endname
	string fldrsav0=getdatafolder(1)
	realfitsloader(filename,path,dataname,writedata)
	wave data = $loadeddatadir
//	If(ckautoshow)
		duplicate /o $loadeddatadir root:Packages:Nika1101:data_disp
		wave data_disp = root:Packages:Nika1101:data_disp
		//if(logimage)
		//	data_disp = log(data_disp)
		//endif
		removeimage /Z /W=datareduction#G0 data_disp
		appendimage /W=datareduction#G0 data_disp
		ModifyImage /W=datareduction#G0 data_disp ctab= {minslider,maxslider,terrain256,0},log=1
		SetAxis/A/R /W=datareduction#G0 left
//		captionstring = "Max = " + num2str(wavemax($loadeddatadir))
//		TextBox /W=datareduction#G0/C/N=text1/F=0/S=3/B=3/E=2/X=63.00/Y=63.00 captionstring
		TextBox  /W=datareduction#G0 /C/N=text0/F=0/S=3/B=3/E=2 /X=30.94/Y=11.59  ""
//	endif
	SetDataFolder $CurrentFolder
end
function openpng(filename, path)
	string filename,path
	string captionstring
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101

	svar loadeddatadir
	variable refnum
	nvar ckautoshow,logimage,writedata,maxslider,minslider
	//print path
	//print filename
	string dataname,basenamecut,midnamecut,endname,pngname
	Splitstring /E="^(.{2,7}).*?(.{3})-?(.{2})\.fits$" filename,basenamecut,midnamecut,endname
	dataname=basenamecut+"_"+midnamecut+endname
	string fldrsav0=getdatafolder(1)
	loadeddatadir =fldrsav0+":data"
	killwaves /z data
	ImageLoad/o/T=rpng/N=data /p=$path filename
	loadeddatadir = stringfromlist(0,S_waveNames,";")
	
	If(V_flag)
		wave data = $loadeddatadir
		duplicate /o data root:Packages:Nika1101:data_disp
		wave data_disp = root:Packages:Nika1101:data_disp
		if(logimage)
			redimension/d data_disp
			data_disp = log(data_disp)
			
		endif
		removeimage /Z /W=datareduction#G0 data_disp
		appendimage /W=datareduction#G0 data_disp
		ModifyImage /W=datareduction#G0 data_disp ctab= {minslider,maxslider,terrain256,0}
		SetAxis/A/R /W=datareduction#G0 left
		captionstring = "Max = " + num2str(wavemax($loadeddatadir))
		TextBox /W=datareduction#G0/C/N=text1/F=0/S=3/B=3/E=2/X=63.00/Y=63.00 captionstring
		TextBox  /W=datareduction#G0 /C/N=text0/F=0/S=3/B=3/E=2 /X=30.94/Y=11.59  ""
	endif
	setDataFolder $CurrentFolder
end


Function LoadAndGenerateStringAll(path)
	string path
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	svar pathname,ccdpath		// Name of symbolic path or "" to get dialog
	String fileName
	String graphName
	Variable index=0
	make /t /o /n=500 basenames,motors,scans,scantypes,times,motor1pos, motor2pos,motor3pos, motor4pos,motor5pos, darkpos, I0s, samplenames
	scans=""
	make /o /n=500 frames,nmotors,scanNum, FSindex
	if (strlen(path)<1)			// If no path specified, create one
		NewPath/O/m="path for txt files" Path_1101panel			// This will put up a dialog
		if (V_flag != 0)
			return -1						// User cancelled
		endif
		path = "Path_1101panel"
		NewPath/O/m="path for fits files" Path_1101panelccd			// This will put up a dialog
		if (V_flag != 0)
			return -1						// User cancelled
		endif
	endif
	pathname = path
	string filenames = sortlist(IndexedFile($pathName, -1, ".txt"),";",4)
	if(strlen(filenames)<1)
		print "No txt files found in directory"
		return 0
	endif

	Variable result
	motor1pos=""; motor2pos="";motor3pos="";motor4pos="";motor5pos="";darkpos=""; I0s="";samplenames=""
	variable goodindex=0
	do			// Loop through each file in folder
		fileName = stringfromlist(index,filenames, ";")
		if (strlen(fileName) <1)			// No more files?
			break									// Break out of loop
		endif

		if(stringmatch(filename,"*-AI.txt"))
			LoadandStoreData(Filename,pathname,goodindex)
			goodindex +=1
		endif
		
		index += 1
	while (1)
	redimension /n=(goodindex) scans, scanNum, FSindex, basenames, times, scantypes, motors, nmotors, frames
	redimension /n=(goodindex,-1) motor1pos, motor2pos,motor3pos, motor4pos,motor5pos, darkpos, I0s, samplenames
	sort scanNum, scans, FSindex, basenames, times, scantypes, motors, nmotors,frames, motor1pos, motor2pos,motor3pos, motor4pos,motor5pos, darkpos, I0s, samplenames
	SetDataFolder $CurrentFolder
	return 0						// Signifies success.
End

Function LoadandStoreData(Filename,path,index)
	string Filename, Path
	variable index
	variable fileref,nmotors1,len,i,ech
	string name,indexnum,basename,lineread,scantype,dummy,motor1,motor2, motor3, motor4, motor5

	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	Splitstring /E="(.*)_?(\\d{4})-AI.txt$" filename,name,indexnum
	Splitstring /E="(.*)-AI.txt$" filename,basename
	wave /t basenames,motors,scans,scantypes,times,motor1pos,motor2pos,motor3pos,motor4pos,motor5pos,darkpos,I0s, samplenames
	wave frames,nmotors,scanNum,FSindex
	basenames[index]=basename
	
	GetFileFolderInfo /q /p=$path filename
	if(v_flag !=0)
		print "File not found,"
		scans[index]="file could not be opened"
		return 0
	endif
	times[index]=secs2time(V_modificationDate,1)
	
	open /z /R /P=$path /T="Text" fileref as filename
	if(v_flag !=0)
		print "File could not be opened"
		scans[index]="File could not be opened"
		return 0
	endif
	
	FReadline /N=2000 /T=(num2char(13)) fileref,lineread
	if(strlen(lineread)>3 ||stringmatch("{*=*}*",lineread))
		splitstring /e="{(.*)}" lineread, lineread
		samplenames[index] = lineread
	endif
	FReadline /N=2000 /T=(num2char(13)) fileref,lineread
	FReadline /N=2000 /T=(num2char(13)) fileref,lineread
	if(strlen(lineread)==0)
		print "not enough information in file"
		scans[index]="not enough information in file"
		close fileref
		return 0
	endif
	Splitstring /E=".*:(.*)$" lineread,scantype
	scantypes[index]=scantype
	len=strlen(lineread)
	ech=-1
	for(;(len>0)&&(ech==-1);) 
		FReadline /N=2000 /T=(num2char(13)) fileref,lineread
		ech =  strsearch(lineread, "Background ROI",0)
		len=strlen(lineread)
	endfor
	
	FReadline /N=2000 /T=(num2char(13)) fileref,lineread
	if(strsearch(lineread, "Path:",0)>-1)
		FReadline /N=2000 /T=(num2char(13)) fileref,lineread
	endif
	if(strlen(lineread)==0)
		print "motor scan did not complete"
		scans[index]= "motor scan did not complete"
		close fileref
		return 0
	endif
	motor1 = stringfromlist(1,lineread,"	")
	motor2 = stringfromlist(2,lineread,"	")
	if(stringmatch(lineread,"*Beamline Energy*") && !stringmatch(motor1,"Beamline Energy")&& !stringmatch(motor2,"Beamline Energy"))
		motor3 = "Beamline Energy"
	else
		motor3 = stringfromlist(3,lineread,"	")
	endif
	if(stringmatch(lineread,"*EPU Polarization*")&& !stringmatch(motor1,"EPU Polarization")&& !stringmatch(motor2,"EPU Polarization"))
		motor4 = "EPU Polarization"
	else
		motor4 = stringfromlist(5,lineread,"	")
	endif
	if(stringmatch(lineread,"*CCD Y*")&& !stringmatch(motor1,"CCD Y")&& !stringmatch(motor2,"CCD Y"))
		motor5 = "CCD Y"
	else
		motor5 = stringfromlist(5,lineread,"	")
	endif
	///Collins
	motor1= ShortenMotor(motor1)
	motor2= ShortenMotor(motor2)
	motor3= ShortenMotor(motor3)
	motor4= ShortenMotor(motor4)
	motor5= ShortenMotor(motor5)
	
	if(strlen(motor1)==0 || (!cmpstr(motor1,"CCD Temperature") || !cmpstr(motor1,"M3 Mirror Current")) || (!cmpstr(motor1,"Beam Current")))
		motors[index]="N/A"
		scans[index]= ""//"no Motors"
		nmotors1=0
	else 
		if(strlen(motor2)==0 || (!cmpstr(motor2,"I0"))  || (!cmpstr(motor2,"Beam Current"))  || (!cmpstr(motor2,"CCD Temperature")) || (!cmpstr(motor2,"M3 Mirror Current")))
			motors[index]= motor1
			scans[index]= motor1
			nmotors1=1
		else
			if(strlen(motor3)==0 || (!cmpstr(motor3,"I0"))  || (!cmpstr(motor3,"Beam Current"))  || (!cmpstr(motor3,"CCD Temperature")) || (!cmpstr(motor3,"M3 Mirror Current")))
				motors[index]= motor1 + "," + motor2
				scans[index]= motor1 + "," + motor2
				nmotors1=2
			else
				if(strlen(motor4)==0 || (!cmpstr(motor4,"I0"))  || (!cmpstr(motor4,"Beam Current"))  || (!cmpstr(motor4,"CCD Temperature")) || (!cmpstr(motor4,"M3 Mirror Current")))
					motors[index]= motor1 + "," + motor2+ "," + motor3
					scans[index]= motor1 + "," + motor2+ "," + motor3
					nmotors1=3
				else
					if(strlen(motor5)==0 || (!cmpstr(motor5,"I0"))  || (!cmpstr(motor5,"Beam Current"))  || (!cmpstr(motor5,"CCD Temperature")) || (!cmpstr(motor5,"M3 Mirror Current")))
						motors[index]= motor1 + "," + motor2+ "," + motor3+ "," + motor4
						scans[index]= motor1 + "," + motor2+ "," + motor3+ "," + motor4
						nmotors1=4
					else
						motors[index]=motor1 + "," + motor2+ "," + motor3+ "," + motor4+ "," + motor5
						scans[index]=motor1 + "," + motor2+ "," + motor3+ "," + motor4+ "," + motor5
						nmotors1=5
					endif
				endif
			endif
		endif
	endif
	variable I0loc,M1loc,M2loc,M3loc,M4loc,M5loc,BCloc,ShutLoc
	BCloc = whichlistitem("Beam Current",lineread,"	")
	m1loc = whichlistitem(Lmotor(motor1),lineread,"	")
	m2loc = whichlistitem(Lmotor(motor2),lineread,"	")
	m3loc = whichlistitem(Lmotor(motor3),lineread,"	")
	m4loc = whichlistitem(Lmotor(motor4),lineread,"	")
	m5loc = whichlistitem(Lmotor(motor5),lineread,"	")
	ShutLoc = whichlistitem("CCD Shutter Inhibit",lineread,"	")
	m1loc = m1loc==-1 ? nan : m1loc
	m2loc = m2loc==-1 ? nan : m2loc
	m3loc = m3loc==-1 ? nan : m3loc
	m4loc = m4loc==-1 ? nan : m4loc
	m5loc = m5loc==-1 ? nan : m5loc
	ShutLoc = ShutLoc==-1 ? nan : ShutLoc
	I0loc = whichlistitem("I0",lineread,"	")
	nmotors[index]=nmotors1
	len=strlen(lineread)
	For(i=0;len != 0;i+=1)
		FReadline /N=2000 /T=(num2char(13)) fileref,lineread
		len = strlen(lineread)
		if(len>0)
			motor1pos[index] += num2str(str2num(StringFromList(M1loc, lineread , "	")))+";"
			motor2pos[index] += num2str(str2num(StringFromList(M2loc, lineread , "	")))+";"
			motor3pos[index] += num2str(str2num(StringFromList(M3loc, lineread , "	")))+";"
			motor4pos[index] += num2str(str2num(StringFromList(M4loc, lineread , "	")))+";"
			motor5pos[index] += num2str(str2num(StringFromList(M5loc, lineread , "	")))+";"
			if(shutloc*0==0)
				darkpos[index] += num2str(str2num(StringFromList(ShutLoc, lineread , "	")))+";"
			else
				darkpos[index] += "0;"
			endif
			I0s[index] += StringFromList(I0loc, lineread , "	")+";"
		endif
	endfor
	frames[index]= i-2
	if(i==1)
		frames[index]=1
	endif
	scanNum[index]=str2num(indexnum)
	FSindex[index]=index
	scans[index]=indexnum + " - " + num2str(frames[index]) + " image(s) " + scans[index] + " '" + Basename+"'"
	if(frames[index]>1)
		//print scans[index]
	endif
	close fileref
	SetDataFolder $CurrentFolder
	return 0
end	

function loaddatalist(row)
	variable row
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	string/g filelist
	string/g samplenamelist
	svar ccdpath
	wave/t basenames,motors,motor1pos,motor2pos,motor3pos,motor4pos,motor5pos, darkpos, samplenames
	samplenamelist = samplenames[row]
	wave nmotors
	filelist = ListMatch(sortlist(IndexedFile($ccdpath,-1, ".fits"),";",17),basenames[row]+"*") //add png here as well
	//if fits then get the time, and return that as well
	//if only png, then the time is unknown
	if(strlen(filelist)<1)
		make /o /t /n=1 files,filedisc
		files = "No files found"
		filedisc = "No files found"
		filelist = ListMatch(IndexedFile($ccdpath,-1, ".png"),basenames[row]+"*")
		if(strlen(filelist)>0)
			displaypng(filelist)
		endif
		return 0
	endif
	make /o /t /n=(itemsinlist(filelist,";")) files,filedisc
	make /o /n=(itemsinlist(filelist,";")) filesel
	wave /t files,filedisc
	files = stringfromlist(p,filelist,";")
	variable j
	if(str2num(darkpos[row])*0==0) // is the dark value even recorded?
		for(j=0;j<dimsize(filedisc,0);j+=1)
			if(str2num(stringfromlist(j,darkpos[row])))
				filedisc[j] = "D"+num2str(j+1)
			else
				filedisc[j] = num2str(j+1)
			endif
		endfor
	else
		filedisc = num2str(p+1)
	endif
	If(nmotors[row]==0)
		filedisc += "_"+basenames[row]
	elseif( nmotors[row]==1 )
		filedisc += "_("+stringfromlist(p,motor1pos[row])+") ("+motors[row]+")"
	elseif( nmotors[row]==2 )
		filedisc += "_("+stringfromlist(p,motor1pos[row])+","+stringfromlist(p,motor2pos[row])+") ("+motors[row]+")"
	elseif( nmotors[row]==3 )
		filedisc += "_("+stringfromlist(p,motor1pos[row])+","+stringfromlist(p,motor2pos[row])+","+stringfromlist(p,motor3pos[row])+") ("+motors[row]+")"
	elseif( nmotors[row]==4 )
		filedisc += "_("+stringfromlist(p,motor1pos[row])+","+stringfromlist(p,motor2pos[row])+","+stringfromlist(p,motor3pos[row])+","+stringfromlist(p,motor4pos[row])+") ("+motors[row]+")"
	elseif( nmotors[row]==5 )
		filedisc += "_("+stringfromlist(p,motor1pos[row])+","+stringfromlist(p,motor2pos[row])+","+stringfromlist(p,motor3pos[row])+","+stringfromlist(p,motor4pos[row])+","+stringfromlist(p,motor5pos[row])+") ("+motors[row]+")"
	endif
	ControlInfo fitslist
	//print numpnts(files)
	if(v_value>0 && v_value<numpnts(files))
		listbox /Z fitslist selrow=v_value
		displayfits(v_value)
	elseif(v_value>numpnts($ (s_datafolder+s_value) ))
		listbox /Z fitslist selrow=numpnts($ (s_datafolder+s_value) )-1
		displayfits(numpnts($ (s_datafolder+s_value) )-1)
	else
		listbox /Z fitslist selrow=0
		displayfits(0)
	endif
	svar header = root:Packages:Nika1101:headerinfo
	string /g imagetime
	variable hour,minute,second, month, day
	sscanf stringbykey("DATETIME",header),"%d/%d/%*d %d%*[:]%d%*[:]%d",month, day,hour,minute,second
	if(month==0)
		sscanf stringbykey("DATETIME",header),"%*d-%d-%dT%d%*[:]%d%*[:]%d",month,day,hour,minute,second
		if(month==0)
			sscanf stringbykey("DATE",header),"%*d-%d-%dT%d%*[:]%d%*[:]%d",month,day,hour,minute,second
		endif
	endif
	sprintf imagetime, "%d/%d %d:%02d:%02d", month, day, hour, minute, second
	string/g imagekeys=""
	string s1
	variable i
	for(i=0;i<itemsinlist(header,";");i+=1)
		splitstring /e="^([^:]*):.*$" stringfromlist(i,header,";"),s1
		imagekeys+=s1+";"
	endfor
	svar imagekeypick
	string/g imagevalue
	imagevalue = stringbykey(imagekeypick,header)
	PopupMenu Key,mode=1,popvalue=imagekeypick//,value=imagevalue
	SetDataFolder $CurrentFolder
end
Function PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string /g imagekeypick = pa.popStr
			svar headerinfo
			string /g imagevalue = stringbykey(popstr,headerinfo)
	endswitch
	SetDataFolder $CurrentFolder
	return 0
End

Function displayfits(row)
	variable row
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	svar ccdpath,loadeddatadir
	wave/t files
	openfits(files[row],ccdpath)
	wave data = $loadeddatadir,i0s,data_mask,data_disp,avg_mask
	if(!waveexists(data_mask)||dimsize(data_mask,1)!=dimsize(data,1)||wavetype(data_mask)!=0x48||mean(data_mask)==255)
		make /o/n=(dimsize(data,0),dimsize(data,1)) data_mask
		redimension /b/u data_mask
		data_mask = ((p+50>dimsize(data_mask,0))&&(q+50>dimsize(data_mask,1))) ? 0 : nan
	endif
	if(!waveexists(avg_mask)||dimsize(avg_mask,1)!=dimsize(data,1)||wavetype(avg_mask)!=0x48)
		make /o/n=(dimsize(data,0),dimsize(data,1)) avg_mask
		redimension /b/u avg_mask
		avg_mask=1
	endif
	nvar normalizedata,indexrow,logimage,normI0
	if(normalizedata)
		imagestats /R=data_mask data
		data-=v_avg
		Print "average background value found to be ="+ num2str(V_avg) + " with std= "+num2str(v_sdev)
	endif
	
	if(normI0)
		data/=I0s[indexrow][row]
		print "I0 = " + num2str(I0s[indexrow][row])
	endif
	//if(logimage)
	//	//data+=1
	//	print "Logging image data"
	//	data_disp = log(data)
	//else
	//	data_disp = data
	//endif
	
	Slider MinG0value1 ,win = DataReduction,limits={max(wavemin(data_disp),0.001*wavemax(data_disp)),wavemax(data_disp),0}
	Slider MinG0value   ,win = DataReduction,limits={max(wavemin(data_disp),0.001*wavemax(data_disp)),wavemax(data_disp),0}
	nvar minslider,maxslider
	if(minslider < wavemin(data_disp) || maxslider<=minslider)
		minslider = wavemin(data_disp)
	endif
	if(maxslider > wavemax(data_disp) || maxslider <= minslider)
		maxslider = wavemax(data_disp)
	endif
//	sumrowsx(data,avg_mask)
//	sumrowsy(data,avg_mask)
	SetDataFolder $CurrentFolder
end
Function displaypng(filelist)
	string filelist
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	svar ccdpath,loadeddatadir
	wave/t files
	openpng(stringfromlist(0,filelist),ccdpath)
	wave data = $loadeddatadir,i0s,data_mask,data_disp
	if(!waveexists(data_mask)||dimsize(data_mask,1)!=dimsize(data,1))
		make /o/n=(dimsize(data,0),dimsize(data,1)) data_mask
		redimension /b/u data_mask
	endif
	nvar normalizedata,indexrow,logimage
	if(normalizedata)
		imagestats /R=data_mask data
		data-=v_avg
		data/=I0s[indexrow][0]
		data+=500
		Print "average background value found to be ="+ num2str(V_avg) + " with std= "+num2str(v_sdev)
		print "I0 = " + num2str(I0s[indexrow][0])
		print "data normalized with these values sucessfully"
		if(logimage)
			data_disp = log(data)
		else
			data_disp = data
		endif
	endif
	sumrowsx(data,avg_mask)
	sumrowsy(data,avg_mask)
	SetDataFolder $CurrentFolder
end
Function ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
//	WAVE/T/Z listWave = lba.listWave
//	WAVE/Z selWave = lba.selWave
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			LoadDatalist(row)
			VARIABLE/G indexrow = row
			setdatafolder currentfolder
			
			//selwave= p==row? 1:0
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
	endswitch
	doupdate
	return 0
End

Window DataReduction() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(130,151,1237,674) as "11.0.1.2 Data Reduction Panel"
	//SetDrawLayer UserBack
	//DrawRect 691,3,1062,441
	//DrawRect 662,10,770,175
	//DrawRect 703,25,851,223
	//DrawRect 851,227,840,203
	//DrawRect 696,10,990,344
	//DrawRect 678,14,1051,433
	//DrawRect 757,76,1013,383
	//DrawRect 797,127,925,277
	//DrawRect 831,172,887,271
	//DrawPoly 1015,154,1,1,{1015,154,1057,147,999,234,967,167,999,218}
	SetDrawEnv fillfgc= (49152,65280,32768),fillbgc= (0,65280,0)
	DrawRect 184,373,619,422
	SetDrawEnv fillfgc= (65280,65280,0)
	DrawRect 113,375,178,422
	TitleBox title0,pos={59,12},size={187,11},fSize=8,frame=0
	TitleBox title0,variable= root:Packages:Nika1101:pathtodata
	Button Browse,pos={6,9},size={50,20},proc=browse,title="Browse"
	ListBox list0,pos={13,42},size={354,329},proc=ListBoxProc,frame=2
	ListBox list0,listWave=root:Packages:Nika1101:scans,mode= 2,selRow= 1
	ListBox list0,editStyle= 1
	ListBox fitslist,pos={369,42},size={238,328},proc=loadimage,frame=2
	ListBox fitslist,listWave=root:Packages:Nika1101:filedisc
	ListBox fitslist,selWave=root:Packages:Nika1101:filesel,mode=10,editStyle= 1
	Button saveibws,pos={3,420},size={101,28},proc=ButtonProc,title="Save Series as\r Igor Binaries"
	Button saveibws,fSize=8
	CheckBox logimage,pos={530,411},size={74,14},disable=1,proc=logimageck,title="Log Image?"
	CheckBox logimage,variable= root:Packages:Nika1101:logimage
	Button button0,pos={2,391},size={105,30},proc=ButtonProc_1,title="Average every N in\r series and save"
	Button button0,fSize=8
	SetVariable setvar0,pos={23,375},size={61,15},title="N = "
	SetVariable setvar0,limits={1,500,1},value= root:Packages:Nika1101:n2save
	Button button1,pos={9,455},size={74,22},proc=LoadMask_button,title="Load Mask"
	Button button2,pos={9,499},size={74,22},proc=DrawMask_button,title="Draw Mask"
	Button button3,pos={9,477},size={74,22},proc=SaveMask_button,title="Save Mask"
	CheckBox logimage1,pos={124,460},size={71,14},proc=ShowMask_ch,title="Show Mask?"
	CheckBox logimage1,variable= root:Packages:Nika1101:showmask
	Button button4,pos={113,434},size={74,22},proc=FinishMask,title="Finish Mask"
	CheckBox logimage2,pos={462,428},size={90,14},disable=1,proc=Checknormalizedata,title="Normalize Data"
	CheckBox logimage2,variable= root:Packages:Nika1101:normalizedata
	Button button5,pos={444,426},size={167,24},proc=ButtonProc_4,title="Plot avg_mask vs motor"
	Button button6,pos={443,456},size={170,21},proc=ButtonProc_3,title="Create Movie from Series"
	CheckBox logimage3,pos={212,460},size={91,14},proc=ShowavgMask_ch,title="Show Avg Mask?"
	CheckBox logimage3,value= 0
	Button button7,pos={189,434},size={95,22},proc=FinishavgMask,title="Finish avg Mask"
	SetVariable setvar2,pos={342,462},size={87,15},title="Start: "
	SetVariable setvar2,limits={0,1000,1},value= root:Packages:Nika1101:plotrunst
	SetVariable setvar3,pos={342,479},size={87,15},title="Step: "
	SetVariable setvar3,limits={1,100,1},value= root:Packages:Nika1101:plotrunsp
	SetVariable setvar4,pos={345,495},size={84,15},title="End: "
	SetVariable setvar4,limits={0,1000,1},value= root:Packages:Nika1101:plotrunend
	Slider MinG0value,pos={103,479},size={212,16},proc=SliderProc
	Slider MinG0value,limits={0,4,0},variable= root:Packages:Nika1101:minslider,vert= 0,ticks= 0
	Slider MinG0value1,pos={103,500},size={212,16},proc=SliderProc
	Slider MinG0value1,limits={0,4,0},variable= root:Packages:Nika1101:maxslider,vert= 0,ticks= 0
	TitleBox title1,pos={378,10},size={29,20},title="bad svar"
	TitleBox title1,variable= root:Packages:Nika1101:imagetime
	PopupMenu Key,pos={448,10},size={100,20},bodyWidth=100,proc=PopMenuProc
	PopupMenu Key,mode=1,popvalue="SIMPLE",value= #"root:Packages:Nika1101:imagekeys"
	TitleBox title2,pos={555,11},size={60,21},labelBack=(65280,43520,32768)
	TitleBox title2,variable= root:Packages:Nika1101:imagevalue,fixedSize=1
	SetVariable filenamebox,pos={297,432},size={130,15},bodyWidth=70
	SetVariable filenamebox,value= root:Packages:Nika1101:filebasename
	CheckBox NormI0data,pos={462,410},size={53,14},disable=1,proc=Checknormalizedata,title="I0 Data"
	CheckBox NormI0data,variable= root:Packages:Nika1101:normI0
	Button saveibws1,pos={191,378},size={84,39},proc=ButtonProc_nikaseries,title="Convert Series\r in Nika"
	Button saveibws2,pos={453,381},size={72,33},proc=ButtonProc_nikamask,title="Open for\r Mask"
	Button saveibws3,pos={526,382},size={89,33},proc=ButtonProc_beamcentering,title="Open for\r beam centering"
	Button saveibws4,pos={373,381},size={78,33},proc=ButtonProc_darkload,title="Load as Dark\r in Nika"
	Button saveibws5,pos={278,378},size={93,40},proc=ButtonProc_nikaseriessel,title="Convert Selection\r in Nika"
	Button button8,pos={117,381},size={56,34},proc=Nika1101BG_button,title="Start Auto\rLoader"
	Button button9,pos={442,482},size={170,21},proc=ButtonProc_6,title="Create Reflectivity Curve"
	Button Update11012panel,pos={318,9},size={50,20},proc=Update11012List,title="Update"
	Display/W=(621,0,1103,518)/FG=(,,FR,FB)/HOST=# 
	AppendImage :Packages:Nika1101:data_mask
	ModifyImage data_mask ctab= {0,10,Grays,0}
	ModifyImage data_mask maxRGB=NaN
	AppendImage :Packages:Nika1101:avg_mask
	ModifyImage avg_mask ctab= {0,10,Grays,0}
	ModifyImage avg_mask maxRGB=NaN
	AppendImage :Packages:Nika1101:data_disp
	ModifyImage data_disp ctab= {*,*,terrain256,0}
	ModifyGraph margin(left)=1,margin(bottom)=1,margin(top)=1,margin(right)=1,frameInset=2,height={Plan,1,left,bottom}
	ModifyGraph mirror=2
	SetAxis/A/R left
	//TextBox/C/N=text0/F=0/S=3/B=3/X=30.94/Y=11.59/E=2 ""
	//TextBox/C/N=text1/F=0/S=3/B=3/X=63.00/Y=63.00/E=2 "Max = 46139"
	RenameWindow #,G0
	SetActiveSubwindow ##
EndMacro
Function Update11012List(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			loadandgeneratestringall("Path_1101panel")
			nvar row  = root:Packages:Nika1101:indexrow
			loaddatalist(row)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function savedatafolder()
	variable row
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	nvar indexrow
	svar loadeddatadir,ccdpath,filebasename
	string nameforoutput,s1,s2
	wave /t filedisc,motors,basenames
	wave /t motor1pos,motor2pos
	wave nmotors
	if(strlen(filebasename)<1)
		splitstring /e="^(.{3,7}).*?(.{4})$" basenames[indexrow],s1,s2
	else
		splitstring /e="^(.{3,7}).*?(.{4})$" basenames[indexrow],s1,s2
		s1 = filebasename
	endif
	for(row=0;row<Dimsize(filedisc,0);row+=1)
		displayfits(row)
		if(nmotors[indexrow]==2)
			nameforoutput = s1+s2+"_"+stringfromlist(row,motor1pos[indexrow])+"_"+stringfromlist(row,motor2pos[indexrow])+".ibw"
		elseif(nmotors[indexrow]==1)
			nameforoutput = s1+s2+"_"+stringfromlist(row,motor1pos[indexrow])+".ibw"
		else
			nameforoutput = s1+s2+".ibw"
		endif
		Save/C/o /p=$ccdpath $loadeddatadir as nameforoutput
	endfor
	SetDataFolder $CurrentFolder
end

Function ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			savedatafolder()
			break
	endswitch

	return 0
End






Function browse(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			svar pathtodata
			string/g pathname
			NewPath/O/m="path for txt files" Path_1101panel			// This will put up a dialog
			if (V_flag != 0)
				break					// User cancelled
			endif
			pathname = "Path_1101panel"
			GetFileFolderInfo /D /Q /P=$pathname
			pathtodata = s_path
			string/g ccdpath
			NewPath/O/m="path for fits files" Path_1101panelccd		// This will put up a dialog
			if (V_flag != 0)
				break					// User cancelled
			endif
			ccdpath = "Path_1101panelccd"
			LoadAndGenerateStringAll(pathName)
			SetDataFolder $CurrentFolder
			break
	endswitch
	return 0
End

Function loadimage(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
//	findvalue /i=1 /s=0 /z selwave
//	row = v_value
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection

			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			displayfits(row)
			svar header = root:Packages:Nika1101:headerinfo
			string /g imagetime
			variable hour,minute,second, month, day
			sscanf stringbykey("DATETIME",header),"%d/%d/%*d %d%*[:]%d%*[:]%d",month, day,hour,minute,second
			if(month==0)
				sscanf stringbykey("DATETIME",header),"%*d-%d-%dT%d%*[:]%d%*[:]%d",month,day,hour,minute,second
				if(month==0)
					sscanf stringbykey("DATE",header),"%*d-%d-%dT%d%*[:]%d%*[:]%d",month,day,hour,minute,second
				endif
			endif
			sprintf imagetime, "%d/%d %d:%02d:%02d", month, day, hour, minute, second
//			setdatafolder root:Packages:Convert2Dto1D
			string/g imagekeys=""
			string s1
			variable i
			for(i=0;i<itemsinlist(header,";");i+=1)
					splitstring /e="^([^:]*):[^:]*$" stringfromlist(i,header,";"),s1
				imagekeys+=s1+";"
			endfor
			svar imagekeypick
			PopupMenu Key,mode=1,popvalue=imagekeypick//,value=imagekeys
			string /g imagevalue = stringbykey(imagekeypick,header)
			SetDataFolder $CurrentFolder
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
	endswitch
	return 0
End

Function logimageck(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			Variable checked = cba.checked
			wave data_disp,data
			if(checked)
				data_disp = log(data)
			else
				data_disp = data
			endif
			SetDataFolder $CurrentFolder
			break
	endswitch

	return 0
End

function averageevery(n)
	variable n
	variable i
	variable row
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	nvar indexrow
	svar loadeddatadir,ccdpath
	make /o /d datasum
	wave datasum
	string nameforoutput,s1,s2
	wave /t filedisc,motors,basenames
	wave/t motor1pos,motor2pos
	splitstring /e="^(.......).*(....)$" basenames[indexrow],s1,s2
	displayfits(0)
	wave data=$loadeddatadir
	duplicate /o data datasum
	for(row=0;row<Dimsize(filedisc,0);)
		datasum=0
		for(i=0;i<3;i+=1)
			displayfits(row)
			datasum += data
			print "adding " +s1+s2+"_"+stringfromlist(row-1,motor1pos[indexrow])+"_"+stringfromlist(row-1,motor2pos[indexrow])+"_"+num2str(row) + " to sum"
			row+=1
		endfor
		nameforoutput = s1+s2+"_"+stringfromlist(row-1,motor1pos[indexrow])+"_"+stringfromlist(row-1,motor2pos[indexrow])+".ibw"
		print "outputting final output named: " + nameforoutput
		Save/C/o /p=$ccdpath datasum as nameforoutput
	endfor
	SetDataFolder $CurrentFolder
end

Function ButtonProc_1(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			nvar n2save
			averageevery(n2save)
			SetDataFolder $currentFolder
			break
	endswitch

	return 0
End
function backgroundsubtract(imwav)
	string imwav
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	wave wave1 = $imwav
	wave eliot_roi_1
	imagestats /R=eliot_roi_1 wave1
	SetDataFolder $CurrentFolder
	return v_avg
end

Function DrawMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			break
	endswitch

	return 0
End

Function LoadMask_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			ImageLoad/T=tiff/O/N=data_mask
			SetDataFolder $CurrentFolder
			break
	endswitch

	return 0
End


Function SaveMask_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			imagesave /T="tiff" /U /i data_mask
			SetDataFolder $CurrentFolder
			break
	endswitch

	return 0
End
//=====================================================
Function ShowMask_ch(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			//Collins altered 3/14/14
			Wave/Z M_ROIMask=root:Packages:Convert2Dto1D:M_ROIMask
//			String CurrentFolder=GetDataFolder(1)
//			SetDataFolder root:Packages:Nika1101
			Variable checked = cba.checked
			if(checked)
				RemoveImage /z /W=DataReduction#G0 M_ROIMask
				APPENDIMAGE/W=DataReduction#G0 M_ROIMask
				ModifyImage/W=DataReduction#G0 M_ROIMask ctab= {0,.9,Grays,0}
				ModifyImage/W=DataReduction#G0 M_ROIMask minRGB=0,maxRGB=NaN
//				RemoveImage /z /W=DataReduction#G0 data_mask
//				APPENDIMAGE/W=DataReduction#G0 data_mask
//				ModifyImage/W=DataReduction#G0 data_mask ctab= {0,10,Grays,0}
//				ModifyImage/W=DataReduction#G0 data_mask minRGB=0,maxRGB=NaN
			else
				RemoveImage /z /W=DataReduction#G0 M_ROIMask
//				RemoveImage /W=DataReduction#G0 data_mask
			endif
//			SetDataFolder $CurrentFolder
			break
	endswitch

	return 0
End
Function ShowavgMask_ch(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			Variable checked = cba.checked
			if(checked)
				RemoveImage /z /W=DataReduction#G0 avg_mask
				APPENDIMAGE/W=DataReduction#G0 avg_mask
				ModifyImage/W=DataReduction#G0 avg_mask ctab= {0,10,Rainbow,0}
				ModifyImage/W=DataReduction#G0 avg_mask minRGB=0,maxRGB=NaN
			else
				RemoveImage /z /W=DataReduction#G0 avg_mask
			endif
			SetDataFolder $CurrentFolder
			break
	endswitch

	return 0
End

Function ButtonProc_2(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			ImageGenerateROIMask /W=datareduction#G0 data_disp
			SetDrawLayer /k /w=datareduction#G0 ProgFront
			duplicate /o m_roimask data_mask
			wave data_mask
			data_mask += -1
			data_mask *= -1
			data_mask = data_mask[p][q]==1 ? nan : data_mask[p][q]
			nvar showmask
			if(showmask)
				RemoveImage /z /W=DataReduction#G0 data_mask
				APPENDIMAGE/W=DataReduction#G0 data_mask
				ModifyImage/W=DataReduction#G0 data_mask ctab= {0,10,Grays,0}
				ModifyImage/W=DataReduction#G0 data_mask minRGB=0,maxRGB=NaN
			else
				RemoveImage /z /W=DataReduction#G0 data_mask
			endif
			SetDataFolder $CurrentFolder
			break
	endswitch

	return 0
End

Function FinishMask_2(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
 			ImageGenerateROIMask /W=datareduction#G0 data_disp
			SetDrawLayer /k /w=datareduction#G0 ProgFront
			duplicate /o m_roimask data_mask
			wave data_mask
			data_mask += -1
			data_mask *= -1
			data_mask = data_mask[p][q]==1 ? nan : data_mask[p][q]
			nvar showmask
			if(showmask)
				RemoveImage /z /W=DataReduction#G0 data_mask
				APPENDIMAGE/W=DataReduction#G0 data_mask
				ModifyImage/W=DataReduction#G0 data_mask ctab= {0,10,Grays,0}
				ModifyImage/W=DataReduction#G0 data_mask minRGB=0,maxRGB=NaN
			else
				RemoveImage /z /W=DataReduction#G0 data_mask
			endif
			SetDataFolder $CurrentFolder
			break
	endswitch

	return 0
End

Function FinishMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			ImageGenerateROIMask /W=datareduction#G0 data_disp
			SetDrawLayer /k /w=datareduction#G0 ProgFront
			duplicate /o m_roimask data_mask
			wave data_mask
			data_mask += -1
			data_mask *= -1
			data_mask = data_mask[p][q]==1 ? nan : data_mask[p][q]
			nvar showmask
			if(showmask)
				RemoveImage /z /W=DataReduction#G0 data_mask
				APPENDIMAGE/W=DataReduction#G0 data_mask
				ModifyImage/W=DataReduction#G0 data_mask ctab= {0,10,Grays,0}
				ModifyImage/W=DataReduction#G0 data_mask minRGB=0,maxRGB=NaN
			else
				RemoveImage /z /W=DataReduction#G0 data_mask
			endif
			SetDataFolder $CurrentFolder
			break
	endswitch

	return 0
End

Function FinishavgMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			ImageGenerateROIMask /W=datareduction#G0 data_disp
			SetDrawLayer /k /w=datareduction#G0 ProgFront
			duplicate /o m_roimask root:Packages:Nika1101:avg_mask
			wave avg_mask
			avg_mask += -1
			avg_mask *= -1
			avg_mask = avg_mask[p][q]==1 ? nan : avg_mask[p][q]
//			nvar showmask
//			if(showmask)
				RemoveImage /z /W=DataReduction#G0 avg_mask
				APPENDIMAGE/W=DataReduction#G0 avg_mask
				ModifyImage/W=DataReduction#G0 avg_mask ctab= {*,*,Grays,0}
				ModifyImage/W=DataReduction#G0 avg_mask minRGB=0,maxRGB=NaN
//			else
//				RemoveImage /z /W=DataReduction#G0 avg_mask
//			endif
			SetDataFolder $CurrentFolder
			break
	endswitch

	return 0
End

Function Checknormalizedata(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
	endswitch

	return 0
End



function makemovie()
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	variable row
	nvar indexrow,plotrunst,plotrunsp,endplotrun,plotrunend
	svar loadeddatadir,pathname
	string nameforoutput,s1="",s2=""
	wave /t filedisc,motors,basenames
	wave /t motor1pos,motor2pos
	wave nmotors
	DoWindow /f datareduction
	SetActiveSubwindow datareduction#G0
	newmovie /I /a

//Start Setup Plot mask 	
	string m1wv,m2wv,avgwv,m1,m2

	avgwv = cutname(basenames[indexrow],0)+ "_mskavg"
	if(nmotors[indexrow]==0)
		make/o /n=(dimsize(filedisc,0)/plotrunsp) /d/o $avgwv
		display $avgwv
	else
		if(nmotors[indexrow]==1)
			m1wv =motors[indexrow]
			make/o /n=(dimsize(filedisc,0)/plotrunsp) /d/o $m1wv,$avgwv
			display $avgwv vs $m1wv
		else
			splitstring /e="^(.*) & (.*)$" motors[indexrow],m1wv,m2wv
			splitstring /e=".*(....)" basenames[indexrow],m1
			m1wv = m1wv+m1+num2str(plotrunst)
			m2wv = m2wv+m1+num2str(plotrunst)
			make/o /n=(abs(plotrunst-plotrunend)/plotrunsp) /d/o $m1wv,$m2wv,$avgwv
			display $avgwv vs $m1wv
		endif
	endif

	wave avgwave = $avgwv
	imagestats /r=avg_mask $loadeddatadir
	avgwave = v_avg
	if(nmotors[indexrow]==0)	
	else
		if(nmotors[indexrow]==1)
			wave m1wave = $m1wv
			m1wave = str2num(stringfromlist(plotrunst+plotrunsp*p,motor1pos[indexrow]))
		else
			wave m1wave = $m1wv,m2wave = $m2wv
			m1wave = str2num(stringfromlist(plotrunst+plotrunsp*p,motor1pos[indexrow]))
			m2wave = str2num(stringfromlist(plotrunst+plotrunsp*p,motor2pos[indexrow]))
		endif
	endif
	
//END setup Plot Mask

	for( row=plotrunst ;row<plotrunend ; row += plotrunsp)
//		displayfits(row)
		wave filesel = root:packages:nika1101:filesel
		filesel = p==row ? 1 : 0
		STRUCT WMListboxAction lba
		lba.eventCode=4
		lba.row = row
		loadimage(lba)
		doupdate
		if(nmotors[indexrow]==0)
			nameforoutput = basenames[indexrow]
		else
			if(nmotors[indexrow]==1)
				sprintf nameforoutput, "%s = %.2f",s1,str2num(stringfromlist(row,motor1pos[indexrow]))
				nameforoutput =motors[indexrow]+"="+ stringfromlist(row,motor1pos[indexrow])
			else
				splitstring /e="^(.*) & (.*)$" motors[indexrow],s1,s2
				sprintf nameforoutput, "%s = %.2f  -  %s = %.2f",s1,str2num(stringfromlist(row,motor1pos[indexrow])),s2,str2num(stringfromlist(row,motor2pos[indexrow]))
			endif
		endif
//		NVAR minslider=root:Packages:Nika1101:minslider, maxslider=root:Packages:Nika1101:maxslider
//		ModifyImage /W=datareduction#G0 data_disp ctab= {minslider,maxslider,terrain256,0}
		print "adding movie frame with title = " + nameforoutput
		TextBox  /W=datareduction#G0 /C/N=text0/F=0/S=3/B=3/E=2 /X=30.94/Y=11.59  nameforoutput
		SetAxis /W=datareduction#G0 /A /R left
//		ColorScale/W=datareduction#G0 /C/N=text2/F=0/S=3/A=MC/B=1/X=53/Y=14 image=data_disp,fsize=10
		DoWindow /f datareduction
		SetActiveSubwindow datareduction#G0
		//doupdate
		addmovieframe
		imagestats /r=avg_mask $loadeddatadir //get statistics on the masked data
		avgwave[(row-plotrunst)/plotrunsp] = v_avg //set the result wave at this location to the average value
	endfor
	print "Closing movie file" 
	closemovie
	SetDataFolder $CurrentFolder
end


function /S cutname(inputname,cutend)
	string inputname
	variable cutend
	string basenamecut,midnamecut,endname
	if(cutend)
		Splitstring /E="^(......).*(....)-(...).....$" inputname,basenamecut,midnamecut,endname
		return basenamecut+"_"+midnamecut+endname
	else
		Splitstring /E="^(.{3,7}).*?(....)$" inputname,basenamecut,midnamecut
		return basenamecut+"_"+midnamecut
	endif
end


function plotmask()
	variable row
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	nvar indexrow,plotrunst,plotrunsp,plotrunend
	svar loadeddatadir,pathname
	wave /t filedisc,motors,basenames
	string m1wv,m2wv,avgwv,m1,m2
	wave/t motor1pos,motor2pos
	wave nmotors

	avgwv = cutname(basenames[indexrow],0)+ "_mskavg"
	if(nmotors[indexrow]==0)
		make/o /n=(dimsize(filedisc,0)/plotrunsp) /d/o $avgwv
		display $avgwv
	else
		if(nmotors[indexrow]==1)
			m1wv =motors[indexrow]
			make/o /n=(dimsize(filedisc,0)/plotrunsp) /d/o $m1wv,$avgwv
			display $avgwv vs $m1wv
		else
			splitstring /e="^(.*) & (.*)$" motors[indexrow],m1wv,m2wv
			splitstring /e=".*(....)" basenames[indexrow],m1
			m1wv = m1wv+m1+num2str(plotrunst)
			m2wv = m2wv+m1+num2str(plotrunst)
			make/o /n=(abs(plotrunst-plotrunend)/plotrunsp) /d/o $m1wv,$m2wv,$avgwv

			display $avgwv vs $m1wv
		endif
	endif
	wave avgwave = $avgwv
	imagestats /r=avg_mask $loadeddatadir
	avgwave = v_avg
	if(nmotors[indexrow]==0)	
	else
		if(nmotors[indexrow]==1)
			wave m1wave = $m1wv
			m1wave = str2num(stringfromlist(plotrunst+plotrunsp*p,motor1pos[indexrow]))
		else
			wave m1wave = $m1wv,m2wave = $m2wv
			m1wave = str2num(stringfromlist(plotrunst+plotrunsp*p,motor1pos[indexrow]))
			m2wave = str2num(stringfromlist(plotrunst+plotrunsp*p,motor2pos[indexrow]))
		endif
	endif
	for(row=plotrunst;row<plotrunend;row+=plotrunsp)
		displayfits(row)
		imagestats /r=avg_mask $loadeddatadir
		avgwave[(row-plotrunst)/plotrunsp] = v_avg
		doupdate
	endfor
	SetDataFolder $CurrentFolder
end

function PlotRefl()
	variable row
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	nvar indexrow,plotrunst,plotrunsp,plotrunend
	svar loadeddatadir,pathname
	wave /t filedisc,motors,basenames
	string m1wv,m2wv,avgwv,m1,m2
	wave/t motor1pos,motor2pos
	wave nmotors

	avgwv = cutname(basenames[indexrow],0)+ "_mskavg"
	if(nmotors[indexrow]==0)
		make/o /n=(dimsize(filedisc,0)/plotrunsp) /d/o $avgwv
		display/k=1 $avgwv
		ModifyGraph log(left)=1
	else
		if(nmotors[indexrow]==1)
			m1wv =motors[indexrow]
			make/o /n=(dimsize(filedisc,0)/plotrunsp) /d/o $m1wv,$avgwv
			display/k=1 $avgwv vs $m1wv
			ModifyGraph log(left)=1
		else
			splitstring /e="^([^,]*),([^,]*)" motors[indexrow],m1wv,m2wv
			splitstring /e=".*(....)" basenames[indexrow],m1
			m1wv = m1wv+m1+num2str(plotrunst)
			m2wv = m2wv+m1+num2str(plotrunst)
			make/o /n=(abs(plotrunst-plotrunend)/plotrunsp) /d/o $m1wv,$m2wv,$avgwv
			display/k=1 $avgwv vs $m1wv
			ModifyGraph log(left)=1
		endif
	endif
	wave avgwave = $avgwv
	imagestats /r=avg_mask $loadeddatadir
	avgwave = v_avg
	if(nmotors[indexrow]==0)	
	else
		if(nmotors[indexrow]==1)
			wave m1wave = $m1wv
			m1wave = str2num(stringfromlist(plotrunst+plotrunsp*p,motor1pos[indexrow]))
		else
			wave m1wave = $m1wv,m2wave = $m2wv
			m1wave = str2num(stringfromlist(plotrunst+plotrunsp*p,motor1pos[indexrow]))
			m2wave = str2num(stringfromlist(plotrunst+plotrunsp*p,motor2pos[indexrow]))
		endif
	endif
	for(row=plotrunst;row<plotrunend;row+=plotrunsp)
		displayfits(row)
		wave data = $loadeddatadir
		avgwave[(row-plotrunst)/plotrunsp]  = fitgaussbeam(data)
		doupdate
	endfor
	SetDataFolder $CurrentFolder
end

Function ButtonProc_3(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			makemovie()
			break
	endswitch

	return 0
End

Function ButtonProc_4(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			plotmask()
			break
	endswitch

	return 0
End
function sumrowsx(wavein,avg_mask)
	wave wavein
	wave avg_mask
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	wave data_mask = root:Packages:Nika1101:data_mask
	make /d /o /n=(dimsize(wavein,0)) datay_temp
	make /d /o /n=(dimsize(wavein,1)) datax_temp,datax
	variable i,j=0
	for(i=0;i<dimsize(wavein,1);i+=1)
		datay_temp = avg_mask[i][p] ? 0 : wavein[i][p]*data_mask[i][p]/255
		datax_temp[i] = mean(datay_temp)
	endfor
	datax= datax_temp[p]==0 ? NAN : datax_temp[p]
	killwaves datax_temp,datay_temp
	SetDataFolder $CurrentFolder
end
	`
function sumrowsy(wavein,avgmask)
	wave wavein,avgmask
	wave data_mask = root:Packages:Nika1101:data_mask
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Nika1101
	imagestats /R=avgmask wavein
	variable vmean = v_avg
	make /d /o /n=(dimsize(wavein,0)) datay_temp,datay
	make /d /o /n=(dimsize(wavein,1)) datax_temp
	variable i,j=0
	for(i=0;i<dimsize(wavein,1);i+=1)
		datax_temp = avgmask[p][i] ? 0 : wavein[p][i]*data_mask[i][p]/255
		datay_temp[i] = mean(datax_temp)
//		if(datay_temp[i])
//			datay[j]=datay_temp[i]
//			j+=1
//		endif
	endfor
	datay= datay_temp[p]==0 ? NAN : datay_temp[p]
//	killwaves datax_temp,datay_temp
////	redimension /n=(j) datay
//	Display datay
//	SetAxis/A
//	fft /dest=ffty /mag /pad={(2*ceil(dimsize(datay,0)/2))} datay
//	appendtograph ffty
	SetDataFolder $CurrentFolder
end

Function SliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // kill
			break
		default:
			if( sa.eventCode & 1 ) // value set
				String CurrentFolder=GetDataFolder(1)
				SetDataFolder root:Packages:Nika1101
				nvar minslider,maxslider
				ModifyImage /W=datareduction#G0 data_disp ctab= {minslider,maxslider,terrain,0}
				SetDataFolder $CurrentFolder
			endif
			break
	endswitch

	return 0
End


Function DrawMask_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			String CurrentFolder=GetDataFolder(1)
			SetDataFolder root:Packages:Nika1101
			SetActiveSubwindow datareduction#G0
			SetDrawLayer /W=datareduction#G0 ProgFront
			setdrawenv /W=datareduction#G0 xcoord=bottom,ycoord=left
			ShowTools/A poly
			SetDataFolder $CurrentFolder
			break
	endswitch

	return 0
End

Function ButtonProc_beamcentering(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up			
			wave filesel = root:Packages:Nika1101:filesel
			string filelist = getfilename(selwave=filesel)
			loadforbeamcenteringinNIKA(stringfromlist(0,filelist))
			break
	endswitch
	return 0
End
Function ButtonProc_darkload(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			wave filesel = root:Packages:Nika1101:filesel
			string filelist = getfilename(selwave=filesel)
			loadasdarkinNIKA(filelist)
			break
	endswitch
	return 0
End
Function ButtonProc_nikamask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			wave filesel = root:Packages:Nika1101:filesel
			string filelist = getfilename(selwave=filesel)
			loadformaskinnika(stringfromlist(0,filelist))
			break
	endswitch

	return 0
End

Function ButtonProc_nikaseries(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			wave filesel = root:Packages:Nika1101:filesel
			filesel = 0
			wave darks = getdarks(filesel)
			string filelist = getfilename(list=1)
			convertnikafilelistsmart(filelist,darks)
			break
	endswitch

	return 0
End
Function ButtonProc_nikaseriessel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			wave filesel = root:Packages:Nika1101:filesel
			string filelist = getfilename(selwave=filesel)
			wave darks = getdarks(filesel)
			convertnikafilelistsmart(filelist,darks)
			break
	endswitch

	return 0
End

Function ButtonProc_6(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			PlotRefl()
		case -1: // control being killed
			break
	endswitch

	return 0
End

function convertpathtonika([main,mask,dark,beamcenter])
	variable mask,dark,beamcenter,main
	PathInfo Path_1101panelccd
	EGN_FitsLoaderPanelFnct()
	doupdate
	if(main)
		EGNA_Convert2Dto1DMainPanel()
		svar SampleNameMatchStr = root:Packages:Convert2Dto1D:SampleNameMatchStr
		SampleNameMatchStr = ""
		popupmenu Select2DDataType win=EGNA_Convert2Dto1DPanel, popmatch="*fits"
		newpath /O/Q/Z Convert2Dto1DDataPath S_path
		SVAR MainPathInfoStr=root:Packages:Convert2Dto1D:MainPathInfoStr
		MainPathInfoStr=S_path
		TitleBox PathInfoStrt, win =EGNA_Convert2Dto1DPanel, variable=MainPathInfoStr
		EGNA_UpdateDataListBox()	
	endif
	if(mask)
		EGNM_CreateMask()
		newpath /O/Q/Z Convert2Dto1DMaskPath S_path
		popupmenu CCDFileExtension win=EGNM_ImageROIPanel, popmatch="*fits"
		SVAR CCDFileExtension=root:Packages:Convert2Dto1D:CCDFileExtension
		CCDFileExtension = ".fits"
		EGNM_UpdateMaskListBox()
	endif
	if(dark)
		EGNA_Convert2Dto1DMainPanel()
		newpath /O/Q/Z Convert2Dto1DEmptyDarkPath S_path
		popupmenu SelectBlank2DDataType win=EGNA_Convert2Dto1DPanel, popmatch="*fits"
		nVAR usedarkfield=root:Packages:Convert2Dto1D:UseDarkField
		usedarkfield=1
		SVAR BlankFileExtension=root:Packages:Convert2Dto1D:BlankFileExtension
		BlankFileExtension = ".fits"
		SVAR DataFileExtension=root:Packages:Convert2Dto1D:DataFileExtension
		DataFileExtension = ".fits"
		svar EmptyDarkNameMatchStr = root:Packages:Convert2Dto1D:EmptyDarkNameMatchStr
		EmptyDarkNameMatchStr = ""
		EGNA_UpdateEmptyDarkListBox()	
	endif
	if(beamcenter)
		EGN_CreateBmCntrFile()
		newpath /O/Q/Z Convert2Dto1DBmCntrPath S_path
		popupmenu BmCntrFileType win=EGN_CreateBmCntrFieldPanel, popmatch="*fits"
		SVAR BmCntrFileType=root:Packages:Convert2Dto1D:BmCntrFileType
		BmCntrFileType = ".fits"
		SVAR BCPathInfoStr=root:Packages:Convert2Dto1D:BCPathInfoStr
		BCPathInfoStr=S_Path
		EGNBC_UpdateBmCntrListBox()
	endif
end

function convertnikafilelist(filenamelist)
	string filenamelist
	convertpathtonika(main=1)
	doupdate
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

function convertnikafilelistsmart(filenamelist,dark)
	string filenamelist
	wave dark
	convertpathtonika(main=1)
	doupdate
	Wave/T  ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
	Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
	
	convertpathtonika(dark=1)
	doupdate
	Wave/T  ListOfdarkfilenames=root:Packages:Convert2Dto1D:ListOf2DEmptyData
			
	
	ListOf2DSampleDataNumbers = 0
	string filename = stringfromlist(0,filenamelist)
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
	variable i
	for(i=0;i<itemsinlist(filenamelist);i+=1)
		filename = stringfromlist(i,filenamelist)
		if(dark[i])
			FindValue /TEXT=filename /TXOP=6 /Z ListOfdarkfilenames
			if(v_value>=0)
				listbox Select2DMaskDarkWave win=EGNA_Convert2Dto1DPanel, selrow=v_value 
				doupdate
				EGNA_LoadEmptyOrDark("Dark")
			endif
		else
			FindValue /TEXT=filename /TXOP=6 /Z ListOf2DSampleData
			if(v_value>=0)
				ListOf2DSampleDataNumbers = p==v_value ? 1 : 0
				doupdate
				EGNA_LoadManyDataSetsForConv()
			endif
		endif
	endfor
	
	
	//selection done
	
end

function convertnikafilelistsel(filenamelist)
	string filenamelist
	convertpathtonika(main=1)
	doupdate
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
function loadasdarkinnika(filenamelist)
//dark image load						EGNA_LoadEmptyOrDark("Dark")
//	Wave/T ListOf2DEmptyData=root:Packages:Convert2Dto1D:ListOf2DEmptyData
//	string SelectedFileToLoad
//	controlInfo /W=EGNA_Convert2Dto1DPanel Select2DMaskDarkWave
//	variable selection = V_Value
//	if(selection<0)
//		setDataFolder OldDf
//		abort
//	endif
	string filenamelist
	string filename
	convertpathtonika(dark=1)
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
function loadformaskinnika(filename)
//mask load image for making mask		EGNM_MaskCreateImage() 
//
//	Wave/T  ListOfCCDDataInCCDPath=root:Packages:Convert2Dto1D:ListOfCCDDataInCCDPath
//	controlInfo /W=EGNM_ImageROIPanel CCDDataSelection
	string filename
	convertpathtonika(mask=1)
	doupdate
	Wave/T  ListOffilenames=root:Packages:Convert2Dto1D:ListOfCCDDataInCCDPath
	variable i
	FindValue /TEXT=filename /TXOP=6 /Z ListOffilenames
	if(v_value>=0)
		listbox CCDDataSelection win=EGNM_ImageROIPanel, selrow=v_value 
		doupdate
		EGNM_MaskCreateImage() 
	endif
end
function loadforbeamcenteringinNIKA(filename)
//beam center load					
//	setDataFOlder root:Packages:Convert2Dto1D
//	Wave/T  ListOfCCDDataInBmCntrPath=root:Packages:Convert2Dto1D:ListOfCCDDataInBmCntrPath
//	controlInfo /W=EGN_CreateBmCntrFieldPanel CCDDataSelection
//	variable selection = V_Value
//	if(selection<0)
//		setDataFolder OldDf
//		abort
//	endif
//	DoWindow CCDImageForBmCntr
//	if(V_Flag)
//		DoWindow/K CCDImageForBmCntr
//	endif
	string filename
	convertpathtonika(beamcenter=1)
	doupdate
	Wave/T  ListOffilenames=root:Packages:Convert2Dto1D:ListOfCCDDataInBmCntrPath
	FindValue /TEXT=filename /TXOP=6 /Z ListOffilenames
	if(v_value>=0)
		listbox CCDDataSelection win=EGN_CreateBmCntrFieldPanel, selrow=v_value 
		doupdate
		EGNBC_BmCntrCreateImage()
		//set slider
		NVAR BMMaxCircleRadius=root:Packages:Convert2Dto1D:BMMaxCircleRadius
		Wave BmCntrFieldImg=root:Packages:Convert2Dto1D:BmCntrCCDImg 
		BMMaxCircleRadius=sqrt(DimSize(BmCntrFieldImg, 0 )^2 + DimSize(BmCntrFieldImg, 1 )^2)
		Slider BMHelpCircleRadius,limits={1,BMMaxCircleRadius,0}, win=EGN_CreateBmCntrFieldPanel
		SetVariable BMHelpCircleRadiusV,limits={1,BMMaxCircleRadius,0}, win=EGN_CreateBmCntrFieldPanel
		NVAR BMImageRangeMinLimit= root:Packages:Convert2Dto1D:BMImageRangeMinLimit
		NVAR BMImageRangeMaxLimit = root:Packages:Convert2Dto1D:BMImageRangeMaxLimit
		Slider ImageRangeMin,limits={BMImageRangeMinLimit,BMImageRangeMaxLimit,0}, win=EGN_CreateBmCntrFieldPanel
		Slider ImageRangeMax,limits={BMImageRangeMinLimit,BMImageRangeMaxLimit,0}, win=EGN_CreateBmCntrFieldPanel
		EGNBC_DisplayHelpCircle()
		EGNBC_DisplayMask()
		TabControl BmCntrTab, value=0, win=EGN_CreateBmCntrFieldPanel
		showinfo /w=CCDImageForBmCntr
	endif
end

function /t getfilename([list,selwave])
	variable list
	wave selwave
	wave/t files = root:Packages:Nika1101:files
	if(waveexists(selwave))
		string filelistsel=""
		variable i
		for(i=0;i<numpnts(files);i+=1)
			if(selwave[i])
				filelistsel = AddListItem(files[i], filelistsel,";",inf)
			endif
		endfor
		return sortlist(filelistsel)
	elseif(paramisdefault(list)||list==0)
		controlInfo /W=DataReduction fitslist
		variable row = V_Value
		return files[row]
	else
		string filelist=""
		variable j
		for(j=0;j<numpnts(files);j+=1)
			filelist = AddListItem(files[j], filelist,";",inf)
		endfor
		return sortlist(filelist)
	endif
end

function /wave getdarks(selwave)
	wave selwave
	
	
	wave/t filedisc = root:Packages:Nika1101:filedisc
	if(sum(selwave)>0)
		duplicate /free selwave, tempsel 
		tempsel = selwave[p]>0 ? 1 :0
		make /n=(sum(tempsel)) /O DARKSEL
		variable i,selnum=0
		
		for(i=0;i<numpnts(filedisc);i+=1)
			if(tempsel[i])
				darksel[selnum]=stringmatch(filedisc[i],"D*")
				selnum+=1
			endif
		endfor
		return darksel
	else
		make /n=(numpnts(filedisc)) /O DARKSEL
		variable j
		for(j=0;j<numpnts(filedisc);j+=1)
			darksel[j] = stringmatch(filedisc[j],"D*")
		endfor
		return darksel
	endif
end

function /d fitGaussBeam(wavein)
	wave wavein

	duplicate/o/r=[0,][4,] wavein, wavefit
	//smooth 5 , wavein
	matrixfilter /n=5 Gauss wavefit
	CurveFit /q/n/w=2 Gauss2D wavefit /D
	
	wave W_coef, W_sigma
	
	//ignore area under baseline...else infinite?
	variable integral = W_coef[1]*2*pi* abs(W_coef[3])* abs(W_coef[5])*sqrt(1- W_coef[6]^2)
	
	//check sigma
	variable i
	for(i=0;i<7;i+=2)
		if(W_sigma[i]>=0.5*(V_endRow-V_startRow))
			print "Sigma too large; check fit"
			integral = 0
		endif
	endfor
	
	print "Area under curves", integral 
	
	return integral
end


Function/T ShortenMotor(mName)
	string mName
	If( stringmatch(mName,"Beamline Energy Goal") )
		return "enG"
	elseif( stringmatch(mName,"EPU Polarization") )
		return "pol"
	elseif( stringmatch(mName,"Beamline Energy") )
		return "En"
	elseif( stringmatch(mName,"CCD Shutter Inhibit") )
		return "Shutter"
	elseif( stringmatch(mName,"Sample X") )
		return "X"
	elseif( stringmatch(mName,"Sample Y") )
		return "Y"
	elseif( stringmatch(mName,"Sample Z") )
		return "Z"
	elseif( stringmatch(mName,"Sample Theta") )
		return "Th"
	elseif( stringmatch(mName,"Sample Number") )
		return "#"
	elseif( stringmatch(mName,"CCD Y") )
		return "DY"
	elseif( stringmatch(mName,"CCD X") )
		return "DX"
	elseif( stringmatch(mName,"CCD Theta") )
		return "DTh"
	elseif( stringmatch(mName,"Higher Order Suppressor") )
		return "OS"
	else
		return mName
	endif
end

Function/T Lmotor(mName)
	string mName
	If( stringmatch(mName,"enG") )
		return "Beamline Energy Goal"
	elseif( stringmatch(mName,"pol") )
		return "EPU Polarization"
	elseif( stringmatch(mName,"En") )
		return "Beamline Energy"
	elseif( stringmatch(mName,"Shutter") )
		return "CCD Shutter Inhibit"
	elseif( stringmatch(mName,"#") )
		return "Sample Number"
	elseif( stringmatch(mName,"X") )
		return "Sample X"
	elseif( stringmatch(mName,"Y") )
		return "Sample Y"
	elseif( stringmatch(mName,"Z") )
		return "Sample Z"
	elseif( stringmatch(mName,"Th") )
		return "Sample Theta"
	elseif( stringmatch(mName,"DX") )
		return "CCD X"
	elseif( stringmatch(mName,"DY") )
		return "CCD Y"
	elseif( stringmatch(mName,"DTh") )
		return "CCD Theta"
	elseif( stringmatch(mName,"OS") )
		return "Higher Order Suppressor"
	else
		return mName
	endif
end