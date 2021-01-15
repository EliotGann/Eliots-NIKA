#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//#include "EGN_Loader"
#include <Multi-peak fitting 2.0>
#include "wa_procs"
//#include "3DSimulationsv3"
//#include "GIWAXSLatticeCalcs"
function /s time2str_gwa(secs)
	variable secs
	string timestr
	variable hours, minutes, seconds
	hours = floor(secs / 3600)
	minutes = floor(secs / 60) - 60*hours
	seconds = secs -60*minutes - 3600*hours
	if(hours>0)
		sprintf timestr "%d:%02d:%02d", hours, minutes, seconds
	elseif(minutes>0)
		sprintf timestr "%d:%02d", minutes, seconds
	else
		if(seconds<1e-9)
			sprintf timestr "%03.2f ps", (seconds*1e12)
		elseif(seconds<1e-6)
			sprintf timestr "%03.2f ns", (seconds*1e9)
		elseif(seconds<1e-3)
			sprintf timestr "%03.2f µs", (seconds*1e6)
		elseif(seconds<1)
			sprintf timestr "%03.2f ms", (seconds*1e3)
		else
			sprintf timestr "0:%02d s", seconds
		endif
	endif
	return timestr
end
function simplepeakfittopgraph()
	string name = WinName(0, 1) 
	string foldersave = getdatafolder(1)
	setdatafolder root:
	newdatafolder /o/s AutoPeakFits
	dowindow /k $(name+"vtemp")
	dowindow /k $(name+"pvtime")
	dowindow /k peakinfo
	killdatafolder /z $name
	newdatafolder/o/s $name
	killwaves/z/a
	string tracelist = TraceNameList("", ";", 1 )
	string wavenames = "", xwaves = ""
	variable i
	for(i=0;i<itemsinlist(tracelist,";");i+=1)
		wavenames += GetWavesDataFolder(TraceNameToWaveRef(name, stringfromlist(i,tracelist) ), 2 ) + ";"
		xwaves +=GetWavesDataFolder(XWaveRefFromTrace(name, stringfromlist(i,tracelist) ), 2 ) + ";"
	endfor
	
	//this one is better for out of plane data
	Variable V_fitOptions=4
	variable v_fiterror=0
	print "Finding All Peaks"
	variable timesofar = 0
	variable timcount
	variable timer = startmstimer
	
	//this line is better for in-plane data (more sensitive)
	//variable error = MPF2_AutoMPFit(name, "Lorentzian", "peakCoef%d", "LogCubic", "Background", wavenames, xwaves, 5 ,minAutoFindFraction=.001,noiseEst=4,smFact=10)
	variable error = MPF2_AutoMPFit(name, "Gauss", "peakCoef%d", "LogPoly5", "Background", wavenames, xwaves, 5 ,minAutoFindFraction=.01,noiseEst=1,smFact=12)
	timesofar += stopmstimer(timer)
	timer=startmstimer
	print "Found all peaks in " + time2str_gwa(timesofar/10^6) 
	if(error!=0)
		print "Error " + num2str(error) +" found"
	endif
	string parentdirectory = getdatafolder(1), timevar
	variable goods=0,bads=0, grazingangle, num=CountObjects(parentdirectory, 4 ), j, tempvar,  heighttest, peaktest, widthtest, heighterrortest
	variable peakerrortest, widtherrortest, goodfit, k, testval, found2ndorder, found3rdorder
	string temps="", names="", times="", peaks="", widths="", heights="", peakerrors="", widtherrors="", heighterrors="", omegas="",testpeakset, WAresult, testpeaknumbers, 	tempdataname
	string allWAResults ="NameofDataset\tChisqr\te\ts_e\tg\ts_g\tM\ts_M\tmw\ts_mw" + "\tdSpacing" + "\tTemperature" + "\ttime" + "\tgrazingangle" + "\tnumPeaks;"
	variable numpeaks
	for(i=0;i<num;i+=1)
		setdatafolder parentdirectory
		setdatafolder GetIndexedObjName("", 4, i )
		nvar/z gNumPeaks
		wave/z datawave = $stringfromlist(i,wavenames)
		wave/z xwave = $stringfromlist(i,xwaves)
		if(nvar_exists(gNumPeaks)==0 || waveexists(datawave)==0)
			continue
		endif
		tempvar = i//numberbykey("Wavelength",note(datawave),"=",";")
		timevar = stringbykey("NUMERICTIMESTAMP",note(datawave),"=",";")
		grazingangle = numberbykey("SAMPLEOMEGA",note(datawave),"=",";")
		
		//make empty peak group text wave, each element of which will be a list of related peaks locations (ie peaks=100,200,300;), and adjusteddataasetwavename (data=wname;)
		make /t/o/n=0 peaklocs // the peak sets which can be found in this dataset and the peak numbers
		make /o/n=0 centralpeakloc // the average d spacing for each peak set found // should be used to calculate the widths for WA calcs
		make /o/n=(gnumpeaks) goodpeaklocs, goodpeaknums // list of all peaks which pass through our checks, and are considered for peaksets
		numpeaks=0
		for(j=0;j<gnumpeaks;j+=1)
			wave/z coefwave = $("peakCoef"+num2str(j))
			wave/z sigmawave = $("W_sigma_"+num2str(j+1))
			if(!waveexists(coefwave))
				bads +=1
				continue
			endif
			peaktest = coefwave[0]
			widthtest = abs(coefwave[1])
			heighttest = coefwave[2]
			goodfit=1
			if(waveexists(sigmawave))
				peakerrortest = abs(sigmawave[0])
				widtherrortest = abs(sigmawave[1])
				heighterrortest = abs(sigmawave[2])
				goodfit *= peakerrortest > peaktest || heighterrortest > heighttest  || widtherrortest > widthtest ? 0 : 1
			else
				peakerrortest = nan
				widtherrortest = nan
				heighterrortest = nan
			endif
			goodfit *= peaktest < .02 || peaktest>.1 ? 0 : 1
			goodfit *= widthtest < .001 || widthtest>4 ? 0 : 1
			goodfit *= heighttest < 0 || heighttest>10^8 ? 0 : 1
			
			if(goodfit)
				// record peak attributes
				names += stringfromlist(i,wavenames) + ";"
				temps += num2str(tempvar)+ ";"
				omegas += num2str(grazingangle)+ ";"
				times += timevar+ ";"
				peaks += num2str(2*pi/peaktest)+ ";"
				widths += num2str(widthtest)+ ";"
				heights += num2str(heighttest)+ ";"
				peakerrors += num2str(peakerrortest)+ ";"
				widtherrors += num2str(widtherrortest)+ ";"
				heighterrors += num2str(heighterrortest)+ ";"
				goods+=1
				goodpeaklocs[numpeaks]=peaktest
				goodpeaknums[numpeaks]=j
				numpeaks+=1
			else
				bads +=1
			endif
		endfor
		redimension /n=(numpeaks) goodpeaklocs, goodpeaknums
		sort goodpeaklocs, goodpeaklocs, goodpeaknums // means we will start with the largest peak that we found and decrease from there
