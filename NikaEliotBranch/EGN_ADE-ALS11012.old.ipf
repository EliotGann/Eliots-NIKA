#pragma rtGlobals=1		// Use modern global access method.
//  Functions to addon to NIKA and deal with various corrections at ALS Beamline 11.0.1.2
//  Developed by the Ade Group  (Eliot Gann ehgann@ncsu.edu  and Brian Collins b.collins@ncsu.edu)
//  Comtinued development by Eliot Gann at monash university (eliot.gann@monash.edu)
#pragma version=2.2
#include <Remove Points>
#include "GIWAXS multipeakfitting and WAv2"
#include "ccdplotting"
#include "NI1_Loader"
#include "GIWAXSLatticeCalcs"
//#include "GIWAXSbkgRemoval-v4"

Function /s loadfitsfilenika(filename,path,refnum,NewWaveName)
	string filename,path,newwavename
	variable refnum
	string lineread,header,key,value,comment
	string wnote

	variable i0last
	variable Izerolast
	
	variable testline=0
	variable findextension=0
	variable lastextfpos=0
	variable imageextfpos=0
	variable imagefpos=0
	variable fpos=0
	string extension
	string/g root:packages:nika1101:name1,root:packages:nika1101:name2,root:packages:nika1101:sernum,root:packages:nika1101:imnum
	svar name1 = root:packages:nika1101:name1 ,  name2 = root:packages:nika1101:name2, sernum= root:packages:nika1101:sernum, imnum= root:packages:nika1101:imnum
	svar regexpg= root:packages:nika1101:loaderregexp
	svar namecreationg = root:packages:nika1101:namecreation
	string regexp = regexpg
	string namecreation = namecreationg
	if(strlen(regexp)<1 || strlen(namecreation)<1)
		defaultfitsexps()
	endif
	variable failed=0
	
	nvar fuckedi0s = root:packages:nika1101:fuckedI0s
	if(fuckedI0s)
		// try to find last file
		splitstring /e=regexp filename,name1,name2,sernum,imnum
		variable imagenumber = str2num(imnum)
		if(strlen(imnum)==0 || (imagenumber*0 != 0) || (imagenumber==1) )
			failed = 1
		else
			string oldimstr
			string newimstr
			sprintf oldimstr "%03d.fits", imagenumber
			sprintf newimstr "%03d.fits", imagenumber-1
			
			string newfilename = replacestring(oldimstr, filename, newimstr)
			open/Z /R /T="BINA" /p=$path refnum as newfilename
			Fstatus refnum
			if(refnum==0)
				failed=1
			endif
		endif
		if(failed==0)
			print "Reading Header from : ",S_filename
			header = ""
			for(lineread = "";!stringmatch(lineread,"END*");)
				FReadline /N=80 refnum,lineread
				splitstring /e="^(\\s*?HIERARCH\\s*?)?(.*?)\\s*=\\s*'?([^'\r\n]{1,})'?\\s*/\\s*([^'\r\n]*)\\s*$" lineread,key,key,value,comment
				if(cmpstr(key,""))
					key = ReplaceString(" ",key,"")
					header+=key +":"+ value+";"
				endif
			endfor
			testline=0
			findextension=0
			lastextfpos=0
			imageextfpos=0
			imagefpos=0
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
				fpos=V_filePos //remember this place in the file in case there are no more xtensions
				//Look for xtension if there is any
				for(testline=0;testline<100;testline+=1)
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
						findextension =1
						break
					else
						findextension=0
					endif
				endfor
				if(findextension)
					extension = ReplaceString(" ",value,"") //set the extension to the value of the previous read, which should be the xtension=line
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
			
			i0last =str2num(stringbykey("IZERO",header))
			Izerolast = str2num(stringbykey("AI3Izero",header)) // changed from AI3Izero
			Print "Loaded old I0 value from "+newfilename+" to correct i0 successfully!"
		else
			i0last = 0
			Izerolast = 0
			Print "WARNING: Failed to old I0 value from previous value successfully!"
		endif
	else
	//	Print "WARNING: Did not load previous i0"
		i0last = 0
		Izerolast = 0
	endif // fixing fucked up analog inputs
	Close /A
	
	GetFileFolderInfo /P=$path /q /Z filename
	variable filecdate = V_creationDate
	chkwaitfile(filename,50*2880,path)
	open/Z /R /T="BINA" /p=$path refnum as filename
	Fstatus refnum
	if(refnum==0)
		print "File was not opened"
		return "File was not loaded;"
	endif
	print "FITS Load From",S_filename
	header = ""
	for(lineread = "";!stringmatch(lineread,"END*");)
		FReadline /N=80 refnum,lineread
		splitstring /e="^(\\s*?HIERARCH\\s*?)?(.*?)\\s*=\\s*'?([^'\r\n]{1,})'?\\s*/\\s*([^'\r\n]*)\\s*$" lineread,key,key,value,comment
		if(cmpstr(key,""))
			key = ReplaceString(" ",key,"")
			header+=key +":"+ value+";"
		endif
	endfor
	testline=0
	findextension=0
	lastextfpos=0
	imageextfpos=0
	imagefpos=0
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
		fpos=V_filePos //remember this place in the file in case there are no more xtensions
		//Look for xtension if there is any
		for(testline=0;testline<100;testline+=1)
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
			extension = ReplaceString(" ",value,"") //set the extension to the value of the previous read, which should be the xtension=line
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
	variable i0 =str2num(stringbykey("IZERO",header)) - i0last
	variable Izero = str2num(stringbykey("AI3Izero",header))-Izerolast // changed from AI3 Izero
	variable beamstopnA = str2num(stringbykey("Ai6beamstop",header))
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
		return "Fits file does not meet requirements of having dimensions of image, please load a different file;"
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
		return "cannot get dimensions from the file header;"
	endif
	//Set appropriate NIKA polarization
	NVAR StartAngle2DPolCor =root:Packages:Convert2Dto1D:StartAngle2DPolCor
	NVAR Use1DPolarizationCor =root:Packages:Convert2Dto1D:Use1DPolarizationCor
	NVAR Use2DPolarizationCor =root:Packages:Convert2Dto1D:Use2DPolarizationCor
	If( pol>99 )
		StartAngle2DPolCor=pol-100
	endif
	Use1DPolarizationCor=0
	Use2DPolarizationCor=1
	//Write header to a few locations so it is available
	string /g root:packages:nika1101:headerinfo = header
	string /g root:headerinfo = header
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
			return "file could not be opened even to check the size;"
		case -1:
			print "timed out waiting for file to be written"
			String/G root:Packages:Nika1101:bkg:message="timed out waiting for file to be written"
			return "timed out waiting for file to be written;"
	endswitch
	//Create Wave at NIKA's perfered location
	make/o /d /n=(xdim,ydim) $NewWaveName
	wave data=$("root:Packages:Convert2Dto1D:" + NewWaveName)
	//Load Data into this new wave
//	 check if we have already read data for this filename, if so, let's just load that data
//	string /g listofLoadedFitsFiles
//	Fstatus refnum
//	variable loadedfitsnum = numberbykey(s_path+s_filename,listofLoadedFitsFiles,"=")
//	if(loadedfitsnum>=0)
//		duplicate/o $("SavedFitsData"+num2str(loadedfitsnum)) , data
//		print "Used previously loaded data #"+num2str(loadedfitsnum)
//	else
		FBinRead /B=2 /F=2 refNum, data
		imagetransform flipcols data
//		if(itemsinlist(listofLoadedFitsFiles)>40)
//			string oldlistitem = stringfromlist(0,listofloadedfitsfiles)
//			string olditemnumber
//			splitstring /e="[^=]*=([^=]*)" oldlistitem, olditemnumber
//			listofloadedfitsfiles = removelistitem(0,listofloadedfitsfiles)
//			duplicate/o data, $("SavedFitsData"+olditemnumber)
//			listofloadedfitsfiles = listofloadedFitsFiles +s_path+s_filename+"="+olditemnumber+";"
//		else
//			string newlistitem = UniqueName("SavedFitsData", 1, 0 )
//			string newitemnumber
//			splitstring /e="SavedFitsData(.*)" newlistitem, newitemnumber
//			duplicate/o data, $("SavedFitsData"+newitemnumber)
//			listofloadedfitsfiles = listofloadedFitsFiles +s_path+s_filename+"="+newitemnumber + ";"
//		endif
//	endif
	//Close the file
	close refnum
//Update the loader panel, incase the available header items have changed
	updatefitsloaderpaneloptions()
//Change directory to Nika1101 for the rest of manipulation
	setdatafolder root:packages:nika1101
//Correct DATA as needed
	//Correct data from BZERO (an offset because Fits files are only Signed, where as the data is unsigned)
	data+=bzero
	//Flatten or at least subtract the background offset from the image
	nvar chkflatten,flatten_line,flatten_width
	if(chkflatten)
		//gatherstatsandflatten(data,flatten_line,flatten_width)
		flattenimage(data,flatten_line,flatten_width)
		data+=0//set arbitrarily
	//else
	//	if(!waveexists(data_mask)||dimsize(data_mask,1)!=dimsize(data,1)||wavetype(data_mask)!=0x48)
	//		make /o/n=(dimsize(data,0),dimsize(data,1)) data_mask
	//		redimension /b/u data_mask
	//		data_mask = ((p+50>dimsize(data_mask,0))&&(q+50>dimsize(data_mask,1))) ? 0 : nan
	//	endif
	//	imagestats /R=data_mask data
	//	data-=v_avg-100
	endif
	//Calculate the corrected I0 if necessary (number of incident photons incident)
	nvar AI3izero
	if(AI3izero)
		i0 = correcti0(izero,en,pol,os) // should return photons that this izero corresponds to
//.		print "Using Photodiode Beamstop value for I0 correction.  Value = " + num2str(i0)
	else
		i0 = correcti0(i0,en,pol,os)
	endif
	//Divide the image by the exposure time if requested
	nvar Exposecorr
	if(exposecorr)
		data /= Expose
		//print "Data corrected for " + num2str(Expose) + " second exposure"
	endif	
	//Correct Image to Number of photons rather than ADUs
	nvar correctionfactor = root:Packages:Convert2Dto1D:correctionfactor
	correctionfactor = 1/(str2num(energy1) / 10.0)
	print "Sample correction factor set to " + num2str(str2num(energy1) / 10.0) + " ADUs / Photon"
//Set variables for Nika to use if it needs them
	//Calculate and set new beamcenter from CCDx and CCDTheta if needed
	nvar AdjBeam
	if(AdjBeam)
		correctbeamcenter()
	endif

	//Set Pixel size in case it is incorrect  (assume it is binning, not ROI)
	nvar pxsizex = root:Packages:Convert2Dto1D:PixelSizeX
	nvar pxsizey = root:Packages:Convert2Dto1D:PixelSizeY
	pxsizex = .0135*2048/xdim
	pxsizey = .0135*2048/ydim
	//set the expose and IO (we have already used/adjusted these values - now we give them to nika)
	nvar SampleI0=root:Packages:Convert2Dto1D:samplei0,SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
	nvar xrayenergy = root:Packages:Convert2Dto1D:XrayEnergy, wavelength = root:Packages:Convert2Dto1D:Wavelength
	samplei0= i0
	samplemeasurementtime = expose
	// Add in the correction for absorption
	nvar Sampletransmission = root:Packages:Convert2Dto1D:SampleTransmission
	sampletransmission = BSnA2Photons(beamstopnA)/i0
	
	// find the zero offset if there is the option, and there exists a avg_mask ... created in the 11.0.1.2 loader panel
	nvar UseSubtractFixedOffset =  root:Packages:Convert2Dto1D:UseSubtractFixedOffset
	nvar SubtractFixedOffset =  root:Packages:Convert2Dto1D:SubtractFixedOffset
	wave/z avg_mask = root:Packages:Nika1101:avg_mask
	if(usesubtractfixedoffset&&waveexists(avg_mask))
		imagestats /r=avg_mask data
		data -= v_avg
		SubtractFixedOffset = 0
	endif
	
	//set wavelength and energy
	if(strlen(energy1)>2)
		xrayenergy = round(10*str2num(energy1))/10000
		wavelength = 12.398424437/xrayenergy
	endif
	
	Variable/G root:Packages:Convert2Dto1D:DoSolidAngleMap=1
	
//find name based on header and inputs
	//Create a Global variable so we can change it with an Excute Command later
	string/g dataname=filename
	nvar fitskeypick1,fitskeypick2,fitskeypick3,fitskeypick4,usefitskey1,usefitskey2,usefitskey3,usefitskey4,dispheader
	svar imagekeys
	string fitsvalue1 = stringbykey(stringfromlist(fitskeypick1-1,imagekeys),header)
	string fitsvalue2 = stringbykey(stringfromlist(fitskeypick2-1,imagekeys),header)
	string fitsvalue3 = stringbykey(stringfromlist(fitskeypick3-1,imagekeys),header)
	string fitsvalue4 = stringbykey(stringfromlist(fitskeypick4-1,imagekeys),header)

	//Split filename into components 
	namecreation = namecreationg
	splitstring /e=regexp filename,name1,name2,sernum,imnum
	//Create new name out of parts (name1, name2, sernum, imnum) plus perhaps constants
	execute("dataname = " + namecreation)
	//Add any header values which might be requested (these are set in updatefitsloaderpaneloptions() )
	if(usefitskey1)
		dataname += "_" + num2str(.1*round(10*str2num(fitsvalue1)))
	endif
	if(usefitskey2)
		dataname += "_" + num2str(.1*round(10*str2num(fitsvalue2)))
	endif
	if(usefitskey3)
		dataname += "_" + num2str(.1*round(10*str2num(fitsvalue3)))
	endif
	if(usefitskey4)
		dataname += "_" + num2str(.1*round(10*str2num(fitsvalue4)))
	endif
	dataname = Replacestring(" ",dataname,"")
	print "Name to be used as User Name = \" " + dataname + "\""
	//Set Nika's User set data name to the created value
	setdatafolder root:Packages:Convert2Dto1D
	svar UserFileName=root:Packages:Convert2Dto1D:OutputDataName
	UserFileName = dataname
//Display Header Information in a window, if necessary
	if(dispheader)
		displayheaderinfo()
	endif
	wnote = replacestring(":",header,"=")
	wnote +=";creationdate="+num2str(filecdate)+";"
	return wnote
end

function displayheaderinfo()
	string foldersave = getdatafolder(1)
	setdatafolder root:
	svar headerinfo
	variable len = itemsinlist(headerinfo,";")
	make /t/o/n=(len) headerkeys,headervalues
	string headerkey,headervalue
	variable i
	for(i=0;i<len;i+=1)
		splitstring /e="^([^:]*):(.*)$" stringfromlist(i,headerinfo,";"),headerkey,headervalue
		headerkeys[i] =headerkey
		headervalues[i] = headervalue 
	endfor
	DoWindow HeaderInfoDisplay
	if(v_flag==0)
		//window doesn't exist
		Edit/K=1/W=(854.25,44,1119,455) /N=HeaderInfoDisplay headerkeys,headervalues as "Header Info Display"
		ModifyTable format(Point)=1,width(Point)=20,alignment(headerkeys)=0,width(headerkeys)=111
		ModifyTable alignment(headervalues)=0,width(headervalues)=93
	else
		DoWindow /f HeaderInfoDisplay
	endif
	setdatafolder foldersave
end

function/d correctI0(i0in,en,pol,os)
	variable i0in,en,pol,os
	variable c_io=NAN
	string foldersave=getdatafolder(1)
	setdatafolder root:Packages:nika1101:
//	os = os<3.4?0:1
	nvar i0offset
	nvar pdoffset
	variable len
	if(!datafolderexists("I0data"))
		len=0
	else
		setdatafolder i0data
		string ioname,I0liststr = wavelist("I0corr*",";","")
		len = itemsinlist(I0liststr)
	endif
	//if(len <1)
	//	print "WARNING no I0 waves found"
	//endif
	variable i,j=0
	string ionote,ionum
	for(i=0;i<len;i+=1)
		ioname = stringfromlist(i,I0liststr)
		splitstring /e="^I0corr(.*)" ioname,ionum
		ionote = note($ioname)
		if(str2num(stringbykey("pol",ionote))==pol && str2num(stringbykey("os",ionote))==os && exists("eI0corr"+ionum))
			c_io= (i0in-i0offset)* interp(en,$("eI0corr"+ionum),$ioname)
			i=len
			print "Found correct polarization I0. Loading "+ ioname + " for i0 correction"
		endif
	endfor
	if(c_io*0 != 0)
		for(i=0;i<len;i+=1)
			ioname = stringfromlist(i,I0liststr)
			splitstring /e="^I0corr(.*)$" ioname,ionum
			ionote = note($ioname)
			if((str2num(stringbykey("pol",ionote))==pol || str2num(stringbykey("os",ionote))==os) && exists("eI0corr"+ionum))
				c_io= (i0in-i0offset)* interp(en,$("eI0corr"+ionum),$ioname)  // nA gold * photons / nA gold
				i=len
				print "WARNING: no correct i0 with the same polarization was found. Instead, we loaded "+ ioname + " for i0 correction"
			endif
		endfor
		if(c_io*0 != 0)
			for(i=0;i<len;i+=1)
				ioname = stringfromlist(i,I0liststr)
				splitstring /e="^I0corr(.*)$" ioname,ionum
				if( exists("eI0corr"+ionum))
					c_io= (i0in-i0offset)* interp(en,$("eI0corr"+ionum),$ioname)  // nA gold * photons / nA gold
					i=len
					print "WARNING: no correct i0 with the same polarization was found. Instead, we loaded "+ ioname + " for i0 correction"
				endif
			endfor
		endif
		if(c_io*0 != 0)
			c_io= PDnA2photons(i0in, en)  // this isn't at all correct, but it's closeish (right order of magnitude)
			print "WARNING: no I0 correction loaded"
		endif
	endif
	setdatafolder $foldersave
	return c_io // c_io is now in equivalent nanoamps - this converts the final output to numbers of incident photons (assumes correction with photodiode)
end

function correctbeamcenter()
	nvar pxsizex = root:Packages:Convert2Dto1D:PixelSizeX
	nvar pxsizey = root:Packages:Convert2Dto1D:PixelSizeY
	nvar beamx = root:Packages:Convert2Dto1D:BeamCenterX
	nvar beamy = root:Packages:Convert2Dto1D:BeamCenterY
	nvar Horztilt = root:Packages:Convert2Dto1D:HorizontalTilt
	nvar Verttilt = root:Packages:Convert2Dto1D:VerticalTilt
	nvar CCDTH0 = root:Packages:Nika1101:CCDTHzero
	nvar CCDY0 = root:Packages:Nika1101:CCDYzero
	nvar CCDX0 = root:Packages:Nika1101:CCDXzero
	nvar SAD0 = root:Packages:Nika1101:SADzero
	nvar BX0 = root:Packages:Nika1101:BXzero
	nvar BY0 = root:Packages:Nika1101:bYzero
	nvar SAD = root:Packages:Convert2Dto1D:SampleToCCDDistance
	svar header = root:headerinfo
	variable CCDx  = str2num(stringbykey("CCDX",header))
	variable CCDY  = str2num(stringbykey("CCDY",header))
	variable SampleZ  = str2num(stringbykey("SampleZ",header))
	variable Sampleth  = str2num(stringbykey("SampleTheta",header))
	variable CCDTheta  = str2num(stringbykey("CCDTheta",header))
	verttilt = (CCDTheta-CCDth0)	
	sad=(sad0+ccdy-CCDY0+Sin(sampleth*pi/180)*samplez)/Cos(verttilt*pi/180)
	beamx=BX0+((-CCDx + CCDX0)/cos((horztilt*pi/180)*pi/180))/pxsizex//  +  (CCDy)*17.5/80
	beamy =BY0+(SAD * sin((verttilt*pi/180)))/pxsizey// - (CCDy)*110/80
//the old way, using beam center in pixels as the stored value
//	beamy = (1/pxsizey) *sad*sin(pi*ccdTheta/180)/cos((ccdtheta+verttilt)*pi/180)-CCDTH0
end
Function Setbeamzero_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			setbeamzero()
			break
	endswitch

	return 0
End

Function setbeamzero()
	svar filestr = root:Packages:Convert2Dto1D:FileNameToLoad
	if(exists("root:Packages:Nika1101:CCDTHzero")&&exists("root:Packages:Nika1101:CCDXzero")&&stringmatch(filestr,"*.fits"))
		nvar pxsizex = root:Packages:Convert2Dto1D:PixelSizeX
		nvar pxsizey = root:Packages:Convert2Dto1D:PixelSizeY
		nvar beamx = root:Packages:Convert2Dto1D:BeamCenterX
		nvar beamy = root:Packages:Convert2Dto1D:BeamCenterY
		nvar Horztilt = root:Packages:Convert2Dto1D:HorizontalTilt
		nvar Verttilt = root:Packages:Convert2Dto1D:VerticalTilt
		nvar SAD = root:Packages:Convert2Dto1D:SampleToCCDDistance
		nvar CCDTH0 = root:Packages:Nika1101:CCDTHzero
		nvar CCDY0 = root:Packages:Nika1101:CCDYzero
		nvar CCDX0 = root:Packages:Nika1101:CCDXzero
		nvar SAD0 = root:Packages:Nika1101:SADzero
		nvar BX0 = root:Packages:Nika1101:BXzero
		nvar BY0 = root:Packages:Nika1101:bYzero
		svar header = root:headerinfo
		variable CCDx  = str2num(stringbykey("CCDX",header))
		variable CCDY  = str2num(stringbykey("CCDY",header))
		variable SampleZ  = str2num(stringbykey("SampleZ",header))
		variable Sampleth  = str2num(stringbykey("SampleTheta",header))
		variable CCDTheta  = str2num(stringbykey("CCDtheta",header))
		CCDTH0 = (CCDtheta - verttilt)
		sad0=sad*cos(verttilt*pi/180)-Sin(sampleth*pi/180)*samplez
		CCDX0 = CCDX
		CCDY0 = CCDY
		BX0 = beamx
		BY0 = Beamy - (Sad/pxsizey)*sin(verttilt*pi/180)
	endif
//Using the old way of finding the effective beamcenter y in pixels
//	CCDth0 = (1/pxsizey) *sad*sin(pi*ccdTheta/180)/cos((ccdtheta+verttilt)*pi/180) - beamy
end

