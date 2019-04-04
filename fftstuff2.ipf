#pragma rtGlobals=1		// Use modern global access method.

// created by Eliot Gann @ NCSU 
// Procedures for simulating the scatter from anisotropic shapes.
// generally procedures either create a large 2D field and populate it with some sort of shape, possibly looking for overlap
// then generally a FFT is performed, and the result is radially integrated

// things to do 
// - conver to 3D transforms.  one test function at the end now does this, the math to generate the object needs to change, 
// (for different simulations) and possibly populating the space with some distribution of sizes etc
// - change radial integrate to actually use min and max angle, and output two 1d graphs, and possibly calculate anisotropic signal vs q
// - allow master functions to be callable with real indices of refraction. (often I just use a real density like function now)
// - allow for A-B-C-(D) for core, aligned, misaligned, matrix indicies to be input, and build refractive 3D map from that
// - integrate with optical contrasts database for asignment of materials based on name.

function /Wave radialintegrate(wave1,centx,centy,minangle,maxangle)
	wave wave1
	variable centx,centy,maxangle,minangle // min and max angle are in degrees
	duplicate /o wave1,radialdistance,mask, maskeddata
	mask = atan((centy-y)/(centx-x)) <maxangle*pi/180 && atan((centy-y)/(centx-x)) >minangle*pi/180 ? 1 : nan
	radialdistance = sqrt((centx-x)^2 + (centy-y)^2)
	maskeddata *= mask
	radialdistance *= mask
	redimension/n=(numpnts(wave1)) maskeddata
	redimension/n=(numpnts(wave1)) radialdistance
	wavetransform zapnans maskeddata
	wavetransform zapnans radialdistance
	variable mn = wavemin(radialdistance)
	variable mx= wavemax(radialdistance)
	variable dmin = min(dimdelta(wave1,0),dimdelta(wave1,0))
	variable range = round((mx-mn)/(dmin))
	make /d/o radialintensity, npoints
	radialintensity = 0
	npoints = 0
	Histogram /B={mn,dmin,range} /c radialdistance, npoints
	Histogram  /B={mn,dmin,range} /c /w=maskeddata radialdistance, radialintensity
	radialintensity /=npoints
	setscale /p x,mn,dmin, radialintensity
	return radialitensity
//	DoWindow/F Radial_Intensity						// Bring graph to front
//	if (V_Flag == 0)									// Verify that graph exists/
//		display /k=1 /n=Radial_Intensity radialintensity
//	endif
end
function radialintegrate2(wave1,centx,centy)
	wave wave1
	variable centx,centy
	make /o /d /n=(numpnts(wave1)) radialdistance,intensity
	variable i,j,n=0,range,mn,mx,dx=dimdelta(wave1,0),dy=dimdelta(wave1,1),ox=dimoffset(wave1,0),oy=dimoffset(wave1,1)
//	print ox, oy,dy,dx
	for(i=0;i<dimsize(wave1,0);i+=1)
		for(j=0;j<dimsize(wave1,1);j+=1)
			radialdistance[n] =  sqrt( (i*dx+ox-centx)^2 +(j*dy+oy-centy)^2 )
			intensity[n]=abs(wave1[i][j])
			n+=1
		endfor
	endfor
	mn = wavemin(radialdistance)
	mx= wavemax(radialdistance)
	range = round((mx-mn)/(min(dx,dy)))
	make /d /o radialintensity,nradintens
	radialintensity = 0
	nradintens = 0
	Histogram /B={mn,min(dx,dy),range} /c radialdistance, nradintens
	Histogram  /B={mn,min(dx,dy),range} /c /w=intensity radialdistance, radialintensity
	radialintensity /=nradintens
//	DoWindow/F Radial_Intensity						// Bring graph to front
//	if (V_Flag == 0)									// Verify that graph exists/
//		display /k=1 /n=Radial_Intensity radialintensity
//	endif
end
function radialintegrate1(wave1,centx,centy,minangle,maxangle)
	wave wave1
	variable centx,centy,minangle,maxangle
	make /o /d /n=(dimsize(wave1,0)*dimsize(wave1,1)) radialdistance,intensity
	variable i,j,n=0,range,mn,mx,dx=dimdelta(wave1,0),dy=dimdelta(wave1,1),ox=dimoffset(wave1,0),oy=dimoffset(wave1,1)
	for(i=0;i<dimsize(wave1,0);i+=1)
		for(j=0;j<dimsize(wave1,1);j+=1)
			radialdistance[n] =  sqrt( (i*dx+ox-centx)^2 +(j*dy+oy-centy)^2 )
			intensity[n]=wave1[i][j]
			n+=1
		endfor
	endfor
	mn = wavemin(radialdistance)
	mx= wavemax(radialdistance)
	range = round((mx-mn)/(2*min(dx,dy)))
	make /d /o radialintensity,nradintens
	radialintensity = 0
	nradintens = 0
	Histogram /B={mn,2*min(dx,dy),range} /c radialdistance, nradintens
	Histogram  /B={mn,2*min(dx,dy),range} /c /w=intensity radialdistance, radialintensity
	radialintensity /=nradintens
	DoWindow/F Radial_Intensity						// Bring graph to front
	if (V_Flag == 0)									// Verify that graph exists
		display /k=1 /n=Radial_Intensity radialintensity
	endif
