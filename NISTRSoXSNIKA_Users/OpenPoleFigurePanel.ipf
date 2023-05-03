#pragma rtGlobals=1		// Use modern global access method and strict wave access

Menu "Macros"
	"Open PoleFigureHelperPanel",  InitPanelPoleFigureBcknd()
End

//////////////////////////////Pole figure functions///////////////////////////////////////////

function InitPanelPoleFigureBcknd()
	if (DataFolderExists("root:ParameterAndVariable"))
 		//Folder is there and might be populated
 	else
 		//Folder has to be created and populated
 		NewDataFolder root:ParameterAndVariable
 	endif
 	Variable/G root:ParameterAndVariable:Pos0a = 100
 	Variable/G root:ParameterAndVariable:Pos0b = 150
 	Variable/G root:ParameterAndVariable:Pos1a = 200
 	Variable/G root:ParameterAndVariable:Pos1b = 250
 	Variable/G root:ParameterAndVariable:Pos2a = 300
 	Variable/G root:ParameterAndVariable:Pos2b = 350
 	String/G root:ParameterAndVariable:Status = "Positions UpToDate"
 	String/G root:ParameterAndVariable:graphNameStr
 	Variable/G  root:ParameterAndVariable:PoleIs90 = 1
	Variable/G  root:ParameterAndVariable:IsGICorrected = 1
	Variable/G root:ParameterAndVariable:ShowBckgrndProf = 0
	Variable/G root:ParameterAndVariable:CrystValue = 0
	Variable/G root:ParameterAndVariable:OrientValue = 0
	Variable/G root:ParameterAndVariable:IntMinus90To90 = 0
	SVar graphNameStr = root:ParameterAndVariable:graphNameStr
	graphNameStr = WinName(0,1)
	AddPosOfLineProfToSquareMap(graphNameStr)
	
	Execute "PanelPoleFig()"
end

