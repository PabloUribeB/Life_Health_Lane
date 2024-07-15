/*************************************************************************
 *************************************************************************			       	
					Extra descriptives
			 
1) Created by: Pablo Uribe						Daniel Márquez
			   World Bank						Harvard Business School
			   puribebotero@worldbank.org		dmarquezm20@gmail.com	
				
2) Date: December 2023

3) Objective: 	Simplificate step 8 outputs to understand which are the
				most common diagnostics for each area of interest

4) Output:	- Three datasets
*************************************************************************
*************************************************************************/	


****************************************************************************
*Globals
****************************************************************************

if "`c(hostname)'" == "SM201439"{
	global data "C:\Proyectos\Banrep research\Returns to Health Sector\Data"
	global logs "C:\Proyectos\Banrep research\Returns to Health Sector\Logs"
	global tables "C:\Proyectos\Banrep research\Returns to Health Sector\Tables"
	global urgencias "C:\Proyectos\Banrep research\More_than_a_Healing\Data"
	global RETHUS "C:\Proyectos\Banrep research\f_ReturnsToEducation Health sector\Data"
}

else {
	global data "\\sm093119\Proyectos\Banrep research\Returns to Health Sector\Data"
	global tables "\\sm093119\Proyectos\Banrep research\Returns to Health Sector\Tables"
	global urgencias "\\sm093119\Proyectos\Banrep research\More_than_a_Healing\Data"
	global RETHUS "\\sm093119\Proyectos\Banrep research\f_ReturnsToEducation Health sector\Data"
	global logs "\\sm093119\Proyectos\Banrep research\Returns to Health Sector\Logs"

}

cap log close
log using "$logs\Step_8.smcl", replace
	

****************************************************************************
**#						1. Processing
****************************************************************************

use "$data\Merge_individual_RIPS.dta", clear

drop diag_prin_ingre fecha_ingreso cod_diag_prin fecha_consul

gen year_RIPS = yofd(date)

drop date

* Create variables by looping over diagnosis codes
local i = 1
foreach d in diag_prin diag_r1 diag_r2 diag_r3 {

	gen diag_mental_`i'	= (substr(substr(`d', 1, 3),1,1) == "F")
	
	gen depresion_`i' = (inlist(substr(`d',1,3),"F32","F33"))
	
	gen ansiedad_`i' = (inlist(substr(`d',1,3),"F40","F41"))

	gen estres_`i' = ((substr(`d',1,2)=="F3") 						///
	| (substr(`d',1,2)=="F4") | (substr(`d',1,4)=="Z563") 			///
	| (substr(`d',1,4)=="Z637") | (substr(`d',1,4)=="Z733"))

	local i = `i' + 1

}

foreach var in diag_mental depresion ansiedad estres {
	
	egen `var' = rowmax(`var'_1 `var'_2 `var'_3 `var'_4)	
	drop `var'_1 `var'_2 `var'_3 `var'_4
	
}

* Work-related afflictions and stress
gen cons_psico 			= 1 if substr(cod_consul,5,2)=="08" & service == "consultas"
replace cons_psico		= 0 if substr(cod_consul,5,2)!="08" & service == "consultas"

gen cons_trab_social 	= 1 if substr(cod_consul,5,2)=="09" & service == "consultas"
replace cons_trab_social= 0 if substr(cod_consul,5,2)!="09" & service == "consultas"

gen cons_psiquiatra 	= 1 if substr(cod_consul,5,2)=="84" & service == "consultas"
replace cons_psiquiatra = 0 if substr(cod_consul,5,2)!="84" & service == "consultas"

gen cons_mental 		= 1 if cons_psico == 1 | cons_psiquiatra == 1 | cons_trab_social == 1
replace cons_mental		= 0 if cons_psico != 1 & cons_psiquiatra != 1 & cons_trab_social != 1 & service == "consultas"

gen cons_general		= 1 if cons_mental == 0
replace cons_general	= 0 if cons_mental == 1

gen ansiedad_mental		= (ansiedad == 1 & cons_mental == 1)
gen estres_mental		= (estres == 1 & cons_mental == 1)
gen depresion_mental	= (depresion == 1 & cons_mental == 1)

gen ansiedad_gral		= (ansiedad == 1 & cons_mental == 0)
gen estres_gral			= (estres == 1 & cons_mental == 0)
gen depresion_gral		= (depresion == 1 & cons_mental == 0)

gen chapter = substr(diag_prin, 1, 1)

* Merge master rethus
compress
merge m:1 personabasicaid using "$data\master_rethus", keepusing(fechapregrado rethus_codigoperfilpre1) keep(3) nogen

gen half_grado = year(dofm(fechapregrado))
gen dist = year_RIPS - half_grado
keep if inrange(half_grado, 2011, 2017)


****************************************************************************
**#						2. Outputs
****************************************************************************

* Hospitalizacion y urgencias
preserve

	keep if inlist(service, "Hospitalizacion", "urgencias")
	
	collapse (count) personabasicaid, by(chapter diag_prin dist service rethus_codigoperfilpre1)
	gsort service rethus_codigoperfilpre1 dist -personabasicaid
	keep if inrange(dist, -2, 4)
	rename personabasicaid counter
	save "$tables\chapter_urg_hos.dta", replace

restore

*Diagnostico de enfermedades mentales
preserve

	keep if inlist(service, "consultas")
	keep if diag_mental == 1

	collapse (count) personabasicaid, by(chapter diag_prin dist service rethus_codigoperfilpre1)
	gsort service rethus_codigoperfilpre1 dist -personabasicaid
	keep if inrange(dist, -2, 4)
	rename personabasicaid counter
	save "$tables\chapter_diag_mental.dta", replace

restore

*Diagnostico con profesional de salud mental
preserve

	keep if inlist(service, "consultas")
	keep if cons_mental == 1

	collapse (count) personabasicaid, by(chapter diag_prin dist service rethus_codigoperfilpre1)
	gsort service rethus_codigoperfilpre1 dist -personabasicaid
	keep if inrange(dist, -2, 4)
	rename personabasicaid counter
	save "$tables\chapter_cons_mental.dta", replace

restore

log close








