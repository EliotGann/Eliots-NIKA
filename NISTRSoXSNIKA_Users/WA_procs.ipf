#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Proc GiWAXSINandOUTofPlane() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	MoveWindow 500,200,1000,500
	ModifyGraph/Z margin(left)=50,margin(bottom)=50,margin(top)=50,margin(right)=14
	ModifyGraph/Z gfSize=14
	ModifyGraph/Z lSize=2
	ModifyGraph/Z rgb[0]=(0,0,0),rgb[1]=(0,0,63232)
	ModifyGraph/Z grid(left)=2,grid(bottom)=2
	ModifyGraph/Z log=1
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror(left)=1
	ModifyGraph/Z minor=1
	ModifyGraph/Z standoff=0
	ModifyGraph/Z axThick=2
	ModifyGraph/Z lblPosMode(bottom)=1,lblPosMode(MT_bottom)=1
	ModifyGraph/Z stThick=1
	ModifyGraph/Z ttThick=1
	ModifyGraph/Z ftThick=1
	ModifyGraph/Z freePos(MT_bottom)=0
	Modifygraph mirror=0
	modifygraph mirror(left)=1
	Legend/C/N=text0/J "\\s(#0) Out of Plane\r\\s(#1) In Plane"
	Label/Z left "Intenisty"
	Label/Z bottom "q [Å\\S-1\\M]"
	Label/Z MT_bottom "d-spacing [Å]"
	SetAxis/Z bottom 0.2,2
EndMacro

Function WarrenAverbach(w,n,m) : FitFunc
	Wave w
	Variable n
	Variable m

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(n,m) = exp(-(n/num)^alpha)*exp(-2* m^2 * pi^2 *n *(g^2 + n*e^2))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ n
	//CurveFitDialog/ m
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = e
	//CurveFitDialog/ w[1] = g
	//CurveFitDialog/ w[2] = num
	//CurveFitDialog/ w[3] = Alpha
	//CurveFitDialog/ w[4] = A0
	//CurveFitDialog/ w[5] = A1
	//CurveFitDialog/ w[6] = A2
	//n/=pi
	//variable SizeFactor = Exp(-((1-w[2]+n)/w[3])^2)*w[3] + (w[2]-n)*sqrt(pi)*Erfc((1-w[2]+n)/w[3])
	//SizeFactor /= Exp(-((1-w[2])/w[3])^2)*w[3] + w[2]*sqrt(pi)*Erfc((1-w[2])/w[3])
	
	variable SizeFactor = sizefunc(n,w[3],w[2])
	return (w[4]+m*w[5] + m*m*w[6])*SizeFactor*exp( -2 * (m^2) * (pi^2) * (n^2) * w[0]^2 ) * exp( -2 * (m^2) * (pi^2) * n * w[1]^2)
	// need to figure out how to add in dispersion in num (w[2]), it will help all fits
	// in fft of delta function
End

function sizefunc(n,sigma,M0)
	variable n, sigma, M0
	variable SizeFactor
	//Gaussian - we use the sigma
	//SizeFactor = Exp(-((1-M0+n)/sigma)^2)*sigma + (M0-n)*sqrt(pi)*Erfc((1-M0+n)/sigma)
	//SizeFactor /= Exp(-((1-M0)/sigma)^2)*sigma + M0*sqrt(pi)*Erfc((1-M0)/sigma)
	//LogNormal - uses sigma
	sizefactor =-2 * n + n * Erfc(Log(M0/(1 + n))/sqrt(Log(1 + sigma^2/M0^2))) 
	sizefactor+= sqrt(M0) * (M0^2 + sigma^2)^(1/4) * Erfc((2 * Log(1 + n) - Log(M0^2 + sigma^2))/( 2 * sqrt(Log(1 + sigma^2/M0^2))))
	sizefactor /=sqrt(M0) * (M0^2 + sigma^2)^(1/4) * Erfc(-(Log(M0^2 + sigma^2)/(2 * sqrt(Log(1 + sigma^2/M0^2)))))
	
	//Poisson Distribution, the sigma is not used
	//SizeFactor = 1 - n/M0 + (M0^n * (exp(-M0) + (-M0+ n) * ExpInt(n, M0))) / gamma(1 + n)
	return sizefactor
end

