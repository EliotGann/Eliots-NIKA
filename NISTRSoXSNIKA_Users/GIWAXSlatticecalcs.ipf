#pragma rtGlobgas=3		// Use modern globga access method and strict wave access.
function qmagnitude(h,k,l,a,b,c,al,be,ga)
// finds the magnitude (in q) of a lattice reflection, for a lattice defined by (abc) and angles (gapha, beta, almma)
	variable h,k,l,a,b,c,ga,be,al
	make /o/d /n=3 av, bv, cv, qav, qbv, qcv, qvec
	av={a,0,0}
	bv={b*cos(ga),b*sin(ga),0}
	cv={c*cos(be), -c*cos(be)*cot(ga) + c*cos(al)*csc(ga), sqrt ( c^2 - c^2 * cos(be)^2 + (c * cos(be) * cot(ga) -  c * cos(al) * csc(ga))^2)}
	cross /T bv,cv
	wave w_cross
	matrixop/o magw = av.w_cross
	variable mag = magw[0]
	cross /T bv,cv
	qav = w_cross*2*pi/mag
	cross /T cv,av
	qbv = w_cross*2*pi/mag
	cross /T av,bv
	qcv = w_cross*2*pi/mag
	qvec = h*qav + k*qbv + l*qcv
	return norm(qvec)
end
function latticeangle(h1,k1,l1,h,k,l,a,b,c,al,be,ga)
// finds the magnitude (in q) of a lattice reflection, for a lattice defined by (abc) and angles (gapha, beta, almma)
	variable h1,k1,l1,h,k,l,a,b,c,ga,be,al
	make /o/d /n=3 av, bv, cv, qav, qbv, qcv, qvec1, qvec2
	av={a,0,0}
	bv={b*cos(ga),b*sin(ga),0}
	cv={c*cos(be), -c*cos(be)*cot(ga) + c*cos(al)*csc(ga), sqrt ( c^2 - c^2 * cos(be)^2 + (c * cos(be) * cot(ga) -  c * cos(al) * csc(ga))^2)}
	cross /T bv,cv
	wave w_cross
	matrixop/o magw = av.w_cross
	variable mag = magw[0]
	cross /T bv,cv
	qav = w_cross*2*pi/mag
	cross /T cv,av
	qbv = w_cross*2*pi/mag
	cross /T av,bv
	qcv = w_cross*2*pi/mag
	qvec1 = h*qav + k*qbv + l*qcv
	qvec2 = h1*qav + k1*qbv + l1*qcv
	matrixop/o magw = qvec1.qvec2
	mag = magw[0]
	return acos(mag/(norm(qvec1)*norm(qvec2)))
end

