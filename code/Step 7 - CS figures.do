/*************************************************************************
 *************************************************************************			       	
					Event study plotting
			 
1) Created by: Pablo Uribe                      Daniel Márquez
			   Yale University                  Harvard Business School
			   p.uribe@yale.edu                 dmarquezm20@gmail.com
				
2) Date: December 2023

3) Objective: Estimate the event studies for PILA and RIPS.
			  This do file can be ran on any computer with access to the ES results.

4) Output:	- One graph per variable in globals
*************************************************************************
*************************************************************************/	


****************************************************************************
*Globals
****************************************************************************

clear all
set more off

global user "`c(username)'"

global tables	"C:\Users\${user}\Dropbox\EH_Papers\Education Paper\Tables"
global figures	"C:\Users\${user}\Dropbox\EH_Papers\Education Paper\Figures"


set scheme white_tableau

****************************************************************************
**#						1. Processing
****************************************************************************

use "${tables}\CS_Results.dta", clear
drop if var == "Pre_avg" | var == "Post_avg"

gen 	dist 		= substr(var, 3, 1) if (strlen(var) == 3)
replace dist 		= substr(var, 3, 2) if (strlen(var) == 4)
destring dist, replace
replace dist 		= dist * (-1) if (substr(var, 1, 2) == "tm")
sort outcome occupation gender dist

gen pila_outcome 	=  (outcome == "sal_dias_cot_0"			| outcome == "pila_salario_r_0" 		|				///
						outcome == "p_cotizaciones_0"		| outcome == "pila_independientes"		|  				///
						outcome == "posgrado_salud"			| outcome == "pila_salario_r_0_np"		| 				///
						outcome == "pila_salario_r_max_0"	| outcome == "pila_salario_r_0_posg"	|				///
						outcome == "pila_salario_r_0_npos"	)
						
gen rips_outcome	=  (outcome == "urg"					| outcome == "urg_np"					| 				///
						outcome == "hosp"					| outcome == "hosp_np" 					|				///
						outcome == "service_mental_forever"	| outcome == "pregnancy"				)
						
keep if pila_outcome == 1 | rips_outcome == 1

* Conversion factor PPA
* Source: https://datos.bancomundial.org/indicator/PA.NUS.PRVT.PP?locations=CO
gen ppa = 1464.41

foreach var in pila_salario_r_0 pila_salario_r_0_np pila_salario_r_max_0 pila_salario_r_0_posg pila_salario_r_0_npos {
	
	replace coef 		= coef / ppa 		if outcome == "`var'"
	replace stderr 		= stderr / ppa 	    if outcome == "`var'"
	replace ci_lower	= ci_lower / ppa 	if outcome == "`var'"
	replace ci_upper 	= ci_upper / ppa 	if outcome == "`var'"
	replace mean	 	= mean / ppa 		if outcome == "`var'"
	
}
drop ppa

		
* Balance for variables with non-estimated periods
preserve

	keep outcome occupation gender pila_outcome
	duplicates drop
	expand 14
	
	bys outcome occupation gender pila_outcome: gen dist = _n - 5
	drop if dist == -1
	
	tempfile temp
	save `temp'
	
restore

merge m:1 dist outcome occupation gender pila_outcome using `temp', nogen
replace coef = 0 if coef == . & dist < 0
replace ci_lower = 0 if ci_lower == . & dist < 0
replace ci_upper = 0 if ci_upper == . & dist < 0

gen dist2 = dist		

* Relevant periods	
drop if (dist < -2 & pila_outcome == 0)
drop if (dist < -4 & pila_outcome == 1)

drop if (dist >  4 & pila_outcome == 0)
drop if (dist >  9 & pila_outcome == 1)

sort outcome occupation gender dist

* Separete professions in figures 			
gen dist1 = dist - 0.1 		if (occupation == "P03" & pila_outcome == 0)
replace dist1 = dist - 0.2 	if (occupation == "P07" & pila_outcome == 0)
replace dist1 = dist - 0.3	if (occupation == "P09" & pila_outcome == 0)
replace dist1 = dist 		if (occupation == "P01" & pila_outcome == 0)

