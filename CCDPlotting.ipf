#pragma rtGlobals=1		// Use modern global access method and strict wave access.
#include "EGN_Loader"

function CCDPlotSquare() : Graph
	PauseUpdate; Silent 1		// building window...
	dowindow /k ccdplotwindow
	Display /k=1/W=(570.6,79.4,892.2,401.6) /n=ccdplotwindow as "CCD image"
	NVAR SampleToCCDDistance=root:Packages:Convert2Dto1D:SampleToCCDDistance		//in millimeters
	NVAR Wavelength = root:Packages:Convert2Dto1D:Wavelength							//in A
	NVAR PixelSizeX = root:Packages:Convert2Dto1D:PixelSizeX								//in millimeters
	NVAR PixelSizeY = root:Packages:Convert2Dto1D:PixelSizeY								//in millimeters
	NVAR beamCenterX=root:Packages:Convert2Dto1D:beamCenterX
	NVAR beamCenterY=root:Packages:Convert2Dto1D:beamCenterY
	wave CCDImageToConvert =  root:Packages:Convert2Dto1D:CCDImageToConvert
	wave/z mask =  root:Packages:Convert2Dto1D:masksq
	make /o/n=(dimsize(ccdimagetoconvert,0)+1) qxyaxis = 4*pi*sin(atan((x-beamcenterx)*PixelSizeX/(SampleToCCDDistance))/2)/Wavelength
	make /o/n=(dimsize(ccdimagetoconvert,1)+1) qzaxis = 4*pi*sin(atan((x-beamcentery)*PixelSizey/(SampleToCCDDistance))/2)/Wavelength
	
	if(waveexists(mask))
		duplicate/o CCDimagetoconvert, maskedccddata
		variable maskx1 = dimoffset(mask,0)
		variable maskx2 = dimoffset(mask,0) + dimsize(mask,0)*dimdelta(mask,0)
		variable masky1 = dimoffset(mask,1)
		variable masky2 = dimoffset(mask,1)+ dimsize(mask,1)*dimdelta(mask,1)
		variable minmaskx = min(maskx1,maskx2)
		variable maxmaskx = max(maskx1,maskx2)
		variable minmasky = min(masky1,masky2)
		variable maxmasky = max(masky1,masky2)
		maskedccddata = mask(x)(-y)==1 ? maskedccddata(x)(y) : 0
		imageinterpolate /dest=interpolatedmaskeddata /S={wavemin(qxyaxis),abs(qxyaxis[0]-qxyaxis[1]),wavemax(qxyaxis),wavemin(qzaxis),abs(qxyaxis[0]-qxyaxis[1]),wavemax(qzaxis)} /w={qxyaxis,qzaxis} XYWaves, maskedccddata
		setscale /p x, wavemin(qxyaxis),abs(qxyaxis[0]-qxyaxis[1]), interpolatedmaskeddata
		setscale /p y, wavemin(qzaxis),abs(qzaxis[0]-qzaxis[1]), interpolatedmaskeddata
		
		AppendImage/T interpolatedmaskeddata
		ModifyImage interpolatedmaskeddata ctab= {60,6000,YellowHot,0}
		ModifyImage interpolatedmaskeddata maxRGB=(0,0,52224)
		ModifyImage interpolatedmaskeddata log=1
	else
		AppendImage/T CCDImageToConvert vs{qxyaxis,qzaxis}
		ModifyImage CCDImageToConvert ctab= {60,6000,YellowHot,0}
		ModifyImage CCDImageToConvert maxRGB=(0,0,52224)
		ModifyImage CCDImageToConvert log=1
	endif
	ModifyGraph margin(left)=42,margin(bottom)=43,margin(top)=43,margin(right)=43,gfSize=14
	ModifyGraph height={Plan,1,left,top}
	ModifyGraph tick=2
	ModifyGraph mirror=3
	ModifyGraph nticks=10
	ModifyGraph fSize=14
	ModifyGraph lblMargin(left)=2
	ModifyGraph standoff=0
	ModifyGraph axOffset(top)=10
	ModifyGraph axThick=2
	ModifyGraph axRGB=(65535,65535,65535)
	ModifyGraph lblLatPos(left)=7
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen(left)=5,btLen(top)=3
	ModifyGraph tlOffset=-2
	Label left "Momentum Transfer Q\\Bz\\M [Å\\S-1\\M]"
	Label top "Momentum Transfer Q\\Bxy\\M [Å\\S-1\\M]"
	SetAxis/R left -0.1,1.9
	SetAxis top -0.1,1.9
	TextBox/C/N=text0/F=0/B=1/A=MB/X=0.00/Y=0.00/E "Momentum Transfer Q\\Bxy\\M [Å\\S-1\\M]"
	TextBox/C/N=text1/O=90/F=0/B=1/A=RC/X=0.00/Y=0.00/E "Momentum Transfer Q\\Bz\\M [Å\\S-1\\M]"