Window PanelPoleFig() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1079,65,1312,591)
	SetDrawLayer UserBack
	DrawLine 14,156,215,156
	DrawLine 12,416,213,416
	DrawText 107,482,"PerpToDirector (-1/2)"
	DrawText 112,517," ParallToDirector (1)"
	DrawText 154,499," Isotropic (0)"
	SetVariable setPos0a,pos={13,166},size={94,18},proc=SetVarProc,title="Pos0a"
	SetVariable setPos0a,value= root:ParameterAndVariable:Pos0a,live= 1
	SetVariable setPos0b,pos={117,166},size={97,18},bodyWidth=60,proc=SetVarProc,title="Pos0b"
	SetVariable setPos0b,value= root:ParameterAndVariable:Pos0b,live= 1
	SetVariable setPos1a,pos={11,190},size={96,18},bodyWidth=60,proc=SetVarProc,title="Pos1a"
	SetVariable setPos1a,value= root:ParameterAndVariable:Pos1a,live= 1
	SetVariable setPos1b,pos={118,190},size={97,18},bodyWidth=60,proc=SetVarProc,title="Pos1b"
	SetVariable setPos1b,value= root:ParameterAndVariable:Pos1b,live= 1
	SetVariable setPos2a,pos={11,214},size={96,18},bodyWidth=60,proc=SetVarProc,title="Pos2a"
	SetVariable setPos2a,value= root:ParameterAndVariable:Pos2a,live= 1
	SetVariable setPos2b,pos={117,214},size={97,18},bodyWidth=60,proc=SetVarProc,title="Pos2b"
	SetVariable setPos2b,value= root:ParameterAndVariable:Pos2b,live= 1
	Button DragLines,pos={10,241},size={204,31},proc=ButtonProcStartCoarseAdj,title="Coarse Adjust Lines by Drag and Drop"
	Button DragLinesFinished,pos={10,278},size={204,31},proc=ButtonProcFinishCoarseAdj,title="Readback Posiitons after Adjusting"
	Button ButtonRemoveProfiles,pos={13,118},size={204,31},proc=ButtonProcRemoveProfiles,title="RemoveProfilesFromImage"
	ValDisplay IntCryst,pos={7,426},size={217,15},bodyWidth=115,title="Crystallinity [ a.u.]"
	ValDisplay IntCryst,limits={0,0,0},barmisc={0,1000}
	ValDisplay IntCryst,value= #"root:ParameterAndVariable:CrystValue"
	TitleBox statusDragAndDrop,pos={13,322},size={199,21}
	TitleBox statusDragAndDrop,variable= root:ParameterAndVariable:Status,fixedSize=1
	Button SetActiveWindow,pos={13,10},size={204,31},proc=ButtonProcSetActWindow,title="SetActiveWindow"
	TitleBox ActSquareMap,pos={15,50},size={199,21}
	TitleBox ActSquareMap,variable= root:ParameterAndVariable:graphNameStr,fixedSize=1
	CheckBox checkIsCorrected,pos={16,356},size={182,14},title="Data is GIGeometry Corrected"
	CheckBox checkIsCorrected,variable= root:ParameterAndVariable:IsGICorrected
	CheckBox checkPoleIs90,pos={16,376},size={91,14},proc=CheckProcUpdate,title="Pole is at 90°"
	CheckBox checkPoleIs90,variable= root:ParameterAndVariable:PoleIs90
	Button ButtonAddProfiles1,pos={13,80},size={204,31},proc=ButtonProcAddProfiles,title="AddProfilesToImage"
	ValDisplay OrientVal,pos={43,445},size={180,15},bodyWidth=115,title="Orientation"
	ValDisplay OrientVal,limits={0,0,0},barmisc={0,1000}
	ValDisplay OrientVal,value= #"root:ParameterAndVariable:OrientValue"
	CheckBox checkIntMinus90To90,pos={102,376},size={126,14},proc=CheckProcUpdate,title="Integrate -90 to 90"
	CheckBox checkIntMinus90To90,variable= root:ParameterAndVariable:IntMinus90To90
	CheckBox checkShowBckgrndProf,pos={16,396},size={159,14},proc=CheckProcUpdate,title="Show Background Profiles"
	CheckBox checkShowBckgrndProf,variable= root:ParameterAndVariable:ShowBckgrndProf
EndMacro