replace dist1 = dist1 + 0.3 if (occupation == "P03" & dist == -2 & pila_outcome == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P07" & dist == -2 & pila_outcome == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P09" & dist == -2 & pila_outcome == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P01" & dist == -2 & pila_outcome == 0)

replace dist1 = dist - 0.15 	if (occupation == "P03" & pila_outcome == 1)
replace dist1 = dist - 0.30 	if (occupation == "P07" & pila_outcome == 1)
replace dist1 = dist - 0.45		if (occupation == "P09" & pila_outcome == 1)
replace dist1 = dist 			if (occupation == "P01" & pila_outcome == 1)

replace dist1 = dist1 + 0.45 	if (occupation == "P03" & dist <= -2 & pila_outcome == 1)
replace dist1 = dist1 + 0.45 	if (occupation == "P07" & dist <= -2 & pila_outcome == 1)
replace dist1 = dist1 + 0.45 	if (occupation == "P09" & dist <= -2 & pila_outcome == 1)
replace dist1 = dist1 + 0.45 	if (occupation == "P01" & dist <= -2 & pila_outcome == 1)

drop dist
rename dist1 dist


* Same Y labels for each outcome set
bys outcome: egen max = max(ci_upper)
bys outcome: egen min = min(ci_lower)

tostring max min, gen(max_s min_s) force
gen negative = 1 if substr(min_s,1,1) == "-" //All mins are negative
drop negative

replace max_s = subinstr(max_s, "-", "", 1)
replace max_s = subinstr(max_s, ".", "0.", 1) if substr(max_s, 1, 1) == "."		
replace min_s = subinstr(min_s, "-", "", 1)
replace min_s = subinstr(min_s, ".", "0.", 1) if substr(min_s, 1, 1) == "."			

foreach var in max min {
			
	forval i = 1(1)12 {			
		gen `var'c_`i' = substr(`var'_s,`i',1)			
	}
	
	gen decimal = 0		
	forval i = 11(-1)3 {
		local j = `i'+1
		replace decimal = `i' if `var'c_`i' == "0" & `var'c_`j' != "0" 		
	}
	
	replace decimal = decimal - 1
	replace decimal = 1 if `var'c_3 != "0" & `var'c_1 == "0"
	replace decimal = 0 if `var'c_1 != "0"
		
	gen unit = 0
	forval i = 12(-1)2 {
		replace unit = `i' - 1 if `var'c_`i' == ""
		replace unit = `i' - 1 if `var'c_`i' == "."
	}
	
	replace unit = 0 if `var'c_1 == "0"
	replace unit = unit - 1 if unit != 0
	
	drop `var'c*
	gen round_number = 1
	replace round_number = round_number * (10 ^ unit)
	replace round_number = round_number / (10 ^ decimal) if unit == 0
	replace round_number = round_number
	rename (round_number decimal unit) (round_number_`var' decimal_`var' unit_`var') 
	
}

egen round_number = rowmax(round_number_min round_number_max)
gen min1 = -round_number
gen max1 = round_number

forval i = 1/10 {
	replace min1 = min1 - round_number if min1 > min
}	

forval i = 1/10 {
	replace min1 = min1 + round_number / 2 if min1 + round_number / 2 < min
}

forval i = 1/10 {
	replace max1 = max1 + round_number if max1 < max
}	

forval i = 1/10 {
	replace max1 = max1 - round_number / 2 if max1 - round_number / 2 > max
}

replace round_number = round_number / 4 if round_number > (max1 - min1) * 0.4
replace round_number = round_number / 2 if round_number > (max1 - min1) * 0.2
replace round_number = round_number * 2 if round_number < (max1 - min1) * 0.1
replace round_number = round_number * 4 if round_number < (max1 - min1) * 0.05
replace round_number = round_number * 8 if round_number < (max1 - min1) * 0.02

drop max-round_number_min
rename (round_number min1 max1) (change min max)
compress		

* Exclude nurses and bacteriologist for postgraduate outcomes
drop if	(outcome 	== "posgrado_salud" | outcome 		== "pila_salario_r_0_npos" | outcome == "pila_salario_r_0_posg") & ///
		(occupation == "P01" 			| occupation 	== "P03")		
		
		
****************************************************************************
**#						2. RIPS
****************************************************************************

levelsof outcome if pila_outcome == 0, local(outcomes)
levelsof gender, local(genders)

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
		
		if gender == "male" | gender == "female" {
			
			qui sum min if (outcome =="`outcome'")
			local min = r(mean)
			qui sum max if (outcome =="`outcome'")
			local max = r(mean)
			qui sum change if (outcome =="`outcome'")
			local change = r(mean)
			
			local ylabel = "`min'(`change')`max'"
			
		}
		else {
			
			local ylabel = "#10"
			
		}
			
		twoway 	(rspike ci_lower ci_upper dist 	if (occupation == "P01" & outcome == "`outcome'"), lcolor(gs11) color(gs11) lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P03" & outcome == "`outcome'"), lcolor(gs9)  color(gs9)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P07" & outcome == "`outcome'"), lcolor(gs6)  color(gs6)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P09" & outcome == "`outcome'"), lcolor(gs1)  color(gs1)  lp(solid))					///
				(scatter coef dist 				if (occupation == "P01" & outcome == "`outcome'"), mlc(gs11)    mfc(gs11)   m(O) msize(medsmall))		///
				(scatter coef dist 				if (occupation == "P03" & outcome == "`outcome'"), mlc(gs9)     mfc(gs9)    m(S) msize(medsmall))		///
				(scatter coef dist 				if (occupation == "P07" & outcome == "`outcome'"), mlc(gs6)     mfc(gs6)    m(D) msize(medsmall))		///
				(scatter coef dist 				if (occupation == "P09" & outcome == "`outcome'"), mlc(gs1)     mfc(gs1)    m(T) msize(medsmall)),		///
				xlabel(-2(1)4, nogrid labsize(small))	 																							 	///
				ylabel(`ylabel', angle(h) format(%10.3fc) labsize(small))																				///
				xline(-1, lcolor(gs10))																													///
				yline(0, lcolor(gs10))																													///
				xtitle("Years from graduation")																											///
				ytitle("Point estimate")																												///
				legend(order(	8 "Dentists" 	"Mean: `mean_P09'" 	7 "Physicians" "Mean: `mean_P07'"													///
								6 "Nurses" 		"Mean: `mean_P03'" 	5 "Bacteriologists" "Mean: `mean_P01'") position(6) col(4))							///
				graphregion(fcolor(white))																												
																				
			
		graph export "${figures}\Callaway SantAnna\ES_`outcome'_`gender'.pdf", replace
	
		restore
		
	}
	
}


