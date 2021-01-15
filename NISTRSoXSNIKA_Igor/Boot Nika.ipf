#pragma rtGlobals=1		// Use modern global access method.
#pragma version=1.70


Menu "Macros"
	StrVarOrDefault("root:Packages:EGNika2DSASItem1Str","Load Eliot Branch of Nika (2D SAS reduction)"), LoadEGN2DSAS()
end


Function LoadEGN2DSAS()
	if (str2num(stringByKey("IGORVERS",IgorInfo(0)))>=6.30)
		Execute/P "INSERTINCLUDE \"EGN_Loader\""
		Execute/P "COMPILEPROCEDURES "
		NewDataFolder/O root:Packages			//create the folder for string variable
		string/g root:Packages:EGNika2DSASItem1Str
		SVAR EGNika2DSASItem1Str=root:Packages:EGNika2DSASItem1Str
		EGNika2DSASItem1Str= "---"
		BuildMenu "SAS 2D"
		Execute/P "EGN_ReadNikaGUIPackagePrefs()"
	else
		DoAlert 0, "Your version of Igor is lower than 6.30, these macros need version 6.30 or higher. Please, update..."  
	endif
end