end

function simspheres(num,size,sigma,noise)
	variable num,size,sigma,noise
	variable i
	make /n=(num) /o /d sizes,centrs,centxs,centys,centths
	make /n=(1024,1024) /o /d testwave,singlesphere
	sizes =size + gnoise(sigma)
	centrs = enoise(200)
	centths = pi + enoise(pi)
	centxs =512+ centrs * sin(centths)
	centys = 512+ centrs * cos(centths)
	singlesphere = Real(2*sqrt(size^2-(p)^2-(q)^2)+2*sqrt(size^2-(p-1024)^2-(q)^2)+2*sqrt(size^2-(p-1024)^2-(q-1024)^2)+2*sqrt(size^2-(p)^2-(q-1024)^2))
	testwave =0
	for(i=0;i<num;i+=1)
		testwave[centxs[i]][centys[i]]=1
	endfor
	fft /Dest=spherefft singlesphere
	fft /dest=testfft testwave
	testfft *= spherefft
	ifft /dest=testwave testfft
	//stackparticles = Real(2*sqrt(sizes(p)^2-(p-centxs(p))^2-(q-centys(p))^2))
	//imagetransform sumplanes stackparticles
	//wave M_Sumplanes
	//duplicate /o  M_SumPlanes, testwave
	//wave testwave
	//setscale /p y, 0, 10e-9,"m", testwave
	//setscale /p x, 0, 10e-9,"m", testwave
	//for(i=0;i<num;i+=1)
	//	testwave += Real(2*sqrt(sizes(i)^2-(p-centxs(i))^2-(q-centys(i))^2))
	//endfor
	testwave += gnoise(noise)^2
	setscale /p y, 0, 2*pi*1e6,"m^-1", testwave
	setscale /p x, 1, 2*pi*1e6,"m^-1", testwave
	fftandintegrate(testwave,1e-6,1e-6)
end
function /s fftandintegrate3D(testwave,[imagename,pwr,polarized,angledelta])
	WAVE testwave
	variable pwr,angledelta,polarized
	string imagename
	variable numx,numy
	pwr = paramisdefault(pwr)? 2 : pwr
	numx = Dimsize(testwave,0)
	numy = dimsize(testwave,1)
	if(numx/2 != round(numx/2) )
		numx +=1
	endif
	if(numy/2 != round(numy/2) )
		numy +=1
	endif	
	FFT  /pad={1*numx,1*numy} /mags /Dest=testfft testwave 
	radialintegrate(testfft,0,0,-10,10)
	wave radialintensity
	radialintegrate(testfft,0,0,-10,10)
//	setscale /p x, 0,xscalem,"", radialintensity
	dowindow /r/k fftdisp
	newimage /k=1 /n=fftdisp testfft
	ModifyGraph/w=fftdisp nticks=0
	ModifyGraph/w=fftdisp margin=1
	ModifyImage/w=fftdisp testfft log=1, ctab= {1,*,terrain,0}

//	setscale /p x, dimdelta(testfft,0),dimdelta(testfft,0), radialintensity
	radialintensity *=x^pwr
	
	if(paramisdefault(imagename))
		imagename = nameofwave(testwave)
	endif
//	variable xscale =xscalem // dimdelta(testwave,0)  //scale in m
//	print xscale
//	variable yscale =yscalem //dimdelta(testwave,1) //scale in m
	duplicate /o radialintensity, smrintensity
	smrintensity[0]=0
//	setscale /p x, 1/xscalem,1/xscalem, smrintensity
//	smooth /s=4 /E=3 11,smrintensity
	duplicate /o smrintensity, $("rfft_"+imagename)
//	setscale /p x, dimdelta(testfft,0),dimdelta(testfft,0), $("rfft_"+imagename)
	display /k=1 $("rfft_"+imagename)
//	testfft[x2pnt(testfft,0)][x2pnt(testfft,0)]=0
//	redimension /n=(2*(floor(numpnts(smrintensity)/2))) smrintensity
	FFT/PAD={2*Ceil(numpnts(smrintensity)/2)} /DEST=actemp smrintensity
	make /d/o/n=(numpnts(actemp)) autocwave 
	autocwave = real(actemp)
	duplicate /o autocwave, $("rac_"+imagename)
	setscale /p x,1/(dimsize(smrintensity,0)*dimdelta(smrintensity,0)), 1/(dimsize(smrintensity,0)*dimdelta(smrintensity,0)), $("rac_"+imagename)
	display /k=1 $("rac_"+imagename)
	string output= "imagename:"+imagename+";fftname:"+"rfft_"+imagename+";acname:"+"rac_"+imagename
	output+=";time:"+time()+";date:"+date() 
	output += ";processedfft:Autocorrellation"
	string wnote = note($("rac_"+imagename))
	wnote += ";processedfft=Autocorrellation"
	wnote += ";wavename="+imagename+"fftname="+"rfft_"+imagename+";acname="+"rac_"+imagename
	wnote += ";time="+time()+";date="+date()
	FindPeak /N /Q autocwave
	output += ";acmin1:"+num2str(V_PeakLoc)
	wnote += ";acmin1="+num2str(V_PeakLoc)
	wnote += ";acheight1="+num2str(V_PeakVal)
	output += ";acheight1:"+num2str(V_PeakVal)
	FindPeak /N /Q /R=(V_PeakLoc+10,) autocwave
	output += ";acmin2:"+num2str(V_PeakLoc)
	wnote += ";acmin2="+num2str(V_PeakLoc)
	wnote += ";acheight2="+num2str(V_PeakVal)
	output += ";acheight2:"+num2str(V_PeakVal)
	FindPeak /N /Q /R=(V_PeakLoc+10,) autocwave
	output += ";acmin3:"+num2str(V_PeakLoc)
	wnote += ";acmin3="+num2str(V_PeakLoc)
	wnote += ";acheight3="+num2str(V_PeakVal)
	output += ";acheight3:"+num2str(V_PeakVal)
	FindLevel /Q autocwave , 0
	wnote += ";aczero=" + num2str(V_LevelX)+";" 
	output += ";aczero:" + num2str(V_LevelX)+";" 
	note $("rac_"+imagename) , wnote
	return output