//		for(k=0;k<numpeaks;k+=1)
//			testval = goodpeaklocs[k]
//			testpeakset = num2str(testval) + ","
//			testpeaknumbers = num2str(goodpeaknums[k]) + ","
//			// Check if we have already included this peak in a set
//			findvalue /TEXT=(num2str(testval)) /txop=0 peaklocs 
//			// unfortunately this only looks for exact matches, but if we found a peak before (which we had a tolerence for), we used the exact value, so this should be alright
//			// this may pick up 6th order peaks and stuff which will be unfortunate, but it will be simple to pick out of data
//			if(v_value>=0)
//				continue
//			endif
//			//  once we have the first order peak, search for reflections 1-4
//			found2ndorder=0
//			found3rdorder=0
//			findvalue /V=(2*testval) /T=(testval/10) /Z goodpeaklocs
//			if(v_value>0) // is there a second order peak
//				testpeakset += num2str(goodpeaklocs[v_value]) + ","
//				testpeaknumbers += num2str(goodpeaknums[v_value]) + ","
//				found2ndorder = 1
//				testval = (goodpeaklocs[v_value] + testval)/3
//			endif
//			findvalue /V=(3*testval) /T=(testval/7) /Z goodpeaklocs
//			if(v_value>0) // is there a third order peak
//				found3rdorder = 1
//				if(found2ndorder)
//					testpeakset += num2str(goodpeaklocs[v_value]) + ","
//					testpeaknumbers += num2str(goodpeaknums[v_value]) + ","
//					testval = (goodpeaklocs[v_value]/3 + testval)/2
//				else
//					testval = (goodpeaklocs[v_value]/3 + testval)/2
//					testpeakset += num2str(testval*2) + "," // add in where second order should have been - the multi peak fit may have just missed it
//					// we do't add a peak number, because there isn't one
//					found2ndorder=1
//					testpeakset += num2str(goodpeaklocs[v_value]) + ","
//				endif
//			endif
//			findvalue /V=(4*testval) /T=(testval/7) /Z goodpeaklocs
//			if(v_value>0) // is there a fourth order peak
//				if(found2ndorder)
//					if(found3rdorder)
//						testpeakset += num2str(goodpeaklocs[v_value]) + ","
//						testpeaknumbers += num2str(goodpeaknums[v_value]) + ","
//						testval = (goodpeaklocs[v_value]/4 + testval)/2
//					else
//						testval = (goodpeaklocs[v_value]/4 + testval)/2
//						testpeakset += num2str(testval*3) + "," // add in where third order should have been - the multi peak fit may have just missed it
//						testpeakset += num2str(goodpeaklocs[v_value]) + ","
//						testpeaknumbers += num2str(goodpeaknums[v_value]) + ","
//					endif
//				else
//					testval = (goodpeaklocs[v_value]/4 + testval)/2
//					testpeakset += num2str(testval*2) + "," // add in where second order should have been - the multi peak fit may have just missed it
//					testpeakset += num2str(testval*3) + "," // add in where third order should have been - the multi peak fit may have just missed it
//					testpeakset += num2str(goodpeaklocs[v_value]) + ","
//					testpeaknumbers += num2str(goodpeaknums[v_value]) + ","
//				endif
//				// at this point we will go ahead and make two possitilibites, one including fifth order and one just including up to 4th order
//				insertpoints 0,1, peaklocs, centralpeakloc
//				centralpeakloc[0] = testval
//				peaklocs[0] = "peaks="+testpeakset+";nums="+testpeaknumbers
//				testpeakset += num2str(testval*5) + "," // add in where fifth might be
//				insertpoints 0,1, peaklocs, centralpeakloc
//				centralpeakloc[0] = testval
//				peaklocs[0] = "peaks="+testpeakset+";nums="+testpeaknumbers
//			else
//				if(found3rdorder) // we only found up to order 3, so try adding a fourth
//					insertpoints 0,1, peaklocs, centralpeakloc
//					centralpeakloc[0] = testval
//					peaklocs[0] = "peaks="+testpeakset+";nums="+testpeaknumbers
//					testpeakset += num2str(testval*4) + "," // add in where fourth peak might be
//					insertpoints 0,1, peaklocs, centralpeakloc
//					centralpeakloc[0] = testval
//					peaklocs[0] = "peaks="+testpeakset+";nums="+testpeaknumbers
//				elseif(found2ndorder) // we only found up to 2, so try adding in a third // two peaks is likely too little to work with
//					insertpoints 0,1, peaklocs, centralpeakloc
//					centralpeakloc[0] = testval
//					peaklocs[0] = "peaks="+testpeakset+";nums="+testpeaknumbers
//					testpeakset += num2str(testval*3) + "," // add in where third peak might be
//					insertpoints 0,1, peaklocs, centralpeakloc
//					centralpeakloc[0] = testval
//					peaklocs[0] = "peaks="+testpeakset+";nums="+testpeaknumbers
//				endif
//			endif
//		endfor // runs through all the peaks which were found in this dataset
//		// for each peak group found, do the WA analysis
//		timesofar += stopmstimer(timer)
//		timer=startmstimer
//		print time2str_gwa(timesofar/10^6) +" Analyzing peaks ("+num2str(i+1)+"/"+num2str(num)+")  - in "+ nameofwave(datawave)
//		for(j=0;j<dimsize(peaklocs,0);j+=1)
//			tempdataname = cleanupname("t_"+nameofwave(datawave),1)
//			duplicate /o datawave, $tempdataname
//			wave tempdata = $tempdataname
//			removepeaksfromdata(tempdata, xwave, stringbykey("nums",peaklocs[j],"=",";"),"Gauss", "peakCoef%d","Constant", "Background")
//			WAresult = CalcWA(tempdata,xwave,stringbykey("peaks",peaklocs[j],"=",";"),centralpeakloc[j]/4,200,5,1)
//			if(str2num(stringfromlist(1,WAresult,"\t"))<10) // was the WA fit ok?
//				allWAResults += WAresult  + num2str(centralpeakloc[j])  + "\t" + num2str(tempvar)  + "\t" + timevar + "\t" + num2str(grazingangle) + "\t" + num2str(itemsinlist(stringbykey("peaks",peaklocs[j],"=",";"),",") ) + ";"
//			endif
//		endfor
	endfor
	Print num2str(goods) + " good peaks were found and " + num2str(bads) + " bad peaks were thrown out."
	setdatafolder parentdirectory
	num = itemsinlist(temps)
	make /o/n=(num) temp,timestamp, peakloc, peakwidth, peakheight, peaklocerr, peakwidtherr, peakheighterr, omega
	make /o/t /n=(num) dataname
	dataname = stringfromlist(p,names)
	omega = str2num(stringfromlist(p,omegas))
	temp = str2num(stringfromlist(p,temps))
	timestamp = str2num(stringfromlist(p,times))
	peakloc = str2num(stringfromlist(p,peaks))
	peakwidth = str2num(stringfromlist(p,widths))
	peakheight = str2num(stringfromlist(p,heights))
	peaklocerr = str2num(stringfromlist(p,peakerrors))
	peakwidtherr = str2num(stringfromlist(p,widtherrors))
	peakheighterr = str2num(stringfromlist(p,heighterrors))
	duplicate/o peakwidth, coherence, coherenceerror
	coherence = 2*pi/peakwidth
	coherenceerror = 2*pi/(peakwidth^2) * peakwidtherr
	
	//sort timestamp, temp,timestamp, peakloc, peakwidth, peakheight, peaklocerr, peakwidtherr, peakheighterr, omega, dataname, coherence,coherenceerror
	sort temp, temp,timestamp, peakloc, peakwidth, peakheight, peaklocerr, peakwidtherr, peakheighterr, omega, dataname, coherence,coherenceerror
	edit /k=1 /n=Peakinfo dataname, temp,timestamp, peakloc, peakwidth, peakheight, peaklocerr, peakwidtherr, peakheighterr, omega, coherence,coherenceerror
	
	variable mintime = wavemin(timestamp)
	timestamp -= mintime
	
	// adding for depth profiling
	dowindow /k depthprofilingplot
	display /k=1 /n=depthprofilingplot coherence vs temp
	appendtograph /w=depthprofilingplot /r=size peakheight vs temp
	appendtograph /w=depthprofilingplot /r=loc peakloc vs temp
	SetAxis /w=depthprofilingplot/A
	ModifyGraph /w=depthprofilingplot mode=4
	ModifyGraph /w=depthprofilingplot margin(right)=142
	ModifyGraph /w=depthprofilingplot mirror=0
	ModifyGraph /w=depthprofilingplot freePos(size)=80,axRGB(size)=(0,26112,13056),axRGB(loc)=(0,0,65280);DelayUpdate
	ModifyGraph /w=depthprofilingplot tlblRGB(size)=(0,26112,13056),tlblRGB(loc)=(0,0,65280);DelayUpdate
	ModifyGraph /w=depthprofilingplot alblRGB(size)=(0,26112,13056),alblRGB(loc)=(0,0,65280)
	Label /w=depthprofilingplot size "Peak Height [AU]"
	Label /w=depthprofilingplot loc "D-Spacing [nm]"
	Label /w=depthprofilingplot left "Coherence Length [nm]"
	ModifyGraph /w=depthprofilingplot mode=0,lsize=2,rgb(coherence)=(0,0,0),rgb(peakheight)=(0,26112,13056)
	ModifyGraph /w=depthprofilingplot rgb(peakloc)=(0,0,65280)
	ErrorBars /w=depthprofilingplot peakheight Y,wave=(peakheighterr,peakheighterr);DelayUpdate
	ErrorBars /w=depthprofilingplot peakloc Y,wave=(peaklocerr,peaklocerr)
	ErrorBars /w=depthprofilingplot coherence Y,wave=(coherenceerror,coherenceerror)
	ModifyGraph tick=2,lblPosMode(loc)=3,lblPos(size)=60,lblPos(loc)=60,standoff=0;DelayUpdate
	ModifyGraph freePos(loc)=0,mirror(bottom)=1,minor=1
	setwindow depthprofilingplot, hook(mouseuphook) = DepthPointDeleterWindowHook
	
	display /k=1/n=$(NAME+"_depth") peakloc vs temp
	ModifyGraph MIRROR=1,mode=3,marker=19,logZColor=1,zmrkSize(peakloc)={coherence,*,30,1,6};DelayUpdate
	ModifyGraph zColor(peakloc)={peakheight,*,*,YellowHot,1},minor=1
	ErrorBars peakloc Y,wave=(peaklocerr,peaklocerr)
	ModifyGraph log(left)=1
	Label left "D-Spacing [nm]"
	Label bottom "Omega [deg]"
	
	// plotting for peak shape analysis plotting