//Create the boundaries for the 3 line profiles, each a lower and upper boundary
//This is designed for Nikas Square Map Plot in the momnet, so X varies for each line
function AddPosOfLineProfToSquareMap(graphNameStr)
	String graphNameStr
	if (DataFolderExists("root:ParameterAndVariable"))
 		//Folder is there and might be populated
 	else
 		//Folder has to be created and populated
 		NewDataFolder root:ParameterAndVariable
 	endif
 	
 	String LineProfXMarkerStr = "root:ParameterAndVariable:LineProfMarker_x"
 	String LineProfYMarkerStr = "root:ParameterAndVariable:LineProfMarker_y"
 	 
 	Variable lsize = 2
	Variable lstyle
	Variable red, green, blue
 	
 	Variable i
	for(i = 0; i<3; i+=1)
 	 	
 	 	
 	 	String LineProfXMarkerStr_a = LineProfXMarkerStr + num2str(i) + "a"
 	 	String LineProfXMarkerStr_b = LineProfXMarkerStr + num2str(i) + "b"
 	 	
 	 	String PosStr_a = "root:ParameterAndVariable:Pos" + num2str(i) + "a"
 	 	NVar Pos_a = $PosStr_a
 	 	String PosStr_b = "root:ParameterAndVariable:Pos" + num2str(i) + "b"
 	 	NVar Pos_b = $PosStr_b
 	 	
 	 	Make/O/N=2 $LineProfXMarkerStr_a
 	 	Wave LineProfXMarker_a = $LineProfXMarkerStr_a
 	 	LineProfXMarker_a = Pos_a
 	 	
		Make/O/N=2 $LineProfXMarkerStr_b
		Wave LineProfXMarker_b = $LineProfXMarkerStr_b
		LineProfXMarker_b = Pos_b
		
		String LineProfYMarkerStr_a = LineProfYMarkerStr + num2str(i) + "a"
 	 	String LineProfYMarkerStr_b = LineProfYMarkerStr + num2str(i) + "b"
		
		Make/O/N=2 $LineProfYMarkerStr_a
		Wave LineProfYMarker_a = $LineProfYMarkerStr_a
		LineProfYMarker_a = {0, inf}
		
		Make/O/N=2 $LineProfYMarkerStr_b
		Wave LineProfYMarker_b = $LineProfYMarkerStr_b
		LineProfYMarker_b = {0, inf}
	
		switch(i)
			case 0:	
				red = 65280; green = 43520; blue = 32768;	//Peach
				lstyle=8	//broken line
				break
			case 1:
				red = 65280; green = 0; blue = 0;	//Red
				lstyle=1	//dotted
				break 
			case 2:
				red = 65280; green = 43520; blue = 0; //Orange
				lstyle=8	//broken line
				break		
		endswitch
	
		String TraceName = "LineProfMarker_y"+num2str(i)+"a"	//This is something Igor doesn tdo well, if i use the whole wave name or the wave refernce it throws an error
		if(strlen(TraceInfo(graphNameStr,TraceName, 0))==0)
			//Append if not already on image 
			AppendToGraph/W=$graphNameStr LineProfYMarker_a vs LineProfXMarker_a;
			ModifyGraph/W=$graphNameStr lstyle($TraceName)=lstyle,lsize($TraceName)=lsize;DelayUpdate
			ModifyGraph/W=$graphNameStr rgb($TraceName)=(red, green, blue); DelayUpdate		
			//Make The line able for position diting 
			ModifyGraph/W=$graphNameStr live($TraceName)=1; DelayUpdate
			ModifyGraph/W=$graphNameStr quickdrag($TraceName)=1; DelayUpdate
		endif

		TraceName = "LineProfMarker_y"+num2str(i)+"b"		
		if(strlen(TraceInfo(graphNameStr,TraceName, 0))==0)			
			AppendToGraph/W=$graphNameStr LineProfYMarker_b vs LineProfXMarker_b;
			ModifyGraph/W=$graphNameStr lstyle($TraceName)=lstyle,lsize($TraceName)=lsize;DelayUpdate
			ModifyGraph/W=$graphNameStr rgb($TraceName)=(red, green, blue); DelayUpdate		
			//Make The line able for position diting 
			ModifyGraph/W=$graphNameStr live($TraceName)=1; DelayUpdate
			ModifyGraph/W=$graphNameStr quickdrag($TraceName)=1; DelayUpdate
		endif
		DoUpdate
		
 	endfor 	 
 end
 
function EnableDragAndDropp(graphNameStr)
	String graphNameStr
 	
 	SVar Status =  root:ParameterAndVariable:Status
 	Status = "Positions NOT Locked or UpToDate"
 	Variable i
	for(i = 0; i<3; i+=1)
 	 	String TraceName = "LineProfMarker_y"+num2str(i)+"a"	//This is something Igor doesn tdo well, if i use the whole wave name or the wave refernce it throws an error
		ModifyGraph/W=$graphNameStr live($TraceName)=1; DelayUpdate
		ModifyGraph/W=$graphNameStr quickdrag($TraceName)=1; DelayUpdate
				
		TraceName = "LineProfMarker_y"+num2str(i)+"b"		
		//Make The line able for position diting 
		ModifyGraph/W=$graphNameStr live($TraceName)=1; DelayUpdate
		ModifyGraph/W=$graphNameStr quickdrag($TraceName)=1; DelayUpdate
		DoUpdate
	endfor 
end