end

function /s fftandintegrate(testwave,xscalem,yscalem,[imagename,pwr])
	WAVE testwave
	variable xscalem,yscalem,pwr
	string imagename
	variable numx,numy
	pwr = paramisdefault(pwr)? 2 : pwr
	numx = Dimsize(testwave,0)
	numy = dimsize(testwave,1)
	if(numx/2 != round(numx/2) )
		numx +=1
	endif
	if(numy/2 != round(numy/2) )
		numy +=1
	endif	
	FFT  /pad={1*numx,1*numy} /mags /Dest=testfft testwave 
	radialintegrate(testfft,0,0,-180,180)
	wave radialintensity
//	radialintegrate(testfft,0,0,-10,10)
//	setscale /p x, 0,xscalem,"", radialintensity

//	dowindow /r/k fftdisp
	newimage /k=1 /n=fftdisp testfft
	ModifyGraph/w=fftdisp nticks=0
	ModifyGraph/w=fftdisp margin=1
	ModifyImage/w=fftdisp testfft log=1, ctab= {1,*,terrain,0}

//	setscale /p x, dimdelta(testfft,0),dimdelta(testfft,0), radialintensity
	radialintensity *=x^pwr
	
	if(paramisdefault(imagename))
		imagename = nameofwave(testwave)
	endif
//	variable xscale =xscalem // dimdelta(testwave,0)  //scale in m
//	print xscale
//	variable yscale =yscalem //dimdelta(testwave,1) //scale in m
	duplicate /o radialintensity, smrintensity
	smrintensity[0]=0
//	setscale /p x, 1/xscalem,1/xscalem, smrintensity
//	smooth /s=4 /E=3 11,smrintensity
	duplicate /o smrintensity, $("rfft_"+imagename)
//	setscale /p x, dimdelta(testfft,0),dimdelta(testfft,0), $("rfft_"+imagename)
	dowindow/r /k $("fft_"+imagename)
	display /n=$("fft_"+imagename) /k=1 $("rfft_"+imagename)
//	testfft[x2pnt(testfft,0)][x2pnt(testfft,0)]=0
//	redimension /n=(2*(floor(numpnts(smrintensity)/2))) smrintensity


//	FFT/PAD={2*Ceil(numpnts(smrintensity)/2)} /DEST=actemp smrintensity
//	make /d/o/n=(numpnts(actemp)) autocwave 
//	autocwave = real(actemp)
//	duplicate /o autocwave, $("rac_"+imagename)
//	setscale /p x,1/(dimsize(smrintensity,0)*dimdelta(smrintensity,0)), 1/(dimsize(smrintensity,0)*dimdelta(smrintensity,0)), $("rac_"+imagename)
//	display /k=1 $("rac_"+imagename)
//	string output= "imagename:"+imagename+";fftname:"+"rfft_"+imagename+";acname:"+"rac_"+imagename
//	output+=";time:"+time()+";date:"+date() 
//	output += ";processedfft:Autocorrellation"
//	string wnote = note($("rac_"+imagename))
//	wnote += ";processedfft=Autocorrellation"
//	wnote += ";wavename="+imagename+"fftname="+"rfft_"+imagename+";acname="+"rac_"+imagename
//	wnote += ";time="+time()+";date="+date()
//	FindPeak /N /Q autocwave
//	output += ";acmin1:"+num2str(V_PeakLoc)
//	wnote += ";acmin1="+num2str(V_PeakLoc)
//	wnote += ";acheight1="+num2str(V_PeakVal)
//	output += ";acheight1:"+num2str(V_PeakVal)
//	FindPeak /N /Q /R=(V_PeakLoc+10,) autocwave
//	output += ";acmin2:"+num2str(V_PeakLoc)
//	wnote += ";acmin2="+num2str(V_PeakLoc)
//	wnote += ";acheight2="+num2str(V_PeakVal)
//	output += ";acheight2:"+num2str(V_PeakVal)
//	FindPeak /N /Q /R=(V_PeakLoc+10,) autocwave
//	output += ";acmin3:"+num2str(V_PeakLoc)
//	wnote += ";acmin3="+num2str(V_PeakLoc)
//	wnote += ";acheight3="+num2str(V_PeakVal)
//	output += ";acheight3:"+num2str(V_PeakVal)
//	FindLevel /Q autocwave , 0
//	wnote += ";aczero=" + num2str(V_LevelX)+";" 
//	output += ";aczero:" + num2str(V_LevelX)+";" 
//	note $("rac_"+imagename) , wnote
	return ""