//	display /W=(35.25,42.5,474.75,679.25) /n=$(name+"vtemp") peakloc vs omega
//	ModifyGraph mode=3,marker=19
//	ModifyGraph grid=1,tick=2,mirror=1,minor=1,standoff=0,gridStyle=3;DelayUpdate
//	Label left "Spacing [Å]";DelayUpdate
//	Label bottom "Temperature [°C]"
//	ModifyGraph logZColor=1,zmrkSize(peakloc)={peakwidth,*,0.1,6,1}
//	ModifyGraph zColor(peakloc)={peakheight,*,*,YellowHot,1}
//	display /W=(465,45.5,904.5,682.25) /n=$(name+"pvtime") peakloc vs timestamp
//	ModifyGraph mode=3,marker=19
//	ModifyGraph grid=1,tick=2,mirror=1,minor=1,standoff=0,gridStyle=3;DelayUpdate
//	Label left "Spacing [Å]";DelayUpdate
//	Label bottom "Time [sec] \\U"
//	ModifyGraph logZColor=1,zmrkSize(peakloc)={peakwidth,*,0.1,6,1}
//	ModifyGraph zColor(peakloc)={peakheight,*,*,YellowHot,1}
//	
//	// split out WA results plot later, maybe
//	variable wanum = itemsinlist(allWAResults)-1
//	make /o/n=(wanum) /t wa_name
//	make /o/n=(wanum) wa_chisqr, wa_e, wa_e_s, wa_g, wa_g_s, wa_M, wa_M_s, wa_mw, wa_wm_s, wa_dspacing, wa_temp, wa_time, wa_grazingangle, wa_numpeaks
//	wa_name = stringfromlist(0,stringfromlist(p+1,allWAResults),"\t")
//	wa_chisqr = str2num(stringfromlist(1,stringfromlist(p+1,allWAResults),"\t"))
//	wa_e = str2num(stringfromlist(2,stringfromlist(p+1,allWAResults),"\t"))
//	wa_e_s = str2num(stringfromlist(3,stringfromlist(p+1,allWAResults),"\t"))
//	wa_g = str2num(stringfromlist(4,stringfromlist(p+1,allWAResults),"\t"))
//	wa_g_s = str2num(stringfromlist(5,stringfromlist(p+1,allWAResults),"\t"))
//	wa_M = str2num(stringfromlist(6,stringfromlist(p+1,allWAResults),"\t"))
//	wa_M_s = str2num(stringfromlist(7,stringfromlist(p+1,allWAResults),"\t"))
//	wa_mw = str2num(stringfromlist(8,stringfromlist(p+1,allWAResults),"\t"))
//	wa_wm_s = str2num(stringfromlist(9,stringfromlist(p+1,allWAResults),"\t"))
//	wa_dspacing = str2num(stringfromlist(10,stringfromlist(p+1,allWAResults),"\t"))
//	wa_temp = str2num(stringfromlist(11,stringfromlist(p+1,allWAResults),"\t"))
//	wa_time = str2num(stringfromlist(12,stringfromlist(p+1,allWAResults),"\t"))
//	wa_grazingangle = str2num(stringfromlist(13,stringfromlist(p+1,allWAResults),"\t"))
//	wa_numpeaks = str2num(stringfromlist(13,stringfromlist(p+1,allWAResults),"\t"))
//	putscraptext replacestring(";",allWAResults,"\r")
//	edit wa_name, wa_chisqr, wa_e, wa_e_s, wa_g, wa_g_s, wa_M, wa_M_s, wa_mw, wa_wm_s, wa_dspacing, wa_temp, wa_time, wa_grazingangle, wa_numpeaks
//	sort wa_time, wa_name, wa_chisqr, wa_e, wa_e_s, wa_g, wa_g_s, wa_M, wa_M_s, wa_mw, wa_wm_s, wa_dspacing, wa_temp, wa_time, wa_grazingangle, wa_numpeaks
//	sort wa_grazingangle, wa_name, wa_chisqr, wa_e, wa_e_s, wa_g, wa_g_s, wa_M, wa_M_s, wa_mw, wa_wm_s, wa_dspacing, wa_temp, wa_time, wa_grazingangle, wa_numpeaks
//	sort wa_numpeaks, wa_name, wa_chisqr, wa_e, wa_e_s, wa_g, wa_g_s, wa_M, wa_M_s, wa_mw, wa_wm_s, wa_dspacing, wa_temp, wa_time, wa_grazingangle, wa_numpeaks
//	
//	display wa_M vs wa_time
//	ModifyGraph mode=3,marker=19
//	appendtograph wa_temp vs wa_time
//	ModifyGraph mode=3
//	appendtograph wa_g vs wa_time
//	RemoveFromGraph wa_g
//	appendtograph/r wa_g vs wa_time
//	ModifyGraph mode=3,marker(wa_g)=5,rgb(wa_g)=(0,0,0)
//	ModifyGraph marker(wa_M)=8,rgb(wa_M)=(0,0,65280);appendtograph /r=dspacing wa_dspacing vs wa_time
//	ModifyGraph mode=3,rgb(wa_g)=(0,52224,0),rgb(wa_dspacing)=(0,0,0)
//	wa_dspacing = 2*pi/wa_dspacing
//	ModifyGraph marker(wa_temp)=23
	SetAxis/A
	setdatafolder foldersave
	dowindow /f name