function findGIWAXSLattice(a,b,c,al,be,ga,hz,kz,lz,maxq, [shownega, shownegb, shownegc,addtograph])
	variable a,b,c,ga,be,al,hz,kz,lz,maxq, shownega,shownegb, shownegc, addtograph
	shownega = paramisdefault(shownega) ? 0 : shownega
	shownegb = paramisdefault(shownegb) ? 0 : shownegb
	shownegc = paramisdefault(shownegc) ? 0 : shownegc
	addtograph = paramisdefault(addtograph) ? 0 : addtograph
	ga/=180/pi
	be/=180/pi
	al/=180/pi
	a=abs(a)
	b=abs(b)
	c=abs(c)
	// find a rough guide for how many times each lattice vector should fit
	//  ie a 20nm lamella spacing, out to 2nm^-1 should have 6 reflections or so
	variable maxa = min(ceil(a *maxq *1.5/ (2*pi) ),20)
	variable maxb = min(ceil(b *maxq *1.5/ (2*pi) ),20)
	variable maxc = min(ceil(c *maxq *1.5/ (2*pi) ),20)
	variable mina = shownega ? -maxa : 0
	variable minb = shownegb ? -maxb : 0
	variable minc = shownegc ? -maxc : 0
	make /o/n=(maxa*maxb*maxc*8) qxy,qz,qmag, xi
	make /o/t /n=(maxa*maxb*maxc*8) hkl
	// create recriprocal lattice vectors
	make /free/o/d /n=3 av, bv, cv, qav, qbv, qcv, qvec, qvecz
	av={a,0,0}
	bv={b*cos(ga),b*sin(ga),0}
	cv={c*cos(be), -c*cos(be)*cot(ga) + c*cos(al)*csc(ga), sqrt ( c^2 - c^2 * cos(be)^2 + (c * cos(be) * cot(ga) -  c * cos(al) * csc(ga))^2)}
	cross /T bv,cv
	wave w_cross
	matrixop/free magw = av.w_cross
	variable mag = magw[0], unitcellvol = magw[0]
	cross /T bv,cv
	qav = w_cross*2*pi/mag
	cross /T cv,av
	qbv = w_cross*2*pi/mag
	cross /T av,bv
	qcv = w_cross*2*pi/mag
	make /d/free/n=3 qvecz = hz*qav + kz*qbv + lz*qcv
	make /d/free/n=3 qvecznorm = qvecz/norm(qvecz) // get the normalized z qvector, so we don't have to calculate this again
	// now go through and calculate lattice positions for all the reflections
	variable h,k,L, goodcount=0, cosxi, xiv
	make/n=3/free/d qvec
	for(h=maxa;h>=mina;h-=1)
		for(k=maxb;k>=minb;k-=1)
			for(L=maxc;L>=minc;L-=1)
				qvec = h*qav + k*qbv + l*qcv
				mag = norm(qvec)
				if(mag<maxq && mag>0)
					qvec /=mag
					matrixop/free/o magw = qvec.qvecznorm
					cosxi = abs(magw[0])
					xiv = acos(cosxi)
					xiv = xiv*0==0 ? xiv : 0
					qmag[goodcount,goodcount+1] = mag
					xi[goodcount,goodcount+1] = xiv
					qz[goodcount,goodcount+1] = mag*cosxi
					qxy[goodcount] = mag*sin(xiv)
					qxy[goodcount+1] = -mag*sin(xiv)
					hkl[goodcount,goodcount+1] = "("+num2str(h)+","+num2str(k)+","+num2str(L)+")"
					goodcount+=2
				endif
			endfor
		endfor
	endfor
	redimension /n=(goodcount) qxy,qz,qmag, xi,hkl
	if(addtograph)
		appendtograph /t qz vs qxy
		ModifyGraph textMarker(qz)={hkl,"Arial",0,90,5,0.00,0.00}
	endif
	return unitcellvol
end

function setuplatticeclicking()
	string foldersave = getdatafolder(1)
	setdatafolder root:Packages:GIWAXSLatticeCalcs
	//ccdplotsquare()
	ccdgraph(name="GIWAXS_Lattice")
	movewindow /w=GIWAXS_Lattice_Graph  864.75, 161.75,1326,623.75
	setwindow GIWAXS_Lattice_Graph, hook(mouseuphook) = MouseclickerWindowHook
	wave qxys_exp, qzs_exp, qz, qxy
	wave /t hkl, hkl_obs
	AppendToGraph qzs_exp vs qxys_exp
	AppendToGraph qz vs qxy
	ModifyGraph mode=3,marker=8,mrkThick=2
	ModifyGraph rgb(qzs_exp)=(0,65280,0),rgb(qz)=(0,0,65280)
	ModifyGraph mrkThick(qzs_exp)=2
	ModifyGraph textMarker(qzs_exp)={root:Packages:GIWAXSLatticeCalcs:hkl_obs,"default",0,0,5,0.00,0.00}
	ModifyImage ''#0 minRGB=(26112,26112,26112),maxRGB=(65535,65535,65535)
	ModifyGraph textMarker(qzs_exp)={hkl_obs,"Arial Black",0,0,4,0.00,0.00}
	ModifyGraph textMarker(qzs_exp)={hkl_obs,"Arial Black",0,0,4,0.00,0.00}
	ModifyGraph hideTrace(qz)=1
	ModifyGraph msize(qz)=3,mrkThick(qz)=1
	ModifyGraph marker=8
	ModifyGraph rgb(qzs_exp)=(0,0,0)
	ModifyImage ''#0 ctab= {200,200000,Spectrum,0}
	setdatafolder foldersave
end