end
function stxmsimulate()
//	Readdatafile("testwave")
	variable offx, offy, dx, dy,npts
	wave testwave
	string /g  paxis,qaxis
	dx = abs(str2num(StringByKey("min",PAxis,":",";"))-str2num(StringByKey("max",PAxis,":",";")))/str2num(StringByKey("npts",PAxis,":",";"))
	dy = abs(str2num(StringByKey("min",qAxis,":",";"))-str2num(StringByKey("max",qAxis,":",";")))/str2num(StringByKey("npts",qAxis,":",";"))
	offx = str2num(StringByKey("min",PAxis,":",";"))
	offy = str2num(StringByKey("min",QAxis,":",";"))
	npts =  str2num(StringByKey("npts",PAxis,":",";"))

	make /n=(npts-90,npts-90) /d /o newwave
	wave newwave
	newwave[][] = testwave[p+90][q+90]
	killwaves testwave
	rename newwave testwave
	wave testwave
	setscale /p x, offx*10^-6 , dx*10^-6 ,"m", testwave
	setscale /p y, offy*10^-6 , dy*10^-6,"m", testwave
	fftandintegrate(testwave,2*pi/(npts*dx*10^3),1)

end	



function makespheres(wavein,num,size,sd)
	wave wavein
	variable num, size, sd
	variable i,j,cx,cy,r,o,pass,pnum=0
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	make /o /n=(num) cxs, cys
	cxs=0
	cys=0
	for(i=0;i<num;i+=1)
		r = size+gnoise(sd)
		pass=0
		pnum=0
		do
			cx = gnoise(sx/8)+sx/2
			cy = gnoise(sy/8)+sy/2
			pass=1
			duplicate /o /r=(cx-r,cx+r)(cy-r,cy+r) wavein, tempwave
			tempwave = (cx-x)^2+(cy-y)^2<r^2 ? tempwave : 0
			if(wavemax(tempwave) > .2)
				pass=0
			endif
			pnum+=1
			if(pnum >500)
				print "fail!"
				pass=1
			endif
		while(pass==0)
		cys[i]=cy
		cxs[i]=cx
		o = enoise(pi)
		wavein[cx-r,cx+r][cy-r,cy+r] += r^2>(p-cx)^2+(q-cy)^2 ?sqrt(r^2-((p-cx)^2+(q-cy)^2))/r : 0
	endfor
end
function makespheressq(wavein,num,size,sd)
	wave wavein
	variable num, size, sd
	variable i,j,cx,cy,r,o,pass,pnum=0
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	make /o /n=(num) cxs, cys
	cxs=0
	cys=0
	for(i=0;i<num;i+=1)
		r = size+gnoise(sd)
		pass=0
		pnum=0
		do
			cx = enoise(sx-2*r)/2 + sx/2
			cy = enoise(sy-2*r)/2 + sy/2
			pass=1
			duplicate /o /r=(cx-r,cx+r)(cy-r,cy+r) wavein, tempwave
			tempwave = (cx-x)^2+(cy-y)^2<r^2 ? tempwave : 0
			if(wavemax(tempwave) > .2)
				pass=0
			endif
			pnum+=1
			if(pnum >500)
				print "fail!"
				pass=1
			endif
		while(pass==0)
		cys[i]=cy
		cxs[i]=cx
		o = enoise(pi)
		wavein[cx-r,cx+r][cy-r,cy+r] += r^2>(p-cx)^2+(q-cy)^2 ?sqrt(r^2-((p-cx)^2+(q-cy)^2))/r : 0
	endfor
end
function makecylinders(wavein,num,size,sd,sep,roughness)
	wave wavein
	variable num, size, sd, sep, roughness
	variable i,j,cx,cy,r,o,pass,pnum=0
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	make /o /n=(num) cxs, cys
	cxs=0
	cys=0
	for(i=0;i<num;i+=1)
		r = size+gnoise(sd)
		pass=0
		pnum=0
		do
			cx = gnoise(sx/8)+sx/2
			cy = gnoise(sy/8)+sy/2
			if(i==0)
				break
			endif
			pass=1
			for(j=0;j<i;j+=1)
				if((cx-cxs[j])^2+(cy-cys[j])^2 < 4* size^2 || i==0)
					pass=0
				endif
			endfor
			pnum+=1
			if(pnum >500)
				print "fail!"
				pass=1
			endif
		while(pass==0)
		cys[i]=cy
		cxs[i]=cx
		o = enoise(pi)
		wavein = r^2<(p-cx)^2+(q-cy)^2 ? wavein : wavein+1
	endfor
end
function makesquares(wavein,num,size,sd)
	wave wavein
	variable num, size, sd
	variable i,cx,cy,r,o
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	for(i=0;i<num;i+=1)
		r = size+gnoise(sd)
		cx = gnoise(sx/8)+sx/2
		cy = gnoise(sx/8)+sx/2
		o = enoise(pi)
	//	wavein =
	endfor