end

Function DepthPointDeleterWindowHook(s)
	STRUCT WMWinHookStruct &s
	Switch(s.eventcode)
		case 5: // mouseup
			string foldersave = getdatafolder(1)
			variable mouseX = s.mouseloc.h
			variable mouseY = s.mouseloc.v
			string tracestr = TraceFromPixel(mouseX, mouseY,"")
			if(s.eventmod==2) // shift key
				//print Tracestr
				variable point = numberbykey("HITPOINT",tracestr)
				wave trace = TraceNameToWaveRef("depthprofilingplot", stringbykey("TRACE",tracestr))
				setdatafolder GetWavesDataFolder(trace,1)
				wave/t dataname
				wave temp,timestamp, peakloc, peakwidth, peakheight, peaklocerr, peakwidtherr, peakheighterr, omega, coherence,coherenceerror
				deletepoints point, 1, dataname, temp, timestamp, peakloc, peakwidth, peakheight, peaklocerr, peakwidtherr, peakheighterr, omega, coherence, coherenceerror
				setdatafolder foldersave
				return 1
			endif
			break
	EndSwitch

	return 0
end


Window peaksvtemp() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:AutoPeakFits:plot_ndi3HU_rdT:plot_ndi3HU_rdT_32:
	Display /W=(465,45.5,904.5,682.25) peakloc vs temp
	SetDataFolder fldrSav0
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph grid=1
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph minor=1
	ModifyGraph standoff=0
	ModifyGraph axOffset(left)=-3.66667
	ModifyGraph gridStyle=3
	Label left "Spacing [Å]"
	Label bottom "Temperature [°C]"
EndMacro