****************************************************************************
**#						3. PILA
****************************************************************************
levelsof outcome if pila_outcome == 1, local(outcomes)
levelsof gender, local(genders)

*Tester
local outcomes = "pila_salario_r_0_npos" "pila_salario_r_0_posg"

foreach outcome in `outcomes' {
	
	if "`outcome'" == "pila_salario_r_0" | "`outcome'" == "pila_salario_r_0_np"  | "`outcome'" == "pila_salario_r_max_0" {		
		local d = "7.0"
		local e = "14.0"
	}
	else if "`outcome'" == "sal_dias_cot_0" | "`outcome'" == "sal_dias_cot_0_np" {	
		local d = "4.2"
		local e = "14.0" 
	}
	else {		
		local d = "4.3"
		local e = "7.2"
	}

	foreach gender in `genders'  {
		
		preserve	
		
		keep if gender == "`gender'"
							
		qui sum mean if (outcome =="`outcome'" & occupation =="P01")
		local mean_P01: dis %`d'fc r(mean)
		local mean_P01: dis strtrim("`mean_P01'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P03")
		local mean_P03: dis %`d'fc r(mean)
		local mean_P03: dis strtrim("`mean_P03'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P07")
		local mean_P07: dis %`d'fc r(mean)
		local mean_P07: dis strtrim("`mean_P07'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P09")
		local mean_P09: dis %`d'fc r(mean)
		local mean_P09: dis strtrim("`mean_P09'")
		
		qui sum min if (outcome =="`outcome'")
		local min = r(mean)
		qui sum max if (outcome =="`outcome'")
		local max = r(mean)
		qui sum change if (outcome =="`outcome'")
		local change = r(mean)
		
		if gender == "male" | gender == "female" {
			local ylabel = "`min'(`change')`max'"
			local yscale = "yscale(range(`min' `max'))"
		}
		else {			
			local ylabel = "#10"	
			local yscale = ""
		}			
			
		twoway 	(rspike ci_lower ci_upper dist 	if (occupation == "P01" & outcome == "`outcome'"), lcolor(gs11) color(gs11) lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P03" & outcome == "`outcome'"), lcolor(gs9)  color(gs9)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P07" & outcome == "`outcome'"), lcolor(gs6)  color(gs6)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P09" & outcome == "`outcome'"), lcolor(gs1)  color(gs1)  lp(solid))					///
				(scatter coef dist 				if (occupation == "P01" & outcome == "`outcome'"), mlc(gs11)    mfc(gs11)   m(O) msize(small))			///
				(scatter coef dist 				if (occupation == "P03" & outcome == "`outcome'"), mlc(gs9)     mfc(gs9)    m(S) msize(small))			///
				(scatter coef dist 				if (occupation == "P07" & outcome == "`outcome'"), mlc(gs6)     mfc(gs6)    m(D) msize(small))			///
				(scatter coef dist 				if (occupation == "P09" & outcome == "`outcome'"), mlc(gs1)     mfc(gs1)    m(T) msize(small)),			///
				xlabel(-4(1)9, nogrid labsize(vsmall))																									///
				ylabel(`ylabel', angle(h) format(%`e'fc) labsize(small)) `yscale'																		///
				xline(-1, lcolor(gs10))																													///
				yline(0, lcolor(gs10))																													///
				xtitle("Semesters from graduation")																										///
				ytitle("Point estimate")																												///
				legend(order(	8 "Dentists" 	"Mean: `mean_P09'" 	7 "Physicians" "Mean: `mean_P07'"													///
								6 "Nurses" 		"Mean: `mean_P03'" 	5 "Bacteriologists" "Mean: `mean_P01'") position(6) col(4))							///
				graphregion(fcolor(white)) graphr(margin(t+5))
				
		graph export "${figures}\Callaway SantAnna\ES_`outcome'_`gender'.pdf", replace
		
		restore
		
	}	
	
}