function FinishDragAndDropp(graphNameStr)
	String graphNameStr
 	Variable i
	for(i = 0; i<3; i+=1)
 	 	String TraceName = "LineProfMarker_y"+num2str(i)+"a"	//This is something Igor doesn tdo well, if i use the whole wave name or the wave refernce it throws an error
		ModifyGraph/W=$graphNameStr live($TraceName)=0; DelayUpdate
		ModifyGraph/W=$graphNameStr quickdrag($TraceName)=0; DelayUpdate
				
		TraceName = "LineProfMarker_y"+num2str(i)+"b"		
		//Make The line able for position diting 
		ModifyGraph/W=$graphNameStr live($TraceName)=0; DelayUpdate
		ModifyGraph/W=$graphNameStr quickdrag($TraceName)=0; DelayUpdate
		DoUpdate
	endfor 
end

function UpdatePosition(graphNameStr, yWaveNameStr)
	String graphNameStr, yWaveNameStr
	String TraceInfoStr = TraceInfo(graphNameStr, yWaveNameStr, 0)
	String SubString = StringFromList(46, TraceInfoStr, ";")
	Variable Offset_x, Offset_y //Offset_x is what we need
	sscanf Substring, "offset(x)={%f,%f}", Offset_x, Offset_y
	
	//Get the path to the XWave so we can update the values and set the offset back to zero
	String XAxisWaveStr = stringbykey("XWAVEDF", TraceInfoStr)  +  stringbykey("XWAVE", TraceInfoStr) 
		
	Wave XAxisWave = $XAxisWaveStr
	XAxisWave = XAxisWave + Offset_x
	ModifyGraph/W=$graphNameStr offset($yWaveNameStr)={0,0}
	
	return round(XAXisWave[0]) //return the position of the line
end

function CalcAverage(graphNameStr, ProfileNo)
	String graphNameStr
	Variable ProfileNo
	
	String WaveListStr = ImageNameList(graphNameStr, ";" )
	String FirstImageName = StringFromList(0, WaveListStr, ";")
	
	Wave Data2D = ImageNameToWaveRef(graphNameStr, FirstImageName)
	
	String DataFolder = GetWavesDataFolder(Data2D, 1) //Full Path to wave without the wave
	String DataFolderShort = GetWavesDataFolder(Data2D, 0) //Full Path to wave without the wave
	
	String PoleFigureFolder = DataFolder + "PoleFig"
	String PoleFigureFolderShort = DataFolderShort + "PoleFig"
	
	String XAxisStr = DataFolder + "XAxisStr"
	SVar XAxis = $XAxisStr
	String ZAxisStr = DataFolder + "ZAxisStr"
	SVar ZAxis = $ZAxisStr
		
	String XAxisValuesStr = DataFolder + "XAxisValues"
	Wave XAxisValues = $XAxisValuesStr

 	String PosStr_a = "root:ParameterAndVariable:Pos" + num2str(ProfileNo) + "a"
	NVar Pos_a = $PosStr_a //Lower Position
 	 	
 	String PosStr_b = "root:ParameterAndVariable:Pos" + num2str(ProfileNo) + "b"
  	NVar Pos_b = $PosStr_b //Upper Position

	if (DataFolderExists(PoleFigureFolder))
 		//Folder is there and might be populated
 	else
 		//Folder has to be created
 		NewDataFolder $PoleFigureFolder
 	endif
	String NewWave =  PoleFigureFolder+":Prof" + num2str(ProfileNo)
	
	Variable noRows = dimsize(Data2D,0)
	Variable noCol = dimsize(Data2D,1)
	
	NVAr PoleIs90 = root:ParameterAndVariable:PoleIs90
	if(PoleIs90==1)
		Variable startAngle = DimOffset(Data2D, 1)-90
	else
		StartAngle = DimOffset(Data2D, 1)	
	endif
	Variable deltaAngle = DimDelta(Data2D, 1)	
		
	Make/O/N=(noCol) $NewWave
	Wave NewWaveX =  $NewWave
	SetScale/P x startAngle,deltaAngle,"", NewWaveX
	NewWaveX = 0
	String NoteStr = "Position_A: " +num2str(Pos_a) + ";Position_B: " + num2str(Pos_B)
	Note/K NewWaveX NoteStr
		
	if (abs(Pos_b-Pos_a) <= 0)
		NewWaveX = Data2D[Pos_a][p]
	else
		Variable i,k, cnt, value
		for(k=0; k < noCol; k+=1)
			cnt = 0
			for (i = min(Pos_a, Pos_b); i<= max(Pos_a, Pos_b); i+=1)
				value = Data2D[i][k]
				if(numtype(value) != 0)
				else
					NewWaveX[k] += value
					cnt+=1
				endif
			endfor
			NewWaveX[k] = NewWaveX[k]/cnt
		endfor	
	endif	
	//DisplayAverages(graphNameStr)
