#pragma rtGlobals=1		// Use modern global access method.
Menu "RSoXS"
		"11.0.1 RSoXs Browser", /Q, Execute/P "INSERTINCLUDE \"1101loadimages-v4\"";Execute/P "COMPILEPROCEDURES ";Execute/P/Q "initialize1101panel()"
		help={"Interactively analyze fits files taken at 11.0.1.2 of the Advanced Light Source"}
		"NIST RSoXS Browser", /Q, Execute/P "INSERTINCLUDE \"NISTRSoXSBrowser\"";Execute/P "COMPILEPROCEDURES ";Execute/P/Q "NRB_InitNISTRSoXS()"
		help={"Interactively browse RSoXS data taken at NSLS-II SST-1 beamline"}
		"RSoXS Simulation System", /Q, Execute/P "INSERTINCLUDE \"3DSimulationsv5\"";Execute/P "COMPILEPROCEDURES ";Execute/P/Q "Model3Dpanel()"
		help={"Interactively Create and Analyze RSoXS Simulations"}
End
