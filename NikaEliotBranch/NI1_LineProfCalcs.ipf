#pragma rtGlobals=1		// Use modern global access method.
#pragma version=2.01
//2.01 updted for Nika 1.43, changed error calculations
//2.0 updated for Nika 1.42
//Line profile functions for NIka
//version September 2009


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function NI1A_LineProf_CreateLP()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

		NVAR LineProf_GIIncAngle=root:Packages:Convert2Dto1D:LineProf_GIIncAngle
		NVAR LineProf_EllipseAR=root:Packages:Convert2Dto1D:LineProf_EllipseAR
		NVAR LineProf_LineAzAngle=root:Packages:Convert2Dto1D:LineProf_LineAzAngle
		NVAR LineProf_DistanceFromCenter=root:Packages:Convert2Dto1D:LineProf_DistanceFromCenter
		NVAR LineProf_Width=root:Packages:Convert2Dto1D:LineProf_Width
		NVAR LineProf_DistanceQ=root:Packages:Convert2Dto1D:LineProf_DistanceQ
		NVAR LineProf_WidthQ=root:Packages:Convert2Dto1D:LineProf_WidthQ
		NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance		//in millimeters
		NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength							//in A
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
		
		
		NVAR BeamCenterX=root:Packages:Convert2Dto1D:BeamCenterX
		NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
		NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
		NVAR HorizontalTilt=root:Packages:Convert2Dto1D:HorizontalTilt
		NVAR VerticalTilt=root:Packages:Convert2Dto1D:VerticalTilt
		NVAR LineProf_UseBothHalfs=root:Packages:Convert2Dto1D:LineProf_UseBothHalfs
		NVAR LineProf_SubtractBackground=root:Packages:Convert2Dto1D:LineProf_SubtractBackground
		
		
		NVAR UseMask=root:Packages:Convert2Dto1D:UseMask
		NVAR LineProfileUseRAW=root:Packages:Convert2Dto1D:LineProfileUseRAW
		NVAR LineProfileUseCorrData=root:Packages:Convert2Dto1D:LineProfileUseCorrData
		SVAR LineProf_CurveType=root:Packages:Convert2Dto1D:LineProf_CurveType
		NVAR HorizontalTilt=root:Packages:Convert2Dto1D:HorizontalTilt
		NVAR VerticalTilt=root:Packages:Convert2Dto1D:VerticalTilt
		NVAR ErrorCalculationsUseOld=root:Packages:Convert2Dto1D:ErrorCalculationsUseOld
		NVAR ErrorCalculationsUseStdDev=root:Packages:Convert2Dto1D:ErrorCalculationsUseStdDev
		NVAR ErrorCalculationsUseSEM=root:Packages:Convert2Dto1D:ErrorCalculationsUseSEM
		//abort if not selected anything meaningful..
	
		if(stringMatch(LineProf_CurveType,"Horizontal Line"))
			//Ok
		elseif(stringMatch(LineProf_CurveType,"Vertical Line"))
			//OK
		elseif(stringMatch(LineProf_CurveType,"Angle Line"))
			//OK
		elseif(stringMatch(LineProf_CurveType,"Ellipse"))
			//OK
		elseif(stringMatch(LineProf_CurveType,"GI_Vertical Line"))
			//OK
		elseif(stringMatch(LineProf_CurveType,"GI_Horizontal Line"))
			//OK
		else
			//not OK. End
			return 0
		endif	



		if(LineProfileUseRAW)
			Wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert_dis
		else
			Wave/Z CCDImageToConvert=root:Packages:Convert2Dto1D:Calibrated2DDataSet
			if(!WaveExists(CCDImageToConvert))
				DoAlert 0, "Corrected data do not exist"
				 return 0
			endif
		endif
		
		wave qxywave = root:Packages:Convert2Dto1D:qxywave
		wave qxwave = root:Packages:Convert2Dto1D:qxwave
		wave qywave = root:Packages:Convert2Dto1D:qywave
		wave qzwave = root:Packages:Convert2Dto1D:qzwave
		wave qxzwave = root:Packages:Convert2Dto1D:qxzwave
		wave xiwave = root:Packages:Convert2Dto1D:Xiwave
		
		
		
		
		//deal with wave note...
		string OldNote=note(CCDImageToConvert)
		//first check if our mask is OK here...
		if(UseMask)
			wave M_ROIMask=root:Packages:Convert2Dto1D:M_ROIMask
			MatrixOp/O MaskedQ2DWave = CCDImageToConvert *( M_ROIMask/M_ROIMask)
		else
			MatrixOp/O MaskedQ2DWave = CCDImageToConvert
		endif
		//Need to create 2d q waves for dataset
		//NI1A_Create2DQWave(CCDImageToConvert)
		
		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		//wave q2dwave
		//if(!waveexists(q2dwave))
			if(UseGrazingIncidence)
				GI_ReHistImage()
			else
				NI1A_Create2DQWave(CCDImageToConvert)
			endif
		//endif
		wave q2dwave
		//first create xwave and ywave for the ImageLineProfile...
		variable length
		if(stringMatch(LineProf_CurveType,"Horizontal Line")||stringMatch(LineProf_CurveType,"GI_Horizontal Line"))
			length=DimSize(CCDImageToConvert, 0 )
			make/O/N=(length) xwave, ywave
		elseif(stringMatch(LineProf_CurveType,"Vertical Line")||stringMatch(LineProf_CurveType,"GI_Vertical Line")||stringMatch(LineProf_CurveType,"GISAXS_FixQy"))
			length=DimSize(CCDImageToConvert, 1 )
			make/O/N=(length) xwave, ywave
		elseif(stringMatch(LineProf_CurveType,"Angle Line"))
			variable dim1
			dim1=max(DimSize(CCDImageToConvert, 0 ),DimSize(CCDImageToConvert, 1 ))
			make/O/N=(dim1) xwave
			make/O/N=(dim1) ywave
		elseif(stringMatch(LineProf_CurveType,"Ellipse"))
			make/O/N=(1440) xwave, ywave			//every 0.25 degrees should be enough...
		endif	
		//here we create paths as needed... This should be the same as in the NI1A_DrawLinesIn2DGraph function
		if(stringMatch(LineProf_CurveType,"Horizontal Line")||stringMatch(LineProf_CurveType,"GI_Horizontal Line"))
			xwave=BeamCenterY-LineProf_DistanceFromCenter
			ywave=p
		elseif(stringMatch(LineProf_CurveType,"Vertical Line")||stringMatch(LineProf_CurveType,"GI_Vertical Line"))
			xwave=p
			ywave=BeamCenterX+LineProf_DistanceFromCenter
		elseif(stringMatch(LineProf_CurveType,"Angle Line"))
			NI1A_GenerAngleLine(Dimsize(CCDImageToConvert, 0),Dimsize(CCDImageToConvert, 1),BeamCenterX,BeamCenterY,LineProf_LineAzAngle,LineProf_DistanceFromCenter,yWave,xWave)
		endif
		if(stringMatch(LineProf_CurveType,"Ellipse")) // altered by eliot to automatically subtract background levels
			if(LineProf_SubtractBackground)
				NI1A_GenerEllipseLine(BeamCenterX,BeamCenterY,LineProf_EllipseAR,LineProf_DistanceFromCenter-LineProf_Width,yWave,xWave)
				ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=MaskedQ2DWave , width= LineProf_Width
				Wave W_ImageLineProfile = root:Packages:Convert2Dto1D:W_ImageLineProfile
				duplicate /o W_ImageLineProfile, lo_imagelineprofile
				NI1A_GenerEllipseLine(BeamCenterX,BeamCenterY,LineProf_EllipseAR,LineProf_DistanceFromCenter+LineProf_Width,yWave,xWave)
				ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=MaskedQ2DWave , width= LineProf_Width
				Wave W_ImageLineProfile = root:Packages:Convert2Dto1D:W_ImageLineProfile
				duplicate /o W_ImageLineProfile, hi_imagelineprofile
				NI1A_GenerEllipseLine(BeamCenterX,BeamCenterY,LineProf_EllipseAR,LineProf_DistanceFromCenter,yWave,xWave)
				ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=MaskedQ2DWave , width= LineProf_Width
				Wave W_ImageLineProfile = root:Packages:Convert2Dto1D:W_ImageLineProfile
				Wave W_LineProfileX = root:Packages:Convert2Dto1D:W_LineProfileX
				Wave W_LineProfileY = root:Packages:Convert2Dto1D:W_LineProfileY
				Wave W_ImageLineProfile = root:Packages:Convert2Dto1D:W_ImageLineProfile
				W_ImageLineProfile -= (lo_imagelineprofile + hi_imagelineprofile)/2
				Wave W_LineProfileStdv=root:Packages:Convert2Dto1D:W_LineProfileStdv
			else
				NI1A_GenerEllipseLine(BeamCenterX,BeamCenterY,LineProf_EllipseAR,LineProf_DistanceFromCenter,yWave,xWave)
				ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=MaskedQ2DWave , width= LineProf_Width
				Wave W_LineProfileX = root:Packages:Convert2Dto1D:W_LineProfileX
				Wave W_LineProfileY = root:Packages:Convert2Dto1D:W_LineProfileY
				Wave W_ImageLineProfile = root:Packages:Convert2Dto1D:W_ImageLineProfile
				Wave W_LineProfileStdv=root:Packages:Convert2Dto1D:W_LineProfileStdv
			endif
		else
			ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=MaskedQ2DWave , width= LineProf_Width
			Wave W_LineProfileX = root:Packages:Convert2Dto1D:W_LineProfileX
			Wave W_LineProfileY = root:Packages:Convert2Dto1D:W_LineProfileY
			Wave W_ImageLineProfile = root:Packages:Convert2Dto1D:W_ImageLineProfile
			Wave W_LineProfileStdv=root:Packages:Convert2Dto1D:W_LineProfileStdv
		endif

		if(LineProf_Width<2)
			Print "NOTE::: Width used for line profile is less than 2 points. Intensity error in this case is calculated as square root of intensity, which may be WRONG."
			W_LineProfileStdv=sqrt(W_ImageLineProfile)
		else
			if(ErrorCalculationsUseSEM)
				W_LineProfileStdv/=sqrt(LineProf_Width)
			endif
			//Print "NOTE: Width used for line profile is 2 points or more, used standard deviation to estimate intensity error."
		endif
		
		Duplicate/O W_ImageLineProfile, LineProfileIntensity, LineProfileQvalues
		Duplicate/O W_LineProfileStdv, LineProfileIntSdev