function removepeaksfromdata(data, xwave, peaknums, peaktype, peakcoeftemplate, backgroundtype, backgroundname)
	wave data, xwave
	string peaknums
	string peaktype
	string peakcoeftemplate
	string backgroundtype
	string backgroundname
	
	FUNCREF MPF2_FuncInfoTemplate blinfo = $(backgroundtype + BL_INFO_SUFFIX)
	string BL_FuncName = blinfo(BLFuncInfo_BaselineFName)
	FUNCREF MPF2_BaselineFunctionTemplate blFunc = $BL_FuncName
	STRUCT MPF2_BLFitStruct BLStruct
	Wave BLStruct.cWave = $backgroundname
	BLStruct.xStart = xwave[0]
	BLStruct.xEnd = xwave[dimsize(xwave,0)-1]
	// this should subtract the background from the dataset (we have to loop through because of stupid blfunc structure
	variable i
	for (i = 0; i < numpnts(data); i += 1)
		BLStruct.x = xwave[i]
		data[i] -= blFunc(BLStruct)
	endfor
	// go through all the peaks, subtracting them from data
	nvar gnumpeaks
	FUNCREF MPF2_FuncInfoTemplate infoFunc=$(peaktype+PEAK_INFO_SUFFIX)
	String PeakFuncName = 	infoFunc(PeakFuncInfo_PeakFName)
	FUNCREF MPF2_PeakFunctionTemplate peakFunc = $PeakFuncName
	string coefname
	duplicate/o data, temppeak
	for(i=0;i<gnumpeaks;i+=1)
		if(findlistitem(num2str(i),peaknums,",",0)==-1) // this peak isn't on the list
			sprintf coefname, peakcoeftemplate, i // load those peak parameters
			wave coefs = $coefname
			peakFunc(coefs, temppeak, xwave) // set temppeak to this peak
			data -= temppeak // subtract the peak from the data
		endif
	endfor

end



function CleanuptopgraphEL() // used to remove some bad set of points from all of the traces on a top graph (typically this is to get a graph ready for multipeakfitting)
	string wname = winname(0,1)
	string tracelist = tracenamelist(wname,";",1)
	variable i
	for(i=0;i<itemsinlist(tracelist);i+=1)
		string tracename = stringfromlist(i,tracelist)
		wave rwave = tracenametowaveref(wname,tracename)
		wave xwave = XWaveRefFromTrace(wname,tracename)
		DeletePoints  619,820, rwave , xwave
		DeletePoints  345,31, rwave , xwave
	endfor
end

function cleanupELPtopgraph(readcursors,whichquadrant)
	variable readcursors,whichquadrant // which quadrant varies by which side the main data is in on the detector.  1 for Jun 2015 data, 0 for Feb 2015 data (I think)
	string wname = winname(0,1)
	if(strlen(CsrInfo(A)) > 0 && strlen(CsrInfo(B)) > 0)
		variable ca = min(pcsr(A), pcsr(B)), cb=max(pcsr(A), pcsr(B))
		if(readcursors &&  ca*cb*0==0 && cb>ca)
			readcursors = 1
		else
			readcursors = 0
		endif
	else
		readcursors = 0
	endif
	if(readcursors)
		cleanuptopgraph(ca+1,cb-ca-1, "Cleaned",1)
	endif
	wave testxwave = waverefindexed("",0,2)
	if(whichquadrant)
		testxwave *=-1
	endif
	wavestats /q testxwave
	if(readcursors)
		cleanuptopgraph(V_MinRowLoc, numpnts(testxwave)-V_MinRowLoc, "Cleaned",0)
	else
		cleanuptopgraph(V_MinRowLoc, numpnts(testxwave)-V_MinRowLoc, "Cleaned",1)
	endif
	doupdate
end

function Cleanuptopgraph(startpoint, numpoints, newfolder, newgraph) // used to remove some bad set of points from all of the traces on a top graph (typically this is to get a graph ready for multipeakfitting)
	// copies all of the displayed waves into a new graph, and copies all of the waves that are graphed into newfolder, which can be any folder starting from the root directory, which will be created
	//deletes numpoints starting at startpoint for all of the graphed waves in the top graph (both x and y waves)
	// if the graph contains waves that are already in the newfolder, then the original data is altered
	variable startpoint, numpoints, newgraph
	string newfolder
	string wname = winname(0,1)
	string commandstr, recreationlist, traceinfostring
	variable tracenum
	string tracename
	variable i,j
	setdatafolder root:
	newdatafolder /o/s $newfolder
	string foldername = getdatafolder(1)
	string newwname = uniquename(cleanupname(wname+"_cl",1),6,0)
	if(newgraph)
		//display /k=1 /n=$newwname as "Cleaned version of "+wname
		CloneWindow(win=wname,newwindowname = newwname, thisfolder=1)
		string oldwindowname = wname
		wname = newwname
	endif
	string tracelist = tracenamelist(wname,";",1)
	doupdate
	for(i=0;i<itemsinlist(tracelist);i+=1)
		tracename = stringfromlist(i,tracelist)
		//tracenum = whichlistitem(tracename, TraceNameList(wname, ";", 5))
		//traceinfostring = traceinfo(wname,tracename,0)
		//recreationlist = traceinfostring[strsearch(traceinfostring,"RECREATION:",0) + strlen("RECREATION:"),inf]
		
		wave rwave = tracenametowaveref(wname,tracename)
		wave xwave = XWaveRefFromTrace(wname,tracename)
		
		//if(stringmatch(getwavesdatafolder(rwave,1), foldername))
			DeletePoints  startpoint,numpoints, rwave
			//wave rwavetoplot = $getwavesdatafolder(rwave,2)
		//else
		//	duplicate /o rwave, $(foldername  + possiblyquotename(nameofwave(rwave)))
		//	wave newrwave = $(foldername  + possiblyquotename(nameofwave(rwave)))
		//	DeletePoints  startpoint,numpoints, newrwave
		//	wave rwavetoplot = $getwavesdatafolder(newrwave,2)
		//	rwavetoplot = max(rwavetoplot,0)
		//endif
		//if(stringmatch(getwavesdatafolder(xwave,1), foldername))
			DeletePoints  startpoint,numpoints, xwave
		//	wave xwavetoplot = $getwavesdatafolder(xwave,2)
		//else
		//	duplicate /o xwave, $(foldername + possiblyquotename(nameofwave(xwave)))
		//	wave newxwave = $(foldername + possiblyquotename(nameofwave(xwave)))
		//	DeletePoints  startpoint,numpoints, newxwave
		//	wave xwavetoplot = $getwavesdatafolder(newxwave,2)
		//endif
		//if(newgraph)
		//	appendtograph /w=$newwname rwavetoplot /TN=$cleanupname(tracename,0) vs xwavetoplot
			//for(j=0;j<itemsinlist(recreationlist);j+=1)
			//	commandstr = "ModifyGraph /w="+newwname +" "+ replacestring("(x)",stringfromlist(j,recreationlist),"["+num2str(tracenum)+"]")
			//	execute/q/z commandstr
			//endfor
		//endif
		//doupdate
	endfor
