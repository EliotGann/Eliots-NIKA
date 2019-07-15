#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.70


Menu "Macros"
	StrVarOrDefault("root:Packages:Nika12DSASItem1Str","Load Nika 2D SAS Macros"), LoadEGN2DSAS()
end


Function LoadEGN2DSAS()
	if (str2num(stringByKey("IGORVERS",IgorInfo(0)))>=6.30)
		Execute/P "INSERTINCLUDE \"EGN_Loader\""
		Execute/P "COMPILEPROCEDURES "
		NewDataFolder/O root:Packages			//create the folder for string variable
		string/g root:Packages:Nika12DSASItem1Str
		SVAR Nika12DSASItem1Str=root:Packages:Nika12DSASItem1Str
		Nika12DSASItem1Str= "---"
		BuildMenu "SAS 2D"
		Execute/P "EGN_ReadNikaGUIPackagePrefs()"
	else
		DoAlert 0, "Your version of Igor is lower than 6.30, these macros need version 6.30 or higher. Please, update..."  
	endif
end


