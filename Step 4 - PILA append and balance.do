/*************************************************************************
 *************************************************************************			       	
	        PILA balancing and appending
			 
1) Created by: Pablo Uribe						Daniel Márquez
			   World Bank						Harvard Business School
			   puribebotero@worldbank.org		dmarquezm20@gmail.com
				
2) Date: December 2023

3) Objective: Balance the PILA panel at a semiannual level and append the 
			  four occupations together.
			  This do file can only be ran at BanRep's servers.

4) Output:	- Individual_balanced_all_PILA.dta
*************************************************************************
*************************************************************************/	


****************************************************************************
*Required packages (uncomment if running for the first time)
****************************************************************************
*ssc install ereplace, replace

****************************************************************************
*Globals
****************************************************************************

* Working directory
if "`c(hostname)'" == "SM201439"{
	global pc "C:"
}

else {
	global pc "\\sm093119"
}

global data 		"${pc}\Proyectos\Banrep research\Returns to Health Sector\Data"

cap log close
log using "${pc}\Proyectos\Banrep research\Returns to Health Sector\Logs\Step_4.smcl", replace


****************************************************************************
**#				1. Process each occupation's dataset
****************************************************************************

global profesiones P01 P03 P07 P09

foreach ocupacion in $profesiones {
	
	* Balancing with rethus sample
	use personabasicaid fechapregrado rethus_codigoperfilpre1 rethus_sexo if rethus_codigoperfilpre1 == "`ocupacion'" using "${data}\master_rethus", clear
	drop rethus_codigoperfilpre1
	
	* Balancear panel
	bys personabasicaid: egen temp = min(fechapregrado)
	drop if temp == .

	expand 176 // 176 months between 2008 and 2022m8
	bys personabasicaid: gen fecha_pila = _n + 575
	format fecha_pila %tm

	merge 1:1 personabasicaid fecha_pila using "${data}\\`ocupacion'_PILA_monthly", keep(1 3)
	
	gen formal = (_merge == 3)
	drop _merge
	replace pila_dependientes 	= 0 if mi(pila_dependientes)
	replace pila_independientes = 0 if mi(pila_independientes)

	bys personabasicaid: ereplace fechapregrado = max(fechapregrado)
	drop if mi(fechapregrado)
	replace year_grado = year(dofm(fechapregrado))
	
	* Additional outcomes
	gen 	posgrado_salud 			= (tipo_cotiz == 21)
	replace posgrado_salud 			= 0 if (fecha_pila < fechapregrado)
	
	gen 	month_posgrado 			= mofd(rethus_fechagradopos1)			
	gen 	posgrado_rethus 		= 0
	replace posgrado_rethus 		= 1  if (month_posgrado == fecha_pila)
	
	replace rethus_perfilpos1		= "" if (month_posgrado > fecha_pila)
	replace rethus_codigoperfilpos1 = "" if (month_posgrado > fecha_pila)
	
	gen auxiliar 	  = substr(rethus_perfilpos1, 1, 1)
	gen posgrado_clin = 1 if auxiliar == "M" & rethus_codigoperfilpre1 == "P07" & rethus_codigoperfilpos1 != "MA99"
	gen posgrado_quir = 1 if auxiliar == "Q" & rethus_codigoperfilpre1 == "P07"
	gen posgrado_otro = 1 if posgrado_clin != 1 & posgrado_quir != 1 & !mi(rethus_perfilpos1)
	drop auxiliar
	
	gen 	posgrado_rethus_acum 	= 0
	replace posgrado_rethus_acum 	= 1 if (fecha_pila >= month_posgrado)
	
	gen 	pila_salario_r_0 		= pila_salario_r
	replace pila_salario_r_0 		= 0 if mi(pila_salario_r)
	
	gen 	pila_salario_r_max_0 	= pila_salario_max_r
	replace pila_salario_r_max_0	= 0 if mi(pila_salario_max_r)	
	
	gen 	sal_dias_cot_0 			= sal_dias_cot
	replace sal_dias_cot_0			= 0 if mi(sal_dias_cot)
	
	gen 	nro_cotizaciones_0 		= nro_cotizaciones
	replace nro_cotizaciones_0		= 0 if mi(nro_cotizaciones)	
	
	* Semiannualize
	replace fecha_pila 				= hofd(dofm(fecha_pila))
	replace fechapregrado 			= hofd(dofm(fechapregrado))
	
	format fecha_pila %th
	format fechapregrado %th
	
	* Birth
	bys personabasicaid: egen birth = mode(fechantomode), minmode missing
	
	collapse 	(median) sal_dias_cot_0 pila_salario_r_0 pila_salario_r_max_0					///				
				(max) nro_cotizaciones_0 formal	incap_dias incap_gral licen_mat					///
				posgrado_salud posgrado_rethus posgrado_rethus_acum posgrado_clin				///
				posgrado_quir posgrado_otro pila_independientes pila_dependientes 				///
				(min) birth,																	///
				by(personabasicaid fecha_pila fechapregrado year_grado rethus_sexo)
	
	* Last variables
	gen 	l_pila_salario_r_0 		= log(pila_salario_r_0)
	gen 	posgrado_salud_term 	= posgrado_salud
	gen		p_cotizaciones_0		= (nro_cotizaciones_0 > 1)
	
	* Age at the graduation date
	gen		year_pila				= yofd(dofh(fecha_pila))
	gen 	year_birth 				= yofd(birth)
	gen		edad					= fecha_pila - birth
	replace	edad					= . if (year_grado != year_pila)
	
	bys personabasicaid: ereplace edad = min(edad)
	drop year_pila year_birth
	
	* Identify occupation
	gen 	rethus_codigoperfilpre1 = "`ocupacion'"

	tempfile 	`ocupacion'
	save 		``ocupacion'', replace
	
}


* Append the datasets and save the joint data

append using `P01' `P03' `P07'
compress
save "${data}\Individual_balanced_all_PILA.dta", replace

log close