end
Function CloneWindow([win,newwindowname,thisfolder])
	String win
	String newwindowname // The new name for the window
	variable thisfolder // if non zero, copy waves to current datafolder
	if(ParamIsDefault(win))
		win=WinName(0,1)
	endif
	if(ParamIsDefault(newwindowname))
		newwindowname=UniqueName(win,6,0)
	else
		newwindowname=CleanupName(newwindowname,0)
		if(wintype(newwindowname))
			newwindowname = uniquename(newwindowname,6,0)
		endif
	endif
	thisfolder = paramisdefault(thisfolder)? 0 : thisfolder
	String curr_folder=GetDataFolder(1)
	if(!thisfolder)
		NewDataFolder /O/S root:savedgraphs
		NewDataFolder /O/S $newwindowname
	endif
	String traces=TraceNameList(win,";",3)
	string nameofnewwave
	Variable i,j
	
	String win_rec=WinRecreation(win,0)
 	// Copy error bars if they exist.  Won't work with subrange display syntax.  
	for(i=0;i<ItemsInList(win_rec,"\r");i+=1)
		String line=StringFromList(i,win_rec,"\r")
		if(StringMatch(line,"*ErrorBars*"))
			String errorbar_names
			sscanf line,"%*[^=]=(%[^)])",errorbar_names
			for(j=0;j<2;j+=1)
				String errorbar_path=StringFromList(j,errorbar_names,",")
				sscanf errorbar_path,"%[^[])",errorbar_path
				String errorbar_name=StringFromList(ItemsInList(errorbar_path,":")-1,errorbar_path,":")
				Duplicate /o $("root"+errorbar_path) $errorbar_name
			endfor
		endif
	endfor
	
	Execute /Q win_rec
	DoWindow /C $newwindowname
	
	for(i=0;i<ItemsInList(traces);i+=1)
		String trace=StringFromList(i,traces)
		Wave TraceWave=TraceNameToWaveRef(win,trace)
		nameofnewwave = nameofwave(TraceWave)
		wave testwave = $nameofnewwave
		if(waveexists(testwave))
			nameofnewwave = uniquename(nameofnewwave,1,0)
		endif
		Duplicate TraceWave $nameofnewwave
		
		replacewave /W=$newwindowname trace=$trace , $nameofnewwave 
		
		Wave /Z TraceXWave=XWaveRefFromTrace(win,trace)
		if(waveexists(TraceXWave))
			nameofnewwave = nameofwave(TraceXWave)
			wave testwave = $nameofnewwave
			if(waveexists(testwave))
				nameofnewwave = uniquename(nameofnewwave,1,0)
			endif
			Duplicate /o TraceXWave $nameofnewwave
			
			
			replacewave /X/W=$newwindowname trace=$trace , $nameofnewwave 
		endif
		
	endfor
	
	
	SetDataFolder $curr_folder
End

