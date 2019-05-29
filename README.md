# Eliot's-NIKA
Branch of NIKA which adds custom functionality for RSoXS and GIWAXS based in Igor Pro

developed by Eliot Gann at North Carolina State University with the help of many other people (most notably Brian Collins)
contact Eliot Gann (eliot.gann@nist.gov) with any questions.  Although this isn't actively maintained in any sense, I will probably be able to help with any reasonable requests.

This is largely extending upon on older altered version of NIKA.  Over the years, it has added many many options and capabilities beyond the version of NIKA which was used as the basis.  

These are a set of useful tools which I have used in my research over the last decade, and which I made before I knew how to code properly.  I include the branched NIKA files which have been edited from the original signifigantly, but are still under that license.  Please cite NIKA properly if you use this to analyze any data.  (see https://usaxs.xray.aps.anl.gov/software/nika for how to cite NIKA as well as the much updated current version of NIKA which is  of course NOT compatible with any of these procedures anymore, but has also added some of these features over the years)

Suggested Installation Method:

1.) clone this repository to your local machine.

2.) uninstall or temporarily move any existing NIKA installation from the active igor pro folder

3.) open your users files directory (from Igor Pro  select Help-> Igor Pro User Files)
    usually this is in the documents/wavemetrics/ folder
    (close Igor after this step)

4.) create a shortcut (windows) or alias (Mac) of EliotMenus.ipf and Boot Nika.ipf files in the "Igor Procedures" directory

5.) create a shortcut or alias of all of the rest of the files and those in the subdirectory into a NIKA directory (make one if there isn't one already) within the "User Procedures" cirectory

6.) Install XMLUtils (https://www.wavemetrics.com/project/XMLutils)

7.) Restart Igor Pro, you should see the menu items appear under Macros