//		Duplicate/O W_LineProfileX, LineProfileYValsPix		//note: I screwed up above, so this needs to be changed...
//		Duplicate/O W_LineProfileY, LineProfileZValsPix
		//Added by Eliot to get all Q and angle profiles that may be needed
		// be careful here about the scaling of the q waves, if it is not the same as xwave and y wave (which right now is no scaling) then there will be bad problems.)
		ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=Q2DWave , width= LineProf_Width
		Duplicate/O W_ImageLineProfile, LineProfileQvalues
		ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=qxywave , width= LineProf_Width
		Duplicate/O W_ImageLineProfile, LineProfileQy
		ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=Qzwave , width= LineProf_Width
		Duplicate/O W_ImageLineProfile, LineProfileQz
		ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=Qxywave , width= LineProf_Width
		Duplicate/O W_ImageLineProfile, LineProfileQxy
//		ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=qxzwave , width= LineProf_Width
//		Duplicate/O W_ImageLineProfile, LineProfileQxz
		ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=qxwave , width= LineProf_Width
		Duplicate/O W_ImageLineProfile, LineProfileQx
		ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=xiwave , width= LineProf_Width
		Duplicate/O W_ImageLineProfile, LineProfileXi
		LineprofileXi *=sign(lineprofileqxy)
		
		//add notes...
		note LineProfileIntensity,  OldNote
		note  LineProfileQvalues, OldNote
		note LineProfileIntSdev,  OldNote
		note  LineProfileQy,  OldNote
		note  LineProfileQz , OldNote
		note  LineProfileQx , OldNote
		note  LineProfileQxy , OldNote
