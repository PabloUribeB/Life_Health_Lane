/*************************************************************************
 *************************************************************************			       	
					Event study plotting
			 
1) Created by: Pablo Uribe						Daniel Márquez
			   World Bank						Harvard Business School
			   puribebotero@worldbank.org		dmarquezm20@gmail.com	
				
2) Date: December 2023

3) Objective: Estimate the event studies for PILA and RIPS.
			  This do file can be ran on any computer with access to the ES results.

4) Output:	- One graph per variable in globals
*************************************************************************
*************************************************************************/	


****************************************************************************
*Required packages (uncomment if running for the first time)
****************************************************************************
*ssc install schemeplot, replace

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

/*
if "`c(hostname)'" == "SM201439"{
	global pc "C:"
}

else {
	global pc "\\sm093119"
}

global tables 	"${pc}\Proyectos\Banrep research\Returns to Health Sector\Tables"
global figures 	"${pc}\Proyectos\Banrep research\Returns to Health Sector\Figures"
*/




set scheme white_tableau

****************************************************************************
**#						1. Processing
****************************************************************************

use "${tables}\ST_Results.dta", clear

g dist = substr(var, 12, 1)
destring dist, replace
sort outcome occupation gender dist
drop var

* Separete professions in figures 	
g dist2 = dist		
g dist1 = dist - 0.1 		if (occupation == "P03")
replace dist1 = dist - 0.2 	if (occupation == "P07")
replace dist1 = dist - 0.3	if (occupation == "P09")
replace dist1 = dist 		if (occupation == "P01")

