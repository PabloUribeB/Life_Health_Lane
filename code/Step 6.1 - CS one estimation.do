/*************************************************************************
 *************************************************************************			       	
	        CS estimation for PILA and RIPS
			 
1) Created by: Pablo Uribe                      Daniel Márquez
			   Yale University                  Harvard Business School
			   p.uribe@yale.edu                 dmarquezm20@gmail.com
				
2) Date: December 2023

3) Objective: Estimate the Callaway & Sant'Anna regressions
			  only for one outcome and append.

4) Output:	- CS_results.dta
*************************************************************************
*************************************************************************/	

****************************************************************************
*Globals
****************************************************************************

// Working directory
if "`c(hostname)'" == "SM201439"{
	global pc "C:"
}

else {
	global pc "\\sm093119"
}

global data 	"${pc}\Proyectos\Banrep research\Returns to Health Sector\Data"
global logs 	"${pc}\Proyectos\Banrep research\Returns to Health Sector\Logs"
global tables 	"${pc}\Proyectos\Banrep research\Returns to Health Sector\Tables"


****************************************************************************
**# 					1. Set-up
****************************************************************************

/*
 Choose professions: 	P01 Bacteriologists, P03 Nurses, P07 Physicians, P09 Dentists
 Choose genders: 		All female male
 Choose dataset: 		Individual_balanced_all_PILA Individual_balanced_all_RIPS

 Choose outcomes:		
	From PILA:			sal_dias_cot_0 posgrado_salud pila_salario_r_0 l_pila_salario_r_0 			///
						posgrado_rethus posgrado_rethus_acum p_cotizaciones_0 nro_cotizaciones_0 	///
						pila_independientes pila_dependientes formal 								///
						pila_salario_max_r incap_dias incap_gral licen_mat
						
	From RIPS			diag_mental diag_mental2 service_mental service_mental2 					///
						urg hosp urg_np hosp_np pregnancy service cons_mental 						///
						cons_mental2 cons_mental3 cons_mental4 consul proce							///
						service_mental_forever service_mental2_forever 								///
						consul_mental_forever consul_mental2_forever
*/

global ocupaciones 	P01 P03 P07 P09
global genders 		all female male
global dataset		Individual_balanced_all_PILA
global outcomes 	pila_salario_r_max_0


****************************************************************************
**# 					2. Estimation
****************************************************************************

foreach ocupacion in $ocupaciones {

	foreach outcome in $outcomes {
		
		foreach gender in $genders {
	
			use "${tables}\CS_results", clear
			drop if occupation == "`ocupacion'" & outcome == "`outcome'" & gender == "`gender'"
			save  "${tables}\CS_results", replace
			
			use if inrange(year_grado,2011,2017) using "${data}\\${dataset}", clear
			drop if (rethus_sexo != 1 & rethus_sexo != 2)
			
			*mdesc fechapregrado
			replace fechapregrado = 0 if mi(fechapregrado) // Replace to zero if never treated for csdid
			
			keep if rethus_codigoperfilpre1 == "`ocupacion'"
			keep personabasicaid fecha_pila fechapregrado `outcome' rethus_sexo rethus_codigoperfilpre1
			
			if "`gender'" == "all" {
				dis as err "All"
			}
			if "`gender'" == "female" {
				dis as err "Women only"
				keep if rethus_sexo == 2
			}
			if "`gender'" == "male" {
				dis as err "Men only"
				keep if rethus_sexo == 1
			}

			gen dist = fecha_pila - fechapregrado
			qui sum `outcome' if (dist == -1 & rethus_codigoperfilpre1 == "`ocupacion'")
			local mean = r(mean)
			
			dis as err "Running CS for PILA `ocupacion' in `outcome' for gender `gender'"			
			
			csdid2 `outcome',			///
			i(personabasicaid) 			/// panel id variable
			t(fecha_pila) 				/// Time variable
			gvar(fechapregrado) 		/// Treatment time
			notyet 						/// Use not-yet treated as comparison
			long2 						/// Calculate results relative to -1
			asinr 						/// Calculate pre-treatment results as in R
			method(drimp)				// Use doubly robust improved method
			
			estat event, post	// Aggregate estimation like an event-study
			
			* Save results in a dta file
			regsave using "${tables}\CS_results", append ci level(95) addlabel(outcome, `outcome', occupation, `ocupacion', gender, `gender', mean, `mean')
			
			csdid2 , clear

		}
		
	}
	
}