end

function DisplayAverages(graphNameStr)
	String graphNameStr
	
	String WaveListStr = ImageNameList(graphNameStr, ";" )
	String FirstImageName = StringFromList(0, WaveListStr, ";")
	Wave Data2D = ImageNameToWaveRef(graphNameStr, FirstImageName)
	String DataFolder = GetWavesDataFolder(Data2D, 1) //Full Path to wave without the wave
	String DataFolderShort = GetWavesDataFolder(Data2D, 0) //Full Path to wave without the wave
	
	String PoleFigureFolder = DataFolder + "PoleFig"
	String PoleFigureFolderShort = DataFolderShort + "PoleFig"
	
	String AvgWindowStr = FirstImageName + "Prof"
	
	DoWindow/F $AvgWindowStr
	if (V_flag == 0)
  		// window does not exist
		Display/N=$AvgWindowStr
		Variable i
		for(i=0; i<3; i+=1)
			String NewWave =  PoleFigureFolder+":Prof" + num2str(i)
			Wave NewWaveX =  $NewWave
			switch(i)
				case 0:
					Variable red =65280; Variable green = 43520; Variable blue = 32768;	//Peach
					break

				case 1:
					red = 65535; green = 0; blue = 0;	//Red
					break
				
				case 2:
					red = 65280; green = 43520; blue = 0; //Orange
					break
			endswitch
			AppendToGraph/W=$AvgWindowStr NewWaveX;DelayUpdate
			ModifyGraph rgb[i]=(red, green, blue);DelayUpdate
		endfor		
  		Label left "Intensity";DelayUpdate
		Label bottom "Angle"; DelayUpdate
		ModifyGraph log(left)=0,log(bottom)=0; DelayUpdate
		ModifyGraph mirror=2; DelayUpdate
		ModifyGraph margin(top)=7,margin(right)=7
		DoUpdate/W=$AvgWindowStr
	endif
end

