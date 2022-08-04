#pragma rtGlobals=1		// Use modern global access method.
#pragma version=2.05
#include <TransformAxis1.2>

// 2.05 3/3/2010  fixed bug for adding Q scales which failed when InvertImages was used. 
// 2.04  2/26/2010 added match strings for sample and empty/dark names
//2.03 2/22/2010 added ability to display the Q axes on the image
//2.02 Pilatus stuff
// 2.01 12/06/2009... Changed error calculations to multiple choice. Version 1.43.
//2.00  10/25/2009... Many changes related to line profile tools and some minor fixes. JIL.
//1.11 9/3/09 fixed I0Monitor count showing up at wrong time, JIL. 
// 1.1 updated 8/31 to address Polarization correction, JIL		
//1.01 changed ADSC type to only display .img files. 

//	NVAR Use2DdataName=root:Packages:Convert2Dto1D:Use2DdataName
//	NVAR UseCorrectionFactor=root:Packages:Convert2Dto1D:UseCorrectionFactor
//	NVAR UseDarkField=root:Packages:Convert2Dto1D:UseDarkField
//	NVAR UseDarkMeasTime=root:Packages:Convert2Dto1D:UseDarkMeasTime
//	NVAR UseEmptyField=root:Packages:Convert2Dto1D:UseEmptyField
//	NVAR UseEmptyMeasTime=root:Packages:Convert2Dto1D:UseEmptyMeasTime
//	NVAR UseI0ToCalibrate=root:Packages:Convert2Dto1D:UseI0ToCalibrate
//	NVAR UseMask=root:Packages:Convert2Dto1D:UseMask
//	NVAR UseMonitorForEF=root:Packages:Convert2Dto1D:UseMonitorForEF
//	NVAR UsePixelSensitivity=root:Packages:Convert2Dto1D:UsePixelSensitivity
//	NVAR UseSampleMeasTime=root:Packages:Convert2Dto1D:UseSampleMeasTime
//	NVAR UseSampleThickness=root:Packages:Convert2Dto1D:UseSampleThickness
//	NVAR UseSampleTransmission=root:Packages:Convert2Dto1D:UseSampleTransmission
//	NVAR UseSubtractFixedOffset=root:Packages:Convert2Dto1D:UseSubtractFixedOffset

//DisplayDataAfterProcessing;"
//	ListOfVariables+="DoSectorAverages;NumberOfSectors;SectorsStartAngle;SectorsHalfWidth;SectorsStepInAngle;"
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_AverageDataPerUserReq(orientation,wavelengths)
	STRING ORIENTATION
	string wavelengths

	string OldDf = GetDataFolder(1)
	setDataFolder root:Packages:Convert2Dto1D
	
	Wave Calibrated2DDataSet=root:Packages:Convert2Dto1D:Calibrated2DDataSet
	string OldNote=note(Calibrated2DDataSet)

	wave LUT=$("root:Packages:Convert2Dto1D:LUT_"+orientation+"_"+wavelengths)
	wave HistogramWv=$("root:Packages:Convert2Dto1D:HistogramWv_"+orientation+"_"+wavelengths)
	wave QvectorA=$("root:Packages:Convert2Dto1D:Qvector_"+orientation+"_"+wavelengths)
	wave QvectorWidth=$("root:Packages:Convert2Dto1D:QvectorWidth_"+orientation+"_"+wavelengths)

	wave TwoThetaA=$("root:Packages:Convert2Dto1D:TwoTheta_"+orientation+"_"+wavelengths)
	wave TwoThetaWidthA=$("root:Packages:Convert2Dto1D:TwoThetaWidth_"+orientation+"_"+wavelengths)

	wave DspacingA=$("root:Packages:Convert2Dto1D:Dspacing_"+orientation+"_"+wavelengths)
	wave DspacingWidthA=$("root:Packages:Convert2Dto1D:DspacingWidth_"+orientation+"_"+wavelengths)
	
	NVAR DoGeometryCorrection=root:Packages:Convert2Dto1D:DoGeometryCorrection
	NVAR DoPolarizationCorrection=root:Packages:Convert2Dto1D:DoPolarizationCorrection
	NVAR Use1DPolarizationCor=root:Packages:Convert2Dto1D:Use1DPolarizationCor
	NVAR Use2DPolarizationCor=root:Packages:Convert2Dto1D:Use2DPolarizationCor
	NVAR StartAngle2DPolCor=root:Packages:Convert2Dto1D:StartAngle2DPolCor


	NVAR QvectorNumberPoints=root:Packages:Convert2Dto1D:QvectorNumberPoints
	NVAR QvectorMaxNumPnts=root:Packages:Convert2Dto1D:QvectorMaxNumPnts
	
	OldNote+="QvectorMaxNumPnts="+num2str(QvectorMaxNumPnts)+";"
	OldNote+="QvectorNumberPoints="+num2str(QvectorNumberPoints)+";"
	OldNote+="Wavelength="+wavelengths+";"
	if(cmpstr(orientation,"C")==0)
		OldNote+="CircularAverage="+"1"+";"
	else
		OldNote+="AngularSector="+stringFromList(0,orientation,"_")+";"
		OldNote+="AngularHalfWidth="+stringFromList(1,orientation,"_")+";"
	endif
	if(DoPolarizationCorrection)
		if(Use1DPolarizationCor)
			OldNote+="PolarizationCorrection=1D;"
		else
			OldNote+="PolarizationCorrection=2D;"
			OldNote+="2DPolarizationCorrection0Angle="+num2str(StartAngle2DPolCor)+";"
		endif
	
	else
		OldNote+="PolarizationCorrection=None;"
	endif
	
	Duplicate/O QvectorA, Qvector, Intensity, Error, Qsmearing
	Duplicate/O TwoThetaA, TwoTheta
	Duplicate/O TwoThetaWidthA, TwoThetaWidth
	Duplicate/O DspacingA, Dspacing
	Duplicate/O DspacingWidthA, DspacingWidth
	Qsmearing = QvectorWidth
	Intensity=0
	Error=0
	variable i, j, counter, numbins, start1, end1
	Duplicate/O LUT, tempInt
	tempInt = Calibrated2DDataSet
	IndexSort LUT, tempInt
	//Duplicate/O tempInt, TempIntSqt
	MatrixOp/O TempIntSqt = tempInt* tempInt
	counter = HistogramWv[0]
	For(j=1;j<QvectorNumberPoints;j+=1)
		numbins = HistogramWv[j]
		if(numbins>0)
			Intensity[j] = sum(tempInt, pnt2x(tempInt,Counter), pnt2x(tempInt,Counter+numbins-1))	//this cointains sum Xi
			Error[j] = sum(TempIntSqt, pnt2x(tempInt,Counter), pnt2x(tempInt,Counter+numbins-1))	//this now contains sum Xi^2
		endif
		Counter+=numbins
	endfor
	MatrixOp/O TempSumXi=Intensity				//OK, now we have sumXi saved
	MatrixOp/O Intensity=Intensity/HistogramWv	//This is average intensity....
	//version 1.43 December 2009, changed uncertainity estimates. Three new methods now available. Old method which has weird formula, standard deviation and standard error fof mean ...
	NVAR ErrorCalculationsUseOld=root:Packages:Convert2Dto1D:ErrorCalculationsUseOld
	NVAR ErrorCalculationsUseStdDev=root:Packages:Convert2Dto1D:ErrorCalculationsUseStdDev
	NVAR ErrorCalculationsUseSEM=root:Packages:Convert2Dto1D:ErrorCalculationsUseSEM
	//change in the Configuration panel. 	
	if(ErrorCalculationsUseOld)	//this is teh old code... Hopefully I did not screw up. 
		Error=sqrt(abs(Error - (TempSumXi^2))/(HistogramWv - 1))	
		MatrixOp/O Error=Error/HistogramWv
	else //now new code. Need to calculate standard deviation anyway... 
		//variance �= (Error - (Intensity^2 / Histogram)) / (Histogram - 1)
		//st deviation = sqrt(variance)
		Error = sqrt(abs(Error - (TempSumXi^2 / HistogramWv)) / (HistogramWv - 1))
		if(ErrorCalculationsUseSEM)
			//error_mean=stdDev/sqrt(Histogram)			use Standard error of mean...
			Error = Error /sqrt(HistogramWv)
		endif
	endif
	//need to add comments to wave note...
	if(ErrorCalculationsUseOld)
		OldNote+="UncertainityCalculationMethod=OldNikaMethod;"
	elseif(ErrorCalculationsUseStdDev)
		OldNote+="UncertainityCalculationMethod=StandardDeviation;"
	elseif(ErrorCalculationsUseSEM)
		OldNote+="UncertainityCalculationMethod=StandardErrorOfMean;"
	endif
	
	//this fix is same for all - if there is only 1 point in the bin, simply use sqrt of intensity... Of course, this can be really wrong, since by now this is fully calibrated and hecne sqrt is useless... 
	//Error = (HistogramWv[p]>1)? Error[p] : sqrt(Intensity[p])
	Error = (HistogramWv[p]>1)? Error[p] : Intensity[p]/2
	
	note Intensity, OldNote
	note Error, OldNote
	killwaves/Z tempInt, TempIntSqt, temp2D, tempQ, NewQwave, TempSumXi
	//remove first point - it contaisn all the masked points set to Q=0...
	DeletePoints 0,1, intensity, error, Qvector, Qsmearing, TwoTheta, TwoThetaWidth, Dspacing, DspacingWidth
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//
//Function EGNA_SolidangleCorrection(qwave,rwave,pixelsize,SDD, lambda,DoGeometryCorrection, DoPolarizationCorrection) //from Dale Schaefer, needs to be checked what is it doing... 
//    		wave qwave,rwave
//        	variable pixelsize,SDD, lambda ,DoGeometryCorrection, DoPolarizationCorrection
//         
//	string oldDf=GetDataFOlder(1)
//	setDataFolder root:Packages:Convert2Dto1D
//
//    duplicate/o qwave, omega, SAP, HYP, theta 
//    theta=2*asin(qwave * Lambda /( 4 * pi) )		//theta here is really 2Theta, since it is angle between beam in and out... 
//    
////    if(DoGeometryCorrection)
//// 	   SAP=PixelSize*cos(theta)		//this is projection of pixel into the direction perpendicular to the center line from sample 
////					   // HYP=((PixelSize*(qwave))^2+SDD^2)^(1/2)//qout is still in pixels 
////	    HYP=SDD/cos(theta)			//this is distance from the sample
////					 //       qwave=(4*pi/wavelength)*(sin(theta/2)) 
////	    omega=(SAP/HYP) 			//this is angle under which we see the pixel from the sample
//// 	   variable startOmega=omega[0]
////	    omega /= startOmega				//and this is to scale it, so the correction for center pixel is 1
////	else
//		omega=1
////	endif
//    	duplicate/o theta, PF 
//    	if(DoPolarizationCorrection)			//comment 6/24/2006 - I think this is wrong... I need to find the right formula... 
//	    PF= (1+cos((theta))^2)/2			// polarization factor, see above, theta is really 2theta
//    	else
//		pf=1 
//      endif
////    rwave=rwave/(omega^2*PF)     		//Squared because it is solid angle and the above is done for lin angle 
////    rwave=rwave/(omega^1.5*PF)     		//Correction JI 5 26 2006
//    rwave=rwave/(PF)     		//Correction JI 5 26 2006
//    //why is it 1.5???? To match geometrical corrections by Fit2D
//    // Correct correction is Int/cos(theta)^3 - that is from NIST macros and agrees with Fit2D - the omega here is already ^2, thats why 1.5...
//    //I believe the right should be ^1, because, only 1 dimensions is actually distorted. ase example pixel on vertical axis. Only
//    //vertical dimension is shrunk, horizontal direction has not changed... But to match Fit2D exactly I need factor of 1.5...
//        
//    killwaves/z  SAP, HYP, omega, PF,theta 
//	setDataFolder OldDf
//end 
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_CorrectDataPerUserReq(orientation,wavelengths)
	string orientation
	string wavelengths

	string OldDf = GetDataFolder(1)
	setDataFolder root:Packages:Convert2Dto1D

	SVAR CalibrationFormula=root:Packages:Convert2Dto1D:CalibrationFormula
	NVAR UseSampleThickness= root:Packages:Convert2Dto1D:UseSampleThickness
	NVAR UseSampleTransmission= root:Packages:Convert2Dto1D:UseSampleTransmission
	NVAR UseCorrectionFactor= root:Packages:Convert2Dto1D:UseCorrectionFactor
	NVAR UseSolidAngle=root:Packages:Convert2Dto1D:UseSolidAngle
	NVAR UseMask= root:Packages:Convert2Dto1D:UseMask
	NVAR UseDarkField= root:Packages:Convert2Dto1D:UseDarkField
	NVAR UseEmptyField= root:Packages:Convert2Dto1D:UseEmptyField
	NVAR UseSubtractFixedOffset= root:Packages:Convert2Dto1D:UseSubtractFixedOffset
	NVAR UseSampleMeasTime= root:Packages:Convert2Dto1D:UseSampleMeasTime
	NVAR UseEmptyMeasTime= root:Packages:Convert2Dto1D:UseEmptyMeasTime
	NVAR UseDarkMeasTime= root:Packages:Convert2Dto1D:UseDarkMeasTime
	NVAR UsePixelSensitivity= root:Packages:Convert2Dto1D:UsePixelSensitivity
	NVAR UseI0ToCalibrate = root:Packages:Convert2Dto1D:UseI0ToCalibrate
	NVAR UseMonitorForEF = root:Packages:Convert2Dto1D:UseMonitorForEF
	
	NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
	NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance
	
	NVAR CorrectionFactor = root:Packages:Convert2Dto1D:CorrectionFactor
	NVAR SampleI0 = root:Packages:Convert2Dto1D:SampleI0
	NVAR EmptyI0 = root:Packages:Convert2Dto1D:EmptyI0
	NVAR SampleThickness = root:Packages:Convert2Dto1D:SampleThickness
	NVAR SampleTransmission = root:Packages:Convert2Dto1D:SampleTransmission
	NVAR SampleMeasurementTime = root:Packages:Convert2Dto1D:SampleMeasurementTime
	NVAR BackgroundMeasTime = root:Packages:Convert2Dto1D:BackgroundMeasTime
	NVAR EmptyMeasurementTime = root:Packages:Convert2Dto1D:EmptyMeasurementTime
	NVAR SubtractFixedOffset = root:Packages:Convert2Dto1D:SubtractFixedOffset
	
	NVAR DoGeometryCorrection=root:Packages:Convert2Dto1D:DoGeometryCorrection

	NVAR Use2DPolarizationCor = root:Packages:Convert2Dto1D:Use2DPolarizationCor
	NVAR DoPolarizationCorrection = root:Packages:Convert2Dto1D:DoPolarizationCorrection
	//Collins added 7/8/13
	If( Exists("root:Packages:Convert2Dto1D:DoSolidAngleMap")!=2 )  //doesn't exist yet, make it & set to zero
		Variable/G root:Packages:Convert2Dto1D:DoSolidAngleMap=0
	endif
	NVAR DoSolidAngleMap = root:Packages:Convert2Dto1D:DoSolidAngleMap
	//end Collins
	
	Wave DataWave=root:Packages:Convert2Dto1D:CCDImageToConvert
	Wave/Z EmptyRunWave=root:Packages:Convert2Dto1D:EmptyData
	Wave/Z DarkCurrentWave=root:Packages:Convert2Dto1D:DarkFieldData
	Wave/Z MaskWave=root:Packages:Convert2Dto1D:M_ROIMask
	Wave/Z Pix2DSensitivity=root:Packages:Convert2Dto1D:Pixel2DSensitivity
	//little checking here...
	if(UseMask)
		if(!WaveExists(MaskWave) || DimSize(MaskWave, 0)!=DimSize(DataWave, 0) || DimSize(MaskWave, 1)!=DimSize(DataWave, 1))
			abort "Mask problem - either does not exist or has differnet dimensions that data "
		endif
	endif
	if(UseDarkField)
		if(!WaveExists(DarkCurrentWave) || DimSize(DarkCurrentWave, 0)!=DimSize(DataWave, 0) || DimSize(DarkCurrentWave, 1)!=DimSize(DataWave, 1))
			abort "Dark field problem - either does not exist or has differnet dimensions that data "
		endif
	endif
	if(UseEmptyField)
		if(!WaveExists(EmptyRunWave) || DimSize(EmptyRunWave, 0)!=DimSize(DataWave, 0) || DimSize(EmptyRunWave, 1)!=DimSize(DataWave, 1))
			abort "Empty data problem - either does not exist or has differnet dimensions that data "
		endif
	endif
	if(UsePixelSensitivity)
		if(!WaveExists(Pix2DSensitivity) || DimSize(Pix2DSensitivity, 0)!=DimSize(DataWave, 0) || DimSize(Pix2DSensitivity, 1)!=DimSize(DataWave, 1))
			abort "Pix2D Sensitivity problem - either does not exist or has differnet dimensions that data "
		endif
	endif

	Duplicate/O DataWave,  Calibrated2DDataSet
	
	Wave Calibrated2DDataSet=root:Packages:Convert2Dto1D:Calibrated2DDataSet
	redimension/S Calibrated2DDataSet
	string OldNote=note(Calibrated2DDataSet)

	variable tempVal
	variable CalibrationPrefactor=1
	
	if(UseCorrectionFactor)
		CalibrationPrefactor*=CorrectionFactor // converts ADUs (pixel values) into photons
	endif
	if(UseI0ToCalibrate)
		CalibrationPrefactor/=SampleI0 // should be total number of photons incident on the sample
		// at this point each pixel should be scattered photons / total incident photons (this is dsigma)
	endif
	if(UseSampleThickness)
		CalibrationPrefactor/=SampleThickness
	endif

	Duplicate/O DataWave, tempDataWv, tempEmptyField
	redimension/S tempDataWv, tempEmptyField
	
	if(UseSolidAngle && !DoSolidAngleMap) // Eliot and Brian have added the correct correction under DoSolidAngleMap below // this is domega
		variable solidAngle =PixelSizeX/SampleToCCDDistance * PixelSizeY/SampleToCCDDistance
		//well, this is approximate, but should be just fine... my testing shows, that for 30mm far pixel with 0.3mm size the difference is less than 4e-4... Who cares?
		CalibrationPrefactor/=solidAngle
		// Eliot and Brian added in Correct Pixel size calculation
		//NVAR BCx=BeamCenterX, BCy=BeamCenterY, Dist=SampleToCCDdistance, pSizeX=pixelSizeX, pSizeY=PixelSizeY,Htilt=HorizontalTilt, Vtilt=VerticalTilt
		//duplicate /o tempDataWv, areamap
		//multithread areaMap= cos( atan( (p-BCx)*pSizeX/Dist) + Htilt*pi/180 ) * cos( atan( (q-BCy)*pSizeY/Dist) + Vtilt*pi/180 ) / (pSizeX/Dist * pSizeY/Dist)
		//matrixop /o tempDataWv = tempDataWv/areamap
	endif
	if(UsePixelSensitivity)
		MatrixOP/O tempDataWv=tempDataWv/Pix2DSensitivity
	endif
	if(UseSampleTransmission)
		MatrixOP/O tempDataWv=tempDataWv/SampleTransmission
	endif
	if(UseDarkField)
		//figure out if there is a darkimage with the same exposure time ELIOT
		wave/z testdarkimage = $("root:Packages:Convert2Dto1D:DarkFieldData_"+replacestring(".",num2str(SampleMeasurementTime),"p"))
		if(waveexists(testdarkimage))
			wave DarkCurrentWave = $("root:Packages:Convert2Dto1D:DarkFieldData_"+replacestring(".",num2str(SampleMeasurementTime),"p"))
			print "Using the dark image for " +num2str(SampleMeasurementTime) + " second exposure"
		else
			print "Using the dafault dark image"
		endif
		//END ELIOT
		if(UseSampleMeasTime && UseDarkMeasTime)
			if(UsePixelSensitivity)
				tempVal = SampleMeasurementTime/BackgroundMeasTime
				MatrixOP/O tempDataWv = tempDataWv - (tempVal*DarkCurrentWave/Pix2DSensitivity)
			else

				tempVal = SampleMeasurementTime/BackgroundMeasTime
				
				MatrixOP/O tempDataWv = tempDataWv - (tempVal*DarkCurrentWave)
			endif
		else
			if(UsePixelSensitivity)
				MatrixOP/O tempDataWv = tempDataWv - (DarkCurrentWave/Pix2DSensitivity)
			else
				MatrixOP/O tempDataWv = tempDataWv - DarkCurrentWave
			endif
		endif
//		if(UseSampleMeasTime && UseDarkMeasTime)
//			tempVal = SampleMeasurementTime/BackgroundMeasTime
//			if(UsePixelSensitivity)
//				if(UseSolidAngle)
//					MatrixOP /O tempDataWv = tempDataWv - (tempVal*DarkCurrentWave/(Pix2DSensitivity*areamap))
//				else
//					MatrixOP/O tempDataWv = tempDataWv - (tempVal*DarkCurrentWave/Pix2DSensitivity)
//				endif
//			else
//				if(UseSolidAngle)
//					MatrixOP /O tempDataWv = tempDataWv - (tempVal*DarkCurrentWave/areamap)
//				else
//					MatrixOP/O tempDataWv = tempDataWv - (tempVal*DarkCurrentWave)
//				endif
//			endif
//		else
//			if(UsePixelSensitivity)
//				if(UseSolidAngle)
//					matrixop /o tempDataWv = tempDataWv - (DarkCurrentWave/(Pix2DSensitivity*areamap))
//				else
//					MatrixOP/O tempDataWv = tempDataWv - (DarkCurrentWave/Pix2DSensitivity)
//				endif
//			else
//				if(UseSolidAngle)
//					matrixop /o tempDataWv = tempDataWv - (DarkCurrentWave/areamap))
//				else
//					MatrixOP/O tempDataWv = tempDataWv - DarkCurrentWave
//				endif
//			endif
//		endif
		
	endif
	if(UseSubtractFixedOffset)
		MatrixOP/O tempDataWv = tempDataWv - SubtractFixedOffset
	endif
	
	tempEmptyField=0
	variable ScalingConstEF=1

	if(UseEmptyField)
		tempEmptyField = EmptyRunWave
		if(UsePixelSensitivity)
			MatrixOP/O tempEmptyField = tempEmptyField/Pix2DSensitivity
		endif
		if(UseSubtractFixedOffset)
			MatrixOP/O tempEmptyField = tempEmptyField - SubtractFixedOffset
		endif
	
		if(UseMonitorForEF)
			ScalingConstEF=SampleI0/EmptyI0
		elseif(UseEmptyMeasTime && UseSampleMeasTime)
			ScalingConstEF=SampleMeasurementTime/EmptyMeasurementTime
		endif

		if(UseDarkField)
			if(UseSampleMeasTime && UseEmptyMeasTime)
				if(UsePixelSensitivity)
					tempVal = EmptyMeasurementTime/BackgroundMeasTime
					MatrixOP/O tempEmptyField=tempEmptyField - (tempVal*(DarkCurrentWave/Pix2DSensitivity))
				else
					tempVal = EmptyMeasurementTime/BackgroundMeasTime
					MatrixOP/O tempEmptyField=tempEmptyField - (tempVal*DarkCurrentWave)
				endif
			else
				if(UsePixelSensitivity)
					MatrixOP/O tempEmptyField=tempEmptyField - (DarkCurrentWave/Pix2DSensitivity)
				else
					MatrixOP/O tempEmptyField=tempEmptyField - DarkCurrentWave
				endif
			endif
		endif

	endif

	MatrixOP/O Calibrated2DDataSet = CalibrationPrefactor * (tempDataWv - ScalingConstEF * tempEmptyField)
	
	if(DoGeometryCorrection)  		//geometry correction (= cos(angle)^3) for solid angle projection, added 6/24/2006 to do in 2D data, not in 1D as done (incorrectly also) before using Dales routine.
		EGNA_GenerateGeometryCorr2DWave()
		Wave GeometryCorrection
		MatrixOp/O Calibrated2DDataSet = Calibrated2DDataSet / GeometryCorrection
	endif
	if(DoPolarizationCorrection)		//added 8/31/09 to enable 2D corection for polarization
		EGNA_Generate2DPolCorrWv()
		Wave polar2DWave
		MatrixOp/O Calibrated2DDataSet = Calibrated2DDataSet / polar2DWave 		//changed to "/" on October 12 2009 since due to use MatrixOp in new formula the calculate values are less than 1 and this is now correct. 
	endif
	
	//Collins Added
	IF( DoSolidAngleMap ) // divide by domega (so if the rest is done correctly, the result should be dsigma/domega in each pixel)  and if we integrate over all pixels there should be a maximum value of 1
		SolidAngleMap()
		Wave AreaMap
		MatrixOP/O Calibrated2DDataSet = Calibrated2DDataSet / AreaMap
	endif
	//End collins
	
	note /K Calibrated2DDataSet
	OldNote+= "CalibrationFormula="+CalibrationFormula+";"
	if(UseSampleThickness)
		OldNote+= "SampleThickness="+num2str(SampleThickness)+";"
	endif
	if(UseSampleTransmission)
		OldNote+= "SampleTransmission="+num2str(SampleTransmission)+";"
	endif
	if(UseCorrectionFactor)
		OldNote+= "CorrectionFactor="+num2str(CorrectionFactor)+";"
	endif
	if(UseSubtractFixedOffset)
		OldNote+= "SubtractFixedOffset="+num2str(SubtractFixedOffset)+";"
	endif
	if(UseSampleMeasTime)
		OldNote+= "SampleMeasurementTime="+num2str(SampleMeasurementTime)+";"
	endif
	if(UseEmptyMeasTime)
		OldNote+= "EmptyMeasurementTime="+num2str(EmptyMeasurementTime)+";"
	endif
	if(UseI0ToCalibrate)
		OldNote+= "SampleI0="+num2str(SampleI0)+";"
		OldNote+= "EmptyI0="+num2str(EmptyI0)+";"
	endif
	if(UseDarkMeasTime)
		OldNote+= "BackgroundMeasTime="+num2str(BackgroundMeasTime)+";"
	endif
	if(UsePixelSensitivity)
		OldNote+= "UsedPixelsSensitivity="+num2str(UsePixelSensitivity)+";"
	endif
	if(UseMonitorForEF)
		OldNote+= "UseMonitorForEF="+num2str(UseMonitorForEF)+";"
	endif

	SVAR CurrentDarkFieldName=root:Packages:Convert2Dto1D:CurrentDarkFieldName
	SVAR CurrentEmptyName=root:Packages:Convert2Dto1D:CurrentEmptyName	
	SVAR CurrentMaskFileName=root:Packages:Convert2Dto1D:CurrentMaskFileName
	if(UseMask)
		OldNote+= "CurrentMaskFileName="+(CurrentMaskFileName)+";"
	endif
	if(UseDarkField)
		OldNote+= "CurrentDarkFieldName="+(CurrentDarkFieldName)+";"
	endif
	if(UseEmptyField)
		OldNote+= "CurrentEmptyName="+(CurrentEmptyName)+";"
	endif

	note Calibrated2DDataSet, OldNote
	KillWaves tempEmptyField, tempDataWv
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_Generate2DPolCorrWv()
	
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	//create Polarization correction
	Wave/Z AnglesWave=root:Packages:Convert2Dto1D:AnglesWave
	if(WaveExists(AnglesWave)==0)
		Wave DataWave=root:Packages:Convert2Dto1D:CCDImageToConvert
		EGNA_Create2DAngleWave(DataWave)	
		Wave AnglesWave=root:Packages:Convert2Dto1D:AnglesWave
	endif
	Wave/Z Theta2DWave = root:Packages:Convert2Dto1D:Theta2DWave
	if(!WaveExists(Theta2DWave))
		Wave DataWave=root:Packages:Convert2Dto1D:CCDImageToConvert
		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		if(UseGrazingIncidence)
			GI_ReHistImage()
		else
			EGNA_Create2DQWave(DataWave)
		endif
	endif
	
	Wave/Z polar2DWave=root:Packages:Convert2Dto1D:polar2DWave

	NVAR Use1DPolarizationCor =root:Packages:Convert2Dto1D:Use1DPolarizationCor
	NVAR Use2DPolarizationCor =root:Packages:Convert2Dto1D:Use2DPolarizationCor

	NVAR StartAngle2DPolCor =root:Packages:Convert2Dto1D:StartAngle2DPolCor
	string OldNOte=""
	if(WaveExists(polar2DWave))
		OldNOte=note(polar2DWave)
	endif
	variable NeedToUpdate=0
	
	string ParamsToCheck="SampleToCCDDistance;Wavelength;PixelSizeX;PixelSizeY;beamCenterX;beamCenterY;StartAngle2DPolCor;HorizontalTilt;VerticalTilt;TwoDPolarizFract;Use1DPolarizationCor;"
	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance		//in millimeters
	NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength							//in A
	NVAR PixelSizeX = root:Packages:Convert2Dto1D:PixelSizeX								//in millimeters
	NVAR PixelSizeY = root:Packages:Convert2Dto1D:PixelSizeY								//in millimeters
	NVAR beamCenterX=root:Packages:Convert2Dto1D:beamCenterX
	//NVAR beamCenterY=root:Packages:Convert2Dto1D:beamCenterY
	
	
		NVAR beamycenter=root:Packages:Convert2Dto1D:BeamCenterY
		nvar effectiveycenter = root:Packages:Convert2Dto1D:effBCY
		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		variable BeamCenterY
		if(nvar_exists(effectiveycenter) && UseGrazingIncidence)
			BeamCenterY = effectiveycenter
		else
			BeamCenterY = beamycenter
		endif
		
	
	NVAR reflbeam=root:Packages:Convert2Dto1D:reflbeam
	NVAR TwoDPolarizFract=root:Packages:Convert2Dto1D:TwoDPolarizFract
//	if(Use1DPolarizationCor)
//		TwoDPolarizFract=0
//	endif

	NVAR HorizontalTilt=root:Packages:Convert2Dto1D:HorizontalTilt							//tilt in degrees
	NVAR VerticalTilt=root:Packages:Convert2Dto1D:VerticalTilt								//tilt in degrees
	variable i
	string TempStr
	For(i=0;i<itemsInList(ParamsToCheck);i+=1)
		TempStr=StringFromList(i, ParamsToCheck)
		NVAR TempVar=$("root:Packages:Convert2Dto1D:"+TempStr)
		if(!stringMatch(num2str(TempVar),StringByKey(TempStr,OldNote,"=",";")))
			NeedToUpdate=1
		endif
	endfor

	if(NeedToUpdate)
		print "Updated Polarization correction 2D wave" 
		variable OffsetInRadians=StartAngle2DPolCor *pi/180
		MatrixOp/O A2Theta2DWave =  2 * Theta2DWave
		if(Use1DPolarizationCor)
			//	Int=Int/( (1+cos((2theta))^2)/2	)
		    	MatrixOP/O polar2DWave = (1+cos(A2Theta2DWave))/2
		else			//at least partially polarized radiation
			if(abs(StartAngle2DPolCor)<1)
			     	MatrixOP/O polar2DWave = (TwoDPolarizFract*(powR(cos(A2Theta2DWave),2) * powR(cos(AnglesWave),2)+powR(sin(AnglesWave),2)) +(1-TwoDPolarizFract)*(powR(cos(A2Theta2DWave),2)*powR(sin(AnglesWave),2)+powR(cos(AnglesWave),2)))
			//note, matrixOp cannot do 1/ therefore changed to use 1/ in calling function....
			else
				Duplicate/O AnglesWave, TempAnglesWave
				//NVAR beamCenterX=root:Packages:Convert2Dto1D:beamCenterX
				//NVAR beamCenterY=root:Packages:Convert2Dto1D:beamCenterY
				//Now angle from 0 degrees, so we can do sectors if necessary
				TempAnglesWave = abs(atan2((BeamCenterY-q),(BeamCenterX-p))-pi+OffsetInRadians)			
			       MatrixOP/O polar2DWave = (TwoDPolarizFract*(powR(cos(A2Theta2DWave),2) * powR(cos(TempAnglesWave),2)+powR(sin(TempAnglesWave),2)) +(1-TwoDPolarizFract)*(powR(cos(A2Theta2DWave),2)*powR(sin(TempAnglesWave),2)+powR(cos(TempAnglesWave),2)))
				KillWaves TempAnglesWave
			endif
		endif
		KillWaves A2Theta2DWave
		
		// 2D polarization correction is created. 
		string NewNote=""
	For(i=0;i<itemsInList(ParamsToCheck);i+=1)
		TempStr=StringFromList(i, ParamsToCheck)
		NVAR TempVar=$("root:Packages:Convert2Dto1D:"+TempStr)
		NewNote+=TempStr+"="+num2str(TempVar)+";"
	endfor
	note/K polar2DWave
	note polar2DWave, NewNote
	endif
	setDataFolder OldDf

end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function  EGNA_GenerateGeometryCorr2DWave()
	
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	
	Wave/Z GeometryCorrection = root:Packages:Convert2Dto1D:GeometryCorrection
//	EGNA_CheckGeometryWaves("C")
//	Wave PixRadius2DWave = root:Packages:Convert2Dto1D:PixRadius2DWave
	Wave/Z Q2DWave = root:Packages:Convert2Dto1D:Q2DWave
	if(!WaveExists(Q2DWave))
		Wave DataWave=root:Packages:Convert2Dto1D:CCDImageToConvert
		NVAR UseGrazingIncidence = root:Packages:Convert2Dto1D:UseGrazingIncidence
		if(UseGrazingIncidence)
			GI_ReHistImage()
		else
			EGNA_Create2DQWave(DataWave)
		endif
		//EGNA_Create2DQWave(DataWave)			//creates 2-D Q wave 
		wave Q2DWave = root:Packages:Convert2Dto1D:Q2DWave
	endif

	NVAR SampleToCCDDistance = root:Packages:Convert2Dto1D:SampleToCCDDistance
	NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength
	string O2N = note(Q2DWave)

	if(WaveExists(GeometryCorrection))
		string OGN= note(GeometryCorrection)
		//BeamCenterX=501.19;BeamCenterY=506.05;PixelSizeX=0.1;  PixelSizeY=0.1;HorizontalTilt=0;VerticalTilt=0;SampleToCCDDistance=250.5;Wavelength=1.541;
		variable Match1=0, Match2=0, Match3=0, Match4
		if(NumberByKey("BeamCenterX",OGN,"=",";")==NumberByKey("BeamCenterX",O2N,"=",";") && NumberByKey("BeamCenterY",OGN,"=+",";")==NumberByKey("BeamCenterY",O2N,"=",";") )
			Match1=1
		endif
		if(NumberByKey("PixelSizeX",OGN,"=",";")==NumberByKey("PixelSizeX",O2N,"=",";") && NumberByKey("PixelSizeY",OGN,"=",";")==NumberByKey("PixelSizeY",O2N,"=",";") )
			Match2=1
		endif
		if(NumberByKey("HorizontalTilt",OGN,"=",";")==NumberByKey("HorizontalTilt",O2N,"=",";") && NumberByKey("VerticalTilt",OGN,"=",";")==NumberByKey("VerticalTilt",O2N,"=",";") )
			Match3=1
		endif
		if(NumberByKey("SampleToCCDDistance",OGN,"=",";")==NumberByKey("SampleToCCDDistance",O2N,"=",";") && NumberByKey("Wavelength",OGN,"=",";")==NumberByKey("Wavelength",O2N,"=",";") )
			Match4=1
		endif
		if(Match1 && match2 && Match3 && Match4)
			return 1
		endif
	endif
	variable Ltemp = Wavelength / (4 * pi)
//    theta=2*asin(qwave * Lambda /( 4 * pi) )		//theta here is really 2Theta, since it is angle between beam in and out... 
	MatrixOp/O GeometryCorrection =  2 * asin(Q2DWave * Ltemp))
	MatrixOp/O GeometryCorrection = powR(cos(GeometryCorrection),3)
	Wave GeometryCorrection
	Redimension/S GeometryCorrection
	
	Note GeometryCorrection, O2N
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_CheckGeometryWaves(orientation,wavelengths)		//checks if current geometry waves are OK for the input geometry
	string orientation
	string wavelengths

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	Wave DataWave=root:Packages:Convert2Dto1D:CCDImageToConvert
	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance		//in millimeters
	NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength							//in A
	NVAR PixelSizeX = root:Packages:Convert2Dto1D:PixelSizeX								//in millimeters
	NVAR PixelSizeY = root:Packages:Convert2Dto1D:PixelSizeY								//in millimeters
	NVAR beamCenterX=root:Packages:Convert2Dto1D:beamCenterX
	NVAR beamCenterY=root:Packages:Convert2Dto1D:beamCenterY
	SVAR CurrentMaskFileName=root:Packages:Convert2Dto1D:CurrentMaskFileName
	NVAR UseMask=root:Packages:Convert2Dto1D:UseMask
	NVAR HorizontalTilt=root:Packages:Convert2Dto1D:HorizontalTilt
	NVAR VerticalTilt=root:Packages:Convert2Dto1D:VerticalTilt
	NVAR UserThetaMin=root:Packages:Convert2Dto1D:UserThetaMin
	NVAR UserThetaMax=root:Packages:Convert2Dto1D:UserThetaMax
	NVAR UserDMin=root:Packages:Convert2Dto1D:UserDMin
	NVAR UserDMax=root:Packages:Convert2Dto1D:UserDMax
	NVAR UserQMin=root:Packages:Convert2Dto1D:UserQMin
	NVAR UserQMax=root:Packages:Convert2Dto1D:UserQMax
	
//	wave/Z Radius2DWave=root:Packages:Convert2Dto1D:Radius2DWave
	wave/Z Q2DWave=root:Packages:Convert2Dto1D:Q2DWave
	wave/Z Rdistribution1D=$("root:Packages:Convert2Dto1D:Rdistribution1D_"+orientation+"_"+wavelengths)
	wave/Z AnglesWave=root:Packages:Convert2Dto1D:AnglesWave
	wave/Z LUT=$("root:Packages:Convert2Dto1D:LUT_"+orientation+"_"+wavelengths)
	wave/Z Qdistribution1D=$("root:Packages:Convert2Dto1D:Qdistribution1D_"+orientation+"_"+wavelengths)
	wave/Z HistogramWv=$("root:Packages:Convert2Dto1D:HistogramWv_"+orientation+"_"+wavelengths)
	wave/Z Qvector=$("root:Packages:Convert2Dto1D:Qvector_"+orientation+"_"+wavelengths)
	////eliot note? move q vectors from save
	//Check that the waves exist at all...
	
	
	
	// TODO:  2022 correction - if only wavelength changed, just scale the vectors
	// if the exact wavelength doesn't exist, load the orientation ONLY wave, and scale it to the new wavelength
	
	
	
	
	
	if (!WaveExists(Qvector) || !WaveExists(HistogramWv) || !WaveExists(LUT))
		EGNA_Create2DQWave(DataWave)			//creates 2-D Q wave does not need to be run always... //eliot changing June 2015
		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		if(UseGrazingIncidence)
			GI_ReHistImage()
		else
			EGNA_Create2DQWave(DataWave)
		endif
		EGNA_Create2DAngleWave(DataWave)			//creates 2-D Azimuth Angle wave does not need to be run always...
		EGNA_CreateLUT(orientation,wavelengths)					//creates 1D LUT, should not be run always....
		//EGNA_CreateQvector(orientation)				//creates 2-D Q wave does not need to be run always... //eliot changing June 2015
		EGNA_CreateHistogram(orientation,wavelengths)				//creates 2-D Q wave does not need to be run always...
		wave KillQ2D = $("root:Packages:Convert2Dto1D:Qdistribution1D_"+orientation+"_"+wavelengths)
		KillWaves/Z KillQ2D
		return 1
	endif
	////eliot note? COpy LUT and q vectors as appropriate to saved locations
	variable yesno=0
	//First, 2DQwave may be wrong... 
	string NoteStr=note(Q2DWave)
	string oldSampleToCCDDistance = stringByKey("SampleToCCDDistance", NoteStr , "=")
	string oldBeamCenterX = stringByKey("BeamCenterX", NoteStr , "=")
	string oldBeamCenterY = stringByKey("BeamCenterY", NoteStr , "=")
	string oldPixelSizeX = stringByKey("PixelSizeX", NoteStr , "=")
	string oldPixelSizeY = stringByKey("PixelSizeY", NoteStr , "=")
	string oldHorizontalTilt = stringByKey("HorizontalTilt", NoteStr , "=")
	string oldVerticalTilt = stringByKey("VerticalTilt", NoteStr , "=")
	string oldWavelength = stringByKey("Wavelength", NoteStr , "=")
//	variable diff6=cmpstr(oldSampleToCCDDistance,num2str(SampleToCCDDistance))!=0 ||cmpstr(oldWavelength,num2str(Wavelength))!=0 || cmpstr(oldBeamCenterX,num2str(BeamCenterX))!=0 || cmpstr(oldBeamCenterY,num2str(BeamCenterY))!=0
//	variable diff7 = cmpstr(oldPixelSizeX,num2str(PixelSizeX))!=0 || cmpstr(oldPixelSizeY,num2str(PixelSizeY))!=0  || cmpstr(oldHorizontalTilt,num2str(HorizontalTilt))!=0  || cmpstr(oldVerticalTilt,num2str(VerticalTilt))!=0
	variable diff6=cmpstr(oldSampleToCCDDistance,num2str(SampleToCCDDistance))!=0 || cmpstr(oldBeamCenterX,num2str(BeamCenterX))!=0 || cmpstr(oldBeamCenterY,num2str(BeamCenterY))!=0
	variable diff7 = cmpstr(oldPixelSizeX,num2str(PixelSizeX))!=0 || cmpstr(oldPixelSizeY,num2str(PixelSizeY))!=0  || cmpstr(oldHorizontalTilt,num2str(HorizontalTilt))!=0  || cmpstr(oldVerticalTilt,num2str(VerticalTilt))!=0
	if(diff6 || diff7)
		
		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		if(UseGrazingIncidence)
			GI_ReHistImage()
		else
			EGNA_Create2DQWave(DataWave)
		endif
		//EGNA_Create2DQWave(DataWave)			//creates 2-D Q wave does not need to be run always...
		yesno=1
	endif

	//First, AnglesWave may be wrong... 
	NoteStr=note(AnglesWave)
	oldBeamCenterX = stringByKey("BeamCenterX", NoteStr , "=")
	oldBeamCenterY = stringByKey("BeamCenterY", NoteStr , "=")
	if(cmpstr(oldBeamCenterX,num2str(BeamCenterX))!=0 || cmpstr(oldBeamCenterY,num2str(BeamCenterY))!=0)
		EGNA_Create2DAngleWave(DataWave)			//creates 2-D Q wave does not need to be run always...
		yesno=1
	endif
	
	NoteStr=note(LUT)
	oldBeamCenterX = stringByKey("BeamCenterX", NoteStr , "=")
	oldSampleToCCDDistance = stringByKey("SampleToCCDDistance", NoteStr , "=")
	oldWavelength = stringByKey("Wavelength", NoteStr , "=")
	oldBeamCenterY = stringByKey("BeamCenterY", NoteStr , "=")
	oldPixelSizeX = stringByKey("PixelSizeX", NoteStr , "=")
	oldPixelSizeY = stringByKey("PixelSizeY", NoteStr , "=")
	oldHorizontalTilt = stringByKey("HorizontalTilt", NoteStr , "=")
	oldVerticalTilt = stringByKey("VerticalTilt", NoteStr , "=")
	variable oldUseMask=NumberByKey("UseMask", NoteStr , "=")
	string OldMaskName=stringByKey("CurrentMaskFileName", NoteStr , "=") 
	//eliot note?  compare multible wavelengths and copy appropriate lut for c, histogram, and q wave in 
//	diff6=cmpstr(oldSampleToCCDDistance,num2str(SampleToCCDDistance))!=0 ||cmpstr(oldWavelength,num2str(Wavelength))!=0 || cmpstr(oldBeamCenterX,num2str(BeamCenterX))!=0 || cmpstr(oldBeamCenterY,num2str(BeamCenterY))!=0
	diff6=cmpstr(oldSampleToCCDDistance,num2str(SampleToCCDDistance))!=0 || cmpstr(oldBeamCenterX,num2str(BeamCenterX))!=0 || cmpstr(oldBeamCenterY,num2str(BeamCenterY))!=0

	if(diff6 || cmpstr(OldMaskName,CurrentMaskFileName)!=0 || UseMask!=oldUseMask || cmpstr(oldPixelSizeX,num2str(PixelSizeX))!=0 || cmpstr(oldPixelSizeY,num2str(PixelSizeY))!=0  || cmpstr(oldHorizontalTilt,num2str(HorizontalTilt))!=0  || cmpstr(oldVerticalTilt,num2str(VerticalTilt))!=0)
//		EGNA_Create2DQWave(DataWave)			//creates 2-D Q wave does not need to be run always...
//		EGNA_Create2DAngleWave(DataWave)			//creates 2-D Azimuth Angle wave does not need to be run always...
		EGNA_CreateLUT(orientation,wavelengths)					//creates 1D LUT, should not be run always....
		yesno=1
	endif
	wave LUT=$("root:Packages:Convert2Dto1D:LUT_"+orientation+"_"+wavelengths)
	
	NoteStr=note(HistogramWv)
	oldSampleToCCDDistance = stringByKey("SampleToCCDDistance", NoteStr , "=")
	oldBeamCenterX = stringByKey("BeamCenterX", NoteStr , "=")
	oldBeamCenterY = stringByKey("BeamCenterY", NoteStr , "=")
	oldPixelSizeX = stringByKey("PixelSizeX", NoteStr , "=")
	oldPixelSizeY = stringByKey("PixelSizeY", NoteStr , "=")
	oldHorizontalTilt = stringByKey("HorizontalTilt", NoteStr , "=")
	oldVerticalTilt = stringByKey("VerticalTilt", NoteStr , "=")
	oldWavelength = stringByKey("Wavelength", NoteStr , "=")
	variable oldQBL = NumberByKey("QbinningLogarithmic", NoteStr , "=")
	variable oldQVNP = NumberByKey("QvectorNumberPoints", NoteStr , "=")
	oldUseMask=NumberByKey("UseMask", NoteStr , "=")
	OldMaskName=stringByKey("CurrentMaskFileName", NoteStr , "=") 
	NVAR QBL=root:Packages:Convert2Dto1D:QbinningLogarithmic
	NVAR QVNP=root:Packages:Convert2Dto1D:QvectorNumberPoints
	
	string oldUserThetaMin=stringByKey("UserThetaMin", NoteStr , "=")
	string oldUserThetaMax=stringByKey("UserThetaMax", NoteStr , "=")
	string oldUserDMin=stringByKey("UserDMin", NoteStr , "=")
	string oldUserDMax=stringByKey("UserDMax", NoteStr , "=")
	string oldUserQMin=stringByKey("UserQMin", NoteStr , "=")
	string oldUserQMax=stringByKey("UserQMax", NoteStr , "=")
	variable diff5=(cmpstr(oldUserThetaMin,num2str(UserThetaMin))!=0 || cmpstr(oldUserThetaMax,num2str(UserThetaMax))!=0 || cmpstr(oldUserDMin,num2str(UserDMin))!=0 || cmpstr(oldUserDMax,num2str(UserDMax))!=0 || cmpstr(oldUserQMin,num2str(UserQMin))!=0 || cmpstr(oldUserQMax,num2str(UserQMax))!=0)
	variable diff1=(yesno || oldQBL!=QBL || oldQVNP!=QVNP || cmpstr(oldSampleToCCDDistance,num2str(SampleToCCDDistance))!=0 || cmpstr(oldBeamCenterX,num2str(BeamCenterX))!=0)
	variable diff2=(cmpstr(oldBeamCenterY,num2str(BeamCenterY))!=0 || cmpstr(oldPixelSizeX,num2str(PixelSizeX))!=0 || cmpstr(oldPixelSizeY,num2str(PixelSizeY))!=0  || cmpstr(oldHorizontalTilt,num2str(HorizontalTilt))!=0  || cmpstr(oldVerticalTilt,num2str(VerticalTilt))!=0 )
//	variable diff3 = abs(str2num(oldWavelength)-Wavelength)>0.001*Wavelength // Eliot took out wavelength check
	variable diff4 =(cmpstr(OldMaskName,CurrentMaskFileName)!=0 || UseMask!=oldUseMask)
	if( diff1 || diff2  || diff4 || diff5)		//Ok, need to run these
//		if(!yesno)				//have not yet run the first three above...
//			EGNA_Create2DQWave(DataWave)			//creates 2-D Q wave does not need to be run always...
//			EGNA_Create2DAngleWave(DataWave)			//creates 2-D Azimuth Angle wave does not need to be run always...
//			EGNA_CreateLUT(orientation)					//creates 1D LUT, should not be run always....
//		endif		//the ones below must be run always...
	//	EGNA_CreateQvector(orientation)				//creates 2-D Q wave does not need to be run always...
		wave/Z Qdistribution1D=$("root:Packages:Convert2Dto1D:Qdistribution1D_"+orientation+"_"+wavelengths)
		
		
		//Eliot note? this is where to add in the memory of different LUT for C orientations, maybe??
		if(!WaveExists(Qdistribution1D))
			EGNA_CreateLUT(orientation,wavelengths)					//creates 1D LUT, should not be run always.... Will create Qdistribution 1D vector...
		endif
		EGNA_CreateHistogram(orientation,wavelengths)				//creates 2-D Q wave does not need to be run always...
		yesno=1
	endif
	wave HistogramWv=$("root:Packages:Convert2Dto1D:HistogramWv_"+orientation+"_"+wavelengths)
//	wave Qvector=$("root:Packages:Convert2Dto1D:Qvector_"+orientation)
	
	wave/Z KillQ2D = $("root:Packages:Convert2Dto1D:Qdistribution1D_"+orientation+"_"+wavelengths)
	wave/Z KillR2D = $("root:Packages:Convert2Dto1D:Rdistribution1D_"+orientation+"_"+wavelengths)
	KillWaves/Z KillQ2D, KillRQ2D
	setDataFolder OldDf
	return YesNo
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_CreateHistogram(orientation,wavelengths)
	string orientation
	string wavelengths

	print "Creating histogram"
	
	string OldDf=GetDataFolder(1)
	setDataFolder root:Packages:Convert2Dto1D
	wave Qdistribution1D=$("root:Packages:Convert2Dto1D:Qdistribution1D_"+orientation+"_"+wavelengths)
	wave LUT=$("root:Packages:Convert2Dto1D:LUT_"+orientation+"_"+wavelengths)
	
	Make/O $("HistogramWv_"+orientation+"_"+wavelengths)
	Wave HistogramWv=$("HistogramWv_"+orientation+"_"+wavelengths)
	redimension/S HistogramWv
	NVAR QbinningLogarithmic=root:Packages:Convert2Dto1D:QbinningLogarithmic
	NVAR QvectorNumberPoints=root:Packages:Convert2Dto1D:QvectorNumberPoints
	
	NVAR UseQvector=root:Packages:Convert2Dto1D:UseQvector
	NVAR UseTheta=root:Packages:Convert2Dto1D:UseTheta
	NVAR UseDspacing=root:Packages:Convert2Dto1D:UseDspacing
	NVAR UserThetaMin=root:Packages:Convert2Dto1D:UserThetaMin
	NVAR UserThetaMax=root:Packages:Convert2Dto1D:UserThetaMax
	NVAR UserDMin=root:Packages:Convert2Dto1D:UserDMin
	NVAR UserDMax=root:Packages:Convert2Dto1D:UserDMax
	NVAR UserQMin=root:Packages:Convert2Dto1D:UserQMin
	NVAR UserQMax=root:Packages:Convert2Dto1D:UserQMax
	NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength							//in A
	variable UserMin=0
	variable UserMax=0
	variable MaxQ
	variable MinQ		//next define Qmin and Qmax according to user needs
	if(UseQvector && UserQMin>0)
		UserMin=1
		MinQ=UserQMin
	elseif(UseDspacing && UserDMax>0)
		UserMin=1
		MinQ=2*pi / UserDMax
	elseif(UseTheta && UserThetaMin>0)
		UserMin=1
		MinQ=4 *pi * sin (pi*UserThetaMin/360) / Wavelength
	else
		UserMin=0
	endif
	if(UseQvector && UserQMax>0)
		UserMax=1
		MaxQ=UserQMax
	elseif(UseDspacing && UserDMin>0)
		UserMax=1
		MaxQ=2*pi / UserDMin
	elseif(UseTheta && UserThetaMax>0)
		UserMax=1
		MaxQ=4 *pi * sin (pi*UserThetaMax/360) / Wavelength
	else
		UserMax=0
	endif
	//wavestats/Q Qdistribution1D
	make/O/N=(QvectorNumberPoints) $("root:Packages:Convert2Dto1D:Qvector_"+orientation+"_"+wavelengths)
	make/O/N=(QvectorNumberPoints) $("root:Packages:Convert2Dto1D:QvectorWidth_"+orientation+"_"+wavelengths)
	wave Qvector=$("root:Packages:Convert2Dto1D:Qvector_"+orientation+"_"+wavelengths)
	wave QvectorWidth=$("root:Packages:Convert2Dto1D:QvectorWidth_"+orientation+"_"+wavelengths)
	variable MinQtemp
	
	if (QbinningLogarithmic)
		//logarithmic binning of Q
		duplicate/O  Qdistribution1D, logQdistribution1D
		logQdistribution1D = log(Qdistribution1D) 
		wavestats/Q logQdistribution1D
		if(!UserMax)
			MaxQ=V_max
		else
			MaxQ = log(MaxQ)
			if(MaxQ > V_max)
				MaxQ = V_max
			endif
		endif
		if(!UserMin)
			MinQ=V_min
		else
			MinQ = log(MinQ)
			if(MinQ<V_min)
				MinQ = V_min
			endif
		endif
		if(MinQ>MaxQ )
			abort "Error in create Histogram, MinQ > MaxQ"
		endif
		MinQtemp = MinQ + 0.2*(MaxQ-MinQ)/QvectorNumberPoints
		logQdistribution1D = (numtype(logQdistribution1D[p])==0 && logQdistribution1D[p]>MinQ) ? logQdistribution1D[p] : MinQtemp
	//	wavestats/Q logQdistribution1D
		Histogram /B={MinQ, ((MaxQ-MinQ)/QvectorNumberPoints), QvectorNumberPoints } logQdistribution1D, HistogramWv 
		Qvector = MinQ + 0.5*(MaxQ-MinQ)/QvectorNumberPoints+p*(MaxQ-MinQ)/QvectorNumberPoints
		Qvector = 10^(Qvector)
		QvectorWidth = Qvector[p+1] - Qvector[p]
		QvectorWidth[numpnts(Qvector)-1]=QvectorWidth[numpnts(Qvector)-2]
		killwaves logQdistribution1D
	else
		//linear binning of Q
		wavestats/Q Qdistribution1D
		if(!UserMax)
			MaxQ=V_max
		else
			if(MaxQ>V_max)
				MaxQ = V_max
			endif
		endif
		if(!UserMin)
			MinQ=V_min
		else
			if(MinQ<V_min)
				MinQ=V_min
			endif
		endif	//next line has problem with MinQ and single precision of Qdistribution1D... Need ot set to slightly higher value...
		if(MinQ>MaxQ )
			abort "Error in create Histogram, MinQ > MaxQ"
		endif
		MinQtemp = MinQ + 0.2*(MaxQ-MinQ)/QvectorNumberPoints
		Qdistribution1D = (Qdistribution1D[p]>MinQ) ? Qdistribution1D[p] : MinQtemp
		Histogram /B={MinQ, ((MaxQ-MinQ)/QvectorNumberPoints), QvectorNumberPoints } Qdistribution1D, HistogramWv 
		Qvector = MinQ + 0.5*(MaxQ-MinQ)/QvectorNumberPoints+ p*(MaxQ-MinQ)/QvectorNumberPoints
		QvectorWidth = Qvector[p+1] - Qvector[p]
		QvectorWidth[numpnts(Qvector)-1]=QvectorWidth[numpnts(Qvector)-2]
	endif
	string NoteStr=note(Qdistribution1D)
	NoteStr+="QbinningLogarithmic="+num2str(QbinningLogarithmic)+";"
	NoteStr+="QvectorNumberPoints="+num2str(QvectorNumberPoints)+";"	
	NoteStr+="UserThetaMin="+num2str(UserThetaMin)+";"	
	NoteStr+="UserThetaMax="+num2str(UserThetaMax)+";"	
	NoteStr+="UserDMin="+num2str(UserDMin)+";"	
	NoteStr+="UserDMax="+num2str(UserDMax)+";"	
	NoteStr+="UserQMin="+num2str(UserQMin)+";"	
	NoteStr+="UserQMax="+num2str(UserQMax)+";"	
	note HistogramWv, NoteStr
	//create now 2theta wave and d spacing wave
	Duplicate/O Qvector, $("root:Packages:Convert2Dto1D:TwoTheta_"+orientation+"_"+wavelengths), $("root:Packages:Convert2Dto1D:Dspacing_"+orientation+"_"+wavelengths)
	Duplicate/O Qvector, $("root:Packages:Convert2Dto1D:TwoThetaWidth_"+orientation+"_"+wavelengths), $("root:Packages:Convert2Dto1D:DspacingWidth_"+orientation+"_"+wavelengths)
	wave TwoTheta=$("root:Packages:Convert2Dto1D:TwoTheta_"+orientation+"_"+wavelengths)
	wave Dspacing = $("root:Packages:Convert2Dto1D:Dspacing_"+orientation+"_"+wavelengths)
	wave TwoThetaWidth = $("root:Packages:Convert2Dto1D:TwoThetaWidth_"+orientation+"_"+wavelengths)
	wave DSpacingWidth = $("root:Packages:Convert2Dto1D:DspacingWidth_"+orientation+"_"+wavelengths)
	// sin (theta) = Q * Lambda / 4 * pi     
	// Lamdba = 2 * d * sin (theta)
	// d = 0.5 * Lambda / sin(theta) = 2 * pi / Q    Q = 2pi/d
	variable constVal=Wavelength / (4 * pi)
	TwoTheta =  2 * asin ( Qvector * constVal) * 180 /pi
	TwoThetaWidth  = TwoTheta[p+1] - TwoTheta [p]
	TwoThetaWidth[numpnts(TwoThetaWidth)-1]=TwoThetaWidth[numpnts(TwoThetaWidth)-2]
	constVal = 2*pi
	Dspacing = constVal / Qvector
	DSpacingWidth  = Dspacing[p+1] - Dspacing [p]
	DSpacingWidth[numpnts(DSpacingWidth)-1]=DSpacingWidth[numpnts(DSpacingWidth)-2]
	
	setDataFOlder OldDF
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_CreateQvector(orientation,wavelengths)
	string orientation
	string wavelengths

//	print "Creating Q vector"
//	
//	string OldDf=GetDataFolder(1)
//	setDataFolder root:Packages:Convert2Dto1D
//	wave Rdistribution1D=$("root:Packages:Convert2Dto1D:Rdistribution1D_"+orientation)
//	wave LUT=$("root:Packages:Convert2Dto1D:LUT_"+orientation)
//	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance		//in millimeters
//	NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength							//in A
//	//wavelength=12.398424437/EnergyInKeV
//	
//	//Create wave for q distribution
//	Duplicate/O Rdistribution1D, $("Qdistribution1D_"+orientation)
//	wave Qdistribution1D=$("Qdistribution1D_"+orientation)
//	Redimension/S Qdistribution1D
//	//Qdistribution1D = ((4*pi)/Wavelength)*sin(0.5*Rdistribution1D/SampleToCCDDistance)
//	Qdistribution1D = ((4*pi)/Wavelength)*sin(0.5*atan(Rdistribution1D/SampleToCCDDistance))
//	string NoteStr=note(Rdistribution1D)
//	NoteStr+="SampleToCCDDistance="+num2str(SampleToCCDDistance)+";"
//	NoteStr+="Wavelength="+num2str(Wavelength)+";"	
//	note Qdistribution1D, NoteStr
//
//	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_CreateLUT(orientation,wavelengths)
	string orientation
	string wavelengths

	print "Creating LUT for "+orientation+"  orientation and "+wavelengths+ " wavelength"

	string OldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	wave Q2DWave=root:Packages:Convert2Dto1D:Q2DWave
	Wave AnglesWave=root:Packages:Convert2Dto1D:AnglesWave
	NVAR UseMask=root:Packages:Convert2Dto1D:UseMask
	NVAR QbinningLogarithmic=root:Packages:Convert2Dto1D:QbinningLogarithmic
	NVAR QvectorNumberPoints=root:Packages:Convert2Dto1D:QvectorNumberPoints
	NVAR DoSectorAverages=root:Packages:Convert2Dto1D:DoSectorAverages
	NVAR NumberOfSectors=root:Packages:Convert2Dto1D:NumberOfSectors
	NVAR SectorsStartAngle=root:Packages:Convert2Dto1D:SectorsStartAngle
	NVAR SectorsHalfWidth=root:Packages:Convert2Dto1D:SectorsHalfWidth
	NVAR SectorsStepInAngle=root:Packages:Convert2Dto1D:SectorsStepInAngle
	SVAR CurrentMaskFileName=root:Packages:Convert2Dto1D:CurrentMaskFileName
	variable centerAngleRad, WidthAngleRad, startAngleFIxed, endAgleFixed
	//apply mask, if selected
	MatrixOp/O MaskedQ2DWave=Q2DWave
	redimension/S MaskedQ2DWave
	if(UseMask)
		wave M_ROIMask=root:Packages:Convert2Dto1D:M_ROIMask
		MatrixOp/O MaskedQ2DWave = Q2DWave * M_ROIMask
	endif
	if(cmpstr(orientation,"C")!=0)
		MatrixOp/O tempAnglesMask = AnglesWave
		centerAngleRad= (pi/180)*str2num(StringFromList(0, orientation,  "_"))
		WidthAngleRad= (pi/180)*str2num(StringFromList(1, orientation,  "_"))
		
		startAngleFixed = centerAngleRad-WidthAngleRad
		endAgleFixed = centerAngleRad+WidthAngleRad

		if(startAngleFixed<0)
			tempAnglesMask = ((AnglesWave[p][q] > (2*pi+startAngleFixed) || AnglesWave[p][q] <endAgleFixed))? 1 : 0
		elseif(endAgleFixed>(2*pi))
			tempAnglesMask = (AnglesWave[p][q] > startAngleFixed || AnglesWave[p][q] <(endAgleFixed-2*pi))? 1 : 0
		else
			tempAnglesMask = (AnglesWave[p][q] > startAngleFixed && AnglesWave[p][q] <endAgleFixed)? 1 : 0
		endif
		
		MatrixOp/O MaskedQ2DWave = MaskedQ2DWave * tempAnglesMask
		killwaves tempAnglesMask
	endif
	//radius data are masked now 

	wavestats/Q MaskedQ2DWave
	make/O/N=(V_npnts)  $("Qdistribution1D_"+orientation+"_"+wavelengths), $("LUT_"+orientation+"_"+wavelengths)
	wave LUT=$("LUT_"+orientation+"_"+wavelengths)
	wave Qdistribution1D=$("Qdistribution1D_"+orientation+"_"+wavelengths)
	redimension/S Qdistribution1D
	Qdistribution1D = MaskedQ2DWave
	LUT=p
	MakeIndex Qdistribution1D, LUT
	string NoteStr=note(Q2DWave)
	NoteStr+="UseMask="+num2str(UseMask)+";"
	NoteStr+="CurrentMaskFileName="+CurrentMaskFileName+";"
	note Qdistribution1D, NoteStr
	note LUT, NoteStr
	KillWaves/Z MaskedQ2DWave
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_Create2DQWave(DataWave)
	wave DataWave

	string OldDf=GetDataFolder(1)
	setDataFolder root:Packages:Convert2Dto1D
	
	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance		//in millimeters
	NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength							//in A
	NVAR PixelSizeX = root:Packages:Convert2Dto1D:PixelSizeX								//in millimeters
	NVAR PixelSizeY = root:Packages:Convert2Dto1D:PixelSizeY								//in millimeters
	NVAR beamCenterX=root:Packages:Convert2Dto1D:beamCenterX
	NVAR beamCenterY=root:Packages:Convert2Dto1D:beamCenterY
	NVAR reflbeam=root:Packages:Convert2Dto1D:reflbeam
	NVAR grazingangle=root:Packages:Convert2Dto1D:LineProf_GIIncAngle
	nvar anglephi=root:Packages:Convert2Dto1D:phiangle // tilt around beam center, used to retilting gisaxs
	NVAR HorizontalTilt=root:Packages:Convert2Dto1D:HorizontalTilt							//tilt in degrees
	NVAR VerticalTilt=root:Packages:Convert2Dto1D:VerticalTilt								//tilt in degrees
	NVAR Inverted=root:Packages:Convert2Dto1D:InvertImages								//yes means z axis needs to flip
	//wavelength=12.398424437/EnergyInKeV
	//OK, existing radius wave was not correct or did not exist, make the right one... 
	print "Creating 2D Q wave"
	//Create wave for q distribution
	//ImageRotate /e=0 /o/A=(phiangle) datawave
	variable phi = anglephi *pi/180
	MatrixOp/O/NTHR=1 Q2DWave=DataWave
	MatrixOp/O/NTHR=1 Theta2DWave=DataWave
	MatrixOp/O/NTHR=1 qxwave=DataWave
	MatrixOp/O/NTHR=1 qywave=DataWave
	MatrixOp/O/NTHR=1 qxywave=DataWave
	MatrixOp/O/NTHR=1 qzwave=DataWave
	//MatrixOp/O/NTHR=1 kinxwave=DataWave
	//MatrixOp/O/NTHR=1 kinywave=DataWave
	//MatrixOp/O/NTHR=1 kinzwave=DataWave
	variable kinxwave, kinywave, kinzwave
	MatrixOp/O/NTHR=1 koutxwave=DataWave
	MatrixOp/O/NTHR=1 koutywave=DataWave
	MatrixOp/O/NTHR=1 koutzwave=DataWave
	MatrixOp/O/NTHR=1 kouttempmag=DataWave
	
	MatrixOp/O/NTHR=1 Xiwave=DataWave
	MatrixOp/O/NTHR=1 Thwave=DataWave

	matrixop/O/NTHR=1 qxypure=datawave // these are the values which we will eventually reorganize, setting up the axis on which we will plot
	matrixop/O/NTHR=1 qzpure=datawave
	
	variable ts=ticks
//Eliot changing theta calculation using k values calculated below
//	if(abs(HorizontalTilt)>0.01 || abs(VerticalTilt)>0.01)		//use tilts, new method March 2011, JIL. Using extracted code by Jon Tischler. 
//		NI2T_Calculate2DThetaWithTilts(Theta2DWave)		
//		print "Both tilts used, time was = "+num2str((ticks-ts)/60)
//	else			//no tilts... 
//		Multithread Theta2DWave = sqrt(((p-BeamCenterX)*PixelSizeX)^2 + ((q-BeamCenterY)*PixelSizeY)^2)
//		//the QsDWave now contains the distance from beam center  Results should be in mm.... 
//		//added to calculate the theta values...
//		if(reflbeam==1)//direct beam
//			Multithread Theta2DWave = atan(Theta2DWave/SampleToCCDDistance)/2
//		elseif(reflbeam==2)//reflected Beam
//			Multithread Theta2DWave = atan(Theta2DWave/SampleToCCDDistance)/2 - grazingangle * pi / 180
//		else // average of the two
//			Multithread Theta2DWave = atan(Theta2DWave/SampleToCCDDistance)/2 - 0.5 * grazingangle * pi / 180
//		endif
//	endif
	variable/g effBCY // effective beam centers
	
	if(reflbeam==1)//direct beam
		kinxwave = 2* pi/ wavelength
		kinzwave = 0
		kinywave = 0
		effBCY = beamcentery
		// the pure waves will set up the q vetical and q horizontal locations of each pixel on the idealized detector which collects everything
		// even the idealized detector does not have equal pixel sizes in q space
		//multithread qxypure = 4*pi*sin(atan((p-beamcenterx)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength // these will be used in the histograms to flatten out the data
		//multithread qzpure=  4*pi*sin(atan((q-effBCY)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength
	elseif(reflbeam==2)//reflected Beam
		kinxwave = (2* pi/ wavelength) * cos(grazingangle*2* pi / 180)
		kinywave = 0
		if(inverted)
			kinzwave = -(2* pi/ wavelength) * Sin(grazingangle*2* pi / 180)
			effBCY = beamcentery + tan(2*grazingangle*pi/180)*SampleToCCDDistance/PixelSizey
		else
			kinzwave = (2* pi/ wavelength) * Sin(grazingangle*2* pi / 180)
			effBCY = beamcentery - tan(2*grazingangle*pi/180)*SampleToCCDDistance/PixelSizey
		endif
		//multithread qxypure = 4*pi*sin(grazingangle* pi / 180 + atan((p-beamcenterx)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength // these will be used in the histograms to flatten out the data
		//multithread qzpure=  4*pi*sin(grazingangle* pi / 180 + atan((q-effBCY)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength
	else // average of the two
		kinxwave = (2* pi/ wavelength) * cos(grazingangle* pi / 180)
		kinywave = 0
		if(inverted)
			kinzwave = -(2* pi/ wavelength) * Sin(grazingangle* pi / 180)
			effBCY = beamcentery - tan(grazingangle*pi/180)*SampleToCCDDistance/PixelSizey
		else
			kinzwave = (2* pi/ wavelength) * Sin(grazingangle* pi / 180)
			effBCY = beamcentery - tan(grazingangle*pi/180)*SampleToCCDDistance/PixelSizey
		endif
		//multithread qxypure = 4*pi*sin(.5*grazingangle* pi / 180 + atan((p-beamcenterx)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength // these will be used in the histograms to flatten out the data
		//multithread qzpure=  4*pi*sin(.5*grazingangle* pi / 180 + atan((q-effBCY)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength
	endif
	if(inverted)
		multithread koutywave =  (Cos(phi)*(p - BeamCenterX)*PixelSizeX -Sin(phi)*(q - beamcentery)*PixelSizeY) // assumes the effective beam center is normal to the beam (or close)
		multithread koutzwave =  -(Sin(phi)*(p - BeamCenterX)*PixelSizeX +Cos(phi)*(q - beamcentery)*PixelSizeY)
	else
		multithread koutywave =  (Cos(phi)*(p - BeamCenterX)*PixelSizeX -Sin(phi)*(q - beamcentery)*PixelSizeY) // assumes the effective beam center is normal to the beam (or close)
		multithread koutzwave =  (Sin(phi)*(p - BeamCenterX)*PixelSizeX +Cos(phi)*(q - beamcentery)*PixelSizeY)
	endif
	// distance from "direct" beam
	
	qxypure[beamcenterx][]=0 // changed from half angle to full angle and 2 pi instead of 4 pi
	qzpure[][effBCY] = 0
	// first just get the vector in the right direction, use the position vector of the pixel relative to the scattering location, which is easy

	multithread koutxwave = SampleToCCDDistance
	// distance to ccd
	// now figure out the magnitude of this vector, so we can scale it correctly to 2pi/wavelength
	multithread kouttempmag = sqrt(koutywave^2 + koutxwave^2 + koutzwave^2)
	multithread koutywave*=2*pi/(wavelength*kouttempmag)
	multithread koutxwave*=2*pi/(wavelength*kouttempmag)
	multithread koutzwave*=2*pi/(wavelength*kouttempmag)
	// now solve for the q vector, which is kout-kin
	multithread qxwave = koutxwave-kinxwave
	multithread qywave = koutywave-kinywave
	multithread qzwave = koutzwave-kinzwave // this is one of the main waves needed for distorting the image creating the wedge
	Multithread qxywave = sqrt(qxwave^2 + qywave^2) * sign(qywave) // this is the main wave needed for distorting the image and creating the wedge
	Multithread Q2DWave = sqrt(qxwave^2 + qywave^2 + qzwave^2) 
	Multithread Theta2DWave = 2*asin(Q2DWave*wavelength/(4* pi))
	multithread xiwave = ( 180/pi ) * atan(abs(qxywave) / abs(qzwave))
	multithread Thwave = ( 180/pi ) * atan2((p - BeamCenterX) , (q - beamcentery))
	
	Theta2DWave[beamCenterX][effBCY] = NaN
	
	//record for which geometry this Radius vector wave was created
	string NoteStr
	NoteStr = note(DataWave)
	NoteStr+="BeamCenterX="+num2str(BeamCenterX)+";"
	NoteStr+="BeamCenterY="+num2str(BeamCenterY)+";"
	NoteStr+="PixelSizeX="+num2str(PixelSizeX)+";"
	NoteStr+="PixelSizeY="+num2str(PixelSizeY)+";"
	NoteStr+="HorizontalTilt="+num2str(HorizontalTilt)+";"
	NoteStr+="VerticalTilt="+num2str(VerticalTilt)+";"
	NoteStr+="SampleToCCDDistance="+num2str(SampleToCCDDistance)+";"
	NoteStr+="Wavelength="+num2str(Wavelength)+";"	
	NoteStr+="ReflectedBeam="+num2str(ReflBeam)+";"	
	NoteStr+="PhiAngle="+num2str(Phi)+";"	
	NoteStr+="IncidentAngle="+num2str(grazingangle)+";"	
	note qxwave, NoteStr
	note qywave, NoteStr
	note qzwave, NoteStr
	note qxywave, NoteStr
	
	note Xiwave, NoteStr
	note Thwave, NoteStr
	note Q2DWave, NoteStr
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_Create2DAngleWave(DataWave)
	wave DataWave
	print "Creating Angle wave"

	string OldDf=GetDataFolder(1)
	setDataFolder root:Packages:Convert2Dto1D
	NVAR beamCenterX=root:Packages:Convert2Dto1D:beamCenterX
	//NVAR beamCenterY=root:Packages:Convert2Dto1D:beamCenterY
	
	
		NVAR beamycenter=root:Packages:Convert2Dto1D:BeamCenterY
		nvar effectiveycenter = root:Packages:Convert2Dto1D:effBCY
		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		variable BeamCenterY
		if(nvar_exists(effectiveycenter) && UseGrazingIncidence)
			BeamCenterY = effectiveycenter
		else
			BeamCenterY = beamycenter
		endif
		
	
	
	//Now angle from 0 degrees, so we can do sectors if necessary
	Duplicate/O DataWave, AnglesWave
	Redimension/S AnglesWave
	AnglesWave = abs(atan2((BeamCenterY-q),(BeamCenterX-p))-pi)			
	//this creates wave with angle values for each point, values are between 0 and 2*pi
	string NoteStr
	NoteStr=";BeamCenterX="+num2str(BeamCenterX)+";"
	NoteStr+="BeamCenterY="+num2str(BeamCenterY)+";"
	note AnglesWave, NoteStr

	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_Check2DConversionData()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	Wave/Z DataWave=root:Packages:Convert2Dto1D:CCDImageToConvert
	Wave/Z EmptyRunWave=root:Packages:Convert2Dto1D:EmptyData
	Wave/Z DarkCurrentWave=root:Packages:Convert2Dto1D:DarkFieldData
	Wave/Z MaskWave=root:Packages:Convert2Dto1D:M_ROIMask
	Wave/Z Pix2DSensitivity=root:Packages:Convert2Dto1D:Pixel2DSensitivity

	NVAR Use2DdataName=root:Packages:Convert2Dto1D:Use2DdataName
	NVAR UseCorrectionFactor=root:Packages:Convert2Dto1D:UseCorrectionFactor
	NVAR UseDarkField=root:Packages:Convert2Dto1D:UseDarkField
	NVAR UseDarkMeasTime=root:Packages:Convert2Dto1D:UseDarkMeasTime
	NVAR UseEmptyField=root:Packages:Convert2Dto1D:UseEmptyField
	NVAR UseEmptyMeasTime=root:Packages:Convert2Dto1D:UseEmptyMeasTime
	NVAR UseI0ToCalibrate=root:Packages:Convert2Dto1D:UseI0ToCalibrate
	NVAR UseMask=root:Packages:Convert2Dto1D:UseMask
	NVAR UseMonitorForEF=root:Packages:Convert2Dto1D:UseMonitorForEF
	NVAR UsePixelSensitivity=root:Packages:Convert2Dto1D:UsePixelSensitivity
	NVAR UseSampleMeasTime=root:Packages:Convert2Dto1D:UseSampleMeasTime
	NVAR UseSampleThickness=root:Packages:Convert2Dto1D:UseSampleThickness
	NVAR UseSampleTransmission=root:Packages:Convert2Dto1D:UseSampleTransmission
	NVAR UseSubtractFixedOffset=root:Packages:Convert2Dto1D:UseSubtractFixedOffset
	NVAR UsePixelSensitivity= root:Packages:Convert2Dto1D:UsePixelSensitivity

	if (!WaveExists(DataWave))
		Abort "Data wave does not exist"
	endif
	if((UseEmptyField && (WaveExists(EmptyRunWave)!=1)))
		Abort "Empty wave does not exist"
	endif
	if((UseDarkField && (WaveExists(DarkCurrentWave)!=1)))
		Abort "Dark field wave does not exist"
	endif
	if((UsePixelSensitivity && (WaveExists(Pix2DSensitivity)!=1)))
		Abort "Pix2D sensitivity wave does not exist"
	endif
	//check the waves for dimensions, they must be the same....
	if(UsePixelSensitivity)
		if(DimSize(DataWave,0)!=dimsize(Pix2DSensitivity,0) || DimSize(DataWave,1)!=DimSize(Pix2DSensitivity,1))
			Abort "Error, the pix2D sensitivity wave does not have the same dimensions" 
		endif
	endif
	if(UseEmptyField)
		if(DimSize(DataWave,0)!=dimsize(EmptyRunWave,0) || DimSize(DataWave,1)!=DimSize(EmptyRunWave,1))
			Abort "Error, the empty wave does not have the same dimensions" 
		endif
	endif
	if(UseDarkField)
		if(DimSize(DataWave,0)!=dimsize(DarkCurrentWave,0) || DimSize(DataWave,1)!=DimSize(DarkCurrentWave,1))
			Abort "Error, the dark field wave does not have the same dimensions" 
		endif
	endif
	if(UseMask)
		if(DimSize(DataWave,0)!=dimsize(MaskWave,0) || DimSize(DataWave,1)!=DimSize(MaskWave,1))
			Abort "Error, the mask field wave does not have the same dimensions" 
		endif
	endif

	setDataFolder OldDf
end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	
	if(cmpstr(ctrlName,"Select2DDataType")==0)
		//set appropriate extension
		SVAR DataFileExtension=root:Packages:Convert2Dto1D:DataFileExtension
		DataFileExtension = popStr
		EGNA_UpdateDataListBox()
		if(cmpstr(popStr,"GeneralBinary")==0)
			EGN_GBLoaderPanelFnct()
		endif
		if(cmpstr(popStr,"Pilatus")==0)
			EGN_PilatusLoaderPanelFnct()
		endif
		if(cmpstr(popStr,"AUSW")==0)
			AUSW_loaderf()
		endif
		if(cmpstr(popStr,"ESRFedf")==0)
			EGN_ESRFEdfLoaderPanelFnct()
		endif
		if(cmpstr(popStr,".fits")==0)
			EGN_FitsLoaderPanelFnct()
		endif
		if(cmpstr(popStr,"BS_Suitcase_Tiff")==0)
			EGN_BSLoaderPanelFnct()
		endif
	endif
	if(cmpstr(ctrlName,"SelectBlank2DDataType")==0)
		//set appropriate extension
		SVAR BlankFileExtension=root:Packages:Convert2Dto1D:BlankFileExtension
		BlankFileExtension = popStr
		EGNA_UpdateEmptyDarkListBox()
		if(cmpstr(popStr,"GeneralBinary")==0)
			EGN_GBLoaderPanelFnct()
		endif
		if(cmpstr(popStr,"Pilatus")==0)
			EGN_PilatusLoaderPanelFnct()
		endif
	endif


		//Select2DMaskType
	if(cmpstr(ctrlName,"Select2DMaskType")==0)
		//set appropriate extension
		SVAR MaskFileExtension=root:Packages:Convert2Dto1D:MaskFileExtension
		if(cmpstr(popStr,"GeneralBinary")==0)
			EGN_GBLoaderPanelFnct()
		endif
		if(cmpstr(popStr,"Pilatus")==0)
			EGN_PilatusLoaderPanelFnct()
		endif
		if (cmpstr(popStr,"tif")==0 || cmpstr(popStr,"AUSW")==0|| cmpstr(popStr,"BS_Suitcase_Tiff")==0)
			MaskFileExtension=".tif"
		elseif (cmpstr(popStr,"AUSY")==0)
			MaskFileExtension=".tif"
		elseif (cmpstr(popStr,".fits")==0)
			MaskFileExtension=".fits"
		elseif (cmpstr(popStr,"Mar")==0)
			MaskFileExtension="????"
		elseif (cmpstr(popStr,"BrukerCCD")==0)
			DataFileExtension="BrukerCCD"
		elseif (cmpstr(popStr,"Pilatus")==0)
			SVAR PilatusFileType=root:Packages:Convert2Dto1D:PilatusFileType
			if(!cmpstr(PilatusFileType,"edf"))
				MaskFileExtension=".edf"
			elseif(!cmpstr(PilatusFileType,"tiff")||!cmpstr(PilatusFileType,"float-tiff"))
				MaskFileExtension=".tif"
			elseif(!cmpstr(PilatusFileType,"img"))
				MaskFileExtension=".img"
			endif
		else	//if (cmpstr(popStr,"any")==0)
			MaskFileExtension="????"
		endif
		EGNA_UpdateMainMaskListBox()
	
	endif


	if(cmpstr(ctrlName,"LineProf_CurveType")==0)
		//here we select start of the range...
		SVAR LineProf_CurveType=root:Packages:Convert2Dto1D:LineProf_CurveType
		LineProf_CurveType=popStr		
		SVAR KnWCT=root:Packages:Convert2Dto1D:LineProf_CurveType
		SetVariable LineProf_LineAzAngle,disable=(!stringMatch(KnWCT,"Angle Line")), win=EGNA_Convert2Dto1DPanel
		SetVariable LineProf_EllipseAR,disable=(!stringMatch(KnWCT,"Ellipse")), win=EGNA_Convert2Dto1DPanel
		SetVariable LineProf_GIIncAngle,disable=((!stringMatch(KnWCT,"GISAXS_FixQy")&&!stringMatch(KnWCT,"GI_Horizontal Line")&&!stringMatch(KnWCT,"GI_Vertical Line"))), win=EGNA_Convert2Dto1DPanel
		checkbox LineProf_UseBothHalfs,disable=(stringMatch(KnWCT,"Angle Line")), win=EGNA_Convert2Dto1DPanel	
		checkbox LineProf_SubtractBackground,disable=(!stringMatch(KnWCT,"Ellipse")), win=EGNA_Convert2Dto1DPanel	
		
		EGNA_LineProf_Update()
	endif


	if(cmpstr(ctrlName,"SelectStartOfRange")==0)
		//here we select start of the range...
		NVAR StartDataRangeNumber=root:Packages:Convert2Dto1D:StartDataRangeNumber
		StartDataRangeNumber=popNum
		EGNA_MakeContiguousSelection()
	endif
	if(cmpstr(ctrlName,"SelectEndOfRange")==0)
		//here we select end of the range...
		NVAR EndDataRangeNumber=root:Packages:Convert2Dto1D:EndDataRangeNumber
		EndDataRangeNumber=popNum
		EGNA_MakeContiguousSelection()
	endif
	if(cmpstr(ctrlName,"ColorTablePopup")==0)
		SVAR ColorTableName=root:Packages:Convert2Dto1D:ColorTableName
		ColorTableName = popStr
		EGNA_TopCCDImageUpdateColors(1)
	endif
	if(cmpstr(ctrlName,"MaskImageColor")==0)
		NI1M_ChangeMaskColor(popStr) 
	endif
	if(cmpstr(ctrlName,"GI_Shape1")==0)
		SVAR GI_Shape1=root:Packages:Convert2Dto1D:GI_Shape1
		GI_Shape1=popStr 
		EGNA_TabProc("",6)
	endif

	DoWIndow/F EGNA_Convert2Dto1DPanel
	DoWIndow/F NI_GBLoaderPanel
	DoWIndow/F NI_PilatusLoaderPanel

	setDataFolder OldDf
End

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************


Function EGNA_UpdateMainMaskListBox()		

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
//	NI1M_UpdateMaskListBox()
	
	pathinfo Convert2Dto1DMaskPath
	if(V_Flag==0)
		abort
	endif

		Wave/T  ListOf2DMaskData=root:Packages:Convert2Dto1D:ListOf2DMaskData
		Wave ListOf2DMaskDataNumbers=root:Packages:Convert2Dto1D:ListOf2DMaskDataNumbers
		SVAR MaskFileExtension=root:Packages:Convert2Dto1D:MaskFileExtension
		string ListOfAvailableMasks
		string MaskFileEnd ="*_mask.tif"
		ListOfAvailableMasks=IndexedFile(Convert2Dto1DMaskPath,-1,MaskFileExtension)
		variable i, imax=0
		string tempstr
		redimension/N=(itemsInList(ListOfAvailableMasks)) ListOf2DMaskData
		redimension/N=(itemsInList(ListOfAvailableMasks)) ListOf2DMaskDataNumbers
		For(i=0;i<ItemsInList(ListOfAvailableMasks);i+=1)
		//	tempstr=StringFromList(0,StringFromList(i, ListOfAvailableMasks),".")
			tempstr=StringFromList(i, ListOfAvailableMasks)
			if (stringmatch(tempstr, MaskFileEnd ))
				ListOf2DMaskData[imax]=tempstr
				imax+=1
			endif
		endfor
		redimension/N=(imax) ListOf2DMaskData
		redimension/N=(imax) ListOf2DMaskDataNumbers
		sort ListOf2DMaskData, ListOf2DMaskData, ListOf2DMaskDataNumbers
		ListOf2DMaskDataNumbers=0
		DoWindow EGNA_Convert2Dto1DPanel
		if(V_Flag)
			ListBox MaskListBoxSelection win=EGNA_Convert2Dto1DPanel, listWave=root:Packages:Convert2Dto1D:ListOf2DMaskData
			ListBox MaskListBoxSelection win=EGNA_Convert2Dto1DPanel, row= 0,mode= 1,selRow= 0
		endif
	setDataFolder OldDf
	DoUpdate
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_UpdateEmptyDarkListBox()		

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
		Wave/T  ListOf2DEmptyData=root:Packages:Convert2Dto1D:ListOf2DEmptyData
		SVAR BlankFileExtension=root:Packages:Convert2Dto1D:BlankFileExtension
		SVAR EmptyDarkNameMatchStr=root:Packages:Convert2Dto1D:EmptyDarkNameMatchStr
		variable i
		string tempstr, realExtension, realext2=""
		if(cmpstr(BlankFileExtension, ".tif")==0)
			realExtension=BlankFileExtension
			realext2 = ".tiff"
		elseif(cmpstr(BlankFileExtension, "ADSC")==0)
			realExtension=".img"
		elseif(cmpstr(BlankFileExtension, ".fits")==0)
			realExtension=".fits"
		elseif (cmpstr(BlankFileExtension,"Pilatus")==0)
			SVAR PilatusFileType=root:Packages:Convert2Dto1D:PilatusFileType
			if(!cmpstr(PilatusFileType,"edf"))
				realExtension=".edf"
			elseif(!cmpstr(PilatusFileType,"tiff")||!cmpstr(PilatusFileType,"float-tiff"))
				realExtension=".tif"
			elseif(!cmpstr(PilatusFileType,"img"))
				realExtension=".img"
			endif
		elseif(cmpstr(BlankFileExtension, "ibw")==0)
			realExtension=".ibw"
		else
			realExtension="????"
		endif
		string ListOfAvailableDataSets
		PathInfo Convert2Dto1DEmptyDarkPath
		if(V_Flag==1)

		ListOfAvailableDataSets=IndexedFile(Convert2Dto1DEmptyDarkPath,-1,realExtension)
		if(strlen(realext2)>0)
			ListOfAvailableDataSets+=IndexedFile(Convert2Dto1DEmptyDarkPath,-1,realext2)
			ListOfAvailableDataSets = sortlist(ListOfAvailableDataSets, ";", 16)
		endif
		if(strlen(ListOfAvailableDataSets)<2)	//none found
			ListOfAvailableDataSets="--none--;"
		endif
		ListOfAvailableDataSets=EGNA_CleanListOfFilesForTypes(ListOfAvailableDataSets,BlankFileExtension,EmptyDarkNameMatchStr)
		redimension/N=(ItemsInList(ListOfAvailableDataSets)) ListOf2DEmptyData
		EGNA_CreateListOfFiles(ListOf2DEmptyData,ListOfAvailableDataSets,realExtension, EmptyDarkNameMatchStr)
		sort ListOf2DEmptyData, ListOf2DEmptyData
		DoWindow EGNA_Convert2Dto1DPanel
		if(V_Flag)
			ListBox Select2DMaskDarkWave win=EGNA_Convert2Dto1DPanel, listWave=root:Packages:Convert2Dto1D:ListOf2DEmptyData
			ListBox Select2DMaskDarkWave win=EGNA_Convert2Dto1DPanel,row= 0,mode= 1,selRow= 0
		endif
		endif
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_MakeContiguousSelection()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	NVAR StartDataRangeNumber=root:Packages:Convert2Dto1D:StartDataRangeNumber
	NVAR EndDataRangeNumber=root:Packages:Convert2Dto1D:EndDataRangeNumber

	Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers

	if (StartDataRangeNumber>0 && EndDataRangeNumber>0)
		ListOf2DSampleDataNumbers[0,StartDataRangeNumber-1]=0
		ListOf2DSampleDataNumbers[StartDataRangeNumber-1,EndDataRangeNumber-1]=1
		if(EndDataRangeNumber<numpnts(ListOf2DSampleDataNumbers))
			ListOf2DSampleDataNumbers[EndDataRangeNumber,inf]=0
		endif
	endif
	setDataFolder OldDf
end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function/T EGNA_Create2DSelectionPopup()

	Wave/T  ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
	variable i, imax=numpnts(ListOf2DSampleData)	
	string MenuStr=""
	For(i=0;i<imax;i+=1)
		MenuStr+=ListOf2DSampleData[i]+";"
	endfor
	return MenuStr
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_ButtonProc(ctrlName) : ButtonControl
	String ctrlName



	if(cmpstr(ctrlName,"CreateOutputPath")==0)
		PathInfo/S Convert2Dto1DOutputPath
		NewPath/C/O/M="Select path to save your data" Convert2Dto1DOutputPath	
	endif
	if(cmpstr(ctrlName,"SelectMaskDarkPath")==0)
		PathInfo/S Convert2Dto1DEmptyDarkPath
		NewPath/C/O/M="Select path to your data" Convert2Dto1DEmptyDarkPath	
		EGNA_UpdateEmptyDarkListBox()	
	endif
	if(cmpstr(ctrlName,"RefreshList")==0)
		ControlInfo/W=EGNA_Convert2Dto1DPanel Select2DInputWave
		variable oldSets=V_startRow
		EGNA_UpdateDataListBox()	
		ListBox Select2DInputWave,win=EGNA_Convert2Dto1DPanel,row=V_startRow
	endif
	if(cmpstr(ctrlName,"LoadDarkField")==0)
		EGNA_LoadEmptyOrDark("Dark")	
	endif
	if(cmpstr(ctrlName,"LoadEmpty")==0)
		EGNA_LoadEmptyOrDark("Empty")		
	endif
	if(cmpstr(ctrlName,"DisplaySelectedFile")==0)
		//set selections for using RAW/Converted data...
		NVAR LineProfileUseRAW=root:Packages:Convert2Dto1D:LineProfileUseRAW
		NVAR LineProfileUseCorrData=root:Packages:Convert2Dto1D:LineProfileUseCorrData
		NVAR SectorsUseRAWData=root:Packages:Convert2Dto1D:SectorsUseRAWData
		NVAR SectorsUseCorrData=root:Packages:Convert2Dto1D:SectorsUseCorrData
		LineProfileUseRAW=1
		LineProfileUseCorrData=0
		SectorsUseRAWData=1
		SectorsUseCorrData=0
		//selection done
		EGNA_DisplayOneDataSet()	
	endif
	if(cmpstr(ctrlName,"ExportDisplayedImage")==0)
		EGNA_ExportDisplayedImage()			
	endif
	if(cmpstr(ctrlName,"SaveDisplayedImage")==0)
		EGNA_SaveDisplayedImage()			
	endif

	if(cmpstr(ctrlName,"ConvertSelectedFiles")==0)
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
	endif
	if(cmpstr(ctrlName,"AveConvertSelectedFiles")==0)
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
		EGNA_AveLoadManyDataSetsForConv()		
	endif
	if(cmpstr(ctrlName,"AveConvertNFiles")==0)
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
		EGNA_AveLoadNDataSetsForConv()		
	endif

	if(cmpstr(ctrlName,"Select2DDataPath")==0)
		PathInfo/S Convert2Dto1DDataPath
		NewPath/C/O/M="Select path to your data" Convert2Dto1DDataPath
		PathInfo Convert2Dto1DDataPath
		SVAR MainPathInfoStr=root:Packages:Convert2Dto1D:MainPathInfoStr
		MainPathInfoStr=S_path
		TitleBox PathInfoStrt, win =EGNA_Convert2Dto1DPanel, variable=MainPathInfoStr
		EGNA_UpdateDataListBox()		
	endif
	if(cmpstr(ctrlName,"MaskSelectPath")==0)
		PathInfo/S Convert2Dto1DMaskPath
		NewPath/C/O/M="Select path to your data" Convert2Dto1DMaskPath	
		EGNA_UpdateMainMaskListBox()	
		NI1M_UpdateMaskListBox()		
	endif
	if(cmpstr(ctrlName,"LoadMask")==0)
		EGNA_LoadMask()
	endif
	if(cmpstr(ctrlName,"DisplayMaskOnImage")==0)
		NI1M_DisplayMaskOnImage()
		PopupMenu MaskImageColor,win=EGNA_Convert2Dto1DPanel, mode=1
	endif
	if(cmpstr(ctrlName,"RemoveMaskFromImage")==0)
		NI1M_RemoveMaskFromImage()
	endif

//LoadPixel2DSensitivity
	if(cmpstr(ctrlName,"LoadPixel2DSensitivity")==0)
		EGNA_LoadEmptyOrDark("Pixel2DSensitivity")		
	endif
//Store current setting for future use
	if(cmpstr(ctrlName,"SaveCurrentToolSetting")==0)
		//call create mask routine here
		EGNA_StoreLoadCurSettingPnl()
	endif
	DoWIndow/F EGNA_Convert2Dto1DPanel

	if(cmpstr(ctrlName,"CreateMask")==0)
		NI1M_CreateMask()
	endif
//create squared sector graph...
	if(cmpstr(ctrlName,"CreateSectorGraph")==0)
		//call create mask routine here
		EGN_MakeSectorGraph()
	endif
	
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1M_DisplayMaskOnImage()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	DoWindow CCDImageToConvertFig
	if(V_Flag)
		DoWindow/F CCDImageToConvertFig
		Wave/Z M_ROIMask=root:Packages:Convert2Dto1D:M_ROIMask
		CheckDisplayed/W=CCDImageToConvertFig M_ROIMask
		if(WaveExists(M_ROIMask) && !V_Flag)
			AppendImage/t/W=CCDImageToConvertFig M_ROIMask
			ModifyImage/W=CCDImageToConvertFig M_ROIMask  ctab ={0.2,0.5, Grays}, minRGB=(12000,12000,12000),maxRGB=NaN
		endif
	endif
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1M_ChangeMaskColor(ColorToUse) //red, blue, green
	string ColorToUse

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	DoWindow CCDImageToConvertFig
	if(V_Flag)
		DoWindow/F CCDImageToConvertFig
		Wave/Z M_ROIMask=root:Packages:Convert2Dto1D:M_ROIMask
		CheckDisplayed/W=CCDImageToConvertFig M_ROIMask
		if(WaveExists(M_ROIMask) && V_Flag)
			if(cmpstr(ColorToUse,"red")==0)//red
				ModifyImage/W=CCDImageToConvertFig M_ROIMask ctab ={0.2,0.5,Grays}, minRGB=(65280,0,0),maxRGB=NaN
			elseif(cmpstr(ColorToUse,"blue")==0)//blue
				ModifyImage/W=CCDImageToConvertFig M_ROIMask ctab ={0.2,0.5,Grays}, minRGB=(0,0,65280),maxRGB=NaN
			elseif(cmpstr(ColorToUse,"grey")==0)//grey
				ModifyImage/W=CCDImageToConvertFig M_ROIMask ctab ={0.2,0.5,Grays}, minRGB=(16000,16000,16000),maxRGB=NaN
			elseif(cmpstr(ColorToUse,"black")==0)
				ModifyImage/W=CCDImageToConvertFig M_ROIMask ctab ={0.2,0.5,Grays}, minRGB=(0,0,0),maxRGB=NaN
			else
				ModifyImage/W=CCDImageToConvertFig M_ROIMask ctab ={0.2,0.5,Grays}, minRGB=(0,65280,0),maxRGB=NaN
			endif
		else
			PopupMenu MaskImageColor,win=EGNA_Convert2Dto1DPanel, mode=1
		endif
	endif
	setDataFolder OldDf

end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function NI1M_RemoveMaskFromImage()
	DoWindow CCDImageToConvertFig
	if(V_Flag)
		CheckDisplayed /W=CCDImageToConvertFig root:Packages:Convert2Dto1D:M_ROIMask
		if(V_Flag)
			RemoveImage/W=CCDImageToConvertFig  M_ROIMask
		endif
	endif
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_CheckParametersForConv()
	//check the parameters for conversion
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	NVAR BeamCenterX=root:Packages:Convert2Dto1D:BeamCenterX
	NVAR BeamCenterY=root:Packages:Convert2Dto1D:BeamCenterY
	NVAR QvectorNumberPoints= root:Packages:Convert2Dto1D:QvectorNumberPoints
	NVAR QbinningLogarithmic=root:Packages:Convert2Dto1D:QbinningLogarithmic
	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance
	NVAR Wavelength=root:Packages:Convert2Dto1D:Wavelength
	NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
	NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
	SVAR CurrentInstrumentGeometry=root:Packages:Convert2Dto1D:CurrentInstrumentGeometry
	SVAR DataFileType=root:Packages:Convert2Dto1D:DataFileType
	SVAR DataFileExtension=root:Packages:Convert2Dto1D:DataFileExtension
	SVAR MaskFileExtension=root:Packages:Convert2Dto1D:MaskFileExtension
	SVAR BlankFileExtension=root:Packages:Convert2Dto1D:BlankFileExtension
	SVAR CurrentMaskFileName=root:Packages:Convert2Dto1D:CurrentMaskFileName
	SVAR CCDDataPath=root:Packages:Convert2Dto1D:CCDDataPath
	SVAR CCDfileName=root:Packages:Convert2Dto1D:CCDfileName
	SVAR CCDFileExtension=root:Packages:Convert2Dto1D:CCDFileExtension
	SVAR FileNameToLoad=root:Packages:Convert2Dto1D:FileNameToLoad
	SVAR ColorTableName=root:Packages:Convert2Dto1D:ColorTableName
	
	//now check the geometry...
	if(SampleToCCDDistance<=0 || Wavelength<=0 || PixelSizeX<=0 || PixelSizeY<=0)
		abort "Experiment geometry not setup correctly"
	endif	
	NVAR StoreDataInIgor= root:Packages:Convert2Dto1D:StoreDataInIgor
	NVAR ExportDataFromIgor= root:Packages:Convert2Dto1D:ExportDataOutOfIgor
	if(ExportDataFromIgor+StoreDataInIgor<1)
		Print "No 1D reduction setting was found... Data are processed, but unless ou save 2D processed image, nothing is saved for you."
	endif
	setDataFolder OldDf
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
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_ImportThisOneFile(SelectedFileToLoad)
	string SelectedFileToLoad

	string OldDf=GetDataFOlder(1)
	setDataFOlder root:Packages:Convert2Dto1D
	SVAR FileNameToLoad=root:Packages:Convert2Dto1D:FileNameToLoad
	FileNameToLoad = SelectedFileToLoad
	SVAR DataFileExtension=root:Packages:Convert2Dto1D:DataFileExtension
	
	EGNA_UniversalLoader("Convert2Dto1DDataPath",SelectedFileToLoad,DataFileExtension,"CCDImageToConvert")
	
	//record import data for future use...
	wave CCDImageToConvert = root:Packages:Convert2Dto1D:CCDImageToConvert
	//allow user function modification to the image through hook function...
		String infostr = FunctionInfo("ModifyImportedImageHook")
		if (strlen(infostr) >0)
			Execute("ModifyImportedImageHook(CCDImageToConvert)")
		endif
	//end of allow user modification of imported image through hook function
	redimension/S CCDImageToConvert
	string NewNote=note(CCDImageToConvert)
	NewNote +="Processed on="+date()+","+time()+";"
	Note/K CCDImageToConvert 
	Note CCDImageToConvert, NewNote 
	MatrixOp/O CCDImageToConvert_dis=CCDImageToConvert
	Note CCDImageToConvert_dis, NewNote
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_DisplayTheRight2DWave()

	string OldDf=GetDataFOlder(1)
	setDataFOlder root:Packages:Convert2Dto1D

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
		
	//EGNA_TopCCDImageUpdateColors(1)

	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_DisplayOneDataSet()
	
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	//Kill top graph with Imge if it exists..
	DoWIndow CCDImageToConvertFig
	if(V_Flag)
		DoWIndow/K CCDImageToConvertFig
	endif
	//now kill the Calibrated wave, since this process will not create one
	Wave/Z Calibrated2DDataSet = root:Packages:Convert2Dto1D:Calibrated2DDataSet
	if(WaveExists(Calibrated2DDataSet))
		KillWaves /Z Calibrated2DDataSet
	endif
	//end set the parameetrs for display...
	NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
	NVAR DisplayRaw2DData=root:Packages:Convert2Dto1D:DisplayRaw2DData
	DisplayProcessed2DData=0
	DisplayRaw2DData=1
	//and disable the controls...
	CheckBox DisplayProcessed2DData,win=EGNA_Convert2Dto1DPanel, disable=2
	
	Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
	if(sum(ListOf2DSampleDataNumbers)<1)
		abort 
	endif	
	Wave/T ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
	string SelectedFileToLoad
	variable i, imax = numpnts(ListOf2DSampleDataNumbers), numLoadedImages=0
	string DataWaveName="CCDImageToConvert"
	string Oldnote=""
	string TempNote=""
	Wave/Z tempWave=root:Packages:Convert2Dto1D:CCDImageToConvertTemp
	if(WaveExists(tempWave))
		KillWaves tempWave
	endif
	For(i=0;i<imax;i+=1)
		if (ListOf2DSampleDataNumbers[i])
			SelectedFileToLoad=ListOf2DSampleData[i]		//this is the file selected to be processed
			EGNA_ImportThisOneFile(SelectedFileToLoad)
			EGNA_DezingerDataSetIfAskedFor(DataWaveName)
			Wave/Z tempWave=root:Packages:Convert2Dto1D:CCDImageToConvertTemp
			Wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
			if(!WaveExists(tempWave))
				OldNote+=note(CCDImageToConvert)
				Duplicate/O CCDImageToConvert, root:Packages:Convert2Dto1D:CCDImageToConvertTemp
				numLoadedImages+=1
				TempNote=note(CCDImageToConvert)
				OldNote+="DataFileName"+num2str(numLoadedImages)+"="+StringByKey("DataFileName", TempNote , "=", ";")+";"
			else
				TempNote=note(CCDImageToConvert)
				MatrixOp/O tempWave=CCDImageToConvert+tempWave
				numLoadedImages+=1
				OldNote+="DataFileName"+num2str(numLoadedImages)+"="+StringByKey("DataFileName", TempNote , "=", ";")+";"
			endif
		endif
	endfor
	OldNote+="NumberOfAveragedFiles="+num2str(numLoadedImages)+";"
	Wave tempWave=root:Packages:Convert2Dto1D:CCDImageToConvertTemp
	redimension/D tempWave
	MatrixOp/O CCDImageToConvert=tempWave/numLoadedImages
	KillWaves/Z tempWave
	note/K CCDImageToConvert
	note CCDImageToConvert, OldNote
		EGNA_DisplayLoadedFile()
		EGNA_DisplayStatsLoadedFile("CCDImageToConvert")
		EGNA_TopCCDImageUpdateColors(1)
		EGNA_DoDrawingsInto2DGraph()
	setDataFolder OldDf
	nvar UseGrazingIncidence = root:Packages:Convert2Dto1D:UseGrazingIncidence
	if(UseGrazingIncidence)
		GI_ReHistImage() 
	endif
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_DisplayStatsLoadedFile(WaveNameStr)
	string WaveNameStr

	string OldDf=GetDataFOlder(1)
	setDataFOlder root:Packages:Convert2Dto1D

	wave basewv=$(WaveNameStr)
	wavestats/Q basewv
	print "Maximum intensity = " +num2str(V_max)
	print "Minimum intensity = " +num2str(V_min)
	//TextBox/C/N=Stats/S=1/F=0/B=1/A=RB "\\K(65280,16384,16384)\\Z10MaxInt="+num2str(V_max)
	setDataFolder OldDf	
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_DisplayLoadedFile()

	string OldDf=GetDataFOlder(1)
	setDataFOlder root:Packages:Convert2Dto1D

	DoWindow CCDImageToConvertFig
	if(V_Flag)
		DoWindow/K CCDImageToConvertFig	
	endif
	wave basewv=root:Packages:Convert2Dto1D:CCDImageToConvert
	// Eliot adding this for Grazing Incidence Warping of image
	duplicate/o basewv, importeddata
	NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
	//if(UseGrazingIncidence)
	//	Gi_ReHistImage()
	//endif
	//end Eliot edit

	wave/Z waveToDisplayDis = $("root:Packages:Convert2Dto1D:CCDImageToConvert_dis")
//	if (!WaveExists(waveToDisplayDis))
//		MatrixOP/O CCDImageToConvert_dis, baseWv
//		wave waveToDisplayDis = $("root:Packages:Convert2Dto1D:CCDImageToConvert_dis")
//	endif
	EGNA_DisplayTheRight2DWave()
	note/K waveToDisplayDis
	note waveToDisplayDis, note(basewv)
	NVAR InvertImages=root:Packages:Convert2Dto1D:InvertImages
	if(InvertImages)
		NewImage/F/K=1 waveToDisplayDis
		ModifyGraph height={Plan,1,left,bottom} //Eliot added this (aspect ratio is fixed) (with with inversion)
	else	
		NewImage/K=1 waveToDisplayDis
		ModifyGraph height={Plan,1,left,top} //Eliot added this (aspect ratio is fixed)
	endif
	ShowInfo
	DoWindow/C CCDImageToConvertFig
	AutoPositionWindow/E/M=0/R=EGNA_Convert2Dto1DPanel CCDImageToConvertFig
	//append naem of the file loaded in...
	string LegendImg=""
	variable NumImages=NumberByKey("NumberOfAveragedFiles", note(waveToDisplayDis) , "=", ";")
	variable i
	if(NumImages>1)
		For(i=1;i<=NumImages;i+=1)
			LegendImg+=StringByKey("DataFileName"+num2str(i), note(waveToDisplayDis) , "=", ";")
			if(i < NumImages)
				 LegendImg+="\r"
			endif 
		endfor
	else
			LegendImg+=StringByKey("DataFileName", note(waveToDisplayDis) , "=", ";")
	endif
	//TextBox/C/N=text0/S=1/B=2/A=LT "\\K(65280,16384,16384)\\Z14"+LegendImg
	
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_DezingerDataSetIfAskedFor(whichFile)
	string whichFile
	
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	NVAR DezingerHowManyTimes=root:Packages:Convert2Dto1D:DezingerHowManyTimes
	NVAR DezingerCCDData =root:Packages:Convert2Dto1D:DezingerCCDData
	NVAR DezingerEmpty =root:Packages:Convert2Dto1D:DezingerEmpty
	NVAR DezingerDarkField =root:Packages:Convert2Dto1D:DezingerDarkField
	
	wave w = $("root:Packages:Convert2Dto1D:"+whichFile)
	variable i
	if (cmpstr(whichFile,"CCDImageToConvert")==0 && DezingerCCDData)
		For(i=0;i<DezingerHowManyTimes;i+=1)
			EGNA_DezingerImage(w)
		endfor
	endif
	if (cmpstr(whichFile,"EmptyData")==0 && DezingerEmpty)
		For(i=0;i<DezingerHowManyTimes;i+=1)
			EGNA_DezingerImage(w)
		endfor
	endif
	if (cmpstr(whichFile,"DarkFieldData")==0 && DezingerDarkField)
		For(i=0;i<DezingerHowManyTimes;i+=1)
			EGNA_DezingerImage(w)
		endfor
	endif
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

//Function EGNA_UpdateMainSliders()
//
//	string oldDf=GetDataFolder(1)
//	setDataFolder root:Packages:Convert2Dto1D
//	NVAR ImageRangeMin=root:Packages:Convert2Dto1D:ImageRangeMin
//	NVAR ImageRangeMax=root:Packages:Convert2Dto1D:ImageRangeMax
//	NVAR ImageRangeMinLimit=root:Packages:Convert2Dto1D:ImageRangeMinLimit
//	NVAR ImageRangeMaxLimit=root:Packages:Convert2Dto1D:ImageRangeMaxLimit
//	
//	wave CCDImageToConvert_dis=root:Packages:Convert2Dto1D:CCDImageToConvert_dis
//	wavestats/Q CCDImageToConvert_dis
//	ImageRangeMin = V_min
//	ImageRangeMax = V_max
//	ImageRangeMinLimit = V_min
//	ImageRangeMaxLimit = V_max
//
//	Slider ImageRangeMin,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0}, win=EGNA_Convert2Dto1DPanel
//	Slider ImageRangeMax,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0}, win=EGNA_Convert2Dto1DPanel
//	EGNA_TopCCDImageUpdateColors(1)
//
//	setDataFolder OldDf
//end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_LoadManyDataSetsForConv()
	
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	//setup controls and display settings...
	//Kill window
	DoWIndow CCDImageToConvertFig
	if(V_Flag)
		DoWIndow/K CCDImageToConvertFig
	endif
	//now kill the Calibrated wave, since this process will create one
	Wave/Z Calibrated2DDataSet = root:Packages:Convert2Dto1D:Calibrated2DDataSet
	if(WaveExists(Calibrated2DDataSet))
		KillWaves /Z Calibrated2DDataSet
	endif
	//end set the parameters for display...
	NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
	NVAR DisplayRaw2DData=root:Packages:Convert2Dto1D:DisplayRaw2DData
	if(DisplayProcessed2DData+DisplayRaw2DData!=1)
		DisplayProcessed2DData=0
		DisplayRaw2DData=1
	endif
	//and enable the controls...
	CheckBox DisplayProcessed2DData,win=EGNA_Convert2Dto1DPanel, disable=0
	
	
	Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
	Wave/T ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
	string SelectedFileToLoad
	variable i, imax = numpnts(ListOf2DSampleDataNumbers)
	string DataWaveName="CCDImageToConvert"
	string DataWaveNameDis="CCDImageToConvert_dis"	//name of copy (lin or log int) for display
	NVAR SampleThickness=root:Packages:Convert2Dto1D:SampleThickness
	NVAR SampleTransmission=root:Packages:Convert2Dto1D:SampleTransmission
	NVAR CorrectionFactor=root:Packages:Convert2Dto1D:CorrectionFactor
	NVAR SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
	NVAR SampleI0=root:Packages:Convert2Dto1D:SampleI0	
	NVAR silentmode = root:Packages:Convert2Dto1D:Silentmode
	SVAR commandstring=root:Packages:Convert2Dto1D:CnvCommandStr
	string extension
	variable timer
	Controlinfo/W=EGNA_Convert2Dto1DPanel   Select2Ddatatype
	extension=S_value
	variable thisisfirsttime=1
	For(i=0;i<imax;i+=1)
		if (ListOf2DSampleDataNumbers[i])
			NVAR average=$("root:Packages:EGN_BSLFiles:BSLaverage")
			NVAR sumframes=$("root:Packages:EGN_BSLFiles:BSLsumframes")
			if(cmpstr(extension,"BSL/SAXS")==0&&sumframes==0&&average==0)
				NVAR saxsframe=$("root:Packages:EGN_BSLFiles:BSLframes")
				NVAR currentframe=$("root:Packages:EGN_BSLFiles:BSLcurrentframe")
			
			
				variable u
				for(u=currentframe;u<saxsframe+1;u+=1)
					currentframe=u
					SelectedFileToLoad=ListOf2DSampleData[i]		//this is the file selected to be processed
					EGNA_ImportThisOneFile(SelectedFileToLoad)	
					EGNA_LoadParamsUsingFncts(SelectedFileToLoad)	
					string Oldnote=""
					Wave/Z CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
					Oldnote=note(CCDImageToConvert)
					OldNote+=EGNA_CalibrationNote()
					note/K CCDImageToConvert
					note CCDImageToConvert, OldNote
					EGNA_DezingerDataSetIfAskedFor(DataWaveName)
					//	EGNA_PrepareLogDataIfWanted(DataWaveName)		//creates the DataWaveNameDis wave...
					if(!silentmode)
						EGNA_DisplayLoadedFile()
						EGNA_TopCCDImageUpdateColors(1)
						EGNA_DoDrawingsInto2DGraph()
					endif
					EGNA_Convert2DTo1D()
					DoUpdate
					Execute /Q/Z commandstring
					if(v_flag==0)
						SetVariable HookNameSV,win=EGNA_Convert2Dto1DPanel,valueColor=(0,26112,0)
						SetVariable HookNameSV,win=EGNA_Convert2Dto1DPanel,valueBackColor=(65535,65535,65535)
					else
						SetVariable HookNameSV,win=EGNA_Convert2Dto1DPanel,valueColor=(65535,65535,65535)
						SetVariable HookNameSV,win=EGNA_Convert2Dto1DPanel,valueBackColor=(52224,0,0)
					endif
				endfor
				currentframe=1
			else
				SelectedFileToLoad=ListOf2DSampleData[i]		//this is the file selected to be processed
				EGNA_ImportThisOneFile(SelectedFileToLoad)
				EGNA_LoadParamsUsingFncts(SelectedFileToLoad)
//				string Oldnote=""
				Wave/Z CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
				Oldnote=note(CCDImageToConvert)
				OldNote+=EGNA_CalibrationNote()
				note/K CCDImageToConvert
				note CCDImageToConvert, OldNote
				EGNA_DezingerDataSetIfAskedFor(DataWaveName)
				
			//	EGNA_PrepareLogDataIfWanted(DataWaveName)		//creates the DataWaveNameDis wave...
				if(!silentmode)
					EGNA_DisplayLoadedFile()
					NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
					if(UseGrazingIncidence)
						GI_ReHistImage()
					endif
					EGNA_DisplayTheRight2DWave()
					EGNA_TopCCDImageUpdateColors(1)
					EGNA_DoDrawingsInto2DGraph()
				else
					if(thisisfirsttime)
						thisisfirsttime=0
						EGNA_Create2DQWave(CCDImageToConvert) // eliot adding this
					endif
				endif
				
				EGNA_Convert2DTo1D()
				
				DoUpdate
				Execute /Q/Z commandstring
				if(v_flag==0)
					SetVariable HookNameSV,win=EGNA_Convert2Dto1DPanel,valueColor=(0,26112,0)
					SetVariable HookNameSV,win=EGNA_Convert2Dto1DPanel,valueBackColor=(65535,65535,65535)
				else
					SetVariable HookNameSV,win=EGNA_Convert2Dto1DPanel,valueColor=(65535,65535,65535)
					SetVariable HookNameSV,win=EGNA_Convert2Dto1DPanel,valueBackColor=(52224,0,0)
				endif
				
			endif
		endif
	endfor
	setDataFolder OldDf
	
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_AveLoadNDataSetsForConv()
	
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	//setup controls and display settings...
	//Kill window
	DoWIndow CCDImageToConvertFig
	if(V_Flag)
		DoWIndow/K CCDImageToConvertFig
	endif
	//now kill the Calibrated wave, since this process will create one
	Wave/Z Calibrated2DDataSet = root:Packages:Convert2Dto1D:Calibrated2DDataSet
	if(WaveExists(Calibrated2DDataSet))
		KillWaves /Z Calibrated2DDataSet
	endif
	//end set the parameters for display...
	NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
	NVAR DisplayRaw2DData=root:Packages:Convert2Dto1D:DisplayRaw2DData
	if(DisplayProcessed2DData+DisplayRaw2DData!=1)
		DisplayProcessed2DData=0
		DisplayRaw2DData=1
	endif
	//and enable the controls...
	CheckBox DisplayProcessed2DData,win=EGNA_Convert2Dto1DPanel, disable=0


	Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
	Wave/T ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
	string SelectedFileToLoad
	variable i, imax = numpnts(ListOf2DSampleDataNumbers)
	variable numLoadedImages=0
	NVAR ProcessNImagesAtTime=root:Packages:Convert2Dto1D:ProcessNImagesAtTime
	string Oldnote=""
	string TempNote=""
	string DataWaveName="CCDImageToConvert"
	string DataWaveNameDis="CCDImageToConvert_dis"	//name of copy (lin or log int) for display
	Wave/Z CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
	if(WaveExists(CCDImageToConvert))
		DoWindow CCDImageToConvertFig
		if(V_Flag)
			DoWindow/K CCDImageToConvertFig
		endif
		KillWaves CCDImageToConvert
	endif
		NVAR SampleThickness=root:Packages:Convert2Dto1D:SampleThickness
		NVAR SampleTransmission=root:Packages:Convert2Dto1D:SampleTransmission
		NVAR CorrectionFactor=root:Packages:Convert2Dto1D:CorrectionFactor
		NVAR SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
		NVAR SampleI0=root:Packages:Convert2Dto1D:SampleI0
	variable LocSampleThickness=0
	variable LocSampleTransmission=0
	variable LocCorrectionFactor=0
	variable LocSampleMeasurementTime=0
	variable LocSampleI0=0
	variable j=0, Loaded=0
	NVAR SkipBadFiles=root:Packages:Convert2Dto1D:SkipBadFiles
	NVAR MaxIntForBadFile=root:Packages:Convert2Dto1D:MaxIntForBadFile
	//need to averaged 5 parameters above...
	For(i=0;i<imax;i+=1)
		Loaded=0
		Oldnote=""
		numLoadedImages=0
		 LocSampleThickness=0
		 LocSampleTransmission=0
		 LocCorrectionFactor=0
		 LocSampleMeasurementTime=0
		 LocSampleI0=0
		 if(ListOf2DSampleDataNumbers[i])
			For(j=0;j<ProcessNImagesAtTime;j+=1)
				if (ListOf2DSampleDataNumbers[i+j])
					SelectedFileToLoad=ListOf2DSampleData[i+j]		//this is the file selected to be processed
					EGNA_ImportThisOneFile(SelectedFileToLoad)
					if(SkipBadFiles)
						Wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
						wavestats/Q CCDImageToConvert
					endif
					if(!SkipBadFiles || (SkipBadFiles && MaxIntForBadFile<=V_max))
						EGNA_LoadParamsUsingFncts(SelectedFileToLoad)	//thsi will call user functions which get sample parameters, if exist
							 LocSampleThickness+=SampleThickness
							 LocSampleTransmission+=SampleTransmission
							 LocCorrectionFactor+=CorrectionFactor
							 LocSampleMeasurementTime+=SampleMeasurementTime
							 LocSampleI0+=SampleI0
						EGNA_DezingerDataSetIfAskedFor(DataWaveName)
						Wave/Z tempWave=root:Packages:Convert2Dto1D:CCDImageToConvertTemp
						Wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
						if(!WaveExists(tempWave))
							OldNote+=note(CCDImageToConvert)
							Duplicate/O CCDImageToConvert, root:Packages:Convert2Dto1D:CCDImageToConvertTemp
							numLoadedImages+=1
							TempNote=note(CCDImageToConvert)
							OldNote+="DataFileName"+num2str(numLoadedImages)+"="+StringByKey("DataFileName", TempNote , "=", ";")+";"
						else
							TempNote=note(CCDImageToConvert)
							MatrixOp/O tempWave=CCDImageToConvert+tempWave
							numLoadedImages+=1
							OldNote+="DataFileName"+num2str(numLoadedImages)+"="+StringByKey("DataFileName", TempNote , "=", ";")+";"
						endif
						Loaded=1
					endif
				endif
			endfor
			i=i+j	-1
			if(Loaded)
				OldNote+="NumberOfAveragedFiles="+num2str(numLoadedImages)+";"
				Wave tempWave=root:Packages:Convert2Dto1D:CCDImageToConvertTemp
					SampleThickness= LocSampleThickness/numLoadedImages
					SampleTransmission= LocSampleTransmission/numLoadedImages
					CorrectionFactor= LocCorrectionFactor/numLoadedImages
					SampleMeasurementTime= LocSampleMeasurementTime/numLoadedImages
					SampleI0= LocSampleI0/numLoadedImages
				OldNote+=EGNA_CalibrationNote()
			
				MatrixOp/O CCDImageToConvert=tempWave/numLoadedImages
				KillWaves/Z tempWave
				note/K CCDImageToConvert
				note CCDImageToConvert, OldNote
				EGNA_DisplayLoadedFile()
				EGNA_DisplayTheRight2DWave()
			//	EGNA_TopCCDImageUpdateColors(1)
				EGNA_DoDrawingsInto2DGraph()
				EGNA_Convert2DTo1D()
				DoUpdate
			endif
		endif
	endfor

	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_AveLoadManyDataSetsForConv()
	
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	//setup controls and display settings...
	//Kill window
	DoWIndow CCDImageToConvertFig
	if(V_Flag)
		DoWIndow/K CCDImageToConvertFig
	endif
	//now kill the Calibrated wave, since this process will create one
	Wave/Z Calibrated2DDataSet = root:Packages:Convert2Dto1D:Calibrated2DDataSet
	if(WaveExists(Calibrated2DDataSet))
		KillWaves /Z Calibrated2DDataSet
	endif
	//end set the parameters for display...
	NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
	NVAR DisplayRaw2DData=root:Packages:Convert2Dto1D:DisplayRaw2DData
	if(DisplayProcessed2DData+DisplayRaw2DData!=1)
		DisplayProcessed2DData=0
		DisplayRaw2DData=1
	endif
	//and enable the controls...
	CheckBox DisplayProcessed2DData,win=EGNA_Convert2Dto1DPanel, disable=0


	Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
	Wave/T ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
	string SelectedFileToLoad
	variable i, imax = numpnts(ListOf2DSampleDataNumbers)
	variable numLoadedImages=0
	string Oldnote=""
	string TempNote=""
	string DataWaveName="CCDImageToConvert"
	string DataWaveNameDis="CCDImageToConvert_dis"	//name of copy (lin or log int) for display
	Wave/Z CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
	if(WaveExists(CCDImageToConvert))
		DoWindow CCDImageToConvertFig
		if(V_Flag)
			DoWindow/K CCDImageToConvertFig
		endif
		KillWaves CCDImageToConvert
	endif
		NVAR SampleThickness=root:Packages:Convert2Dto1D:SampleThickness
		NVAR SampleTransmission=root:Packages:Convert2Dto1D:SampleTransmission
		NVAR CorrectionFactor=root:Packages:Convert2Dto1D:CorrectionFactor
		NVAR SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
		NVAR SampleI0=root:Packages:Convert2Dto1D:SampleI0
	variable LocSampleThickness=0
	variable LocSampleTransmission=0
	variable LocCorrectionFactor=0
	variable LocSampleMeasurementTime=0
	variable LocSampleI0=0
	NVAR SkipBadFiles=root:Packages:Convert2Dto1D:SkipBadFiles
	NVAR MaxIntForBadFile=root:Packages:Convert2Dto1D:MaxIntForBadFile
	//need to averaged 5 parameters above...
	For(i=0;i<imax;i+=1)
		if (ListOf2DSampleDataNumbers[i])
			SelectedFileToLoad=ListOf2DSampleData[i]		//this is the file selected to be processed
			EGNA_ImportThisOneFile(SelectedFileToLoad)
			if(SkipBadFiles)
				Wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
				wavestats/Q CCDImageToConvert
			endif
				if(!SkipBadFiles || (SkipBadFiles && MaxIntForBadFile<=V_max))
				EGNA_LoadParamsUsingFncts(SelectedFileToLoad)	//thsi will call user functions which get sample parameters, if exist
					 LocSampleThickness+=SampleThickness
					 LocSampleTransmission+=SampleTransmission
					 LocCorrectionFactor+=CorrectionFactor
					 LocSampleMeasurementTime+=SampleMeasurementTime
					 LocSampleI0+=SampleI0
				EGNA_DezingerDataSetIfAskedFor(DataWaveName)
				Wave/Z tempWave=root:Packages:Convert2Dto1D:CCDImageToConvertTemp
				Wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert
				if(!WaveExists(tempWave))
					OldNote+=note(CCDImageToConvert)
					Duplicate/O CCDImageToConvert, root:Packages:Convert2Dto1D:CCDImageToConvertTemp
					numLoadedImages+=1
					TempNote=note(CCDImageToConvert)
					OldNote+="DataFileName"+num2str(numLoadedImages)+"="+StringByKey("DataFileName", TempNote , "=", ";")+";"
				else
					TempNote=note(CCDImageToConvert)
					MatrixOp/O tempWave=CCDImageToConvert+tempWave
					numLoadedImages+=1
					OldNote+="DataFileName"+num2str(numLoadedImages)+"="+StringByKey("DataFileName", TempNote , "=", ";")+";"
				endif
			endif
		endif
	endfor
	OldNote+="NumberOfAveragedFiles="+num2str(numLoadedImages)+";"
	Wave tempWave=root:Packages:Convert2Dto1D:CCDImageToConvertTemp
		SampleThickness= LocSampleThickness/numLoadedImages
		SampleTransmission= LocSampleTransmission/numLoadedImages
		CorrectionFactor= LocCorrectionFactor/numLoadedImages
		SampleMeasurementTime= LocSampleMeasurementTime/numLoadedImages
		SampleI0= LocSampleI0/numLoadedImages
	OldNote+=EGNA_CalibrationNote()

	MatrixOp/O CCDImageToConvert=tempWave/numLoadedImages
	KillWaves/Z tempWave
	note/K CCDImageToConvert
	note CCDImageToConvert, OldNote
	EGNA_DisplayLoadedFile()
	EGNA_DisplayTheRight2DWave()
	//EGNA_TopCCDImageUpdateColors(1)
	EGNA_DoDrawingsInto2DGraph()
	EGNA_Convert2DTo1D()
	DoUpdate
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function/S EGNA_CalibrationNote()

	string newNote=""
		NVAR UseSampleThickness=root:Packages:Convert2Dto1D:UseSampleThickness
		NVAR UseSampleThicknFnct=root:Packages:Convert2Dto1D:UseSampleThicknFnct
		SVAR SampleThicknFnct=root:Packages:Convert2Dto1D:SampleThicknFnct
		NVAR SampleThickness=root:Packages:Convert2Dto1D:SampleThickness
		if(UseSampleThickness && UseSampleThicknFnct)
			newNote+="SampleThicknFnct="+SampleThicknFnct+";"
		endif
		newNote+="SampleThickness="+num2str(SampleThickness)+";"

		NVAR UseSampleTransmission=root:Packages:Convert2Dto1D:UseSampleTransmission
		NVAR UseSampleTransmFnct=root:Packages:Convert2Dto1D:UseSampleTransmFnct
		SVAR SampleTransmFnct=root:Packages:Convert2Dto1D:SampleTransmFnct
		NVAR SampleTransmission=root:Packages:Convert2Dto1D:SampleTransmission
		if(UseSampleTransmission && UseSampleThicknFnct)
			newNote+="SampleTransmFnct="+SampleTransmFnct+";"
		endif
		newNote+="SampleTransmission="+num2str(SampleTransmission)+";"
		
		NVAR UseCorrectionFactor=root:Packages:Convert2Dto1D:UseCorrectionFactor
		NVAR CorrectionFactor=root:Packages:Convert2Dto1D:CorrectionFactor
		NVAR UseSampleCorrectFnct=root:Packages:Convert2Dto1D:UseSampleCorrectFnct
		SVAR SampleCorrectFnct=root:Packages:Convert2Dto1D:SampleCorrectFnct
		if(UseCorrectionFactor && UseSampleCorrectFnct)
			newNote+="SampleCorrectFnct="+SampleCorrectFnct+";"
		endif
		newNote+="h="+num2str(CorrectionFactor)+";"
		
		NVAR UseSampleMeasTime=root:Packages:Convert2Dto1D:UseSampleMeasTime
		NVAR UseSampleMeasTimeFnct=root:Packages:Convert2Dto1D:UseSampleMeasTimeFnct
		SVAR SampleMeasTimeFnct=root:Packages:Convert2Dto1D:SampleMeasTimeFnct
		NVAR SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
		if(UseSampleMeasTime && UseSampleMeasTimeFnct)
			newNote+="SampleMeasTimeFnct="+SampleMeasTimeFnct+";"
		endif
		newNote+="SampleMeasurementTime="+num2str(SampleMeasurementTime)+";"

		NVAR UseEmptyMeasTime=root:Packages:Convert2Dto1D:UseEmptyMeasTime
		NVAR UseEmptyTimeFnct=root:Packages:Convert2Dto1D:UseEmptyTimeFnct
		SVAR EmptyTimeFnct=root:Packages:Convert2Dto1D:EmptyTimeFnct
		NVAR EmptyMeasurementTime=root:Packages:Convert2Dto1D:EmptyMeasurementTime
		if(UseEmptyMeasTime && UseEmptyTimeFnct)
			newNote+="EmptyTimeFnct="+EmptyTimeFnct+";"
		endif
		newNote+="EmptyMeasurementTime="+num2str(EmptyMeasurementTime)+";"
		
		NVAR UseDarkMeasTime=root:Packages:Convert2Dto1D:UseDarkMeasTime
		NVAR UseBackgTimeFnct=root:Packages:Convert2Dto1D:UseBackgTimeFnct
		SVAR BackgTimeFnct=root:Packages:Convert2Dto1D:BackgTimeFnct
		NVAR BackgroundMeasTime=root:Packages:Convert2Dto1D:BackgroundMeasTime
		if(UseDarkMeasTime && UseBackgTimeFnct)
			newNote+="BackgTimeFnct="+BackgTimeFnct+";"
		endif
		newNote+="BackgroundMeasTime="+num2str(BackgroundMeasTime)+";"

		NVAR UseI0ToCalibrate=root:Packages:Convert2Dto1D:UseI0ToCalibrate
		NVAR UseSampleMonitorFnct=root:Packages:Convert2Dto1D:UseSampleMonitorFnct
		SVAR SampleMonitorFnct=root:Packages:Convert2Dto1D:SampleMonitorFnct
		NVAR SampleI0=root:Packages:Convert2Dto1D:SampleI0
		if(UseI0ToCalibrate && UseSampleMonitorFnct)
			newNote+="SampleMonitorFnct="+SampleMonitorFnct+";"
		endif
		newNote+="SampleI0="+num2str(SampleI0)+";"
			
		NVAR UseMonitorForEF=root:Packages:Convert2Dto1D:UseMonitorForEF
		NVAR UseEmptyMonitorFnct=root:Packages:Convert2Dto1D:UseEmptyMonitorFnct
		SVAR EmptyMonitorFnct=root:Packages:Convert2Dto1D:EmptyMonitorFnct
		NVAR EmptyI0=root:Packages:Convert2Dto1D:EmptyI0
		if(UseMonitorForEF && UseEmptyMonitorFnct)
			newNote+="EmptyMonitorFnct="+EmptyMonitorFnct+";"
		endif
		newNote+="EmptyI0="+num2str(EmptyI0)+";"

	return newnote
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_LoadParamsUsingFncts(SelectedFileToLoad)
	string SelectedFileToLoad
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

		variable/g temp
		
		NVAR UseSampleThickness=root:Packages:Convert2Dto1D:UseSampleThickness
		NVAR UseSampleThicknFnct=root:Packages:Convert2Dto1D:UseSampleThicknFnct
		SVAR SampleThicknFnct=root:Packages:Convert2Dto1D:SampleThicknFnct
		NVAR SampleThickness=root:Packages:Convert2Dto1D:SampleThickness
		if(UseSampleThickness && UseSampleThicknFnct)
			Execute("root:Packages:Convert2Dto1D:temp = "+SampleThicknFnct+"(\""+SelectedFileToLoad+"\")")
			if(numtype(temp)!=0 || temp<=0)
				Abort "Thickness function returned NaN or thickness <=0"
			endif
			SampleThickness=temp
		endif
		
		NVAR UseSampleTransmission=root:Packages:Convert2Dto1D:UseSampleTransmission
		NVAR UseSampleTransmFnct=root:Packages:Convert2Dto1D:UseSampleTransmFnct
		SVAR SampleTransmFnct=root:Packages:Convert2Dto1D:SampleTransmFnct
		NVAR SampleTransmission=root:Packages:Convert2Dto1D:SampleTransmission
		if(UseSampleTransmission && UseSampleTransmFnct)
			Execute("root:Packages:Convert2Dto1D:temp ="+SampleTransmFnct+"(\""+SelectedFileToLoad+"\")")
			if(numtype(temp)!=0 || temp<=0)// || temp >1.5)
				Abort "Transmission function returned NaN or value <=0 or >1.5"
			endif
			SampleTransmission=temp
		endif
		
		NVAR UseCorrectionFactor=root:Packages:Convert2Dto1D:UseCorrectionFactor
		NVAR CorrectionFactor=root:Packages:Convert2Dto1D:CorrectionFactor
		NVAR UseSampleCorrectFnct=root:Packages:Convert2Dto1D:UseSampleCorrectFnct
		SVAR SampleCorrectFnct=root:Packages:Convert2Dto1D:SampleCorrectFnct
		if(UseCorrectionFactor && UseSampleCorrectFnct)
			Execute("root:Packages:Convert2Dto1D:temp ="+SampleCorrectFnct+"(\""+SelectedFileToLoad+"\")")
			if(numtype(temp)!=0 || temp<=0)
				Abort "Correction factor function returned NaN or value <=0"
			endif
			CorrectionFactor=temp
		endif
		
		NVAR UseSampleMeasTime=root:Packages:Convert2Dto1D:UseSampleMeasTime
		NVAR UseSampleMeasTimeFnct=root:Packages:Convert2Dto1D:UseSampleMeasTimeFnct
		SVAR SampleMeasTimeFnct=root:Packages:Convert2Dto1D:SampleMeasTimeFnct
		NVAR SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
		if(UseSampleMeasTime && UseSampleMeasTimeFnct)
			Execute("root:Packages:Convert2Dto1D:temp ="+SampleMeasTimeFnct+"(\""+SelectedFileToLoad+"\")")
			if(numtype(temp)!=0 || temp<=0)
				Abort "Sample measurement time factor function returned NaN or value <=0"
			endif
			SampleMeasurementTime=temp
		endif

		NVAR UseEmptyMeasTime=root:Packages:Convert2Dto1D:UseEmptyMeasTime
		NVAR UseEmptyTimeFnct=root:Packages:Convert2Dto1D:UseEmptyTimeFnct
		SVAR EmptyTimeFnct=root:Packages:Convert2Dto1D:EmptyTimeFnct
		NVAR EmptyMeasurementTime=root:Packages:Convert2Dto1D:EmptyMeasurementTime
		if(UseEmptyMeasTime && UseEmptyTimeFnct)
			Execute("root:Packages:Convert2Dto1D:temp ="+EmptyTimeFnct+"(\""+SelectedFileToLoad+"\")")
			if(numtype(temp)!=0 || temp<=0)
				Abort "Empty beam measurement time factor function returned NaN or value <=0"
			endif
			EmptyMeasurementTime=temp
		endif
		
		NVAR UseDarkMeasTime=root:Packages:Convert2Dto1D:UseDarkMeasTime
		NVAR UseBackgTimeFnct=root:Packages:Convert2Dto1D:UseBackgTimeFnct
		SVAR BackgTimeFnct=root:Packages:Convert2Dto1D:BackgTimeFnct
		NVAR BackgroundMeasTime=root:Packages:Convert2Dto1D:BackgroundMeasTime
		if(UseDarkMeasTime && UseBackgTimeFnct)
			Execute("root:Packages:Convert2Dto1D:temp ="+BackgTimeFnct+"(\""+SelectedFileToLoad+"\")")
			if(numtype(temp)!=0 || temp<=0)
				Abort "Dark field measurement time factor function returned NaN or value <=0"
			endif
			BackgroundMeasTime=temp
		endif

		NVAR UseI0ToCalibrate=root:Packages:Convert2Dto1D:UseI0ToCalibrate
		NVAR UseSampleMonitorFnct=root:Packages:Convert2Dto1D:UseSampleMonitorFnct
		SVAR SampleMonitorFnct=root:Packages:Convert2Dto1D:SampleMonitorFnct
		NVAR SampleI0=root:Packages:Convert2Dto1D:SampleI0
		if(UseI0ToCalibrate && UseSampleMonitorFnct)
			Execute("root:Packages:Convert2Dto1D:temp ="+SampleMonitorFnct+"(\""+SelectedFileToLoad+"\")")
			if(numtype(temp)!=0 || temp<=0)
				Abort "Sample monitor count function returned NaN or value <=0"
			endif
			SampleI0=temp
		endif
			
		NVAR UseMonitorForEF=root:Packages:Convert2Dto1D:UseMonitorForEF
		NVAR UseEmptyMonitorFnct=root:Packages:Convert2Dto1D:UseEmptyMonitorFnct
		SVAR EmptyMonitorFnct=root:Packages:Convert2Dto1D:EmptyMonitorFnct
		NVAR EmptyI0=root:Packages:Convert2Dto1D:EmptyI0
		if(UseMonitorForEF && UseEmptyMonitorFnct)
			Execute("root:Packages:Convert2Dto1D:temp ="+EmptyMonitorFnct+"(\""+SelectedFileToLoad+"\")")
			if(numtype(temp)!=0 || temp<=0)
				Abort "Empty beam monitor count function returned NaN or value <=0"
			endif
			EmptyI0=temp
		endif
		
	
	setDataFolder OldDf

end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_ExportDisplayedImage()
	
	string OldDf=GetDataFolder(1)
	setDataFOlder root:Packages:Convert2Dto1D
	WAVE/Z ww=root:Packages:Convert2Dto1D:CCDImageToConvert_dis
	NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
	if(WaveExists(ww)==0)
		Abort "Something is wrong here"
	endif
	SVAR FileNameToLoad=root:Packages:Convert2Dto1D:FileNameToLoad
	string  SaveFileName=FileNameToLoad[0,25]+"_mod.tif"
	Prompt SaveFileName, "Input file name for file to save"
	DoPrompt "Correct file name to use for saving this file", SaveFileName
	if(V_Flag)
		abort
	endif
	if (strlen(SaveFileName)==0)
		abort "No name specified"
	endif
		//print SaveFileName[strlen(SaveFileName)-4,inf]
	if(cmpstr(SaveFileName[strlen(SaveFileName)-4,inf],".tif")!=0)
		SaveFileName+=".tif"
	endif
	string ListOfFilesThere
	ListOfFilesThere=IndexedFile(Convert2Dto1DDataPath,-1,".tif")
	if(stringMatch(ListOfFilesThere,"*"+SaveFileName+"*"))
		DoAlert 1, "File with this name exists, overwrite?"
		if(V_Flag!=1)
			abort
		endif	
	endif
	Duplicate/O ww, wwtemp
	Redimension/S wwtemp
	//Redimension/W/U wwtemp		//this converts to unsigned 16 bit word... needed for export. It correctly rounds.... 
	if(!DisplayProcessed2DData)	//raw data, these are integers...	
		ImageSave/P=Convert2Dto1DDataPath/F/T="TIFF"/O wwtemp SaveFileName			//we save that as single precision float anyway...
	else			//processed, this is real data... 
		ImageSave/P=Convert2Dto1DDataPath/F/T="TIFF"/O wwtemp SaveFileName			// this is single precision float..  
	endif
	//ImageSave/D=16/T="TIFF"/O/P=Convert2Dto1DDataPath wwtemp SaveFileName
	KilLWaves wwtemp
	EGNA_UpdateDataListBox()
	SetDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_SaveDisplayedImage()
	
	string OldDf=GetDataFolder(1)
	setDataFOlder root:Packages:Convert2Dto1D
	WAVE/Z ww=root:Packages:Convert2Dto1D:CCDImageToConvert_dis
	NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
	if(WaveExists(ww)==0)
		Abort "Image does not exist"
	endif
	SVAR FileNameToLoad=root:Packages:Convert2Dto1D:FileNameToLoad
	string  SaveFileName=FileNameToLoad[0,30]
	string precision="Unsigned Integer"		//default value, but for processed data we need to have at least single precision..
	Prompt precision, "Precision for wave to save", popup, "Unsigned Integer;Signed Integer;Single;Double;"
	if(DisplayProcessed2DData)
		precision="Single"
		Prompt precision, "Precision for wave to save", popup, "Single;Double;"
	endif
	string MakeImage="no"
	Prompt SaveFileName, "Input file name for file to save"
	Prompt MakeImage, "Make Image?", popup, "no;yes;"
	DoPrompt "Saving this image", SaveFileName, precision, MakeImage
	if(V_Flag)
		abort
	endif
	if (strlen(SaveFileName)==0)
		abort "No name specified"
	endif
		//print SaveFileName[strlen(SaveFileName)-4,inf]
	string ListOfFilesThere
	setDataFolder root:
	NewDataFolder/O/S SavedImages
	wave/Z testme=$(SaveFileName)
	if(WaveExists(testme))
		DoAlert 1, "Image of this name already exists, overwrite?"
		if(V_Flag==2)
			abort
		endif
	endif
	Duplicate/O ww, $(SaveFileName)
	Wave NewWv=$(SaveFileName)
	if(cmpstr(precision,"Unsigned Integer")==0)
		Redimension/U/W NewWv
	elseif(cmpstr(precision,"Signed Integer")==0)
		Redimension/W NewWv
	elseif(cmpstr(precision,"Single")==0)
		Redimension/S NewWv
	elseif(cmpstr(precision,"Double")==0)
		Redimension/D NewWv
	endif
	if(cmpstr(MakeImage,"yes")==0)
		NVAR InvertImages=root:Packages:Convert2Dto1D:InvertImages
		if(InvertImages)
			NewImage/F/K=1 NewWv
			ModifyGraph height={Plan,1,left,bottom}
		else
			NewImage/K=1 NewWv
			ModifyGraph height={Plan,1,left,top}
		endif
		string SavedImage=UniqueName("SavedImage", 6, 0)
		
		DoWindow/C/T $(SavedImage),SaveFileName
	endif
	SetDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_PrepareLogDataIfWanted(DataWaveName)
	string DataWaveName

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	wave waveToDisplay = $("root:Packages:Convert2Dto1D:"+DataWaveName)
	Duplicate/O waveToDisplay, $("root:Packages:Convert2Dto1D:"+DataWaveName+"_dis")
	wave waveToDisplayDis= $("root:Packages:Convert2Dto1D:"+DataWaveName+"_dis")
	Redimension/S waveToDisplayDis
	NVAR ImageDisplayLogScaled=root:Packages:Convert2Dto1D:ImageDisplayLogScaled
		if(ImageDisplayLogScaled)
			MatrixOp/O waveToDisplayDis = log(waveToDisplay)
		else
			MatrixOp/O waveToDisplayDis = waveToDisplay
		endif
	setDataFolder OldDF
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_LoadEmptyOrDark(EmptyOrDark)
	string EmptyOrDark
	//check the parameters for conversion
	
	string OldDf=getDataFolder(1)
	setDataFolder root:Packages:Convert2Dto1D
	SVAR DataFileExtension=root:Packages:Convert2Dto1D:DataFileExtension
	SVAR BlankFileExtension=root:Packages:Convert2Dto1D:BlankFileExtension
	string FileExtLocal
	
	//for now !!!!!!!!!!!!!!!!
	//BlankFileExtension = DataFileExtension
	FileExtLocal=DataFileExtension
	
	Wave/T ListOf2DEmptyData=root:Packages:Convert2Dto1D:ListOf2DEmptyData
	string SelectedFileToLoad
	controlInfo /W=EGNA_Convert2Dto1DPanel Select2DMaskDarkWave
	variable selection = V_Value
	if(selection<0)
		setDataFolder OldDf
		abort
	endif
	DoWindow EMptyOrDarkImage
	if(V_Flag)
		DoWindow/K EMptyOrDarkImage
	endif
	SVAR CurrentEmptyName
	SVAR CurrentDarkFieldName
	SVAR CurrentPixSensFile
	string FileNameToLoad=ListOf2DEmptyData[selection]
	string NewWaveName
		if(numtype(strlen(FileNameToLoad))!=0)		//abort if user did nto select anything in the box
			abort
		endif
	if(cmpstr(EmptyOrDark,"Empty")==0)
		CurrentEmptyName = FileNameToLoad
		NewWaveName = "EmptyData"
	elseif(cmpstr(EmptyOrDark,"Pixel2DSensitivity")==0)
		CurrentPixSensFile = FileNameToLoad
		NewWaveName = "Pixel2DSensitivity"
		FileExtLocal="tiff"
	else
		CurrentDarkFieldName= FileNameToLoad
		NewWaveName = "DarkFieldData"
		//eliot - can we add a switch here for the exposure time? no
	endif

	EGNA_UniversalLoader("Convert2Dto1DEmptyDarkPath",FileNameToLoad,FileExtLocal,NewWaveName)

	EGNA_DezingerDataSetIfAskedFor(NewWaveName)
	
	//eliot - we can read the exposure time now and duplicate the loaded data accordingly
	if(!cmpstr("DarkFieldData",newwavename))
		//get exposure time from header
		nvar SampleMeasurementTime=root:Packages:Convert2Dto1D:SampleMeasurementTime
		duplicate/o $("root:Packages:Convert2Dto1D:Darkfielddata"),$("root:Packages:Convert2Dto1D:Darkfielddata" + "_"+replacestring(".",num2str(samplemeasurementtime),"p") )
		newwavename += "_"+replacestring(".",num2str(samplemeasurementtime),"p") 
	endif
	//eliot - end

	wave NewCCDData = $(NewWaveName)

	//allow user function modification to the image through hook function...
		String infostr = FunctionInfo("ModifyImportedImageHook")
		if (strlen(infostr) >0)
			Execute("ModifyImportedImageHook("+NewWaveName+")")
		endif
	//end of allow user modification of imported image through hook function

	duplicate/O NewCCDData, $(NewWaveName+"_dis")
	wave NewCCDDataDis=$(NewWaveName+"_dis")
	redimension/S NewCCDDataDis
	NVAR ImageDisplayLogScaled=root:Packages:Convert2Dto1D:ImageDisplayLogScaled
	if(ImageDisplayLogScaled)
		MatrixOp/O NewCCDDataDis=log(NewCCDData)
	else
		MatrixOp/O NewCCDDataDis=NewCCDData
	endif
	NVAR InvertImages=root:Packages:Convert2Dto1D:InvertImages
	if(InvertImages)
		NewImage/F/K=1 NewCCDDataDis
		ModifyGraph height={Plan,1,left,bottom}
	else	
		NewImage/K=1 NewCCDDataDis
		ModifyGraph height={Plan,1,left,top}
	endif
	DoWindow/C EmptyOrDarkImage
	AutoPositionWindow/E/M=0/R=EGNA_Convert2Dto1DPanel EmptyOrDarkImage
	EGNA_TopCCDImageUpdateColors(1)
	setDataFolder OldDf
end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_DisplayOneDataSets()
	//check the parameters for conversion

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	
	Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
	Wave/T ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
	string SelectedFileToLoad
	variable i, imax = numpnts(ListOf2DSampleDataNumbers)
	For(i=0;i<imax;i+=1)
		if (ListOf2DSampleDataNumbers[i])
			SelectedFileToLoad=ListOf2DSampleData[i]		//this is the file selected to be processed
			EGNA_ImportThisOneFile(SelectedFileToLoad)
			abort
		endif
	endfor
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_LoadMask()

	string OldDf=GetDataFOlder(1)
	setDataFOlder root:Packages:Convert2Dto1D
	Wave/T  ListOf2DMaskData=root:Packages:Convert2Dto1D:ListOf2DMaskData
	SVAR CurrentMaskFileName=root:Packages:Convert2Dto1D:CurrentMaskFileName

	controlInfo /W=EGNA_Convert2Dto1DPanel MaskListBoxSelection
	variable selection = V_Value
	if(selection<0)
		setDataFolder OldDf
		abort
	endif
	SVAR FileNameToLoad
	FileNameToLoad=ListOf2DMaskData[selection]

	EGNA_UniversalLoader("Convert2Dto1DMaskPath",FileNameToLoad,"tiff","M_ROIMask")

	CurrentMaskFileName = FileNameToLoad
	wave M_ROIMask
	Redimension/B/U M_ROIMask
	M_ROIMask=M_ROIMask>0.5 ? 1 : 0
	duplicate/o M_ROIMASK, loadedmask //for image transformations such as grazing incidence later
	setDataFolder oldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_UpdateDataListBox()		

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
		Wave/T  ListOf2DSampleData=root:Packages:Convert2Dto1D:ListOf2DSampleData
		Wave ListOf2DSampleDataNumbers=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
		SVAR DataFileExtension=root:Packages:Convert2Dto1D:DataFileExtension
		SVAR SampleNameMatchStr = root:Packages:Convert2Dto1D:SampleNameMatchStr
		string realExtension, realext2=""		//set to real extension for data types with weird extensions...
		if(cmpstr(DataFileExtension, ".tif")==0 || cmpstr(DataFileExtension,"BS_Suitcase_Tiff")==0)
			realExtension=".tif"
			realext2 = ".tiff"
		elseif(cmpstr(DataFileExtension, "ADSC")==0)
			realExtension=".img"
		elseif(cmpstr(DataFileExtension, ".fits")==0)
			realExtension=".fits"
		elseif(cmpstr(DataFileExtension, "ibw")==0)
			realExtension=".ibw"
		elseif(cmpstr(DataFileExtension, "DND/txt")==0)
			realExtension=".txt"
		else
			realExtension="????"
		endif
		string ListOfAvailableCompounds
		PathInfo Convert2Dto1DDataPath
		if(V_Flag)	//path exists...
			ListOfAvailableCompounds=IndexedFile(Convert2Dto1DDataPath,-1,realExtension)	
			if(strlen(realext2)>0)
				ListOfAvailableCompounds+=IndexedFile(Convert2Dto1DDataPath,-1,realext2)
				ListOfAvailableCompounds = sortlist(ListOfAvailableCompounds, ";", 16)
			endif
		
			
			if(strlen(ListOfAvailableCompounds)<2)	//none found
				ListOfAvailableCompounds="--none--;"
			endif
			ListOfAvailableCompounds=EGNA_CleanListOfFilesForTypes(ListOfAvailableCompounds,DataFileExtension,SampleNameMatchStr)
			redimension/N=(ItemsInList(ListOfAvailableCompounds)) ListOf2DSampleData
			redimension/N=(ItemsInList(ListOfAvailableCompounds)) ListOf2DSampleDataNumbers
			EGNA_CreateListOfFiles(ListOf2DSampleData,ListOfAvailableCompounds,realExtension,"")
			sort ListOf2DSampleData, ListOf2DSampleData, ListOf2DSampleDataNumbers
			ListOf2DSampleDataNumbers=0
			
			DoWindow EGNA_Convert2Dto1DPanel
			if(V_Flag)
				ListBox Select2DInputWave win=EGNA_Convert2Dto1DPanel,listWave=root:Packages:Convert2Dto1D:ListOf2DSampleData, row=0,selRow= 0
				ListBox Select2DInputWave win=EGNA_Convert2Dto1DPanel,selWave=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
				PopupMenu SelectStartOfRange,win=EGNA_Convert2Dto1DPanel,popvalue="---",value= #"EGNA_Create2DSelectionPopup()"
				PopupMenu SelectEndOfRange,win=EGNA_Convert2Dto1DPanel,popvalue="---",value= #"EGNA_Create2DSelectionPopup()"
			endif
		endif
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function/T EGNA_CleanListOfFilesForTypes(ListOfAvailableCompounds,DataFileType, MatchString)
	string ListOfAvailableCompounds,DataFileType, MatchString
	
	variable i, imax, numberOfFile
	if(strlen(ListOfAvailableCompounds)<2)
		return ""
	endif
	imax = itemsInList(ListOfAvailableCompounds)
	if (imax==0)
		return ""
	endif
	string result, tempFileName
	result=""
	For(i=0;i<imax;i+=1)
		tempFileName = stringFromList(i,ListOfAvailableCompounds)
			if(strlen(MatchString)==0 || stringmatch(tempFileName, MatchString ))
				if(cmpstr(DataFileType,"BrukerCCD")==0)				//this is one of unknown extensions
					result+= tempFileName +";"
				elseif(cmpstr(DataFileType,"marIP/Fit2d")==0 || cmpstr(DataFileType,"Mar")==0)
					if(cmpstr(tempFileName[strlen(tempFileName)-7,inf],"mar2300")==0 || cmpstr(tempFileName[strlen(tempFileName)-7,inf],"mar3450")==0)
						result+= tempFileName +";"
					endif
				elseif(cmpstr(DataFileType,"BSL/SAXS")==0)		//display only BSL/OTOKO SAXS file, Xnn003.nnn, note Xnn000.nnn must exist too but not checked
					if(stringmatch(tempFileName, "*001.*" ))
						result+= tempFileName +";"
					endif
				elseif(cmpstr(DataFileType,"BSL/WAXS")==0)		//display only BSL/OTOKO SAXS file, Xnn003.nnn, note Xnn000.nnn must exist too but not checked
					if(stringmatch(tempFileName, "*003.*" ))
						result+= tempFileName +";"
					endif
				elseif(cmpstr(DataFileType,"Fuji/img")==0)		//display only *.img files (Fuji image plate)
					if(stringmatch(tempFileName, "*.img" ))
						result+= tempFileName +";"
					endif
				elseif (cmpstr(DataFileType,"Pilatus")==0)
					SVAR PilatusFileType=root:Packages:Convert2Dto1D:PilatusFileType
					if(!cmpstr(PilatusFileType,"edf"))
						if(stringmatch(tempFileName, "*.edf" ))
							result+= tempFileName +";"
						endif
					elseif(!cmpstr(PilatusFileType,"tiff")||!cmpstr(PilatusFileType,"float-tiff"))
						if(stringmatch(tempFileName, "*.tif" ))
							result+= tempFileName +";"
						endif
					elseif(!cmpstr(PilatusFileType,"img"))
						if(stringmatch(tempFileName, "*.img" ))
							result+= tempFileName +";"
						endif
					endif
				elseif(cmpstr(DataFileType,"AUSW")==0)
					if(stringmatch(tempFileName, "*.tif" ) && !stringmatch(tempfilename,"*_CR*")&& !stringmatch(tempfilename,"*_UR*")&& !stringmatch(tempfilename,"*_LL*") && !stringmatch(tempfilename,"*CR_*")&& !stringmatch(tempfilename,"*UR_*")&& !stringmatch(tempfilename,"*LL_*"))
						result+= tempFileName +";"
					endif
				elseif(cmpstr(DataFileType,"BS_Suitcase_Tiff")==0)
					if(stringmatch(tempFileName, "*.tif" ) || stringmatch(tempFileName, "*.tiff" ) )
						result+= tempFileName +";"
					endif
				else
					result+= tempFileName +";"
				endif
			endif
	endfor
	return result
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_CreateListOfFiles(ListOf2DSampleData,ListOfFiles,Extension, NameMatchString)
	wave/T ListOf2DSampleData
	string ListOfFiles,Extension, NameMatchString
	
	variable i, imax, numberOfParts
	imax = itemsInList(listOfFiles)
	string result, tempFileName
	For(i=0;i<imax;i+=1)
		tempFileName = stringFromList(i,ListOfFiles)
		numberOfParts = itemsInList(tempFileName,".")
		if(strlen(NameMatchString)==0 || stringmatch(tempFileName, NameMatchString ))
			if(cmpstr(Extension,"????")==0)				//this is one of unknown extensions
				ListOf2DSampleData[i] = tempFileName 
			else
			//	ListOf2DSampleData[i] = RemoveEnding(tempFileName , Extension)
				ListOf2DSampleData[i] = tempFileName 
			endif
		endif
	endfor
	
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Proc EGNA_Convert2Dto1DPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(16,57,454,758) as "Main 2D to 1D conversion panel"
	DoWindow/C EGNA_Convert2Dto1DPanel
	SetDrawLayer UserBack
	SetDrawEnv fsize= 18,fstyle= 1,textrgb= (0,12800,52224)
	DrawText 48,20,"2D to 1D data conversion panel"
	DrawText 10,89,"Select input data here"
	DrawText 11,249,"Select contiguous range:"
//first data selection part
	Button Select2DDataPath,pos={15,30},size={200,20},proc=EGNA_ButtonProc,title="Select data path"
	Button Select2DDataPath,help={"Select Data path where 2D data are"}
	TitleBox PathInfoStrt, pos={3,55}, size={350,20}, variable=root:Packages:Convert2Dto1D:MainPathInfoStr, fsize=9, frame=0, fstyle=2, fColor=(0,12800,32000)
	PopupMenu Select2DDataType,pos={249,30},size={111,21},proc=EGNA_PopMenuProc,title="Image type"
	PopupMenu Select2DDataType,help={"Select type of 2D images being loaded"}
	PopupMenu Select2DDataType,mode=2,popvalue=root:Packages:Convert2Dto1D:DataFileExtension,value= #"root:Packages:Convert2Dto1D:ListOfKnownExtensions"
	CheckBox InvertImages,pos={260,75},size={146,14},proc=EGNA_CheckProc,title="Invert 0, 0 corner?"
	CheckBox InvertImages,help={"Check to have 0,0 in left BOTTOM corner, uncheck to have 0,0 in left TOP corner. Only for newly loaded images!"}
	CheckBox InvertImages,variable= root:Packages:Convert2Dto1D:InvertImages

	Button RefreshList,pos={330,90},size={100,18},proc=EGNA_ButtonProc,title="Refresh"
	Button RefreshList,help={"Refresh lisbox"}
	Button SaveCurrentToolSetting,pos={330,110},size={100,18},proc=EGNA_ButtonProc,title="Save/Load Config"
	Button SaveCurrentToolSetting,help={"Save or recall configuration of this panel"}, font="Times New Roman",fSize=11
	Button ExportDisplayedImage,pos={330,130},size={100,18},proc=EGNA_ButtonProc,title="Export image"
	Button ExportDisplayedImage,help={"Save displayed image as tiff file for future use"}, font="Times New Roman",fSize=11
	Button SaveDisplayedImage,pos={330,150},size={100,18},proc=EGNA_ButtonProc,title="Store image"
	Button SaveDisplayedImage,help={"Store displayed image within Ior experiment for future use. This can recult in VERY large files..."}, font="Times New Roman",fSize=11


	SetVariable SampleNameMatchStr,pos={10,214},size={135,18},proc=EGNA_PanelSetVarProc,title="Match :"
	SetVariable SampleNameMatchStr,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:SampleNameMatchStr

	ListBox Select2DInputWave,pos={16,92},size={300,120},row=0
	ListBox Select2DInputWave,help={"Select data file to be converted, you can select multiple data sets"}
	ListBox Select2DInputWave,listWave=root:Packages:Convert2Dto1D:ListOf2DSampleData
	ListBox Select2DInputWave,selWave=root:Packages:Convert2Dto1D:ListOf2DSampleDataNumbers
	ListBox Select2DInputWave,mode= 4, proc=EGN_MainListBoxProc
	PopupMenu SelectStartOfRange,pos={155,217},size={214,21},proc=EGNA_PopMenuProc,title="Start"
	PopupMenu SelectStartOfRange,help={"Select first 2D data to process"}
	PopupMenu SelectStartOfRange,mode=1,popvalue="---",value= #"EGNA_Create2DSelectionPopup()"
	PopupMenu SelectEndOfRange,pos={160,239},size={211,21},proc=EGNA_PopMenuProc,title="End"
	PopupMenu SelectEndOfRange,help={"Select last 2D data to process"}
	PopupMenu SelectEndOfRange,mode=1,popvalue="---",value= #"EGNA_Create2DSelectionPopup()"
//tab controls here
	TabControl Convert2Dto1DTab,pos={4,284},size={430,300},proc=EGNA_TabProc
	TabControl Convert2Dto1DTab,help={"Select tabs to control various parameters"}
	TabControl Convert2Dto1DTab,tabLabel(0)="Main",tabLabel(1)="Param"
	TabControl Convert2Dto1DTab,tabLabel(2)="Mask",tabLabel(3)="Emp/Dk"
	TabControl Convert2Dto1DTab,tabLabel(4)="Sectors",tabLabel(5)="Prev", tabLabel(6)="LineProf", value= 0
//tab 1 geometry and method of calibration
	SetVariable SampleToDetectorDistance,pos={24,309},size={230,16},Disable=1,proc=EGNA_PanelSetVarProc,title="Sample to CCD distance [mm]"
	SetVariable SampleToDetectorDistance,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:SampleToCCDDistance
	SetVariable Wavelength,pos={21,331},size={162,16},proc=EGNA_PanelSetVarProc,title="Wavelength [A]  "
	SetVariable Wavelength,help={"\"Input wavelegth of X-rays in Angstroems\" "}
	SetVariable Wavelength,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:Wavelength
	TitleBox GeometryDesc,pos={67,356},size={276,16},title="Direction     X (horizontal)                       Y (vertical)"
	TitleBox GeometryDesc,labelBack=(56576,56576,56576),fSize=12,frame=0
	TitleBox GeometryDesc,fColor=(0,0,65280)
	SetVariable PixleSizeX,pos={34,377},size={160,16},proc=EGNA_PanelSetVarProc,title="CCD pixel size [mm]"
	SetVariable PixleSizeX,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:PixelSizeX
	SetVariable PixleSizeY,pos={222,377},size={160,16},proc=EGNA_PanelSetVarProc,title="CCD pixel size [mm]"
	SetVariable PixleSizeY,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:PixelSizeY
	SetVariable BeamCenterX,pos={34,400},size={160,16},proc=EGNA_PanelSetVarProc,title="Beam center"
	SetVariable BeamCenterX,limits={-INF,Inf,1},value= root:Packages:Convert2Dto1D:BeamCenterX
	SetVariable BeamCenterY,pos={222,400},size={160,16},proc=EGNA_PanelSetVarProc,title="Beam center"
	SetVariable BeamCenterY,limits={-INF,Inf,1},value= root:Packages:Convert2Dto1D:BeamCenterY
	SetVariable HorizontalTilt,pos={34,420},size={160,16},proc=EGNA_PanelSetVarProc,title="Horizontal Tilt"
	SetVariable HorizontalTilt,limits={-90,90,0},value= root:Packages:Convert2Dto1D:HorizontalTilt,help={"Tilt of the image in horizontal plane (around 0 degrees)"}
	SetVariable VerticalTilt,pos={222,420},size={160,16},proc=EGNA_PanelSetVarProc,title="Vertical Tilt"
	SetVariable VerticalTilt,limits={-90,90,0},value= root:Packages:Convert2Dto1D:VerticalTilt,help={"Tilt of the image in vertical plane (around 90 degrees)"}
	SetVariable XrayEnergy,pos={205,331},size={162,16},proc=EGNA_PanelSetVarProc,title="X-ray energy [keV]"
	SetVariable XrayEnergy,help={"Input energy of X-rays in keV (linked with wavelength)"}
	SetVariable XrayEnergy,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:XrayEnergy
	CheckBox UseSampleThickness,pos={10,440},size={146,14},proc=EGNA_CheckProc,title="Use sample thickness (St)?"
	CheckBox UseSampleThickness,help={"Check if you will use sample thickness to scale data for calibration purposes"}
	CheckBox UseSampleThickness,variable= root:Packages:Convert2Dto1D:UseSampleThickness
	CheckBox UseSampleTransmission,pos={10,456},size={155,14},proc=EGNA_CheckProc,title="Use sample transmission (T)?"
	CheckBox UseSampleTransmission,help={"Check if you wil use sample transmission"}
	CheckBox UseSampleTransmission,variable= root:Packages:Convert2Dto1D:UseSampleTransmission
	CheckBox UseSampleCorrectionFactor,pos={10,472},size={173,14},proc=EGNA_CheckProc,title="Use sample Corection factor (C)?"
	CheckBox UseSampleCorrectionFactor,help={"Check if you will use correction factor to scale data to absolute scale"}
	CheckBox UseSampleCorrectionFactor,variable= root:Packages:Convert2Dto1D:UseCorrectionFactor
	CheckBox UseSolidAngle,pos={10,488},size={173,14},proc=EGNA_CheckProc,title="Use Solid Angle Corection (O)?"
	CheckBox UseSolidAngle,help={"Check if you will use correction factor to scale data to absolute scale"}
	CheckBox UseSolidAngle,variable= root:Packages:Convert2Dto1D:UseSolidAngle
	CheckBox UseI0ToCalibrate,pos={10,504},size={99,14},proc=EGNA_CheckProc,title="Use Monitor (I0)?"
	CheckBox UseI0ToCalibrate,help={"Check if you want to scale data by monitor counts"}
	CheckBox UseI0ToCalibrate,variable= root:Packages:Convert2Dto1D:UseI0ToCalibrate
	CheckBox UseDarkField,pos={10,520},size={128,14},proc=EGNA_CheckProc,title="Use Dark field (DF2D)?"
	CheckBox UseDarkField,help={"Check if you will use dark field"}
	CheckBox UseDarkField,variable= root:Packages:Convert2Dto1D:UseDarkField
	CheckBox UseEmptyField,pos={10,536},size={133,14},proc=EGNA_CheckProc,title="Use Empty field (EF2D)?"
	CheckBox UseEmptyField,help={"Check if you will use empty field"}
	CheckBox UseEmptyField,variable= root:Packages:Convert2Dto1D:UseEmptyField
	CheckBox UseSubtractFixedOffset,pos={209,461},size={183,14},proc=EGNA_CheckProc,title="Subtract constant from data (Ofst)?"
	CheckBox UseSubtractFixedOffset,help={"Check if you want to subtract constant from CCD data (replace dark field)"}
	CheckBox UseSubtractFixedOffset,variable= root:Packages:Convert2Dto1D:UseSubtractFixedOffset
	CheckBox UseSampleMeasTime,pos={209,500},size={184,14},proc=EGNA_CheckProc,title="Use sample measurement time (ts)?"
	CheckBox UseSampleMeasTime,help={"Check if you want to scale data by measurement time"}
	CheckBox UseSampleMeasTime,variable= root:Packages:Convert2Dto1D:UseSampleMeasTime
	CheckBox UseEmptyMeasTime,pos={209,518},size={180,14},proc=EGNA_CheckProc,title="Use empty measurement time (te)?"
	CheckBox UseEmptyMeasTime,help={"Check if you want to scale empty field data by measurement time"}
	CheckBox UseEmptyMeasTime,variable= root:Packages:Convert2Dto1D:UseEmptyMeasTime
	CheckBox UseDarkMeasTime,pos={209,536},size={195,14},proc=EGNA_CheckProc,title="Use dark field measurement time (td)?"
	CheckBox UseDarkMeasTime,help={"Check if you want to scale dark field data by measurement time"}
	CheckBox UseDarkMeasTime,variable= root:Packages:Convert2Dto1D:UseDarkMeasTime
	CheckBox UsePixelSensitivity,pos={209,442},size={159,14},proc=EGNA_CheckProc,title="Use pixel sensitivity (Pix2D)?"
	CheckBox UsePixelSensitivity,help={"Check if you want to use pixel sensitivity map"}
	CheckBox UsePixelSensitivity,variable= root:Packages:Convert2Dto1D:UsePixelSensitivity
	CheckBox UseMOnitorForEF,pos={209,480},size={146,14},proc=EGNA_CheckProc,title="Use I0/I0ef for empty field?"
	CheckBox UseMOnitorForEF,help={"Check if you want to scale empty by ratio of monitor values"}
	CheckBox UseMOnitorForEF,variable= root:Packages:Convert2Dto1D:UseMonitorForEF
	SetVariable CalibrationFormula,pos={12,558},size={390,16},title=" "
	SetVariable CalibrationFormula,help={"This is calibration method which will be applied to your data"}
	SetVariable CalibrationFormula,labelBack=(32768,40704,65280),fSize=10,frame=0
	SetVariable CalibrationFormula,limits={-Inf,Inf,0},value= root:Packages:Convert2Dto1D:CalibrationFormula
//tab 2 sample and calibration values

	CheckBox DoGeometryCorrection,pos={20,310},size={100,14},title="Geometry correction?",proc=EGNA_CheckProc
	CheckBox DoGeometryCorrection,help={"Correct for change in relative angular size and obliqueness of off-axis pixels. Correction to the output intensities to be equivalent to 2-theta scan. "}
	CheckBox DoGeometryCorrection,variable= root:Packages:Convert2Dto1D:DoGeometryCorrection

	CheckBox DoPolarizationCorrection,pos={220,310},size={100,14},title="Polarization correction?",proc=EGNA_CheckProc
	CheckBox DoPolarizationCorrection,help={"Correct intensities for Polarization correction."}
	CheckBox DoPolarizationCorrection,variable= root:Packages:Convert2Dto1D:DoPolarizationCorrection
	

	CheckBox UseSampleThicknFnct,pos={15,340},size={50,14},title="Use fnct?",proc=EGNA_CheckProc
	CheckBox UseSampleThicknFnct,help={"Check is thickness=Function(sampleName) for function name input."}
	CheckBox UseSampleThicknFnct,variable= root:Packages:Convert2Dto1D:UseSampleThicknFnct
	SetVariable SampleThickness,pos={193,340},size={180,16},title="Sample thickness [mm]"
	SetVariable SampleThickness,help={"Input sample thickness in mm"}
	SetVariable SampleThickness,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:SampleThickness
	SetVariable SampleThicknFnct,pos={93,340},size={300,16},title="Sa Thickness =", proc=EGNA_SetVarProcMainPanel
	SetVariable SampleThicknFnct,help={"Input function name which returns thickness in mm."}
	SetVariable SampleThicknFnct,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:SampleThicknFnct
	
	CheckBox UseSampleTransmFnct,pos={15,365},size={50,14},title="Use fnct?",proc=EGNA_CheckProc
	CheckBox UseSampleTransmFnct,help={"Check is transmission=Function(sampleName) for function name input."}
	CheckBox UseSampleTransmFnct,variable= root:Packages:Convert2Dto1D:UseSampleTransmFnct
	SetVariable SampleTransmFnct,pos={93,365},size={300,16},title="Sa Transmis =", proc=EGNA_SetVarProcMainPanel
	SetVariable SampleTransmFnct,help={"Input function name which returns transmission (0 - 1)."}
	SetVariable SampleTransmFnct,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:SampleTransmFnct
	SetVariable SampleTransmission,pos={193,365},size={180,16},title="Sample transmission"
	SetVariable SampleTransmission,help={"Input sample transmission"}
	SetVariable SampleTransmission,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:SampleTransmission


	CheckBox UseSampleCorrectFnct,pos={15,395},size={50,14},title="Use fnct?",proc=EGNA_CheckProc
	CheckBox UseSampleCorrectFnct,help={"Check is Correction factor=Function(sampleName) for function name input."}
	CheckBox UseSampleCorrectFnct,variable= root:Packages:Convert2Dto1D:UseSampleCorrectFnct
	SetVariable SampleCorrectFnct,pos={93,395},size={300,16},title="Corr factor =",proc=EGNA_SetVarProcMainPanel
	SetVariable SampleCorrectFnct,help={"Input function name which returns Corection/Calibration factor."}
	SetVariable SampleCorrectFnct,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:SampleCorrectFnct
	SetVariable CorrectionFactor,pos={193,395},size={180,16},title="Correction factor    "
	SetVariable CorrectionFactor,help={"Corection factor to multiply Measured data by "}
	SetVariable CorrectionFactor,limits={1e-32,Inf,0.1},value= root:Packages:Convert2Dto1D:CorrectionFactor

	CheckBox UseSampleMeasTimeFnct,pos={15,418},size={50,14},title="Use fnct?",proc=EGNA_CheckProc
	CheckBox UseSampleMeasTimeFnct,help={"Check is Measurement time=Function(sampleName) for function name input."}
	CheckBox UseSampleMeasTimeFnct,variable= root:Packages:Convert2Dto1D:UseSampleMeasTimeFnct
	SetVariable SampleMeasTimeFnct,pos={93,418},size={300,16},title="Sample Meas time =",proc=EGNA_SetVarProcMainPanel
	SetVariable SampleMeasTimeFnct,help={"Input function name which returns Sample measurement time."}
	SetVariable SampleMeasTimeFnct,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:SampleMeasTimeFnct
	SetVariable SampleMeasurementTime,pos={123,418},size={250,16},title="Sample measurement time [s]"
	SetVariable SampleMeasurementTime,limits={1e-32,Inf,1},value= root:Packages:Convert2Dto1D:SampleMeasurementTime


	CheckBox UseEmptyTimeFnct,pos={15,438},size={50,14},title="Use fnct?",proc=EGNA_CheckProc
	CheckBox UseEmptyTimeFnct,help={"Check is Empty meas. time = Function(sampleName) for function name input."}
	CheckBox UseEmptyTimeFnct,variable= root:Packages:Convert2Dto1D:UseEmptyTimeFnct
	SetVariable EmptyTimeFnct,pos={93,438},size={300,16},title="Empty meas time =",proc=EGNA_SetVarProcMainPanel
	SetVariable EmptyTimeFnct,help={"Input function name which returns Empty measurement time."}
	SetVariable EmptyTimeFnct,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:EmptyTimeFnct
	SetVariable EmptyMeasurementTime,pos={123,438},size={250,16},title="Empty measurement time [s]  "
	SetVariable EmptyMeasurementTime,help={"Empty beam measurement time"}
	SetVariable EmptyMeasurementTime,limits={1e-32,Inf,1},value= root:Packages:Convert2Dto1D:EmptyMeasurementTime

	CheckBox UseBackgTimeFnct,pos={15,460},size={50,14},title="Use fnct?",proc=EGNA_CheckProc
	CheckBox UseBackgTimeFnct,help={"Check is Background meas. time = Function(sampleName) for function name input."}
	CheckBox UseBackgTimeFnct,variable= root:Packages:Convert2Dto1D:UseBackgTimeFnct
	SetVariable BackgTimeFnct,pos={93,460},size={300,16},title="Backgr meas time =",proc=EGNA_SetVarProcMainPanel
	SetVariable BackgTimeFnct,help={"Input function name which returns Background measurement time."}
	SetVariable BackgTimeFnct,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:BackgTimeFnct
	SetVariable BackgroundMeasTime,pos={93,460},size={280,16},title="Background measurement time [s]  "
	SetVariable BackgroundMeasTime,help={"Background beam measurement time"}
	SetVariable BackgroundMeasTime,limits={1e-32,Inf,1},value= root:Packages:Convert2Dto1D:BackgroundMeasTime

	SetVariable SubtractFixedOffset,pos={153,490},size={220,16},title="Fixed offset for CCD images"
	SetVariable SubtractFixedOffset,help={"Subtract fixed offset value for CCD images"}
	SetVariable SubtractFixedOffset,limits={1e-32,Inf,1},value= root:Packages:Convert2Dto1D:SubtractFixedOffset

	CheckBox UseSampleMonitorFnct,pos={15,525},size={50,14},title="Use fnct?",proc=EGNA_CheckProc
	CheckBox UseSampleMonitorFnct,help={"Check is Sample Monitor = Function(sampleName) for function name input."}
	CheckBox UseSampleMonitorFnct,variable= root:Packages:Convert2Dto1D:UseSampleMonitorFnct
	SetVariable SampleMonitorFnct,pos={93,525},size={300,16},title="Sample monitor =",proc=EGNA_SetVarProcMainPanel
	SetVariable SampleMonitorFnct,help={"Input function name which returns Sample monitor (I0) count"}
	SetVariable SampleMonitorFnct,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:SampleMonitorFnct
	SetVariable SampleI0,pos={153,525},size={220,16},title="Sample Monitor counts"
	SetVariable SampleI0,help={"Monitor counts for sample"}
	SetVariable SampleI0,limits={1e-32,Inf,1},value= root:Packages:Convert2Dto1D:SampleI0

	CheckBox UseEmptyMonitorFnct,pos={15,550},size={50,14},title="Use fnct?",proc=EGNA_CheckProc
	CheckBox UseEmptyMonitorFnct,help={"Check is Empty Monitor = Function(sampleName) for function name input."}
	CheckBox UseEmptyMonitorFnct,variable= root:Packages:Convert2Dto1D:UseEmptyMonitorFnct
	SetVariable EmptyMonitorFnct,pos={93,550},size={300,16},title="Empty Mon cnts =",proc=EGNA_SetVarProcMainPanel
	SetVariable EmptyMonitorFnct,help={"Input function name which returns Empty monitor (I0) counts"}
	SetVariable EmptyMonitorFnct,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:EmptyMonitorFnct
	SetVariable EmptyI0,pos={153,550},size={220,16},title="Empty Monitor counts  "
	SetVariable EmptyI0,help={"Monitor counts for empty beam"}
	SetVariable EmptyI0,limits={1e-32,Inf,1},value= root:Packages:Convert2Dto1D:EmptyI0
//tab 3 mask part
	CheckBox UseMask,pos={271,315},size={72,14},proc=EGNA_CheckProc,title="Use Mask?"
	CheckBox UseMask,help={"Check if you will use mask"}
	CheckBox UseMask,variable= root:Packages:Convert2Dto1D:UseMask
	Button MaskSelectPath,pos={25,339},size={200,20},proc=EGNA_ButtonProc,title="Select mask data path"
	Button MaskSelectPath,help={"Select path to mask file"}
//	PopupMenu Select2DMaskType,pos={232,339},size={111,21},proc=EGNA_PopMenuProc,title="Image type"
//	PopupMenu Select2DMaskType,help={"Masks made by this code are tiff files, the should be: xxxx_mask.ext (tif)"}
//	PopupMenu Select2DMaskType,mode=1,popvalue=root:Packages:Convert2Dto1D:MaskFileExtension,value= #"\"tif;\""
	ListBox MaskListBoxSelection,pos={83,375},size={260,100}, row=0
	ListBox MaskListBoxSelection,help={"Select 2D data set for mask"}
	ListBox MaskListBoxSelection,listWave=root:Packages:Convert2Dto1D:ListOf2DMaskData
	ListBox MaskListBoxSelection,row= 0,mode= 1,selRow= 0
	Button LoadMask,pos={192,480},size={150,20},proc=EGNA_ButtonProc,title="Load mask"
	Button LoadMask,help={"Load the mask file "}
	Button CreateMask,pos={24,480},size={150,20},proc=EGNA_ButtonProc,title="Create new mask"
	Button CreateMask,help={"Create mask file using GUI"}
	Button DisplayMaskOnImage,pos={24,504},size={150,20},proc=EGNA_ButtonProc,title="Add mask to image"
	Button DisplayMaskOnImage,help={"Display the mask file in the image"}
	Button RemoveMaskFromImage,pos={192,504},size={150,20},proc=EGNA_ButtonProc,title="Remove mask from image"
	Button RemoveMaskFromImage,help={"Remove mask from image"}
	PopupMenu MaskImageColor,pos={25,528},size={111,21},proc=EGNA_PopMenuProc,title="Mask color"
	PopupMenu MaskImageColor,help={"Select mask color"}
	PopupMenu MaskImageColor,mode=1,value= #"\"grey;red;blue;black;green\""
	SetVariable CurrentMaskName,pos={43,555},size={300,16},title="Current mask name :"
	SetVariable CurrentMaskName,labelBack=(32768,32768,65280),frame=0
	SetVariable CurrentMaskName,limits={-Inf,Inf,0},value= root:Packages:Convert2Dto1D:CurrentMaskFileName,noedit= 1
//tab 4 Empty, dark and pixel sensitivity
	CheckBox DezingerCCDData,pos={22,310},size={112,14},title="Dezinger 2D Data?"
	CheckBox DezingerCCDData,help={"Remove speckles from image"}, proc=EGNA_CheckProc
	CheckBox DezingerCCDData,variable= root:Packages:Convert2Dto1D:DezingerCCDData
	CheckBox DezingerEmpty,pos={256,464},size={101,14},title="Dezinger Empty"
	CheckBox DezingerEmpty,help={"Remove speckles from empty"}, proc=EGNA_CheckProc
	CheckBox DezingerEmpty,variable= root:Packages:Convert2Dto1D:DezingerEmpty
	CheckBox DezingerDark,pos={255,485},size={95,14},title="Dezinger Dark"
	CheckBox DezingerDark,help={"Remove speckles from dark field"}, proc=EGNA_CheckProc
	CheckBox DezingerDark,variable= root:Packages:Convert2Dto1D:DezingerDarkField
	SetVariable DezingerRatio,pos={150,310},size={100,16},title="Dez. Ratio"
	SetVariable DezingerRatio,help={"Dezinger ratio for removing speckles (usually 1.5 to 2)"}
	SetVariable DezingerRatio,limits={0,Inf,0.1},value= root:Packages:Convert2Dto1D:DezingerRatio
	SetVariable DezingerHowManyTimes,pos={260,310},size={140,16},title="Dez. N times, N="
	SetVariable DezingerHowManyTimes,help={"Dezinger multiplicity, runs sample through the dezinger filter so many times..."}
	SetVariable DezingerHowManyTimes,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:DezingerHowManyTimes
	ListBox Select2DMaskDarkWave,pos={23,354},size={351,100},disable=1, row=0
	ListBox Select2DMaskDarkWave,help={"Select data file to be used as empty beam or dark field"}
	ListBox Select2DMaskDarkWave,listWave=root:Packages:Convert2Dto1D:ListOf2DEmptyData
	ListBox Select2DMaskDarkWave,row= 0,mode= 1,selRow= 0
	Button LoadEmpty,pos={51,460},size={130,20},proc=EGNA_ButtonProc,title="Load Empty"
	Button LoadEmpty,help={"Load empty data"}
	Button LoadDarkField,pos={41,483},size={160,20},proc=EGNA_ButtonProc,title="Load Dark Field"
	Button LoadDarkField,help={"Load dark field data"}
	Button SelectMaskDarkPath,pos={10,330},size={240,20},proc=EGNA_ButtonProc,title="Select path to mask, dark & pix sens. files"
	Button SelectMaskDarkPath,help={"Select Data path where Empty and Dark files are"}
	PopupMenu SelectBlank2DDataType,pos={270,330},size={111,21},proc=EGNA_PopMenuProc,title="Image type"
	PopupMenu SelectBlank2DDataType,help={"Select type of 2D images being loaded"}
	PopupMenu SelectBlank2DDataType,mode=2,popvalue=root:Packages:Convert2Dto1D:DataFileExtension,value= #"root:Packages:Convert2Dto1D:ListOfKnownExtensions"
	SetVariable CurrentEmptyName,pos={19,533},size={350,16},title="Empty file:"
	SetVariable CurrentEmptyName,help={"Name of file currently used as empty beam"}
	SetVariable CurrentEmptyName,frame=0, noedit=1
	SetVariable CurrentEmptyName,limits={-Inf,Inf,0},value= root:Packages:Convert2Dto1D:CurrentEmptyName
	SetVariable CurrentDarkFieldName,pos={19,548},size={350,16},title="Dark file:"
	SetVariable CurrentDarkFieldName,help={"Name of file currently used as dark field"}
	SetVariable CurrentDarkFieldName,frame=0, noedit=1
	SetVariable CurrentDarkFieldName,limits={-Inf,Inf,0},value= root:Packages:Convert2Dto1D:CurrentDarkFieldName
	Button LoadPixel2DSensitivity,pos={34,508},size={180,20},proc=EGNA_ButtonProc,title="Load Pixel sensitivity file"
	Button LoadPixel2DSensitivity,help={"Load dark field data"}
	SetVariable CurrentPixSensFileName,pos={19,563},size={350,16},title="Pix sensitivity file:"
	SetVariable CurrentPixSensFileName,help={"Name of file currently used as pixel sensitivity"}
	SetVariable CurrentPixSensFileName,frame=0, noedit =1
	SetVariable CurrentPixSensFileName,limits={-Inf,Inf,0},value= root:Packages:Convert2Dto1D:CurrentPixSensFile

	SetVariable EmptyDarkNameMatchStr,pos={245,510},size={155,18},proc=EGNA_PanelSetVarProc,title="Match :"
	SetVariable EmptyDarkNameMatchStr,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:EmptyDarkNameMatchStr

//tab 5 output conditions
	
	CheckBox UseSectors,pos={15,310},size={90,14},title="Use?", mode=0, proc=EGNA_CheckProc
	CheckBox UseSectors,help={"Use any of the settings in this tab?"}
	CheckBox UseSectors,variable= root:Packages:Convert2Dto1D:UseSectors
	CheckBox UseQvector,pos={100,310},size={90,14},title="Q space?", mode=1, proc=EGNA_CheckProc
	CheckBox UseQvector,help={"Select to have output as function of q [inverse nm]"}
	CheckBox UseQvector,variable= root:Packages:Convert2Dto1D:UseQvector
	CheckBox UseDspacing,pos={180,310},size={90,14},title="d space?", mode=1, proc=EGNA_CheckProc
	CheckBox UseDspacing,help={"Select to have output as function of d spacing"}
	CheckBox UseDspacing,variable= root:Packages:Convert2Dto1D:UseDspacing
	CheckBox UseTheta,pos={260,310},size={90,14},title="2 Theta space?", mode=1, proc=EGNA_CheckProc
	CheckBox UseTheta,help={"Select to have output as function of 2 theta"}
	CheckBox UseTheta,variable= root:Packages:Convert2Dto1D:UseTheta
	SetVariable UserQMin,pos={20,330},size={180,16},title="Min Q (0 = automatic)"//,proc=EGNA_PanelSetVarProc
	SetVariable UserQMin,help={"Input minimum in Q, left set to 0 for automatic - find first available Q value"}
	SetVariable UserQMin,limits={0,Inf,0},value= root:Packages:Convert2Dto1D:UserQMin
	SetVariable UserQMax,pos={220,330},size={180,16},title="Max Q (0 = automatic)"//,proc=EGNA_PanelSetVarProc
	SetVariable UserQMax,help={"Input maximum in Q, left set to 0 for automatic - find last available Q value"}
	SetVariable UserQMax,limits={0,Inf,0},value= root:Packages:Convert2Dto1D:UserQMax
	SetVariable UserThetaMin,pos={20,330},size={180,16},title="Min 2th (0 = automatic)"//,proc=EGNA_PanelSetVarProc
	SetVariable UserThetaMin,help={"Input minimum in 2 theta, left set to 0 for automatic - find first available 2 theta value"}
	SetVariable UserThetaMin,limits={0,Inf,0},value= root:Packages:Convert2Dto1D:UserThetaMin
	SetVariable UserThetaMax,pos={220,330},size={180,16},title="Max 2th (0 = automatic)"//,proc=EGNA_PanelSetVarProc
	SetVariable UserThetaMax,help={"Input maximum in 2 theta, left set to 0 for automatic - find last available 2 theta value"}
	SetVariable UserThetaMax,limits={0,Inf,0},value= root:Packages:Convert2Dto1D:UserThetaMax
	SetVariable UserDMin,pos={20,330},size={180,16},title="Min d (0 = automatic)"//,proc=EGNA_PanelSetVarProc
	SetVariable UserDMin,help={"Input minimum in d, left set to 0 for automatic - find first available d value"}
	SetVariable UserDMin,limits={0,Inf,0},value= root:Packages:Convert2Dto1D:UserDMin
	SetVariable UserDMax,pos={220,330},size={180,16},title="Max d (0 = automatic)"//,proc=EGNA_PanelSetVarProc
	SetVariable UserDMax,help={"Input maximum in d, left set to 0 for automatic - find last available d value"}
	SetVariable UserDMax,limits={0,Inf,0},value= root:Packages:Convert2Dto1D:UserDMax


	CheckBox QbinningLogarithmic,pos={20,350},size={90,14},title="Log binning?",proc=EGNA_CheckProc
	CheckBox QbinningLogarithmic,help={"Check to have binning in q (d or theta) logarithmic"}
	CheckBox QbinningLogarithmic,variable= root:Packages:Convert2Dto1D:QbinningLogarithmic
	SetVariable QbinPoints,pos={172,370},size={160,16},title="Number of points"
	SetVariable QbinPoints,help={"Number of points in Q you want to create"}, disable = (root:Packages:Convert2Dto1D:QvectorMaxNumPnts)
	SetVariable QbinPoints,limits={0,Inf,10},value= root:Packages:Convert2Dto1D:QvectorNumberPoints
	CheckBox QvectorMaxNumPnts,pos={172,350},size={130,14},title="Max num points?",proc=EGNA_CheckProc
	CheckBox QvectorMaxNumPnts,help={"Use Max possible number of points? Num pnts = num pixels"}
	CheckBox QvectorMaxNumPnts,variable= root:Packages:Convert2Dto1D:QvectorMaxNumPnts

	CheckBox DoCircularAverage,pos={20,370},size={130,14},title="Do circular average?",proc=EGNA_CheckProc
	CheckBox DoCircularAverage,help={"Create data with circular average?"}
	CheckBox DoCircularAverage,variable= root:Packages:Convert2Dto1D:DoCircularAverage
	CheckBox DoSectorAverages,pos={20,390},size={130,14},title="Make sector averages?",proc=EGNA_CheckProc
	CheckBox DoSectorAverages,help={"Create data with sector average?"}, proc=EGNA_checkProc
	CheckBox DoSectorAverages,variable= root:Packages:Convert2Dto1D:DoSectorAverages
	SetVariable NumberOfSectors,pos={20,410},size={160,16},title="Number of sectors",proc=EGNA_PanelSetVarProc
	SetVariable NumberOfSectors,help={"Number of sectors you want to create"}
	SetVariable NumberOfSectors,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:NumberOfSectors
	
	SetVariable SectorsStartAngle,pos={200,410},size={160,16},title="Start angle of sectors",proc=EGNA_PanelSetVarProc
	SetVariable SectorsStartAngle,help={"Angle around which first sectors is centered"}
	SetVariable SectorsStartAngle,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:SectorsStartAngle
	SetVariable SectorsHalfWidth,pos={20,430},size={160,16},title="Width of sector +/- ",proc=EGNA_PanelSetVarProc
	SetVariable SectorsHalfWidth,help={"Half width of sectors in degrees"}
	SetVariable SectorsHalfWidth,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:SectorsHalfWidth
	SetVariable SectorsStepInAngle,pos={200,430},size={160,16},title="Angle between sectors",proc=EGNA_PanelSetVarProc
	SetVariable SectorsStepInAngle,help={"Angle between center directions of sectors"}
	SetVariable SectorsStepInAngle,limits={0,Inf,1},value= root:Packages:Convert2Dto1D:SectorsStepInAngle

	CheckBox DisplayDataAfterProcessing,pos={20,450},size={159,14},title="Create 1D graph?"
	CheckBox DisplayDataAfterProcessing,help={"Create graph of 1D data after processing"},proc=EGNA_CheckProc
	CheckBox DisplayDataAfterProcessing,variable= root:Packages:Convert2Dto1D:DisplayDataAfterProcessing

	CheckBox StoreDataInIgor,pos={20,470},size={159,14},title="Store data in Igor experiment?"
	CheckBox StoreDataInIgor,help={"Save data in current Igor experiment"},proc=EGNA_CheckProc
	CheckBox StoreDataInIgor,variable= root:Packages:Convert2Dto1D:StoreDataInIgor
	CheckBox OverwriteDataIfExists,pos={200,470},size={159,14},title="Overwrite existing data if exist?"
	CheckBox OverwriteDataIfExists,help={"Overwrite data in current Igor experiment if they already exist"}
	CheckBox OverwriteDataIfExists,variable= root:Packages:Convert2Dto1D:OverwriteDataIfExists
	


	CheckBox ExportDataOutOfIgor,pos={20,500},size={122,14},title="Export data as ASCII?"
	CheckBox ExportDataOutOfIgor,help={"Check to export data out of Igor, select data path"}
	CheckBox ExportDataOutOfIgor,variable= root:Packages:Convert2Dto1D:ExportDataOutOfIgor

	CheckBox SaveGSASdata,pos={150,500},size={122,14},title="GSAS?", disable=!(root:Packages:Convert2Dto1D:UseTheta)
	CheckBox SaveGSASdata,help={"Check to export data out of Igoras GSAS data"}
	CheckBox SaveGSASdata,variable= root:Packages:Convert2Dto1D:SaveGSASdata

	CheckBox Use2DdataName,pos={20,528},size={170,14},title="Use input data name for output?"
	CheckBox Use2DdataName,help={"Check to have output data named after input data name"}
	CheckBox Use2DdataName,variable= root:Packages:Convert2Dto1D:Use2DdataName
	Button CreateOutputPath,pos={212,500},size={160,20},title="Select output path"
	Button CreateOutputPath,help={"Select path to export data into"},proc=EGNA_ButtonProc
	SetVariable OutputFileName,pos={20,554},size={360,16},title="ASCII data name"
	SetVariable OutputFileName,help={"Input string for 1D data"}
	SetVariable OutputFileName,value= root:Packages:Convert2Dto1D:OutputDataName
	//tab 6 - sectors for namual processing...
	Button CreateSectorGraph,pos={20,530},size={160,20},title="Create sector graph"
	Button CreateSectorGraph,help={"Create graph in of angle vs pixel for manual processing"},proc=EGNA_ButtonProc
	SetVariable SectorsNumSect,pos={20,320},size={180,16},title="Number of sectors   "
	SetVariable SectorsNumSect,help={"How many sectors to use for creating the graph?"}, proc=EGNA_SetVarProcMainPanel
	SetVariable SectorsNumSect,value= root:Packages:Convert2Dto1D:SectorsNumSect, limits={2,720,1}
	SetVariable SectorsSectWidth,pos={20,350},size={180,16},title="Width of each sector"
	SetVariable SectorsSectWidth,help={"How wide (in degrees) the sectors should be?"}, limits={0.5,180,1}
	SetVariable SectorsSectWidth,value= root:Packages:Convert2Dto1D:SectorsSectWidth, proc=EGNA_SetVarProcMainPanel
	SetVariable SectorsGraphStartAngle,pos={20,380},size={220,16},title="Start Angle for sector graph"
	SetVariable SectorsGraphStartAngle,help={"Start angle for sector graph?"}, limits={0,360,1}
	SetVariable SectorsGraphStartAngle,value= root:Packages:Convert2Dto1D:SectorsGraphStartAngle, proc=EGNA_SetVarProcMainPanel
	SetVariable SectorsGraphEndAngle,pos={20,410},size={220,16},title="End Angle for sector graph "
	SetVariable SectorsGraphEndAngle,help={"How wide (in degrees) the sectors should be?"}, limits={0,360,1}
	SetVariable SectorsGraphEndAngle,variable= root:Packages:Convert2Dto1D:SectorsGraphEndAngle, proc=EGNA_SetVarProcMainPanel
	CheckBox A2DmaskImage,pos={20,440},size={170,14},title="Mask the data?"
	CheckBox A2DmaskImage,help={"Check to have  data masked"}
	CheckBox A2DmaskImage,variable= root:Packages:Convert2Dto1D:A2DmaskImage
	CheckBox SectorsUseRAWData,pos={20,460},size={170,14},title="Use RAW data?", mode=1
	CheckBox SectorsUseRAWData,help={"Use raw data for creating sectors graph?"}, proc=EGNA_CheckProc
	CheckBox SectorsUseRAWData,variable= root:Packages:Convert2Dto1D:SectorsUseRAWData
	CheckBox SectorsUseCorrData,pos={20,480},size={170,14},title="Use Processed data?", mode=1
	CheckBox SectorsUseCorrData,help={"Check to have  data masked"}, proc=EGNA_CheckProc
	CheckBox SectorsUseCorrData,variable= root:Packages:Convert2Dto1D:SectorsUseCorrData

//tab 6 output conditions
	CheckBox UseLineProfile,pos={15,310},size={90,14},title="Use?", mode=0, proc=EGNA_CheckProc
	CheckBox UseLineProfile,help={"Use any of the settings in this tab?"}
	CheckBox UseLineProfile,variable= root:Packages:Convert2Dto1D:UseLineProfile
	CheckBox LineProf_UseBothHalfs,pos={15,330},size={90,14},title="Include mirror?", mode=0, proc=EGNA_CheckProc
	CheckBox LineProf_UseBothHalfs,help={"Use lines at both + and - distance?"}
	CheckBox LineProf_UseBothHalfs,variable= root:Packages:Convert2Dto1D:LineProf_UseBothHalfs
	CheckBox LineProf_SubtractBackground,pos={110,330},size={90,14},title="Background Subtract?", mode=0, proc=EGNA_CheckProc
	CheckBox LineProf_SubtractBackground,help={"Automatically subtract average of profile one width larger and one width lower?"}
	CheckBox LineProf_SubtractBackground,variable= root:Packages:Convert2Dto1D:LineProf_SubtractBackground
	
	
	
	
//LineProfileUseRAW;LineProfileUseCorrData
	CheckBox LineProfileUseRAW,pos={300,310},size={90,14},title="Use RAW?", mode=1, proc=EGNA_CheckProc
	CheckBox LineProfileUseRAW,help={"Use uncorrected data?"}
	CheckBox LineProfileUseRAW,variable= root:Packages:Convert2Dto1D:LineProfileUseRAW
	CheckBox LineProfileUseCorrData,pos={300,330},size={90,14},title="Use Processed?", mode=1, proc=EGNA_CheckProc
	CheckBox LineProfileUseCorrData,help={"Use corrected data?"}
	CheckBox LineProfileUseCorrData,variable= root:Packages:Convert2Dto1D:LineProfileUseCorrData

	PopupMenu LineProf_CurveType,pos={20,355},size={214,21},proc=EGNA_PopMenuProc,title="Path type:"
	PopupMenu LineProf_CurveType,help={"Select Line profile method to use"}
	PopupMenu LineProf_CurveType,mode=1,popvalue=root:Packages:Convert2Dto1D:LineProf_CurveType,value= #"root:Packages:Convert2Dto1D:LineProf_KnownCurveTypes"
//Shape specific controls.
	SetVariable LineProf_GIIncAngle,pos={220,355},size={210,16},title="GI inc. angle [deg] "
	SetVariable LineProf_GIIncAngle,help={"Incident angle for GISAXS configuration in degrees?"}, limits={-inf, inf,0.01}
	SetVariable LineProf_GIIncAngle,variable= root:Packages:Convert2Dto1D:LineProf_GIIncAngle, proc=EGNA_SetVarProcMainPanel

	SetVariable LineProf_EllipseAR,pos={220,355},size={210,16},title="Ellipse AR"
	SetVariable LineProf_EllipseAR,help={"Aspect ratio for ellipse?"}, limits={-inf, inf,1}
	SetVariable LineProf_EllipseAR,variable= root:Packages:Convert2Dto1D:LineProf_EllipseAR, proc=EGNA_SetVarProcMainPanel

	SetVariable LineProf_LineAzAngle,pos={220,355},size={210,16},title="Line Az angle [deg]"
	SetVariable LineProf_LineAzAngle,help={"Azimuthal angle for line going through center in degrees?"}, limits={0, 179.999,1}
	SetVariable LineProf_LineAzAngle,variable= root:Packages:Convert2Dto1D:LineProf_LineAzAngle, proc=EGNA_SetVarProcMainPanel
	
//other controls	
	SetVariable LineProf_DistanceFromCenter,pos={20,405},size={220,16},title="Distance from center [in pixles] "
	SetVariable LineProf_DistanceFromCenter,help={"Distacne from center in pixels?"}, limits={-inf, inf,1}
	SetVariable LineProf_DistanceFromCenter,variable= root:Packages:Convert2Dto1D:LineProf_DistanceFromCenter, proc=EGNA_SetVarProcMainPanel
	SetVariable LineProf_DistanceQ,pos={280,405},size={100,16},title="Q =  ",format="%.4f"
	SetVariable LineProf_DistanceQ,help={"Distance from center in q units"}, limits={-inf, inf,0}
	SetVariable LineProf_DistanceQ,variable= root:Packages:Convert2Dto1D:LineProf_DistanceQ//, proc=EGNA_SetVarProcMainPanel
	SetVariable LineProf_Width,pos={20,425},size={220,17},proc=EGNA_SetVarProcMainPanel,title="Width [in pixles]                      "
	SetVariable LineProf_Width,help={"WIdth of the line in pixels?"}
	SetVariable LineProf_Width,variable= root:Packages:Convert2Dto1D:LineProf_Width
	SetVariable LineProf_WidthQ,pos={280,425},size={100,17},title="Q =  "
	SetVariable LineProf_WidthQ,help={"Width in q units"},format="%.4f"
	SetVariable LineProf_WidthQ,limits={-inf,inf,0},variable= root:Packages:Convert2Dto1D:LineProf_WidthQ

 
//last few items under the tabs area
	Button DisplaySelectedFile,pos={14,587},size={150,18},proc=EGNA_ButtonProc,title="Ave & Display sel. file(s)"
	Button DisplaySelectedFile,help={"Average selected files and display, only correction is dezingering!"}, font="Times New Roman",fSize=11
	Button ConvertSelectedFiles,pos={15,607},size={150,18},proc=EGNA_ButtonProc,title="Convert sel. files 1 at time"
	Button ConvertSelectedFiles,help={"Convert selected files (1 by 1) using parameters selected in the tabs"}, font="Times New Roman",fSize=11
	Button AveConvertSelectedFiles,pos={15,627},size={150,18},proc=EGNA_ButtonProc,title="Ave & Convert sel. files"
	Button AveConvertSelectedFiles,help={"Average and convert files selected above using parameters set here"}, font="Times New Roman",fSize=11
//added 6 30 2009 as test
//Button SlicingButton,pos={170,627},size={120,18},proc=SlicingPanel ,title="Slice sel. file", font="Times New Roman",fSize=11


	Slider ImageRangeMin,pos={15,647},size={150,16},proc=EGNA_MainSliderProc,variable= root:Packages:Convert2Dto1D:ImageRangeMin,live= 0,side= 2,vert= 0,ticks= 0
	Slider ImageRangeMin,limits={root:Packages:Convert2Dto1D:ImageRangeMinLimit,root:Packages:Convert2Dto1D:ImageRangeMaxLimit,0}
	Slider ImageRangeMax,pos={15,663},size={150,16},proc=EGNA_MainSliderProc,variable= root:Packages:Convert2Dto1D:ImageRangeMax,live= 0,side= 2,vert= 0,ticks= 0
	Slider ImageRangeMax,limits={root:Packages:Convert2Dto1D:ImageRangeMinLimit,root:Packages:Convert2Dto1D:ImageRangeMaxLimit,0}

	Button AveConvertNFiles,pos={170,587},size={150,18},proc=EGNA_ButtonProc,title="Ave & Convert N files"
	Button AveConvertNFiles,help={"Average N files at time, convert all files selected above using parameters set here"}, font="Times New Roman",fSize=11

	SetVariable ProcessNImagesAtTime,pos={335,589},size={80,16},title="N = "
	SetVariable ProcessNImagesAtTime,help={"Howmany images at time should be averaged?"}, limits={1,inf,1}
	SetVariable ProcessNImagesAtTime,variable= root:Packages:Convert2Dto1D:ProcessNImagesAtTime, proc=EGNA_SetVarProcMainPanel
//
	CheckBox SkipBadFiles,pos={185,608},size={120,16},title="Skip bad files?"
	CheckBox SkipBadFiles,help={"Skip images with low maximum intensity?"}
	CheckBox SkipBadFiles,variable= root:Packages:Convert2Dto1D:SkipBadFiles
	CheckBox SkipBadFiles proc=EGNA_CheckProc
	SetVariable MaxIntForBadFile,pos={300,610},size={120,16},title="Min. Int = "
	SetVariable MaxIntForBadFile,help={"Bad file has less than this intensity?"}, limits={0,inf,1}
	SetVariable MaxIntForBadFile,variable= root:Packages:Convert2Dto1D:MaxIntForBadFile, disable=!(root:Packages:Convert2Dto1D:SkipBadFiles)

	CheckBox DisplayRaw2DData,pos={185,625},size={120,16},title="Display RAW data?"
	CheckBox DisplayRaw2DData,help={"In the 2D image, display raw data?"}, mode=1
	CheckBox DisplayRaw2DData,variable= root:Packages:Convert2Dto1D:DisplayRaw2DData
	CheckBox DisplayRaw2DData proc=EGNA_CheckProc
	CheckBox DisplayProcessed2DData,pos={185,640},size={120,16},title="Display Processed?"
	CheckBox DisplayProcessed2DData,help={"In the 2D image, display processed, calibrated data?"}, mode=1
	CheckBox DisplayProcessed2DData,variable= root:Packages:Convert2Dto1D:DisplayProcessed2DData
	CheckBox DisplayProcessed2DData proc=EGNA_CheckProc


	PopupMenu ColorTablePopup,pos={170,658},size={107,21},proc=EGNA_PopMenuProc,title="Colors"
	PopupMenu ColorTablePopup,mode=1,popvalue=root:Packages:Convert2Dto1D:ColorTableName,value= #"\"Grays;Rainbow;YellowHot;BlueHot;BlueRedGreen;RedWhiteBlue;PlanetEarth;Terrain;\""
	CheckBox ImageDisplayBeamCenter,variable= root:Packages:Convert2Dto1D:DisplayBeamCenterEG_N2DGraph, help={"Display beam center on teh image?"}
	CheckBox ImageDisplayBeamCenter proc=EGNA_CheckProc, pos={310,630},size={120,16},title="Display beam center?"
	CheckBox ImageDisplaySectors,variable= root:Packages:Convert2Dto1D:DisplaySectorsEG_N2DGraph, help={"Display sectors(if selected) in the image?"}
	CheckBox ImageDisplaySectors proc=EGNA_CheckProc, pos={310,645},size={120,16},title="Display sects/Lines?"
	CheckBox ImageDisplayLogScaled,pos={310,660},size={120,16},title="Log Int display?"
	CheckBox ImageDisplayLogScaled,help={"Display image with log(intensity)?"}
	CheckBox ImageDisplayLogScaled,variable= root:Packages:Convert2Dto1D:ImageDisplayLogScaled
	CheckBox ImageDisplayLogScaled proc=EGNA_CheckProc

	CheckBox DisplayQValsOnImage,pos={100,682},size={120,16},title="Image with Q axes?"
	CheckBox DisplayQValsOnImage,help={"Display image with Q values on axis?"}
	CheckBox DisplayQValsOnImage,variable= root:Packages:Convert2Dto1D:DisplayQValsOnImage
	CheckBox DisplayQValsOnImage proc=EGNA_CheckProc

	CheckBox DisplayQvalsWIthGridsOnImg,pos={260,682},size={120,16},title="Img w/Q axes with grids?"
	CheckBox DisplayQvalsWIthGridsOnImg,help={"Display image with Q values on axis and grids?"}
	CheckBox DisplayQvalsWIthGridsOnImg,variable= root:Packages:Convert2Dto1D:DisplayQvalsWIthGridsOnImg
	CheckBox DisplayQvalsWIthGridsOnImg proc=EGNA_CheckProc
	
	CheckBox Gi_Use_Main_CHK,pos={303,611},size={126,14},proc=GI_Use_Chk,title="Use Grazing Incidence"
	CheckBox Gi_Use_Main_CHK,variable= root:Packages:Convert2Dto1D:UseGrazingIncidence
	
	CheckBox SilentModeC,pos={28,249},size={68,14},title="Silent Mode"
	CheckBox SilentModeC,variable= root:Packages:Convert2Dto1D:SilentMode
	
	SetVariable HookNameSV,pos={6,266},size={425,15},title="Command to run after each conversion:"
	SetVariable HookNameSV,help={"Input string for 1D data"}
	SetVariable HookNameSV,value= root:Packages:Convert2Dto1D:CnvCommandStr
	
	
	Button SwitchQranges,pos={350,176},size={54,27},proc=swnika_but,title="Switch\rQ Ranges"
	Button SwitchQranges,fSize=8
EndMacro

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_SetVarProcMainPanel(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

	NVAR SectorsNumSect= root:Packages:Convert2Dto1D:SectorsNumSect
	NVAR SectorsGraphEndAngle= root:Packages:Convert2Dto1D:SectorsGraphEndAngle
	NVAR SectorsSectWidth= root:Packages:Convert2Dto1D:SectorsSectWidth
	NVAR SectorsGraphStartAngle= root:Packages:Convert2Dto1D:SectorsGraphStartAngle
	variable temp
	
	if(stringMatch("LineProf_DistanceFromCenter",ctrlName)||stringMatch("LineProf_Width",ctrlName)||stringMatch("LineProf_LineAzAngle",ctrlName)||stringMatch("LineProf_GIIncAngle",ctrlName)||stringMatch("LineProf_EllipseAR",ctrlName))
		EGNA_LineProfUpdateQ()
		EGNA_AllDrawingsFrom2DGraph()
		EGNA_DrawCenterEG_N2DGraph()
		EGNA_DrawLinesEG_N2DGraph()
		EGNA_DrawSectorsEG_N2DGraph()
		EGNA_LineProf_CreateLP()
		EGNA_LineProf_DisplayLP()
	endif


	if(cmpstr("SectorsNumSect",ctrlName)==0)
		if(SectorsGraphStartAngle>SectorsGraphEndAngle)
			temp = SectorsGraphEndAngle
			SectorsGraphEndAngle=SectorsGraphStartAngle
			SectorsGraphStartAngle=temp
		endif
		SectorsSectWidth = (SectorsGraphEndAngle-SectorsGraphStartAngle)/SectorsNumSect
	endif
	if(cmpstr("SectorsSectWidth",ctrlName)==0)
	
	endif
	if(cmpstr("ProcessNImagesAtTime",ctrlName)==0)
		Button AveConvertNFiles, title="Ave & Convert "+num2str(varNum)+" files", win=EGNA_Convert2Dto1DPanel
	endif
	if(cmpstr("SectorsGraphStartAngle",ctrlName)==0)
		if(SectorsGraphStartAngle>SectorsGraphEndAngle)
			temp = SectorsGraphEndAngle
			SectorsGraphEndAngle=SectorsGraphStartAngle
			SectorsGraphStartAngle=temp
		endif
		SectorsSectWidth = (SectorsGraphEndAngle-SectorsGraphStartAngle)/SectorsNumSect
	endif
	if(cmpstr("SectorsGraphEndAngle",ctrlName)==0)
		if(SectorsGraphStartAngle>SectorsGraphEndAngle)
			temp = SectorsGraphEndAngle
			SectorsGraphEndAngle=SectorsGraphStartAngle
			SectorsGraphStartAngle=temp
		endif
		SectorsSectWidth = (SectorsGraphEndAngle-SectorsGraphStartAngle)/SectorsNumSect
	endif
	string testFunctInfo
	if(cmpstr("SampleThicknFnct",ctrlName)==0)
		testFunctInfo = FunctionInfo(varStr)
		if(strlen(testFunctInfo)<1)
			Abort "This is not existing user function"
		endif
		if(NumberByKey("RETURNTYPE", testFunctInfo, ":" , ";")!=4)
			Abort "This function does not return single variable value"
		endif
		if(NumberByKey("N_PARAMS", testFunctInfo, ":" , ";")!=1 || NumberByKey("PARAM_0_TYPE", testFunctInfo, ":" , ";")!=8192 )
			Abort "This function does not use ONE string input parameter"
		endif
	endif

	if(cmpstr("SampleTransmFnct",ctrlName)==0)
		testFunctInfo = FunctionInfo(varStr)
		if(strlen(testFunctInfo)<1)
			Abort "This is not existing user function"
		endif
		if(NumberByKey("RETURNTYPE", testFunctInfo, ":" , ";")!=4)
			Abort "This function does not return single variable value"
		endif
		if(NumberByKey("N_PARAMS", testFunctInfo, ":" , ";")!=1 || NumberByKey("PARAM_0_TYPE", testFunctInfo, ":" , ";")!=8192 )
			Abort "This function does not use ONE string input parameter"
		endif
	endif
	if(cmpstr("SampleMonitorFnct",ctrlName)==0)
		testFunctInfo = FunctionInfo(varStr)
		if(strlen(testFunctInfo)<1)
			Abort "This is not existing user function"
		endif
		if(NumberByKey("RETURNTYPE", testFunctInfo, ":" , ";")!=4)
			Abort "This function does not return single variable value"
		endif
		if(NumberByKey("N_PARAMS", testFunctInfo, ":" , ";")!=1 || NumberByKey("PARAM_0_TYPE", testFunctInfo, ":" , ";")!=8192 )
			Abort "This function does not use ONE string input parameter"
		endif
	endif
	if(cmpstr("SampleMeasTimeFnct",ctrlName)==0)
		testFunctInfo = FunctionInfo(varStr)
		if(strlen(testFunctInfo)<1)
			Abort "This is not existing user function"
		endif
		if(NumberByKey("RETURNTYPE", testFunctInfo, ":" , ";")!=4)
			Abort "This function does not return single variable value"
		endif
		if(NumberByKey("N_PARAMS", testFunctInfo, ":" , ";")!=1 || NumberByKey("PARAM_0_TYPE", testFunctInfo, ":" , ";")!=8192 )
			Abort "This function does not use ONE string input parameter"
		endif
	endif
	if(cmpstr("EmptyTimeFnct",ctrlName)==0)
		testFunctInfo = FunctionInfo(varStr)
		if(strlen(testFunctInfo)<1)
			Abort "This is not existing user function"
		endif
		if(NumberByKey("RETURNTYPE", testFunctInfo, ":" , ";")!=4)
			Abort "This function does not return single variable value"
		endif
		if(NumberByKey("N_PARAMS", testFunctInfo, ":" , ";")!=1 || NumberByKey("PARAM_0_TYPE", testFunctInfo, ":" , ";")!=8192 )
			Abort "This function does not use ONE string input parameter"
		endif
	endif
	if(cmpstr("EmptyTimeFnct",ctrlName)==0)
		testFunctInfo = FunctionInfo(varStr)
		if(strlen(testFunctInfo)<1)
			Abort "This is not existing user function"
		endif
		if(NumberByKey("RETURNTYPE", testFunctInfo, ":" , ";")!=4)
			Abort "This function does not return single variable value"
		endif
		if(NumberByKey("N_PARAMS", testFunctInfo, ":" , ";")!=1 || NumberByKey("PARAM_0_TYPE", testFunctInfo, ":" , ";")!=8192 )
			Abort "This function does not use ONE string input parameter"
		endif
	endif
	if(cmpstr("BackgTimeFnct",ctrlName)==0)
		testFunctInfo = FunctionInfo(varStr)
		if(strlen(testFunctInfo)<1)
			Abort "This is not existing user function"
		endif
		if(NumberByKey("RETURNTYPE", testFunctInfo, ":" , ";")!=4)
			Abort "This function does not return single variable value"
		endif
		if(NumberByKey("N_PARAMS", testFunctInfo, ":" , ";")!=1 || NumberByKey("PARAM_0_TYPE", testFunctInfo, ":" , ";")!=8192 )
			Abort "This function does not use ONE string input parameter"
		endif
	endif
	if(cmpstr("EmptyMonitorFnct",ctrlName)==0)
		testFunctInfo = FunctionInfo(varStr)
		if(strlen(testFunctInfo)<1)
			Abort "This is not existing user function"
		endif
		if(NumberByKey("RETURNTYPE", testFunctInfo, ":" , ";")!=4)
			Abort "This function does not return single variable value"
		endif
		if(NumberByKey("N_PARAMS", testFunctInfo, ":" , ";")!=1 || NumberByKey("PARAM_0_TYPE", testFunctInfo, ":" , ";")!=8192 )
			Abort "This function does not use ONE string input parameter"
		endif
	endif
	if(cmpstr("SampleCorrectFnct",ctrlName)==0)
		testFunctInfo = FunctionInfo(varStr)
		if(strlen(testFunctInfo)<1)
			Abort "This is not existing user function"
		endif
		if(NumberByKey("RETURNTYPE", testFunctInfo, ":" , ";")!=4)
			Abort "This function does not return single variable value"
		endif
		if(NumberByKey("N_PARAMS", testFunctInfo, ":" , ";")!=1 || NumberByKey("PARAM_0_TYPE", testFunctInfo, ":" , ";")!=8192 )
			Abort "This function does not use ONE string input parameter"
		endif
	endif

	
	if(cmpstr("GI_Sh1_Param1",ctrlName)==0)
		Execute("SetVariable GI_Sh1_Param1,limits = {-inf, inf, "+num2str(varNum/20)+"}")
	endif

	DoWIndow/F EGNA_Convert2Dto1DPanel
	setDataFolder OldDf
End
 //*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_MainSliderProc(ctrlName,sliderValue,event) //: SliderControl
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved

	if(cmpstr(ctrlName,"ImageRangeMin")==0 || cmpstr(ctrlName,"ImageRangeMax")==0)
		if(event %& 0x1)	// bit 0, value set
				EGNA_TopCCDImageUpdateColors(0)
		endif
	endif
	if(cmpstr(ctrlName,"ImageRangeMinSquare")==0 || cmpstr(ctrlName,"ImageRangeMaxSquare")==0)
		if(event %& 0x1)	// bit 0, value set
				EGNA_SQCCDImageUpdateColors(0)
		endif
	endif
	return 0
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_TopCCDImageUpdateColors(updateRanges)
	variable updateRanges
	
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	NVAR ImageRangeMin= root:Packages:Convert2Dto1D:ImageRangeMin
	NVAR ImageRangeMax = root:Packages:Convert2Dto1D:ImageRangeMax
	SVAR ColorTableName=root:Packages:Convert2Dto1D:ColorTableName
	NVAR ImageRangeMinLimit= root:Packages:Convert2Dto1D:ImageRangeMinLimit
	NVAR ImageRangeMaxLimit = root:Packages:Convert2Dto1D:ImageRangeMaxLimit
	String s= ImageNameList("", ";")
	Variable p1= StrSearch(s,";",0)
	if( p1<0 )
		return 0			// no image in top graph
	endif
	s= s[0,p1-1]
	if(updateRanges)
	//	Wave waveToDisplayDis=$(s)
		Wave waveToDisplayDis=ImageNameToWaveRef("",s)
		wavestats/Q  waveToDisplayDis
		ImageRangeMin=V_min
		ImageRangeMinLimit=V_min
		ImageRangeMax=V_max
		ImageRangeMaxLimit=V_max
		Slider ImageRangeMin,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0}, win=EGNA_Convert2Dto1DPanel
		Slider ImageRangeMax,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0}, win=EGNA_Convert2Dto1DPanel
	endif
	ModifyImage $(s) ctab= {ImageRangeMin,ImageRangeMax,$ColorTableName,0}
	PopupMenu MaskImageColor,win=EGNA_Convert2Dto1DPanel, mode=1
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_TabProc(ctrlName,tabNum)
	String ctrlName
	Variable tabNum

	NVAR UseSampleThickness= root:Packages:Convert2Dto1D:UseSampleThickness
	NVAR UseSampleTransmission= root:Packages:Convert2Dto1D:UseSampleTransmission
	NVAR UseCorrectionFactor= root:Packages:Convert2Dto1D:UseCorrectionFactor
	NVAR UseMask= root:Packages:Convert2Dto1D:UseMask
	NVAR UseDarkField= root:Packages:Convert2Dto1D:UseDarkField
	NVAR UseEmptyField= root:Packages:Convert2Dto1D:UseEmptyField
	NVAR UseSubtractFixedOffset= root:Packages:Convert2Dto1D:UseSubtractFixedOffset
	NVAR UseSampleMeasTime= root:Packages:Convert2Dto1D:UseSampleMeasTime
	NVAR UseEmptyMeasTime= root:Packages:Convert2Dto1D:UseEmptyMeasTime
	NVAR UseDarkMeasTime= root:Packages:Convert2Dto1D:UseDarkMeasTime
	NVAR UsePixelSensitivity= root:Packages:Convert2Dto1D:UsePixelSensitivity
	NVAR UseSubtractFixedOffset= root:Packages:Convert2Dto1D:UseSubtractFixedOffset
	NVAR DoSectorAverages= root:Packages:Convert2Dto1D:DoSectorAverages
	NVAR DezingerCCDData= root:Packages:Convert2Dto1D:DezingerCCDData
	NVAR DezingerEmpty= root:Packages:Convert2Dto1D:DezingerEmpty
	NVAR DezingerDarkField= root:Packages:Convert2Dto1D:DezingerDarkField


	NVAR UseSampleThicknFnct= root:Packages:Convert2Dto1D:UseSampleThicknFnct
	NVAR UseSampleTransmFnct= root:Packages:Convert2Dto1D:UseSampleTransmFnct
	NVAR UseSampleMonitorFnct= root:Packages:Convert2Dto1D:UseSampleMonitorFnct
	NVAR UseSampleMeasTimeFnct= root:Packages:Convert2Dto1D:UseSampleMeasTimeFnct
	NVAR UseEmptyTimeFnct= root:Packages:Convert2Dto1D:UseEmptyTimeFnct
	NVAR UseBackgTimeFnct= root:Packages:Convert2Dto1D:UseBackgTimeFnct
	NVAR UseSampleMonitorFnct= root:Packages:Convert2Dto1D:UseSampleMonitorFnct
	NVAR UseEmptyMonitorFnct= root:Packages:Convert2Dto1D:UseEmptyMonitorFnct
	NVAR UseSampleCorrectFnct= root:Packages:Convert2Dto1D:UseSampleCorrectFnct

	//tab 0 controls
	SetVariable SampleToDetectorDistance,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	SetVariable PixleSizeX, disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	SetVariable PixleSizeY,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	SetVariable BeamCenterX,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	SetVariable BeamCenterY,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	SetVariable HorizontalTilt,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	SetVariable VerticalTilt,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	TitleBox GeometryDesc,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	SetVariable Wavelength,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	SetVariable XrayEnergy,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSampleThickness,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSampleTransmission,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSampleCorrectionFactor,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSolidAngle,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseDarkField,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseEmptyField,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSubtractFixedOffset,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseI0ToCalibrate,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSampleMeasTime,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseEmptyMeasTime,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseDarkMeasTime,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UsePixelSensitivity,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	CheckBox UseMOnitorForEF,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel
	SetVariable CalibrationFormula,disable=(tabNum!=0), win=EGNA_Convert2Dto1DPanel

	//tab 1 controls
	CheckBox DoGeometryCorrection,disable=(tabNum!=1), win=EGNA_Convert2Dto1DPanel
	CheckBox DoPolarizationCorrection,disable=(tabNum!=1), win=EGNA_Convert2Dto1DPanel

	//tab 2 controls
	CheckBox UseMask,disable=(tabNum!=2), win=EGNA_Convert2Dto1DPanel
	ListBox MaskListBoxSelection,disable=(tabNum!=2 || !UseMask), win=EGNA_Convert2Dto1DPanel
	Button MaskSelectPath,disable=(tabNum!=2 || !UseMask), win=EGNA_Convert2Dto1DPanel
	//PopupMenu Select2DMaskType,disable=(tabNum!=2 || !UseMask), win=EGNA_Convert2Dto1DPanel
	Button LoadMask,disable=(tabNum!=2 || !UseMask), win=EGNA_Convert2Dto1DPanel
	Button DisplayMaskOnImage,disable=(tabNum!=2 || !UseMask), win=EGNA_Convert2Dto1DPanel
	Button RemoveMaskFromImage,disable=(tabNum!=2 || !UseMask), win=EGNA_Convert2Dto1DPanel
	SetVariable CurrentMaskName,disable=(tabNum!=2 || !UseMask), win=EGNA_Convert2Dto1DPanel
	Button CreateMask,disable=(tabNum!=2 || !UseMask), win=EGNA_Convert2Dto1DPanel
	PopupMenu MaskImageColor,disable=(tabNum!=2 || !UseMask), win=EGNA_Convert2Dto1DPanel
	//tab 1 controls
	NVAR UseI0ToCalibrate=root:Packages:Convert2Dto1D:UseI0ToCalibrate
	NVAR UseMonitorForEF= root:Packages:Convert2Dto1D:UseMonitorForEF
	SetVariable SampleThickness,disable=(tabNum!=1 || !UseSampleThickness || UseSampleThicknFnct), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSampleThicknFnct,disable=(tabNum!=1 || !UseSampleThickness), win=EGNA_Convert2Dto1DPanel
	SetVariable SampleThicknFnct,disable=(tabNum!=1 || !UseSampleThickness || !UseSampleThicknFnct), win=EGNA_Convert2Dto1DPanel

	SetVariable SampleTransmission,disable=(tabNum!=1 || !UseSampleTransmission || UseSampleTransmFnct), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSampleTransmFnct,disable=(tabNum!=1 || !UseSampleTransmission), win=EGNA_Convert2Dto1DPanel
	SetVariable SampleTransmFnct,disable=(tabNum!=1 || !UseSampleTransmission || !UseSampleTransmFnct), win=EGNA_Convert2Dto1DPanel

	SetVariable SampleI0,disable=(tabNum!=1 || (!UseI0ToCalibrate && !UseMonitorForEF) || UseSampleMonitorFnct), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSampleMonitorFnct,disable=(tabNum!=1 || (!UseI0ToCalibrate && !UseMonitorForEF)), win=EGNA_Convert2Dto1DPanel
	SetVariable SampleMonitorFnct,disable=(tabNum!=1 || (!UseI0ToCalibrate && !UseMonitorForEF) || !UseSampleMonitorFnct), win=EGNA_Convert2Dto1DPanel

	SetVariable SampleMeasurementTime,disable=(tabNum!=1 || !UseSampleMeasTime || UseSampleMeasTimeFnct), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSampleMeasTimeFnct,disable=(tabNum!=1 || !UseSampleMeasTime), win=EGNA_Convert2Dto1DPanel
	SetVariable SampleMeasTimeFnct,disable=(tabNum!=1 || !UseSampleMeasTime || !UseSampleMeasTimeFnct), win=EGNA_Convert2Dto1DPanel

	SetVariable EmptyMeasurementTime,disable=(tabNum!=1 || !UseEmptyMeasTime || UseEmptyTimeFnct), win=EGNA_Convert2Dto1DPanel
	CheckBox UseEmptyTimeFnct,disable=(tabNum!=1 || !UseEmptyMeasTime), win=EGNA_Convert2Dto1DPanel
	SetVariable EmptyTimeFnct,disable=(tabNum!=1 || !UseEmptyMeasTime || !UseEmptyTimeFnct), win=EGNA_Convert2Dto1DPanel

	SetVariable BackgroundMeasTime,disable=(tabNum!=1 || !UseDarkMeasTime || UseBackgTimeFnct), win=EGNA_Convert2Dto1DPanel
	CheckBox UseBackgTimeFnct,disable=(tabNum!=1 || !UseDarkMeasTime), win=EGNA_Convert2Dto1DPanel
	SetVariable BackgTimeFnct,disable=(tabNum!=1 || !UseDarkMeasTime || !UseBackgTimeFnct), win=EGNA_Convert2Dto1DPanel

	SetVariable CorrectionFactor,disable=(tabNum!=1 || !UseCorrectionFactor || UseSampleCorrectFnct), win=EGNA_Convert2Dto1DPanel
	CheckBox UseSampleCorrectFnct,disable=(tabNum!=1 || !UseCorrectionFactor), win=EGNA_Convert2Dto1DPanel
	SetVariable SampleCorrectFnct,disable=(tabNum!=1 || !UseCorrectionFactor || !UseSampleCorrectFnct), win=EGNA_Convert2Dto1DPanel


//	SetVariable EmptyI0,disable=(tabNum!=1 ||  (!UseI0ToCalibrate && !UseMonitorForEF) || UseEmptyMonitorFnct), win=EGNA_Convert2Dto1DPanel
//	CheckBox UseEmptyMonitorFnct,disable=(tabNum!=1 || (!UseI0ToCalibrate && !UseMonitorForEF)), win=EGNA_Convert2Dto1DPanel
//	SetVariable EmptyMonitorFnct,disable=(tabNum!=1 || (!UseI0ToCalibrate && !UseMonitorForEF) || !UseEmptyMonitorFnct), win=EGNA_Convert2Dto1DPanel
	//fix logic here, JIL, 9/3/09 reported bug. Showed up even when was not necessary, confusing users
	SetVariable EmptyI0,disable=(tabNum!=1 ||  (!UseMonitorForEF) || UseEmptyMonitorFnct), win=EGNA_Convert2Dto1DPanel
	CheckBox UseEmptyMonitorFnct,disable=(tabNum!=1 || (!UseMonitorForEF)), win=EGNA_Convert2Dto1DPanel
	SetVariable EmptyMonitorFnct,disable=(tabNum!=1 || (!UseMonitorForEF) || !UseEmptyMonitorFnct), win=EGNA_Convert2Dto1DPanel


	SetVariable SubtractFixedOffset,disable=(tabNum!=1 || !UseSubtractFixedOffset), win=EGNA_Convert2Dto1DPanel
	//tab 3 controls
	CheckBox DezingerCCDData,disable=(tabNum!=3), win=EGNA_Convert2Dto1DPanel
	CheckBox DezingerEmpty,disable=(tabNum!=3 || !UseEmptyField), win=EGNA_Convert2Dto1DPanel
	CheckBox DezingerDark,disable=(tabNum!=3 || !UseDarkField), win=EGNA_Convert2Dto1DPanel
	if((DezingerCCDData || DezingerEmpty || DezingerDarkField) && tabNum==3)
	NVAR UseLineProfile=root:Packages:Convert2Dto1D:UseLineProfile
			SetVariable DezingerRatio, disable=0, win=EGNA_Convert2Dto1DPanel
			SetVariable DezingerHowManyTimes, disable=0, win=EGNA_Convert2Dto1DPanel
	else
			SetVariable DezingerRatio, disable=1, win=EGNA_Convert2Dto1DPanel
			SetVariable DezingerHowManyTimes, disable=1, win=EGNA_Convert2Dto1DPanel
	endif
//	SetVariable DezingerHowManyTimes,disable=(tabNum!=3)
//	SetVariable DezingerRatio,disable=(tabNum!=3)
	PopupMenu SelectBlank2DDataType,disable=(tabNum!=3), win=EGNA_Convert2Dto1DPanel
	ListBox Select2DMaskDarkWave,disable=(tabNum!=3 || !(UseEmptyField || UseDarkField || UsePixelSensitivity)), win=EGNA_Convert2Dto1DPanel
	if(tabNum==3)
		EGNA_UpdateEmptyDarkListBox()
	endif
	Button LoadEmpty,disable=(tabNum!=3 || !UseEmptyField), win=EGNA_Convert2Dto1DPanel
	Button LoadDarkField,disable=(tabNum!=3 || !UseDarkField), win=EGNA_Convert2Dto1DPanel
	Button LoadPixel2DSensitivity,disable=(tabNum!=3 || !UsePixelSensitivity), win=EGNA_Convert2Dto1DPanel
	SetVariable CurrentEmptyName,disable=(tabNum!=3 || !UseEmptyField), win=EGNA_Convert2Dto1DPanel
	SetVariable CurrentDarkFieldName,disable=(tabNum!=3 || !UseDarkField), win=EGNA_Convert2Dto1DPanel
	SetVariable CurrentPixSensFileName,disable=(tabNum!=3 || !UsePixelSensitivity), win=EGNA_Convert2Dto1DPanel
	Button SelectMaskDarkPath,disable=(tabNum!=3 || !(UseEmptyField || UseDarkField || UsePixelSensitivity)), win=EGNA_Convert2Dto1DPanel
	SetVariable EmptyDarkNameMatchStr,disable=(tabNum!=3 || !(UseEmptyField || UseDarkField || UsePixelSensitivity)), win=EGNA_Convert2Dto1DPanel
	//tab 4 controls
	NVAR UseQvector=root:Packages:Convert2Dto1D:UseQvector
	NVAR UseDspacing=root:Packages:Convert2Dto1D:UseDspacing
	NVAR UseTheta=root:Packages:Convert2Dto1D:UseTheta
	NVAR QvectorMaxNumPnts=root:Packages:Convert2Dto1D:QvectorMaxNumPnts
	NVAR UseSectors=root:Packages:Convert2Dto1D:UseSectors
	NVAR UseLineProfile=root:Packages:Convert2Dto1D:UseLineProfile

	CheckBox UseSectors,disable=(tabNum!=4), win=EGNA_Convert2Dto1DPanel
	CheckBox UseQvector,disable=(tabNum!=4||!UseSectors), win=EGNA_Convert2Dto1DPanel
	CheckBox UseDspacing,disable=(tabNum!=4||!UseSectors), win=EGNA_Convert2Dto1DPanel
	CheckBox UseTheta,disable=(tabNum!=4||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable UserQMin,disable=(tabNum!=4 || !UseQvector||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable UserQMax,disable=(tabNum!=4 || !UseQvector||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable UserThetaMin,disable=(tabNum!=4 || !UseTheta||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable UserThetaMax,disable=(tabNum!=4 || !UseTheta||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable UserDMin,disable=(tabNum!=4 || !UseDspacing||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable UserDMax,disable=(tabNum!=4 || !UseDspacing||!UseSectors), win=EGNA_Convert2Dto1DPanel

	CheckBox QbinningLogarithmic,disable=(tabNum!=4||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable QbinPoints,disable=(tabNum!=4 || QvectorMaxNumPnts||!UseSectors), win=EGNA_Convert2Dto1DPanel
	CheckBox QvectorMaxNumPnts,disable=(tabNum!=4||!UseSectors), win=EGNA_Convert2Dto1DPanel
	CheckBox DoCircularAverage,disable=(tabNum!=4||!UseSectors), win=EGNA_Convert2Dto1DPanel
	//the nextset will be used also in Line profile, so make it appear also when that is selected on its tab...
	CheckBox StoreDataInIgor,disable=!((tabNum==4&&UseSectors)||(tabNum==6&&UseLineProfile)), win=EGNA_Convert2Dto1DPanel
	CheckBox OverwriteDataIfExists,disable=!((tabNum==4&&UseSectors)||(tabNum==6&&UseLineProfile)), win=EGNA_Convert2Dto1DPanel
	CheckBox ExportDataOutOfIgor,disable=!((tabNum==4&&UseSectors)||(tabNum==6&&UseLineProfile)), win=EGNA_Convert2Dto1DPanel
	CheckBox SaveGSASdata,disable=(tabNum!=4 || !UseTheta||!UseSectors), win=EGNA_Convert2Dto1DPanel
	CheckBox Use2DdataName,disable=!((tabNum==4&&UseSectors)||(tabNum==6&&UseLineProfile)), win=EGNA_Convert2Dto1DPanel
	Button CreateOutputPath,disable=!((tabNum==4&&UseSectors)||(tabNum==6&&UseLineProfile)), win=EGNA_Convert2Dto1DPanel
	SetVariable OutputFileName,disable=!((tabNum==4&&UseSectors)||(tabNum==6&&UseLineProfile)), win=EGNA_Convert2Dto1DPanel
	CheckBox DisplayDataAfterProcessing,disable=!((tabNum==4&&UseSectors)||(tabNum==6&&UseLineProfile)), win=EGNA_Convert2Dto1DPanel	
	//end of common block for line profiel and secotrs
	CheckBox DoSectorAverages,disable=(tabNum!=4||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable NumberOfSectors,disable=(tabNum!=4 || !DoSectorAverages||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable SectorsStartAngle,disable=(tabNum!=4 || !DoSectorAverages||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable SectorsHalfWidth,disable=(tabNum!=4 || !DoSectorAverages||!UseSectors), win=EGNA_Convert2Dto1DPanel
	SetVariable SectorsStepInAngle,disable=(tabNum!=4 || !DoSectorAverages||!UseSectors), win=EGNA_Convert2Dto1DPanel
	//tab 5 controls
	Button CreateSectorGraph,disable=(tabNum!=5), win=EGNA_Convert2Dto1DPanel
	SetVariable SectorsNumSect,disable=(tabNum!=5), win=EGNA_Convert2Dto1DPanel
	SetVariable SectorsSectWidth,disable=(tabNum!=5), win=EGNA_Convert2Dto1DPanel
	SetVariable SectorsGraphStartAngle,disable=(tabNum!=5), win=EGNA_Convert2Dto1DPanel
	SetVariable SectorsGraphEndAngle,disable=(tabNum!=5), win=EGNA_Convert2Dto1DPanel
	CheckBox A2DmaskImage,disable=(tabNum!=5), win=EGNA_Convert2Dto1DPanel
	CheckBox SectorsUseRAWData,disable=(tabNum!=5), win=EGNA_Convert2Dto1DPanel
	//here alco check, if Corrected data are meaningful, else make grey next button...
	Variable CorrImgExists=exists("root:Packages:Convert2Dto1D:Calibrated2DDataSet")
	if(!CorrImgExists)
		NVAR SectorsUseCorrData=root:Packages:Convert2Dto1D:SectorsUseCorrData
		NVAR SectorsUseRAWData=root:Packages:Convert2Dto1D:SectorsUseRAWData
		SectorsUseCorrData=0
		SectorsUseRAWData=1
	endif
	CheckBox SectorsUseCorrData,disable=(tabNum!=5 || !CorrImgExists), win=EGNA_Convert2Dto1DPanel

// tab 6 controls, GI geometry
	SVAR KnWCT=root:Packages:Convert2Dto1D:LineProf_CurveType
	CheckBox UseLineProfile,disable=(tabNum!=6), win=EGNA_Convert2Dto1DPanel
	PopupMenu LineProf_CurveType,disable=(tabNum!=6||!UseLineProfile), win=EGNA_Convert2Dto1DPanel
	CheckBox LineProf_UseBothHalfs,disable=(tabNum!=6||!UseLineProfile||stringMatch(KnWCT,"Angle Line")), win=EGNA_Convert2Dto1DPanel
	CheckBox LineProf_SubtractBackground,disable=(tabNum!=6||!UseLineProfile||!stringMatch(KnWCT,"Ellipse")), win=EGNA_Convert2Dto1DPanel
	
	

	CheckBox LineProfileUseRAW,disable=(tabNum!=6||!UseLineProfile), win=EGNA_Convert2Dto1DPanel
	CheckBox LineProfileUseCorrData,disable=(tabNum!=6||!UseLineProfile), win=EGNA_Convert2Dto1DPanel

	SetVariable LineProf_DistanceFromCenter,disable=(tabNum!=6||!UseLineProfile), win=EGNA_Convert2Dto1DPanel
	SetVariable LineProf_DistanceQ,disable=(tabNum!=6||!UseLineProfile), win=EGNA_Convert2Dto1DPanel
	SetVariable LineProf_Width,disable=(tabNum!=6||!UseLineProfile), win=EGNA_Convert2Dto1DPanel
	SetVariable LineProf_WidthQ,disable=(tabNum!=6||!UseLineProfile), win=EGNA_Convert2Dto1DPanel
	
	SetVariable LineProf_LineAzAngle,disable=(tabNum!=6||!UseLineProfile||!stringMatch(KnWCT,"Angle Line")), win=EGNA_Convert2Dto1DPanel
	SetVariable LineProf_EllipseAR,disable=(tabNum!=6||!UseLineProfile||!stringMatch(KnWCT,"Ellipse")), win=EGNA_Convert2Dto1DPanel
	SetVariable LineProf_GIIncAngle,disable=(tabNum!=6||!UseLineProfile||(!stringMatch(KnWCT,"GISAXS_FixQy")&&!stringMatch(KnWCT,"GI_Horizontal line")&&!stringMatch(KnWCT,"GI_Vertical line"))), win=EGNA_Convert2Dto1DPanel
	
	return 0
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_PanelSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName


	if(cmpstr("BeamCenterX",ctrlName)==0)
		EGNA_DoDrawingsInto2DGraph()
		NI1U_UpdateQAxisInImage()
	endif
	if(cmpstr("BeamCenterY",ctrlName)==0)
		EGNA_DoDrawingsInto2DGraph()
		NI1U_UpdateQAxisInImage()
	endif
	if(cmpstr("XrayEnergy",ctrlName)==0)
		NVAR Wavelength= root:Packages:Convert2Dto1D:Wavelength
		Wavelength = 12.398424437/VarNum
		//changed SDD, need to do anything?Wavelength
		NI1U_UpdateQAxisInImage()
	endif
	if(cmpstr("Wavelength",ctrlName)==0)
		NVAR XrayEnergy= root:Packages:Convert2Dto1D:XrayEnergy
		XrayEnergy = 12.398424437/VarNum
		NI1U_UpdateQAxisInImage()
	endif
	if(cmpstr("SampleToDetectorDistance",ctrlName)==0)
		//changed SDD, need to do anything?
		NI1U_UpdateQAxisInImage()
	endif	

	if(cmpstr("SampleNameMatchStr",ctrlName)==0)
		//changed SDD, need to do anything?
		EGNA_UpdateDataListBox()
	endif	

	if(cmpstr("EmptyDarkNameMatchStr",ctrlName)==0)
		//changed SDD, need to do anything?
		EGNA_UpdateEmptyDarkListBox()
	endif	


	if(cmpstr("NumberOfSectors",ctrlName)==0)
		NVAR tr =root:Packages:Convert2Dto1D:NumberOfSectors
		tr=EG_N2G_roundDecimalPlaces(tr,1)
		EGNA_DoDrawingsInto2DGraph()
	endif	
	if(cmpstr("SectorsStartAngle",ctrlName)==0)
		NVAR tr =root:Packages:Convert2Dto1D:SectorsStartAngle
		tr=EG_N2G_roundDecimalPlaces(tr,1)
		EGNA_DoDrawingsInto2DGraph()
	endif	
	if(cmpstr("SectorsHalfWidth",ctrlName)==0)
		NVAR tr =root:Packages:Convert2Dto1D:SectorsHalfWidth
		tr=EG_N2G_roundDecimalPlaces(tr,1)
		EGNA_DoDrawingsInto2DGraph()
	endif	
	if(cmpstr("SectorsStepInAngle",ctrlName)==0)
		NVAR tr =root:Packages:Convert2Dto1D:SectorsStepInAngle
		tr=EG_N2G_roundDecimalPlaces(tr,1)
		EGNA_DoDrawingsInto2DGraph()
	endif	
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_ListBoxProc(ctrlName,row,col,event)
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
					//5=cell select with shift key, 6=begin edit, 7=end

	if(cmpstr("MaskListBoxSelection",ctrlName)==0)
	
	endif
	return 0
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_PolarCorCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
				NVAR Use1DPolarizationCor = root:Packages:Convert2Dto1D:Use1DPolarizationCor
				NVAR Use2DPolarizationCor = root:Packages:Convert2Dto1D:Use2DPolarizationCor
				if(stringmatch(cba.ctrlName,"Use1DPolarizationCor"))
					Use2DPolarizationCor=!Use1DPolarizationCor
				endif
				if(stringmatch(cba.ctrlName,"Use2DPolarizationCor"))
					Use1DPolarizationCor=!Use2DPolarizationCor
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

WIndow EGNA_PolCorPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(345,282,645,482) as "Polarization Correction"
	Dowindow/C EGNA_PolCorPanel
	SetDrawLayer UserBack
	SetDrawEnv fsize= 14,fstyle= 3,textrgb= (0,0,65535)
	DrawText 23,31,"Polarization correction settings"
	SetDrawEnv fstyle= 1
	DrawText 13,150,"For 2D Pol Corr:"
	DrawText 13,170,"0 deg ... S. Pol. plane horizontal on det."
	DrawText 13,190,"90 deg ... S. Pol. plane vertical on det."
	DrawRect 250,135,280,165
	SetDrawEnv linethick= 2
	DrawLine 265,150,280,150
	DrawRect 250,168,280,198
	SetDrawEnv linethick= 2
	DrawLine 265,168,265,183
	CheckBox Use1DPolarizationCor,pos={15,40},size={145,14},proc=EGNA_PolarCorCheckProc,title="Unpolarized radiation (desktop)"
	CheckBox Use1DPolarizationCor,variable= root:Packages:Convert2Dto1D:Use1DPolarizationCor,mode=1, help={"Select to use with unpolarized radiation such as from tube source"}
	CheckBox Use2DPolarizationCor,pos={16,65},size={145,14},proc=EGNA_PolarCorCheckProc,title="Polarized radiation (synchrotrons)"
	CheckBox Use2DPolarizationCor,variable= root:Packages:Convert2Dto1D:Use2DPolarizationCor,mode=1, help={"Use to apply Polarization correction for linearly polarized radiation"}
	SetVariable TwoDPolarizFract,pos={13,88},size={240,16},title="Sigma : Pi ratio (~1 usually)"
	SetVariable TwoDPolarizFract,value= root:Packages:Convert2Dto1D:TwoDPolarizFract, limits={0,1,0.05}, help={"1 for fully polarized (usual, synchrotrons)"}
	SetVariable a2DPolCorrStarAngle,pos={13,110},size={240,16},title="Sigma Polar. Plane [deg]"
	SetVariable a2DPolCorrStarAngle,value= root:Packages:Convert2Dto1D:StartAngle2DPolCor, limits={0,180,90}, help={"0 for polarization horizontally on detector, 90 vertically"}
EndMacro
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_LineProfUpdateQ()


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
		
		
		
		
		//NVAR BeamCenterY=root:Packages:Convert2Dto1D:BeamCenterY
		NVAR BeamCenterX=root:Packages:Convert2Dto1D:BeamCenterX
		NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
		NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
		NVAR HorizontalTilt=root:Packages:Convert2Dto1D:HorizontalTilt
		NVAR VerticalTilt=root:Packages:Convert2Dto1D:VerticalTilt
		NVAR LineProf_UseBothHalfs=root:Packages:Convert2Dto1D:LineProf_UseBothHalfs

		NVAR LineProf_LineAzAngle=root:Packages:Convert2Dto1D:LineProf_LineAzAngle
		NVAR LineProf_GIIncAngle=root:Packages:Convert2Dto1D:LineProf_GIIncAngle
		NVAR LineProf_EllipseAR=root:Packages:Convert2Dto1D:LineProf_EllipseAR
		
		SVAR LineProf_CurveType=root:Packages:Convert2Dto1D:LineProf_CurveType
		variable distance, distanceW1, distancew2
		if(stringMatch(LineProf_CurveType,"Horizontal Line") || stringMatch(LineProf_CurveType,"GI_Horizontal line"))
			distance=NI1T_TiltedToCorrectedR( LineProf_DistanceFromCenter*PixelSizeY ,SampleToCCDDistance,VerticalTilt)		//in mm 
			distancew1=NI1T_TiltedToCorrectedR( (LineProf_DistanceFromCenter+LineProf_Width)*PixelSizeY ,SampleToCCDDistance,VerticalTilt)		//in mm 
			distancew2=NI1T_TiltedToCorrectedR(  (LineProf_DistanceFromCenter-LineProf_Width)*PixelSizeY ,SampleToCCDDistance,VerticalTilt)		//in mm 
		endif
		if(stringMatch(LineProf_CurveType,"Vertical Line")|| stringMatch(LineProf_CurveType,"Ellipse")|| stringMatch(LineProf_CurveType,"Angle Line"))
			distance=NI1T_TiltedToCorrectedR( LineProf_DistanceFromCenter*PixelSizeX ,SampleToCCDDistance,HorizontalTilt)		//in mm 
			distancew1=NI1T_TiltedToCorrectedR(  (LineProf_DistanceFromCenter+LineProf_Width)*PixelSizeX ,SampleToCCDDistance,HorizontalTilt)		//in mm 
			distancew2=NI1T_TiltedToCorrectedR(  (LineProf_DistanceFromCenter-LineProf_Width)*PixelSizeX ,SampleToCCDDistance,HorizontalTilt)		//in mm 
		endif
		variable theta=atan(distance/SampleToCCDDistance)/2
		variable thetaw1=atan(distancew1/SampleToCCDDistance)/2
		variable thetaw2=atan(distancew2/SampleToCCDDistance)/2
		variable Qval= ((4*pi)/Wavelength)*sin(theta)
		variable Qvalw1= ((4*pi)/Wavelength)*sin(thetaw1)
		variable Qvalw2= ((4*pi)/Wavelength)*sin(thetaw2)

		if( stringMatch(LineProf_CurveType,"GI_Vertical line"))
			Qval = NI1GI_CalculateQxyz(LineProf_DistanceFromCenter+BeamCenterX,BeamCenterY,"xy") // changing from y to xy pure
			Qvalw1 = NI1GI_CalculateQxyz(LineProf_DistanceFromCenter+BeamCenterX+LineProf_Width,BeamCenterY,"xy")
			Qvalw2 = NI1GI_CalculateQxyz(LineProf_DistanceFromCenter+BeamCenterX-LineProf_Width,BeamCenterY,"xy")
		endif
		if( stringMatch(LineProf_CurveType,"GI_Horizontal line"))
			Qval = NI1GI_CalculateQxyz(BeamCenterX,BeamCenterY-LineProf_DistanceFromCenter,"z") // changing to z pure
			Qvalw1 = NI1GI_CalculateQxyz(BeamCenterX,BeamCenterY-LineProf_Width-LineProf_DistanceFromCenter,"Z")
			Qvalw2 = NI1GI_CalculateQxyz(BeamCenterX,BeamCenterY+LineProf_Width-LineProf_DistanceFromCenter,"Z")
		endif
		
		LineProf_DistanceQ=Qval
		LineProf_WidthQ=abs(Qvalw1-Qvalw2)
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	string oldDf=GetDataFolder(1)
	setDataFolder root:Packages:Convert2Dto1D

	NVAR UseSampleThickness= root:Packages:Convert2Dto1D:UseSampleThickness
	NVAR UseSampleTransmission= root:Packages:Convert2Dto1D:UseSampleTransmission
	NVAR UseCorrectionFactor= root:Packages:Convert2Dto1D:UseCorrectionFactor
	NVAR UseMask= root:Packages:Convert2Dto1D:UseMask
	NVAR UseDarkField= root:Packages:Convert2Dto1D:UseDarkField
	NVAR UseEmptyField= root:Packages:Convert2Dto1D:UseEmptyField
	NVAR UseSubtractFixedOffset= root:Packages:Convert2Dto1D:UseSubtractFixedOffset
	NVAR UseSampleMeasTime= root:Packages:Convert2Dto1D:UseSampleMeasTime
	NVAR UseEmptyMeasTime= root:Packages:Convert2Dto1D:UseEmptyMeasTime
	NVAR UseDarkMeasTime= root:Packages:Convert2Dto1D:UseDarkMeasTime
	NVAR UsePixelSensitivity= root:Packages:Convert2Dto1D:UsePixelSensitivity
	NVAR UseI0ToCalibrate = root:Packages:Convert2Dto1D:UseI0ToCalibrate
	NVAR UseMonitorForEF = root:Packages:Convert2Dto1D:UseMonitorForEF
	NVAR UseQvector = root:Packages:Convert2Dto1D:UseQvector
	NVAR UseDspacing = root:Packages:Convert2Dto1D:UseDspacing
	NVAR UseTheta = root:Packages:Convert2Dto1D:UseTheta
	NVAR SkipBadFiles=root:Packages:Convert2Dto1D:SkipBadFiles

	NVAR SectorsUseRAWData= root:Packages:Convert2Dto1D:SectorsUseRAWData
	NVAR SectorsUseCorrData= root:Packages:Convert2Dto1D:SectorsUseCorrData
	NVAR LineProfileUseRAW= root:Packages:Convert2Dto1D:LineProfileUseRAW
	NVAR LineProfileUseCorrData= root:Packages:Convert2Dto1D:LineProfileUseCorrData

	if(StringMatch("LineProfileUseRAW",ctrlName))
		LineProfileUseCorrData=!LineProfileUseRAW
		EGNA_LineProf_Update()
	endif
	if(StringMatch("LineProfileUseCorrData",ctrlName))
		LineProfileUseRAW=!LineProfileUseCorrData
		EGNA_LineProf_Update()
	endif

	NVAR QnoGrids= root:Packages:Convert2Dto1D:DisplayQValsOnImage
	NVAR Qgrids = root:Packages:Convert2Dto1D:DisplayQvalsWIthGridsOnImg

	if(StringMatch("DisplayQValsOnImage",ctrlName))
		if(checked)
			Qgrids=0
			DoWIndow CCDImageToConvertFig
			if(!V_flag)
				return 0
			endif
			NI1G_AddQAxisToImage(0)
		else
			NI1G_RemoveQAxisToImage(1)
		endif
	endif
	if(StringMatch("DisplayQvalsWIthGridsOnImg",ctrlName))
		if(checked)
			QnoGrids=0
			DoWIndow CCDImageToConvertFig
			if(!V_flag)
				return 0
			endif
			NI1G_AddQAxisToImage(1)
		else
			NI1G_RemoveQAxisToImage(1)
		endif
	endif
	if(StringMatch("LineProf_UseBothHalfs",ctrlName) || StringMatch("LineProf_SubtractBackground",ctrlName))
		EGNA_LineProf_Update()
	endif
	if(StringMatch("SectorsUseRAWData",ctrlName))
		SectorsUseCorrData=!SectorsUseRAWData
	endif
	if(StringMatch("SectorsUseCorrData",ctrlName))
		SectorsUseRAWData=!SectorsUseCorrData
	endif

	if(cmpstr("SkipBadFiles",ctrlName)==0)
		SetVariable MaxIntForBadFile,disable=(!SkipBadFiles)
	endif
	
	NVAR DisplayRaw2DData=root:Packages:Convert2Dto1D:DisplayRaw2DData
	NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
	
	if(cmpstr("DisplayRaw2DData",ctrlName)==0)
		DisplayProcessed2DData=!DisplayRaw2DData
		EGNA_DisplayTheRight2DWave()
	endif
	if(cmpstr("DisplayProcessed2DData",ctrlName)==0)
		DisplayRaw2DData = !DisplayProcessed2DData
		EGNA_DisplayTheRight2DWave()
	endif

	if(cmpstr("UseQvector",ctrlName)==0)
		//UseQvector=0
		UseDspacing=0
		UseTheta=0
		SetVariable UserQMin,disable=(!UseQvector)
		SetVariable UserQMax,disable=( !UseQvector)
		SetVariable UserThetaMin,disable=( !UseTheta)
		SetVariable UserThetaMax,disable=( !UseTheta)
		SetVariable UserDMin,disable=( !UseDspacing)
		SetVariable UserDMax,disable=( !UseDspacing)
		Checkbox SaveGSASdata, disable=(!UseTheta)
	endif
	if(cmpstr("UseDspacing",ctrlName)==0)
		UseQvector=0
		//UseDspacing=0
		UseTheta=0
		SetVariable UserQMin,disable=(!UseQvector)
		SetVariable UserQMax,disable=( !UseQvector)
		SetVariable UserThetaMin,disable=( !UseTheta)
		SetVariable UserThetaMax,disable=( !UseTheta)
		SetVariable UserDMin,disable=( !UseDspacing)
		SetVariable UserDMax,disable=( !UseDspacing)
		Checkbox SaveGSASdata, disable=(!UseTheta)
	endif
	if(cmpstr("UseTheta",ctrlName)==0)
		UseQvector=0
		UseDspacing=0
		//UseTheta=0
		SetVariable UserQMin,disable=(!UseQvector)
		SetVariable UserQMax,disable=( !UseQvector)
		SetVariable UserThetaMin,disable=( !UseTheta)
		SetVariable UserThetaMax,disable=( !UseTheta)
		SetVariable UserDMin,disable=( !UseDspacing)
		SetVariable UserDMax,disable=( !UseDspacing)
		Checkbox SaveGSASdata, disable=(!UseTheta)
	endif

	if(cmpstr("DoCircularAverage",ctrlName)==0)
		EGNA_DoDrawingsInto2DGraph()
	endif	
	if(cmpstr("DoSectorAverages",ctrlName)==0)
		EGNA_DoDrawingsInto2DGraph()
	endif	
	if(cmpstr("UseSectors",ctrlName)==0)
		EGNA_TabProc("",4)
	endif
	if(cmpstr("UseI0ToCalibrate",ctrlName)==0)
	endif
	if(cmpstr("UseSampleThickness",ctrlName)==0)
	endif

	if(cmpstr("UseSampleThicknFnct",ctrlName)==0)
		SetVariable SampleThickness,disable=(checked), win=EGNA_Convert2Dto1DPanel
		SetVariable SampleThicknFnct,disable=(!checked), win=EGNA_Convert2Dto1DPanel
	endif
	if(cmpstr("UseSampleMonitorFnct",ctrlName)==0)
		SetVariable SampleI0,disable=(checked), win=EGNA_Convert2Dto1DPanel
		SetVariable SampleMonitorFnct,disable=(!checked), win=EGNA_Convert2Dto1DPanel
	endif
	
	if(cmpstr("UseSampleTransmFnct",ctrlName)==0)
		SetVariable SampleTransmission,disable=(checked), win=EGNA_Convert2Dto1DPanel
		SetVariable SampleTransmFnct,disable=(!checked), win=EGNA_Convert2Dto1DPanel
	endif
	
	if(cmpstr("UseSampleMeasTimeFnct",ctrlName)==0)
		SetVariable SampleMeasurementTime,disable=(checked), win=EGNA_Convert2Dto1DPanel
		SetVariable SampleMeasTimeFnct,disable=(!checked), win=EGNA_Convert2Dto1DPanel
	endif
	
	if(cmpstr("UseEmptyTimeFnct",ctrlName)==0)
		SetVariable EmptyMeasurementTime,disable=(checked), win=EGNA_Convert2Dto1DPanel
		SetVariable EmptyTimeFnct,disable=(!checked), win=EGNA_Convert2Dto1DPanel
	endif
	
	if(cmpstr("UseBackgTimeFnct",ctrlName)==0)
		SetVariable BackgroundMeasTime,disable=(checked), win=EGNA_Convert2Dto1DPanel
		SetVariable BackgTimeFnct,disable=(!checked), win=EGNA_Convert2Dto1DPanel
	endif
	
	if(cmpstr("UseSampleCorrectFnct",ctrlName)==0)
		SetVariable CorrectionFactor,disable=(checked), win=EGNA_Convert2Dto1DPanel
		SetVariable SampleCorrectFnct,disable=(!checked), win=EGNA_Convert2Dto1DPanel
	endif
	
	if(cmpstr("UseEmptyMonitorFnct",ctrlName)==0)
		SetVariable EmptyI0,disable=(checked), win=EGNA_Convert2Dto1DPanel
		SetVariable EmptyMonitorFnct,disable=(!checked), win=EGNA_Convert2Dto1DPanel
	endif


	if(cmpstr("UseSampleTransmission",ctrlName)==0)
	endif
	if(cmpstr("UseSampleCorrectionFactor",ctrlName)==0)
	endif
	if(cmpstr("UseMask",ctrlName)==0)
		if(!checked)
			NI1M_RemoveMaskFromImage()
		endif
		EGNA_TabProc("nothing",2)
	endif
	if(cmpstr("UseDarkField",ctrlName)==0)
		UseSubtractFixedOffset=0
	endif
	if(cmpstr("UseEmptyField",ctrlName)==0)
	endif
	if(cmpstr("UseSubtractFixedOffset",ctrlName)==0)
		UseDarkField = 0
	endif
	if(cmpstr("UseSampleMeasTime",ctrlName)==0)
	endif
	if(cmpstr("UseEmptyMeasTime",ctrlName)==0)
	endif
	if(cmpstr("UseDarkMeasTime",ctrlName)==0)
	endif
	if(cmpstr("UseSolidAngle",ctrlName)==0)
	endif
	if(cmpstr("SilentModeC",ctrlName)==0)
	endif
	if(cmpstr("UseMonitorForEF",ctrlName)==0)
	endif
	if(cmpstr("QbinningLogarithmic",ctrlName)==0)
		if(checked)
			NVAR QvectorMaxNumPnts=root:Packages:Convert2Dto1D:QvectorMaxNumPnts
			QvectorMaxNumPnts=0
			SetVariable QbinPoints, win=EGNA_Convert2Dto1DPanel, disable=QvectorMaxNumPnts
		endif
	endif
	if(cmpstr("QvectorMaxNumPnts",ctrlName)==0)
		SetVariable QbinPoints, win=EGNA_Convert2Dto1DPanel, disable=checked
		if(checked)
			NVAR QbinningLogarithmic=root:Packages:Convert2Dto1D:QbinningLogarithmic
			QbinningLogarithmic=0
		endif
	endif
	if(cmpstr("DoSectorAverages",ctrlName)==0)
		EGNA_TabProc("nothing",4)
	endif
	if(cmpstr("UseLineProfile",ctrlName)==0)
		EGNA_TabProc("nothing",6)
	endif
	
	
	if(cmpstr("DisplayDataAfterProcessing",ctrlName)==0)
		if(checked)
			NVAR tr=root:Packages:Convert2Dto1D:StoreDataInIgor
			tr=1
		endif
	endif
	if(cmpstr("StoreDataInIgor",ctrlName)==0)
		if(!checked)
			NVAR tr=root:Packages:Convert2Dto1D:DisplayDataAfterProcessing
			tr=0
		endif
	endif
	if(cmpstr("ImageDisplayBeamCenter",ctrlName)==0)
		EGNA_DoDrawingsInto2DGraph()
	endif
	if(cmpstr("ImageDisplaySectors",ctrlName)==0)
		EGNA_DoDrawingsInto2DGraph()
	endif

	if(cmpstr("ImageDisplayLogScaled",ctrlName)==0)
		
		string  TopImgName=WinName(0,1)
		if(cmpstr(TopImgName,"CCDImageToConvertFig")!=0 && cmpstr(TopImgName,"EmptyOrDarkImage")!=0)
			DoWindow CCDImageToConvertFig
			if(!V_Flag)
				DoWindow EmptyOrDarkImage
				if(!V_Flag)
					abort
				else
					DoWindow/F EmptyOrDarkImage	
					TopImgName="EmptyOrDarkImage"	
				endif
			else
				DoWindow/F CCDImageToConvertFig	
				TopImgName="CCDImageToConvertFig"
			endif
		endif
		if (cmpstr(TopImgName,"CCDImageToConvertFig")==0)
			EGNA_DisplayTheRight2DWave()
//			NVAR DisplayProcessed2DData=root:Packages:Convert2Dto1D:DisplayProcessed2DData
//			NVAR DisplayRaw2DData=root:Packages:Convert2Dto1D:DisplayRaw2DData
//			if(DisplayRaw2DData)
//				wave waveToDisplay = root:Packages:Convert2Dto1D:CCDImageToConvert
//			else
//				wave/Z waveToDisplay = root:Packages:Convert2Dto1D:Calibrated2DDataSet
//				if(!WaveExists(waveToDisplay))
//					Abort "Error in Irena in display of Calibrated data initiated by log int change. Please contact author"
//				endif
//			endif
//		//	Duplicate/O waveToDisplay, CCDImageToConvert_dis
//			wave waveToDisplayDis = root:Packages:Convert2Dto1D:CCDImageToConvert_dis
//
//			Redimension/S waveToDisplayDis
//			if(checked)
//				MatrixOp/O waveToDisplayDis =  log(waveToDisplay)
//			else
//				MatrixOp/O waveToDisplayDis = waveToDisplay
//			endif
		endif
		if (cmpstr(TopImgName,"EmptyOrDarkImage")==0)
			String s= ImageNameList("", ";")
			Variable p1= StrSearch(s,";",0)
			if( p1<0 )
				abort			// no image in top graph
			endif
			s= s[0,p1-1]
			if(cmpstr(s,"EmptyData_Dis")==0)
				wave waveToDisplay = root:Packages:Convert2Dto1D:EmptyData
				wave waveToDisplayDis = root:Packages:Convert2Dto1D:EmptyData_dis
			elseif(cmpstr(s,"DarkFieldData_Dis")==0)
				wave waveToDisplay = root:Packages:Convert2Dto1D:DarkFieldData
				wave waveToDisplayDis = root:Packages:Convert2Dto1D:DarkFieldData_dis
			elseif(cmpstr(s,"Pixel2Dsensitivity_Dis")==0)
				wave waveToDisplay = root:Packages:Convert2Dto1D:Pixel2Dsensitivity
				wave waveToDisplayDis = root:Packages:Convert2Dto1D:Pixel2Dsensitivity_dis
			else
				abort
			endif
			Redimension/S waveToDisplayDis
			if(checked)
				MatrixOp/O waveToDisplayDis = log(waveToDisplay)
			else
				MatrixOp/O waveToDisplayDis = waveToDisplay
			endif
		endif
		EGNA_TopCCDImageUpdateColors(1)
	endif

	
	if(cmpstr("DezingerCCDData",ctrlName)==0 || cmpstr("DezingerEmpty",ctrlName)==0 || cmpstr("DezingerDark",ctrlName)==0)
		EGNA_TabProc("nothing",3)	//this sets the displayed variables accordingly
	endif

	EGNA_SetCalibrationFormula()

	DoWIndow/F EGNA_Convert2Dto1DPanel	
	
	//and these ones should npt raise the panel above...
	if(cmpstr("DoPolarizationCorrection",ctrlName)==0)
		if(checked)
			DoWindow EGNA_PolCorPanel
			if(V_Flag)
				DoWIndow/F EGNA_PolCorPanel
			else
				Execute("EGNA_PolCorPanel()")
			endif
		else
			DoWindow EGNA_PolCorPanel
			if(V_Flag)
				DoWIndow/K EGNA_PolCorPanel
			endif
		endif		
	endif

	
	setDataFolder OldDf
End
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_LineProf_Update()
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
		EGNA_LineProfUpdateQ()
		EGNA_AllDrawingsFrom2DGraph()
		EGNA_DrawLinesEG_N2DGraph()
		variable cont = EGNA_LineProf_CreateLP()
		if(cont)
			EGNA_LineProf_DisplayLP()	
		endif	
	setDataFolder OldDf

end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_DoDrawingsInto2DGraph()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	NVAR DisplayBeamCenterEG_N2DGraph=root:Packages:Convert2Dto1D:DisplayBeamCenterEG_N2DGraph
	NVAR DisplaySectorsEG_N2DGraph=root:Packages:Convert2Dto1D:DisplaySectorsEG_N2DGraph
	NVAR UseSectors = root:Packages:Convert2Dto1D:UseSectors
	NVAR UseLineProfile=root:Packages:Convert2Dto1D:UseLineProfile
	NVAR DisplayQValsOnImage= root:Packages:Convert2Dto1D:DisplayQValsOnImage
	NVAR DisplayQvalsWIthGridsOnImg = root:Packages:Convert2Dto1D:DisplayQvalsWIthGridsOnImg
	
	EGNA_AllDrawingsFrom2DGraph()
	if(DisplayBeamCenterEG_N2DGraph)
		EGNA_DrawCenterEG_N2DGraph()
	endif
	if(DisplaySectorsEG_N2DGraph && UseSectors)
		EGNA_DrawSectorsEG_N2DGraph()
	endif
	if(DisplaySectorsEG_N2DGraph && UseLineProfile)
		EGNA_DrawLinesEG_N2DGraph()
	endif
	if(DisplayQValsOnImage)
		NI1G_AddQAxisToImage(0)
	endif
	if(DisplayQvalsWIthGridsOnImg)
		NI1G_AddQAxisToImage(1)
	endif
	
	setDataFolder OldDf
end
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
Function EGNA_DrawSectorsEG_N2DGraph()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

 	DoWindow CCDImageToConvertFig
	if(V_Flag)
	     setDrawLayer/W=CCDImageToConvertFig ProgFront
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
		NVAR DoSectorAverages=root:Packages:Convert2Dto1D:DoSectorAverages
		NVAR UseSectors = root:Packages:Convert2Dto1D:UseSectors
		NVAR UseLineProfile=root:Packages:Convert2Dto1D:UseLineProfile
		NVAR NumberOfSectors=root:Packages:Convert2Dto1D:NumberOfSectors
		NVAR SectorsStartAngle=root:Packages:Convert2Dto1D:SectorsStartAngle
		NVAR SectorsHalfWidth=root:Packages:Convert2Dto1D:SectorsHalfWidth
		Wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert_dis
		NVAR SectorsStepInAngle=root:Packages:Convert2Dto1D:SectorsStepInAngle
		variable i, tempEndX, tempEndY, sectorCenterAngle, tempLength
		variable temp1, temp2, temp3, temp4
		
		if(DoSectorAverages && UseSectors)
			For(i=0;i<NumberOfSectors;i+=1)
				//calculate coordinates for lines...
				sectorCenterAngle = SectorsStartAngle+90 + i*(SectorsStepInAngle)
				if(sectorCenterAngle>=90 && sectorCenterAngle<180)
					temp1 = DimSize(CCDImageToConvert, 0 )-xcenter
					temp2 = ycenter
				elseif(sectorCenterAngle>=180 && sectorCenterAngle<270)
					temp1 = xcenter
					temp2= ycenter
				elseif(sectorCenterAngle>=270 && sectorCenterAngle<360)
					temp1 = xcenter
					temp2= DimSize(CCDImageToConvert, 1)-ycenter
				elseif(sectorCenterAngle>=360 && sectorCenterAngle<450)
					temp1 = DimSize(CCDImageToConvert, 0 )-xcenter
					temp2= DimSize(CCDImageToConvert, 1)-ycenter
				endif
				tempLength = sqrt((temp1 * sin(pi/180*sectorCenterAngle))^2+ (temp2 * cos(pi/180*sectorCenterAngle))^2)
				//center line
				tempEndX= (xcenter + (tempLength)*sin(pi/180*(sectorCenterAngle)))
				tempEndY=(ycenter + (tempLength)*cos(pi/180*(sectorCenterAngle)))
				string AxList= AxisList("CCDImageToConvertFig" )
				if(stringMatch(axlist,"*top*"))
					setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=top,ycoord=left,save
				else
					setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=bottom,ycoord=left,save
				endif
				SetDrawEnv/W=CCDImageToConvertFig linefgc= (8704,8704,8704),dash= 7  
				SetDrawEnv /W=CCDImageToConvertFig linethick=2
				Drawline/W=CCDImageToConvertFig xcenter, ycenter, tempEndX, tempEndY
				//side lines
				tempEndX= (xcenter + (tempLength)*sin(pi/180*(sectorCenterAngle-SectorsHalfWidth)))
				tempEndY=(ycenter + (tempLength)*cos(pi/180*(sectorCenterAngle-SectorsHalfWidth)))
				if(stringMatch(axlist,"*top*"))
					setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=top,ycoord=left,save
				else
					setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=bottom,ycoord=left,save
				endif
				SetDrawEnv/W=CCDImageToConvertFig linefgc= (65280,65280,0)
				SetDrawEnv /W=CCDImageToConvertFig dash= 2,linethick= 1.00
				Drawline/W=CCDImageToConvertFig xcenter, ycenter, tempEndX, tempEndY
				tempEndX=(xcenter + (tempLength)*sin(pi/180*(sectorCenterAngle+SectorsHalfWidth)))
				tempEndY=(ycenter + (tempLength)*cos(pi/180*(sectorCenterAngle+SectorsHalfWidth)))
				if(stringMatch(axlist,"*top*"))
					setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=top,ycoord=left,save
				else
					setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=bottom,ycoord=left,save
				endif
				SetDrawEnv/W=CCDImageToConvertFig linefgc= (65280,65280,0)
				SetDrawEnv /W=CCDImageToConvertFig dash= 2,linethick= 1.00
				Drawline/W=CCDImageToConvertFig xcenter, ycenter, tempEndX, tempEndY
			 endfor
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
Function EGNA_DrawLinesEG_N2DGraph()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D

 	DoWindow CCDImageToConvertFig
	if(V_Flag)
	     setDrawLayer/W=CCDImageToConvertFig ProgFront
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

		NVAR UseLineProfile=root:Packages:Convert2Dto1D:UseLineProfile
		Wave CCDImageToConvert=root:Packages:Convert2Dto1D:CCDImageToConvert_dis

		NVAR LineProf_UseBothHalfs=root:Packages:Convert2Dto1D:LineProf_UseBothHalfs
		NVAR LineProf_DistanceFromCenter=root:Packages:Convert2Dto1D:LineProf_DistanceFromCenter
		NVAR LineProf_Width=root:Packages:Convert2Dto1D:LineProf_Width
		NVAR LineProf_DistanceQ=root:Packages:Convert2Dto1D:LineProf_DistanceQ
		NVAR LineProf_WidthQ=root:Packages:Convert2Dto1D:LineProf_WidthQ
		SVAR LineProf_CurveType=root:Packages:Convert2Dto1D:LineProf_CurveType
	
		variable i, tempEndX, tempEndY, sectorCenterAngle, tempLength
		variable temp1, temp2, temp3, temp4
		variable CenterStartX, CenterStartY, CenterEndX, CenterEndY
		variable LeftStartX,LeftEndX,LeftStartY,leftEndY
		variable RightStartX,RightStartY,RightEndX,RightEndY
		NVAR LineProf_UseBothHalfs=root:Packages:Convert2Dto1D:LineProf_UseBothHalfs

		NVAR LineProf_LineAzAngle=root:Packages:Convert2Dto1D:LineProf_LineAzAngle
		NVAR LineProf_GIIncAngle=root:Packages:Convert2Dto1D:LineProf_GIIncAngle
		NVAR LineProf_EllipseAR=root:Packages:Convert2Dto1D:LineProf_EllipseAR

		variable isStraightLine
		if(UseLineProfile)
				//calculate coordinates for lines...

			if(stringMatch(LineProf_CurveType,"Angle Line"))
				isStraightLine=0
					make/O/N=(Dimsize(CCDImageToConvert, 0)) WaveX, WaveXL, WaveXR
					make/O/N=(Dimsize(CCDImageToConvert, 1)) WaveY, WaveYL, WaveYR
					EGNA_GenerAngleLine(Dimsize(CCDImageToConvert, 0),Dimsize(CCDImageToConvert, 1),xcenter,ycenter,LineProf_LineAzAngle,LineProf_DistanceFromCenter,WaveX,WaveY)
					EGNA_GenerAngleLine(Dimsize(CCDImageToConvert, 0),Dimsize(CCDImageToConvert, 1),xcenter,ycenter,LineProf_LineAzAngle,LineProf_DistanceFromCenter+LineProf_Width,WaveXL,WaveYL)
					EGNA_GenerAngleLine(Dimsize(CCDImageToConvert, 0),Dimsize(CCDImageToConvert, 1),xcenter,ycenter,LineProf_LineAzAngle,LineProf_DistanceFromCenter-LineProf_Width,WaveXR,WaveYR)
			endif
			if(stringMatch(LineProf_CurveType,"Ellipse"))
				isStraightLine=0
					make/O/N=(1440) WaveX, WaveXL, WaveXR
					make/O/N=(1440) WaveY, WaveYL, WaveYR
					EGNA_GenerEllipseLine(xcenter,ycenter,LineProf_EllipseAR,LineProf_DistanceFromCenter,WaveX,WaveY)
					EGNA_GenerEllipseLine(xcenter,ycenter,LineProf_EllipseAR,LineProf_DistanceFromCenter+LineProf_Width,WaveXL,WaveYL)
					EGNA_GenerEllipseLine(xcenter,ycenter,LineProf_EllipseAR, LineProf_DistanceFromCenter-LineProf_Width,WaveXR,WaveYR)
			endif
			if(stringMatch(LineProf_CurveType,"GISAXS_FixQy"))
				isStraightLine=0
					CenterStartY = DimSize(CCDImageToConvert, 1 )
					make/O/N=(CenterStartY) WaveX, WaveXL, WaveXR
					make/O/N=(CenterStartY) WaveY, WaveYL, WaveYR
					waveY=p
					WaveYL=p
					WaveYR=p
					variable Qy0=NI1GI_CalculateQxyz(LineProf_DistanceFromCenter-xcenter,ycenter,"Y")
					WaveX=NIGI_CalcYdimForFixQz(WaveY[p],Qy0)
					Qy0=NI1GI_CalculateQxyz(LineProf_DistanceFromCenter+LineProf_Width-xcenter,ycenter,"Y")
					WaveXL=NIGI_CalcYdimForFixQz(WaveY[p],Qy0)
					Qy0=NI1GI_CalculateQxyz(LineProf_DistanceFromCenter-LineProf_Width-xcenter,ycenter,"Y")
					WaveXR=NIGI_CalcYdimForFixQz(WaveY[p],Qy0)
			endif

			if(stringMatch(LineProf_CurveType,"Horizontal Line")||stringMatch(LineProf_CurveType,"GI_Horizontal Line"))
					isStraightLine=1
					CenterStartX = DimSize(CCDImageToConvert, 0 )
					leftStartX=DimSize(CCDImageToConvert, 0 )
					RightStartX=DimSize(CCDImageToConvert, 0 )
					CenterEndX = 0
					LeftEndX=0
					RightEndY=0
					CenterStartY=ycenter-LineProf_DistanceFromCenter
					LeftStartY=CenterStartY+LineProf_Width
					RightStartY=CenterStartY-LineProf_Width
					CenterEndY=ycenter-LineProf_DistanceFromCenter
					LeftEndY=CenterEndY+LineProf_Width
					RightEndY=CenterEndY-LineProf_Width
			endif

			if(stringMatch(LineProf_CurveType,"Vertical Line")||stringMatch(LineProf_CurveType,"GI_Vertical Line"))
					isStraightLine=1
					CenterStartY = DimSize(CCDImageToConvert, 1 )
					LeftStartY = DimSize(CCDImageToConvert, 1 )
					RightStartY = DimSize(CCDImageToConvert, 1 )
					CenterEndY = 0
					LeftEndY = 0
					RightEndY = 0
					CenterStartX=Xcenter+LineProf_DistanceFromCenter
					LeftStartX=Xcenter+LineProf_DistanceFromCenter+LineProf_Width
					RightStartX=Xcenter+LineProf_DistanceFromCenter-LineProf_Width
					CenterEndX=xcenter+LineProf_DistanceFromCenter
					LeftEndX=xcenter+LineProf_DistanceFromCenter+LineProf_Width
					RightEndX=xcenter+LineProf_DistanceFromCenter-LineProf_Width
			endif

			if(isStraightLine)
				string AxList= AxisList("CCDImageToConvertFig" )
				if(stringMatch(axlist,"*top*"))
					setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=top,ycoord=left,save
				else
					setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=bottom,ycoord=left,save
				endif
				SetDrawEnv/W=CCDImageToConvertFig linefgc= (8704,8704,8704),dash= 7  
				SetDrawEnv /W=CCDImageToConvertFig linethick=2
				Drawline/W=CCDImageToConvertFig CenterStartX,CenterStartY,centerEndX,CenterEndY
				SetDrawEnv/W=CCDImageToConvertFig linefgc= (65280,65280,0)
				SetDrawEnv /W=CCDImageToConvertFig dash= 2,linethick= 1.00
				Drawline/W=CCDImageToConvertFig LeftStartX,LeftStartY,leftEndX,leftEndY
				SetDrawEnv/W=CCDImageToConvertFig linefgc= (65280,65280,0)
				SetDrawEnv /W=CCDImageToConvertFig dash= 2,linethick= 1.00
				Drawline/W=CCDImageToConvertFig RightStartX,RightStartY,RightEndX,RightEndY
				
			else
					setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=bottom,ycoord=left,save
					SetDrawEnv/W=CCDImageToConvertFig linefgc= (8704,8704,8704),dash= 7  
					SetDrawEnv /W=CCDImageToConvertFig linethick=2
//					DrawPoly /W=CCDImageToConvertFig/ABS  0, 0,1,1, WaveX, WaveY
					SetDrawEnv/W=CCDImageToConvertFig linefgc= (65280,65280,0)
					SetDrawEnv /W=CCDImageToConvertFig dash= 2,linethick= 1.00
					DrawPoly /W=CCDImageToConvertFig/ABS  0, 0,1,1, WaveXL, WaveYL
					SetDrawEnv/W=CCDImageToConvertFig linefgc= (65280,65280,0)
					SetDrawEnv /W=CCDImageToConvertFig dash= 2,linethick= 1.00
					DrawPoly /W=CCDImageToConvertFig/ABS  0, 0,1,1, WaveXR, WaveYR
			endif
		//mirror line, if needed... for 
				if(LineProf_UseBothHalfs && isStraightLine)
						//calculate coordinates for lines...
					if(stringMatch(LineProf_CurveType,"Horizontal Line")||stringMatch(LineProf_CurveType,"GI_Horirontal Line"))
							CenterStartX = DimSize(CCDImageToConvert, 0 )
							leftStartX=DimSize(CCDImageToConvert, 0 )
							RightStartX=DimSize(CCDImageToConvert, 0 )
							CenterEndX = 0
							LeftEndX=0
							RightEndY=0
							CenterStartY=ycenter+LineProf_DistanceFromCenter
							LeftStartY=CenterStartY+LineProf_Width
							RightStartY=CenterStartY-LineProf_Width
							CenterEndY=ycenter+LineProf_DistanceFromCenter
							LeftEndY=CenterEndY+LineProf_Width
							RightEndY=CenterEndY-LineProf_Width
					endif
		
					if(stringMatch(LineProf_CurveType,"Vertical Line")||stringMatch(LineProf_CurveType,"GI_Vertical Line"))
							CenterStartY = DimSize(CCDImageToConvert, 1 )
							LeftStartY = DimSize(CCDImageToConvert, 1 )
							RightStartY = DimSize(CCDImageToConvert, 1 )
							CenterEndY = 0
							LeftEndY = 0
							RightEndY = 0
							CenterStartX=Xcenter-LineProf_DistanceFromCenter
							LeftStartX=CenterStartX+LineProf_Width
							RightStartX=CenterStartX-LineProf_Width
							CenterEndX=xcenter-LineProf_DistanceFromCenter
							LeftEndX=CenterEndX+LineProf_Width
							RightEndX=CenterEndX-LineProf_Width
					endif
		
						 AxList= AxisList("CCDImageToConvertFig" )
						if(stringMatch(axlist,"*top*"))
							setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=top,ycoord=left,save
						else
							setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=bottom,ycoord=left,save
						endif
						SetDrawEnv/W=CCDImageToConvertFig linefgc= (8704,8704,8704),dash= 7  
						SetDrawEnv /W=CCDImageToConvertFig linethick=2
						Drawline/W=CCDImageToConvertFig CenterStartX,CenterStartY,centerEndX,CenterEndY
						SetDrawEnv/W=CCDImageToConvertFig linefgc= (65280,65280,0)
						SetDrawEnv /W=CCDImageToConvertFig dash= 2,linethick= 1.00
						Drawline/W=CCDImageToConvertFig LeftStartX,LeftStartY,leftEndX,leftEndY
						SetDrawEnv/W=CCDImageToConvertFig linefgc= (65280,65280,0)
						SetDrawEnv /W=CCDImageToConvertFig dash= 2,linethick= 1.00
						Drawline/W=CCDImageToConvertFig RightStartX,RightStartY,RightEndX,RightEndY
				endif
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

Function EGNA_GenerAngleLine(DetDimX,DetDimY,BCx,BCy,Angle,Offset,WaveX,WaveY)
	variable DetDimX,DetDimY,BCx,BCy,Angle,Offset
	Wave WaveX,WaveY
	//generate X-Y path for angle line on the detector
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	
	make/O/N=(DetDimX) tempWvX
	make/O/N=(DetDimY) tempWvY
	if(abs(angle)<45)
		tempWvX=p
		tempWvY=BCy-(tempWvX-BCx)*tan(Angle*pi/180)
	elseif(abs(angle)>=45 || abs(angle)<135)
		tempWvY=p
		tempWvX=BCx+(tempWvY-BCy)*tan((Angle-90)*pi/180)
	else
		tempWvX=p
		tempWvY=BCy-(tempWvX-BCx)*tan(Angle*pi/180)	
	endif
	//now offset the line by the geometrically corrected offset...
	if(abs(angle)<45)
		tempWvY-=Offset / cos(Angle*pi/180)
	elseif(abs(angle)>=45 || abs(angle)<135)
		tempWvX-=Offset / sin((Angle)*pi/180) 
	else
		tempWvY-=Offset / cos(Angle*pi/180)	
	endif
	WaveX=tempWvX
	WaveY=tempWvY
	killWaves tempWvY, tempWvX
	
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_GenerEllipseLine(BCx,BCy,Excentricity,Offset,WaveX,WaveY)
	variable Excentricity,BCx,BCy,Offset
	Wave WaveX,WaveY
	//generate X-Y path for angle line on the detector
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	
	
	Redimension/N=(1440) WaveX,WaveY
	WaveX = BCx + Offset * cos(p*(pi/720))
	WaveY = BCy + Offset * Excentricity* sin(p*(pi/720))
	
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_GenerGISAXSQyLine(DetDimX,DetDimY,BCx,BCy,Angle,Offset,WaveX,WaveY)
	variable DetDimX,DetDimY,BCx,BCy,Angle,Offset
	Wave WaveX,WaveY
	//generate X-Y path for angle line on the detector
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	
	make/O/N=(DetDimX) tempWvX
	make/O/N=(DetDimY) tempWvY



	WaveX=tempWvX
	WaveY=tempWvY
	killWaves tempWvY, tempWvX
	
	setDataFolder OldDf
end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NI1GI_CalculateQxyz(DimXpos,DimYpos,WhichOne)
	variable DimXpos,DimYpos
	String WhichOne
	
	NVAR ycenter=root:Packages:Convert2Dto1D:BeamCenterY
	

		
	
	NVAR xcenter=root:Packages:Convert2Dto1D:BeamCenterX
	NVAR LineProf_GIIncAngle=root:Packages:Convert2Dto1D:LineProf_GIIncAngle
	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance
	NVAR Wavelength=root:Packages:Convert2Dto1D:Wavelength
	NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
	NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
	
	// edited by eliot to use already calculated the q values (and include qxy as valid option)
	//begin old code
//	variable K0val=2*pi/wavelength
//	variable TwoThetaF=atan((xcenter-DimXpos)*PixelSizeX /SampleToCCDDistance)
//	variable alphaF = atan((ycenter - DimYpos)*PixelSizeY /SampleToCCDDistance)
//	variable alphaI = LineProf_GIIncAngle * pi / 180
//	if(stringmatch(WhichOne,"X"))
////		variable Qx = K0val * (cos(TwoThetaF)*cos(AlphaF) - cos(AlphaI))
//		return Qx
//	elseif(stringmatch(WhichOne,"Y"))
////		variable Qy = -1 * K0val * (sin(TwoThetaF)*cos(AlphaF))
//		return Qy
//	elseif(stringmatch(WhichOne,"Z"))
////		variable Qz = K0val * (sin(alphaF)+sin(alphaI))  // old way  I don't think this is right (Eliot)
//		variable Qz = 2* K0val * (sin(   atan( ((ycenter-DimYpos)*PixelsizeY/SampletoCCDDistance  - tan(2*AlphaI)  )/2 ) )  // this is assuming the reflected beam location is the 0q location
//														// also this assumes that the reflected beam is normal to the detector, not the direct beam
//		return Qz
//	else
//		RETURN 0
//	endif
	// end old code
	
	// start new code
	if(stringmatch(WhichOne,"X"))
		wave qxwave = root:Packages:Convert2Dto1D:qxwave
		return qxwave[dimxpos][dimypos]
	elseif(stringmatch(WhichOne,"Y"))
		wave qywave = root:Packages:Convert2Dto1D:qywave
		return qywave[dimxpos][dimypos]
	elseif(stringmatch(WhichOne,"Z"))
		wave qzwave = root:Packages:Convert2Dto1D:qzwave
		return qzwave[dimxpos][dimypos]
	elseif(stringmatch(WhichOne,"XY"))
		wave qxywave = root:Packages:Convert2Dto1D:qxywave
		return qxywave[dimxpos][dimypos]
	elseif(stringmatch(WhichOne,"xypure"))
		wave qxypure = root:Packages:Convert2Dto1D:qxypure
		return qxypure[dimxpos][dimypos]
	elseif(stringmatch(WhichOne,"zpure"))
		wave qzpure = root:Packages:Convert2Dto1D:qzpure
		return qzpure[dimxpos][dimypos]
	elseif(stringmatch(WhichOne,"XZ"))
		wave qxzwave = root:Packages:Convert2Dto1D:qxzwave
		return qxzwave[dimxpos][dimypos]
	else
		RETURN 0
	endif
	
	
	
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************//
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function NIGI_CalcYdimForFixQz(DimYPos,Qy)
	variable DimYPos	//this defines really Qz in pixel value
	variable Qy			//for which value of Qy we want to calcualte this?

	NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance
	NVAR xcenter=root:Packages:Convert2Dto1D:BeamCenterX
	NVAR Wavelength=root:Packages:Convert2Dto1D:Wavelength
	NVAR LineProf_GIIncAngle=root:Packages:Convert2Dto1D:LineProf_GIIncAngle
	variable alphaI = LineProf_GIIncAngle * pi / 180
	
	variable Qz=NI1GI_CalculateQxyz(0,DimYpos,"Z")
	variable K0val=2*pi/wavelength
	
	variable sinAlphaF = (Qz  - K0val *sin(alphaI))/K0val
	variable AlphaF = asin(sinAlphaF)
	
	variable sEG_N2ThetaF = Qy/(k0val * cos(AlphaF))
	variable TwoThetaF = asin(sEG_N2ThetaF)
	//and now convert to pixel units...
//	variable TwoThetaF=atan((xcenter-DimXpos)*PixelSizeX /SampleToCCDDistance)
	variable DimXpos = -1* xcenter + tan(TwoThetaF) * SampleToCCDDistance / PixelSizeX
	
	return DimXpos

end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_DrawCenterEG_N2DGraph()
	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
 	DoWindow CCDImageToConvertFig
	NVAR displaybeamcenterEG_N2Dgraph=root:Packages:Convert2Dto1D:displaybeamcenterEG_N2Dgraph
	if(V_Flag&&displaybeamcenterEG_N2Dgraph)
	     setDrawLayer/W=CCDImageToConvertFig ProgFront
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
		if(stringMatch(AxisList("CCDImageToConvertFig"),"*top*"))
			setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=top,ycoord=left,save
		else
			setdrawenv/W=CCDImageToConvertFig fillpat=0,xcoord=bottom,ycoord=left,save
		endif
		SetDrawEnv/W=CCDImageToConvertFig linefgc=(65535, 65535,65535 )
		SetDrawEnv /W=CCDImageToConvertFig linethick=3
		DrawOval/W=CCDImageToConvertFig xcenter-2, ycenter+2, xcenter+2, ycenter-2
		SetDrawEnv/W=CCDImageToConvertFig linefgc=(65535, 0,0 )
		SetDrawEnv/W=CCDImageToConvertFig linethick=2
		DrawOval/W=CCDImageToConvertFig xcenter-10, ycenter+10, xcenter+10, ycenter-10
		SetDrawEnv/W=CCDImageToConvertFig linefgc=(65535, 0,0 )
		SetDrawEnv/W=CCDImageToConvertFig linethick=2
		DrawOval/W=CCDImageToConvertFig xcenter-50, ycenter+50, xcenter+50, ycenter-50
		SetDrawEnv/W=CCDImageToConvertFig linefgc=(65535, 0,0 )
		SetDrawEnv/W=CCDImageToConvertFig linethick=2
		DrawOval/W=CCDImageToConvertFig xcenter-200, ycenter+200, xcenter+200, ycenter-200
	      setDrawLayer/W=CCDImageToConvertFig UserFront
	  endif
	  	setDataFolder OldDf
EndMacro
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_AllDrawingsFrom2DGraph()
	DoWindow CCDImageToConvertFig
	if(V_Flag)
	      setDrawLayer/W=CCDImageToConvertFig/K ProgFront
	      setDrawLayer/W=CCDImageToConvertFig UserFront
	 endif
end


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_SetCalibrationFormula()

	string oldDf=GetDataFOlder(1)
	setDataFolder root:Packages:Convert2Dto1D
	SVAR CalibrationFormula=root:Packages:Convert2Dto1D:CalibrationFormula
	NVAR UseSampleThickness= root:Packages:Convert2Dto1D:UseSampleThickness
	NVAR UseSampleTransmission= root:Packages:Convert2Dto1D:UseSampleTransmission
	NVAR UseCorrectionFactor= root:Packages:Convert2Dto1D:UseCorrectionFactor
	NVAR UseSolidAngle= root:Packages:Convert2Dto1D:UseSolidAngle
	NVAR UseMask= root:Packages:Convert2Dto1D:UseMask
	NVAR UseDarkField= root:Packages:Convert2Dto1D:UseDarkField
	NVAR UseEmptyField= root:Packages:Convert2Dto1D:UseEmptyField
	NVAR UseSubtractFixedOffset= root:Packages:Convert2Dto1D:UseSubtractFixedOffset
	NVAR UseSampleMeasTime= root:Packages:Convert2Dto1D:UseSampleMeasTime
	NVAR UseEmptyMeasTime= root:Packages:Convert2Dto1D:UseEmptyMeasTime
	NVAR UseDarkMeasTime= root:Packages:Convert2Dto1D:UseDarkMeasTime
	NVAR UsePixelSensitivity= root:Packages:Convert2Dto1D:UsePixelSensitivity
	NVAR UseI0ToCalibrate = root:Packages:Convert2Dto1D:UseI0ToCalibrate
	NVAR UseMonitorForEF = root:Packages:Convert2Dto1D:UseMonitorForEF

	string PreProcess=""
	string SampleString=""
	if(UseCorrectionFactor)
		PreProcess+="C"
	endif
	if(strlen(PreProcess)==0)
		PreProcess+="1"
	endif
	if(UseSolidAngle)
		PreProcess+="/O"
	endif
	if(UseI0ToCalibrate)
		PreProcess+="/I0"
	endif
	if(UseSampleThickness)
		PreProcess+="/St"
	endif

	if(strlen(PreProcess)>0)
		SampleString+="*"
	endif
	if(UseSampleTransmission)
		SampleString+="(1/T*"
	else
		SampleString+="("
	endif
//	if(strlen(SampleString)>2)
//		SampleString+="*"
//	endif
	if(UsePixelSensitivity)
		SampleString+="(Sa2D/Pix2D"
	else
		SampleString+="(Sa2D"
	endif
	if(UseSubtractFixedOffset)
		SampleString+="-Ofst"
	endif
	if(UseDarkField)
		if(UseSampleMeasTime && UseDarkMeasTime)
			if(UsePixelSensitivity)
				SampleString+="-(ts/td)*DF2D/Pix2D"
			else
				SampleString+="-(ts/td)*DF2D"
			endif
		else
			if(UsePixelSensitivity)
				SampleString+="-DF2D/Pix2D"
			else
				SampleString+="-DF2D"
			endif
		endif
	endif
		SampleString+=")"
	
		string EmptyStr=""
	if(UseEmptyField)
		EmptyStr+="-"
		if(UseMonitorForEF)
			EmptyStr+="I0/I0ef"
		elseif(UseEmptyMeasTime && UseSampleMeasTime)
			EmptyStr+="ts/te"
		endif
		if(strlen(EmptyStr)>2)
			EmptyStr+="*"
		endif
		if(UsePixelSensitivity)
			EmptyStr+="(EF2D/Pix2D"
		else
			EmptyStr+="(EF2D"
		endif
	if(UseSubtractFixedOffset)
		EmptyStr+="-Ofst"
	endif
		if(UseDarkField)
			if(UseSampleMeasTime && UseEmptyMeasTime)
				if(UsePixelSensitivity)
					EmptyStr+="-(te/td)*(DF2D/Pix2D"
				else
					EmptyStr+="-(te/td)*(DF2D"
				endif
			else
				if(UsePixelSensitivity)
					EmptyStr+="-DF2D/Pix2D"
				else
					EmptyStr+="-DF2D"
				endif
			endif
		endif
		EmptyStr+=")"
	endif

	CalibrationFormula = PreProcess+SampleString+EmptyStr+")"
	setDataFolder OldDf
end

//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************

Function EGNA_DezingerImage(image)
        Wave image
        string OldDf=GetDataFOlder(1)
        setDataFolder root:Packages:Convert2Dto1D
 	 NVAR DezingerRatio =root:Packages:Convert2Dto1D:DezingerRatio
 	 string OldNote=note(image)
        Duplicate/O image, dup, DiffWave, FilteredDiffWave
        Redimension/S DiffWave, FilteredDiffWave    	    // make single precision
        MatrixFilter /N=3 median image				    // 3x3 median filter (integer result if image integer, fp if fp)
        MatrixOp/O DiffWave = dup / (abs(image))          	  	    // difference between raw and filtered, high values (>35) are cosmics and high signals
       //image = SelectNumber(DiffWave>DezingerRatio,dup,image)    // choose filtered (image) if difference is great
   	MatrixOp/O image = dup * (-1)*(greater(Diffwave,DezingerRatio)-1) + image*(greater(Diffwave,DezingerRatio))
	//the MatrxiOp is 3x faster than the original line.... 
	note image, OldNote
        KillWaves/Z DiffWave, FilteredDiffWave, dup
        setDataFolder OldDf
End


//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//*******************************************************************************************************************************************
//************************************************************************
//************************************************************************
//************************************************************************

Function NI1G_AddQAxisToImage(UseGrids)
	variable UseGrids
	
		//EGNA_Create2DQWave(CCDImageToConvert)
		//EGNA_Create2DQWave(CCDImageToConvert)
		string OldDf = GetDataFolder(1)
		setDataFolder root:Packages:Convert2Dto1D

		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		if(UseGrazingIncidence)
			//GI_ReHistImage()
		else
			EGNA_Create2DQWave(root:packages:Convert2Dto1D:CCDImageToConvert)
		endif
	
	DoWIndow CCDImageToConvertFig
	if(!V_flag)
		abort
	else
		DoWIndow/F CCDImageToConvertFig
	endif
	//OK, image exists... Now we need to check the image does nto have transform axis. 
	string ImgRecreationStr=WinRecreation("CCDImageToConvertFig", 0 )
	
	variable UsesTopAxis
	string HorAxisName, MT_HorAxisname
	
	if(stringMatch(AxisList("CCDImageToConvertFig"),"*top;*"))
		UsesTopAxis=1
		HorAxisName="top"
		MT_HorAxisname="MT_top"
	else
		UsesTopAxis=0		//uses bottom axis in the image (Inverted 0,0)
		HorAxisName="bottom"
		MT_HorAxisname="MT_bottom"
	endif
	
	//and now we need to add the transform axes to the image
	if(!stringmatch(ImgRecreationStr, "*MT_left*" ))
		SetupTransformMirrorAxis("CCDImageToConvertFig", "left", "TransAx_CalculateVerticalQaxis", $"", 7, 1, 5, 0)
	endif
	
	if(!stringmatch(ImgRecreationStr, "*MT_top*" )&&!stringmatch(ImgRecreationStr, "*MT_bottom*" ))
		SetupTransformMirrorAxis("CCDImageToConvertFig", HorAxisName, "TransAx_CalculateHorizQaxis", $"", 7, 1, 5, 0)
	endif
	SetWindow CCDImageToConvertFig, hook(MyKillGraphHook) = NI1U_KillWindowHookF
	//And now we need to format them. 

		SVAR LineProf_CurveType=root:Packages:Convert2Dto1D:LineProf_CurveType
		NVAR UseLineProfile = root:Packages:Convert2Dto1D:UseLineProfile



	ModifyGraph margin=40
	ModifyGraph noLabel(left)=1, noLabel($(HorAxisName))=1
		if(UseLineProfile && (stringMatch(LineProf_CurveType,"GI_Vertical Line") || stringMatch(LineProf_CurveType,"GI_Horizontal Line")))
				Label left "\\Z14q\\Bz\\M\\Z14 [�\\S-1\\M\\Z14]"		
		else
				Label left "\\Z14q\\Bz\\M\\Z14 [�\\S-1\\M\\Z14]"		
		endif
	Label $(HorAxisName) "\\Z14q\\Bxy\\M\\Z14 [�\\S-1\\M\\Z14]"
	ModifyGraph tick(left)=3, tick($(HorAxisName))=3
	ModifyGraph grid=0
	DoUpdate	
	ModifyGraph tick(MT_left)=0 , tick($(MT_HorAxisname))=0
		if(UseLineProfile && (stringMatch(LineProf_CurveType,"GI_Vertical Line") || stringMatch(LineProf_CurveType,"GI_Horizontal Line")))
			Label MT_left "\\Z14q\\Bz\\M\\Z14 [�\\S-1\\M\\Z14]"
		else
			Label MT_left "\\Z14q\\Bz\\M\\Z14 [�\\S-1\\M\\Z14]"
		endif
	Label $(MT_HorAxisname) "\\Z14q\\Bxy\\M\\Z14 [�\\S-1\\M\\Z14]"
	ModifyGraph noLabel(MT_left)=0 , nolabel($(MT_HorAxisname))=0
	ModifyGraph mirror(MT_left)=3 , mirror($(MT_HorAxisname))=3
	ModifyGraph lblPos(MT_left)=40,lblLatPos=0
	ModifyGraph lblPos($(MT_HorAxisname))=35,lblLatPos=0
	if(UseGrids)
		ModifyGraph grid(MT_left)=1
		ModifyGraph grid($(MT_HorAxisname))=1
	endif
	setDataFolder oldDf
end
//************************************************************************
//************************************************************************
//************************************************************************

Function NI1G_RemoveQAxisToImage(Recreate)
	variable Recreate
	
		string OldDf = GetDataFolder(1)
		setDataFolder root:Packages:Convert2Dto1D
		
	DoWIndow CCDImageToConvertFig
	if(!V_flag)
		abort
	else
		DoWIndow/F CCDImageToConvertFig
	endif
	//OK, image exists... Now we need to check the image does nto have transform axis. 
	string ImgRecreationStr=WinRecreation("CCDImageToConvertFig", 0 )
	
	//and now we need to add the transform axes to the image
	if(stringmatch(ImgRecreationStr, "*MT_left*" )||stringmatch(ImgRecreationStr, "*MT_top*" )||stringmatch(ImgRecreationStr, "*MT_bottom*" ))
		CloseTransformAxisGraph("CCDImageToConvertFig", 0)
	endif
	
	if(Recreate)

		
		wave importeddata
		// Eliot adding this for Grazing Incidence Warping of image
		duplicate/o importeddata, CCDImageToConvert
		EGNA_DisplayLoadedFile()
		EGNA_DisplayStatsLoadedFile("CCDImageToConvert")
		EGNA_TopCCDImageUpdateColors(1)
		EGNA_DoDrawingsInto2DGraph()
	endif
	
	setDataFolder oldDf
end

//************************************************************************
//************************************************************************
//************************************************************************
Function NI1U_UpdateQAxisInImage()
	DoWIndow CCDImageToConvertFig
	if(!V_flag)
		abort
	endif
	//OK, image exists... Now we need to check the image does nto have transform axis. 
	string ImgRecreationStr=WinRecreation("CCDImageToConvertFig", 0 )
	
	//and now we need to add the transform axes to the image
	if(stringmatch(ImgRecreationStr, "*MT_left*" ))
		TicksForTransformAxis("CCDImageToConvertFig", "left",  7, 1, 5,"MT_left", 0,1)
	endif
	if(stringmatch(ImgRecreationStr, "*MT_top*" ))
		TicksForTransformAxis("CCDImageToConvertFig", "top",  7, 1, 5,"MT_top",0 ,1)
	endif
	
end
//************************************************************************
//************************************************************************
//************************************************************************

Function NI1U_KillWindowHookF(s)
	STRUCT WMWinHookStruct &s
	
	Variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.

	switch(s.eventCode)
		case 17:					// Keyboard event
					Print "Killed the window"
					hookResult = 1
					NI1G_RemoveQAxisToImage(0)
			break
	endswitch

	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End

//************************************************************************
//************************************************************************
//************************************************************************

Function TransAx_CalculateVerticalQaxis(w, x)
	Wave/Z w
	Variable x		//in pixels


		SVAR LineProf_CurveType=root:Packages:Convert2Dto1D:LineProf_CurveType
		NVAR HorizontalTilt=root:Packages:Convert2Dto1D:HorizontalTilt
		NVAR VerticalTilt=root:Packages:Convert2Dto1D:VerticalTilt
		NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
		NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
		NVAR UseLineProfile = root:Packages:Convert2Dto1D:UseLineProfile
		NVAR SampleToCCDDistance = root:Packages:Convert2Dto1D:SampleToCCDDistance
		NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength
		NVAR InvertImages = root:Packages:Convert2Dto1D:InvertImages
		NVAR grazingangle=root:Packages:Convert2Dto1D:LineProf_GIIncAngle
		NVAR reflbeam=root:Packages:Convert2Dto1D:reflbeam

		NVAR BeamCenterX=root:Packages:Convert2Dto1D:BeamCenterX
		NVAR BeamCenterY=root:Packages:Convert2Dto1D:BeamCenterY

		variable PixPosition= x
		variable DistanceInmmPixPos
		variable DistInQ
		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		//wave/z qzpure = root:Packages:Convert2Dto1D:Qxypure
		if(usegrazingincidence)
			//wave data = root:Packages:Convert2Dto1D:ccdimagetoconvert
			//distinq = dimdelta(data,1) * (x-beamcentery)
			if(InvertImages)
				if(reflbeam==1)
					distinq = -4*pi*sin(atan((-x+beamcentery)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength
				elseif(reflbeam==2)
					distinq = -4*pi*sin(grazingangle*pi/180 + atan((-x+beamcentery)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength
				else
					distinq = -4*pi*sin(.5*grazingangle*pi/180 + atan((-x+beamcentery)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength
				endif
			else
				if(reflbeam==1)
					distinq = -4*pi*sin(atan((x-beamcentery)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength
				elseif(reflbeam==2)
					distinq = -4*pi*sin(grazingangle*pi/180 + atan((x-beamcentery)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength
				else
					distinq = -4*pi*sin(.5*grazingangle*pi/180 + atan((x-beamcentery)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength
				endif
			endif
			//distinq = NI1GI_CalculateQxyz(BeamCentery,PixPosition,"z") //4*pi*sin((x-beamcentery)*PixelSizey/(2*SampleToCCDDistance))/Wavelength
		elseif(UseLineProfile && (stringMatch(LineProf_CurveType,"GI_Vertical Line") || stringMatch(LineProf_CurveType,"GI_Horizontal Line")))
			// this is exception,  need to use GI geometry for conversion, All other should eb the same...
			DistInQ=NI1GI_CalculateQxyz(BeamCenterX,PixPosition,"Z")
		else
			PixPosition=BeamCenterY - x
			DistanceInmmPixPos = PixPosition * PixelSizeY
			//let's not worry about tilsts here, this is just approximate
			DistInQ=EGNA_LP_ConvertPosToQ(DistanceInmmPixPos, SampleToCCDDistance, Wavelength)
		endif
		
		if(InvertImages)
			//DistInQ*=-1
		endif

	return  DistInQ
end

//************************************************************************
//************************************************************************
//************************************************************************

Function TransAx_CalculateHorizQaxis(w, x)
	Wave/Z w
	Variable x		//in pixels
//print x

		SVAR LineProf_CurveType=root:Packages:Convert2Dto1D:LineProf_CurveType
		NVAR HorizontalTilt=root:Packages:Convert2Dto1D:HorizontalTilt
		NVAR VerticalTilt=root:Packages:Convert2Dto1D:VerticalTilt
		NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
		NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
		NVAR UseLineProfile = root:Packages:Convert2Dto1D:UseLineProfile
		NVAR SampleToCCDDistance = root:Packages:Convert2Dto1D:SampleToCCDDistance
		NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength

		NVAR BeamCenterX=root:Packages:Convert2Dto1D:BeamCenterX
		NVAR BeamCenterY=root:Packages:Convert2Dto1D:BeamCenterY

		variable PixPosition=x
		variable DistanceInmmPixPos
		variable DistInQ

		NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
		//wave/z qxypure = root:Packages:Convert2Dto1D:Qxypure
		if(usegrazingincidence)
			//wave data = root:Packages:Convert2Dto1D:ccdimagetoconvert
			//distinq = NI1GI_CalculateQxyz(BeamCenterX,PixPosition,"xy") 
			distinq = 4*pi*sin(atan((x-beamcenterx)*PixelSizeX/(SampleToCCDDistance))/2)/Wavelength
			//dimdelta(data,0) * (x-beamcenterx)
		elseif(UseLineProfile && (stringMatch(LineProf_CurveType,"GI_Vertical Line") || stringMatch(LineProf_CurveType,"GI_Horizontal Line")))
			// this is exception,  need to use GI geometry for conversion, All other should eb the same...
			DistInQ=NI1GI_CalculateQxyz(PixPosition,BeamCenterY,"xypure") // Eliot changing this to xypure rather than "Y"
		else
			PixPosition=BeamCenterX-x
			DistanceInmmPixPos = PixPosition * PixelSizeX
			//let's not worry about tilsts here, this is just approximate
			DistInQ=EGNA_LP_ConvertPosToQ(DistanceInmmPixPos, SampleToCCDDistance, Wavelength)
		endif

		return DistInQ
end
//************************************************************************
//************************************************************************
//************************************************************************


//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_testThetaWithTilts()		// calculate theta for pixel px, py - optionally reset parameters from defaluts, else read stored structure
	
	STRUCT NikadetectorGeometry d
	wave testImg
		NI2T_ReadOrientationFromGlobals(d)
		NI2T_SaveStructure(d)
		NI2t_printDetectorStructure(d)
//variable startTicks=ticks	
//	multithread testImg =  NI2T_pixel2Theta(d,p,q)
//print (ticks-startTicks)/60
end

//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_Calculate2DThetaWithTilts(Theta2DWave)		// calculate theta for pixel px, py
	wave Theta2DWave
	STRUCT NikadetectorGeometry d

		NI2T_ReadOrientationFromGlobals(d)
		NI2T_SaveStructure(d)
		Multithread Theta2DWave =  NI2T_pixelTheta(d,p,q)
end


//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

  Function/C NI2T_CalculatePxPyWithTilts(theta, direction)  
	variable theta, direction
	//theta is bragg angle in question
	//direction is azimuthal angle in radians
	variable TwoTheta= 2*theta		//theta of this px, py with tilts
	variable px,py
	NVAR BeamCenterX = root:Packages:Convert2Dto1D:BeamCenterX
	NVAR BeamCenterY = root:Packages:Convert2Dto1D:BeamCenterY
	px=  cos(direction)
	py=  sin(direction)
	variable GammaAngle=NI2T_CalculateGammaWithTilts(px,py)		//gamma angle
	variable SDD
	NVAR SampleToCCDDistance = root:Packages:Convert2Dto1D:SampleToCCDDistance	//in mm
	NVAR PixelSizeX=root:Packages:Convert2Dto1D:PixelSizeX
	NVAR PixelSizeY=root:Packages:Convert2Dto1D:PixelSizeY
	SDD=SampleToCCDDistance/(0.5*(PixelSizeX+PixelSizeY))
	variable OtherAngle = pi - TwoTheta - GammaAngle
	variable distance = SDD*sin(TwoTheta)/sin(OtherAngle)		//distance in pixels from beam center 
	variable pxR = BeamCenterX+distance*cos(direction)
	variable pyR = BeamCenterY+distance*sin(direction)
	
	return cmplx(pxR,pyR)
	
end

//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_CalculateGammaWithTilts(px,py)		// calculate theta for pixel px, py - optionally reset parameters from defaluts, else read stored structure
	variable  px, py
	
	STRUCT NikadetectorGeometry d
	
		NI2T_ReadOrientationFromGlobals(d)
		NI2T_SaveStructure(d)
	
	return  NI2T_pixelGamma(d,px,py)
end
//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_pixelGamma(d,px,py)				// returns 2-theta (rad)
	STRUCT NikadetectorGeometry &d
	Variable px,py									// pixel position, 0 based, first pixel is (0,0), NOT (1,1)

	make/FREE/N=3 ki
	make/FREE/N=3 kout
	ki = {0,0,1}									//	ki =   ki[p],  incident beam direction

	NI2T_pixel3XYZ(d,px,py,kout)						// kout is in direction of pixel in beam line coords...
	//MatrixOp/O kout= Normalize(kout)
	NI2T_normalize(kout)

	Variable Theta =pi- acos(MatrixDot(kout,ki))   	// ki.kf = cos(2theta), (radians)
	//comment: Added pi - acos here on May 28, 2011. It should be right now. Tested on 45 degree image and needed to agree with the image and analyzed data.. 
	//MatrixOp/O Theta =acos(kout.ki)   	// ki.kf = cos(2theta), (radians)
 
 	return Theta
End


//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_pixel3XYZ(d,px,py,xyz)					// convert pixel position to the beamline coordinate but with detector not moved. 
	STRUCT NikadetectorGeometry, &d
	Variable px,py									// pixel position on detector (full chip & zero based)
	Wave xyz											// 3-vector to receive the result, position in beam line coords (micron)

	Variable xp,yp, zp									// x' and y' (requiring z'=0), detector starts centered on origin and perpendicular to z-axis
	//d.P[0] is Beam center x position in pixels
	//d.P[1] is Beam center y position in pixels
	//d.P[2] is SDD in pixels
//	xp = (px - d.P[0]) //* d.sizeX/d.Nx					// (x' y' z'), position on detector, but with respect to beam center now (not center of detector)
//	yp = (py - d.P[1]) //* d.sizeY/d.Ny					//now in pixels
//	zp = 0								      				 // 
	xp = (px) //* d.sizeX/d.Nx					// (x' y' z'), position on detector, but with respect to beam center now (not center of detector)
	yp = (py) //* d.sizeY/d.Ny					//now in pixels
	zp = 0								      				 // 

	xyz[0] = d.rho00*xp + d.rho01*yp + d.rho02*zp	// xyz = rho x [ (x' y' z') + P ]
	xyz[1] = d.rho10*xp + d.rho11*yp + d.rho12*zp	// rho is pre-calculated from vector d.R
	xyz[2] = d.rho20*xp + d.rho21*yp + d.rho22*zp

//	xyz[2] += d.P[2]								      			 //translate by P distance from sample in pixles. 
//do nto move here, we need this without move to calculate gamma angle

End

//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_CalculateThetaWithTilts2(px,py)		// calculate theta for pixel px, py - optionally reset parameters from defaluts, else read stored structure
	variable  px, py
	
	STRUCT NikadetectorGeometry d
//	NI2T_LoadStructure(d)
	NI2T_ReadOrientationFromGlobals(d)
	NI2T_SaveStructure(d)
	variable theta = NI2T_pixelTheta(d,px,py)	
	return theta								
end
//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_CalculateThetaWithTilts(px,py,resetParameters)		// calculate theta for pixel px, py - optionally reset parameters from defaluts, else read stored structure
	variable  px, py, resetParameters
	
	STRUCT NikadetectorGeometry d
	
	if(resetParameters&&px==0&&py==0)					//read default parameters from defaults 
		NI2T_ReadOrientationFromGlobals(d)
		NI2T_SaveStructure(d)
	else										//read stored structure
		NI2T_LoadStructure(d)
	endif
	
	return NI2T_pixelTheta(d,px,py)
end

//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

//main routine returning theta angle (in radians) for pixel
// convert px,py positions on detector into Q vector, assumes ki={0,0,1}

ThreadSafe Function NI2T_pixelTheta(d,px,py)				// returns 2-theta (rad)
	STRUCT NikadetectorGeometry &d
	Variable px,py									// pixel position, 0 based, first pixel is (0,0), NOT (1,1)

	make/FREE/N=3 ki
	make/FREE/N=3 kout
	ki = {0,0,1}									//	ki =   ki[p],  incident beam direction

	NI2T_pixel2XYZ(d,px,py,kout)						// kout is in direction of pixel in beam line coords
	NI2T_normalize(kout)
	//MatrixOp kout= Normalize(kout)
	
	Variable Theta = acos(MatrixDot(kout,ki)) /2   	// ki.kf = cos(2theta), (radians)
 	//MatrixOp/FREE Theta =acos(kout.ki)   	// ki.kf = cos(2theta), (radians)
	//note, cannot use matrixOp since this is threadsafe function and waves are global... ALso, surprisingly MatrixOp here is slower by far... 
 	return Theta
End
//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Threadsafe Function NI2T_normalize(a)	// normalize a and return the initial magnitude
	Wave a
	Variable norm_a
	if (WaveDims(a)==1)											// for a 1-d wave, normalize the vector
		norm_a = norm(a)
	elseif(WaveDims(a)==2 && DimSize(a,0)==DimSize(a,1))	// for an (n x n) wave, divide by the determinant
		norm_a = MatrixDet(a)^(1/DimSize(a,0))
	endif
	if (norm_a==0 || numtype(norm_a))
		return 0
	endif

	if (WaveType(a)&1)											// for a complex wave
		FastOp/C a = (1/norm_a)*a								//	a /= norm_a
	else
		FastOp a = (1/norm_a)*a									//	a /= norm_a
	endif
	return norm_a
End

//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Structure NikaDetectorGeometry			// structure definition for a detector
	int16 used							// TRUE=detector used, FALSE=detector un-used ... not used in Nika
	int32 Nx, Ny						// # of un-binned pixels in full detector
	double sizeX,sizeY					// outside size of detector (sizeX = Nx*pitchX), measured to outer edge of outer pixels (micron)
	double R[3]						// rotation vector (length is angle in radians)
	double P[3]						// translation vector (micron)

	uchar timeMeasured[100]		// when this geometry was calculated
	uchar geoNote[100]				// note
	uchar detectorID[100]			// unique detector ID ... not used in Nika
	uchar distortionMapFile[100]	// name of file with distortion map ... not used in Nika

	double rho00, rho01, rho02		// rotation matrix internally calculated from R[3]
	double rho10, rho11, rho12
	double rho20, rho21, rho22
EndStructure

//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************


Function NI2T_InitTiltCorrection()

	string OldDf=GetDataFolder(1)
	setDataFolder root:
	NewDataFolder/O root:Packages							// ensure Packages exists
	NewDataFolder/O root:Packages:NikaTiltCorrections		// ensure NikaTiltCorrections exists

	Make/N=3/O/D root:Packages:NikaTiltCorrections:pixel2q_ki, root:Packages:NikaTiltCorrections:pixel2q_kout

	setDataFolder OldDf
end 
//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

// this is move first, tilt then. 
//threadsafe Function NI2T_pixel2XYZ(d,px,py,xyz)					// convert pixel position to the beam line coordinate system
//	STRUCT NikadetectorGeometry, &d
//	Variable px,py									// pixel position on detector (full chip & zero based)
//	Wave xyz											// 3-vector to receive the result, position in beam line coords (micron)
//
//	Variable xp,yp, zp								// x' and y' (requiring z'=0), detector starts centered on origin and perpendicular to z-axis
//
//	xp = (px - 0.5*(d.Nx-1)) * d.sizeX/d.Nx		// (x' y' z'), position on detector
//	yp = (py - 0.5*(d.Ny-1)) * d.sizeY/d.Ny
//
//	xp += d.P[0]										// translate by P
//	yp += d.P[1]
//	zp = d.P[2]
//
//	xyz[0] = d.rho00*xp + d.rho01*yp + d.rho02*zp	// xyz = rho x [ (x' y' z') + P ]
//	xyz[1] = d.rho10*xp + d.rho11*yp + d.rho12*zp	// rho is pre-calculated from vector d.R
//	xyz[2] = d.rho20*xp + d.rho21*yp + d.rho22*zp
//
//End

//This is tilt first, move then... 
//threadsafe Function NI2T_pixel2XYZ(d,px,py,xyz)					// convert pixel position to the beam line coordinate system
//	STRUCT NikadetectorGeometry, &d
//	Variable px,py									// pixel position on detector (full chip & zero based)
//	Wave xyz											// 3-vector to receive the result, position in beam line coords (micron)
//
//	Variable xp,yp, zp								// x' and y' (requiring z'=0), detector starts centered on origin and perpendicular to z-axis
//
//	xp = (px - 0.5*(d.Nx-1)) * d.sizeX/d.Nx		// (x' y' z'), position on detector
//	yp = (py - 0.5*(d.Ny-1)) * d.sizeY/d.Ny
//
//	xyz[0] = d.rho00*xp + d.rho01*yp + d.rho02*zp	// xyz = rho x [ (x' y' z') + P ]
//	xyz[1] = d.rho10*xp + d.rho11*yp + d.rho12*zp	// rho is pre-calculated from vector d.R
//	xyz[2] = d.rho20*xp + d.rho21*yp + d.rho22*zp
//
//	xyz[0] += d.P[0]										// translate by P
//	xyz[1] += d.P[1]
//	xyz[2] += d.P[2]
//
//
//End

//thsi si with respect to beam center...
threadsafe Function NI2T_pixel2XYZ(d,px,py,xyz)					// convert pixel position to the beam line coordinate system
	STRUCT NikadetectorGeometry, &d
	Variable px,py									// pixel position on detector (full chip & zero based)
	Wave xyz											// 3-vector to receive the result, position in beam line coords (micron)

	Variable xp,yp, zp									// x' and y' (requiring z'=0), detector starts centered on origin and perpendicular to z-axis
	//d.P[0] is Beam center x position in pixels
	//d.P[1] is Beam center y position in pixels
	//d.P[2] is SDD in pixels
	xp = (px - d.P[0]) //* d.sizeX/d.Nx					// (x' y' z'), position on detector, but with respect to beam center now (not center of detector)
	yp = (py - d.P[1]) //* d.sizeY/d.Ny					//now in pixels
	zp = 0								      				 // 

	xyz[0] = d.rho00*xp + d.rho01*yp + d.rho02*zp	// xyz = rho x [ (x' y' z') + P ]
	xyz[1] = d.rho10*xp + d.rho11*yp + d.rho12*zp	// rho is pre-calculated from vector d.R
	xyz[2] = d.rho20*xp + d.rho21*yp + d.rho22*zp

	xyz[2] += d.P[2]								      			 //translate by P distance from sample in pixles. 


End


//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_ReadOrientationFromGlobals(d)						// sets d to the reference orientation based on user values
	STRUCT NikadetectorGeometry &d

	Wave/Z CCDImageToConvert = root:Packages:Convert2Dto1D:CCDImageToConvert
	Wave/Z BmCntrCCDImg = root:Packages:Convert2Dto1D:BmCntrCCDImg
	variable NumPixX, NumPixY

	if(WaveExists(BmCntrCCDImg))
		NumPixX=dimsize(BmCntrCCDImg,0)
		NumPixY=dimsize(BmCntrCCDImg,1)
	elseif(WaveExists(CCDImageToConvert))
		NumPixX=dimsize(CCDImageToConvert,0)
		NumPixY=dimsize(CCDImageToConvert,1)
	else
		abort "Need image to grab the dimensions from"
	endif
	NVAR SDD=root:Packages:Convert2Dto1D:SampleToCCDDistance
	NVAR BeamCntrX=root:Packages:Convert2Dto1D:BeamCenterX
	NVAR PixSizeX=root:Packages:Convert2Dto1D:PixelSizeX
	NVAR BeamCntrY=root:Packages:Convert2Dto1D:BeamCenterY
	NVAR PixSizeY=root:Packages:Convert2Dto1D:PixelSizeY
	NVAR HorizontalTilt= root:Packages:Convert2Dto1D:HorizontalTilt
	NVAR VerticalTilt = root:Packages:Convert2Dto1D:VerticalTilt
//	NVAR AzimuthalTilt = root:Packages:Convert2Dto1D:AzimuthalTilt

	// define Detector 0, located SDDmm directly behind the sample 
	d.used = 1
	d.Nx = NumPixX ;					d.Ny = NumPixX						// number of un-binned pixels in whole detector
	d.sizeX = NumPixX*PixSizeX*1000;		d.sizeY = NumPixY*PixSizeY*1000		// outside size of detector (micron)

// NOTE THE change here:
	d.R[1]=pi*HorizontalTilt/180
	d.R[0]=pi*VerticalTilt/180
//	d.R[2]=pi*AzimuthalTilt/180							// angle of detector, theta = 0
	d.R[2]=0							// angle of detector, theta = 0
	//if we are doing stuff wrt beam center, these shifts are no more needed
//	d.P[0]=(NumPixX/2 - BeamCntrX)*PixSizeX*1000
//	d.P[1]=(NumPixY/2 - BeamCntrY)*PixSizeX*1000			
	d.P[0]=BeamCntrX		//put the beam center here....
	d.P[1]=BeamCntrY		//put the beam center here... 	
	d.P[2]=SDD	/(0.5 *(PixSizeX+PixSizeY))   			// offset to detector in pixels
	d.timeMeasured = "This is basic setup with detector perpendicularly to beam SDD away"
	d.geoNote = "Basic perpendicular orientation"
	d.detectorID = "User defined"
	d.distortionMapFile = ""
	
	NI2T_DetectorUpdateCalc(d)
end
//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_SaveOrientationToGlobals(d)						// sets d to the reference orientation based on user values
	STRUCT NikadetectorGeometry &d

	Wave/Z CCDImageToConvert = root:Packages:Convert2Dto1D:CCDImageToConvert
	Wave/Z BmCntrCCDImg = root:Packages:Convert2Dto1D:BmCntrCCDImg
	variable NumPixX, NumPixY
	if(WaveExists(BmCntrCCDImg))
		NumPixX=dimsize(BmCntrCCDImg,0)
		NumPixY=dimsize(BmCntrCCDImg,1)
	elseif(WaveExists(CCDImageToConvert))
		NumPixX=dimsize(CCDImageToConvert,0)
		NumPixY=dimsize(CCDImageToConvert,1)
	else
		abort "Need image to grab the dimensions from"
	endif
	NVAR SDD=root:Packages:Convert2Dto1D:SampleToCCDDistance
	NVAR BeamCntrX=root:Packages:Convert2Dto1D:BeamCenterX
	NVAR PixSizeX=root:Packages:Convert2Dto1D:PixelSizeX
	NVAR BeamCntrY=root:Packages:Convert2Dto1D:BeamCenterY
	NVAR PixSizeY=root:Packages:Convert2Dto1D:PixelSizeY
	NVAR HorizontalTilt= root:Packages:Convert2Dto1D:HorizontalTilt
	NVAR VerticalTilt = root:Packages:Convert2Dto1D:VerticalTilt


// NOTE THE change here:
	HorizontalTilt = 180*d.R[1]/pi		//		d.R[1]=pi*HorizontalTilt/180
	VerticalTilt = 180*d.R[0]/pi		//		d.R[0]=pi*VerticalTilt/180
	//d.R[2]=0							// angle of detector, theta = 0
//	BeamCntrX = NumPixX/2 - (d.P[0]/(PixSizeX*1000))						//	d.P[0]=(NumPixX/2 - BeamCntrX)*PixSizeX*1000
//	BeamCntrY = NumPixY/2 - (d.P[1]/(PixSizeY*1000))						//d.P[1]=(NumPixY/2 - BeamCntrY)*PixSizeX*1000			
	BeamCntrX = d.P[0]						//	d.P[0]=beam center X
	BeamCntrY = d.P[1]						//d.P[1]=beam center Y			
	SDD= 		d.P[2]/1000						//d.P[2]=SDD*1000	  			// offset to detector (micron)
	d.timeMeasured = "This is basic setup with detector perpendicularly to beam SDD away"
	d.geoNote = "Basic perpendicular orientation"
	d.detectorID = "User defined"
	d.distortionMapFile = ""
end
//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_DetectorUpdateCalc(d)						// update all internally calculated things in the detector structure
	STRUCT NikadetectorGeometry &d
	if (!(d.used))
		return 1
	endif

	Variable Rx, Ry, Rz								// used to make the rotation matrix rho from vector R
	Variable theta, c, s, c1
	Variable i
	Rx=d.R[0]; Ry=d.R[1]; Rz=d.R[2]				// make the rotation matrix rho from vector R
	theta = sqrt(Rx*Rx+Ry*Ry+Rz*Rz)
	if (theta==0)										// no rotation, set to identity matrix
		d.rho00 = 1;		d.rho01 = 0;		d.rho02 = 0
		d.rho10 = 0;		d.rho11 = 1;		d.rho12 = 0
		d.rho20 = 0;		d.rho21 = 0;		d.rho22 = 1
		return 0
	endif

	c=cos(theta)
	s=sin(theta)
	c1 = 1-c
	Rx /= theta;	Ry /= theta;	Rz /= theta		// make |{Rx,Ry,Rz}| = 1

	d.rho00 = c + Rx*Rx*c1;		d.rho01 = Rx*Ry*c1 - Rz*s;	d.rho02 = Ry*s + Rx*Rz*c1		// this is the Rodrigues formula from:
	d.rho10 = Rz*s + Rx*Ry*c1;	d.rho11 = c + Ry*Ry*c1;		d.rho12 = -Rx*s + Ry*Rz*c1	// http://mathworld.wolfram.com/RodriguesRotationFormula.html
	d.rho20 = -Ry*s + Rx*Rz*c1;	d.rho21 = Rx*s + Ry*Rz*c1;	d.rho22 = c + Rz*Rz*c1
	return 0
End

//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************


Function NI2T_SaveStructure(d)						//save structure back into string and create it if necessary. 
	STRUCT NikadetectorGeometry &d	
	
	SVAR/Z  strStruct = root:Packages:NikaTiltCorrections:NikaDetectorGeometryStr
	if(!SVAR_Exists(strStruct))
		string OldDf=getDataFolder(1)
		NewDataFolder/O/S root:Packages:NikaTiltCorrections
		EG_N2G_CreateItem("string","NikaDetectorGeometryStr")
		SVAR  strStruct = root:Packages:NikaTiltCorrections:NikaDetectorGeometryStr
		setDataFolder OldDf	
	endif
	//NI2T_ReadOrientationFromGlobals(d)				// set structure to the values in the geo panel globals
	NI2T_DetectorUpdateCalc(d)
	StructPut/S/B=2 d, strStruct
end
//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************

Function NI2T_LoadStructure(d)					//here we load structure from saved structure in the string... 
	STRUCT NikadetectorGeometry &d	
	
	SVAR/Z strStruct = root:Packages:NikaTiltCorrections:NikaDetectorGeometryStr
	if(!SVAR_Exists(strStruct))
		ABort "Structure does not exist. Create it first with Beam center & Calibration tool"
	endif
	StructGet/S/B=2 d, strStruct								// found structure information, load into geo
	//NI2T_SaveOrientationToGlobals(d)						// set structure to the values in the geo panel globals
	NI2T_DetectorUpdateCalc(d)
//	StructPut/S/B=2 d, strStruct
end
//*************************************************************************************************
//*************************************************************************************************
//*************************************************************************************************




Function NI2t_printDetectorStructure(d)							// print the details for passed detector geometry to the history window
	STRUCT NikadetectorGeometry &d

	printf "	Nx=%d, Ny=%d			// number of un-binned pixels in detector\r",d.Nx,d.Ny
	printf "	sizeX=%g, sizeY=%g		// size of detector (mm)\r",(d.sizeX/1000), (d.sizeY/1000)
	printf "	R = {%.7g, %.7g, %.7g}, a rotation of %.7g�	// rotation vector\r",d.R[0],d.R[1],d.R[2],sqrt(d.R[0]*d.R[0] + d.R[1]*d.R[1] + d.R[2]*d.R[2])*180/PI
	printf "	P = {%g, %g, %g}					// translation vector (mm)\r",(d.P[0])/1000,(d.P[1])/1000,(d.P[2])/1000

	printf "	geometry measured on  '%s'\r",d.timeMeasured
	if (strlen(d.geoNote))
		printf "	detector note = '%s'\r",d.geoNote
	endif
	if (strlen(d.distortionMapFile))
		printf "	detector distortion file = '%s'\r",d.distortionMapFile
	endif
	printf "	detector ID = '%s'\r"d.detectorID
	if (NumVarOrDefault("root:Packages:geometry:printVerbose",0))
		printf "			{%+.6f, %+.6f, %+.6f}	// rotation matrix from R\r",d.rho00, d.rho01, d.rho02
		printf "	rho =	{%+.6f, %+.6f, %+.6f}\r",d.rho10, d.rho11, d.rho12
		printf "			{%+.6f, %+.6f, %+.6f}\r",d.rho20, d.rho21, d.rho22
	endif
	return 0
End

