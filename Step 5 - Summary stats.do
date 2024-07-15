/*************************************************************************
 *************************************************************************			       	
					Summary statistics
			 
1) Created by: Pablo Uribe						Daniel Márquez
			   World Bank						Harvard Business School
			   puribebotero@worldbank.org		dmarquezm20@gmail.com		
				
2) Date: December 2023

3) Objective: Calculate the summary statistics for our sample.
			  This do file can only be ran at BanRep's servers.

4) Output:	- hist_graduates_all.pdf
			- hist_graduates_sample.pdf
			- Descriptives.xls
*************************************************************************
*************************************************************************/	


****************************************************************************
*Required packages (uncomment if running for the first time)
****************************************************************************
*ssc install schemeplot, replace

****************************************************************************
*Globals and matrices rows and columns
****************************************************************************

* Working directory
if "`c(hostname)'" == "SM201439"{
	global pc "C:"
}

else {
	global pc "\\sm093119"
}

global logs 	"${pc}\Proyectos\Banrep research\Returns to Health Sector\Logs"
global data 	"${pc}\Proyectos\Banrep research\Returns to Health Sector\Data"
global tables 	"${pc}\Proyectos\Banrep research\Returns to Health Sector\Tables"
global figures 	"${pc}\Proyectos\Banrep research\Returns to Health Sector\Figures"

global data_rethus 	"${pc}\Proyectos\Banrep research\f_ReturnsToEducation Health sector\Data"

set scheme white_tableau

global rips_rows " "service" "consul" "proce" "urg_np" "hosp_np" "urg" "hosp" "service_mental" "service_mental2" "pregnancy" "Total" "

global pila_rows " "sal_dias_cot_0" "pila_salario_r_0" "l_pila_salario_r_0" "nro_cotizaciones_0" "formal" "posgrado_salud"  "posgrado_rethus" "posgrado_rethus_acum" "p_cotizaciones_0" "pila_independientes" "pila_dependientes" "edad" "Total" "

global columns " "Mean_all" "SD_all" "Min_all" "Max_all" "Mean_male" "SD_male" "Min_male" "Max_male" "Mean_female" "SD_female" "Min_female" "Max_female" "

global ocupaciones Bact Nurse Phys Dent


local rips_row : list sizeof global(rips_rows) // Count number of outcomes for # rows
local pila_row : list sizeof global(pila_rows) // Count number of outcomes for # rows
local column   : list sizeof global(columns)   // Count number of outcomes for # rows

cap log close
log using "${pc}\Proyectos\Banrep research\Returns to Health Sector\Logs\Step_5.smcl", replace


****************************************************************************
**#						1. RETHUS
****************************************************************************

use "${data}\master_rethus.dta", clear

gen profesionales = 1
mat define 		table1	= J(5,6,.)
mat colnames 	table1	= "N" "Percent" "N male" "Percent male" "N female" "Percent female"
mat rownames 	table1	= "All" "Bacteriologist" "Nurse" "Physician" "Dentist"

	
* All
keep if inrange(year_grado, 2011, 2017)
drop if (rethus_sexo != 1 & rethus_sexo != 2)

sum profesionales
mat table1[1,1] = r(N)
mat table1[1,2] = table1[1,1] / table1[1,1]

sum profesionales if rethus_sexo == 1
mat table1[1,3] = r(N)
mat table1[1,4] = table1[1,3] / table1[1,1]

sum profesionales if rethus_sexo == 2
mat table1[1,5] = r(N)
mat table1[1,6] = table1[1,5] / table1[1,1]


count
local rethus: dis %10.0fc r(N)