//		note  LineProfileQxz , OldNote
		note  LineProfileXi , OldNote
		
		//and now add the mirror lines, if needed...
		if(LineProf_UseBothHalfs)
				variable skipme=0
				if(stringMatch(LineProf_CurveType,"Horizontal Line")||stringMatch(LineProf_CurveType,"GI_Horizontal Line"))
					xwave=LineProf_DistanceFromCenter+BeamCenterY
					ywave=p
				elseif(stringMatch(LineProf_CurveType,"Vertical Line")||stringMatch(LineProf_CurveType,"GI_Vertical Line"))
					xwave=p
					ywave=BeamCenterX-LineProf_DistanceFromCenter
				else 
					skipme=1
				endif
				if(!skipme)	
					ImageLineProfile/S xWave=ywave, yWave=xwave, srcwave=MaskedQ2DWave , width= LineProf_Width
					Wave W_LineProfileX = root:Packages:Convert2Dto1D:W_LineProfileX
					Wave W_LineProfileY = root:Packages:Convert2Dto1D:W_LineProfileY
					Wave W_ImageLineProfile = root:Packages:Convert2Dto1D:W_ImageLineProfile
					Wave W_LineProfileStdv=root:Packages:Convert2Dto1D:W_LineProfileStdv

					if(LineProf_Width<2)
						W_LineProfileStdv=sqrt(W_ImageLineProfile)
					else
						if(ErrorCalculationsUseSEM)
							W_LineProfileStdv/=sqrt(LineProf_Width)
						else
						endif
					endif
					
					Duplicate/O W_ImageLineProfile, LineProfileIntensity2
					Duplicate/O W_LineProfileStdv, LineProfileIntSdev2
					
					NI1_SumTwoIntensitiesWithNaNs(LineProfileIntensity,LineProfileIntensity2)
					NI1_SumTwoErrorsWithNaNs(LineProfileIntSdev,LineProfileIntSdev2)
					KillWaves LineProfileIntSdev2,LineProfileIntensity2
				endif
		endif
		KillWaves MaskedQ2DWave
		
		//now we need to calculate the right Q values... There is difference between the regular geometry and GI geometry...