*Postgraduates
levelsof gender, local(genders)
* "posgrado_salud" "pila_salario_r_0_posg" "pila_salario_r_0_npos"
local outcomes = "posgrado_salud pila_salario_r_0_posg pila_salario_r_0_npos"

foreach outcome in `outcomes' {

	if "`outcome'" == "pila_salario_r_0_posg" | "`outcome'" == "pila_salario_r_0_npos" {		
		local d = "7.0"
		local e = "14.0"
	}
	else {		
		local d = "1.0"
		local e = "7.2"
	}
				
	foreach gender in `genders'  {
		
		preserve	
		
		keep if gender == "`gender'"
							
		qui sum mean if (outcome =="`outcome'" & occupation =="P07")
		local mean_P07: dis %`d'fc r(mean)
		local mean_P07: dis strtrim("`mean_P07'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P09")
		local mean_P09: dis %`d'fc r(mean)
		local mean_P09: dis strtrim("`mean_P09'")
		
		qui sum min if (outcome =="`outcome'")
		local min = r(mean)
		qui sum max if (outcome =="`outcome'")
		local max = r(mean)
		qui sum change if (outcome =="`outcome'")
		local change = r(mean)
		
		if gender == "male" | gender == "female" {
			local ylabel = "`min'(`change')`max'"
			local yscale = "yscale(range(`min' `max'))"
		}
		else {			
			local ylabel = "#10"	
			local yscale = ""
		}			
			
		twoway 	(rspike ci_lower ci_upper dist 	if (occupation == "P07" & outcome == "`outcome'"), lcolor(gs6)  color(gs6)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P09" & outcome == "`outcome'"), lcolor(gs1)  color(gs1)  lp(solid))					///
				(scatter coef dist 				if (occupation == "P07" & outcome == "`outcome'"), mlc(gs6)     mfc(gs6)    m(D) msize(small))			///
				(scatter coef dist 				if (occupation == "P09" & outcome == "`outcome'"), mlc(gs1)     mfc(gs1)    m(T) msize(small)),			///
				xlabel(-4(1)9, nogrid labsize(vsmall))																									///
				ylabel(`ylabel', angle(h) format(%`e'fc) labsize(small)) `yscale'																		///
				xline(-1, lcolor(gs10))																													///
				yline(0, lcolor(gs10))																													///
				xtitle("Semesters from graduation")																										///
				ytitle("Point estimate")																												///
				legend(order(4 "Dentists" 	"Mean: `mean_P09'" 	3 "Physicians" "Mean: `mean_P07'") position(6) col(4))									///
				graphregion(fcolor(white)) graphr(margin(t+5))
				
		graph export "${figures}\Callaway SantAnna\ES_`outcome'_`gender'.pdf", replace
		
		restore
		
	}	
	
}