Function MouseclickerWindowHook(s)
	STRUCT WMWinHookStruct &s
	Switch(s.eventcode)
		case 5: // mouseup
			string foldersave = getdatafolder(1)
			setdatafolder root:Packages:GIWAXSLatticeCalcs
			variable mouseX = s.mouseloc.h
			variable mouseY = s.mouseloc.v
			wave qxys_exp, qzs_exp, mindist, minidx, h_obs, k_obs, l_obs
			wave /t  hkl_obs
			string tracestr = TraceFromPixel(mouseX, mouseY,"ONLY:qzs_exp;")
			if(s.eventmod==2)
				//print Tracestr
				if(stringmatch(stringbykey("Trace",tracestr),"qzs_exp"))
					variable point = numberbykey("HITPOINT",tracestr)
					deletepoints point, 1, qxys_exp, qzs_exp, mindist, hkl_obs, h_obs, k_obs, l_obs, minidx
					setdatafolder foldersave
					return 1
				endif
			elseif(s.eventmod==8)
				Variable xpos = AxisValFromPixel("", "bottom", mousex)
				Variable ypos = AxisValFromPixel("", "left", mousey)
				insertpoints 0,1, qxys_exp, qzs_exp, mindist, hkl_obs, h_obs, k_obs, l_obs, minidx
				qxys_exp[0] = xpos
				qzs_exp[0] = ypos
				mindist[0] = nan
				minidx[0] = nan
				hkl_obs[0] = "?"
				h_obs[0] =nan
				k_obs[0] =nan
				l_obs[0] =nan
				wave qxy,qz
				checklattice(qxys_exp,qzs_exp,qxy,qz,.2, .1, .1)
				setdatafolder foldersave
				return 1
			endif
			break
	EndSwitch

	return 0
end
function checklattice(x1,y1,x2,y2,extra1, extra2, maxd)
	// finds the nearest point in x2 and y2 (pairs) from each set of x1,y1 pairs
	// calculates the total distance for all pairs (within maxd)
	// for un matched pairs, extra error extra1 and extra2 are added
	wave x1,y1,x2,y2
	variable extra1, extra2, maxd
	duplicate /free x2, distx, disty, disttot
	duplicate/o x1, minidx, mindist // the index of the x2 that is closest to the x1 value
	variable j =0, found=0
	for(j=0;j<dimsize(x1,0);j+=1)
		distx = x2[p]-x1[j]
		disty = y2[p]-y1[j]
		disttot = sqrt(distx^2 + disty^2)
		mindist[j] = wavemin(disttot)
		if(mindist[j] < maxd)
			findvalue /v=(mindist[j]) disttot
			minidx[j] = v_value
			found+=1
		else
			mindist[j] = extra1
			minidx[j] = nan
		endif
	endfor
	variable error = extra2 * (dimsize(x2,0)-found)
	wave/t hkl
	if(waveexists(hkl))
		make /n=(dimsize(x1,0)) /t /o hkl_obs = Selectstring(minidx[p]*0==0,"?",hkl(minidx[p])), hkl_raw = replacestring("(",replacestring(")",hkl(minidx[p]),""),"")
		
		sort hkl_obs, x1,y1,mindist, hkl_obs, minidx
		make /n=(dimsize(x1,0)) /o h_obs = minidx[p]*0==0? str2num(stringfromlist(0,hkl_raw,",")) : nan
		make /n=(dimsize(x1,0)) /o k_obs = minidx[p]*0==0? str2num(stringfromlist(1,hkl_raw,",")) : nan
		make /n=(dimsize(x1,0)) /o L_obs = minidx[p]*0==0? str2num(stringfromlist(2,hkl_raw,",")) : nan
	endif
	
	return error * norm(mindist)
end

function latticecheck(params,coefw)
	wave params
	wave coefw
	// this is the function which will be optimized (via the optimize command)
	// this is a non-least squares version of fitting, just finding the coefficients which minimize the function value (defined by check lattice)
	// params will be the graphed qxy and qz waves, (list of wave names), extra1, extra2, maxd (for the energy calc), and hz,kz,lz,maxq  for the qz calculation
	// coefw will be the a,b,c,alpha, beta, gamma lattice 
	// this function will load up the qxy, qz waves from params, generate the test qxy, qz waves from coefw
	// and return the weighted difference between the observed qxy,qz values and calculated qxy,qz values
	wave qxy_obs = qxys_exp
	wave qz_obs = qzs_exp
	variable extra1 = params[0]
	variable extra2 = params[1]
	variable maxd = params[2]
	variable hz = params[3]
	variable kz = params[4]
	variable Lz = params[5]
	variable maxq = params[6]
	findGIWAXSLattice(coefw[0],coefw[1],coefw[2],coefw[3],coefw[4],coefw[5],hz,kz,lz,maxq, shownega=1, shownegb=1, shownegc=1)
	wave qxy, qz
	return checklattice(qxy_obs,qz_obs,qxy,qz,extra1, extra2, maxd)