texresults3 using "${tables}\numbers.txt", texmacro(samplerethus) 			///
result(`rethus') replace // Only for internal use. Comment for publication.

replace rethus_codigoperfilpre1 = "Bact" 	if rethus_codigoperfilpre1 == "P01"
replace rethus_codigoperfilpre1 = "Phys" 	if rethus_codigoperfilpre1 == "P07"
replace rethus_codigoperfilpre1 = "Nurse" 	if rethus_codigoperfilpre1 == "P03"
replace rethus_codigoperfilpre1 = "Dent" 	if rethus_codigoperfilpre1 == "P09"


local f = 2
foreach ocupacion in $ocupaciones {
	
	sum profesionales if (rethus_codigoperfilpre1 == "`ocupacion'")
	mat table1[`f',1] = r(N)
	mat table1[`f',2] = table1[`f',1] / table1[1,1]
	
	local mean 		  = table1[`f',2] * 100
	texresults3 using "${tables}\numbers.txt", texmacro(mean`ocupacion') 	///
	result(`mean') round(0) unit append // Only for internal use. Comment for publication.
	
	local ++f
	
}

* Males
local f = 2
foreach ocupacion in $ocupaciones {
	
	sum profesionales if (rethus_codigoperfilpre1 == "`ocupacion'" & rethus_sexo == 1)
	mat table1[`f',3] = r(N)
	mat table1[`f',4] = table1[`f',3] / table1[1,1]
	
	local ++f
	
}

* Females
local f = 2
foreach ocupacion in $ocupaciones {
	
	sum profesionales if (rethus_codigoperfilpre1 == "`ocupacion'" & rethus_sexo == 2)
	mat table1[`f',5] = r(N)
	mat table1[`f',6] = table1[`f',5] / table1[1,1]

	local ++f
	
}
	
matlist table1
putexcel set "$tables\Descriptives.xls", sheet("Rethus", replace) modify
putexcel B2=mat(table1), names

* Graduates per year
tw 	hist year_grado, freq disc xlab(2011(1)2017) barw(0.5) fcolor(gs13) ///
lcolor(gs11) xtitle("Year of graduation") ylabel(#10,format(%12.0fc))
graph export "${figures}\hist_graduates_sample.pdf", replace
	
* Graduates per half
replace fechapregrado = hofd(dofm(fechapregrado))
format fechapregrado %th

tw 	hist fechapregrado, freq disc xlab(102(1)115) barw(0.5) fcolor(gs13) ///
lcolor(gs11) xtitle("Semester of graduation") ylabel(#10,format(%12.0fc)) xlab(, angle(45))
graph export "${figures}\hist_graduates_sample_half.pdf", replace	
	
	

****************************************************************************
**#						2. RIPS
****************************************************************************

use "${data}\Individual_balanced_all_RIPS.dta", clear
keep if (year_grado >= 2011 & year_grado <= 2017)
drop if (rethus_sexo != 1 & rethus_sexo != 2)

rename 	(urg_np hosp_np service_mental service_mental2) ///
		(urgnp hospnp mentaldiag mentalEAD)

global d_outcomes 	service consul proce urgnp hospnp urg hosp 	///
					mentaldiag mentalEAD pregnancy

mat define 		RIPS = J(`rips_row', `column', .)
mat colnames 	RIPS = $columns
mat rownames 	RIPS = $rips_rows	
				
* All sample
preserve

	collapse (max) $d_outcomes , by(personabasicaid)

	local f = 1
	foreach outcome in $d_outcomes {
		
		qui sum `outcome'
		mat RIPS[`f',1] = r(mean)
		mat RIPS[`f',2] = r(sd)
		mat RIPS[`f',3] = r(min)
		mat RIPS[`f',4] = r(max)
		
		local mean 		= RIPS[`f',1] * 100
		texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome') 	///
		result(`mean') round(0) unit append // Only for internal use. Comment for publication.
		
		local ++f
		
	}

	qui sum personabasicaid, det
	mat RIPS[11,1] = r(N)

restore

* * Males
preserve

	collapse (max) $d_outcomes , by(personabasicaid rethus_sexo)

	local f = 1
	foreach outcome in $d_outcomes {
		
		qui sum `outcome' if rethus_sexo == 1
		mat RIPS[`f',5] = r(mean)
		mat RIPS[`f',6] = r(sd)
		mat RIPS[`f',7] = r(min)
		mat RIPS[`f',8] = r(max)
		
		local mean 		= RIPS[`f',5] * 100
		texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome'M) 	///
		result(`mean') round(0) unit append // Only for internal use. Comment for publication.
		local ++f
		
	}

	qui sum personabasicaid if rethus_sexo == 1, det
	mat RIPS[11,5] = r(N)

restore

* Females
preserve

	collapse (max) $d_outcomes , by(personabasicaid rethus_sexo)

	local f = 1
	foreach outcome in $d_outcomes {
		
		qui sum `outcome' if rethus_sexo == 2
		mat RIPS[`f',9]  = r(mean)
		mat RIPS[`f',10] = r(sd)
		mat RIPS[`f',11] = r(min)
		mat RIPS[`f',12] = r(max)
		
		local mean 		= RIPS[`f',9] * 100
		texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome'F) 	///
		result(`mean') round(0) unit append // Only for internal use. Comment for publication.
		local ++f
		
	}

	qui sum personabasicaid if rethus_sexo == 2, det
	mat RIPS[11,9] = r(N)

restore

matlist RIPS
putexcel set "$tables\Descriptives.xls", sheet("RIPS", replace) modify
putexcel B2=mat(RIPS), names
	
	
****************************************************************************
**#						3. PILA
****************************************************************************

use "${data}\Individual_balanced_all_PILA.dta", clear
drop if (rethus_sexo != 1 & rethus_sexo != 2)
sort personabasicaid fecha_pila

replace rethus_codigoperfilpre1 = "Bact" 	if rethus_codigoperfilpre1 == "P01"
replace rethus_codigoperfilpre1 = "Phys" 	if rethus_codigoperfilpre1 == "P07"
replace rethus_codigoperfilpre1 = "Nurse" 	if rethus_codigoperfilpre1 == "P03"
replace rethus_codigoperfilpre1 = "Dent" 	if rethus_codigoperfilpre1 == "P09"

drop year
gen year = year(dofh(fecha_pila))

keep if year == 2021

** For internal use (comment for publication)
	qui sum pila_salario_r_0 if (rethus_codigoperfilpre1 == "Phys" & posgrado_rethus == 1)

	qui sum pila_salario_r_0 if (rethus_codigoperfilpre1 == "Phys" & posgrado_clin == 1)
	local mean: dis %15.0fc r(mean)
	dis as err "Physician with clinical: `mean'"

	qui sum pila_salario_r_0 if (rethus_codigoperfilpre1 == "Phys" & posgrado_quir == 1)
	local mean: dis %15.0fc r(mean)
	dis as err "Physician with surgical: `mean'"

	qui sum pila_salario_r_0 if (rethus_codigoperfilpre1 == "Phys" & posgrado_otro == 1)
	local mean: dis %15.0fc r(mean)
	dis as err "Physician with others: `mean'"

	* Dentist with postgrad.
	qui sum pila_salario_r_0 if (rethus_codigoperfilpre1 == "Dent" & posgrado_rethus_acum == 1)
	local mean: dis %15.0fc r(mean)
	dis as err "Dentist with postgrad: `mean'"

** End of internal use


* Subset
use if (year_grado >= 2011 & year_grado <= 2017) & (rethus_sexo == 1 | rethus_sexo == 2) ///
	using "${data}\Individual_balanced_all_PILA.dta", clear

sort personabasicaid fecha_pila

rename 	(sal_dias_cot_0 pila_salario_r_0 l_pila_salario_r_0 nro_cotizaciones_0) ///
		(daysworked wage logwage numberjobs)

global c_outcomes 	daysworked wage logwage numberjobs formal

rename 	(posgrado_salud posgrado_rethus posgrado_rethus_acum p_cotizaciones_0 	///
		pila_independientes pila_dependientes)									///
		(postgrad postrethus postaccum simuljobs selfemploy dependent)
		
global d_outcomes 	postgrad postrethus postaccum simuljobs selfemploy dependent edad

					
mat define 		PILA = J(`pila_row', `column', .)
mat colnames 	PILA = $columns
mat rownames 	PILA = $pila_rows

* All sample
preserve

	collapse (mean) $c_outcomes (max) $d_outcomes , by(personabasicaid)

	local f = 1
	foreach outcome in $c_outcomes $d_outcomes {

		if inlist("`outcome'", "wage", "logwage"){
			local maxim "r(max)"
			local calcu ": display %11.0fc PILA[`f',1]"
		}
		else if inlist("`outcome'", "daysworked", "numberjobs", "edad"){
			local maxim "r(max)"
			local calcu ": display %5.2fc PILA[`f',1]"
		}
		else{
			local maxim "r(max)"
			local calcu "= PILA[`f',1] * 100"
		}

		qui sum `outcome', det
		mat PILA[`f',1] = r(mean)
		mat PILA[`f',2] = r(sd)
		mat PILA[`f',3] = r(min)
		mat PILA[`f',4] = `maxim'
		
		local mean `calcu'
		texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome') 	///
		result(`mean') round(0) unit append // Only for internal use. Comment for publication.
		local ++f
		
	}
		
	qui sum personabasicaid, det
	mat PILA[13,1] = r(N)

restore

* Male
preserve

	collapse (mean) $c_outcomes (max) $d_outcomes , by(personabasicaid rethus_sexo)

	local f = 1
	foreach outcome in $c_outcomes $d_outcomes {

		if inlist("`outcome'", "wage", "logwage"){
			local maxim "r(max)"
			local calcu ": display %11.0fc PILA[`f',5]"
		}
		else if inlist("`outcome'", "daysworked", "numberjobs", "edad"){
			local maxim "r(max)"
			local calcu ": display %5.2fc PILA[`f',5]"
		}
		else{
			local maxim "r(max)"
			local calcu "= PILA[`f',5] * 100"
		}

		qui sum `outcome' if rethus_sexo == 1, det
		mat PILA[`f',5] = r(mean)
		mat PILA[`f',6] = r(sd)
		mat PILA[`f',7] = r(min)
		mat PILA[`f',8] = `maxim'
		
		local mean `calcu'
		texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome'M) 	///
		result(`mean') round(0) unit append // Only for internal use. Comment for publication.
		local ++f
		
	}
		
	qui sum personabasicaid, det
	mat PILA[13,5] = r(N)

restore

* Female
preserve

	collapse (mean) $c_outcomes (max) $d_outcomes , by(personabasicaid rethus_sexo)

	local f = 1
	foreach outcome in $c_outcomes $d_outcomes {

		if inlist("`outcome'", "wage", "logwage"){
			local maxim "r(max)"
			local calcu ": display %11.0fc PILA[`f',9]"
		}
		else if inlist("`outcome'", "daysworked", "numberjobs", "edad"){
			local maxim "r(max)"
			local calcu ": display %5.2fc PILA[`f',9]"
		}
		else{
			local maxim "r(max)"
			local calcu "= PILA[`f',9] * 100"
		}

		qui sum `outcome' if rethus_sexo == 2, det
		mat PILA[`f',9]  = r(mean)
		mat PILA[`f',10] = r(sd)
		mat PILA[`f',11] = r(min)
		mat PILA[`f',12] = `maxim'
		
		local mean `calcu'
		texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome'F) 	///
		result(`mean') round(0) unit append // Only for internal use. Comment for publication.
		local ++f
		
	}
		
	qui sum personabasicaid, det
	mat PILA[13,9] = r(N)

restore

matlist PILA
putexcel set "${tables}\Descriptives.xls", sheet("PILA", replace) modify
putexcel B2=mat(PILA), names


****************************************************************************
**#						3.1. Wage by ranges
****************************************************************************
use "${data}\Individual_balanced_all_PILA.dta", clear
keep if (year_grado >= 2011 & year_grado <= 2017)
drop if (rethus_sexo != 1 & rethus_sexo != 2)

* Minimum wage per year
gen     mw = 461500  if (year == 2008)
replace mw = 496900  if (year == 2009)
replace mw = 515000  if (year == 2010)
replace mw = 535600  if (year == 2011)
replace mw = 566700  if (year == 2012)
replace mw = 589500  if (year == 2013)
replace mw = 616000  if (year == 2014)
replace mw = 644350  if (year == 2015)
replace mw = 689455  if (year == 2016)
replace mw = 737717  if (year == 2017)
replace mw = 781242  if (year == 2018)
replace mw = 828116  if (year == 2019)
replace mw = 877803  if (year == 2020)
replace mw = 908526  if (year == 2021)
replace mw = 1000000 if (year == 2022)

preserve

	g graduates = 1

	g w_range = .
	replace w_range = 1 if (pila_salario_r_0 <= mw)
	replace w_range = 2 if (pila_salario_r_0 >  mw			& pila_salario_r_0 <= (mw * 2))
	replace w_range = 3 if (pila_salario_r_0 > (mw * 2) 	& pila_salario_r_0 <= (mw * 3))
	replace w_range = 4 if (pila_salario_r_0 > (mw * 3)  	& pila_salario_r_0 <= (mw * 5))
	replace w_range = 5 if (pila_salario_r_0 > (mw * 5))
	
	collapse (sum) graduates, by(rethus_codigoperfilpre1 fecha_pila w_range)
	format fecha_pila %th
	save "${tables}\wage_ranges", replace
	export excel using "${tables}\wage_ranges.xlsx", firstrow(variables) sheet("All") sheetreplace

restore


* Count people by salary range
gen w_range_1 = (pila_salario_r_0 <= mw)
gen w_range_2 = (pila_salario_r_0 >  mw		& pila_salario_r_0 <= (mw * 2))
gen w_range_3 = (pila_salario_r_0 > (mw * 2)  & pila_salario_r_0 <= (mw * 3))
gen w_range_4 = (pila_salario_r_0 > (mw * 3)  & pila_salario_r_0 <= (mw * 5))
gen w_range_5 = (pila_salario_r_0 > (mw * 5))

collapse (sum) w_range*, by(rethus_codigoperfilpre1 fecha_pila)
sort fecha_pila
order fecha_pila
save "${tables}\wage_ranges", replace
export excel using "${tables}\wage_ranges.xlsx", firstrow(variables) sheet("All") sheetreplace


****************************************************************************
**#						3.2. Age descriptives
****************************************************************************

* Age at the graduation figure
use "${data}\Individual_balanced_all_PILA.dta", clear
drop if (rethus_sexo != 1 & rethus_sexo != 2)

collapse (max) edad, by(year_grado rethus_codigoperfilpre1)

tw 	(connected edad year_grado if rethus_codigoperfilpre1 == "P01", color(gs11)   m(O) msize(medsmall))			///
	(connected edad year_grado if rethus_codigoperfilpre1 == "P03", color(gs9)    m(S) msize(medsmall))			///
	(connected edad year_grado if rethus_codigoperfilpre1 == "P07", color(gs6)    m(D) msize(medsmall))			///
	(connected edad year_grado if rethus_codigoperfilpre1 == "P09", color(gs1)    m(T) msize(medsmall)),		///
	xtitle(Year) ytitle(Age at graduation date)	ylab(#10) xlab(2011(1)2017)										///
	legend(order(4 "Dentists" 3 "Physicians" 2 "Nurses" 1 "Bacteriologists") position(6) col(4))				///
	graphregion(fcolor(white))
	
graph export "${figures}\Age_at_graddate.pdf", replace	

* Outcomes by age
use "${data}\Individual_balanced_all_PILA.dta", clear
drop if (rethus_sexo != 1 & rethus_sexo != 2)

global outcomes sal_dias_cot_0 posgrado_salud pila_salario_r_0 l_pila_salario_r_0 			///
				p_cotizaciones_0 pila_independientes pila_salario_r_max_0

collapse (mean) ${outcomes}, by(edad rethus_codigoperfilpre1)
save "${tables}\wage_ages", replace


****************************************************************************
**#						3.3. Additional descriptives
****************************************************************************
/*
* Number of professionals in 2021
use "${data}\Individual_balanced_all_PILA.dta", clear
drop if (rethus_sexo != 1 & rethus_sexo != 2)

drop year
g year = year(dofh(fecha_pila))
keep if year == 2021

keep personabasicaid year rethus_codigoperfilpre1
gduplicates drop

foreach ocupacion in P01 P03 P07 P09 {
	
	count if rethus_codigoperfilpre1 == "`ocupacion'"
	
}


* Professionals with only 1 undergraduate degree in our sample
use  using "${data_rethus}\RETHUS_procesada.dta", clear
drop if (rethus_sexo != 1 & rethus_sexo != 2)

gen year_grado = year(dofm(fechapregrado))
keep if inrange(year_grado, 2011, 2017) & substr(rethus_codigoperfilpre1,1,1) == "P"

g one_degree = mi(rethus_codigoperfilpre2)
g ocupacion  = (rethus_codigoperfilpre1 == "P01" | rethus_codigoperfilpre1 == "P03" | ///
				rethus_codigoperfilpre1 == "P07" | rethus_codigoperfilpre1 == "P09" )
g main_sample = one_degree*ocupacion
sum main_sample


* Professionals with only 1 undergraduate degree in total
use  using "${data_rethus}\RETHUS_procesada.dta", clear
drop if (rethus_sexo != 1 & rethus_sexo != 2)

gen year_grado = year(dofm(fechapregrado))
keep if year_grado > 1980 & substr(rethus_codigoperfilpre1,1,1) == "P"

g one_degree = mi(rethus_codigoperfilpre2)
g ocupacion  = (rethus_codigoperfilpre1 == "P01" | rethus_codigoperfilpre1 == "P03" | ///
				rethus_codigoperfilpre1 == "P07" | rethus_codigoperfilpre1 == "P09" )
g main_sample = one_degree*ocupacion
sum main_sample
*/

log close