****************************************************************************
**#						4. Mean difference test
****************************************************************************

drop if gender == "all"

keep coef outcome occupation gender pila_outcome dist2 mean stderr
reshape wide coef mean stderr, i(outcome occupation pila_outcome dist2) j(gender) string

rename coefmale x_m
rename coeffemale x_f
rename meanmale m_m
rename meanfemale m_f
rename stderrmale e_m
rename stderrfemale e_f

gen mean = m_m-m_f
gen coef = x_m-x_f
gen sed  = sqrt((e_m^2)+(e_f^2))

gen ci_lower = coef - 1.96*sed
gen ci_upper = coef + 1.96*sed

drop x_m x_f m_m m_f e_m e_f
rename dist2 dist

gen dist1 = dist - 0.1 		if (occupation == "P03" & pila_outcome == 0)
replace dist1 = dist - 0.2 	if (occupation == "P07" & pila_outcome == 0)
replace dist1 = dist - 0.3	if (occupation == "P09" & pila_outcome == 0)
replace dist1 = dist 		if (occupation == "P01" & pila_outcome == 0)

replace dist1 = dist1 + 0.3 if (occupation == "P03" & dist == -2 & pila_outcome == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P07" & dist == -2 & pila_outcome == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P09" & dist == -2 & pila_outcome == 0)
replace dist1 = dist1 + 0.3 if (occupation == "P01" & dist == -2 & pila_outcome == 0)

replace dist1 = dist - 0.15 	if (occupation == "P03" & pila_outcome == 1)
replace dist1 = dist - 0.30 	if (occupation == "P07" & pila_outcome == 1)
replace dist1 = dist - 0.45		if (occupation == "P09" & pila_outcome == 1)
replace dist1 = dist 			if (occupation == "P01" & pila_outcome == 1)

replace dist1 = dist1 + 0.45 	if (occupation == "P03" & dist <= -2 & pila_outcome == 1)
replace dist1 = dist1 + 0.45 	if (occupation == "P07" & dist <= -2 & pila_outcome == 1)
replace dist1 = dist1 + 0.45 	if (occupation == "P09" & dist <= -2 & pila_outcome == 1)
replace dist1 = dist1 + 0.45 	if (occupation == "P01" & dist <= -2 & pila_outcome == 1)

drop dist
rename dist1 dist


****************************************************************************
**#						4.1. RIPS
****************************************************************************
		