End

Window CCDPlotSquare_1() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(188.4,47,556.8,416) as "CCD image"
	AppendImage/T :Packages:Convert2Dto1D:CCDImageToConvert
	ModifyImage CCDImageToConvert ctab= {3000,100000,YellowHot,0}
	ModifyImage CCDImageToConvert maxRGB=(0,0,52224)
	ModifyImage CCDImageToConvert log= 1
	ModifyGraph margin(left)=42,margin(bottom)=43,margin(top)=43,margin(right)=43,gfSize=18
	ModifyGraph height={Plan,1,left,top}
	ModifyGraph tick=2
	ModifyGraph mirror=3
	ModifyGraph nticks=3
	ModifyGraph minor=1
	ModifyGraph fSize(top)=16
	ModifyGraph standoff=0
	ModifyGraph axOffset(top)=10
	ModifyGraph axThick=2
	ModifyGraph axRGB=(65535,65535,65535)
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen(left)=5,btLen(top)=3
	ModifyGraph tlOffset=-5
	Label left "\\Z16Q\\Bz\\M \\Z20[\\Z14Å\\S-1\\M\\Z20]"
	Label top "\\Z16Q\\Bxy\\M \\Z20[\\Z14Å\\S-1\\M\\Z20]"
	SetAxis/R left -0.2,1.9
	SetAxis top -0.2,1.9
	TextBox/C/N=text0/F=0/B=1/A=MB/X=0.00/Y=0.00/E "\\Z16Q\\Bxy\\M \\Z20[\\Z14Å\\S-1\\M\\Z20]"
	TextBox/C/N=text1/O=90/F=0/B=1/A=RC/X=0.00/Y=0.00/E "\\Z16Q\\Bz\\M \\Z20[\\Z14Å\\S-1\\M\\Z20]"
EndMacro

Window CCDPlotSquare_3() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(649.2,73.4,936,360.8) as "CCD image"
	AppendImage/T :Packages:Convert2Dto1D:CCDImageToConvert
	ModifyImage CCDImageToConvert ctab= {3000,100000,YellowHot,0}
	ModifyImage CCDImageToConvert maxRGB=(0,0,52224)
	ModifyImage CCDImageToConvert log= 1
	ModifyGraph margin(left)=42,margin(bottom)=43,margin(top)=43,margin(right)=43,gfSize=18
	ModifyGraph height={Plan,1,left,top}
	ModifyGraph tick=2
	ModifyGraph mirror=3
	ModifyGraph nticks=3
	ModifyGraph minor=1
	ModifyGraph fSize(top)=16
	ModifyGraph standoff=0
	ModifyGraph axOffset(top)=10
	ModifyGraph axThick=2
	ModifyGraph axRGB=(65535,65535,65535)
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen(left)=5,btLen(top)=3
	ModifyGraph tlOffset=-5
	Label left "\\Z16Q\\Bz\\M \\Z20[\\Z14Å\\S-1\\M\\Z20]"
	Label top "\\Z16Q\\Bxy\\M \\Z20[\\Z14Å\\S-1\\M\\Z20]"
	SetAxis/R left -0.2,1.9
	SetAxis top -0.2,1.9
	TextBox/C/N=text0/F=0/B=1/A=MB/X=0.00/Y=0.00/E "\\Z16Q\\Bxy\\M \\Z20[\\Z14Å\\S-1\\M\\Z20]"
	TextBox/C/N=text1/O=90/F=0/B=1/A=RC/X=0.00/Y=0.00/E "\\Z16Q\\Bz\\M \\Z20[\\Z14Å\\S-1\\M\\Z20]"
EndMacro

function squaremapgood() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(327.6,224.6,883.8,469.4)/K=1 
	wave qvectorp, angles
	AppendImage root:Packages:Convert2Dto1D:SquareMap vs {qvectorp,angles}
	ModifyImage SquareMap ctab= {500,3000,Terrain,0}
	ModifyImage SquareMap log= 1
	ModifyGraph margin(left)=50,margin(bottom)=50,margin(top)=3,margin(right)=28,gfSize=14
	ModifyGraph log(bottom)=1
	ModifyGraph mirror=2
	Label left "Angle from Normal [deg]"
	Label bottom "D Spacing [Å]"
	SetAxis left 0,90
	SetAxis bottom 3.2319262695581,12.8928245047096
	ColorScale/C/N=text0/A=RT/X=-5.89/Y=13.75 image=SquareMap, log=1, minor=1