//		if(!stringMatch(LineProf_CurveType,"GI_Horizontal Line") && !stringMatch(LineProf_CurveType,"GI_vertical Line"))		//regular geometry...
//			//first convert to position in pixels...
//			LineProfileYValsPix = LineProfileYValsPix[p] - BeamCenterX
//			LineProfileZValsPix = BeamCenterY- LineProfileZValsPix[p] 
//			//now convert to distance in mm
//			LineProfileQy =PixelSizeX*LineProfileYValsPix[p]
//			LineProfileQz =PixelSizeY*LineProfileZValsPix[p]
//			//now fix tilts, if needed
//			LineProfileQy=NI1T_TiltedToCorrectedR( LineProfileQy[p] ,SampleToCCDDistance,HorizontalTilt) 	//in mm 
//			LineProfileQz=NI1T_TiltedToCorrectedR( LineProfileQz[p] ,SampleToCCDDistance,VerticalTilt) 	//in mm 
//
//			LineProfileQy = NI1A_LP_ConvertPosToQ(LineProfileQy[p], SampleToCCDDistance, Wavelength)
//			LineProfileQz = NI1A_LP_ConvertPosToQ(LineProfileQz[p], SampleToCCDDistance, Wavelength)
//
//		//	LineProfileQvalues=sign(LineProfileQy[p])*sign(LineProfileQz[p])*sqrt((LineProfileQy[p])^2+(LineProfileQz[p])^2)
//			LineProfileQvalues=sign(LineProfileQz[p])*sqrt((LineProfileQy[p])^2+(LineProfileQz[p])^2)
//		elseif(stringMatch(LineProf_CurveType,"GI_Horizontal Line"))		//GI geometry....
//			Duplicate/O LineProfileQy, LineProfileQx, tempY
//			LineProfileQx = NI1GI_CalculateQxyz(LineProfileYValsPix[p],LineProfileZValsPix[p],"X")
//			LineProfileQy = NI1GI_CalculateQxyz(LineProfileYValsPix[p],LineProfileZValsPix[p],"Y")
//			LineProfileQz = NI1GI_CalculateQxyz(LineProfileYValsPix[p],LineProfileZValsPix[p],"Z")
//			LineProfileQvalues=sign(LineProfileQy[p])*sign(LineProfileQz[p])*sqrt((LineProfileQx[p])^2+(LineProfileQy[p])^2+(LineProfileQz[p])^2)
//		elseif(stringMatch(LineProf_CurveType,"GI_vertical Line"))		//GI geometry....
//			Duplicate/O LineProfileQy, LineProfileQx, tempY
//			LineProfileQx = NI1GI_CalculateQxyz(LineProfileYValsPix[p],LineProfileZValsPix[p],"X")
//			LineProfileQy = NI1GI_CalculateQxyz(LineProfileYValsPix[p],LineProfileZValsPix[p],"Y")
//			LineProfileQz = NI1GI_CalculateQxyz(LineProfileYValsPix[p],LineProfileZValsPix[p],"Z")
//			LineProfileQvalues=sign(LineProfileQy[p])*sign(LineProfileQz[p])*sqrt((LineProfileQx[p])^2+(LineProfileQy[p])^2+(LineProfileQz[p])^2)
//		endif
		//add to the note some info for user...
		string Newnote=""
		Newnote+=	"LineProf_DistanceFromCenter="+num2str(LineProf_DistanceFromCenter)+";"
		Newnote+=	"LineProf_Width="+num2str(LineProf_Width)+";"
		Newnote+=	"LineProf_DistanceQ="+num2str(LineProf_DistanceQ)+";"
		Newnote+=	"LineProf_UseBothHalfs="+num2str(LineProf_UseBothHalfs)+";"
		Newnote+=	"LineProf_SubtractBackground="+num2str(LineProf_SubtractBackground)+";"
		Newnote+=	"UseMask="+num2str(UseMask)+";"
		Newnote+=	"LineProfileUseRAW="+num2str(LineProfileUseRAW)+";"
		Newnote+=	"LineProfileUseCorrData="+num2str(LineProfileUseCorrData)+";"
		Newnote+=	"LineProf_CurveType="+LineProf_CurveType+";"

		if(ErrorCalculationsUseSEM)
			Newnote+="UncertainityCalculationMethod=StandardErrorOfMean;"
		else
			Newnote+="UncertainityCalculationMethod=StandardDeviation;"		
		endif

		note LineProfileIntensity , Newnote
		note  LineProfileQvalues , Newnote
		note LineProfileIntSdev , Newnote
		note  LineProfileQy , Newnote
		note  LineProfileQz , Newnote
		note  LineProfileQx , Newnote
		note  LineProfileQxy , Newnote