function NI1_FitsLoaderPanelFnct() : Panel
	string currentfolder = getdatafolder(1)
	DoWindow  NI1_FitsLoaderPanel
	if(V_Flag)
		DoWindow/F NI1_FitsLoaderPanel
		setdatafolder root:packages:nika1101
		string /g imagekeys=""
	else
		if(!datafolderexists("root:packages:nika1101"))
			newdatafolder /s /o root:Packages:Nika1101
			string /g headerinfo
			defaultfitsexps()
		else
			setdatafolder root:packages:nika1101
			string /g loaderregexp
			string /g namecreation
		endif
		string /g imagekeys=""

		make /t /o loadedizeros
		nvar/z fitskeypick1
		if(!nvar_exists(fitskeypick1))
			variable/g fitskeypick1=1
		endif
		nvar/z fitskeypick2
		if(!nvar_exists(fitskeypick2))
			variable/g fitskeypick2=1
		endif
		nvar/z fitskeypick3
		if(!nvar_exists(fitskeypick3))
			variable/g fitskeypick3=1
		endif
		nvar/z fitskeypick4
		if(!nvar_exists(fitskeypick4))
			variable/g fitskeypick4=1
		endif
		//variable/g fitskeypick1
		//variable/g fitskeypick2
		//variable/g fitskeypick3
		//variable/g fitskeypick4
		variable/g usefitskey1
		variable/g usefitskey2
		variable/g usefitskey3
		variable/g usefitskey4
		variable/g chkflatten
		variable/g SupExChar
		variable/g flatten_line
		variable/g flatten_width
		variable/g Ai3izero
		variable/g Exposecorr
		variable/g dispheader
		variable/g photoncorr
		variable/g AdjBeam
		variable/g CCDXzero
		variable/g CCDTHzero
		variable/g SADzero
		variable/g CCDYzero
		variable/g BXzero
		variable/g bYzero
		variable/g FuckedI0s // because beamline 11.0.1.2 recorded series data incorrectly Dec-2013

		PauseUpdate; Silent 1		// building window...
		NewPanel /K=1 /W=(1077,58,1561,333)/N=NI1_FitsLoaderPanel as "Fits Naming"
		ModifyPanel/w=NI1_FitsLoaderPanel fixedSize=1
		SetDrawLayer/w=NI1_FitsLoaderPanel UserBack
		SetDrawEnv/w=NI1_FitsLoaderPanel fillfgc= (32768,65280,65280)
		DrawRect/w=NI1_FitsLoaderPanel 197,81,477,123
		SetDrawEnv/w=NI1_FitsLoaderPanel fillfgc= (32768,65280,32768)
		DrawRect/w=NI1_FitsLoaderPanel 197,2,477,78
		SetDrawEnv/w=NI1_FitsLoaderPanel fillfgc= (65280,65280,48896)
		DrawRect/w=NI1_FitsLoaderPanel 3,126,478,201
		SetDrawEnv/w=NI1_FitsLoaderPanel fillfgc= (51456,44032,58880)
		DrawRect/w=NI1_FitsLoaderPanel 3,2,193,123
		DrawText/w=NI1_FitsLoaderPanel 43,19,"Build Name from:"
		CheckBox mot1_ch,pos={169,24},size={16,14},title="",win=NI1_FitsLoaderPanel
		CheckBox mot1_ch,variable= root:Packages:Nika1101:usefitskey1,win=NI1_FitsLoaderPanel
		CheckBox mot2_ch,pos={169,46},size={16,14},title="",win=NI1_FitsLoaderPanel
		CheckBox mot2_ch,variable= root:Packages:Nika1101:usefitskey2,win=NI1_FitsLoaderPanel
		CheckBox mot3_ch,pos={169,68},size={16,14},title="",win=NI1_FitsLoaderPanel
		CheckBox mot3_ch,variable= root:Packages:Nika1101:usefitskey3,win=NI1_FitsLoaderPanel
		CheckBox mot4_ch,pos={169,90},size={16,14},title="",win=NI1_FitsLoaderPanel
		CheckBox mot4_ch,variable= root:Packages:Nika1101:usefitskey4,win=NI1_FitsLoaderPanel
		CheckBox Ai3izero_ch,pos={204,207},size={105,14},title="Use Ai3Izero for I0",win=NI1_FitsLoaderPanel
		CheckBox Ai3izero_ch,variable= root:Packages:Nika1101:Ai3izero,win=NI1_FitsLoaderPanel
		PopupMenu motor1_pop,pos={15,19},size={145,21},bodyWidth=100,proc=PopMenuProc_1,title="Motor 1: ",win=NI1_FitsLoaderPanel
		PopupMenu motor1_pop,mode=1,popvalue="none",value= #"root:packages:nika1101:imagekeys",win=NI1_FitsLoaderPanel
		PopupMenu motor2_pop,pos={15,41},size={145,21},bodyWidth=100,proc=PopMenuProc_2,title="Motor 2: ",win=NI1_FitsLoaderPanel
		PopupMenu motor2_pop,mode=1,popvalue="none",value= #"root:packages:nika1101:imagekeys",win=NI1_FitsLoaderPanel
		PopupMenu motor3_pop,pos={15,63},size={145,21},bodyWidth=100,proc=PopMenuProc_3,title="Motor 3: ",win=NI1_FitsLoaderPanel
		PopupMenu motor3_pop,mode=1,popvalue="none",value= #"root:packages:nika1101:imagekeys",win=NI1_FitsLoaderPanel
		PopupMenu motor4_pop,pos={15,85},size={145,21},bodyWidth=100,proc=PopMenuProc_4,title="Motor 4: ",win=NI1_FitsLoaderPanel
		PopupMenu motor4_pop,mode=1,popvalue="none",value= #"root:packages:nika1101:imagekeys",win=NI1_FitsLoaderPanel
		CheckBox automot_ch1,pos={211,17},size={226,14},title="Adjust Beam center based on CCD Location",win=NI1_FitsLoaderPanel
		CheckBox automot_ch1,variable= root:Packages:Nika1101:ADJBeam,win=NI1_FitsLoaderPanel
		SetVariable CCDX_zero,pos={234,38},size={174,16},title="CCDX - calibrated zero",win=NI1_FitsLoaderPanel
		SetVariable CCDX_zero,limits={-100,100,0.1},value= root:Packages:Nika1101:CCDXZero,win=NI1_FitsLoaderPanel
		SetVariable CCDTheta_zero1,pos={219,58},size={190,16},title="CCDTheta calibrated zero",win=NI1_FitsLoaderPanel
		SetVariable CCDTheta_zero1,limits={-100,100,0.1},value= root:Packages:Nika1101:CCDThZero,win=NI1_FitsLoaderPanel
		CheckBox flattenimageck,pos={215,87},size={203,14},title="Flatten image with screened out pixels?",win=NI1_FitsLoaderPanel
		CheckBox flattenimageck,variable= root:Packages:Nika1101:chkflatten,win=NI1_FitsLoaderPanel
		SetVariable Calibrationlinebox,pos={203,105},size={161,16},title="Flatten Center Line",win=NI1_FitsLoaderPanel
		SetVariable Calibrationlinebox,limits={0,2700,1},value= root:Packages:Nika1101:flatten_line,win=NI1_FitsLoaderPanel
		SetVariable Calibrationlinebox1,pos={370,104},size={93,16},title="Width",win=NI1_FitsLoaderPanel
		SetVariable Calibrationlinebox1,limits={0,2000,1},value= root:Packages:Nika1101:flatten_width
		SetVariable setvar0,pos={9,132},size={466,16},title="Regular Expression for Naming (Advanced) :",win=NI1_FitsLoaderPanel
		SetVariable setvar0,value= root:Packages:Nika1101:loaderregexp,win=NI1_FitsLoaderPanel
		SetVariable setvar1,pos={9,149},size={466,16},title="Naming String Construction (Advanced) :",win=NI1_FitsLoaderPanel
		SetVariable setvar1,value= root:Packages:Nika1101:namecreation,win=NI1_FitsLoaderPanel
		Button button0,pos={300,169},size={141,21},proc=dfe_buttoncctl,title="Set to Naming Defaults",win=NI1_FitsLoaderPanel
		CheckBox Exposurecorr_ch1,pos={15,206},size={166,14},title="Correct Data for Exposure Time",win=NI1_FitsLoaderPanel
		CheckBox Exposurecorr_ch1,variable= root:Packages:Nika1101:Exposecorr,win=NI1_FitsLoaderPanel
		CheckBox DIspHeader_ch,pos={36,108},size={134,14},title="Display Header On Load",win=NI1_FitsLoaderPanel
		CheckBox DIspHeader_ch,variable= root:Packages:Nika1101:dispheader,win=NI1_FitsLoaderPanel
		Button SetBeamzero,pos={415,34},size={58,41},proc=Setbeamzero_ButtonProc,title="Set Now",win=NI1_FitsLoaderPanel
		Button LoadI0,pos={13,228},size={70,40},proc=ButtonProc_5,title="Load I0\rScan",win=NI1_FitsLoaderPanel
		ListBox list0,pos={92,229},size={381,42},win=NI1_FitsLoaderPanel
		ListBox list0,listWave=root:Packages:Nika1101:loadedizeros,row= 1,win=NI1_FitsLoaderPanel
		CheckBox Sup_Extra_ch,pos={19,171},size={174,26},title="Suppress Extra Name Characters\r (eg C, glp etc)",win=NI1_FitsLoaderPanel
		CheckBox Sup_Extra_ch,variable= root:Packages:Nika1101:SupExChar,win=NI1_FitsLoaderPanel
		CheckBox Ai3izero_ch1,pos={342,205},size={86,14},title="Messed up I0s",win=NI1_FitsLoaderPanel
		CheckBox Ai3izero_ch1,variable= root:Packages:Nika1101:FuckedI0s,win=NI1_FitsLoaderPanel
	endif

		
	setdatafolder root:packages:nika1101
	svar header = headerinfo
	svar imagekeys
	imagekeys = ""
	nvar fitskeypick1 // there is an annoying bug with this.  Some images have different index of different components, so we need to remeber the actual name, rather than the index 
	nvar fitskeypick2
	nvar fitskeypick3
	nvar fitskeypick4
	string /g fitskeyname1
	string /g fitskeyname2
	string /g fitskeyname3
	string /g fitskeyname4
	nvar usefitskey1
	nvar usefitskey2
	nvar usefitskey3
	nvar usefitskey4
	nvar chkflatten
	nvar SupExChar
	nvar flatten_line
	nvar flatten_width
	string s1
	variable i
	for(i=0;i<itemsinlist(header,";");i+=1)
		splitstring /e="^([^:]*):[^;]*$" stringfromlist(i,header,";"),s1
		s1=ReplaceString(" ",s1,"")
		imagekeys+=s1+";"
	endfor
	string imagekeystring = imagekeys
	if(strlen(stringbykey(fitskeyname1,header))>0)
		fitskeypick1 =whichlistitem(fitskeyname1,imagekeys)+1
		PopupMenu motor1_pop,mode=fitskeypick1,win=NI1_FitsLoaderPanel
	else
		PopupMenu motor1_pop,mode=fitskeypick1,win=NI1_FitsLoaderPanel
		fitskeyname1 = stringfromlist(fitskeypick1-1,imagekeys)
	endif
	if(strlen(stringbykey(fitskeyname2,header))>0)
		fitskeypick2 =whichlistitem(fitskeyname2,imagekeys)+1
		PopupMenu motor2_pop,mode=fitskeypick2,win=NI1_FitsLoaderPanel
	else
		PopupMenu motor2_pop,mode=fitskeypick2,win=NI1_FitsLoaderPanel
		fitskeyname2 = stringfromlist(fitskeypick2-1,imagekeys)
	endif
	if(strlen(stringbykey(fitskeyname3,header))>0)
		fitskeypick3 =whichlistitem(fitskeyname3,imagekeys)+1
		PopupMenu motor3_pop,mode=fitskeypick3,win=NI1_FitsLoaderPanel
	else
		PopupMenu motor3_pop,mode=fitskeypick3,win=NI1_FitsLoaderPanel
		fitskeyname3 = stringfromlist(fitskeypick3-1,imagekeys)
	endif
	if(strlen(stringbykey(fitskeyname4,header))>0)
		fitskeypick4 =whichlistitem(fitskeyname4,imagekeys)+1
		PopupMenu motor4_pop,mode=fitskeypick4,win=NI1_FitsLoaderPanel
	else
		PopupMenu motor4_pop,mode=fitskeypick4,win=NI1_FitsLoaderPanel
		fitskeyname4 = stringfromlist(fitskeypick1-1,imagekeys)
	endif

	string /g fitsvalue1 = stringbykey(fitskeyname1,header)
	string /g fitsvalue2 = stringbykey(fitskeyname2,header)
	string /g fitsvalue3 = stringbykey(fitskeyname3,header)
	string /g fitsvalue4 = stringbykey(fitskeyname4,header)
	setdatafolder currentfolder
End


function updatefitsloaderpaneloptions()
	string currentfolder = getdatafolder(1)
	if(!datafolderexists("root:packages:nika1101"))
		newdatafolder /s /o root:Packages:Nika1101
		string /g headerinfo
	else
		setdatafolder root:packages:nika1101
	endif
	string /g imagekeys=""
	nvar/z fitskeypick1
	if(!nvar_exists(fitskeypick1))
		variable/g fitskeypick1=1
	endif
	nvar/z fitskeypick2
	if(!nvar_exists(fitskeypick2))
		variable/g fitskeypick2=1
	endif
	nvar/z fitskeypick3
	if(!nvar_exists(fitskeypick3))
		variable/g fitskeypick3=1
	endif
	nvar/z fitskeypick4
	if(!nvar_exists(fitskeypick4))
		variable/g fitskeypick4=1
	endif
	//variable/g fitskeypick2
	//variable/g fitskeypick3
	//variable/g fitskeypick4
	variable/g usefitskey1
	variable/g usefitskey2
	variable/g usefitskey3
	variable/g usefitskey4
	variable/g chkflatten
	variable/g SupExChar
	variable/g flatten_line
	variable/g flatten_width
	string /g fitskeyname1
	string /g fitskeyname2
	string /g fitskeyname3
	string /g fitskeyname4
	svar header = headerinfo
	string s1
	variable i
	for(i=0;i<itemsinlist(header,";");i+=1)
		splitstring /e="^([^:]*):[^;]*$" stringfromlist(i,header,";"),s1
		s1=ReplaceString(" ",s1,"")
		imagekeys+=s1+";"
	endfor
	if(strlen(stringbykey(fitskeyname1,header))>0)
		fitskeypick1 =whichlistitem(fitskeyname1,imagekeys)+1
		PopupMenu motor1_pop,mode=fitskeypick1, win=NI1_FitsLoaderPanel
	else
		PopupMenu motor1_pop,mode=fitskeypick1,win=NI1_FitsLoaderPanel
		fitskeyname1 = stringfromlist(fitskeypick1-1,imagekeys)
	endif
	if(strlen(stringbykey(fitskeyname2,header))>0)
		fitskeypick2 =whichlistitem(fitskeyname2,imagekeys)+1
		PopupMenu motor2_pop,mode=fitskeypick2, win=NI1_FitsLoaderPanel
	else
		PopupMenu motor2_pop,mode=fitskeypick2,win=NI1_FitsLoaderPanel
		fitskeyname2 = stringfromlist(fitskeypick2-1,imagekeys)
	endif
	if(strlen(stringbykey(fitskeyname3,header))>0)
		fitskeypick3 =whichlistitem(fitskeyname3,imagekeys)+1
		PopupMenu motor3_pop,mode=fitskeypick3, win=NI1_FitsLoaderPanel
	else
		PopupMenu motor3_pop,mode=fitskeypick3,win=NI1_FitsLoaderPanel
		fitskeyname3 = stringfromlist(fitskeypick3-1,imagekeys)
	endif
	if(strlen(stringbykey(fitskeyname4,header))>0)
		fitskeypick4 =whichlistitem(fitskeyname4,imagekeys)+1
		PopupMenu motor4_pop,mode=fitskeypick4, win=NI1_FitsLoaderPanel
	else
		PopupMenu motor4_pop,mode=fitskeypick4,win=NI1_FitsLoaderPanel
		fitskeyname4 = stringfromlist(fitskeypick1-1,imagekeys)
	endif

	string /g fitsvalue1 = stringbykey(fitskeyname1,header)
	string /g fitsvalue2 = stringbykey(fitskeyname2,header)
	string /g fitsvalue3 = stringbykey(fitskeyname3,header)
	string /g fitsvalue4 = stringbykey(fitskeyname4,header)
	setdatafolder currentfolder
end