function CalcBackgroundCorrPoleFig(graphNameStr)
	String graphNameStr
	
	String WaveListStr = ImageNameList(graphNameStr, ";" )
	String FirstImageName = StringFromList(0, WaveListStr, ";")
	Wave Data2D = ImageNameToWaveRef(graphNameStr, FirstImageName)
	String DataFolder = GetWavesDataFolder(Data2D, 1) //Full Path to wave without the wave
	String DataFolderShort = GetWavesDataFolder(Data2D, 0) //Full Path to wave without the wave
	String PoleFigureFolder = DataFolder + "PoleFig"
	String PoleFigureFolderShort = DataFolderShort + "PoleFig"
	
	String BckgrndLowStr =  PoleFigureFolder+":Prof0"
	String DataUncorrStr =  PoleFigureFolder+":Prof1"
	String BckgrndHighStr =  PoleFigureFolder+":Prof2"
	String PoleFigStr =  PoleFigureFolder+":PoleFig"
	String SinCorrStr =  PoleFigureFolder+":SinCorrPole"
	Wave Bckgrnd_LowQ = $BckgrndLowStr
	Wave DataUncorr = $DataUncorrStr
	Wave Bckgrnd_HighQ = $BckgrndHighStr
	duplicate/O DataUncorr, $PoleFigStr
	Wave PoleFig = $PoleFigStr
  	duplicate/O DataUncorr, $SinCorrStr
	Wave SinCorrPoleFig = $SinCorrStr
  	  	
  	NVar Pos0a =root:ParameterAndVariable:Pos0a
  	NVar Pos0b =root:ParameterAndVariable:Pos0b
  	NVar Pos1a =root:ParameterAndVariable:Pos1a
  	NVar Pos1b =root:ParameterAndVariable:Pos1b
  	NVar Pos2a =root:ParameterAndVariable:Pos2a
  	NVar Pos2b =root:ParameterAndVariable:Pos2b
  	NVar CrystValue = root:ParameterAndVariable:CrystValue
  	NVar Orientation = root:ParameterAndVariable:OrientValue
   
  	Variable Pos0 = (Pos0b+Pos0a)/2
  	Variable Pos1 = (Pos1b+Pos1a)/2
  	Variable Pos2 = (Pos2b+Pos2a)/2
  	 
  	//Calculation of the background corrected polefigure
  	//Assume linear background and use the Mittelwertsatz der Integralrechnung   	 
  	PoleFig *= abs(Pos1b-Pos1a+1)
	PoleFig[] -= ( (Bckgrnd_HighQ[p] - Bckgrnd_LowQ[p])/(Pos2 - Pos0) * (1/2*((Pos1b+0.5)^2 - (Pos1a-0.5)^2) - Pos0*(Pos1b-Pos1a+1)) + Bckgrnd_LowQ[p]*(Pos1b-Pos1a+1) )
	
	SinCorrPoleFig = PoleFig*abs(sin(x/180*Pi))
	
	String NoteStr = "Background Corrected PoleFigure\r"
	NoteStr += "Background_A: " + num2str(Pos0) + " ("+ num2str(Pos0a)  +", " +num2str(Pos0b) + ")\r"
	NoteStr += "Background_B: " + num2str(Pos2) + " ("+ num2str(Pos2a)  + ", " +num2str(Pos2b) + ")\r"
	NoteStr += "Profile Posiiton: " + num2str(Pos1) + " ("+ num2str(Pos1a)  + ", " +num2str(Pos1b) + ")"
	
	Note PoleFig NoteStr
	Note SinCorrPoleFig NoteStr
	
	NVar IntMinus90To90 = root:ParameterAndVariable:IntMinus90To90
	if(IntMinus90To90==1)
		Variable MinX = -90
		Variable MaxX = 90	
		NoteStr = "Integrated Pole Figure Value (-90, 90) = "
		Variable factor = 1
	else
		MinX = 0  //Subh change
		MaxX = 90  //Subh change
		NoteStr = "Integrated Pole Figure Value 2x(0, 90) = "  //Subh change
		factor = 2
	endif
	
	CrystValue  = factor*area(SinCorrPoleFig, MinX, MaxX)
	NoteStr += num2str(CrystValue)
	print "Crystallinity = ", Crystvalue  //Subh add
	
	Note SinCorrPoleFig, NoteStr

// calculate orientation parameter	
	Orientation = orientparam(sincorrpolefig, minX, maxX)
	
//	duplicate/O SinCorrPoleFig Normalisation
//	duplicate/O SinCorrPoleFig Zaehler
//	duplicate/O SinCorrPoleFig AngleInRad
//	
//	duplicate/O/R=(0,90) SinCorrPoleFig Normalisation  //Subh add
//	duplicate/O/R=(0,90) SinCorrPoleFig Zaehler        //Subh add
//	duplicate/O/R=(0,90) SinCorrPoleFig AngleInRad     //Subh add
//	
//	Variable Offset = dimOffset(SinCorrPoleFig,0)
//	Variable delta = dimDelta(SinCorrPoleFig,0)
//	AngleInRad = x/180*pi	
//		
//	Zaehler = SinCorrPoleFig * 1/2*(3*(cos(AngleInRad))^2-1)
//	Zaehler = Normalisation * (cos(AngleInRad))^2  //Subh add
//	
//	//The Integration is from a small angle to pi/half to avoid the evanescent field near the horizon
//	//Its hard to estimate the error due to the missing wedge in the data 
//	Orientation = AreaXY(AngleInRad,Zaehler,MinX/180*pi,MaxX/180*pi) / AreaXY(AngleInRad,Normalisation,MinX/180*pi, MaxX/180*pi)
//	Orientation = 0.5*(3*AreaXY(AngleInRad,Zaehler,0,MaxX/180*pi)/AreaXY(AngleInRad,Normalisation,0,MaxX/180*pi)-1)    //Subh add
//	print "Orientation = ", Orientation  //Subh add