function /S CalcWA(wavein,waveinx,locations,width,maxq,sigma,quiet)
	wave wavein, waveinx
	string locations
	variable width,maxq, sigma,quiet
	string foldersave = getdatafolder(1)
	setdatafolder root:
	newdatafolder /o/s WA_analysis
	newdatafolder /o/s $uniquename(nameofwave(wavein),11,0)
	variable num = itemsinlist(locations,","),j=0, peakvalue
	make /n=(num) /wave /o peaks, peakffts
	if(quiet==0)
		dowindow /k PeakPlot
		display /k=1 /n=PeakPlot
	endif
	variable xoffset, yoffset, y1offset, Aoffset
	Variable V_fitOptions=4
	variable v_fiterror=0
	for(j=0;j<num;j+=1)
		make /n=100 /o peak
		setscale /i x, -width*1.2, width*1.2, peak
		xoffset = str2num(stringfromlist(j,locations,","))
		peak = interp(x+xoffset, waveinx, wavein)
		//display /k=1 peak
		//Make/D/N=5/O W_coef = {.01,1,.01,width*.2,.01}
		//FuncFit /NTHR=0 /q /w=2 NI2BC_GaussWithSlopeBckg W_coef  peak /D 
		//peak -= w_coef[0] + x * w_coef[4]
		//peak /= w_coef[1]
		Make/D/N=5/O W_coef = {.01,1,.01,width*.2}
		v_fiterror=0
		V_fitOptions=4
		CurveFit/q/M=2/W=2 gauss, peak
		xoffset += w_coef[2]
		yoffset = w_coef[0]
		Aoffset = w_coef[1]
		peak = interp(x+xoffset, waveinx, wavein)
		peak -= yoffset
		peak /= Aoffset
		//doupdate
		
		Make/D/N=5/O W_coef = {.01,1,.01,width*.2,.01}
		v_fiterror=0
		V_fitOptions=4
		FuncFit /NTHR=0 /q /w=2 NI2BC_GaussWithSlopeBckg W_coef  peak /D 
		xoffset += w_coef[2]
		Aoffset *= w_coef[1]
		yoffset += w_coef[0]
		peak = interp(x+xoffset, waveinx, wavein)
		peak -= yoffset  + x * w_coef[4]
		peak /= Aoffset
		//doupdate
		
		duplicate /o peak, peakx
		peakx=x
		make /o/n=64 $("Peak_"+num2str(j))
		wave temppeak = $("Peak_"+num2str(j))
		peaks[j] = $("Peak_"+num2str(j))
		setscale /i x, -width, width, temppeak
		temppeak=interp(x,peakx,peak)
		fft /dest=peakfft /real temppeak
		peakfft *=(-1)^p
//		peakvalue = peakfft[0]
//		peakfft/=  peakvalue
		duplicate/o peakfft, $("Peakfft_"+num2str(j))
		peakffts[j] = $("Peakfft_"+num2str(j))
		if(quiet==0)
			appendtograph temppeak
		endif
	endfor
	make /o/n=(dimsize(peakfft,0),num) flatpeakffts, xvalues, mvalues
	for(j=0;j<num;j+=1)
		wave tempfft = peakffts[j]
		flatpeakffts[][j] = tempfft[p]
	endfor
	mvalues = q+1
	xvalues = pnt2x(tempfft,p)
	redimension /n=(dimsize(tempfft,0)*num) flatpeakffts, xvalues, mvalues
	duplicate /o xvalues, xmask
	xmask = xvalues<maxq &&xvalues>=1? 1 : 0
	//xmask = xvalues<maxq ? 1 : 0	
	Make/D/O W_coef = {0.0000004, 0.004, .5 , sigma , 1,1,1}
	Make/D/O new_epswave = {.0000000001,.0000001,.00001,.00001,.00001,.00001,.00001}
	Make/O/T T_Constraints = {"K0>0","K1>0","K2>0","K2<300"}
	//Make/O/T T_Constraints = {"K1>0.000001"}
	v_fiterror=0
	V_fitOptions=4
	FuncFit /ODR=1/NTHR=0 /w=(quiet*2)/q=(quiet)/NTHR=0 /H="0000000" WarrenAverbach W_coef  flatpeakffts /X={xvalues,mvalues} /M=xmask /D /E=new_epswave /C=T_Constraints 
	//if(v_fiterror)
	//	setdatafolder foldersave
	//	return "ERROR"
	//endif
	wave w_sigma
	make /o/n=(200,num) fit_x, fit_m, fit_peakffts
	setscale /i x, wavemin(xvalues),wavemax(xvalues), fit_x
	fit_x=x
	fit_m=q+1
	redimension /n=(200*num)  fit_x, fit_m, fit_peakffts
	FIT_peakffts = WarrenAverbach(w_coef,fit_x[p],fit_m[p])
	redimension /n=(200,num)  fit_x, fit_m, fit_peakffts
	if(quiet==0)
		dowindow /k PeakFFTPlot
		display /W=(38.25,284,432.75,492.5) /k=1 /n=PeakFFTPlot
		for(j=0;j<num;j+=1)
			appendtograph FIT_peakffts[][j] vs fit_x[][j]
		endfor
		appendtograph flatpeakffts vs xvalues
		ModifyGraph mode(flatpeakffts)=3,rgb(flatpeakffts)=(0,0,0)
	endif
	setdatafolder foldersave
	string output = nameofwave(wavein) + "\t" + num2str(v_chisq) + "\t" //name of wave, chi square of fit (higher than 1 is unreasonable (generally) - this is also returned direction from function
	output += num2str(w_coef[0]) + "\t" + num2str(w_sigma[0]) + "\t"	//e - energetic disprder parameter (percentage of error between crystals)
	output += num2str(w_coef[1]) + "\t" + num2str(w_sigma[1]) + "\t"	//g - paracrystallinity (percentage of error in each crystal)
	output += num2str(w_coef[2]) + "\t" + num2str(w_sigma[2]) + "\t"	//center of distribution of crystal sizes
	output += num2str(w_coef[3]) + "\t" + num2str(w_sigma[3]) + "\t"	//width of distribution of crystal sizes
	if(quiet==0)
		putscraptext output
	endif
	doupdate
	return OUTPUT