//		note  LineProfileQxz , Newnote
		note  LineProfileXi , Newnote

	setDataFolder OldDf
	return 1
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1_SumTwoIntensitiesWithNaNs(wave1,wave2)
	Wave wave1,wave2
	//returns average of the two waves if both exists or if one in NaN, returns just the single value
	variable i
	if(numpnts(wave1)!=numpnts(wave2))
		abort  "Error in NI1_SumTwoIntensitiesWithNaNs"
	endif
	For(i=0;i<numpnts(wave1);i+=1)
		if(numtype(Wave1[i])==0 && numtype(wave2[i])==0)
			Wave1[i]=(Wave1[i] + Wave2[i])/2
		elseif(numtype(Wave1[i])==0)
			Wave1[i]=Wave1[i]
		elseif(numtype(wave2[i])==0)
			Wave1[i]=Wave2[i]
		else
			Wave1[i]=nan
		endif 
	endfor
end
Function NI1_SumTwoErrorsWithNaNs(wave1,wave2)
	Wave wave1,wave2
	//returns average of the two waves if both exists or if one in NaN, returns just the single value
	variable i
	if(numpnts(wave1)!=numpnts(wave2))
		abort  "Error in NI1_SumTwoErrorsWithNaNs"
	endif
	For(i=0;i<numpnts(wave1);i+=1)
		if(numtype(Wave1[i])==0 && numtype(wave2[i])==0)
			Wave1[i]=sqrt((Wave1[i]^2 + Wave2[i]^2))
		elseif(numtype(Wave1[i])==0)
			Wave1[i]=Wave1[i]
		elseif(numtype(wave2[i])==0)
			Wave1[i]=Wave2[i]
		else
			Wave1[i]=nan
		endif 
	endfor