//	Killwaves/Z Normalisation, Zaehler, AngleInRad

	Notestr = "Orientation = "  //Subh add
	NoteStr += num2str(Orientation)  //Subh add
	Note SinCorrPoleFig, NoteStr   //Subh add
	
	DoWindow/F $PoleFigureFolderShort
	if (V_flag == 0)
		Display/N=$PoleFigureFolderShort PoleFig
  		AppendToGraph/R SinCorrPoleFig
  		Label bottom "Angle [ °]"; DelayUpdate
  		Label left "Intensity [ a.u]";DelayUpdate
  		Label left "Intensity [ a.u]";DelayUpdate
		SetAxis bottom -90,90; DelayUpdate
		ModifyGraph nticks(bottom)=7; DelayUpdate
		ModifyGraph mirror(bottom)=2; DelayUpdate
		ModifyGraph rgb[0]=(0,0,0); DelayUpdate
		ModifyGraph rgb[1]=(30464,30464,30464); DelayUpdate
		Legend/C/N=text0/A=LT
		DoUpdate/W=$PoleFigureFolderShort
	else
		if(strlen(TraceInfo(PoleFigureFolderShort,NameOfWave(PoleFig), 0))==0)		
			AppendToGraph/W=$PoleFigureFolderShort PoleFig
  	 	endif
  	 	
  	 	if(strlen(TraceInfo(PoleFigureFolderShort,NameOfWave(SinCorrPoleFig), 0))==0)		
			AppendToGraph/R/W=$PoleFigureFolderShort SinCorrPoleFig
  	 	endif
	endif
end

//This is Updates the positons after coarse adjusting
function UpdateAllPositions(graphNameStr)
	String GraphNameStr

	Variable i
	for(i = 0; i<3; i+=1)
 	 	
 	 	String PosStr_a = "root:ParameterAndVariable:Pos" + num2str(i) + "a"
  	 	NVar Pos_a = $PosStr_a
  	 	String TraceName = "LineProfMarker_y"+num2str(i)+"a"	//This is something Igor doesn tdo well, if i use the whole wave name or the wave refernce it throws an error
  	 	Pos_a = UpdatePosition(graphNameStr, TraceName)
 	 	
 	 	String PosStr_b = "root:ParameterAndVariable:Pos" + num2str(i) + "b"
  	 	NVar Pos_b = $PosStr_b
  	 	TraceName = "LineProfMarker_y"+num2str(i)+"b"	//This is something Igor doesn tdo well, if i use the whole wave name or the wave refernce it throws an error
  	 	Pos_b = UpdatePosition(graphNameStr, TraceName)
 	 	
 	 	 CalcAverage(graphNameStr, i)
 	 	
	endfor 
	
	NVar DispBckgnrdProf = root:ParameterAndVariable:ShowBckgrndProf
	if(DispBckgnrdProf==1)
		DisplayAverages(graphNameStr) //Show each of the background Profiles
	endif
	
	SVAr Status =  root:ParameterAndVariable:Status 
	Status = "Positions UpToDate"

end