end
function makegausses(wavein,num,size,sd)
	wave wavein
	variable num, size, sd
	variable i,j,cx,cy,r,o,pass,pnum=0
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	for(i=0;i<num;i+=1)
		r = size+gnoise(sd)
		pass=0
		pnum=0
		do
			cx = gnoise(sx/8)+sx/2
			cy = gnoise(sy/8)+sy/2
			pass=1
			duplicate /o /r=(cx-2*r,cx+2*r)(cy-2*r,cy+2*r) wavein, tempwave
			tempwave = (cx-x)^2+(cy-y)^2<4*r^2 ? tempwave : 0
			if(wavemax(tempwave) > .2 * r)
				pass=0
			endif
			pnum+=1
			if(pnum >500)
				print "fail!"
				pass=1
			endif
		while(pass==0)
		wavein[cx-r*10,cx+r*10][cy-10*r,cy+10*r] += Exp(- ((p-cx)^2 +(q-cy)^2)/(2*r^2))*r
	endfor
end
function makegaussessq(wavein,num,size,sd)
	wave wavein
	variable num, size, sd
	variable i,j,cx,cy,r,o,pass,pnum=0
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	for(i=0;i<num;i+=1)
		r = size+gnoise(sd)
		pass=0
		pnum=0
		do
			cx = enoise(sx-10*r)/2 + sx/2
			cy = enoise(sy-10*r)/2 + sy/2
			pass=1
			duplicate /o /r=(cx-2*r,cx+2*r)(cy-2*r,cy+2*r) wavein, tempwave
			tempwave = (cx-x)^2+(cy-y)^2<4*r^2 ? tempwave : 0
			if(wavemax(tempwave) > .2 * r)
				pass=0
			endif
			pnum+=1
			if(pnum >500)
				print "fail!"
				pass=1
			endif
		while(pass==0)
		wavein[cx-r*10,cx+r*10][cy-10*r,cy+10*r] += Exp(- ((p-cx)^2 +(q-cy)^2)/(2*r^2))*r
	endfor
end

function /wave combwaves( w5,w20,w100,im1name, im2name, im3name,[wavein])
	string wavein,im1name,im2name,im3name
	variable w5, w20, w100
	string waven
	wave im5 = root:$im1name, im20 = root:$im2name, im100 = root:$im3name
	if(!waveexists(im5) || dimsize(im5,0)!=5000|| dimsize(im5,1)!=5000)
		make/o/n=(5000,5000) im5
		makegausses(im5, 5000, 5, .5)
		newimage im5
	endif
	if(!waveexists(im20) || dimsize(im20,0)!=5000|| dimsize(im20,1)!=5000)
		make/o/n=(5000,5000) im20
		makegausses(im20, 500, 20, 2)
		newimage im20
	endif
	if(!waveexists(im100) || dimsize(im100,0)!=5000|| dimsize(im100,1)!=5000)
		make/o/n=(5000,5000) im100
		makegausses(im100, 30, 100, 10)
		newimage im100
	endif
	if(paramisdefault(wavein))
		wavein = uniquename("system",1,0)
	endif
	wave inwave = $wavein
	if(!waveexists(inwave))
		make/o /n=(5000,5000) $wavein
		wave inwave = $wavein
	endif
	inwave = w5*im5 + w20*im20+w100*im100
	return inwave