end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1A_LP_ConvertPosToQ(distance, SampleToCCDDistance, Wavelength)
		variable distance, SampleToCCDDistance, Wavelength
		
		variable theta=atan(abs(distance)/SampleToCCDDistance)/2
		return sign(distance)*((4*pi)/Wavelength)*sin(theta)

end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1A_LineProf_DisplayLP()
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

		Wave LineProfileQy = root:Packages:Convert2Dto1D:LineProfileQy
		Wave LineProfileQz = root:Packages:Convert2Dto1D:LineProfileQz
		Wave LineProfileQvalues = root:Packages:Convert2Dto1D:LineProfileQvalues
		Wave LineProfileIntSdev = root:Packages:Convert2Dto1D:LineProfileIntSdev
		Wave LineProfileIntensity = root:Packages:Convert2Dto1D:LineProfileIntensity

	DoWindow LineProfile_Preview
	if(V_Flag)
		DoWIndow/F LineProfile_Preview
	else
		Display/W=(400,600,1000,788)/K=1 as "Line Profile Preview"
		DoWindow/C LineProfile_Preview
		ControlBar /T/W=LineProfile_Preview 25
		CheckBox DisplayQ,pos={5,5},size={10,14},proc=NI1_LineProf_CheckProc,title="Use Q?"
		CheckBox DisplayQ,help={"Use Q as x axis for the graph?"}, mode=1
		CheckBox DisplayQ,variable= root:Packages:Convert2Dto1D:LineProfileDisplayWithQ
		CheckBox DisplayQy,pos={70,5},size={10,14},proc=NI1_LineProf_CheckProc,title=" Qy?"
		CheckBox DisplayQy,help={"Use Qy as x axis for the graph?"}, mode=1
		CheckBox DisplayQy,variable= root:Packages:Convert2Dto1D:LineProfileDisplayWithQy
		CheckBox DisplayQz,pos={145,5},size={10,14},proc=NI1_LineProf_CheckProc,title=" Qz?"
		CheckBox DisplayQz,help={"Use Qz as x axis for the graph?"}, mode=1
		CheckBox DisplayQz,variable= root:Packages:Convert2Dto1D:LineProfileDisplayWithQz

		CheckBox LineProfileDisplayLogX,pos={220,5},size={10,14},proc=NI1_LineProf_CheckProc,title=" Log X Axis?"
		CheckBox LineProfileDisplayLogX,help={"Use log x axis for the graph?"}, mode=0
		CheckBox LineProfileDisplayLogX,variable= root:Packages:Convert2Dto1D:LineProfileDisplayLogX

		CheckBox LineProfileDisplayLogY,pos={325,5},size={10,14},proc=NI1_LineProf_CheckProc,title=" Log Y axis?"
		CheckBox LineProfileDisplayLogY,help={"Use log y axis for the graph?"}, mode=0
		CheckBox LineProfileDisplayLogY,variable= root:Packages:Convert2Dto1D:LineProfileDisplayLogY
		
		Button SaveDataNow, pos={420,5}, size={100,15}, title="Save Data",proc=NI1_LineProf_ButtonProc
		AutoPositionWindow/E/M=1/R=CCDImageToConvertFig
	endif
	CheckDisplayed /W=LineProfile_Preview  LineProfileIntensity 
	if(V_Flag)
		RemoveFromGraph /W=LineProfile_Preview  LineProfileIntensity 
	endif
	
		NVAR LineProfileDisplayWithQz=root:Packages:Convert2Dto1D:LineProfileDisplayWithQz
		NVAR LineProfileDisplayWithQy=root:Packages:Convert2Dto1D:LineProfileDisplayWithQy
		NVAR LineProfileDisplayWithQ=root:Packages:Convert2Dto1D:LineProfileDisplayWithQ
		NVAR LineProfileDisplayLogX=root:Packages:Convert2Dto1D:LineProfileDisplayLogX
		NVAR LineProfileDisplayLogY=root:Packages:Convert2Dto1D:LineProfileDisplayLogY
	if(LineProfileDisplayWithQ)
		AppendTograph LineProfileIntensity vs LineProfileQvalues
		Label bottom "Q [1/A]"
	elseif(LineProfileDisplayWithQy)
		AppendTograph LineProfileIntensity vs LineProfileQy  //Graph line profile Eliot
		Label bottom "Qy [1/A]"
	else
		AppendTograph LineProfileIntensity vs LineProfileQz
		Label bottom "Qz [1/A]"
	endif
	if(LineProfileDisplayLogX)
		ModifyGraph log(bottom)=1
	else
		ModifyGraph log(bottom)=0
	endif
	if(LineProfileDisplayLogY)
		ModifyGraph log(left)=1
	else
		ModifyGraph log(left)=0
	endif
	Label left "Intensity"
	ErrorBars LineProfileIntensity Y,wave=(LineProfileIntSdev,LineProfileIntSdev)
	setDataFolder OldDf