levelsof outcome if pila_outcome == 0, local(outcomes)

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
				xlabel(-2(1)4, nogrid labsize(small))	 																							 	///
				ylabel(#10, angle(h) format(%9.3fc) labsize(small))																						///
				xline(-1, lcolor(gs10))																													///
				yline(0, lcolor(gs10))																													///
				xtitle("Years from graduation")																											///
				ytitle("Point estimate")																												///
				legend(order(	8 "Dentists" 	"Mean: `mean_P09'" 	7 "Physicians" "Mean: `mean_P07'"													///
								6 "Nurses" 		"Mean: `mean_P03'" 	5 "Bacteriologists" "Mean: `mean_P01'") position(6) col(4))							///
				graphregion(fcolor(white))																												
																				
			
		graph export "${figures}\Callaway SantAnna\ES_`outcome'_gap.pdf", replace
	
}
	

****************************************************************************
**#						4.2. PILA
****************************************************************************	

levelsof outcome if pila_outcome == 1, local(outcomes)

*Tester
*local outcomes = "pila_salario_r_max_0"

foreach outcome in `outcomes' {
	
	if "`outcome'" == "pila_salario_r_0" | "`outcome'" == "pila_salario_r_0_np" | "`outcome'" == "pila_salario_r_max_0" {		
		local d = "7.0"	
		local e = "12.0"
	} 
	else if "`outcome'" == "sal_dias_cot_0" | "`outcome'" == "sal_dias_cot_0_np" {	
		local d = "4.2"
		local e = "14.0"
	}
	else {		
		local d = "5.3"	
		local e = "5.2"	
	}
					
		qui sum mean if (outcome =="`outcome'" & occupation =="P01")
		local mean_P01: dis %`d'fc r(mean)
		local mean_P01: dis strtrim("`mean_P01'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P03")
		local mean_P03: dis %`d'fc r(mean)
		local mean_P03: dis strtrim("`mean_P03'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P07")
		local mean_P07: dis %`d'fc r(mean)
		local mean_P07: dis strtrim("`mean_P07'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P09")
		local mean_P09: dis %`d'fc r(mean)
		local mean_P09: dis strtrim("`mean_P09'")
			
		twoway 	(rspike ci_lower ci_upper dist 	if (occupation == "P01" & outcome == "`outcome'"), lcolor(gs11) color(gs11) lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P03" & outcome == "`outcome'"), lcolor(gs9)  color(gs9)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P07" & outcome == "`outcome'"), lcolor(gs6)  color(gs6)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P09" & outcome == "`outcome'"), lcolor(gs1)  color(gs1)  lp(solid))					///
				(scatter coef dist 				if (occupation == "P01" & outcome == "`outcome'"), mlc(gs11)    mfc(gs11)   m(O) msize(small))			///
				(scatter coef dist 				if (occupation == "P03" & outcome == "`outcome'"), mlc(gs9)     mfc(gs9)    m(S) msize(small))			///
				(scatter coef dist 				if (occupation == "P07" & outcome == "`outcome'"), mlc(gs6)     mfc(gs6)    m(D) msize(small))			///
				(scatter coef dist 				if (occupation == "P09" & outcome == "`outcome'"), mlc(gs1)     mfc(gs1)    m(T) msize(small)),			///
				xlabel(-4(1)9, nogrid labsize(vsmall))																									///
				ylabel(#10, angle(h) format(%`e'fc) labsize(small))																						///
				xline(-1, lcolor(gs10))																													///
				yline(0, lcolor(gs10))																													///
				xtitle("Semesters from graduation")																										///
				ytitle("Point estimate")																												///
				legend(order(	8 "Dentists" 	"Mean: `mean_P09'" 	7 "Physicians" "Mean: `mean_P07'"													///
								6 "Nurses" 		"Mean: `mean_P03'" 	5 "Bacteriologists" "Mean: `mean_P01'") position(6) col(4))							///
				graphregion(fcolor(white))																												
				
		graph export "${figures}\Callaway SantAnna\ES_`outcome'_gap.pdf", replace
		
}	
	

* Postgraduates
local outcomes = "posgrado_salud pila_salario_r_0_posg pila_salario_r_0_npos"

foreach outcome in `outcomes' {

	if "`outcome'" == "pila_salario_r_0_posg" | "`outcome'" == "pila_salario_r_0_npos" {		
		local d = "7.0"
		local e = "14.0"
	}
	else {		
		local d = "1.0"
		local e = "5.2"
	}
	
		qui sum mean if (outcome =="`outcome'" & occupation =="P07")
		local mean_P07: dis %`d'fc r(mean)
		local mean_P07: dis strtrim("`mean_P07'")
		qui sum mean if (outcome =="`outcome'" & occupation =="P09")
		local mean_P09: dis %`d'fc r(mean)
		local mean_P09: dis strtrim("`mean_P09'")
			
		twoway 	(rspike ci_lower ci_upper dist 	if (occupation == "P07" & outcome == "`outcome'"), lcolor(gs6)  color(gs6)  lp(solid))					///
				(rspike ci_lower ci_upper dist 	if (occupation == "P09" & outcome == "`outcome'"), lcolor(gs1)  color(gs1)  lp(solid))					///
				(scatter coef dist 				if (occupation == "P07" & outcome == "`outcome'"), mlc(gs6)     mfc(gs6)    m(D) msize(small))			///
				(scatter coef dist 				if (occupation == "P09" & outcome == "`outcome'"), mlc(gs1)     mfc(gs1)    m(T) msize(small)),			///
				xlabel(-4(1)9, nogrid labsize(vsmall))																									///
				ylabel(#10, angle(h) format(%`e'fc) labsize(small))																						///
				xline(-1, lcolor(gs10))																													///
				yline(0, lcolor(gs10))																													///
				xtitle("Semesters from graduation")																										///
				ytitle("Point estimate")																												///
				legend(order(4 "Dentists" 	"Mean: `mean_P09'" 	3 "Physicians" "Mean: `mean_P07'") position(6) col(4))									///
				graphregion(fcolor(white))																												
				
		graph export "${figures}\Callaway SantAnna\ES_`outcome'_gap.pdf", replace
		
}