end
function fftsim1([killolddata,name,step,im1name,im2name,im3name,pwr]) //ffts all the traces in the top graph and returns a double exponential fit of the first part of the resulting correlation function
	variable killolddata,step,pwr
	string name,im1name,im2name,im3name
	string datafoldersave = getdatafolder(1)
	newdatafolder /o/s root:ffts
	step = paramisdefault(step)? 1 : step
	if(paramisdefault(im1name))
		im1name="root:im5"
	endif
	if(paramisdefault(im2name))
		im2name="root:im20"
	endif
	if(paramisdefault(im3name))
		im3name="root:im100"
	endif
	killolddata = paramisdefault(killolddata) ? 0:killolddata
	if(killolddata)
		dowindow /R/K parameteroutputs
		killwaves/z fftoutputs,wavenames,fftnames,fitnames,acheight1,acheight2,acheight3,aczero,acmin1,acmin2,acmin3
	endif
	variable num=100
	variable i,starti=0,j
	variable graphandsave = 1
	newdatafolder /o/s $name
	make/t/o/n=(num) fftoutputs,wavenames,fftnames,acnames
	make/o/d/n=(num) acheight1=0,acheight2=0,acheight3=0,aczero=0,acmin1=0,acmin2=0,acmin3 = 0
	dowindow /R/K parameteroutputs
	edit/w=(650,400,1000,600) /n=parameteroutputs /k=1 acheight1,acheight2,acheight3,aczero,acmin1,acmin2,acmin3
	string output
	dowindow /r/k $("acfit_"+name)
	display /w=(0,300,600,500) /k=1 /n=$("acfit_"+name) aczero,acmin1,acmin2,acmin3 as "Autocorrlation Properties for "+name
	appendtograph /w=$("acfit_"+name) /r  acheight1,acheight2,acheight3
	ModifyGraph /w=$("acfit_"+name) log(right)=1, log(left)=1
	ModifyGraph /w=$("acfit_"+name) lsize=2,rgb(aczero)=(0,0,0),rgb(acmin1)=(0,0,65280);DelayUpdate
	ModifyGraph /w=$("acfit_"+name) rgb(acmin2)=(0,43520,65280),lstyle(acmin3)=3;DelayUpdate
	ModifyGraph /w=$("acfit_"+name) rgb(acmin3)=(0,43520,65280),rgb(acheight1)=(0,26112,13056);DelayUpdate
	ModifyGraph /w=$("acfit_"+name) rgb(acheight2)=(0,65280,33024),lstyle(acheight3)=2;DelayUpdate
	ModifyGraph /w=$("acfit_"+name) rgb(acheight3)=(0,65280,33024)
	ModifyGraph /w=$("acfit_"+name) lstyle(acmin2)=3,rgb(acmin2)=(0,0,65280),lstyle(acmin3)=8;DelayUpdate
	ModifyGraph /w=$("acfit_"+name) rgb(acmin3)=(0,0,65280),rgb(acheight1)=(0,52224,0);DelayUpdate
	ModifyGraph /w=$("acfit_"+name) lstyle(acheight2)=3,rgb(acheight2)=(0,52224,0),lstyle(acheight3)=8;DelayUpdate
	ModifyGraph /w=$("acfit_"+name) rgb(acheight3)=(0,52224,0)
	ModifyGraph /w=$("acfit_"+name)  mode=3,marker(acmin1)=8,marker(acmin2)=5,marker(acmin3)=6;DelayUpdate
	ModifyGraph /w=$("acfit_"+name)  marker(acheight1)=8,marker(acheight2)=5,marker(acheight3)=6
	setaxis  /w=$("acfit_"+name) bottom 0,100
	setaxis  /w=$("acfit_"+name) left 1,500
	dowindow /R/K $("ac_"+name)
	display/w=(0,300,600,500) /k=1 /n=$("ac_"+name) as "Graph of Fourier Transforms of Scatter Data (Autocorrelations)"
	dowindow /R/K $("fft_"+name)
	display/w=(0,300,600,500) /k=1 /n=$("fft_"+name) as "Graph of Scatter Data"
	dowindow /R/K $("layout_"+name)
	newLayout /k=1/n=$("layout_"+name) /C=1/W=(6.75,39.5,843.75,696.5)/p=landscape as "AutocorrellationLayout"
	printsettings /w=$("layout_"+name) margins={.5,.5,.5,.5}
	appendlayoutobject /F=0 /w=$("layout_"+name)/r=(431.25,347.25,755.25,502.5) graph $("fft_"+name)
	appendlayoutobject /F=0 /w=$("layout_"+name)/r=(526.5,200.25,772.5,355.5)  graph $("acfit_"+name)
	appendlayoutobject /F=0 /w=$("layout_"+name)/r=(41.25,341.25,441.75,496.5)  graph $("ac_"+name)
	appendlayoutobject /F=0 /w=$("layout_"+name)/r=(522.75,39.75,750.75,195)  graph Graph3
	appendlayoutobject /F=0 /w=$("layout_"+name)/r=(344.25,38.25,512.25,342.75)  graph fftdisp
	appendlayoutobject /F=0 /w=$("layout_"+name)/r=(36.75,38.25,345.75,342.75)  graph disp
	ModifyLayout mag=1
	doupdate
	SavePict/O/WIN=$("layout_"+name) /E=-5/P=_PictGallery_/w=(0,0,1000,800) as "myPict"
	newmovie/o/p=Save/PICT=mypict as (name+".mov")
	colortab2wave SpectrumBlack
	duplicate/o M_colors, colorsw
	setscale/i x,0,num, colorsw
	wave c5=root:c5,c20=root:c20,c100=root:c100
	for(i=starti;i<num+starti;i+=step)
		setdrawlayer/k/w=graph3 Userfront
		setdrawlayer /w=graph3 Userfront
		setdrawenv /w=graph3 linethick=2, linepat=1, linefgc=(0,50000,50000), xcoord = bottom, ycoord=left
		drawline /w=graph3 i,.01,i,1
		wave tempwave = combwaves(c5[i],c20[i],c100[i],im1name,im2name,im3name,wavein="tempwave")
		dowindow /r/k disp
		newimage /k=1 /n=disp tempwave
		ModifyGraph/w=disp nticks=0
		ModifyGraph/w=disp margin=1
		ModifyImage/w=disp tempwave log=1, ctab= {.001,*,Grays,0}
		output = fftandintegrate(tempwave,5000,5000,imagename="test"+num2str(i),pwr=pwr)
		wavenames[i] = stringbykey("wavename",output)
		acnames[i] = stringbykey("acname",output)
		fftnames[i] = stringbykey("fftname",output)
		appendtograph /w=$("ac_"+name) $acnames[i]
		modifygraph /w=$("ac_"+name) log(bottom)=1, rgb($acnames[i])=(colorsw(i)[0],colorsw(i)[1],colorsw(i)[2])
		appendtograph /w=$("fft_"+name) $fftnames[i]
		modifygraph /w=$("fft_"+name) log=1, rgb($fftnames[i])=(colorsw(i)[0],colorsw(i)[1],colorsw(i)[2])
		acheight1[i-starti] = -1*numberbykey("acheight1",output)
		acheight2[i-starti] = -1*numberbykey("acheight2",output)
		acheight3[i-starti] = -1*numberbykey("acheight3",output)
		acmin1[i-starti] = numberbykey("acmin1",output)
		acmin2[i-starti] = numberbykey("acmin2",output)
		acmin3[i-starti] = numberbykey("acmin3",output)
		aczero[i-starti] = numberbykey("aczero",output)
		doupdate
		dowindow/f /w=$("layout_"+name) $("layout_"+name)
		doupdate
		SavePict/O/WIN=$("layout_"+name)/E=-5/P=_PictGallery_/w=(0,0,100*11,100*8) as "myPict"
		AddMovieFrame/PICT=myPict
	endfor
	closemovie
	//dowindow /R/K $("acfit_"+name)
	//dowindow /R/K $("ac_"+name)
	//dowindow /R/K $("fft_"+name)
	dowindow /R/K $("layout_"+name)
	dowindow /R/K disp
	dowindow /R/K fftdisp
	dowindow /R/K parameteroutputs
	killwaves/z tempwave, testfft, radialdistance, npoints, wave1lin
	setdatafolder datafoldersave