Function ButtonProcStartCoarseAdj(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			SVar graphNameStr =  root:ParameterAndVariable:graphNameStr 
			EnableDragAndDropp(graphNameStr)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcFinishCoarseAdj(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			SVar graphNameStr =  root:ParameterAndVariable:graphNameStr 
			FinishDragAndDropp(graphNameStr)
			UpdateAllPositions(graphNameStr)	//This also calculates the averages
			CalcBackgroundCorrPoleFig(graphNameStr)		
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function UpdateAfterValueChange()
	Variable i
	for(i = 0; i<3; i+=1)
 	 	SVar graphNameStr =  root:ParameterAndVariable:graphNameStr 
 	 	
 	 	String PosStr_a = "root:ParameterAndVariable:Pos" + num2str(i) + "a"
  	 	NVar Pos_a = $PosStr_a
  	 	String TraceName = "root:ParameterAndVariable:" + "LineProfMarker_x"+num2str(i)+"a"	//This is something Igor doesn tdo well, if i use the whole wave name or the wave refernce it throws an error
  	 	Wave Trace = $TraceName
  	 	Trace = Pos_a 
 	 	
 	 	String PosStr_b = "root:ParameterAndVariable:Pos" + num2str(i) + "b"
  	 	NVar Pos_b = $PosStr_b
  	 	TraceName = "root:ParameterAndVariable:" + "LineProfMarker_x"+num2str(i)+"b"	//This is something Igor doesn tdo well, if i use the whole wave name or the wave refernce it throws an error
  	 	Wave Trace = $TraceName
  	 	Trace = Pos_b 
 	 	
 	 	 CalcAverage(graphNameStr, i)
 	 	
	endfor 
	
	NVar DispBckgnrdProf = root:ParameterAndVariable:ShowBckgrndProf
	if(DispBckgnrdProf==1)
		DisplayAverages(graphNameStr) //Show each of the background Profiles
	else
		String WaveListStr = ImageNameList(graphNameStr, ";" )
		String FirstImageName = StringFromList(0, WaveListStr, ";")
		String AvgWindowStr = FirstImageName + "Prof"
		DoWindow/F $AvgWindowStr
		if (V_flag == 0)
			//WindowDoes not exist
		else
			KillWindow  $AvgWindowStr
		endif
	endif
	
	CalcBackgroundCorrPoleFig(graphNameStr)	
	
	SVAr Status =  root:ParameterAndVariable:Status 
	Status = "Positions UpToDate"
end

Function SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			UpdateAfterValueChange()
						
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcSetActWindow(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SVar graphNameStr =  root:ParameterAndVariable:graphNameStr 
			graphNameStr = WinName(0,1)			// Prints the name of the top graph.
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcAddProfiles(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			SVar graphNameStr  = root:ParameterAndVariable:graphNameStr 
			AddPosOfLineProfToSquareMap(graphNameStr)
			UpdateAfterValueChange() //This caluclates the Averages and Background Corr PoleFig
			
			//UpdateAllPositions(graphNameStr)	//This also calculates the averages
			//CalcBackgroundCorrPoleFig(graphNameStr)		
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcRemoveProfiles(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			SVar graphNameStr  = root:ParameterAndVariable:graphNameStr
			Variable i
			for(i=0;i<3;i+=1)
  	 			String TraceName = "LineProfMarker_y"+num2str(i)+"a"	//This is something Igor doesn tdo well, if i use the whole wave name or the wave refernce it throws an error
				if(strlen(TraceInfo(graphNameStr,TraceName, 0))!=0)		
					RemoveFromGraph/W=$graphNameStr $TraceName
  	 			endif
  	 			TraceName = "LineProfMarker_y"+num2str(i)+"b"	//This is something Igor doesn tdo well, if i use the whole wave name or the wave refernce it throws an error
				if(strlen(TraceInfo(graphNameStr,TraceName, 0))!=0)		
					RemoveFromGraph/W=$graphNameStr $TraceName
  	 			endif
			endfor
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CheckProcUpdate(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			UpdateAfterValueChange()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

///////////////////////////////////////////////////////////////////////////////////////