function fitalltopgraphAng(name, alkyl,extra)
	// this function takes all of the traces in the top graph and tries to fit them to an In-plane gaussian (symmettric at + and - 90 degrees), and an out of plane gaussian, centered at zero
	// this is often used for depth profiling or monitoring peak intensities and orientational widths vs some other variable (ie temperature)  these parameters will likely all be made progromatic
	// in the future, although for the time being, the code is changed for each as necessary.
	
	// this will also be changed to allow for similar peak fitting vs q space, although precise locations of peaks will be needed 
	// (use simplepeakfittopgraph() for more flexible applications (with auto peak finding and indexing))
	
	string name
	variable alkyl, extra
	string wname = winname(0,1)
	string tracelist = tracenamelist(wname,";",1+4)
	variable i
	string foldersave = getdatafolder(1)
	if(alkyl)
		name+= "_alk"
	else
		name += "_pi"
	endif
	setdatafolder root:
	newdatafolder /o/s angularresults
	newdatafolder /o/s $name
	make/o /n=(itemsinlist(tracelist)) incidentangle, ippeakwidth, ippeakheight, ippeakwidtherr, ippeakheighterr,ooppeakwidth, ooppeakheight, ooppeakwidtherr, ooppeakheighterr, temp
	if(extra)
		make/o /n=(itemsinlist(tracelist)) extrapeakheight, extrapeakheighterr, extrapeakwidth, extrapeakwidtherr, extrapeakloc, extrapeaklocerr
	endif
	make/o /n=(itemsinlist(tracelist)) /t dataname
	for(i=0;i<itemsinlist(tracelist);i+=1)
		string tracename = stringfromlist(i,tracelist)
		wave rwave = tracenametowaveref(wname,tracename)
		wave xwave = XWaveRefFromTrace(wname,tracename)
		variable V_FitError = 0
		if(alkyl)
			if(extra)
				Make/D/N=5/O W_coef = {10,500,40,500,6,500,8,46} // y offset, in plane amplitude, width, out of plane amplitude, height
				FuncFit/w=2/q/H="00101010"/NTHR=0 IP_OOP_andextra_Gauss W_coef  rwave /X=xwave /D //F={0.950000, 4}
			else
				Make/D/N=5/O W_coef = {0,10,15,0,5}
				FuncFit/w=2/q/H="00000"/NTHR=0 InAndOutOfPlaneGauss W_coef  rwave /X=xwave /D //F={0.950000, 4}
			endif
		else
			if(extra)
				Make/D/N=5/O W_coef = {0.1,100,15,200,5,100,5,30}
				FuncFit/w=2/q/H="10000000"/NTHR=0 IP_OOP_andextra_Gauss W_coef  rwave /X=xwave /D //F={0.950000, 4}
			else
				Make/D/N=5/O W_coef = {0.1,100,15,200,5}
				FuncFit/w=2/q/H="10000"/NTHR=0 InAndOutOfPlaneGauss W_coef  rwave /X=xwave /D //F={0.950000, 4}
			endif
		endif
		//FuncFit/q/H="10000"/NTHR=0 InAndOutOfPlaneGauss W_coef  rwave /X=xwave /D //F={0.950000, 4}
		//InAndOutOfPlaneGauss
		//IPGaussOOPLorentzian
		if(V_FitError)
			continue
		endif
		wave w_sigma
		string wavenote = note(rwave)
		incidentangle[i] = str2num(stringbykey("SampleOmega",wavenote,"=",";"))
		temp[i] = str2num(stringbykey("Temperature1",wavenote,"=",";"))
		dataname[i] = tracename
		ippeakwidth[i]  = 2*sqrt(ln(2))*w_coef[2]
		ippeakwidtherr[i] = 2*sqrt(ln(2))*w_sigma[2]
		ippeakheight[i] = exp(w_coef[1])
		ippeakheighterr[i] = exp(w_sigma[1])
		ooppeakwidth[i]  = w_coef[4]*2*sqrt(ln(2))   //  gaussian peaks need the correction term to go from width to FWHM, Lorentzian do not.
		ooppeakwidtherr[i] = w_sigma[4]*2*sqrt(ln(2))
		ooppeakheight[i] = exp(w_coef[3])
		ooppeakheighterr[i] = exp(w_sigma[3])
		if(extra)
			extrapeakheight[i] = w_coef[5]
			extrapeakheighterr[i] = w_sigma[5]
			extrapeakwidth[i] = w_coef[6]
			extrapeakwidtherr[i] = w_sigma[6]
			extrapeakloc[i] = w_coef[7]
			extrapeaklocerr[i] = w_sigma[7]
		endif
	endfor
	string ename = cleanupname("values_"+name,0)
	dowindow /k $ename
	if(extra)
		edit /k=1 /n=$ename dataname,incidentangle, ippeakwidth, ippeakwidtherr, ippeakheight, ippeakheighterr,ooppeakwidth, ooppeakwidtherr, ooppeakheight, ooppeakheighterr, temp,extrapeakheight, extrapeakheighterr, extrapeakwidth, extrapeakwidtherr, extrapeakloc, extrapeaklocerr
		sort temp, dataname,incidentangle, ippeakwidth, ippeakwidtherr, ippeakheight, ippeakheighterr,ooppeakwidth, ooppeakwidtherr, ooppeakheight, ooppeakheighterr, temp,extrapeakheight, extrapeakheighterr, extrapeakwidth, extrapeakwidtherr, extrapeakloc, extrapeaklocerr
	else
		edit /k=1 /n=$ename dataname,incidentangle, ippeakwidth, ippeakwidtherr, ippeakheight, ippeakheighterr,ooppeakwidth, ooppeakwidtherr, ooppeakheight, ooppeakheighterr, temp
		sort temp, dataname,incidentangle, ippeakwidth, ippeakwidtherr, ippeakheight, ippeakheighterr,ooppeakwidth, ooppeakwidtherr, ooppeakheight, ooppeakheighterr, temp
	endif
	string gname = cleanupname("plot_"+name,0)
	dowindow /k $gname
	display /k=1 /n=$gname ippeakwidth vs temp
	SetAxis/A
	//DeletePoints 7,1, peakheighterr,peakwidtherr,peakheight,peakwidth,incidentangle
	//DeletePoints 6,1, peakheighterr,peakwidtherr,peakheight,peakwidth,incidentangle
	ippeakwidth = abs(ippeakwidth)
	appendtograph /r ippeakheight vs temp
	ModifyGraph rgb(ippeakwidth)=(0,0,0),rgb(ippeakheight)=(0,0,65280);DelayUpdate
	ErrorBars ippeakwidth Y,wave=(ippeakwidtherr,ippeakwidtherr);DelayUpdate
	ErrorBars ippeakheight Y,wave=(ippeakheighterr,ippeakheighterr)
	ModifyGraph tick=2,mirror(bottom)=1,minor=1,lblPosMode(right)=1,standoff=0;DelayUpdate
	ModifyGraph axRGB(right)=(0,0,65280),tlblRGB(right)=(0,0,65280);DelayUpdate
	ModifyGraph alblRGB(right)=(0,0,65280);DelayUpdate
	Label right "Peak Height"
	Label bottom "Incident Angle [deg]"
	Label left "Distribution Width Angle [deg]"
	ModifyGraph log(right)=1
	appendtograph ooppeakwidth vs temp
	//SetAxis/A
	//DeletePoints 7,1, peakheighterr,peakwidtherr,peakheight,peakwidth,incidentangle
	//DeletePoints 6,1, peakheighterr,peakwidtherr,peakheight,peakwidth,incidentangle
	ooppeakwidth = abs(ooppeakwidth)
	appendtograph /r ooppeakheight vs temp
	ModifyGraph rgb(ooppeakwidth)=(0,0,0),rgb(ooppeakheight)=(0,0,65280)
	ErrorBars ooppeakwidth Y,wave=(ooppeakwidtherr,ooppeakwidtherr)
	ErrorBars ooppeakheight Y,wave=(ooppeakheighterr,ooppeakheighterr)
	ModifyGraph tick=2,mirror(bottom)=1,minor=1,lblPosMode(right)=1,standoff=0
	ModifyGraph axRGB(right)=(0,0,65280),tlblRGB(right)=(0,0,65280)
	ModifyGraph alblRGB(right)=(0,0,65280)
	ModifyGraph lstyle(ippeakwidth)=3,lstyle(ippeakheight)=3,lsize=3
	if(extra)
		appendtograph /r extrapeakheight vs temp
		appendtograph extrapeakwidth vs temp
		appendtograph /r=extra extrapeakloc vs temp
		ModifyGraph rgb(extrapeakwidth)=(0,0,0),rgb(extrapeakheight)=(0,0,65280),rgb(extrapeakloc)=(0,65280,0)
		ErrorBars extrapeakwidth Y,wave=(extrapeakwidtherr,extrapeakwidtherr)
		ErrorBars extrapeakheight Y,wave=(extrapeakheighterr,extrapeakheighterr)
		ErrorBars extrapeakloc Y,wave=(extrapeaklocerr,extrapeaklocerr)
		ModifyGraph tick=2,minor=1,lblPosMode(extra)=1,standoff=0
		ModifyGraph axRGB(extra)=(0,65280,0),tlblRGB(extra)=(0,65280,0)
		ModifyGraph alblRGB(extra)=(0,65280,0)
		ModifyGraph lstyle(extrapeakwidth)=5,lstyle(extrapeakheight)=5,lsize=3
	endif
	setdatafolder foldersave
end

