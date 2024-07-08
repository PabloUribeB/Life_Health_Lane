/*************************************************************************
 *************************************************************************			       	
					Extra descriptives simplification
			 
1) Created by: Pablo Uribe						Daniel Márquez
			   World Bank						Harvard Business School
			   puribebotero@worldbank.org		dmarquezm20@gmail.com	
				
2) Date: December 2023

3) Objective: 	Simplificate step 8 outputs to understand which are the
				most common diagnostics for each area of interest

4) Output:	- Three tables
*************************************************************************
*************************************************************************/	


****************************************************************************
*Required packages (uncomment if running for the first time)
****************************************************************************
*ssc install gsort, replace

****************************************************************************
*Globals
****************************************************************************

clear all
set more off


if "`c(username)'" == "Pablo Uribe" {
	global tables	"C:\Users\Pablo Uribe\Dropbox\EH_Papers\Education Paper\Tables"
	global figures	"C:\Users\Pablo Uribe\Dropbox\EH_Papers\Education Paper\Figures"

}

else {
	global tables	"C:\Users\danie\Dropbox\EH_Papers\Education Paper\Tables"
	global figures	"C:\Users\danie\Dropbox\EH_Papers\Education Paper\Figures"
	
}

****************************************************************************
**#						1. Processing
****************************************************************************

use "${tables}\chapter_diag_mental.dta", clear

keep if substr(diag_prin,1,1) == "F"
keep if dist >= 0
collapse (sum) counter, by(diag_prin)
gsort -counter
keep if _n <= 20

save "${tables}\sum_diag_mental.dta", replace

use "${tables}\chapter_cons_mental.dta", clear

keep if dist >= 0
collapse (sum) counter, by(diag_prin)
gsort -counter
keep if _n <= 20

save "${tables}\sum_cons_mental.dta", replace

use "${tables}\chapter_urg_hos.dta", clear

keep if dist >= 0
collapse (sum) counter, by(diag_prin service)
gsort service -counter
bys service: keep if _n <= 20

save "${tables}\sum_urg_hos.dta", replace