end
function makepolspheress(wavein,num,size,sd)
	wave wavein
	variable num, size, sd
	variable i,j,cx,cy,r,o,pass,pnum=0
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	make /o /n=(num) cxs, cys
	cxs=0
	cys=0
	for(i=0;i<num;i+=1)
		r = size+gnoise(sd)
		pass=0
		pnum=0
		do
			cx = enoise(sx-2*r)/2 + sx/2
			cy = enoise(sy-2*r)/2 + sy/2
			pass=1
			duplicate /o /r=(cx-r,cx+r)(cy-r,cy+r) wavein, tempwave
			tempwave = (cx-x)^2+(cy-y)^2<r^2 ? tempwave : 0
			if(wavemax(tempwave) > .2)
				pass=0
			endif
			pnum+=1
			if(pnum >500)
				print "fail!"
				pass=1
			endif
		while(pass==0)
		cys[i]=cy
		cxs[i]=cx
		o = enoise(pi)
		wavein[cx-r,cx+r][cy-r,cy+r] += r^2>(p-cx)^2+(q-cy)^2 ? (sqrt(r^2-((p-cx)^2+(q-cy)^2))/r)*abs(cx-p)/sqrt((cx-p)^2 + (cy-q)^2) : 0
	endfor
end
function makepolspheres(wavein,num,size,sd)
	wave wavein
	variable num, size, sd
	variable i,j,cx,cy,r,o,pass,pnum=0
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	make /o /n=(num) cxs, cys
	cxs=0
	cys=0
	for(i=0;i<num;i+=1)
		r = size+gnoise(sd)
		pass=0
		pnum=0
		do
			cx = enoise(sx-2*r)/2 + sx/2
			cy = enoise(sy-2*r)/2 + sy/2
			pass=1
			duplicate /o /r=(cx-r,cx+r)(cy-r,cy+r) wavein, tempwave
			tempwave = (cx-x)^2+(cy-y)^2<r^2 ? tempwave : 0
			if(wavemax(tempwave) > .2)
				pass=0
			endif
			pnum+=1
			if(pnum >500)
				print "fail!"
				pass=1
			endif
		while(pass==0)
		cys[i]=cy
		cxs[i]=cx
		o = enoise(pi)
		//wavein[cx-r,cx+r][cy-r,cy+r] += r^2>(p-cx)^2+(q-cy)^2 ? 2*abs(q-cy)* log( (r+sqrt(r^2-(p-cx)^2-(q-cy)^2))/sqrt((p-cx)^2+(q-cy)^2 ) )/r : 0
		wavein[cx-r,cx+r][cy-r,cy+r] += r^2>(p-cx)^2+(q-cy)^2 ? 2*abs(p-cx)* asinh(sqrt(r^2/((p-cx)^2+(q-cy)^2)-1)) : 0
	endfor
end
function makepolgaussessq(wavein,num,size,sd)
	wave wavein
	variable num, size, sd
	variable i,j,cx,cy,r,o,pass,pnum=0
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	for(i=0;i<num;i+=1)
		r = size+gnoise(sd)
		pass=0
		pnum=0
		do
			cx = enoise(sx-10*r)/2 + sx/2
			cy = enoise(sy-10*r)/2 + sy/2
			pass=1
			duplicate /o /r=(cx-2*r,cx+2*r)(cy-2*r,cy+2*r) wavein, tempwave
			tempwave = (cx-x)^2+(cy-y)^2<4*r^2 ? tempwave : 0
			if(wavemax(tempwave) > .2 * r)
				pass=0
			endif
			pnum+=1
			if(pnum >500)
				print "fail!"
				pass=1
			endif
		while(pass==0)
		wavein[cx-r*10,cx+r*10][cy-10*r,cy+10*r] += Exp(- ((p-cx)^2 +(q-cy)^2)/(2*r^2))*abs(cy-q)/sqrt((cx-p)^2 + (cy-q)^2)
	endfor