Function dfe_buttoncctl(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			defaultfitsexps()
			break
	endswitch

	return 0
End

function defaultfitsexps()
	string currentfolder = getdatafolder(1)
	setdatafolder root:packages:nika1101
	string /g loaderregexp="^([^_]{1,6})[^_]*?_([^_]{1,6})?.*([1234567890]{4,6})-?(.{3,6}?).fits$"
	string /g namecreation= "name1"
	setdatafolder currentfolder
end
//Brian's smoothed version
//function flattenimage(image,yloc,wid)
//	wave image
//	variable yloc,wid
//	make/o/n=2 ytrace={yloc,yloc},xtrace={0,dimsize(image,1)}
//	ImageLineProfile srcWave=image width=(wid) , xWave=xTrace, yWave=yTrace
//	wave w=w_imagelineprofile
//	smooth/M=10 2, w
//	smooth/E=3/B=3 21, w
//	image-=w(x)
//end

function flattenimage(image,yloc,wid)
	wave image
	variable yloc,wid
	make/o/n=2 ytrace={yloc,yloc},xtrace={0,dimsize(image,1)}
	ImageLineProfile srcWave=image width=(wid) , xWave=xTrace, yWave=yTrace
	variable v_fiterror=0
	wave w_imagelineprofile
	removenans(W_ImageLineProfile)
	CurveFit/M=2/W=2/Q/L=3000 dblexp, W_ImageLineProfile/D
	if(v_fiterror)
		v_fiterror=0
		w_imagelineprofile+=exp(p/3000)
		CurveFit/M=2/W=2/Q/L=3000 dblexp_XOffset, W_ImageLineProfile/D	
	endif
	wave fit_W_ImageLineProfile
	image-=fit_W_ImageLineProfile(x)
//	image-=W_ImageLineProfile(x)
end


Function PopMenuProc_1(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
 			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string currentfolder = getdatafolder(1)
			setdatafolder root:packages:nika1101
			variable /g fitskeypick1 = popnum
			svar headerinfo
			string /g fitsvalue1 = stringbykey(popstr,headerinfo)
			string /g fitskeyname1 = popstr
			setdatafolder currentfolder
			break
	endswitch

	return 0
End
Function PopMenuProc_2(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string currentfolder = getdatafolder(1)
			setdatafolder root:packages:nika1101
			variable /g fitskeypick2 = popnum
			svar headerinfo
			string /g fitsvalue2 = stringbykey(popstr,headerinfo)
			string /g fitskeyname2 = popstr
			setdatafolder currentfolder
			break
	endswitch

	return 0
End

Function PopMenuProc_3(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string currentfolder = getdatafolder(1)
			setdatafolder root:packages:nika1101
			variable /g fitskeypick3 = popnum
			svar headerinfo
			string /g fitsvalue3 = stringbykey(popstr,headerinfo)
			string /g fitskeyname3 = popstr
			setdatafolder currentfolder
			break
	endswitch

	return 0
End
Function PopMenuProc_4(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string currentfolder = getdatafolder(1)
			setdatafolder root:packages:nika1101
			variable /g fitskeypick4 = popnum
			svar headerinfo
			string /g fitsvalue4 = stringbykey(popstr,headerinfo)
			string /g fitskeyname4 = popstr
			setdatafolder currentfolder
			break
	endswitch

	return 0
End


//loads a set of data and normalizes it to another dataset that is assumed to be the straight beam for NEXAFS spectra
Function GetNEXAFS(dName, OS, pol, [pdOff,izerooff, d, hLine])
	String dName
	Variable OS // binary: Was Order Sorter In?
	Variable Pol // polarization used (info may not be in the data file)
	Variable pdOff //optional photodiode zero offset uses zero by default
	Variable izeroOff //optional photodiode zero offset uses zero by default
	Variable d // 1=display data, 2=append data, 3=append to right axis
	Variable hLine //line number of the headers in the wave: sigma scans are on line 12 and trajectory scans are line 9
	hLine= ParamIsDefault(hLine) ? 9 : hLine
	String CurrentFolder=GetDataFolder(1)
	
	//Load I0 Data
	If( ParamIsDefault(pdOff) )
		pdOff=Loadi0(OS,"I0","photodiode",notNIKA=1) //loads I0 data
	else
		Loadi0(OS,"I0","photodiode", pdOff=pdOff,izerooff=izeroOff, notNIKA=1) //loads I0 data		
	endif

	Variable i
	For( i=0; ; i+=1 )
		wave i0corr=$("I0corr"+num2str(i)), ei0corr=$("eI0corr"+num2str(i))
		If( !WaveExists(i0corr) )
			print "Error: No I0 match"
			SetDataFolder $CurrentFolder
			return 0
		endif
		If( pol==numberbykey("POL",note(i0corr)) && OS==numberbykey("OS",note(i0corr)) )
			break
		elseif( numberbykey("POL",note(i0corr))*0 != 0 )
			break
		endif
	endfor
	
	//Load I1 Data
	NewDataFolder/O/S :I1Raw
	LoadWave /A/W/O/L={hLine,hLine+1,0,0,0}/J //names the waves it imports using the column headers
	If( V_Flag==0 ) //user canceled
		print "User canceled operation."
		SetDataFolder $CurrentFolder
		return 0
	endif
	Wave Beamline_energy, mesh=I0, pd=Photodiode
	Duplicate/d/o BeamLine_Energy $(dName+"_signal"), $(dName+"_i0")
	Wave signal=$(dName+"_signal"), I0interp=$(dName+"_i0")
	SetDataFolder $CurrentFolder
	Duplicate/d/o Beamline_Energy $(dName+"_e") $(dName)
	Wave energy=$(dName+"_e"), spec=$(dName)
	signal=(pd-pdOff)/mesh
	i0interp=interp( energy, ei0corr, i0corr)
	spec=ln(i0interp/signal)
	
	If( d==1 )
		display spec vs energy
		Label left "Absobance [OD]"
		Label bottom "Energy [eV]"
		ModifyGraph grid=2,tick=2,mirror=1,standoff=0
	elseif( d==2 )
		appendtograph spec vs energy
	elseif( d==3 )
		appendtograph/r spec vs energy
		Label right "Absobance [OD]"
	endif
end

//Loads an I0 correction 'trajectory scan' file which may contain energy scans with different polarizations
//corrects for photodiode zero offset if given or is in the file along with "CCDshutterInhibit" column
//saves the polarization and order sorter information in the wave note of each scan wave
Function Loadi0(OS,i0wavename,pdname, [polarization,pdOff,izerooff, notNIKA, hLine])
	Variable OS //is the order sorter in (1) or out (0)
	string pdname,i0wavename
	variable polarization //polarization of this scan (used if epu_polarization is not loaded)
	Variable pdOff //Override value for the photodiode zero offset (usually read from file when "CCDshutterInihibit" is used)
	Variable izerooff //I0 value offset (0 if unset)
	Variable notNIKA //Binary, don't store in NIKA1101 folder (don't affect the official NIKA I0correction)
	Variable hLine //line number of the headers in the wave: sigma scans are on line 12 and trajectory scans are line 9
	izerooff = paramisdefault(izerooff) ? 0 : izerooff
	polarization = paramisdefault(polarization) ? -1 : polarization
	hLine= ParamIsDefault(hLine) ? 9 : hLine
//	os = os<3.4?0:1
	String CurrentFolder=GetDataFolder(1)
	If( !notNIKA )
		NewDataFolder/O root:Packages
		NewDataFolder/O root:Packages:Nika1101
		NewDataFolder/O/S root:Packages:Nika1101:RawI0scan
	else
		NewDataFolder/O/S $(CurrentFolder+"Raw")
	endif
	LoadWave /A/W/O/L={hLine, hLine+1,0,0,0}/J/Q //names the waves it imports using the column headers
	If( V_Flag==0 ) //user canceled
		print "User canceled operation."
		SetDataFolder $CurrentFolder
		return 0
	endif
	string filename = S_fileName
	string pathloaded = s_path
	getfilefolderinfo /Q pathloaded+filename
	string createddate = secs2date(v_creationDate,0)+" "+secs2time(v_creationDate,3)
	If( !WaveExists(Beamline_Energy) )
		If( !WaveExists(Beamline_Energy_Goal) )
			Doalert 0, "Error: Wrong first line for column names! Aborting."
			SetdataFolder $CurrentFolder
			return 0
		else
			rename Beamline_Energy_Goal, Beamline_Energy
		endif
	endif
	Duplicate/d/o Beamline_Energy dEnergy
	Differentiate dEnergy
	//	Energy, 	Polarization, 	Gold Mesh, 	Photodiode, 	Energy Derivative, 	Shutter Closed
	WAVE/Z Beamline_Energy, EPU_polarization, I0=$i0wavename, Photodiode=$pdname, dEnergy,osp = Higher_Order_Suppressor//, CCDshutterInhibit
	WAVE/Z ai3=ai_3_izero, bc=Beam_current, i00=izero, timeStamp=Time_of_Day // changed from Ai3 Izero
	i0 -= Izerooff
	Duplicate/d/o I0 I0corr, eI0corr
	string i0corrname, I0name, Ename, nIndex, noteStr, ParseVals, lgndTxt="", ai3name, bcName, i00name, pdnamenew
	string dispScans="", pdDisp="", ai3disp="", bcDisp="", i00disp=""
	ParseVals="0"
	//ParseVals="0;49;50;53;102;103"//
	ParseVals=ParseEscan(dEnergy)
	Variable i, nPts, start, nScans=itemsInList(parseVals), NoPdOff=paramIsDefault(pdOff), PolData=WaveExists(EPU_polarization)
	If( NoPdOff && waveExists(CCDshutterInhibit) ) //read photodiode zero offset value from file if it exists
		Redimension/I CCDshutterInhibit
		FindValue/I=1/Z CCDshutterInhibit
		If( V_Value>0 )
			pdOff=Photodiode[V_Value]
			NoPdOff=0 //successfully read the photodiode zero offset from file
		else
			pdOff=0
		endif
	endif

	DoWindow/F I0corrdata
	If( V_Flag == 0 && !notNIKA )
		Display/K=1/n=I0corrData as "I0corr Data"
		display/N=pddata/k=1 as "PD Data"
		display/N=ai3data/k=1 as "ai3 Data"
		display/N=bcData/k=1 as "Beam Current Data"
		display/N=i00data/k=1 as "izero Data"
		If( PolData )
			TextBox/N=Lgnd/F=2/A=MC "Polarization \t OS"
		endif
	else
		dispScans=TraceNameList("I0corrData",";",1)
		pdDisp=TraceNameList("pdData",";",1)
		ai3disp=TraceNameList("ai3data",";",1)
		bcdisp=TraceNameList("bcdata",";",1)
		i00disp=TraceNameList("i00data",";",1)
	endif
	SetDataFolder :: //move up a folder
	For( i=0; i<nScans ; i+=1 )
		start = str2num(stringfromlist(i,ParseVals))
		nPts = i==nScans-1 ? numpnts(I0) - start : str2num(stringfromlist(i+1,ParseVals)) - start
//		If( NoPdOff )// && waveExists(CCDshutterInhibit) && CCDshutterInhibit[start]==1 )
//			continue //don't record this scan if it is the dark scan
//		endif
		Redimension/n=(nPts) I0corr, eI0corr
		eI0corr=Beamline_energy[p+start]
		I0corr=(Photodiode[p+start]-pdOff)/I0[p+start]  //nA diode / nA Mesh
		If( stringmatch(pdname,"Photodiode") )
			i0corr=PDna2photons(i0corr,eI0corr)  // Photons / nA goldmesh
		elseif( stringmatch(pdname,"AI_3_Izero") ) // changed from Ai3 Izerog
			i0corr=BSna2photons(I0corr)
		endif
		//save polarization & order sorter info in the wavenote
		If( PolData )
			polarization = EPU_polarization[start]
		endif
		if(waveexists(osp))
			os = osp[start]
		else
			nvar ospanelvalue= root:Packages:Nika1101:i0oslocation
			os=ospanelvalue
		endif
		sprintf noteStr, "POL:%f;OS:%f;", polarization, OS
		notestr = addlistitem("File:"+filename,notestr)
		notestr = addlistitem("CreationDate:"+createddate,notestr)
		notestr = addlistitem("Path:"+pathloaded,notestr)
		
		//save each scan to Nika1101
		
		nIndex=FindExistingEscan(polarization, OS)
		If( strLen(nIndex)<1 ) //create brand new I0 scan
			I0CorrName=UniqueName("I0corr", 1, 0)
			SplitString/E="^I0corr(.*)$" I0CorrName, nIndex
		else  //overwrite old I0 scan with new scan
			I0CorrName="I0corr"+nIndex
		endif
		Ename="eI0corr"+nIndex
		PDnamenew="PD"+nIndex
		ai3name="ai3"+nIndex
		i00name="i00"+nindex
		BCname="BC"+nIndex
		Note/K I0corr, noteStr
		Note/K eI0corr, noteStr
		Duplicate/d/o I0corr $I0corrName
		Duplicate/d/o eI0corr $Ename
		If( strlen(ListMatch(dispScans,I0corrName))<1 ) //this trace is not plotted
			Appendtograph/W=i0corrData $I0CorrName vs $Ename
			ModifyGraph/W=i0corrData grid=2,tick=2,mirror=1,minor=1,standoff=0
			ModifyGraph/W=i0corrData margin(left)=36,margin(bottom)=29,margin(top)=14,margin(right)=14
			Label/W=i0corrData left "Correction Factor \u"
			Label/W=i0corrData bottom "Energy [eV]"
			lgndTxt="\\s("+I0CorrName+") P="+num2str(polarization)+", OS="+num2str(os)
			Textbox/C/N=Lgnd/W=i0corrData
			AppendText/N=Lgnd/W=i0corrData lgndTxt
		endif
		NewDataFolder/O/S root:Packages:Nika1101:I0data
		Duplicate/d/o I0corr $I0corrName
		Duplicate/d/o eI0corr $Ename
		Duplicate/d/o Photodiode $PDnamenew
		Duplicate/d/o ai3 $ai3name
		Duplicate/d/o bc $bcName
		Duplicate/d/o i00 $i00name
		Duplicate/d/o timeStamp $("time"+nIndex)
		Note/K $PDnamenew, noteStr
		Note/K $ai3name, noteStr
		Note/K $i00name, noteStr
		Note/K $bcName, noteStr
		If( strlen(ListMatch(pdDisp,PDname))<1 ) //this trace is not plotted
			appendtograph/W=pdData $PDnamenew vs $ename
			appendtograph/W=ai3data $ai3name vs $ename
			appendtograph/W=bcdata $bcname vs $ename
			appendtograph/W=i00data $i00name vs $ename
		endif
	Endfor
	SetDataFolder $CurrentFolder
	printf "Loaded %d scans(s) from %s%s.\r",nScans,S_path,S_fileName
	If( NoPdOff )
		printf "WARNING: No photodiode offset found/used.  To input manually, add optional 'pdOff' parameter.\r"
	else
		printf "Photodiode Zero Offset = %g\t i0 offset = %g\r", pdOff, izerooff
	endif
	UpdateIzeroList()
	return pdOff
End

//given the derivative of the energy data, this function returns a list string containing the first index of each scan
Function/S ParseEscan(w)
	wave w //derivative of the energies
	Variable i, direction= w[5]>0 ? 1 : -1, pos=0 //direction tells if the energy is being swept up or down
	string pVals="0;"
	Do
		Findlevel/Edge=(direction>0?2:1)/Q/P/R=[pos] w, (direction*-1) //look for zero crossing opposite "direction"
		If( V_Flag==0 ) //found it
			pos=ceil(V_levelX)+1
			pVals+=num2str(pos)+";"
		else
			Break
		endif
	While( 1 )
	return pVals
End

//Checks existing I0 scans in Nika1101 for scans that have the same polarization and order sorter info
Function/S FindExistingEscan(pol,OS)
	Variable OS, pol
	string matchStr="", I0scans=wavelist("I0corr*",";","")
	variable i, savedPol, savedOS
	For( i=0; i<itemsInList(I0scans); i+=1 )
		WAVE w=$(stringfromlist(i, I0scans))
		savedPol=NumberByKey("POL",Note(w))
		savedOS=NumberByKey("OS",Note(w))
		if(pol == savedpol && os ==savedOS)
			SplitString/E="^I0corr(.*)$" NameOfWave(w), matchStr
		endif
	endfor
	return matchStr // returns matching io scan if applicable, or a blank string
End



//used during Jan 2011 beamtime to produce graphs
function ProcessLines1(str,smth,qMult,vSpace,qTilt,qName)
	String Str //string to match in the data name
	Variable smth, qMult, vSpace, qTilt
	String qName
       string loname
       string foldersave = getdatafolder(1)
       if(!datafolderexists("root:SAS"))
               print "lineouts not loaded"
               return -1
       endif
       setdatafolder root:SAS
       string lineoutsstr = DataFolderDir(1)
       lineoutsstr = ReplaceString("FOLDERS:", lineoutsstr, "")
       lineoutsstr = ReplaceString(";\r", lineoutsstr, "")
       variable len = itemsinlist(lineoutsstr,",")
       if(len <1)
               print "no lineouts found in folder"
       endif
       print len
       variable i,j=0

       for(i=0;i<len;i+=1)
               loname = stringfromlist(i,lineoutsstr,",")
               if(stringmatch(loname,"*"+str+"*"))
			setdatafolder $loname
			wave qwave = $(qname+"_" + loname),rwave = $("r_" + loname)
			wave rOrig=$("rO_" + loname), yOrig=$(qname+"O_" + loname)
			If( !WaveExists(rOrig) )
				duplicate/o rwave, $("rO_" + loname)
				duplicate/o qwave, $(qname+"O_" + loname)
			else	
				duplicate/o rOrig, rwave
				duplicate/o yOrig, qwave
			endif
			smooth smth,rwave
			qwave *=qMult
			rwave *=qwave^qTilt
			rwave *=vSpace^j
			setdatafolder root:SAS
			j+=1
               endif
       endfor
       setdatafolder foldersave
end


//Rewritten to alter data in target graph, use graph style of target graph to make Kratky graph have same colors etc.
function cProcessLines(targetWin,mStr,smth,xMult,vSpace,xTilt,d,[preFact])
	String targetWin //target window name leave blank for top window
	String mStr //string to match in the data name
	Variable smth, xMult, vSpace, xTilt, d //display
	Variable preFact //optional prefactor before tilting if xw is d-spacing instead of q use "1/(2*pi)"
	If( ParamIsDefault(preFact) )
		preFact=1
	endif
	If( strLen(targetWin) < 1 )
		targetWin=WinName(0,1)
	endif
	string currentFolder = getdatafolder(1)
	NewDataFolder/O/S root:SASprofiles
	Variable i, ctr=0
	If( d )
		Display as targetWin+" Kratky"
		DoWindow/C $UniqueName(targetWin,6,0)
	endif
	For( i=0; ; i+=1 )
		WAVE yw=WaveRefIndexed(targetWin,i,1)
		If( !WaveExists(yw) )
			break
		elseif( StringMatch(NameOfWave(yw),"*"+mStr+"*") )
			String yn=NameOfWave(yw)
			Duplicate/d/o yw $yn
			WAVE yw=$yn, xw=XWaveRefFromTrace(targetwin,yn)
			If( WaveExists(xw) )
				String xn=NameOfWave(xw)
				Duplicate/d/o xw $xn
				WAVE xw=$xn
				If( d )
					appendtograph yw vs xw
				endif
			elseif( d )
				appendtograph yw
			endif
		endif
		smooth smth, yw
		xw *=xMult
		yw *=preFact*xw^xTilt
		yw *=vSpace^ctr
		ctr+=1
	Endfor
	SetDataFolder $CurrentFolder
end

Function NikaBG()
	DoWindow/F AutoLoadPanel // bring panel to front if it exists
	if( V_Flag != 0 )
		return 0 // panel already exists
	endif
	String dfSav= GetDataFolder(1)// so we can leave current DF as we found it
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:Nika1101
	NewDataFolder/O/S root:Packages:Nika1101:bkg // our variables go here
	string /g CommandStr=""
	// still here if no panel, create globals if needed
	if( NumVarOrDefault("inited",0) == 0 )
		string /g CommandStr=""
		Variable/G inited= 1
		Variable/G lastRunTicks= 0 // value of ticks function last time we ran
		Variable/G runNumber= 0 // incremented each time we run
		// message displayed in panel using SetVariable...
		String/G message="Task paused. Click Start to resume."
		Variable/G running=0 // when set, we do our thing
	endif
	SetDataFolder dfSav
	NewPanel/K=2 /W=(1476,57,1810,128)
	ModifyPanel fixedSize=1
	DoWindow/C AutoLoadPanel // set panel name
	Button StartButton,pos={21,12},size={50,20},proc=BGStartStopProc,title="Start"
	SetVariable msg,pos={21,43},size={300,17},title=" ",frame=0
	SetVariable msg,limits={-Inf,Inf,1},value= root:Packages:Nika1101:bkg:message
	SetVariable CommandStringBox,pos={79,16},size={250,16},title="Command to Run: "
	SetVariable CommandStringBox,value= root:Packages:Nika1101:bkg:CommandStr
	SetVariable msg noedit=1
End

Function NikaBGTask(s)
	STRUCT WMBackgroundStruct &s
	NVAR running= root:Packages:Nika1101:bkg:running
	if( running == 0 )
		return 0 // not running -- wait for user
	endif
	NVAR lastRunTicks= root:Packages:Nika1101:bkg:lastRunTicks
	if( (lastRunTicks+20) >= ticks )
		return 0 // not time yet, wait
	endif
	NVAR runNumber= root:Packages:Nika1101:bkg:runNumber
	runNumber += 1
	variable bgcheck= BGCheckdir()
	if(bgcheck==2)
		svar filename = root:Packages:Nika1101:bkg:filename 
		print "New fits file loaded: " + filename
		String/G root:Packages:Nika1101:bkg:message="Converted "+filename+" - execution failed - waiting for new file"
		doupdate
	elseif(bgcheck==1)
		svar filename = root:Packages:Nika1101:bkg:filename 
		print "New fits file loaded: " + filename
		String/G root:Packages:Nika1101:bkg:message="Converted "+filename+" - execution successful -  waiting for new file"
		doupdate
	elseif(bgcheck==3)
		svar filename = root:Packages:Nika1101:bkg:filename 
		print "New fits file loaded: " + filename
		String/G root:Packages:Nika1101:bkg:message="Converted "+filename+" - waiting for new file"
		doupdate
	elseif(bgcheck<0)
		String/G root:Packages:Nika1101:bkg:message="Failed to check directory"
		print "NIKA Bkg autoloader: Failed directory check"
		doupdate
		return 0
	else
		String/G root:Packages:Nika1101:bkg:message="Waiting for a new file to convert"
		doupdate
	endif
	lastRunTicks= ticks
	return 0
End

Function BGStartStopProc(ctrlName) : ButtonControl
	String ctrlName
	NVAR running= root:Packages:Nika1101:bkg:running
	if( CmpStr(ctrlName,"StartButton") == 0 )
		running= 1
		Button $ctrlName,rename=StopButton,title="Stop"
		String/G root:Packages:Nika1101:bkg:message="starting up"	
		svar Extension=root:Packages:Convert2Dto1D:DataFileExtension
		svar pilatusfiletype = root:Packages:Convert2Dto1D:pilatusfiletype
		string datafileextension = extension
		if(stringmatch("Pilatus",datafileextension))
			datafileextension = pilatusfiletype
		endif
		if(!stringmatch(".*",datafileextension))
			datafileextension = "."+datafileextension	
		endif
		string/g root:Packages:Nika1101:bkg:oldfilenames = IndexedFile(Convert2Dto1DDataPath, -1, DatafileExtension)
		CtrlNamedBackground NikaBGTask, burst=0, proc=NikaBGTask, period=60,dialogsOK=0, start
	endif
	if( CmpStr(ctrlName,"StopButton") == 0 )
		running= 0
		Button $ctrlName,rename=StartButton,title="Start"
		CtrlNamedBackground NikaBGTask, stop
		String/G root:Packages:Nika1101:bkg:message="Task paused. Press Start to resume."
	endif
End


function chkwaitfile(filename,size,path)
	string filename,path
	variable size
	variable fileref1,i,w
	Do
		open /R /z /p=$path fileref1 as filename
		sleep /t 5
		w+=1
	while(v_flag!=0 & w<200)
	if(v_flag != 0)
		print "Unable to open the file"
		return -2
	endif
	fstatus fileref1
	do 
		sleep /t 5
		fstatus fileref1
		i+=1
		if(i>200)
			//waited for 60 seconds already
			close fileref1
			return -1
		endif
	while(V_logEOF< size)
	close fileref1
	return 0
end


function BGCheckdir()
	string dfsave = getdatafolder(1)
	setdatafolder root:Packages:Nika1101:bkg
	string /g oldfilenames
	svar Extension=root:Packages:Convert2Dto1D:DataFileExtension
	svar pilatusfiletype = root:Packages:Convert2Dto1D:pilatusfiletype
	string datafileextension = extension
	variable waitfor2=0
	variable successfulexecution=0
	if(stringmatch("Pilatus",datafileextension))
		waitfor2=1
		datafileextension = pilatusfiletype
	endif
	if(!stringmatch(datafileextension,".*"))
		datafileextension = "."+datafileextension	
	endif
	string filenames = IndexedFile(Convert2Dto1DDataPath, -1, datafileextension)
	variable i
	variable newfilefound = 0,written=0
	string testfilename
	for(i=0;i<itemsinlist(filenames,";");i+=1)
		testfilename = stringfromlist(i,filenames,";")
		if(FindListItem(testfilename,oldfilenames) < 0)
			//filename is not in the old list of files  this filename is the one to open!
			string/g filename = testfilename
			newfilefound = 1
			String/G root:Packages:Nika1101:bkg:message="Found New File - Waiting for file to be written"
			doupdate
			if(waitfor2==1)
				string hilo,otherfilename,otherhilo
				Splitstring /e="^.*_(lo|hi)_.*$" testfilename,hilo
				if(!cmpstr("",hilo))
					//there is no tiling
				elseif(!cmpstr("hi",hilo))
					otherhilo = "lo"
					otherfilename = replacestring(hilo,testfilename,otherhilo)
					String/G root:Packages:Nika1101:bkg:message="Found "+testfilename+" - waiting for " + otherfilename
					doupdate
					do
						sleep /s 1
						GetFileFolderInfo /P=Convert2Dto1DDataPath /Q /Z otherfilename
						written = v_flag? 0:1
					while(written==0)
					String/G root:Packages:Nika1101:bkg:message="Found both files! "
					doupdate
					sleep /s 1
				elseif(!cmpstr("lo",hilo))
					otherhilo = "hi"
					otherfilename = replacestring(hilo,testfilename,otherhilo)
					String/G root:Packages:Nika1101:bkg:message="Found "+testfilename+" - waiting for " + otherfilename
					doupdate
					do
						sleep /s 1
						GetFileFolderInfo /P=Convert2Dto1DDataPath /Q /Z otherfilename
						written = v_flag? 0:1
					while(written==0)
					String/G root:Packages:Nika1101:bkg:message="Found both files! "
					doupdate
					sleep /s 1
				endif
				filenames = IndexedFile(Convert2Dto1DDataPath, -1, datafileextension)
			endif
//			variable imagesize = 2000
//			switch (chkwaitfile(filename,imagesize)) 	//check if filename is the right size in loop sleep .1 second between writes
//			case -2:
//				print "file could not be opened at all"
//				String/G root:Packages:Nika1101:bkg:message="file could not be opened even to check the size - skipping this file"
//				return 0
//			case -1:
//				print "timed out waiting for file to be written"
//				String/G root:Packages:Nika1101:bkg:message="timed out waiting for file to be written - skipping this file"
//				return 0
//			endswitch
//			String/G root:Packages:Nika1101:bkg:message="Found New File - Asking Nika to Convert the new file"
			NI1A_UpdateDataListBox()
			doupdate
			Wave/T  ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
			Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
			FindValue /TEXT=filename /TXOP=6 /Z ListOf2DSampleData
			if(v_value>=0)
				ListOf2DSampleDataNumbers = 0
				ListOf2DSampleDataNumbers[v_value] = 1
				
				NI1A_CheckParametersForConv()
				//set selections for using RAW/Converted data...
				NVAR LineProfileUseRAW=root:Packages:Convert2Dto1D:LineProfileUseRAW
				NVAR LineProfileUseCorrData=root:Packages:Convert2Dto1D:LineProfileUseCorrData
				NVAR SectorsUseRAWData=root:Packages:Convert2Dto1D:SectorsUseRAWData
				NVAR SectorsUseCorrData=root:Packages:Convert2Dto1D:SectorsUseCorrData
				svar commandstr=root:Packages:nika1101:bkg:CommandStr
				svar username=root:Packages:Convert2Dto1D:OutputDataName
				svar sernum=root:Packages:nika1101:sernum
				svar header=root:Packages:nika1101:headerinfo
				svar imnum=root:Packages:nika1101:imnum
				svar name1=root:Packages:nika1101:name1
				svar name2=root:Packages:nika1101:name2
				svar filename=root:Packages:Convert2Dto1D:FileNameToLoad
				LineProfileUseRAW=0
				LineProfileUseCorrData=1
				SectorsUseRAWData=0
				SectorsUseCorrData=1
				//selection done
				NI1A_LoadManyDataSetsForConv()	
				string commandstring = replacestring("*name*",commandstr,username)
				if(!cmpstr(commandstr,"")||!cmpstr(username,"") )
					commandstring=""
				else
					commandstring = replacestring("*name1*",commandstring,name1)
					commandstring = replacestring("*name2*",commandstring,name2)
					commandstring = replacestring("*filename*",commandstring,filename)
					commandstring = replacestring("*imnum*",commandstring,imnum)
					commandstring = replacestring("*sernum*",commandstring,sernum)
					string headername
					do
						splitstring /e=".*\*header-(.*)\*.*" commandstring, headername
						commandstring = replacestring("*header-"+headername+"*",commandstring,stringbykey(headername,header))
					while(strsearch(commandstring,"*header-",2)>0)
					commandstring = replacestring("*sernum*",commandstring,sernum)
					Execute /Q/Z commandstring
					if(v_flag==0)
						successfulexecution = 1
						SetVariable CommandStringBox,win=AutoLoadPanel,valueColor=(0,26112,0)
						SetVariable CommandStringBox,win=AutoLoadPanel,valueBackColor=(65535,65535,65535)
					else
						successfulexecution = -1
						SetVariable CommandStringBox,win=AutoLoadPanel,valueColor=(65535,65535,65535)
						SetVariable CommandStringBox,win=AutoLoadPanel,valueBackColor=(52224,0,0)
					endif
				endif
			else
				setdatafolder dfsave
				return -1
			endif
			break
		endif
	endfor
	oldfilenames = filenames
	setdatafolder dfsave
	if(newfilefound==1)
		if(successfulexecution==1)
			return 1
		elseif(successfulexecution==-1)
			return 2
		else
			return 3
		endif
	else
		return newfilefound
	endif
end
function groupplot(gn,matchstr,qn,[meshdata,revq,qpwr,plotq,imageq,contq,sm,numsm,qmin,qmax,qpnts,logq,logsurf,minen,maxen,colorstyle,addtograph,offpwr,stayindir,foldername,ignored,usecolorstyle,usestyle,atonm,envalues,smsurf,interpData,izero,addaxisnm,addlegend,nika,combine,cmbadjoverlap, porod,porodmin,porodmax,normv,normxval,normwid])
//Collects all the datawaves which have a matchstring in their names, adjusts the files as necessary and copiesthe data and a qwave (or d wave) into a new folder (default this is root:grazing)
// then the function meshs data into a 3d image (by default) and displays it or a contour of it and/or possibly plots data with an optional offset and colorscheme

//inputs and their purpose and use:
//x gn = graph name (the name of the set of data you are converting
//x matchstr = the match string (ie "*datarun1*" which all the data of interest shares in their names 
		//other options are "graph:xxx" which will get all the waves that are displayed in the xxx or top graph if "graph:top" or just "graph:"
//x qn = the q name that is of interest
//x usecolorstyle = wether to color the traces automatically
//x usestyle = the style to apply to a graph
//x colorstyle = the colorstyle for the traces in a plot of the image or contour plots generated by this program
//x foldername = default is grazing, a folder name to put all the file of interest (where they will then be edited, smoothed, etc), also the location of the mesh output, if any is needed
//x imageq = wether to display an image of the meshed data
//x contq = wether to display a contour map of the meshed data
//x revq = wether to reverse q or not (usually used in grazing if qy values are all negative)
//x qpwr = the power of q to multiply r by to scale it (ie for a kratky plot)
//x sm = the amount of smoothing to use
//x qmin = the minimum q value to keep in meshing (the program finds this by default if not specified)
//x qmax= the maximum q vale to keep """
//x qpnts = how many points in q for the final data default is the length of any of the qwaves
//x logq = wether to log the q values or not (this happens before minq, maxq, and qpnts are calculated, and before the new qwave is interpolated
//x logsurf = log the intensities of the resulting surface (if meshing data) 
//x minen = the other dimension of the mesh, assumed to be linear, any parameter needs to be specified but 280 is default (ie for energy) 
//x maxen = """"
//x Atonm = change Angstrom units to nanometers default is yes
//x numsm = number of smoothings to perform on data
//x plotq = wether to plot the rescaled and interpolated waves in a new graph
//x addtograph = wether to add new traces to an existing graph (only used if a graph with that graph name is already in existance - ignores wether trace actually exists or not)
//x offpwr = the multiplicitive offset used in a trace plot
//x stayindir = wether to move back to the starting directory when ending  - if creating 3D graphs it is helpful to set this parameter to 0, as the 3d graphing tools only search the current directory
//x meshdata = wether to actually mesh the data - if only plotting traces, set this to 0 and images and contours are completely ignored
//x envalues = either a name of a wave containing the values of energy (or whatever the parameter that varies from plot to plot) or "header-xxxx" where xxxx is a header variable which can be read as a number
			// example "header-BeamlineEnergy"  will attempt to use the header information and find a BeamlineEnergy key and display the value according to that 
//x smsurf = smooth the surface
//xxx interpData = 1 don't change the q-points and interpolate the intensity data, just use the x & y data given (can't be used in conjunction with mesh)
//x izero = wave of izero values to divide data by
//x addaxisnm = wether to add a mirror axis of nm to the top of plot (by default 1)
//x addlegend = wether to add legend of color bar (-1) to graph, by default 0
//x nika = to look for nika type files, or some other type
//x combine = string which if defined, will try to search the files for matching pairs, ie "_35_,_38_" will, if a file has the string "_35_", attempt to find the
		// corresponding file with "_38_" and conbine the two into one single file which will then be handeled by the rest of the code.
			// currently expanding to implment three or more elements, at which point the order of the strings is used in the sense that the
		// first two are cobbled together, then that combined set and the third, then that combined wave and the fourth etc.
//x cmbadjoverlap = wether to adjust the values of one of the waves when combining them - a list of values of the number of points to average in overlap region
		// the first element is for the overlap between wave 1 and 2, second is between 2 and three etc.
//x porod = wether to integrate or not
//x porodmin = minimum q location of porod integration
//x porodmax = maximum of porod
//x matchheaderkey = if it is called, only traces with header values that match will be collected
//x matcheheadervalue = the value of the corresponding matchheaderkey
//x matchheaderperc = the percentage error to match the value within the header
//x normv = 1 to normalize all curves to an average value (defaults to average of whole curve)
//x normxval = takes the value at x location on each r wave, and devides by that value
//x normwid = averages this range of values to either side of p
	string gn,matchstr,qn,colorstyle,foldername,usestyle,envalues,combine,cmbadjoverlap
	variable imageq,contq,revq,qpwr,sm,qmin,qmax,qpnts,logq,logsurf,minen,maxen,numsm,plotq,addtograph,offpwr,stayindir,meshdata,ignored,usecolorstyle,atonm,smsurf, interpData,addlegend,addaxisnm,nika, porod,porodmin,porodmax
	variable normv, normxval, normwid
	wave/d izero
	meshdata = paramisdefault(meshdata) ? 1 : meshdata
	ignored = paramisdefault(ignored) ? 0 : meshdata
	offpwr = paramisdefault(offpwr) ? 1 : offpwr
	stayindir = paramisdefault(stayindir) ? 1 : stayindir
	qmax = paramisdefault(qmax) ? 0 : qmax
	qmin = paramisdefault(qmin) ? 0 : qmin
	minen = paramisdefault(minen) ? 280 : minen
	maxen = paramisdefault(maxen) ? 290 : maxen
	logsurf = paramisdefault(logsurf) ? 1 : logsurf
	qpwr = paramisdefault(qpwr) ? 0 : qpwr
	numsm = paramisdefault(numsm)||numsm<1 ? 1 : numsm
	usecolorstyle = paramisdefault(usecolorstyle) ? 1 : usecolorstyle
	atonm = paramisdefault(atonm) ? 1 : atonm
	interpData = paramisdefault(interpData) ? 1 : interpData
	meshdata = interpData ? meshData : 0
	addaxisnm = paramisdefault(addaxisnm) ? 1 : addaxisnm
	addlegend = paramisdefault(addlegend) ? 0 : addlegend
	nika = paramisdefault(nika) ? 1 : nika
	porod = paramisdefault(porod) ? 0 : porod
	porodmin = paramisdefault(porodmin) ? .004 : porodmin
	porodmax = paramisdefault(porodmax) ? .007 : porodmax
	normv = paramisdefault(normv) ? 0 : normv
	normwid = paramisdefault(normwid) ? .001 : normwid
	
	
	if(paramisdefault(colorstyle)||whichlistitem(colorstyle,ctablist(),";",0,0)<0)
		colorstyle = "spectrumblack"
	endif
	if(paramisdefault(usestyle)||!exists(usestyle)==5)
		usestyle = ""
	endif
	if(paramisdefault(foldername))
		foldername = "grazing"
	endif
	if(paramisdefault(envalues))
		envalues = ""
	endif
	if(paramisdefault(combine))
		combine = ""
	endif
	variable combinetraces = paramisdefault(combine) ? 0 : 1
	variable cmbnum = itemsinlist(combine,",")
	if(cmbnum>1)
		make /t /o /n=(cmbnum) inname = stringfromlist(p,combine,",")
		if(!cmpstr("",inname[0])||!cmpstr("",inname[1]))
			combinetraces=0
		endif
	endif
	variable fromgraph = stringmatch(matchstr,"graph:*") ? 1 : 0
	variable addgraph
	string loname,workingdir
	string foldersave = getdatafolder(1)
	if(!datafolderexists("root:SAS") && !fromgraph)
		print "lineouts not loaded"
		return -1
	endif
	if(!datafolderexists("root:"+foldername))
		print "creating directory to hold traces"
		newdatafolder /o $("root:"+foldername)
	endif
	string lineoutsstr
	if(fromgraph)
		workingdir = getdatafolder(1)
		splitstring /e="^graph:(.*)$" matchstr,matchstr
		if(!cmpstr(matchstr,"top"))
			matchstr = winname(0,1)
		endif
		lineoutsstr = tracenamelist(matchstr,";",1+4)
		nika=0
	elseif(nika==1)
		workingdir = "root:SAS"
		setdatafolder $workingdir
		lineoutsstr = DataFolderDir(1)
		lineoutsstr = ReplaceString("FOLDERS:", lineoutsstr, "")
		lineoutsstr = ReplaceString(";\r", lineoutsstr, "")
		lineoutsstr = replacestring(",",lineoutsstr,";")
	elseif(nika==0)
		workingdir = getdatafolder(1)
		lineoutsstr = wavelist("r_"+matchstr,";","TEXT:0,DIMS:1")
	endif
	//lineoutsstr = sortlist(lineoutsstr)
	variable len = itemsinlist(lineoutsstr,";")
	variable getenfromwave=0
	if(len <1)
		print "no lineouts found in folder"
	endif
	print "Number of datasets found: " +num2str( len)
	setdatafolder $workingdir
	if((!paramisdefault(plotq))&&plotq>0)
		dowindow /f $("plot_"+gn)
		if(v_flag==0)
			display /k=1 /n=$("plot_"+gn)
			DoWindow /T $("plot_"+gn), "Plot of "+gn
			addtograph = 1
		else
			if(paramisdefault(addtograph))
				addtograph=0
			endif
		endif
	endif
	make/n=500 /d /o $("en_"+gn)
	wave envaluesw = $("en_"+gn)
	make /n=500 /d /o $("int_"+gn)
	wave intvaluesw = $("int_"+gn)
	if(stringmatch(envalues,"header-*"))
		getenfromwave=1
		splitstring /e="^header-(.*)$" envalues,envalues
	endif
	
	
	variable normvalue, normmin, normmax, minimumq
	variable cmbi,i,j=0
	string qnames="",rnames="",wnote,oldpath=""
	for(i=0;i<len;i+=1)
		loname = stringfromlist(i,lineoutsstr)
		if(nika==0&&fromgraph==0)
			splitstring /e="^_r(.*)$" loname,loname
		endif
		if(stringmatch(loname,matchstr)|| fromgraph)
			if( combinetraces )
				if(StringMatch(loname,"*"+inname[0]+"*"))
					string basicname = replacestring(inname[0],loname,"")
					make /o tempqwave1,temprwave1
					string saveinname = inname[0]
					for(cmbi=0;cmbi<cmbnum-1;cmbi+=1)
						string othername = replacestring(inname[0],loname,inname[cmbi+1])
						if(fromgraph)
							// loname  is a trace name on the graph
							If(cmbi>0)
								wave rwave1 = $(oldpath+loname)
								wave qwave1 = $(oldpath+replacestring("r_",loname,qn+"_"))

							else
								wave rwave1 = tracenametowaveref(matchstr,loname)
								wave qwave1 = XWaveRefFromTrace(matchstr,loname)
							endif
							wave rwave2 = tracenametowaveref(matchstr,othername)
							wave qwave2 = XWaveRefFromTrace(matchstr,othername)
						else
							string foldersave2=getdatafolder(1)
							if(nika)
								if(cmbi>0)
									setdatafolder oldpath
									loname=replacestring("r_",loname,"")
								else
									setdatafolder $loname
								endif
							endif
							wave qwave1 = $cleanupname(qn+"_" + loname,1)
							wave rwave1 = $("r_" + loname)
							if(nika)
								setdatafolder foldersave2
								if(datafolderexists(othername))
									setdatafolder $othername
								else
									continue
								endif
							endif
							wave qwave2 = $cleanupname(qn+"_" + othername,1)
							wave rwave2 = $("r_" + othername)
							setdatafolder foldersave2
						endif


						variable lowwave = wavemin(qwave1)<wavemin(qwave2) ? 1 : 2
						variable overlappoint, minqoverlap, maxqoverlap, wave1overlap, wave2overlap
						variable ovp=10
						if(!paramisdefault(cmbadjoverlap))
							ovp = str2num(stringfromlist(cmbi,cmbadjoverlap,","))
						endif
						if(lowwave==1)
							minqoverlap = qwave1[0]
							maxqoverlap = qwave2[inf]
							if(revq)
								overlappoint = qwave1[numpnts(qwave1)-ovp]
								wave1overlap = faveragexy(qwave1,rwave1,qwave1[numpnts(qwave1)-ovp],qwave1[numpnts(qwave1)-ovp-ovp]  )
								wave2overlap = faveragexy(qwave2,rwave2,qwave1[numpnts(qwave1)-ovp],qwave1[numpnts(qwave1)-ovp-ovp]  )
							else
								overlappoint = qwave2[ovp]
								wave1overlap = faveragexy(qwave1,rwave1,qwave2[ovp],qwave2[ovp+ovp]  )
								wave2overlap = faveragexy(qwave2,rwave2,qwave2[ovp],qwave2[ovp+ovp]  )
							endif
							if(!paramisdefault(cmbadjoverlap))
								rwave1 *= (wave2overlap/wave1overlap)
							endif
						else
							if(revq)
								overlappoint = qwave2[numpnts(qwave2)-ovp]
								wave1overlap = faveragexy(qwave1,rwave1,qwave2[numpnts(qwave2)-ovp],qwave2[numpnts(qwave2)-ovp-ovp] )
								wave2overlap = faveragexy(qwave2,rwave2,qwave2[numpnts(qwave2)-ovp],qwave2[numpnts(qwave2)-ovp-ovp] )
							else
								overlappoint = qwave1[ovp] 
								wave1overlap = faveragexy(qwave1,rwave1,qwave1[ovp],qwave1[ovp+ovp] )
								wave2overlap = faveragexy(qwave2,rwave2,qwave1[ovp],qwave1[ovp+ovp])
							endif
							if(!paramisdefault(cmbadjoverlap))
								rwave2 *= (wave1overlap/wave2overlap)
							endif
						endif
						variable qminc = lowwave==1 ? wavemin(qwave1) : wavemin(qwave2)
						variable qmaxc = lowwave==1 ? wavemax(qwave2) : wavemax(qwave1)
						variable qstepc = lowwave==1 ? abs(qwave1[1]-qwave1[2]) : abs(qwave2[1]-qwave2[2])
						if( (qmaxc-qminc)/qstepc >10000)  //deal with possibilities of arbitrarily low q - limit points to 1000
							qstepc = (qmaxc-qminc)/10000
						endif
						variable nqpntsc = floor((qmaxc-qminc)/qstepc)
						if(nqpntsc/2!=floor(nqpntsc/2))
							nqpntsc -=1
						endif
						if(nqpntsc>0)
							string outputname = replacestring("'",replacestring("r_",basicname,""),"")
							if(nika)
								newdatafolder /o/s $outputname
								make /d/o/n=(nqpntsc) $(qn+"_"+outputname) = p*qstepc+qminc //make evenly spaced q wave data
								make /d /o/n=(nqpntsc) $("r_"+outputname)
								wave oldqwave = $(qn+"_"+outputname)
								wave oldrwave = $("r_"+outputname)
								setdatafolder foldersave2
							else
								make /d/o/n=(nqpntsc) $(qn+"_"+outputname) = p*qstepc+qminc //make evenly spaced q wave data
								make /d /o/n=(nqpntsc) $(outputname)
								wave oldqwave = $(qn+"_"+outputname)
								wave oldrwave = $(outputname)
							endif
							duplicate /free oldrwave, low_or_high
							low_or_high =  (oldqwave[p]<overlappoint&&lowwave==1)||(oldqwave[p]>overlappoint&&lowwave==2) ? 1 : 0
							smooth /B=10 ovp, low_or_high
							oldrwave = low_or_high* interp(oldqwave[p],qwave1,rwave1) +(1-low_or_high)*interp(oldqwave[p],qwave2,rwave2)
							//oldrwave = (oldqwave[p]<overlappoint&&lowwave==1)||(oldqwave[p]>overlappoint&&lowwave==2) ? interp(oldqwave[p],qwave1,rwave1) : interp(oldqwave[p],qwave2,rwave2)
							setscale /p x, qminc , qstepc , oldrwave
							note oldrwave, note(rwave1)
							note oldqwave, note(qwave1)
							//appendtograph /w=$("comb_"+gn) oldrwave vs oldqwave
						endif
						if(lowwave==1)
							if(!paramisdefault(cmbadjoverlap))
								rwave1 /= (wave2overlap/wave1overlap)
							endif
						else
							if(!paramisdefault(cmbadjoverlap))
								rwave2 /= (wave1overlap/wave2overlap)
							endif
						endif
						if(cmbi<cmbnum-2)
							string foldersave3 = getdatafolder(1)
							setdatafolder getwavesdatafolder(qwave1,1)
							oldpath = getwavesdatafolder(qwave1,1)
							duplicate/O oldqwave, $(qn+"_"+replacestring("r_",replacestring("'",replacestring(inname[0],loname,"~"),""),""))
							duplicate/O oldrwave, $("r_"+replacestring("r_",replacestring("'",replacestring(inname[0],loname,"~"),""),""))
							loname = replacestring(inname[0],loname,"~")
							
							inname[0]="~"
							setdatafolder foldersave3
						endif
					endfor
					loname = outputname
					inname[0] = saveinname
				else
					continue
				endif
			else
				if(fromgraph)
					// loname  is a trace name on the graph
					wave oldrwave = tracenametowaveref(matchstr,loname)
					wave oldqwave = XWaveRefFromTrace(matchstr,loname)
				else
					if(nika)
						setdatafolder $loname
					endif
					wave oldqwave = $cleanupname(qn+"_" + loname,1)
					wave oldrwave = $("r_" + loname)
				endif
			endif
			string qname = "root:"+foldername+":'"+nameofwave(oldqwave)+"'"
			string rname = "root:"+foldername+":'"+nameofwave(oldrwave)+"'"
			qnames +=qname+";"
			rnames +=rname+";"
			make/o $(qname)
			wave qwave= $(qname)
			make/o $(rname)
			wave rwave= $(rname)
			duplicate/o oldqwave,qwave
			duplicate/o oldrwave,rwave
			setscale /P x,0,1,rwave
			setscale /P x,0,1,qwave
			if(!(paramisdefault(revq)||revq==0)) //If revq is not default AND not equal to 0, then invert q
				qwave*=-1
			endif
			if(!cmpstr("d",qn)&&ignored==0&&Atonm) //if we are not ignoring the fact that dspacing is different than q, and d is also the "qwave", (and the conversion to nm is chosen)
				qwave/=10
			elseif(Atonm) //(if only conversion to nm is chosen, but either d is not the qwave or we are ignoring the fact that d is the q wave, then change the q wave to nanometers)
				qwave*=10
			endif
			if(!cmpstr("d",qn)&&ignored==0) //if we are not ignoring the fact that dspacing is different than q, and d is also the "qwave" then do the kratcky plotting correctly
				rwave *=(2*pi/qwave)^qpwr
			else
				rwave *=qwave^qpwr
			endif	

			If( InterpData )
				duplicate /free qwave, oldq
				
				if(logq)
					//qwave = ln(oldq)
					duplicate /free oldq, tempoldq
					tempoldq = abs(tempoldq)
					wavestats /Q /Z /m=1 tempoldq
					qpnts = paramisdefault(qpnts) ? v_npnts : qpnts
					make /free/n=(qpnts) qwave=0
					qmax = paramisdefault(qmax) ? ln(v_max) : ln(qmax)
					minimumq = paramisdefault(qmin) ? ln(wavemin(tempoldq)) : ln(qmin)
					qwave = exp(minimumq + (qmax-minimumq)*p/qpnts) // evenly spaced log scale
					note qwave, note(oldq) + ";GroupPlot rescaled:Logq;qmax="+num2str(qmax)+";qmin:"+num2str(minimumq)+";"
				else
					wavestats /Q /Z /m=1 oldq
					qpnts = paramisdefault(qpnts) ? v_npnts : qpnts
					make /free/n=(qpnts) qwave=0
					if(revq)
						minimumq = paramisdefault(qmin) ? v_max : qmin
						qmax = paramisdefault(qmax) ? v_min : qmax
					else
						minimumq = paramisdefault(qmin) ? v_min : qmin
						qmax = paramisdefault(qmax) ? v_max : qmax
					endif
					qwave = minimumq + (qmax-minimumq)*p/qpnts
				endif
				
				duplicate /o rwave,oldr
				make /free/n=(qpnts) rwave
				note rwave, note(oldr) +  ";GroupPlot created copy of:"+getwavesdatafolder(oldr,2)+";"
				// remove all nans from rwave and qwave
			//	qwave = rwave[p]*0==0 ? qwave[p] : 1000000000000
			//	sort qwave, qwave, rwave
			//	findvalue /v=(1000000000000) qwave
			//	if(v_value>0)
			//		deletepoints v_value, (dimsize(qwave,0)-v_value), qwave, rwave
			//	endif
				// remove all nans from oldr and oldq
				oldq = oldr[p]*0==0 ? oldq[p] : 1000000000000
				sort oldq, oldq, oldr
				findvalue /v=(1000000000000) oldq
				if(v_value>0)
					deletepoints v_value, (dimsize(oldq,0)-v_value), oldq, oldr
				endif
				
				//rwave = logq? mean(oldr,Binarysearch(oldq, qwave[p-1] ),Binarysearch(oldq, qwave[p]))  : mean(oldr,Binarysearch(oldq,qwave[p-1]),Binarysearch(oldq,qwave[p]))
				// I need to add a more inteppigent algorithym, which interpolates if the local destination spacing is smaller than the source, but averages if the destination spacing is larger
				// this is because with log spacing, regions may be larger, and regions may be smaller
				duplicate /free qwave, spacingwave
				deletepoints 0,1,spacingwave
				spacingwave = binarysearch(oldq,qwave[p])-binarysearch(oldq,qwave[p+1]) <= 1 ? 0 : 1 // if spacing of destination is smaller, there will be 0 or 1 points between each qwave point - 0, if spacing of destination is larger - 1
				rwave = spacingwave ? mean(oldr,binarysearch(oldq,qwave[p]) , binarysearch(oldq,qwave[p+1])) : interp(qwave,oldq,oldr)
				 // we have found the q values with the real q values, now it is time to reverse the q wave if we are supposed to
				// qwave *= revq ? -1 : 1
				//rwave = mean(oldr,Binarysearch(oldq,qwave[p-1]),Binarysearch(oldq,qwave[p]))
				//redimension /n=(qpnts) rwave,qwave
//				string unLogQname=
			endif
			
			if( (!paramisdefault(sm) )&& sm>0)
				smooth /s=4 /E=3 sm,rwave
			endif
			
			//// Porod Integration - added by John T. //edited by eliot
			if(porod) 
				// already calculated above //rwave_INT = oldqwave*oldqwave*oldrwave///calculate I*q^2 that matche SAS NIKA output to calculate integral
				intvaluesw[j] = areaXY(qwave, rwave, porodmin, porodmax)
			endif 
			//
				// remove all nans from rwave and qwave
			qwave = qwave[p]*rwave[p]*0==0 ? qwave[p] : 1000000000000
			sort qwave, qwave, rwave
			findvalue /v=(1000000000000) qwave
			if(v_value>0)
				deletepoints v_value, (dimsize(qwave,0)-v_value), qwave, rwave
			endif
				// nans are removed
			if(normv)
				
				if(paramisdefault(normxval))
					normvalue = mean(rwave)
				else
					findlevel /q QWAVE, (normxval-normwid)
					if(V_LevelX < 0)
						normmin = 0
					else
						normmin = V_LevelX
					endif
					findlevel /q QWAVE, (normxval+normwid)
					if(V_LevelX < 0)
						normmax = dimsize(rwave,0)-1
					else
						normmax = V_LevelX
					endif
					normvalue = mean(rwave,normmin,normmax)
				endif
				rwave /= normvalue
				
			endif
			
			if( !paramisdefault(izero) )
				rwave/=izero[j]
			endif
		//add to plot if needed
			if(plotq)
				loname =  replacestring("'",loname,"")
				//duplicate/o $rname, $("root:"+foldername+":'ro_" + loname+"'")
				duplicate/o rwave, $("root:"+foldername+":"+possiblyquotename(cleanupname("ro_" + loname,1)))
				wave roff= $("root:"+foldername+":"+possiblyquotename(cleanupname("ro_" + loname,1)))
				//duplicate/o $qname, $("root:"+foldername+":'qo_" + loname+"'")
				duplicate/o qwave, $("root:"+foldername+":"+possiblyquotename(cleanupname("qo_" + loname,1)))
				wave qoff= $("root:"+foldername+":"+possiblyquotename(cleanupname("qo_" + loname,1)))
				roff *=offpwr^j
				//if(logq)
				//	qoff = exp(qoff)
				//endif
				if(addtograph && !logq) //plot unlog here
					appendtograph /w=$("plot_"+gn) $("root:"+foldername+":"+possiblyquotename(cleanupname("ro_" + loname,1))) vs $("root:"+foldername+":"+possiblyquotename(cleanupname("qo_" + loname,1)))
				elseif( addtograph && logq)
					appendtograph /w=$("plot_"+gn) $("root:"+foldername+":"+possiblyquotename(cleanupname("ro_" + loname,1))) vs $("root:"+foldername+":"+possiblyquotename(cleanupname("qo_" + loname,1)))			
				endif
			endif
			if(getenfromwave)
				envaluesw[j] = str2num(stringbykey(envalues,note(rwave),"=",";"))
			endif
			j+=1
			setdatafolder $workingdir
		endif
	endfor
	variable numwaves = itemsinlist(qnames)-1
	print "Number of waves loaded: "+num2str(numwaves)
	if(numwaves==0)
		return 0
	endif
	if(!cmpstr(envalues,""))
		envaluesw = minen+(maxen-minen)*p/numwaves
		redimension /n=(numwaves) envaluesw
	elseif(getenfromwave)
		redimension /n=(numwaves) envaluesw
	else
		wave envaluesw = $envalues
	endif
	redimension /n=(numwaves) intvaluesw
	maxen = wavemax(envaluesw)
	minen = wavemin(envaluesw)
	if(porod)
		display /N=$("porod_"+gn) /k=1 intvalues vs envaluesw as "Porod Integration of "+Gn
	endif	
	//color the traces in the plot if needed
	if(plotq&&addtograph)
		ModifyGraph /w=$("plot_"+gn) log=1
		TextBox/w=$("plot_"+gn) /C/N=text0/F=0/A=LT/X=0.00/Y=0.00/E ("\Z14"+gn)
		string tracelist = TraceNameList(("plot_"+gn),";",1),tracename
		if(usecolorstyle)
			variable ntraces = Itemsinlist(tracelist)

			colortab2wave $colorstyle
			variable colorlen = dimsize(m_colors,0)
			make/n=(colorlen)/d/o col_r_wave,col_g_wave ,col_b_wave
			make/n=(colorlen,3)/d/o colscalewave
			wave m_colors

			col_r_wave = m_colors[mod(p,colorlen)][0]
			col_g_wave = m_colors[mod(p,colorlen)][1]
			col_b_wave = m_colors[mod(p,colorlen)][2]
			colscalewave[][0] = col_r_wave[p]
			colscalewave[][1] = col_g_wave[p]
			colscalewave[][2] = col_b_wave[p]
			make/n=(colorlen) /d/o colorindex = p

			variable enrange = maxen-minen
			variable mcolorsmax = dimsize(m_colors,0)
			duplicate/o envaluesw,scaledenvalues
			scaledenvalues = (envaluesw[p]-minen)*mcolorsmax/enrange
			
			for(i=0;i<ntraces;i+=1)
				tracename = stringfromlist(i,tracelist)
				modifygraph/w=$("plot_"+gn) rgb($tracename)=(interp(scaledenvalues[i],colorindex,col_r_wave),interp(scaledenvalues[i],colorindex,col_g_wave),interp(scaledenvalues[i],colorindex,col_b_wave))
			endfor
			killwaves M_colors,col_b_wave,col_r_wave,col_g_wave,colorindex
			setscale/I x, minen,maxen, colscalewave
			if(addlegend==-1)
				ColorScale/w=$("plot_"+gn)/C/N=text1 cindex=colscalewave
			elseif(addlegend == 1)
				legend/w=$("plot_"+gn)
			endif
		endif
		
		if(addaxisnm)
			doupdate
			//struct WMAxisHookStruct info
			addQ2nmaxisplain()
		endif
		if(cmpstr("",usestyle)!=0)
			execute usestyle+"()"
		endif
	endif
	
	//MESH data
	if(meshdata)
		variable maxq =inf,minq=-inf,qsteps =0,rlen
		for(i=0;i<numwaves;i+=1)
			wave qwave=$stringfromlist(i,qnames)
			minq=qwave[0]>minq?qwave[0]:minq
//				if(minq==0)
//					print qwave
//				endif
			maxq=qwave[inf]<maxq?qwave[inf]:maxq
			qsteps = numpnts(qwave)
			//cycle through the waves again, finding the max and min q values
		endfor
		//create matrix with appropriate dimensions
		setdatafolder $("root:"+foldername)
		make /d/o /n=(qsteps*2,numwaves) $(gn+"nsc")
		wave surf = $(gn+"nsc")
		setscale /i x,minq,maxq,surf
		setscale /i y,minen,maxen,surf
		make /n=(numwaves) /o/t qnamewave = stringfromlist(p,qnames), rnamewave = stringfromlist(p,rnames)
		sort envaluesw, envaluesw, qnamewave, rnamewave // this sorts out the waves in order, so that at least the wave will be monotonic so interpolation will work
		for(i=0;i<numwaves;i+=1)
			//cycle through the waves one more time, interpolating them into matrix
			wave qwave=$qnamewave[i] //$stringfromlist(i,qnames)
			wave rwave=$rnamewave[i] //$stringfromlist(i,rnames)
			surf[][i] = interp(x,qwave,rwave)
		endfor
		//the q values are set, envalues still holds the energy values for the rows.  We want to rescale the data in this direction now, so each column needs to be reinterpolated into a new surface
		make /d/o /n=(qsteps*2,numwaves*10) $(gn)
		wave surfsc = $(gn)
		setscale /i x,minq,maxq,surfsc
		setscale /i y,minen,maxen,surfsc
		make /d/o /n=(numwaves) intensitywaveataen
		for(i=0;i<qsteps*2;i+=1)
			//cycle through the q values of surf
			//surfsc[i][] = interp(ENERGY VALUE I WANT,ENERGY WAVE I HAVE,Intensities vs energy that I HAVE)
			intensitywaveataen = surf[i][p]
			surfsc[i][] = interp(y,envaluesw,intensitywaveataen)
		endfor
		
		//plot matrix
		if(logsurf)
			surf = log(surf)
			surfsc = log(surfsc)
		endif
		if(!paramisdefault(smsurf)&&sm)
			smooth /DIM=1 sm,surfsc

		endif
		duplicate /o surfsc,lastout
		if((!paramisdefault(imageq))&&imageq>0)
			dowindow /f $("img_"+gn)
			if(!v_flag)
				newimage /k=1 /n=$("img_"+gn) surfsc
				DoWindow /T $("img_"+gn), "Image plot of "+gn
				ModifyImage /w=$("img_"+gn) $gn ctab= {*,*,$colorstyle,0}
			endif
		endif
		if(!paramisdefault(contq) &&contq>0)
			dowindow /f $("cont_"+gn)
			if(v_flag)
				RemoveContour /w=$("cont_"+gn) $gn
			else
				Display/k=1 /n=$("cont_"+gn) as ("Contour plot of "+gn)
			endif
			AppendMatrixContour /w=$("cont_"+gn) $gn
			ModifyContour /w=$("cont_"+gn) $gn ctabLines={*,*,$colorstyle,0},autoLevels={*,*,100}
			ModifyContour /w=$("cont_"+gn) $gn labels=0
		endif
	endif
	if(stayindir)
		setdatafolder foldersave
	endif
end
Function TransAx_QtoD(w, x)
	Wave/Z w
	Variable x
	return 2*pi/x 
end


function addQ2nmaxis(info)
	struct WMAxisHookStruct &info
	string foldersave = getdatafolder(1)
	NewDataFolder /s/o root:packages:nika1101
	newdatafolder /s/o TransformedAxes
	getaxis /q bottom
	variable mind = 10^(floor(log(2*pi/v_max) ) )
	variable maxd = 10^(ceil(log(2*pi/v_min) ) )
	maxd = 0 != maxd*0 ? 1000 : maxd
	mind = 0 != mind*0 ? 1 : mind
	string wname=winname(0,1)
	make /o /n=(10*log(maxd/mind) +1) $("tv"+wname)
	make /o /t /n=((10*log(maxd/mind) +1),2) $("tl"+wname)
	wave tickvals = $("tv"+wname)
	wave /t ticklabels = $("tl"+wname)
	variable i,j=0
	for(i=0;i<(10*log(maxd/mind) +1);i+=1)
		//figure out which order of 10 we are at
		variable order = floor(i/10) +log(mind) // 0 for 0 to 9, 1 for 10 to 19, 2 for 20 to 29
		variable digit = 10*(i/10-floor(i/10))
		if(digit>1.1)
			tickvals[j] = 2*pi/(10^order*digit)
			if((10*log(maxd/mind) +1)>32 )
				ticklabels[j][0]= ""
			else
				ticklabels[j][0]=  " \r\Zr080"+num2str(digit)
			endif
			ticklabels[j][1]="Minor"
			j+=1
		endif
	endfor
	for(i=0;i<(10*log(maxd/mind) +1);i+=1)
		//figure out which order of 10 we are at
		order = floor(i/10) +log(mind) // 0 for 0 to 9, 1 for 10 to 19, 2 for 20 to 29
		digit = 10*(i/10-floor(i/10))
		if(digit==0)
			tickvals[j] = 2*pi/(10^order + digit)
			if((10*log(maxd/mind) +1)>32 )
				ticklabels[j][0]=""+num2str(10^order)
			else
				ticklabels[j][0]=""+num2str(10^order)+"\Zr080\r"
			endif
			ticklabels[j][1]="Major"
			j+=1
		endif
	endfor
	redimension /n=(j,2) ticklabels
	redimension /n=(j) tickvals
//	ModifyGraph margin(left)=50,margin(bottom)=50,margin(top)=50,margin(right)=14
//	ModifyGraph grid(left)=2,grid(bottom)=2
//	ModifyGraph mirror(left)=1
//	ModifyGraph lblPosMode(bottom)=1
//	ModifyGraph lblLatPos(bottom)=0
//	ModifyGraph mirror(bottom)=0
//	Label left "Intenisty * q\\S2\\M [nm\\S-2\\M]"
//	Label bottom "q [nm\\S-1\\M]"
	setdimlabel 1,1,'Tick Type',tickLabels
//	print getdimlabel(ticklabels,1,-1)
//	NewFreeAxis/O/T MT_bottom
//	ModifyFreeAxis/Z MT_bottom,master= bottom,hook= addQ2nmaxis
//	ModifyGraph userticks(MT_bottom)={tickVals,tickLabels}
//	ModifyGraph lblMargin(MT_bottom)=0,lblPosMode(MT_bottom)=1,lblLatPos(MT_bottom)=0
//	ModifyGraph freePos(MT_bottom)=0
//	Label MT_bottom "2\\F'Symbol'p\\F'Arial'/q [nm]"
//	ModifyGraph axThick=2,stThick=1,ftThick=1,ttThick=1
//	ModifyGraph gfSize=14
//	ModifyGraph log=1
//	ModifyGraph tick=2
//	ModifyGraph standoff=0,minor=1
	setdatafolder foldersave
end

function addQ2nmaxisplain()
	string foldersave = getdatafolder(1)
	NewDataFolder /s/o root:packages
	NewDataFolder /s/o nika1101
	NewDataFolder /s/o TransformedAxes
	getaxis /q bottom
	variable mind = 10^(floor(log(2*pi/v_max) ) )
	variable maxd = 10^(ceil(log(2*pi/v_min) ) )
	string wname=winname(0,1)
	make /o /n=(10*log(maxd/mind) +1) $("tv"+wname)
	make /o /t /n=((10*log(maxd/mind) +1),2) $("tl"+wname)
	wave tickvals = $("tv"+wname)
	wave /t ticklabels = $("tl"+wname)
	variable i,j=0
	for(i=0;i<(10*log(maxd/mind) +1);i+=1)
		//figure out which order of 10 we are at
		variable order = floor(i/10) +log(mind) // 0 for 0 to 9, 1 for 10 to 19, 2 for 20 to 29
		variable digit = 10*(i/10-floor(i/10))
		if(digit>1.1)
			tickvals[j] = 2*pi/(10^order*digit)
			if((10*log(maxd/mind) +1)>32 )
				ticklabels[j][0]= ""
			else
				ticklabels[j][0]=  " \r\Zr080"+num2str(digit)
			endif
			ticklabels[j][1]="Minor"
			j+=1
		endif
	endfor
	for(i=0;i<(10*log(maxd/mind) +1);i+=1)
		//figure out which order of 10 we are at
		order = floor(i/10) +log(mind) // 0 for 0 to 9, 1 for 10 to 19, 2 for 20 to 29
		digit = 10*(i/10-floor(i/10))
		if(digit==0)
			tickvals[j] = 2*pi/(10^order + digit)
			if((10*log(maxd/mind) +1)>32 )
				ticklabels[j][0]=""+num2str(10^order)
			else
				ticklabels[j][0]=""+num2str(10^order)+"\Zr080\r"
			endif
			ticklabels[j][1]="Major"
			j+=1
		endif
	endfor
	redimension /n=(j,2) ticklabels
	redimension /n=(j) tickvals
	ModifyGraph margin(left)=50,margin(bottom)=50,margin(top)=50,margin(right)=14
	//ModifyGraph grid(left)=2,grid(bottom)=2
	ModifyGraph mirror(left)=1
	ModifyGraph lblPosMode(bottom)=1
	ModifyGraph lblLatPos(bottom)=0
	ModifyGraph mirror(bottom)=0
	Label left "Intenisty * q\\S2\\M [nm\\S-2\\M]"
	Label bottom "q [nm\\S-1\\M]"
	setdimlabel 1,1,'Tick Type',tickLabels
	print getdimlabel(ticklabels,1,-1)
	NewFreeAxis/O/T MT_bottom
	ModifyFreeAxis/Z MT_bottom,master= bottom,hook= addQ2nmaxis
	ModifyGraph userticks(MT_bottom)={tickVals,tickLabels}
	ModifyGraph lblMargin(MT_bottom)=0,lblPosMode(MT_bottom)=1,lblLatPos(MT_bottom)=0
	ModifyGraph freePos(MT_bottom)=0
	Label MT_bottom "2\\F'Symbol'p\\F'Arial'/q [nm]"
	ModifyGraph axThick=2,stThick=1,ftThick=1,ttThick=1
	ModifyGraph gfSize=14
	ModifyGraph log=1
	ModifyGraph tick=2
	ModifyGraph standoff=0,minor=1
	Label MT_bottom "2\\F'Symbol'p\\F'Arial'/q [nm]"
	Label MT_bottom "d-spacing [nm]"
	Label left "Intensity"
	Label bottom "Momentum Transfer q [nm\\S-1\\M]"
	setdatafolder foldersave
end
function BSnA2Photons(beamstopna) // returns number of photons
	variable beamstopna
	return beamstopna*9.45e8 //9.45 e 8 photons-eV/nanoamp
end

function PDnA2Photons(beamstopna, energyeV) // returns number of photons given the nanoamps read on a photodiode, and the photon energy
	// eliot is editing Jan 2015
	// this isn't returning the number of photons, but rather then number of photons * eV  
	//  we need to devide by the energy of the X-ray which produced this current to get the correct number of photons
	variable beamstopna, energyeV
	return beamstopna*2.8e12 / (energyeV) // nA * 9.8e8 (photons * eV/nA/sec) / eV = photons (possibly per second depending on if measurement is divided by exposure time
end


function UpdateIzeroList()
	string foldersave=getdatafolder(1)
	setdatafolder root:Packages:nika1101:
	wave /t loadedizeros
	setdatafolder i0data
	string ioname,I0liststr = wavelist("I0corr*",";","")
	setdatafolder ::
	variable len = itemsinlist(I0liststr)
	if(len <1)
		loadedizeros= {"no I0 waves found in folder"}
		setdatafolder foldersave
		return 0
	endif
	make/o/t /n=(len) loadedizeros
	variable i,j=0
	string ionote,ionum,i0string,pol,os,createddate,filename
	for(i=0;i<len;i+=1)
		ioname = stringfromlist(i,I0liststr)
		splitstring /e="^I0corr(.*)" ioname,ionum
		setdatafolder i0data
		ionote = note($ioname)
		setdatafolder ::
		pol= stringbykey("pol",ionote)
		os = stringbykey("os",ionote)
		createddate = stringbykey("CreationDate",ionote)
		filename = stringbykey("File",ionote)
		loadedizeros[i] = ionum + " OS" +os+" POL=" +pol+" " + createddate +" - "+ filename
	endfor
	setdatafolder foldersave
	return 0
end

Function Nika1101BG_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NikaBG()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function LoadI0panel() : Panel
	string foldersave = getdatafolder(1)
	setdatafolder root:packages:nika1101
	DoWindow  LoadIzeroPanel
	if(V_Flag)
		DoWindow/F NI1_FitsLoaderPanel
		setdatafolder root:packages:nika1101
	else
		if(!exists("i0photodiode"))
			string /g i0photodiode = "Photodiode"
		else
			svar i0photodiode
		endif
		if(!exists("i0izero"))
			string /g i0Izero = "Izero"
		else
			svar i0Izero
		endif
		if(!exists("i0hline"))
			variable /g i0hline=9
		else
			nvar i0hline
		endif
		if(!exists("i0oslocation"))
			variable /g i0oslocation=4
		else
			nvar i0oslocation
		endif
		if(!exists("i0polarization"))
			variable /g i0polarization=-1
		else
			nvar i0polarization
		endif
		if(!exists("i0offset"))
			variable /g i0offset=0
		else
			nvar i0offset
		endif
		if(!exists("pdoffset"))
			variable /g pdoffset=0
		else
			nvar pdoffset
		endif
		PauseUpdate; Silent 1		// building window...
		NewPanel /K=1 /W=(820,69,1044,326) as "Load Izero panel"
		ModifyPanel fixedSize=1
		SetVariable OSval,pos={61,30},size={148,15},title="Order Sorter Value:   "
		SetVariable OSval,value= root:Packages:Nika1101:i0oslocation
		SetVariable hlineval,pos={7,6},size={201,15},title="Line containing Column names   "
		SetVariable hlineval,value= root:Packages:Nika1101:i0hline
		SetVariable i0val,pos={78,79},size={111,15},title="I0 to load: "
		SetVariable i0val,value= root:Packages:Nika1101:i0Izero
		SetVariable pdval,pos={10,101},size={195,15},title="Photodiode Scan to load"
		SetVariable pdval,value= root:Packages:Nika1101:i0photodiode
		Button LOADI0,pos={81,175},size={101,41},proc=Loadi0file_button,title="Load File"
		SetVariable polval,pos={63,54},size={146,15},title="Polarization Value:   "
		SetVariable polval,value= root:Packages:Nika1101:i0polarization
		SetVariable pdval1,pos={10,101},size={195,15},title="Photodiode Scan to load"
		SetVariable pdval1,value= root:Packages:Nika1101:i0photodiode
		SetVariable pdoffset,pos={56,128},size={146,15},title="Photodiode Offset:   "
		SetVariable pdoffset,value= root:Packages:Nika1101:pdoffset
		SetVariable i0offsetinput,pos={58,146},size={146,15},title="I0 Offset:    "
		SetVariable i0offsetinput,value= root:Packages:Nika1101:i0offset
	endif
	setdatafolder foldersave
End

Function Loadi0file_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string foldersave = getdatafolder(1)
			setdatafolder root:packages:nika1101
			svar i0photodiode,i0Izero
			nvar i0hline,i0oslocation,i0polarization
			nvar i0offset, pdoffset
			Loadi0(i0oslocation,i0Izero,i0photodiode,izerooff = i0offset,pdoff=pdoffset, hLine=i0hline,polarization = i0polarization)
			setdatafolder foldersave
			dowindow /k LoadIzeroPanel
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_5(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			LoadI0panel()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function GI_ReHistImage()
	string foldersave = getdatafolder(1)
	setDataFolder root:Packages:Convert2Dto1D
	wave data = CCDImageToConvert
	wave rawdata = importeddata
	string oldnote = note(rawdata)
	wave/z mask = M_ROIMask
	wave/z rawmask = loadedmask
	duplicate/o rawdata, data
	if(waveexists(rawmask))
		duplicate/o rawmask, mask
	else
		duplicate/o rawdata, mask
	endif
	if(!waveexists(data))
		print "no data wave loaded to change"
		return 0
	endif
		
	//	string NoteStr=note(Q2DWave)
	//	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance		//in millimeters
	//	NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength							//in A
	//	NVAR PixelSizeX = root:Packages:Convert2Dto1D:PixelSizeX								//in millimeters
	//	NVAR PixelSizeY = root:Packages:Convert2Dto1D:PixelSizeY								//in millimeters
	//	NVAR beamCenterX=root:Packages:Convert2Dto1D:beamCenterX
	//	NVAR beamCenterY=root:Packages:Convert2Dto1D:beamCenterY
	//	NVAR HorizontalTilt=root:Packages:Convert2Dto1D:HorizontalTilt
	//	NVAR VerticalTilt=root:Packages:Convert2Dto1D:VerticalTilt
	//	string oldSampleToCCDDistance = stringByKey("SampleToCCDDistance", NoteStr , "=")
	//	string oldBeamCenterX = stringByKey("BeamCenterX", NoteStr , "=")
	//	string oldBeamCenterY = stringByKey("BeamCenterY", NoteStr , "=")
	//	string oldPixelSizeX = stringByKey("PixelSizeX", NoteStr , "=")
	//	string oldPixelSizeY = stringByKey("PixelSizeY", NoteStr , "=")
	//	string oldHorizontalTilt = stringByKey("HorizontalTilt", NoteStr , "=")
	//	string oldVerticalTilt = stringByKey("VerticalTilt", NoteStr , "=")
	//	string oldWavelength = stringByKey("Wavelength", NoteStr , "=")
	//	variable diff6=cmpstr(oldSampleToCCDDistance,num2str(SampleToCCDDistance))!=0 || cmpstr(oldBeamCenterX,num2str(BeamCenterX))!=0 || cmpstr(oldBeamCenterY,num2str(BeamCenterY))!=0
	//	variable diff7 = cmpstr(oldPixelSizeX,num2str(PixelSizeX))!=0 || cmpstr(oldPixelSizeY,num2str(PixelSizeY))!=0  || cmpstr(oldHorizontalTilt,num2str(HorizontalTilt))!=0  || cmpstr(oldVerticalTilt,num2str(VerticalTilt))!=0
	//	if(diff6 || diff7)
			NI1A_Create2DQWave(data) // need qz and qxy 2d waves which are created here
		//endif
		
	wave qxywave
	wave qzwave
	wave q2dwave
	string wavenote = note(q2dwave)
	wave theta2dwave
	wave qxypure
	wave qzpure
	wave xiwave
	svar xaxisplot
	svar yaxisplot
	variable row, minq
////	data *=sin(xiwave)
	
	// 2D Interpolation - working relatively well right now
	make /o/n=(dimsize(data,0)*2,dimsize(data,1)*2) datasq, masksq
	NVAR BeamCenterX = root:Packages:Convert2Dto1D:BeamCenterX
	NVAR BeamCenterY = root:Packages:Convert2Dto1D:BeamCenterY
	NVAR PxX = root:Packages:Convert2Dto1D:PixelSizeX
	NVAR PxY = root:Packages:Convert2Dto1D:PixelSizeY
	NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength
	NVAR sad  = root:Packages:Convert2Dto1D:SampleToCCDDistance
	NVAR invertimages = root:Packages:Convert2Dto1D:invertimages
	NVAR grazingangle=root:Packages:Convert2Dto1D:LineProf_GIIncAngle
	NVAR reflbeam=root:Packages:Convert2Dto1D:reflbeam
	
	// make 0 be the minimum q value and 0 be 0, the other side will be calculated as needed
	variable dx =  ((4*pi)/Wavelength)*sin(atan(PxX/sad)/2) // axes will be qxy and qz, but in pixel distances
	variable offsetx = -beamcenterx*dx
	variable dy 
	if(Invertimages)
		dy =  -((4*pi)/Wavelength)*sin(atan(PxY/sad)/2)
	else
		dy =  ((4*pi)/Wavelength)*sin(atan(PxY/sad)/2)
	endif
	variable offsety,effBCY
	if(reflbeam==1)
		effBCY = beamcentery
	elseif(reflbeam==2)
//		if(invertimages)
			effBCY = beamcentery + tan(2*grazingangle*pi/180)*sad/PxY
//		else
//			effBCY = beamcentery - tan(2*grazingangle*pi/180)*sad/PxY
//		endif
	else
//		if(invertimages)
			effBCY = beamcentery + tan(grazingangle*pi/180)*sad/PxY
//		else
//			effBCY = beamcentery - tan(grazingangle*pi/180)*sad/PxY
//		endif
	endif
	offsety = (dimsize(qxypure,1)-effBCY) * dy
//	print "dy = ", dy
//	print "offsety = ", offsety
//	print wavemin(qzwave)
//	print wavemax(qzwave)
	redimension /n=(dimsize(qxypure,0)*dimsize(qxypure,1)) data, qxywave,qzwave, mask
	
	setscale /p x, offsetx, dx/2, datasq, masksq
	setscale /p y, offsety, -dy/2, datasq, masksq
	JointHistogram_eliot(qxywave,qzwave,data,datasq)
	JointHistogram_eliot(qxywave,qzwave,mask,masksq)
	duplicate/o datasq, normalizationsq
	data=1
	JointHistogram_eliot(qxywave,qzwave,data,normalizationsq)
	matrixfilter /N=5 Gauss datasq
	matrixfilter /N=5 Gauss masksq
	matrixfilter /N=5 Gauss normalizationsq
	datasq /= normalizationsq[p][q]>0 ? normalizationsq[p][q] : 1
	masksq /= normalizationsq[p][q]>0 ? normalizationsq[p][q] : 1
	imageinterpolate /PXSZ={2,2} pixelate datasq
	duplicate /o m_pixelatedimage, data
	imagerotate /V/o data
	imageinterpolate /PXSZ={2,2} pixelate masksq
	duplicate /o m_pixelatedimage, mask
	imagerotate /V/o mask
	
	duplicate /o data, qxywave, qzwave,  theta2dwave, xiwave,  q2dwave//, qxwave, qywave // now that the image is distorted, we need to update the qwaves accordingly
	setscale /p x, offsetx, dx, data, qxywave, qzwave,  theta2dwave, xiwave,  q2dwave//, qxwave, qywave
	//setscale /p y, effBCY * dy, ((4*pi)/Wavelength)*sin(atan(PxY/sad)/2),  data, qxywave, qzwave,  theta2dwave, xiwave,  q2dwave
	if(invertimages)
		setscale /p y, dimsize(data,1)*dy-offsety, -dy,  data, qxywave, qzwave,  theta2dwave, xiwave,  q2dwave//, qxwave, qywave//, mask
	else
		setscale /p y, offsety-dimsize(data,1)*dy, dy,  data, qxywave, qzwave,  theta2dwave, xiwave,  q2dwave//, qxwave, qywave//, mask
	endif
	mask=mask>0.7 ? 1 : 0
	oldnote += "Flattened Image to qz-qy axis = 1;"
	note /K data
	note data, oldnote
	qxywave = x // this is a q image with equal spacing
	qzwave = y
	q2dwave = sqrt(x^2 + y^2)
	theta2Dwave = asin( q2dwave * wavelength / (4*pi) )
	xiwave = ( 180/pi ) * atan(abs(x/y))
	setscale /p x, 0,1, qxywave, qzwave,  theta2dwave, xiwave,  q2dwave
	setscale /p y, 0,1, qxywave, qzwave,  theta2dwave, xiwave,  q2dwave
	note q2dwave, wavenote
	note qzwave, wavenote
	note qxywave, wavenote
	note theta2Dwave, wavenote
	note xiwave, wavenote
	//1D Interpolation
//	make/o /n=(dimsize(data,0)) tempdatarow,tempoldq,tempnewq,tempnewdatarow, tempabswave
//	for(row=0;row<dimsize(data,1);row+=1)
//		tempdatarow = data[p][row]
//		tempoldq = qywave[p][row]
//		if(!cmpstr(Xaxisplot,"Qxy"))
//			tempnewq = qxywave[p][row]
//		else
//			break
//		endif
	// Re-Histogram
//		Histogram/c /B={wavemin(tempoldq),2*(wavemax(tempoldq)-wavemin(tempoldq))/numpnts(tempoldq), numpnts(tempoldq)/2} /w=tempdatarow tempnewq, tempnewdatarow
//		data[][row] = tempnewdatarow[p/2]
//		tempabswave = abs(tempnewq)
//		minq = wavemin(tempabswave)
//		tempnewdatarow = abs(tempoldq[p])<minq? 0 : interp(tempoldq,tempnewq, tempdatarow)
//		data[][row] = tempnewdatarow[p]
//	endfor

	ADE_UpdatePlot()

	
	
	//smooth 4,data
	setdatafolder foldersave
end
function ADE_UpdatePlot()
	NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
	NVAR DisplayRaw2DData=root:Packages:Convert2Dto1D:DisplayRaw2DData
	NVAR ImageDisplayLogScaled=root:Packages:Convert2Dto1D:ImageDisplayLogScaled
	
	Wave/Z CCDImageToConvert_dis=root:Packages:Convert2Dto1D:CCDImageToConvert_dis
	Wave/Z CCDImageToConvert =root:Packages:Convert2Dto1D:CCDImageToConvert
	if(!WaveExists(CCDImageToConvert_dis)||!WaveExists(CCDImageToConvert))
		return 0
	endif
	if(DisplayRaw2DData)
		wave waveToDisplay = root:Packages:Convert2Dto1D:CCDImageToConvert
	else
		wave/Z waveToDisplay = root:Packages:Convert2Dto1D:Calibrated2DDataSet
		if(!WaveExists(waveToDisplay))
			//Abort "Error in Irena in display of Calibrated data initiated by log int change. Please contact author"
			return 0
		endif
	endif
	Redimension/S CCDImageToConvert_dis
	Redimension/S waveToDisplay
	if(ImageDisplayLogScaled)
		MatrixOp/O CCDImageToConvert_dis =  log(waveToDisplay)
	else
		MatrixOp/O CCDImageToConvert_dis = waveToDisplay
	endif
end

Function PopGI_Angle(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			GI_ReHistImage()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function PopGi_PlotAxis1(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			svar XAxisPlot=root:Packages:Convert2Dto1D:XAxisPlot
			XAxisPlot = popstr
			GI_ReHistImage()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PopGI_PlotAxis2(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			svar YAxisPlot=root:Packages:Convert2Dto1D:YAxisPlot
			YAxisPlot = popstr
			GI_ReHistImage()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PopGI_Center(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			NVAR reflbeam=root:Packages:Convert2Dto1D:reflbeam
			reflbeam = popNum
			GI_ReHistImage()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function GI_Use_Chk(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				dowindow/f GiOptions
				if(!v_flag)
					Gi_Options()
				endif
				GI_ReHistImage()
			else
				dowindow/k GiOptions
				duplicate /o root:Packages:Convert2Dto1D:importeddata, root:Packages:Convert2Dto1D:CCDImageToConvert
				ADE_UpdatePlot()
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function Gi_Options() : Panel
	PauseUpdate; Silent 1		// building window...
	NVAR reflbeam=root:Packages:Convert2Dto1D:reflbeam
	NVAR phiangle=root:Packages:Convert2Dto1D:phiangle
	svar YAxisPlot=root:Packages:Convert2Dto1D:YAxisPlot
	svar XAxisPlot=root:Packages:Convert2Dto1D:XAxisPlot
	variable yitemnum = whichlistitem(YAxisplot,"Pixel X;Pixel Y;Angle X;AngleY;Qx;Qy;Qz;Qxy")
	variable xitemnum = whichlistitem(XAxisplot,"Pixel X;Pixel Y;Angle X;AngleY;Qx;Qy;Qz;Qxy")
	yitemnum = yitemnum<0 ? 1 : yitemnum+1
	xitemnum = xitemnum<0 ? 1 : xitemnum+1
	reflbeam = reflbeam>0 ? reflbeam : 1
	//phiangle=0
	dowindow /k GiOptions
	NewPanel /N=GiOptions/k=1 /W=(1117,82,1314,257) as "Grazing Incidence Options"
	ModifyPanel fixedSize=1
	PopupMenu GLCenter,pos={6,26},size={177,20},proc=PopGI_Center,title="Center Location: "
	PopupMenu GLCenter,mode=1,popvalue="Direct Beam",value= #"\"Direct Beam;Reflected Beam;Average\""
	PopupMenu GI_PlotAxis1,pos={17,54},size={129,20},proc=PopGi_PlotAxis1,title="X Axis of Plot"
	PopupMenu GI_PlotAxis1,mode=1,popvalue="Pixel X",value= #"\"Pixel X;Pixel Y;Angle X;AngleY;Qx;Qy;Qz;Qxy\""
	PopupMenu GI_PlotAxis2,pos={16,78},size={129,20},proc=PopGI_PlotAxis2,title="Y Axis of Plot"
	PopupMenu GI_PlotAxis2,mode=1,popvalue="Pixel X",value= #"\"Pixel X;Pixel Y;Angle X;AngleY;Qx;Qy;Qz;Qxy\""
	SetVariable GI_AlphaBox,pos={16,4},size={143,15},proc=PopGI_Angle,title="Incident Angle = "
	SetVariable GI_AlphaBox,value= root:Packages:Convert2Dto1D:LineProf_GIIncAngle
	SetVariable GI_AlphaBox1,pos={13,105},size={143,15},title="Incident Angle = "
	SetVariable GI_AlphaBox1,value= root:Packages:Convert2Dto1D:Phiangle,proc=PopGI_Angle
	Button GIWAXS_Load,pos={40,129},size={95,36},proc=GIWAXS_Load,title="Find Lattice\rParameters"
EndMacro

Function JointHistogram_eliot(w0,w1,weight,hist)
	wave w0,w1,hist,weight
 
	variable bins0=dimsize(hist,0)
	variable bins1=dimsize(hist,1)
	variable n=numpnts(w0)
	variable left0=min(dimoffset(hist,0),dimoffset(hist,0) +bins0*dimdelta(hist,0))
	variable histoffsetx = dimoffset(hist,0)
	variable histoffsety = dimoffset(hist,1)
	variable histdx = dimdelta(hist,0)
	variable histdy = dimdelta(hist,1)
	variable left1=min(dimoffset(hist,1),dimoffset(hist,1) +bins1*dimdelta(hist,1))
	variable right0=max(dimoffset(hist,0),dimoffset(hist,0) +bins0*dimdelta(hist,0))
	variable right1=max(dimoffset(hist,1),dimoffset(hist,1) +bins1*dimdelta(hist,1))
 
	make/free /n=(n) idx//, idxw
	multithread idx=w0>left0 && w0< right0 && w1>left1 && w1 < right1 ? round(bins0*(w0-left0)/(right0-left0))+bins0*round(bins1*(w1-left1)/(right1-left1)) : 0 // what pixel these elements fallinto
 	//redimension /n=(bins0*bins1) hist // Redimension to 1D.  
	// Compute the histogram and redimension it. 
	histogram /b={0,1,bins0*bins1}/w=weight idx , hist 
	redimension /n=(bins0,bins1) hist // Redimension to 2D.
	if(histdy<0)
		imagetransform flipcols, hist
	endif	
	if(histdx<0)
		imagetransform fliprows, hist
	endif
	setscale/p x,histoffsetx,histdx,hist // Fix the histogram scaling in the x-dimension.
	setscale/p y,histoffsety,histdy,hist // Fix the histogram scaling in the y-dimension.
End

Function SolidAngleMap()
	String CurrentFolder=GetDataFolder(1)
	SetDataFolder root:Packages:Convert2Dto1D
	NVAR BCx=BeamCenterX, BCy=BeamCenterY, d=SampleToCCDdistance
	NVAR dX=pixelSizeX, dY=PixelSizeY
	NVAR Htilt=HorizontalTilt, Vtilt=VerticalTilt
	variable chx = Htilt * pi/180
	variable chy = Vtilt *pi/180
	WAVE CCD=CCDImageToConvert
	Duplicate/d/o CCD areaMap
	// this was brian's solid angle correction
	//areaMap= cos( atan( (p-BCx)*pSizeX/Dist) + Htilt*pi/180 ) * cos( atan( (q-BCy)*pSizeY/Dist) + Vtilt*pi/180 )
	// this is Eliot's
	areaMap = (1/((d^2*2*pi^2))) *dx * dy * Sec(Chx) *Sec(Chy) 
	areaMap *= (Sin(Chx + ASin((d - (BCx-p)*dx * Sin(Chx))/Sqrt(d^2 + ((BCx-p)*dx)^2 - 2*d*((BCx-p)*dx)*Sin(Chx))))^2) 
	areaMap *= (Sin(Chy + ASin((d - (BCy-q)*dy * Sin(Chy))/Sqrt(d^2 + ((BCy-q)*dy)^2 - 2*d*((BCy-q)*dy)*Sin(Chy))))^2) 
	// this is the angular area of each pixel, which when summed over all angles = 1
	// Checked with Mathematica January 2015 - Eliot
	SetDataFolder $currentFolder
end


Menu "Macros"
	"RSoXS Background Subtraction", /Q, ;Execute/P/Q "StartFluorescenceBackground()"
	help={"Interactively subtract flouresence and compton scattering backgrounds from scattering data"}
End

function startFluorescenceBackground()
	// look for top graph
	string windowname = winname(0,1,1)
	if(strlen(windowname)==0)
		doalert /t="Error - no graphs found" 0,"Please create a graph first"
		return 0
	endif
	
	dowindow /k FS_Background
	string foldersave = getdatafolder(1)
	setdatafolder root:
	newdatafolder /o/s Packages
	newdatafolder /o/s FBackgroundSubtraction
	string /g currentwindow = windowname
	string /g currenttracename=""
	variable /g tracenum=0
	
	variable /g currentFBackground=0
	variable /g currentCSBackground=0
	
	variable /g CurrentQPower
	// for remembering all of the properties of the plotted trace, before we mess it all up to "highlight" it
	string /g recreationlist
	string /g tracenameplotted
	// remmebring the real wave name we are adjusting (we will remove it from the graph and replace it with the altered wave)
	string /g currentwavename
	// name of altered wave we are replacing the wave with on the graph (this will be a cleaned up shortened, unique name starting with "fs_")
	string /g currentFsubwavename
	// name of the current x wave, which will be used in the graphing and the calculation of the background
	string /g currentxwavename
	string /g derivativexwavename // this is the derivative of the current x wave with respect to theta
	string /g ComptonScatteringWaveName // this is the compton scattering background wave calculated from the current wave
	
	//create panel
	NewPanel /k=1/n=FS_Background /W=(211,487,523,696) as "Scattering Background Subtraction"
	PopupMenu TracenamePop,pos={80,6},size={216,21},proc=FS_PopTraceSel,title="Trace to Adjust:"
	PopupMenu TracenamePop,mode=19,popvalue="fs_ro_K11_292_100_C",value= #"TraceNameList(\"\",\";\",1)"
	Slider FS_BValSlide,pos={1,62},size={297,19},proc=FS_SliderProc
	Slider FS_BValSlide,limits={-1,1,0},value= 0,vert= 0,ticks= 0
	SetVariable FS_BkVal,pos={30,36},size={235,20},bodyWidth=80,proc=FS_setvar,title="Flouresence Background"
	SetVariable FS_BkVal,fSize=14
	SetVariable FS_BkVal,limits={0,inf,0},value=currentFBackground
	SetVariable FS_Qpwr,pos={4,7},size={72,20},bodyWidth=30,proc=FS_setvar,title="Power"
	SetVariable FS_Qpwr,fSize=14
	SetVariable FS_Qpwr,limits={0,10,1},value=CurrentQPower
	Slider FS_CSBValSlide,pos={3,116},size={297,19},proc=FS_CSSliderProc
	Slider FS_CSBValSlide,limits={-1,1,0},value= 0,vert= 0,ticks= 0
	SetVariable FS_CSBkVal,pos={12,91},size={277,20},bodyWidth=80,proc=FS_CSsetvar,title="Empirical Background"
	SetVariable FS_CSBkVal,fSize=14
	SetVariable FS_CSBkVal,limits={0,inf,0},value=root:Packages:FBackgroundSubtraction:currentCSBackground
	Button FS_resetwindowbut,pos={153,146},size={150,50},proc=FS_UndoAlltopWindow,title="Undo all Background\rcorrections in top window"
	Button FS_ActivateWindow,pos={9,138},size={131,36},proc=FS_ActivateTopWindow,title="Activate Top\rWindow"
	Button FS_DeactivateWindow,pos={9,171},size={131,36},proc=FS_DeactivateTopWindow,title="Deactivate Top\rWindow"
	//setup the windowhook function for the chosen window
	setwindow $windowname, hook(mouseuphook)=FsubCTraceSelectWindowHook
	
	//choose the first trace by default
	string tracestr = stringfromlist(0,TraceNameList(windowname, ";", 5)) // top non-hidden trace
	//do the usual FS_UpdateChooseTrace(newtracename) function - same as will happen when new trace is chosen
	FS_updateChooseTrace(tracestr, windowname)
	setdatafolder foldersave
end
	



Function FsubCTraceSelectWindowHook(s)
	STRUCT WMWinHookStruct &s
	Switch(s.eventcode)
		case 5: // mouseup
			variable mouseX = s.mouseloc.h
			variable mouseY = s.mouseloc.v
			string tracestr = TraceFromPixel(mouseX, mouseY,"")
			string tracename = stringbykey("TRACE",tracestr)
			//string tracename = stringbykey("Tracename
			//if(strlen(tracename)>0)
			if(s.eventmod & 2) // control button is down
				nvar/z CurrentCSBackground = root:Packages:FBackgroundSubtraction:currentCSBackground
				nvar/z CurrentFBackground = root:Packages:FBackgroundSubtraction:currentFBackground
				variable savefval = CurrentFBackground
				variable savecval = CurrentCSBackground
			endif
			FS_UpdateChooseTrace(tracename,s.winName)
			
			if(s.eventmod & 2) // control button is down
				CurrentCSBackground = savecval
				CurrentFBackground =savefval
				FS_UpdateFValue()
			endif
			//endif
			string cstr = "dowindow/F FS_Background;DelayUpdate\r"
			cstr += "	dowindow/F "+s.winName
			Execute /z/q/P cstr
			break
		case 17:// Kill
			FS_updateChooseTrace("","") // unload the waves
			//killdatafolder root:Packages:FBackgroundSubtraction
	EndSwitch

	return 0
end

function FS_updateChooseTrace(tracestr, windowname)
	string tracestr, windowname
	string foldersave = getdatafolder(1)
	setdatafolder root:Packages:FBackgroundSubtraction
	svar currentwindow
	svar currentwavename // the wave name (and directory) of the currently loaded wave
	nvar tracenum
	nvar currentFBackground
	nvar currentCSBackground
	svar recreationlist
	svar tracenameplotted
	svar currentwavename
	svar currentFsubwavename
	svar currentxwavename
	svar derivativexwavename 
	svar ComptonScatteringWaveName
	wave/z wavetoload = TraceNameToWaveRef(windowname, tracestr )
	if(waveexists(wavetoload))
		string wavenametoload = GetWavesDataFolder(wavetoload, 2 )
		string wavedirectorytoload = GetWavesDataFolder(wavetoload, 1 )
		string justwavename = nameofwave(wavetoload)
	endif // don't quit because the wave doesn't exist, we still want to unload the current waves
	variable j
	string commandstr
	if(cmpstr(tracenameplotted,tracestr) || cmpstr(windowname, currentwindow))
	//if(cmpstr(windowname, currentwindow))
	// is the new wave the same as the old wave?  window name and tracename have not changed?
	//if the wave has changed
		// unload the current wave (if (there is one already)) // change the trace style back to the remembered style
				//for loop running through the modify graph commands in recreationlist with win=$currentwindow
		if(strlen(currentwindow)>1 && strlen(traceinfo(currentwindow,tracenameplotted,0))>0)
			for(j=0;j<itemsinlist(recreationlist);j+=1)
				commandstr = "ModifyGraph /w="+currentwindow +" "+ replacestring("(x)",stringfromlist(j,recreationlist),"["+num2str(tracenum)+"]")
				execute/q/z commandstr
			endfor
	
		
			// if the FS value is 0, then replace the FS of the previously loaded wave with the original wave
			if(currentFBackground==0 && currentCSBackground==0 )
				wave/z originalwave = $currentwavename
				if(waveexists(originalwave))
					replacewave /w=$currentwindow TRACE=$tracenameplotted, originalwave 
				else
					print "can't find the original wave or trace"
				endif
			endif
		endif
		if( cmpstr(windowname, currentwindow))
		// if the new window is different (than currentwindow), 
			//unload hook function on old window
			setwindow $currentwindow, hook(mouseuphook) = $""
			//load it on new window
			setwindow $windowname, hook(mouseuphook) = FsubCTraceSelectWindowHook
			//update the currentwindow to the new windowname
			currentwindow = windowname
		endif
		if(!waveexists(wavetoload) || strlen(tracestr)==0)
			// we have done everything we need to do, now quit
			setdatafolder foldersave
			return 0
		endif
		//update the current tracename and tracenum (run tracelist, and find tracename in the list)
		currentwavename = wavenametoload
		tracenum = whichlistitem(tracestr, TraceNameList(currentwindow, ";", 5))
		PopupMenu  TracenamePop, win=FS_Background,mode=(tracenum+1)
		//check if this is a flouresence subtracted wave already
		if(stringmatch(justwavename,"fs_*"))
			// if it is, then load the real waves into the global variables (currentwavename, currentxwavename, currentfsubwavename, derivativexwavename), and the FValue into currentFBackground
				// read the wavenote of the wave's trace, if there is an entry for FS_originalwavename, FS_originalxwavename, and fvalue, then load those
			string oldwavenote = note(wavetoload)
			currentwavename = stringbykey("FS_OriginalWave",oldwavenote,"=",";")
			currentxwavename = stringbykey("FS_OriginalXWave",oldwavenote,"=",";")
			currentFsubwavename = wavenametoload
			currentFBackground = numberbykey("FS_fvalue",oldwavenote,"=",";")
			currentCSBackground = numberbykey("FS_CSvalue",oldwavenote,"=",";")
			if(currentCSBackground*0!=0)
				currentCSBackground=0
			endif
			if(currentFBackground*0!=0)
				currentFBackground=0
			endif
			// remove the derivativex wave reference from the wavenote
			oldwavenote = removebykey("FS_dqdt",oldwavenote,"=",";",1)
			note /k wavetoload, oldwavenote
			if(strlen(currentwavename) * strlen(currentxwavename) ==0 || currentFBackground*0!=0 || currentCSBackground*0!=0)
				print "Something failed in reading the parameters from the flouresence wave"
				return 0
			endif
			wave wavetoload = $currentwavename
			wave FSwave= $currentFsubwavename
		else
			// if it isn't 
			// check that the new wave exists
			currentxwavename = GetWavesDataFolder(xwavereffromtrace(windowname, tracestr ), 2 )
			currentFsubwavename = wavenametoload
				// create the Fsub wave (in the same folder as the wave)
			setdatafolder wavedirectorytoload
			string nameofFSwave = cleanupname("fs_"+justwavename,1)
			wave /z FSwave = $nameofFSwave
			if(waveexists(FSwave))
				nameofFSwave = uniquename(nameofFSwave,1,1)
			endif
			duplicate wavetoload, $nameofFSwave
			wave FSwave = $nameofFSwave
				// add to the wavenote of the fsub wave, the entries for FS_originalwavename, FS_originalxwavename, and fvalue (=0)
			string wnote = note(wavetoload)
			wnote += ";FS_OriginalWave="+currentwavename
			wnote += ";FS_OriginalxWave="+currentxwavename
			wnote += ";FS_fvalue=0"
			NOTE /K FSwave, wnote
			currentFsubwavename = GetWavesDataFolder(FSwave, 2 )
				// replacewave trace=oldwavename, fsubwavename  //replaces the wave with it's duplicate we have made
			replacewave /w=$currentwindow TRACE=$tracestr, FSwave
			currentFBackground = 0
			currentCSBackground = 0
		endif
		// store the trace parameters to the global variable recreationlist
		tracenameplotted = stringfromlist(tracenum,TraceNameList(currentwindow, ";", 5))
		string teststring = traceinfo(currentwindow,tracenameplotted,0)
		//print "tracename = " + tracenameplotted
		//print "Currentwindow = " + currentwindow
		//print teststring
		recreationlist = teststring[strsearch(teststring,"RECREATION:",0) + strlen("RECREATION:"),inf]
		// change the trace style to the "Highlighted" type
		modifygraph /w=$windowname mode[tracenum]=0,lsize[tracenum]=3,rgb[tracenum]=(65280,0,0)
		// create the dqdth wave (overwrite if it exists, there is not necessarily a one-one correspondence here, we only need this when changing a wave)
			// read the lambda from the wavenote
		variable lambda = 0.001 * numberbykey("Wavelength",note(FSwave),"=",";") //(in nanometers)
			// dqdth = (4 * Pi *Sqrt(1 - (q^2 *labmda^2)/(16 * pi^2) )/lambda
		wave xwave = $currentxwavename
		string nameofdqdtwave = cleanupname("dqdt_"+justwavename,1) // flouresence background
		duplicate/o FSwave, $nameofdqdtwave
		wave dqdt = $nameofdqdtwave
		dqdt = lambda/(Sqrt(1 - (xwave^2 *lambda^2)/(16 * pi^2) )) // this is actually d sigma / d q
		string nameofCSBwave = cleanupname("CSB_"+justwavename,1) // compton scattering background
		duplicate/o FSwave, $nameofCSBwave
		wave CSBwave = $nameofCSBwave
		//CSBwave = Sqrt(16*pi^2 - (xwave^2 *lambda^2))*(32 * pi^2 - (xwave^2 *lambda^2)) *sec((1/2)*asin(xwave*lambda/(4*pi)))  // this is actually d sigma / d q
		CSBwave = xwave^-.5 -1*xwave^2+1
		
		note /NOCR FSwave, ";FS_dqdt="+getwavesdatafolder(dqdt,2)
		note /NOCR FSwave, ";FS_CSBwave="+getwavesdatafolder(CSBwave,2)
		derivativexwavename = getwavesdatafolder(dqdt,2)
		ComptonScatteringWaveName = getwavesdatafolder(CSBwave,2)
	endif
	//whether the wave is new or not, update the panel to make sure the correct wave is chosen in the popup
	// run the FS_UpdateFValue function
	FS_UpdateFValue()
	setdatafolder foldersave
end

function FS_UpdateFValue()
			// load the original wave, the dqdth wave, and the fsub wave
			// assumes that root:Packages:FBackgroundSubtraction:currentCSBackground has been updated
	svar/z originalwavename = root:Packages:FBackgroundSubtraction:currentwavename
	svar/z currentFsubwavename = root:Packages:FBackgroundSubtraction:currentFsubwavename
	svar/z currentxwavename = root:Packages:FBackgroundSubtraction:currentxwavename
	svar/z derivativexwavename = root:Packages:FBackgroundSubtraction:derivativexwavename
	svar/z ComptonScatteringWaveName = root:Packages:FBackgroundSubtraction:ComptonScatteringWaveName
	svar/z currentwindow = root:Packages:FBackgroundSubtraction:currentwindow
	
	if(!svar_exists(originalwavename) || !svar_exists(currentFsubwavename) || !svar_exists(currentxwavename) || !svar_exists(derivativexwavename) || !svar_exists(ComptonScatteringWaveName))
		print "unable to find the waves that should have been setup"
		return 0
	endif
	
	wave/z originalwave = $originalwavename
	wave/z currentFsubwave = $currentFsubwavename
	wave/z currentxwave = $currentxwavename
	wave/z derivativexwave = $derivativexwavename
	wave/z ComptonScatteringWave = $ComptonScatteringWaveName
	
	if(!waveexists(originalwave) || !waveexists(currentFsubwave) || !waveexists(currentxwave) || !waveexists(derivativexwave))
		print "unable to subtract flouresence because waves do not exist"
		return 0
	endif
	
	nvar/z CurrentCSBackground = root:Packages:FBackgroundSubtraction:currentCSBackground
	nvar/z CurrentFBackground = root:Packages:FBackgroundSubtraction:currentFBackground
	nvar/z CurrentQPower = root:Packages:FBackgroundSubtraction:CurrentQPower
	
	if(!nvar_exists(currentFBackground) || !nvar_exists(currentCSBackground))
		print "unable to subtract background because global variable holding flouresence or comptonscattering does not exist"
		setwindow $currentwindow, hook(mouseuphook) = $""
		currentwindow=""
		return 0
	endif
	
	// set the Fsub wave to the original-fvalue*dqdth
	currentFsubwave	=originalwave - (derivativexwave) * currentFBackground * currentxwave^CurrentQPower
	currentFsubwave	=currentFsubwave - (ComptonScatteringWave) * currentCSBackground * currentxwave^CurrentQPower
	string oldwavenote = removebykey("FS_fvalue",note(currentFsubwave),"=",";",1)
	oldwavenote = removebykey("FS_CSvalue",oldwavenote,"=",";",1)
	oldwavenote +=";FS_fvalue="+num2str(currentFBackground)
	oldwavenote +=";FS_CSvalue="+num2str(currentCSBackground)
	note /K currentFsubwave, oldwavenote
end	


Function FS_setvar(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			FS_UpdateFValue()
			break
		case -1: // control being killed
			if(datafolderexists("root:Packages:FBackgroundSubtraction"))
				FS_updateChooseTrace("","") // unload the waves
				killdatafolder root:Packages:FBackgroundSubtraction
			endif
			return 0
	endswitch

	return 0
End
Function FS_CSsetvar(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			FS_UpdateFValue()
			break
	endswitch
	return 0
End

Function FS_SliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa
	//sa.blockReentry = 1
	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 2 ) // mouse down
				Variable curval = sa.curval
				string foldersave = getdatafolder(1)
				setdatafolder root:Packages:FBackgroundSubtraction:
				nvar fs_value = currentFBackground
				variable /g fs_centeradj = fs_value
				setdatafolder foldersave
			endif
			if( sa.eventCode & 1 &&  sa.eventCode & 3) // value set (while the mouse is still down)
				nvar fs_value = root:Packages:FBackgroundSubtraction:currentFBackground
				nvar fs_centeradj = root:Packages:FBackgroundSubtraction:fs_centeradj
				fs_value =  max(0,-1+exp(.0000002*sa.curval) + exp(2*sa.curval) *fs_centeradj)
				FS_UpdateFValue()
			endif
			if( sa.eventCode & 4 ) // mouse up
				Slider $sa.ctrlName value = 0 
			endif
			break
	endswitch

	return 0
End
Function FS_CSSliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa
	//sa.blockReentry = 1
	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 2 ) // mouse down
				Variable curval = sa.curval
				string foldersave = getdatafolder(1)
				setdatafolder root:Packages:FBackgroundSubtraction:
				nvar fs_value = currentCSBackground
				svar rwavename = currentwavename
				wave rwave = $rwavename
				variable /g fs_CSmaxadj = wavemax(rwave)/3
				variable /g fs_CScenteradj = fs_value
				setdatafolder foldersave
			endif
			if( sa.eventCode & 1 &&  sa.eventCode & 3) // value set (while the mouse is still down)
				nvar fs_value = root:Packages:FBackgroundSubtraction:currentCSBackground
				nvar fs_centeradj = root:Packages:FBackgroundSubtraction:fs_CScenteradj
				nvar fs_CSmaxadj = root:Packages:FBackgroundSubtraction:fs_CSmaxadj
				
				//fs_value =  max(0,-1+exp(fs_CSmaxadj*sa.curval) + exp(.05*sa.curval) *fs_centeradj)
				fs_value =  max(0,-1+exp(fs_CSmaxadj*sa.curval) + exp(sa.curval) *fs_centeradj)
				FS_UpdateFValue()
			endif
			if( sa.eventCode & 4 ) // mouse up
				Slider $sa.ctrlName value = 0 
			endif
			break
	endswitch

	return 0
End

Function FS_PopTraceSel(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string windowname = winname(0,1,1) // this can break if someone switches the window before the popup can update
			FS_updateChooseTrace(popStr, windowname)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


function FS_updatetopgraph(FSvalue,CBvalue, qpower)
	// updated both the flouresence background and the CBvalue for all the graphs in the top window
	variable fsvalue, CBvalue, qpower
	nvar/z CurrentFBackground = root:Packages:FBackgroundSubtraction:currentFBackground
	nvar/z CurrentQPower = root:Packages:FBackgroundSubtraction:CurrentQPower
	nvar/z CurrentCSBackground = root:Packages:FBackgroundSubtraction:currentCSBackground
	string tracelist = tracenamelist("",";",1)
	string windowname = winname(0,1,1)
	variable i
	for(i=0;i<itemsinlist(tracelist);i+=1)
		FS_UpdateChooseTrace(stringfromlist(i,tracelist),windowname)
		CurrentFBackground = fsvalue
		CurrentQPower = qpower
		CurrentCSBackground = CBvalue
		FS_UpdateFValue()
	endfor
end

function FS_ClearWindow()
	nvar/z currentFBackground = root:Packages:FBackgroundSubtraction:currentFBackground
	nvar/z currentCSBackground = root:Packages:FBackgroundSubtraction:currentCSBackground
	string windowname = winname(0,1,1)
	string tracelist = tracenamelist(windowname,";",1)
	variable i
	for(i=0;i<itemsinlist(tracelist);i+=1)
		FS_updateChooseTrace(stringfromlist(i,tracelist), windowname)
		currentFBackground=0
		currentCSBackground=0
		FS_UpdateFValue()
	endfor
	FS_updateChooseTrace("","")
end

Function FS_UndoAlltopWindow(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			FS_ClearWindow()
			break
	endswitch
	return 0
End
Function FS_ActivateTopWindow(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			string windowname = winname(0,1,1)
			FS_updateChooseTrace("", windowname)
			break
	endswitch
	return 0
End
Function FS_DeactivateTopWindow(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			FS_updateChooseTrace("","")
			break
	endswitch
	return 0
End

function colorlines(colorscheme)
	string colorscheme
	string tracelist=TraceNameList("",";",1),currenttrace
	variable i,scaling
	if(!cmpstr(colorscheme,""))
		colorscheme = "rainbow"
	endif
	ColorTab2Wave $colorscheme
	wave M_colors
	scaling = (DimSize(M_colors,0))/itemsinlist(tracelist,";")
	for(i=0;i<itemsinlist(tracelist,";");i+=1)
		currenttrace = stringfromlist(i,tracelist,";")
		ModifyGraph rgb($currenttrace)=(M_colors[scaling*i][0],M_colors[scaling*i][1],M_colors[scaling*i][2])
	endfor
end


Function ButtonChangetoSel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
				string foldersave = getdatafolder(1)
				wave/t listwave = root:Packages:SwitchNIKA:listwave
				wave selwave = root:Packages:SwitchNIKA:selwave
				svar name = root:Packages:SwitchNIKA:name
				controlinfo Switch
				variable row = v_value
				SetDataFOlder root:Packages:Convert2Dto1D
				NewPath/q/O/M="Select path to your data" Convert2Dto1DMaskPath,listwave[row][5]
				NI1A_UpdateMainMaskListBox()	
				NI1M_UpdateMaskListBox()
				
				SVAR CurrentMaskFileName=root:Packages:Convert2Dto1D:CurrentMaskFileName
				nvar bcx = root:Packages:Convert2Dto1D:BeamCenterX
				nvar bcy = root:Packages:Convert2Dto1D:BeamCenterY
				nvar sdd = root:Packages:Convert2Dto1D:SampleToCCDDistance
				nvar flatten_line = root:Packages:NIKA1101:flatten_line
				nvar flatten_width = root:Packages:NIKA1101:flatten_width
				name = listwave[row][0] 
				bcx = str2num(listwave[row][1])
				bcy = str2num(listwave[row][2])
				sdd = str2num(listwave[row][3])
				
				NI1A_UniversalLoader("Convert2Dto1DMaskPath",listwave[row][4],"tiff","M_ROIMask")
				CurrentMaskFileName = listwave[row][4]
				wave M_ROIMask
				Redimension/B/U M_ROIMask
				M_ROIMask=M_ROIMask>0.5 ? 1 : 0
				
				flatten_line = str2num(listwave[row][6])
				flatten_width = str2num(listwave[row][7])
				setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonAddSwitch(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
				string foldersave = getdatafolder(1)
				wave/t listwave = root:Packages:SwitchNIKA:listwave
				wave selwave = root:Packages:SwitchNIKA:selwave
				svar name = root:Packages:SwitchNIKA:name
				
				SetDataFOlder root:Packages:Convert2Dto1D
				PathInfo/S Convert2Dto1DMaskPath
				string path = s_path
				SVAR CurrentMaskFileName=root:Packages:Convert2Dto1D:CurrentMaskFileName
				nvar bcx = root:Packages:Convert2Dto1D:BeamCenterX
				nvar bcy = root:Packages:Convert2Dto1D:BeamCenterY
				nvar sdd = root:Packages:Convert2Dto1D:SampleToCCDDistance
				nvar flatten_line = root:Packages:NIKA1101:flatten_line
				nvar flatten_width = root:Packages:NIKA1101:flatten_width
				variable index = dimsize(listwave,0)
				redimension /n=(index+1,8) selwave,listwave
				selwave = p==index ? 3 : 2
				listwave[index][0] = name
				listwave[index][1] = num2str(bcx)
				listwave[index][2] = num2str(bcy)
				listwave[index][3] = num2str(sdd)
				listwave[index][4] = CurrentMaskFileName
				listwave[index][5] = path
				listwave[index][6] = num2str(flatten_line)
				listwave[index][7] = num2str(flatten_width)
				setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonRemoveSwitch(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
				wave/t listwave = root:Packages:SwitchNIKA:listwave
				wave selwave = root:Packages:SwitchNIKA:selwave
				svar name = root:Packages:SwitchNIKA:name
				controlinfo Switch
				variable row = v_value
				deletepoints /m=0 row,1,selwave,listwave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
function StartSwitchNika()
	string foldersave = getdatafolder(1)
	setdatafolder root:
	newdatafolder /o/s Packages
	newdatafolder /o/s SwitchNIKA
	wave/z/t listwave
	variable rows=0
	if(waveexists(listwave))
		rows = dimsize(listwave,0)
	endif
	make/n=(rows,8)/o/t listwave
	make/n=(rows,8)/o selwave = 3
	make /o/t columnnames = {"Name","Xpos","Ypos","S-D","Mask","MaskPath","FlattenCenter","FlattenWidth"}
	string/g name
	NewPanel /n=SwitchNika/W=(509,271,1155,445) as "Switch Q Range"
	Button MovetoSelected,pos={2.00,15.00},size={130.00,39.00},proc=ButtonChangetoSel,title="Change to Selection"
	Button SaveSelected,pos={2.00,55.00},size={130.00,37.00},proc=ButtonAddSwitch,title="Save Current Settings"
	ListBox Switch,pos={139.00,9.00},size={499.00,148.00}
	ListBox Switch,listWave=root:Packages:SwitchNIKA:listwave
	ListBox Switch,selWave=root:Packages:SwitchNIKA:selwave
	ListBox Switch,titleWave=root:Packages:SwitchNIKA:columnnames,mode= 2,selRow= 0
	ListBox Switch,userColumnResize= 1
	SetVariable Name,pos={3.00,138.00},size={133.00,18.00},title="Name"
	SetVariable Name,value= root:Packages:SwitchNIKA:name
	Button RemoveSelected,pos={2.00,93.00},size={130.00,37.00},proc=ButtonRemoveSwitch,title="Remove Selection"
End

function PolarizationTopGraph([name,normtoFirstEn])
	// look at the top graph, and finds groups of 2-8 exposures (horizontal (left/right) and vertical (up down) and different polarizations) and calculates the A profile
	string name
	variable normtoFirstEn
	normtoFirstEn = paramisdefault(normtoFirstEn) ? 0 : normtoFirstEn
	string foldersave = getdatafolder(1)
	setdatafolder root:
	newdatafolder /o/s Packages
	newdatafolder /o/s PolarizationCalcs
	string windowname = winname(0,1)
	string tracelist = tracenamelist(windowname,";",1)
	tracelist = sortlist(tracelist)
	variable num = itemsinlist(tracelist)
	make /wave /free /n=(num) waves=tracenametowaveref(windowname,stringfromlist(p,tracelist))
	make /wave /free /n=(num) xwaves=xwavereffromtrace(windowname,stringfromlist(p,tracelist))
	variable j,groupnum, minq, maxq
	string basename, tracename, grouplist, wnote
	variable hl,hr,hu,hd,vl,vr,vu,vd
	// get name for graph and folder
	tracename = stringfromlist(j,tracelist)
	if(paramisdefault(name))
		splitstring /e="^'?(.*)[^_]{3,5}_1[90]0_(90|180|270|360)_20'?$" tracename,basename
		if(strlen(basename)<1)
			basename = windowname
		endif
	else
		basename=name
	endif
	newdatafolder /o/s $basename
	string gname = Cleanupname(basename+"_Anisotropy",0)
	string imagename = Cleanupname(basename+"_ImagePlot",0)
	string avenname = Cleanupname(basename + "_vsEnergy",0)
	//dowindow /k $gname
	//display /k=1 /n=$gname as "Plot of Anisotropy for "+basename
	dowindow /k $avenname
	display /k=1 /n=$avenname as "Anisotropy vs Energy for "+basename
	dowindow /k $imagename
	display/W=(745.5,87.5,1098.75,404)/n=$imagename /k=1 as "Anisotropy vs Q and Energy for "+basename
	make /o/n=0 $Cleanupname(basename+"_Atot",1),$Cleanupname(basename+"_En",1)
	make /o/n=0 $Cleanupname(basename+"_Mesh",1)
	wave mesh = $Cleanupname(basename+"_Mesh",1)
	make /n=0/wave /free awaves, axwaves
	wave Atot = $Cleanupname(basename+"_Atot",1)
	wave En = $Cleanupname(basename+"_En",1)
	variable index
	for(j=0;j<num;j+=1)
		tracename = stringfromlist(j,tracelist)
		splitstring /e="^'?(.*)_1[90]0_(90|180|270|360)_20'?$" tracename,basename
		if(strlen(basename)<1)
			print "Tracename: \"" + tracename + "\" could not by parced"
			continue
		endif
		grouplist = greplist(tracelist,"^'?"+basename+"_1[90]0_(90|180|270|360)_20'?$")
		groupnum = itemsinlist(grouplist)
		if(groupnum<2)
			continue
		endif
		j+= groupnum -1
		hd = whichlistitem(removeending(greplist(grouplist,"_100_90_20'?$"),";"),tracelist)
		hl = whichlistitem(removeending(greplist(grouplist,"_100_180_20'?$"),";"),tracelist)
		hu = whichlistitem(removeending(greplist(grouplist,"_100_270_20'?$"),";"),tracelist)
		hr = whichlistitem(removeending(greplist(grouplist,"_100_360_20'?$"),";"),tracelist)
		vd = whichlistitem(removeending(greplist(grouplist,"_190_90_20'?$"),";"),tracelist)
		vl = whichlistitem(removeending(greplist(grouplist,"_190_180_20'?$"),";"),tracelist)
		vu = whichlistitem(removeending(greplist(grouplist,"_190_270_20'?$"),";"),tracelist)
		vr = whichlistitem(removeending(greplist(grouplist,"_190_360_20'?$"),";"),tracelist)
		// combine into average parallel and perpindicular r and q waves (largest range possible) for different polarizations
		if((hd<0 && hu<0) || (hr<0 && hl<0))
			// horizontal polarization is not complete, so skip it
		else
			make /o /n=1000 $cleanupname(basename+"_perph",1), $cleanupname(basename+"_perphx",1), $cleanupname(basename+"_parah",1), $cleanupname(basename+"_parahx",1)
			wave perph = $cleanupname(basename+"_perph",1)
			wave perphx = $cleanupname(basename+"_perphx",1)
			wave parah = $cleanupname(basename+"_parah",1)
			wave parahx = $cleanupname(basename+"_parahx",1)
			if(hd>=0)
				wave perph1 = waves[hd]
				wnote = note(perph1)
				wave perph1x = xwaves[hd]
				if(hu>=0)
					wave perph2 = waves[hu]
					wave perph2x = xwaves[hu]
					minq=min(wavemin(perph2x),wavemin(perph1x))
					maxq=max(wavemax(perph2x),wavemax(perph1x))
					
					setscale /i x,minq,maxq,perph, perphx
					perphx=x
					perph = x>=wavemin(perph1x) && x<=wavemax(perph1x) ? interp(x,perph1x,perph1) : 0
					perph += x>=wavemin(perph2x) && x<=wavemax(perph2x) ? interp(x,perph2x,perph2) : 0
					perph /= x>=wavemin(perph2x) && x<=wavemax(perph2x)  && x>=wavemin(perph1x) && x<=wavemax(perph1x) ? 2 : 1
				else
					minq=wavemin(perph1x)
					maxq=wavemax(perph1x)
					setscale /i x,minq,maxq,perph, perphx
					perphx = x
					perph =interp(x,perph1x,perph1)
				endif
			else
				wave perph1 = waves[hu]
				wnote = note(perph1)
				wave perph1x = xwaves[hu]
				minq=wavemin(perph1x)
				maxq=wavemax(perph1x)
				setscale /i x,minq,maxq,perph, perphx
				perphx = x
				perph =interp(x,perph1x,perph1)
			endif
			Note perph, wnote
			//appendtograph /w=gname perph /TN=$basename vs perphx
			if(hl>=0)
				wave parah1 = waves[hl]
				wave parah1x = xwaves[hl]
				if(hr>=0)
					wave parah2 = waves[hr]
					wave parah2x = xwaves[hr]
					minq=min(wavemin(parah2x),wavemin(parah1x))
					maxq=max(wavemax(parah2x),wavemax(parah1x))
					
					setscale /i x,minq,maxq,parah, parahx
					parahx=x
					parah = x>=wavemin(parah1x) && x<=wavemax(parah1x) ? interp(x,parah1x,parah1) : 0
					parah += x>=wavemin(parah2x) && x<=wavemax(parah2x) ? interp(x,parah2x,parah2) : 0
					parah /= x>=wavemin(parah2x) && x<=wavemax(parah2x)  && x>=wavemin(parah1x) && x<=wavemax(parah1x) ? 2 : 1
				else
					minq=wavemin(parah1x)
					maxq=wavemax(parah1x)
					setscale /i x,minq,maxq,parah, parahx
					parahx = x
					parah =interp(x,parah1x,parah1)
				endif
			else
				wave parah1 = waves[hr]
				wave parah1x = xwaves[hr]
				minq=wavemin(parah1x)
				maxq=wavemax(parah1x)
				setscale /i x,minq,maxq,parah, parahx
				parahx = x
				parah =interp(x,parah1x,parah1)
			endif
			Note parah, wnote
			//appendtograph /w=gname parah /TN=$basename vs parahx
		endif
		if((vr<0 && vl<0) || (vu<0 && vd<0))
			// vertical polarization is not complete, so skip it
		else
			make /o /n=1000 $cleanupname(basename+"_perpv",1), $cleanupname(basename+"_perpvx",1), $cleanupname(basename+"_parav",1), $cleanupname(basename+"_paravx",1)
			wave perpv = $cleanupname(basename+"_perpv",1)
			wave perpvx = $cleanupname(basename+"_perpvx",1)
			wave parav = $cleanupname(basename+"_parav",1)
			wave paravx = $cleanupname(basename+"_paravx",1)
			if(vr>=0)
				wave perpv1 = waves[vr]
				wnote = note(perpv1)
				wave perpv1x = xwaves[vr]
				if(vl>=0)
					wave perpv2 = waves[vl]
					wave perpv2x = xwaves[vl]
					minq=min(wavemin(perpv2x),wavemin(perpv1x))
					maxq=max(wavemax(perpv2x),wavemax(perpv1x))
					
					setscale /i x,minq,maxq,perpv, perpvx
					perpvx=x
					perpv = x>=wavemin(perpv1x) && x<=wavemax(perpv1x) ? interp(x,perpv1x,perpv1) : 0
					perpv += x>=wavemin(perpv2x) && x<=wavemax(perpv2x) ? interp(x,perpv2x,perpv2) : 0
					perpv /= x>=wavemin(perpv2x) && x<=wavemax(perpv2x)  && x>=wavemin(perpv1x) && x<=wavemax(perpv1x) ? 2 : 1
				else
					minq=wavemin(perpv1x)
					maxq=wavemax(perpv1x)
					setscale /i x,minq,maxq,perpv, perpvx
					perpvx = x
					perpv =interp(x,perpv1x,perpv1)
				endif
			else
				wave perpv1 = waves[vl]
				wnote = note(perpv1)
				wave perpv1x = xwaves[vl]
				minq=wavemin(perpv1x)
				maxq=wavemax(perpv1x)
				setscale /i x,minq,maxq,perpv, perpvx
				perpvx = x
				perpv =interp(x,perpv1x,perpv1)
			endif
			Note perpv, wnote
			
			//appendtograph /w=gname perpv /TN=$basename vs perpvx
			if(vd>=0)
				wave parav1 = waves[vd]
				wave parav1x = xwaves[vd]
				if(vu>=0)
					wave parav2 = waves[vu]
					wave parav2x = xwaves[vu]
					minq=min(wavemin(parav2x),wavemin(parav1x))
					maxq=max(wavemax(parav2x),wavemax(parav1x))
					
					setscale /i x,minq,maxq,parav, paravx
					paravx=x
					parav = x>=wavemin(parav1x) && x<=wavemax(parav1x) ? interp(x,parav1x,parav1) : 0
					parav += x>=wavemin(parav2x) && x<=wavemax(parav2x) ? interp(x,parav2x,parav2) : 0
					parav /= x>=wavemin(parav2x) && x<=wavemax(parav2x)  && x>=wavemin(parav1x) && x<=wavemax(parav1x) ? 2 : 1
				else
					minq=wavemin(parav1x)
					maxq=wavemax(parav1x)
					setscale /i x,minq,maxq,parav, paravx
					paravx = x
					parav =interp(x,parav1x,parav1)
				endif
			else
				wave parav1 = waves[vu]
				wave parav1x = xwaves[vu]
				minq=wavemin(parav1x)
				maxq=wavemax(parav1x)
				setscale /i x,minq,maxq,parav, paravx
				paravx = x
				parav =interp(x,parav1x,parav1)
			endif
			Note parav, wnote
			//appendtograph /w=gname parav /TN=$basename vs paravx
		endif
		
		// use the parallel and perpindicular waves to calculate A (anisotropy) for each polarization, then average as possible to create a single A
		
		if(waveexists(parah) &&waveexists(perph))
			make /o/n=1000 $cleanupname(basename+"_Ah",1), $cleanupname(basename+"_Ahx",1)
			wave Ah = $cleanupname(basename+"_Ah",1)
			wave Ahx = $cleanupname(basename+"_Ahx",1)
			minq=max(wavemin(parahx),wavemin(perphx))
			maxq = min(wavemax(parahx),wavemax(perphx))
			setscale /i x,minq,maxq, Ah, Ahx
			Ahx = x
			Ah = (interp(Ahx,parahx,parah) - interp(Ahx,perphx,perph))/(interp(Ahx,parahx,parah) + interp(Ahx,perphx,perph))
			duplicate /o Ah,  $cleanupname(basename+"_A",1)
			duplicate /o Ahx, $cleanupname(basename+"_Ax",1)
			wave A = $cleanupname(basename+"_A",1)
			wave Ax = $cleanupname(basename+"_Ax",1)
		endif
		if(waveexists(parav) && waveexists(perpv))
			make /o/n=1000 $cleanupname(basename+"_Av",1), $cleanupname(basename+"_Avx",1)
			wave Av = $cleanupname(basename+"_Av",1)
			wave Avx = $cleanupname(basename+"_Avx",1)
			minq=max(wavemin(paravx),wavemin(perpvx))
			maxq = min(wavemax(paravx),wavemax(perpvx))
			setscale /i x,minq,maxq, Av, Avx
			Avx = x
			Av = (interp(Avx,paravx,parav) - interp(Avx,perpvx,perpv))/(interp(Avx,paravx,parav) + interp(Avx,perpvx,perpv))
			if(waveexists(A))
				minq=min(wavemin(Avx),wavemin(Ahx))
				maxq=max(wavemax(Avx),wavemax(Ahx))
				setscale /i x,minq,maxq, A,Ax
				Ax=x
				A = x>=wavemin(Avx) && x<=wavemax(Avx) ? interp(x,Avx,Av) : 0
				A+=x>=wavemin(Ahx) && x<=wavemax(Ahx) ? interp(x,Ahx,Ah) : 0
				A /= x>=wavemin(Ahx) && x<=wavemax(Ahx) && x>=wavemin(Avx) && x<=wavemax(Avx) ? 2 : 1
			else
				duplicate /o Av,$cleanupname(basename+"_A",1)
				duplicate /o Avx,$cleanupname(basename+"_Ax",1)
				wave A = $cleanupname(basename+"_A",1)
				wave Ax = $cleanupname(basename+"_Ax",1)
			endif
		endif
		note A, wnote
		note Ax, wnote
		//  Plot all of the As together on a new graph
		//appendtograph /w=$gname A /TN=$basename vs Ax
		
		// integrate As and plot vs energy (for only certain q range?)
		index = dimsize(Atot,0)
		insertpoints index,1,Atot,En,awaves, axwaves
		Atot[index] = mean(A)
		En[index] = numberbykey("BeamlineEnergy",wnote,"=",";")
		Awaves[index] = $getwavesdatafolder(A,2)
		Axwaves[index] = $getwavesdatafolder(Ax,2)
		killwaves /z asdf
		wave /z A = asdf
		wave /z Ax = asdf
		wave /z perph = asdf
		wave /z perphx = asdf
		wave /z parah = asdf
		wave /z parahx = asdf
		wave /z perpv = asdf
		wave /z perpvx = asdf
		wave /z parav = asdf
		wave /z paravx = asdf
	endfor
	// make energy vs anisotropy vs q imageplot
	sort En, Atot, En, Awaves, Axwaves
	minq = 0
	maxq = 100000
	for(j=0;j<index;j+=1)
		minq = max(wavemin(Axwaves[j]),minq)
		maxq = min(wavemax(Axwaves[j]),maxq)
	endfor
	make /free/n=(index,200) UnScaledMesh
	redimension /n=(200,200) Mesh
	setscale /i y,minq,maxq,UnScaledMesh
	setscale /i x,minq,maxq, Mesh
	for(j=0;j<index;j+=1)
		wave tempx = Axwaves[j]
		wave temp = Awaves[j]
		unscaledMesh[j][] = interp(y,tempx,temp)
	endfor
	make /n=(index) /free tempwave
	setscale /i y,en[0],en[index],Mesh
	for(j=0;j<200;j+=1)
		tempwave = unscaledMesh[p][j]
		mesh[j][] = interp(y,en,tempwave)
	endfor
	if(normtoFirstEn)
		wave tempx = Axwaves[0]
		wave temp = Awaves[0]
		mesh[][] -= interp(x,tempx,temp)
	endif
	appendimage /w=$imagename/T mesh
	ModifyImage /w=$imagename ''#0 ctab= {-0.5,0.5,RedWhiteBlue,0}
	ModifyGraph /w=$imagename margin(left)=47,margin(bottom)=14,margin(top)=44,margin(right)=71,log(top)=1
	ModifyGraph /w=$imagename mirror=2, minor=1, fSize=14, standoff=0, tkLblRot(left)=90, btLen=3, tlOffset=-2
	Label /w=$imagename left "X-ray Energy [eV]"
	Label /w=$imagename top "Momentum Transfer q [nm\\S-1\\M]"
	SetAxis/A/R /w=$imagename left
	ColorScale /w=$imagename/C/N=text0/F=0/S=3/A=RC/X=0/Y=0/E image=''#0
	AppendText "Anisotropy"
	
	appendtograph /w=$avenname Atot vs En
	ModifyGraph /w=$avenname mode=4,marker=19,rgb=(0,0,0)
	SetAxis /w=$avenname left -0.2,0.2
	setdatafolder foldersave
end

Window GroupPlotWin() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(676,57,1317,661) as "Group Plotting"
	ShowTools/A
	SetDrawLayer UserBack
	Button GroupPlotButton,pos={5,533},size={119,65},title="Do It!"
	SetVariable setvar0,pos={5,508},size={268,16},title="Name of Group :"
	SetVariable setvar0,value= _STR:""
	SetVariable setvar1,pos={5,485},size={318,16},title="Find 1D conversions matching :"
	SetVariable setvar1,value= _STR:""
	SetVariable setvar2,pos={7,33},size={188,16},title="X-Axis to use :"
	SetVariable setvar2,value= _STR:""
	GroupBox PlottingOptions,pos={414,13},size={214,312},title="Plotting Options"
	GroupBox YaxisOptions,pos={206,13},size={200,313},title="Y-axis options"
	GroupBox XaxisOptions,pos={4,13},size={196,310},title="X-axis options"
	GroupBox ImagePlotOptions,pos={5,331},size={623,147},title="Image Plot Options"
	PopupMenu popup0,pos={12,424},size={200,21},mode=1,value= #"\"*COLORTABLEPOP*\""
	SetVariable GStylevar,pos={429,75},size={188,16},title="Use Style :"
	SetVariable GStylevar,value= _STR:""
	CheckBox useColorStyleChk,pos={429,53},size={128,14},title="Use Image Color Style?"
	CheckBox useColorStyleChk,value= 0
	SetVariable FolderNameVar,pos={346,486},size={272,16},title="Folder to put new waves :"
	SetVariable FolderNameVar,value= _STR:""
	CheckBox ImagePlotChk,pos={12,354},size={125,14},title="Plot an Image of data?"
	CheckBox ImagePlotChk,value= 0
	CheckBox useColorStyleChk2,pos={429,32},size={133,14},title="Plot 1D Data individually"
	CheckBox useColorStyleChk2,value= 0
	CheckBox AtoNMchk,pos={7,157},size={165,14},title="Change from Angstroms to nm?"
	CheckBox AtoNMchk,value= 0
	SetVariable QPwrVar,pos={429,97},size={188,16},title="Q Scaling Pwr :"
	SetVariable QPwrVar,value= _NUM:0
	SetVariable OffsetPwrVar,pos={429,118},size={188,16},title="Trace Offset Pwr :"
	SetVariable OffsetPwrVar,value= _NUM:0
	CheckBox ContPlotChk,pos={12,377},size={145,14},title="Plot a ContourPlot of data?"
	CheckBox ContPlotChk,value= 0
	CheckBox RevQChk,pos={7,53},size={83,14},title="Invert x data?",value= 0
	CheckBox LogQChk,pos={7,74},size={86,14},title="log x spacing?",value= 0
	CheckBox LogSurfChk,pos={12,400},size={106,14},title="log scale Surface?"
	CheckBox LogSurfChk,value= 0
	SetVariable SmoothVar,pos={211,42},size={188,16},title="Smoothing pnts (odd >11) :"
	SetVariable SmoothVar,value= _NUM:0
	SetVariable NSmoothVar,pos={211,64},size={188,16},title="Number of Smooths :"
	SetVariable NSmoothVar,value= _NUM:0
	SetVariable MaxQvar,pos={7,115},size={188,16},title="Maximum X Value :"
	SetVariable MaxQvar,value= _NUM:0
	SetVariable MinimumQvar,pos={7,95},size={188,16},title="Minimum X Value :"
	SetVariable MinimumQvar,value= _NUM:0
	SetVariable QPntsVar,pos={7,136},size={188,16},title="Number of X pnts :"
	SetVariable QPntsVar,value= _NUM:0
	SetVariable MinimumEnvar,pos={197,376},size={188,16},title="Minimum Y Value :"
	SetVariable MinimumEnvar,value= _NUM:0
	SetVariable MaxEnvar,pos={410,376},size={188,16},title="Maximum Y Value :"
	SetVariable MaxEnvar,value= _NUM:0
	SetVariable setvar3,pos={197,352},size={414,16},title="Y-Axis to use (use \"header-xxx\" to find value in header of wave) :"
	SetVariable setvar3,value= _STR:""
	CheckBox addtographVar,pos={429,140},size={114,14},title="Add to existing Plot?"
	CheckBox addtographVar,value= 0
	CheckBox StayInFolderChk,pos={480,509},size={113,14},title="Stay in New Folder?"
	CheckBox StayInFolderChk,value= 0
	SetVariable SmoothVar1,pos={197,400},size={188,16},title="Smoothing Surface Y axis pnts :"
	SetVariable SmoothVar1,value= _NUM:0
	SetVariable GStylevar1,pos={211,86},size={188,16},title="Normalization wave:"
	SetVariable GStylevar1,value= _STR:""
	CheckBox addnmaxischk,pos={429,162},size={111,14},title="Add nm axis labels?"
	CheckBox addnmaxischk,value= 0
	CheckBox addlegendchk,pos={429,184},size={78,14},title="Add legend?",value= 0
	CheckBox StayInFolderChk1,pos={298,509},size={158,14},title="Use waves created by NIKA?"
	CheckBox StayInFolderChk1,value= 0
	SetVariable CombineVar,pos={137,556},size={480,16},title="Combine String (differing strings seperated by comma(s)) :"
	SetVariable CombineVar,value= _STR:""
	SetVariable CombineVar1,pos={137,581},size={480,16},title="Combine overlaps (pnts, seperated by commas) :"
	SetVariable CombineVar1,value= _STR:""
	CheckBox PorodChk,pos={211,108},size={97,14},title="Porod Integrate?",value= 0
	SetVariable PorodMinVar,pos={211,130},size={188,16},title="Minimum Porod X Value :"
	SetVariable PorodMinVar,value= _NUM:0
	SetVariable PorodMaxvar,pos={211,152},size={188,16},title="Maximum Porod X Value :"
	SetVariable PorodMaxvar,value= _NUM:0
	SetVariable HeaderKeyvar,pos={137,532},size={211,16},title="Header Key to Match :"
	SetVariable HeaderKeyvar,value= _STR:""
	SetVariable HeaderValuevar,pos={356,532},size={119,16},title="Header Value :"
	SetVariable HeaderValuevar,value= _NUM:0
	SetVariable HeaderValuevar1,pos={483,532},size={134,16},title="Header Precision :"
	SetVariable HeaderValuevar1,value= _NUM:0
	CheckBox NormalizeChk,pos={211,174},size={122,14},title="Normalize at X Value?"
	CheckBox NormalizeChk,value= 0
	SetVariable NormalizeValueVar,pos={211,196},size={188,16},title="Normalize at X Value :"
	SetVariable NormalizeValueVar,value= _NUM:0
	SetVariable NormalizeWidthVar,pos={211,218},size={188,16},title="Normalize X Width :"
	SetVariable NormalizeWidthVar,value= _NUM:0
EndMacro