end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1_LineProf_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here'
			
			//SaveDataNow
				NVAR LineProf_DistanceQ=root:Packages:Convert2Dto1D:LineProf_DistanceQ
				NVAR LineProf_WidthQ=root:Packages:Convert2Dto1D:LineProf_WidthQ
				SVAR LineProf_CurveType=root:Packages:Convert2Dto1D:LineProf_CurveType	
				NVAR LineProf_LineAzAngle=root:Packages:Convert2Dto1D:LineProf_LineAzAngle
				nvar wavelength = root:Packages:Convert2Dto1D:wavelength
				string wavelengths = num2str(round(wavelength*100))
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
					sprintf tempStr, "%1.2f" LineProf_DistanceQ
				elseif(stringMatch(LineProf_CurveType,"Ellipse"))
					tempStr1="ELp_"
					sprintf tempStr, "%1.2g" LineProf_DistanceQ
				elseif(stringMatch(LineProf_CurveType,"Angle Line"))
					tempStr1="ALp_"
					sprintf tempStr, "%1.2g" LineProf_LineAzAngle
				endif
//				nvar supexchar = root:Packages:Nika1101:SupExChar
//				if(supexchar)
//					NI1A_SaveDataPerUserReq(tempStr1,wavelengths)
//				else
					NI1A_SaveDataPerUserReq(tempStr1+tempStr,wavelengths)
//				endif
			break
	endswitch

	return 0
End

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1_LineProf_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			NVAR LineProfileDisplayWithQz=root:Packages:Convert2Dto1D:LineProfileDisplayWithQz
			NVAR LineProfileDisplayWithQy=root:Packages:Convert2Dto1D:LineProfileDisplayWithQy
			NVAR LineProfileDisplayWithQ=root:Packages:Convert2Dto1D:LineProfileDisplayWithQ
			if(stringmatch(cba.ctrlName,"DisplayQ")&&LineProfileDisplayWithQ)
				LineProfileDisplayWithQz=0
				LineProfileDisplayWithQy=0
				NI1A_LineProf_DisplayLP()
			endif
			if(stringmatch(cba.ctrlName,"DisplayQz")&&LineProfileDisplayWithQz)
				LineProfileDisplayWithQ=0
				LineProfileDisplayWithQy=0
				NI1A_LineProf_DisplayLP()
			endif
			if(stringmatch(cba.ctrlName,"DisplayQy")&&LineProfileDisplayWithQy)
				LineProfileDisplayWithQz=0
				LineProfileDisplayWithQ=0
				NI1A_LineProf_DisplayLP()
			endif
			NVAR LineProfileDisplayLogX=root:Packages:Convert2Dto1D:LineProfileDisplayLogX
			NVAR LineProfileDisplayLogY=root:Packages:Convert2Dto1D:LineProfileDisplayLogY
			if(stringmatch(cba.ctrlName,"LineProfileDisplayLogX"))
				ModifyGraph log(bottom)=LineProfileDisplayLogX
			endif
			if(stringmatch(cba.ctrlName,"LineProfileDisplayLogY"))
				ModifyGraph log(left)=LineProfileDisplayLogY
			endif
	


			break
	endswitch

	return 0
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