end
function makepolspheresshell(wavein,num,size,sd,shellsize)
	wave wavein
	variable num, size, sd,shellsize
	variable i,j,cx,cy,r,o,pass,pnum=0,r1,disq
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	make /o /n=(num) cxs, cys
	cxs=0
	cys=0
	for(i=0;i<num;i+=1)
		r = abs(size+gnoise(sd))
		pass=0
		pnum=0
		do
			cx = enoise(sx-2*r)/2 + sx/2
			cy = enoise(sy-2*r)/2 + sy/2
			pass=1
			duplicate /o /r=(cx-r,cx+r)(cy-r,cy+r) wavein, tempwave
			tempwave = (cx-x)^2+(cy-y)^2<r^2 ? tempwave : 0
			if(wavemax(tempwave) > .2)
				pass=0
			endif
			pnum+=1
			if(pnum >500)
				print "fail!"
				pass=1
			endif
		while(pass==0)
		cys[i]=cy
		cxs[i]=cx
		o = enoise(pi)
		r1 = shellsize*r
		disq = ((p-cx)^2+(q-cy)^2)
		//wavein[cx-r,cx+r][cy-r,cy+r] += r1^2 > disq ? sqrt(r1^2-disq) : 0
		//wavein[cx-r,cx+r][cy-r,cy+r] += (shellsize*r)^2>(p-cx)^2+(q-cy)^2 ? (    sqrt(r^2-((p-cx)^2+(q-cy)^2)) - sqrt((shellsize*r)^2-((p-cx)^2+(q-cy)^2))     )/r  *  abs(cx-p)/sqrt((cx-p)^2 + (cy-q)^2) : 0
		wavein[cx-r,cx+r][cy-r,cy+r] += r^2>((p-cx)^2+(q-cy)^2) && r1^2<=((p-cx)^2+(q-cy)^2)  ?  2*abs(q-cy)* asinh(sqrt(r^2/((p-cx)^2+(q-cy)^2)-1))  : 0
		//wavein[cx-r,cx+r][cy-r,cy+r] += r1^2>((p-cx)^2+(q-cy)^2) ? 2*sqrt(r1^2-((p-cx)^2+(q-cy)^2)) + 2*abs(p-cx)*( asinh(sqrt(r^2/((p-cx)^2+(q-cy)^2)-1))- asinh(sqrt(r1^2/((p-cx)^2+(q-cy)^2)-1)) ) : 0 // filled shell
		wavein[cx-r,cx+r][cy-r,cy+r] += r1^2>((p-cx)^2+(q-cy)^2) ? 2*abs(q-cy)*( asinh(sqrt(r^2/((p-cx)^2+(q-cy)^2)-1))- asinh(sqrt(r1^2/((p-cx)^2+(q-cy)^2)-1)) ) : 0 //empty shell
	endfor
end
function makepolgausshell(wavein,num,size,sd)
	wave wavein
	variable num, size, sd
	variable i,j,cx,cy,r,o,pass,pnum=0
	variable sx=dimsize(wavein,0)
	variable sy=dimsize(wavein,1)
	for(i=0;i<num;i+=1)
		r = size+gnoise(sd)
		pass=0
		pnum=0
		do
			cx = enoise(sx-10*r)/2 + sx/2
			cy = enoise(sy-10*r)/2 + sy/2
			pass=1
			duplicate /o /r=(cx-2*r,cx+2*r)(cy-2*r,cy+2*r) wavein, tempwave
			tempwave = (cx-x)^2+(cy-y)^2<4*r^2 ? tempwave : 0
			if(wavemax(tempwave) > .2 * r)
				pass=0
			endif
			pnum+=1
			if(pnum >500)
				print "fail!"
				pass=1
			endif
		while(pass==0)
		wavein[cx-r*10,cx+r*10][cy-10*r,cy+10*r] += Exp(- ((p-cx)^2 +(q-cy)^2)/(2*r^2))*abs(cy-q)/sqrt((cx-p)^2 + (cy-q)^2)
	endfor
end
function threedtransform(num)
	variable num
	make /o/n=(num,num,num) ss3d
	setscale /i x,-100,100, ss3d
	setscale /i y,-100,100, ss3d
	setscale /i z,-100,100, ss3d
	ss3d = x^2+y^2+z^2>15^2 && x^2+y^2+z^2<20^2 ? abs(y)/sqrt(x^2 + y^2 + z^2) : 0
	fft /dest=ss3dfft ss3d
	make/o /n=(dimsize(ss3dfft,0),dimsize(ss3dfft,1),dimsize(ss3dfft,2)) ss3dfftr, ss3dffti
	ss3dfftr = real(ss3dfft)
	ss3dffti = imag(ss3dfft)
	imagetransform xprojection ss3dfftr
	duplicate/o M_xprojection, ss3dfftrp
	imagetransform xprojection ss3dffti
	duplicate/o M_xprojection, ss3dfftip
	duplicate/o ss3dfftip, ss3dfftp
	ss3dfftp = ss3dfftip[p][q]^2 + ss3dfftrp[p][q]^2
	newimage ss3dfftp
end	