replace dist1 = dist1 + 0.3 if (occupation == "P03" & dist == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P07" & dist == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P09" & dist == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P01" & dist == 0)

drop dist
rename dist1 dist

		
****************************************************************************
**#						2. RIPS
****************************************************************************

levelsof outcome, local(outcomes)
levelsof gender,  local(genders)

*Tester
*local outcomes = "consul_mental_forever"

foreach outcome in `outcomes' {

	foreach gender in `genders' {
		
		preserve
	
		keep if gender == "`gender'"

		qui sum mean if (outcome =="`outcome'" & occupation =="P01")
		local mean_P01: dis %6.4fc r(mean)
		local mean_P01: dis strtrim("`mean_P01'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P03")
		local mean_P03: dis %6.4fc r(mean)
		local mean_P03: dis strtrim("`mean_P03'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P07")
		local mean_P07: dis %6.4fc r(mean)
		local mean_P07: dis strtrim("`mean_P07'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P09")
		local mean_P09: dis %6.4fc r(mean)
		local mean_P09: dis strtrim("`mean_P09'")
		
		twoway 	(rspike ci_lower ci_upper dist 	if (occupation == "P01" & outcome == "`outcome'"), lcolor(gs11) color(gs11) lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P03" & outcome == "`outcome'"), lcolor(gs9)  color(gs9)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P07" & outcome == "`outcome'"), lcolor(gs6)  color(gs6)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P09" & outcome == "`outcome'"), lcolor(gs1)  color(gs1)  lp(solid))					///
				(scatter coef dist 				if (occupation == "P01" & outcome == "`outcome'"), mlc(gs11)    mfc(gs11)   m(O) msize(medsmall))		///
				(scatter coef dist 				if (occupation == "P03" & outcome == "`outcome'"), mlc(gs9)     mfc(gs9)    m(S) msize(medsmall))		///
				(scatter coef dist 				if (occupation == "P07" & outcome == "`outcome'"), mlc(gs6)     mfc(gs6)    m(D) msize(medsmall))		///
				(scatter coef dist 				if (occupation == "P09" & outcome == "`outcome'"), mlc(gs1)     mfc(gs1)    m(T) msize(medsmall)),		///
				xlabel(0(1)4, nogrid labsize(small))	 																							 	///
				ylabel(#10, angle(h) format(%10.3fc) labsize(small))																					///
				xline(-1, lcolor(gs10))																													///
				yline(0, lcolor(gs10))																													///
				xtitle("Years from graduation")																											///
				ytitle("Point estimate")																												///
				legend(order(	8 "Dentists" 	"Mean: `mean_P09'" 	7 "Physicians" "Mean: `mean_P07'"													///
								6 "Nurses" "Mean: `mean_P03'" 		5 "Bacteriologists" "Mean: `mean_P01'") position(6) col(4))							///
				graphregion(fcolor(white))																												
																				
			
		graph export "${figures}\Sun and Abraham\ES_`outcome'_`gender'.pdf", replace
	
		restore
		
	}
	
}


****************************************************************************
**#						4. Mean difference test
****************************************************************************

drop if gender == "all"

keep coef outcome occupation gender dist2 mean stderr
reshape wide coef mean stderr, i(outcome occupation dist2) j(gender) string

rename coefmale x_m
rename coeffemale x_f
rename meanmale m_m
rename meanfemale m_f
rename stderrmale e_m
rename stderrfemale e_f

g mean = m_m-m_f
g coef = x_m-x_f
g sed  = sqrt((e_m^2)+(e_f^2))

g ci_lower = coef - 1.96*sed
g ci_upper = coef + 1.96*sed

drop x_m x_f m_m m_f e_m e_f
rename dist2 dist

* Separete professions in figures
g dist2 = dist 			
g dist1 = dist - 0.1 		if (occupation == "P03")
replace dist1 = dist - 0.2 	if (occupation == "P07")
replace dist1 = dist - 0.3	if (occupation == "P09")
replace dist1 = dist 		if (occupation == "P01")

replace dist1 = dist1 + 0.3 if (occupation == "P03" & dist == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P07" & dist == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P09" & dist == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P01" & dist == 0)

drop dist
rename dist1 dist

****************************************************************************
**#						4.1. RIPS
****************************************************************************
		
levelsof outcome, local(outcomes)

*Tester
*local outcomes = "hosp"

foreach outcome in `outcomes' {
		
		qui sum mean if (outcome =="`outcome'" & occupation =="P01")
		local mean_P01: dis %6.4fc r(mean)
		local mean_P01: dis strtrim("`mean_P01'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P03")
		local mean_P03: dis %6.4fc r(mean)
		local mean_P03: dis strtrim("`mean_P03'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P07")
		local mean_P07: dis %6.4fc r(mean)
		local mean_P07: dis strtrim("`mean_P07'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P09")
		local mean_P09: dis %6.4fc r(mean)
		local mean_P09: dis strtrim("`mean_P09'")
		
		twoway 	(rspike ci_lower ci_upper dist 	if (occupation == "P01" & outcome == "`outcome'"), lcolor(gs11) color(gs11) lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P03" & outcome == "`outcome'"), lcolor(gs9)  color(gs9)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P07" & outcome == "`outcome'"), lcolor(gs6)  color(gs6)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P09" & outcome == "`outcome'"), lcolor(gs1)  color(gs1)  lp(solid))					///
				(scatter coef dist 				if (occupation == "P01" & outcome == "`outcome'"), mlc(gs11)    mfc(gs11)   m(O) msize(medsmall))		///
				(scatter coef dist 				if (occupation == "P03" & outcome == "`outcome'"), mlc(gs9)     mfc(gs9)    m(S) msize(medsmall))		///
				(scatter coef dist 				if (occupation == "P07" & outcome == "`outcome'"), mlc(gs6)     mfc(gs6)    m(D) msize(medsmall))		///
				(scatter coef dist 				if (occupation == "P09" & outcome == "`outcome'"), mlc(gs1)     mfc(gs1)    m(T) msize(medsmall)),		///
				xlabel(0(1)4, nogrid labsize(small))	 																							 	///
				ylabel(#10, angle(h) format(%9.3fc) labsize(small))																						///
				xline(-1, lcolor(gs10))																													///
				yline(0, lcolor(gs10))																													///
				xtitle("Years from graduation")																											///
				ytitle("Point estimate")																												///
				legend(order(	8 "Dentists" 	"Mean `mean_P09'" 	7 "Physicians" "Mean `mean_P07'"													///
								6 "Nurses" 		"Mean `mean_P03'" 	5 "Bacteriologists" "Mean `mean_P01'") position(6) col(4))							///
				graphregion(fcolor(white))																												
																				
			
		graph export "${figures}\Sun and Abraham\ES_`outcome'_gap.pdf", replace
	
}
	