****************************************************************************
**#						5. Extra descriptives
****************************************************************************

use "${tables}\wage_ages", clear
rename edad dist
keep if dist >= 18 & dist <= 67

local outcomes sal_dias_cot_0 posgrado_salud pila_salario_r_0 l_pila_salario_r_0 		///
				p_cotizaciones_0 pila_independientes pila_salario_r_max_0
				
foreach outcome in `outcomes' {

	if "`outcome'" == "pila_salario_r_0" | "`outcome'" == "pila_salario_r_max_0" {		
		local e = "12.0"
	} 
	else if "`outcome'" == "sal_dias_cot_0" {	
		local e = "12.0"
	}
	else {		
		local e = "5.2"	
	}

	twoway 	(line `outcome' dist if (rethus_codigoperfilpre1 == "P01"), lc(gs11))		///
			(line `outcome' dist if (rethus_codigoperfilpre1 == "P03"), lc(gs9) )		///
			(line `outcome' dist if (rethus_codigoperfilpre1 == "P07"), lc(gs6) )		///
			(line `outcome' dist if (rethus_codigoperfilpre1 == "P09"), lc(gs1) ),		///
			xlabel(18(1)67, nogrid labsize(vsmall))	 						 			///
			ylabel(#10, angle(h) format(%`e'fc) labsize(small))							///
			xline(24, lcolor(gs10))														///
			xline(47, lcolor(gs10))														///
			xline(52, lcolor(gs10))														///
			xtitle("Age")																///
			ytitle("`outcome'")															///
			graphregion(fcolor(white))													///
			legend(order(	4 "Dentists" 	3 "Physicians"								///
							2 "Nurses" 		1 "Bacteriologists")						///
							position(6) col(4))
	
	graph export "${figures}\Old professionals\\`outcome'.png", replace

}