EndMacro

function CCDGraph([minqy,maxqy,minqz,maxqz,colors,minval, maxval,name])
	variable minval, maxval,minqy,maxqy,minqz,maxqz
	string name,colors
	minqz = paramisdefault(minqz) ? -0.05 : minqz
	maxqz = paramisdefault(maxqz) ? 1.95 : maxqz
	minval = paramisdefault(minval) ? 2000 : minval
	maxval = paramisdefault(maxval) ? 200000 : maxval
	if(paramisdefault(name))
		svar username = root:Packages:Convert2Dto1D:OutputDataName
		name = username
	endif
	if(paramisdefault(colors))
		colors = "YellowHot"
	endif
	string gname = Cleanupname(name + "_Graph",0)
	dowindow /k $gname
	string gtitle = name + " 2D GIWAXS plot"
	Display /k=1/n=$gname  /W=(570.6,79.4,900,700) as gtitle
	string foldersave = getdatafolder(1)
	setdatafolder root:Packages:Convert2Dto1D
	wave CCDImageToConvert
	NVAR UseGrazingIncidence=root:Packages:Convert2Dto1D:UseGrazingIncidence
	if(UseGrazingIncidence)
		if(!waveexists(warped2DDataSet))
			GI_ReHistImage()
		endif
		//wave datao = warped2DDataSet
	endif
	wave datao = CCDImageToConvert
	
	if(dimoffset(datao,0)<-1.2)
		minqy = paramisdefault(minqy) ? 0.15 : minqy
		maxqy = paramisdefault(maxqy) ? -1.95 : maxqy
	else
		minqy = paramisdefault(minqy) ? -0.15 : minqy
		maxqy = paramisdefault(maxqy) ? 1.95 : maxqy
	endif
	string dataname = (name+"_2D")
	duplicate/o datao $dataname
	wave data = $dataname
	make /o/n=(101,2) /t GIWAXSTIXnames 
	make /o/n=101 GIWAXSTIX
	GIWAXSTIX = p/10 - 5
	variable j
	for(j=0;j<101;j+=1)
		if(GIWAXSTIX[j]*2 == round(GIWAXSTIX[j]*2))
			GIWAXSTIXnames[j][0] = num2str(abs(GIWAXSTIX*10))
			GIWAXSTIXnames[j][1] = "Major"
		else
			GIWAXSTIXnames[j][0] =	""
			GIWAXSTIXnames[j][1] = "Minor"
		endif
	endfor
	setdimlabel 1,1,'Tick Type',GIWAXSTIXnames
	
	AppendImage data
	ModifyImage $dataname ctab= {minval,maxval,$colors,0}
	ModifyImage $dataname maxRGB=(0,0,52224)
	ModifyImage $dataname log= 1
	ModifyGraph margin(left)=50,margin(bottom)=45,margin(top)=4,margin(right)=4,gfSize=10
	ModifyGraph height={Plan,1,left,bottom}
	ModifyGraph tick=2
	ModifyGraph mirror=0
	ModifyGraph fSize=0,gfsize=18
	ModifyGraph lblMargin(left)=2
	ModifyGraph standoff=0
	ModifyGraph axOffset(bottom)=10
	ModifyGraph axThick=1
	ModifyGraph axRGB=(65535,65535,65535)
	ModifyGraph lblLatPos(left)=0
	ModifyGraph btLen=3,stLen=2,stThick=1.5,btThick=3
	ModifyGraph tlOffset(bottom)=-2,tlOffset(left)=0,userticks={GIWAXSTIX,GIWAXSTIXnames}
	Label left "Momentum Transfer Q\\Bz\\M [nm\\S-1\\M]"
	Label bottom "Momentum Transfer Q\\Bxy\\M [nm\\S-1\\M]"
	SetAxis/R left minqz,maxqz
	SetAxis bottom minqy,maxqy
//	TextBox/C/N=text0/F=0/B=1/A=MB/X=0.00/Y=0.00/E "Momentum Transfer Q\\Bxy\\M [Å\\S-1\\M]"
//	TextBox/C/N=text1/O=90/F=0/B=1/A=RC/X=0.00/Y=0.00/E "Momentum Transfer Q\\Bz\\M [Å\\S-1\\M]"
//	TextBox /C/MC /F=2/N=test2 name
	setdatafolder foldersave
end