end

function WATopGraph(peaklocs)
	string peaklocs
	string waveliststr = TraceNameList("", ";", 1 )
	make /wave/o/n=(itemsinlist(waveliststr)) xwaves, ywaves
	ywaves = TraceNameToWaveRef("", stringfromlist(p,waveliststr) )
	xwaves = XWaveRefFromTrace("", stringfromlist(p,waveliststr) )
	variable i, bestsigma, bestwidth, j
	string results
	make /n=40 /o chiresults=0
	make/t /o/n=(dimsize(ywaves,0)) wavenames
	make /o/n=(dimsize(ywaves,0)) chisqrs, widths, es, eerrors, gs, gerrors, nums, numerrors, sigmas
	edit/W=(5.25,42.5,954,269.75)/k=1 wavenames,chisqrs, widths, es, eerrors, gs, gerrors, nums, numerrors, sigmas
	dowindow /k ChiPlot
	display /W=(518.25,347,912.75,555.5) /n=ChiPlot chiresults
	ModifyGraph mode=3,marker=19,rgb=(0,0,0)
	Label left "Chi Squared"
	ModifyGraph tick=2,mirror=1,standoff=0
	for(i=0;i<dimsize(ywaves,0);i+=1)
//		setscale/i x,1,30,chiresults
//		dowindow /f Chiplot
//		SetAxis/A bottom
//		ModifyGraph log(left)=1
//		chiresults=0
//		Label bottom "Width of Distribution [repeatunits]"
//		doupdate
//		string output
//	//	for(j=0;j<numpnts(chiresults);j+=1)
//	//		output = CalcWA(ywaves[i],xwaves[i],peaklocs,.15,200,pnt2x(chiresults,j),1)
//	//		chiresults[j]=str2num(stringfromlist(1,output,"\t") )
//	//	endfor
//	//	wavestats /z/q chiresults
//	//	bestsigma = v_minloc
//	//	setscale/i x,max(.8*bestsigma-5,1),bestsigma*1.5+5,chiresults
//	//	dowindow /f Chiplot
//	//	SetAxis/A bottom
//	//	chiresults=0
//	//	doupdate
//		for(j=0;j<numpnts(chiresults);j+=1)
//			output = CalcWA(ywaves[i],xwaves[i],peaklocs,.15,200,pnt2x(chiresults,j),1)
//			chiresults[j]=str2num(stringfromlist(1,output,"\t") )
//		endfor
//		wavestats /z/q chiresults
//		bestsigma = v_minloc
//		setscale/i x,.05,.3,chiresults
//		dowindow /f Chiplot
//		SetAxis/A bottom
//		chiresults=0
//		Label bottom "Peak Window [dQ]"
//		doupdate
//		for(j=0;j<numpnts(chiresults);j+=1)
//			output = CalcWA(ywaves[i],xwaves[i],peaklocs,pnt2x(chiresults,j),100,bestsigma,1)
//			chiresults[j]=str2num(stringfromlist(1,output,"\t") )
//		endfor
//		wavestats /z/q chiresults
//		bestwidth = v_minloc
//		setscale/i x,max(bestwidth-.02,.03),bestwidth+.02,chiresults
//		dowindow /f Chiplot
//		SetAxis/A bottom
//		chiresults=0
//		doupdate
//		for(j=0;j<numpnts(chiresults);j+=1)
//			output = CalcWA(ywaves[i],xwaves[i],peaklocs,pnt2x(chiresults,j),100,bestsigma,1)
//			chiresults[j]=str2num(stringfromlist(1,output,"\t") )
//		endfor
//		wavestats /z/q chiresults
//		bestwidth = v_minloc
		results = CalcWA(ywaves[i],xwaves[i],peaklocs,.15,200,5,0)
		wavenames[i] = stringfromlist(0,results,"\t")
		chisqrs[i] = str2num(stringfromlist(1,results,"\t"))
		es[i] = str2num(stringfromlist(2,results,"\t"))
		eerrors[i] = str2num(stringfromlist(3,results,"\t"))
		gs[i] = str2num(stringfromlist(4,results,"\t"))
		gerrors[i] = str2num(stringfromlist(5,results,"\t"))
		nums[i] = str2num(stringfromlist(6,results,"\t"))
		numerrors[i] = str2num(stringfromlist(7,results,"\t"))
		sigmas[i] = str2num(stringfromlist(8,results,"\t"))
		widths[i] = bestwidth
		doupdate
	endfor
	
end