Function InAndOutOfPlaneGauss(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = y0+y1*x+A*exp(-((x-x0)/width)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = Ainplane
	//CurveFitDialog/ w[2] = widthinplane
	//CurveFitDialog/ w[3] = Aoutofplane
	//CurveFitDialog/ w[4] = widthoutofplane

	return w[0]+exp(w[1])*exp(-((x+90)/w[2])^2)+exp(w[1])*exp(-((x-90)/w[2])^2)+exp(w[3])*exp(-((x)/w[4])^2)
End

Function IP_OOP_andextra_Gauss(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = y0+y1*x+A*exp(-((x-x0)/width)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = Ainplane
	//CurveFitDialog/ w[2] = widthinplane
	//CurveFitDialog/ w[3] = Aoutofplane
	//CurveFitDialog/ w[4] = widthoutofplane
	//CurveFitDialog/ w[5] = Aextra
	//CurveFitDialog/ w[6] = widthextra
	//CurveFitDialog/ w[7] = locextra

	return w[0]    +    w[1]*exp(-((x+90)/w[2])^2)    +    w[1]*exp(-((x-90)/w[2])^2)    +     w[3]*exp(-((x)/w[4])^2)   +    w[5]*exp(-((x-w[7])/w[6])^2)    +    w[5]*exp(-((x+w[7])/w[6])^2)
End


Function InAndOutOfPlaneLorentzian(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = y0+y1*x+A*exp(-((x-x0)/width)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = Ainplane
	//CurveFitDialog/ w[2] = widthinplane
	//CurveFitDialog/ w[3] = Aoutofplane
	//CurveFitDialog/ w[4] = widthoutofplane

	return w[0]+w[1]/((x+90)^2 + (w[2]^2)/4)+w[1]/((x-90)^2 + (w[2]^2)/4)+w[3]/((x)^2 + (w[4]^2)/4)
End

Function IPGaussOOPLorentzian(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = y0+y1*x+A*exp(-((x-x0)/width)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = Ainplane
	//CurveFitDialog/ w[2] = widthinplane
	//CurveFitDialog/ w[3] = Aoutofplane
	//CurveFitDialog/ w[4] = widthoutofplane

	return w[0]+w[1]*(w[2]^2/2)/((x+90)^2 + (w[2]^2)/4)+w[1]*(w[2]^2/2)/((x-90)^2 + (w[2]^2)/4) + w[3]*exp(-((x)/w[4])^2)
End

function ChiSCalcTopGraph([xaxis,sinscaling])
	variable sinscaling // 0 if we don't scale the data by sin(chi) 1(default) if we do scale by sin(chi) 
	string xaxis // an optional parameter from the wave notes of the traces to use as the xaxis in a plot of results
	string tracelist = Tracenamelist("",";",1)
	variable i, xmax, xmin, Intn, Intd, s,j, badpoint, area1, area2
	string tracename
	string foldersave =getdatafolder(1)
	variable power = sinscaling==1 || paramisdefault(sinscaling) ? 2 : 1
	setdatafolder root:
	newdatafolder /o/s Packages
	newdatafolder /o/s ChiSCalcs
	newdatafolder /o/s $stringfromlist(i,winlist("*",";","WIN:1"))
	make /d/o/n=(itemsinlist(tracelist)) xaxiswave, swave
	make /o/t /n=(itemsinlist(tracelist)) tracenamewave
	string xaxisstring
	variable xaxisvar
	for(i=0;i<itemsinlist(tracelist);i+=1)
		tracename = stringfromlist(i,tracelist)
		wave origxwave = XWaveRefFromTrace("",tracename)
		wave origrwave = TraceNameToWaveRef("",tracename)
		duplicate /free origxwave, xwave
		duplicate /free origrwave, rwave, nanwave
		nanwave = xwave*rwave
		for(j=dimsize(rwave,0)-1;j>=0;j-=1)
			if(nanwave[j]*0!=0)
				deletepoints j, 1, xwave, rwave
			endif
		endfor
		
		xmax = max(abs(wavemin(xwave)),wavemax(xwave)) //the maximum extent of the x wave from zero
		duplicate /free xwave, tempx
		
		// make sure that the waves are relatively monotonic, with no huge jumps
		differentiate tempx
		wavestats/q tempx
		findlevel/q tempx, 0//v_avg+v_sdev*4
		if(v_flag==0)
			badpoint = floor(v_levelx)-1
		else
			badpoint = inf
		endif
		findlevel/q tempx, 0//v_avg-v_sdev*10
		if(v_flag==0)
			badpoint = min(badpoint,floor(v_levelx)-1)
		endif
		if(badpoint*0==0)
			redimension /n=(badpoint) xwave, rwave, tempx
		endif
		tempx = abs(xwave)
		xmin = wavemin(tempx)
		if(xmax<80 || xmax > 100 || xmin > 20)
			print "the x limits of "+tracename+" don't look like a Xi wave, so we are ignoring it"
			continue
		endif
		xwave *=pi/180
		
		tempx = Cos(xwave)^2 *sin(xwave)^power * max(0,rwave) // this sin should change to sin^2 for sin intensity correction
		
		area1 =  areaxy(xwave, tempx, 0, pi/2) 
		area2 = areaxy(xwave, tempx, 0, -pi/2) 
		intn = area1*0==0 ? area1 : 0
		intn += area2*0==0 ? abs(area2) : 0
		
		tempx = sin(xwave)^power * max(0,rwave)  // this sin should change to sin^2 for sin intensity correction

		area1 =  areaxy(xwave, tempx, 0, pi/2) 
		area2 = areaxy(xwave, tempx, 0, -pi/2) 
		intd = area1*0==0 ? area1 : 0
		intd += area2*0==0 ? abs(area2) : 0
		
		s = (1/2)*(3*intn/intd-1)
		tracenamewave[i] = tracename
		swave[i]=s
		if(!paramisdefault(xaxis))
			xaxisstring = stringbykey(xaxis,note(rwave),"=",";")
			//print xaxisstring
			sscanf xaxisstring, "%f", xaxisvar
			xaxiswave[i] = xaxisvar
		endif
	endfor
	if(!paramisdefault(xaxis))
		dowindow /k Chidisp
		display /k=1 /n=Chidisp swave vs xaxiswave as "Orientation Parameter vs "+xaxis
		Label left "Herman's Orientation Parameter S"
		Label bottom xaxis
		ModifyGraph mode=3,marker=8,rgb=(0,0,0)
	endif
	dowindow /k HermanDisp
	edit /k=1 /n=HermanDisp tracenamewave, swave, xaxiswave as "Orientational Parameter"
	setdatafolder foldersave
end