end

function testlatticecheck()
	make /o/n=9 params = {.2,.1,.05,0,0,1,2.1}
	make /o/n=6 coefw ={10.5,3.6,23.9,90,95.5,90}
	make /o/n=(6,2) limits = {{6,3,23,60,60,60},{15,5,25,130,130,130}}
	//print latticecheck(params,coefw)
	optimize /A=0 /M={1,0} /R={12.5,3.6,24.50,90,90,90} /S=2 /X=coefw /I=10000 /XSA=limits latticecheck, params
end



Function Slider_GIWAXS(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				string foldersave = getdatafolder(1)
				setdatafolder root:Packages:GIWAXSLatticeCalcs
				nvar a,b,c,al,be,ga,hz,kz,lz,maxq, unitcellvol
				unitcellvol = findGIWAXSLattice(a,b,c,al,be,ga,hz,kz,lz,maxq, shownega=1, shownegb=1, shownegc=1)
				wave qxys_exp,qzs_exp,qxy,qz
				checklattice(qxys_exp,qzs_exp,qxy,qz,.2, .1, .1)
				setdatafolder foldersave
			endif
			break
	endswitch

	return 0
End

Function SetVar_GIWAXS(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			// update giwaxs calculation
			string foldersave = getdatafolder(1)
			setdatafolder root:Packages:GIWAXSLatticeCalcs
			nvar a,b,c,al,be,ga,hz,kz,lz,maxq, unitcellvol
			unitcellvol = findGIWAXSLattice(a,b,c,al,be,ga,hz,kz,lz,maxq, shownega=1, shownegb=1, shownegc=1)
			wave qxys_exp,qzs_exp,qxy,qz
			checklattice(qxys_exp,qzs_exp,qxy,qz,.2, .1, .1)
			setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function GIWAXS_Load(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Load_GIWAXS_Lattice() 
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function Load_GIWAXS_Lattice() 
	dowindow /k GIWAXS_Lattice
	NewPanel /n=GIWAXS_Lattice /W=(164,88,641,492) /k=1 as "GIWAXS Lattice Editor"
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawText 76,278,"Minimum"
	DrawText 154,278,"Maximum"
	DrawText 122,256,"Limits"
	DrawText 192,17,"Qz is defined by:"
	DrawText 311,24,"Q Calculation Details:"
	DrawText 308,77,"Optimization Details:"
	DrawText 241,322,"Control+Click on CCD Plot to Add peak"
	DrawText 264,345,"Shift Click on Peak to Remove it"
	// create waves and variables that will be used for functions
	string foldersave = getdatafolder(1)
	setdatafolder root:
	newdatafolder /o/s Packages
	newdatafolder /o/s GIWAXSLatticeCalcs
	wave/z  qxys_exp, qzs_exp, mindist, h_obs, k_obs, l_obs, minidx, qz, qxy
	wave /z/t hkl, hkl_obs
	if(waveexists(qxys_exp)*waveexists(qzs_exp)*waveexists(mindist)*waveexists(h_obs)*waveexists(k_obs)*waveexists(l_obs)*waveexists(minidx)*waveexists(qz)*waveexists(qxy)*waveexists(hkl)*waveexists(hkl_obs)==0)
		make/o /n=0 qxys_exp, qzs_exp, mindist, h_obs, k_obs, l_obs, minidx, qz, qxy
		make/o/t /n=0 hkl, hkl_obs
	endif
	nvar/z a,b,c,al,be,ga,hz,kz,lz,amin, amax, bmin, bmax, cmin, cmax, almin, almax, bemin, bemax, gamin, gamax, error1, error2, maxd, maxq, unitcellvol
	if(!nvar_exists(a))
		variable /g a = 20
	endif
	if(!nvar_exists(b))
		variable /g b = 10
	endif
	if(!nvar_exists(c))
		variable /g c = 3.5
	endif
	if(!nvar_exists(al))
		variable /g al = 90
	endif
	if(!nvar_exists(be))
		variable /g be = 90
	endif
	if(!nvar_exists(ga))
		variable /g ga = 90
	endif
	if(!nvar_exists(hz))
		variable /g hz = 1
	endif
	if(!nvar_exists(kz))
		variable /g kz = 0
	endif
	if(!nvar_exists(lz))
		variable /g lz = 0
	endif
	if(!nvar_exists(amin))
		variable /g amin = 5
	endif
	if(!nvar_exists(amax))
		variable /g amax = 50
	endif
	if(!nvar_exists(bmin))
		variable /g bmin = 3
	endif
	if(!nvar_exists(bmax))
		variable /g bmax = 20
	endif
	if(!nvar_exists(cmin))
		variable /g cmin = 2
	endif
	if(!nvar_exists(cmax))
		variable /g cmax = 8
	endif
	if(!nvar_exists(almin))
		variable /g almin = 60
	endif
	if(!nvar_exists(almax))
		variable /g almax = 135
	endif
	if(!nvar_exists(bemin))
		variable /g bemin = 60
	endif
	if(!nvar_exists(bemax))
		variable /g bemax = 135
	endif
	if(!nvar_exists(gamin))
		variable /g gamin = 60
	endif
	if(!nvar_exists(gamax))
		variable /g gamax = 135
	endif
	if(!nvar_exists(maxq))
		variable /g maxq = 2.5
	endif
	if(!nvar_exists(maxd))
		variable /g maxd = .15
	endif
	if(!nvar_exists(error1))
		variable /g error1 = .1
	endif
	if(!nvar_exists(error2))
		variable /g error2 = .1
	endif
	if(!nvar_exists(unitcellvol))
		variable /g unitcellvol = 0
	endif
	
	
	
	Button SetupGraph_GIWAXS,pos={10,7},size={101,57},proc=SetupGIWAXSLatticeGraphing,title="Setup Graph for\rLattice Calculations"
	Button Button_ClearPeaksGIWAXS,pos={114,7},size={64,56},proc=GIWAXS_clearpeaks,title="Clear Peaks\rfrom Graph"
	Slider slider_A,pos={7,107},size={118,6},variable= root:Packages:GIWAXSLatticeCalcs:a,proc=Slider_GIWAXS
	Slider slider_A,limits={1,50,0.1},value= 20,side= 0,vert= 0
	Slider slider_B,pos={7,142},size={119,6},variable= root:Packages:GIWAXSLatticeCalcs:b,proc=Slider_GIWAXS
	Slider slider_B,limits={1,50,0.1},value= 10,side= 0,vert= 0
	Slider slider_C,pos={7,171},size={117,6},variable= root:Packages:GIWAXSLatticeCalcs:c,proc=Slider_GIWAXS
	Slider slider_C,limits={1,50,0.1},value= 3.5,side= 0,vert= 0
	Slider slider_alpha,pos={136,107},size={121,6},variable= root:Packages:GIWAXSLatticeCalcs:al,proc=Slider_GIWAXS
	Slider slider_alpha,limits={60,135,0.1},value= 90,side= 0,vert= 0
	Slider slider_beta,pos={136,142},size={121,6},variable= root:Packages:GIWAXSLatticeCalcs:be,proc=Slider_GIWAXS
	Slider slider_beta,limits={60,135,0.1},value= 90,side= 0,vert= 0
	Slider slider_gamma,pos={136,171},size={121,6},variable= root:Packages:GIWAXSLatticeCalcs:ga,proc=Slider_GIWAXS
	Slider slider_gamma,limits={60,135,0.1},side= 0,vert= 0
	Button button_optimize,pos={14,193},size={159,38},proc=OptimizeGiwaxsLattice_but,title="Optimize Values and Index Peaks\r(need to be close)"
	SetVariable var_hz,pos={214,21},size={50,16},proc=SetVar_GIWAXS,value=root:Packages:GIWAXSLatticeCalcs:hz,title="h"
	SetVariable var_kz,pos={214,38},size={50,16},proc=SetVar_GIWAXS,value=root:Packages:GIWAXSLatticeCalcs:kz,title="k"
	SetVariable var_lz,pos={217,55},size={47,16},proc=SetVar_GIWAXS,value=root:Packages:GIWAXSLatticeCalcs:lz,title="l"
	SetVariable var_A,pos={37,83},size={70,16},proc=SetVar_GIWAXS,value=root:Packages:GIWAXSLatticeCalcs:a,title="A",limits={-inf,inf,0.1}
	SetVariable var_B,pos={37,121},size={70,16},proc=SetVar_GIWAXS,value=root:Packages:GIWAXSLatticeCalcs:b,title="B",limits={-inf,inf,0.1}
	SetVariable var_C,pos={37,152},size={70,16},proc=SetVar_GIWAXS,value=root:Packages:GIWAXSLatticeCalcs:c,title="C",limits={-inf,inf,0.1}
	SetVariable var_Alpha,pos={158,84},size={75,16},proc=SetVar_GIWAXS,value=root:Packages:GIWAXSLatticeCalcs:al,title="Alpha",limits={-inf,inf,0.5}
	SetVariable var_Beta,pos={163,118},size={70,16},proc=SetVar_GIWAXS,value=root:Packages:GIWAXSLatticeCalcs:be,title="Beta",limits={-inf,inf,0.5}
	SetVariable var_Gamma,pos={149,152},size={84,16},proc=SetVar_GIWAXS,value=root:Packages:GIWAXSLatticeCalcs:ga,title="Gamma",limits={-inf,inf,0.5}
	SetVariable var_A1,pos={62,282},size={57,16},value=root:Packages:GIWAXSLatticeCalcs:amin,title="A"
	SetVariable var_B1,pos={62,299},size={57,16},value=root:Packages:GIWAXSLatticeCalcs:bmin,title="B"
	SetVariable var_C1,pos={62,316},size={57,16},value=root:Packages:GIWAXSLatticeCalcs:cmin,title="C"
	SetVariable var_Alpha1,pos={44,332},size={85,16},value=root:Packages:GIWAXSLatticeCalcs:almin,title="Alpha"
	SetVariable var_Beta1,pos={47,350},size={82,16},value=root:Packages:GIWAXSLatticeCalcs:bemin,title="Beta"
	SetVariable var_Gamma1,pos={33,367},size={96,16},value=root:Packages:GIWAXSLatticeCalcs:gamin,title="Gamma"
	SetVariable var_A2,pos={152,283},size={57,16},value=root:Packages:GIWAXSLatticeCalcs:amax,title="A"
	SetVariable var_B2,pos={152,300},size={57,16},value=root:Packages:GIWAXSLatticeCalcs:bmax,title="B"
	SetVariable var_C2,pos={152,317},size={57,16},value=root:Packages:GIWAXSLatticeCalcs:cmax,title="C"
	SetVariable var_Alpha2,pos={134,333},size={75,16},value=root:Packages:GIWAXSLatticeCalcs:almax,title="Alpha"
	SetVariable var_Beta2,pos={137,351},size={72,16},value=root:Packages:GIWAXSLatticeCalcs:bemax,title="Beta"
	SetVariable var_Gamma2,pos={123,368},size={86,16},value=root:Packages:GIWAXSLatticeCalcs:gamax,title="Gamma"
	SetVariable var_maxq,pos={298,35},size={163,16},bodyWidth=60,title="Maximum q to calculate"
	SetVariable var_maxq,value= root:Packages:GIWAXSLatticeCalcs:maxq,proc=SetVar_GIWAXS
	SetVariable var_maxd,pos={327,151},size={136,28},bodyWidth=60,title="Maximum q to\rsearch for match"
	SetVariable var_maxd,value= root:Packages:GIWAXSLatticeCalcs:maxd
	SetVariable var_Error1,pos={286,88},size={177,28},bodyWidth=60,title="Cost for no Peak matching\ra Calculated Reflection"
	SetVariable var_Error1,value= root:Packages:GIWAXSLatticeCalcs:error1
	SetVariable var_Error2,pos={287,119},size={176,28},bodyWidth=60,title="Cost for no Calculated\rreflection matching a Peak"
	SetVariable var_Error2,value= root:Packages:GIWAXSLatticeCalcs:error2
	Button SaveLattice,pos={334,197},size={115,25},proc=Savelatticesettings_But,title="Save Lattice Settings"
	Button RecallLattice,pos={334,223},size={115,25},proc=RecallLatticeSettings,title="Recall Lattice Settings"
	Button LoadOptLattice,pos={184,194},size={112,38},proc=LoadOptSettings,title="Load Optimized Lattice"
	SetVariable var_UnitVol,pos={266,270},size={124,13},bodyWidth=50,title="Unit Cell Volume",value=root:Packages:GIWAXSLatticeCalcs:unitcellvol
	CheckBox chk_disprefl,pos={280,365},size={161,14},proc=disprefl_chk,title="Display All Calculated Reflections"
	CheckBox chk_disprefl,value= 0
	setdatafolder foldersave
End

Function disprefl_chk(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				ModifyGraph /w=GIWAXS_Lattice_Graph /z hideTrace(qz)=0
			else
				ModifyGraph /w=GIWAXS_Lattice_Graph /z hideTrace(qz)=1
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SetupGIWAXSLatticeGraphing(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			setuplatticeclicking()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function OptimizeGiwaxsLattice_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
				string foldersave = getdatafolder(1)
				setdatafolder root:Packages:GIWAXSLatticeCalcs
				nvar a,b,c,al,be,ga,amin,bmin,cmin,almin,bemin,gamin,amax,bmax,cmax,almax,bemax,gamax,hz,kz,lz,maxq, error1, error2, maxd
				make /o/n=9 params = {error1,error2,maxd,hz,kz,lz,maxq}
				make /o/n=6 coefw ={a,b,c,al,be,ga}
				make /o/n=(6,2) limits = {{amin,bmin,cmin,almin,bemin,gamin},{amax,bmax,cmax,almax,bemax,gamax}}
				//print latticecheck(params,coefw)
				optimize /A=0 /M={2,0} /R={12.5,3.6,24.50,90,90,90} /S=1 /T=.001 /X=coefw /I=10000 /XSA=limits latticecheck, params
				setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function Savelatticesettings_But(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
				string foldersave = getdatafolder(1)
				setdatafolder root:Packages:GIWAXSLatticeCalcs
				nvar a,b,c,al,be,ga
				make /o/n=6 savedlattice ={a,b,c,al,be,ga}
				setdatafolder foldersave
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function RecallLatticeSettings(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
				string foldersave = getdatafolder(1)
				setdatafolder root:Packages:GIWAXSLatticeCalcs
				nvar a,b,c,al,be,ga,hz,kz,lz,maxq, unitcellvol
				wave /z savedlattice // ={a,b,c,al,be,ga}
				if(waveexists(savedlattice))
					a = savedlattice[0]
					b = savedlattice[1]
					c = savedlattice[2]
					al = savedlattice[3]
					be = savedlattice[4]
					ga = savedlattice[5]
					unitcellvol = findGIWAXSLattice(a,b,c,al,be,ga,hz,kz,lz,maxq, shownega=1, shownegb=1, shownegc=1)
					wave qxys_exp,qzs_exp,qxy,qz
					checklattice(qxys_exp,qzs_exp,qxy,qz,.2, .1, .1)
				endif
				setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function LoadOptSettings(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
				string foldersave = getdatafolder(1)
				setdatafolder root:Packages:GIWAXSLatticeCalcs
				nvar a,b,c,al,be,ga,hz,kz,lz,maxq, unitcellvol
				wave /z coefw // ={a,b,c,al,be,ga}
				if(waveexists(coefw))
					a = coefw[0]
					b = coefw[1]
					c = coefw[2]
					al = coefw[3]
					be = coefw[4]
					ga = coefw[5]
					unitcellvol = findGIWAXSLattice(a,b,c,al,be,ga,hz,kz,lz,maxq, shownega=1, shownegb=1, shownegc=1)
					wave qxys_exp,qzs_exp,qxy,qz
					checklattice(qxys_exp,qzs_exp,qxy,qz,.2, .1, .1)
				endif
				setdatafolder foldersave
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function GIWAXS_clearpeaks(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
				string foldersave = getdatafolder(1)
				setdatafolder root:Packages:GIWAXSLatticeCalcs
				make/o /n=0 qxys_exp, qzs_exp, mindist, h_obs, k_obs, l_obs, minidx
				make/o/t /n=0 hkl_obs
				setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
