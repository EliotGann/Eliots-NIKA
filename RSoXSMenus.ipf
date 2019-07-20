#pragma rtGlobals=1		// Use modern global access method.
Menu "RSoXS"
	"11.0.1 RSoXs Browser", /Q, Execute/P "INSERTINCLUDE \"1101loadimages-v4\"";Execute/P "COMPILEPROCEDURES ";Execute/P/Q "initialize1101panel()"
	help={"Interactively analyze fits files taken at 11.0.1"}
End
Menu "RSoXS"
	"3D Simulation System", /Q, Execute/P "INSERTINCLUDE \"3DSimulationsv5\"";Execute/P "COMPILEPROCEDURES ";Execute/P/Q "Model3Dpanel()"
	help={"Interactively Create 3D Models and Simulate Scattering"}
End
Menu "RSoXS"
	"NIST RSoXS Browser", /Q, Execute/P "INSERTINCLUDE \"NISTRSoXSBrowser\"";Execute/P "COMPILEPROCEDURES ";Execute/P/Q "NRB_InitNISTRSoXS()"
	help={"Interactively browse data taken at the NIST RSoXS beamline"}
End
