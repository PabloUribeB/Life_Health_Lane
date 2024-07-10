/*************************************************************************
 *************************************************************************			       	
	        CS estimation for PILA and RIPS
			 
1) Created by: Pablo Uribe						Daniel Márquez
			   World Bank						Harvard Business School
			   puribebotero@worldbank.org		dmarquezm20@gmail.com
				
2) Date: December 2023

3) Objective: Estimate the Callaway & Sant'Anna regressions
			  This do file can only be ran at BanRep's servers.

4) Output:	- CS_results.dta
*************************************************************************
*************************************************************************/	

****************************************************************************
*Required packages (uncomment if running for the first time)
****************************************************************************
*ssc install drdid, 	replace
*ssc install csdid, 	replace
*ssc install regsave,replace

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


cap log close
log using "${logs}\CS_estimation.smcl", replace

* P01 Bacteriologists, P03 Nurses, P07 Physicians, P09 Dentists
global ocupaciones P01 P03 P07 P09
global genders all female male

****************************************************************************
**# 					1. PILA estimation
****************************************************************************

* Specify outcomes in global outcomes
global outcomes sal_dias_cot_0 posgrado_salud pila_salario_r_0 l_pila_salario_r_0 			///
				posgrado_rethus posgrado_rethus_acum p_cotizaciones_0 nro_cotizaciones_0 	///
				pila_independientes pila_dependientes formal  								///
				pila_salario_r_max_0 incap_dias incap_gral licen_mat

local replace replace
foreach ocupacion in $ocupaciones {

	foreach outcome in $outcomes {
		
		foreach gender in $genders {
	
			use if inrange(year_grado,2011,2017) using "${data}\Individual_balanced_all_PILA", clear
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
			regsave using "${tables}\CS_results", `replace' ci level(95) addlabel(outcome, `outcome', occupation, `ocupacion', gender, `gender', mean, `mean')
			
			csdid2 , clear
			
			local replace append

		}
		
	}
	
}


****************************************************************************
**# 					2. RIPS estimation
****************************************************************************

* Specify outcomes in global outcomes
global outcomes diag_mental diag_mental2 service_mental service_mental2 ///
				urg hosp urg_np hosp_np pregnancy service cons_mental 	///
				cons_mental2 cons_mental3 cons_mental4 consul proce		///
				service_mental_forever service_mental2_forever 			///
				consul_mental_forever consul_mental2_forever
			
foreach ocupacion in $ocupaciones {

	foreach outcome in $outcomes {
		
		foreach gender in $genders {
	
			use personabasicaid year_grado year_RIPS fechapregrado `outcome' rethus_sexo rethus_codigoperfilpre1 if inrange(year_grado,2011,2017) & rethus_codigoperfilpre1 == "`ocupacion'" using "${data}\Individual_balanced_all_RIPS", clear
			drop if (rethus_sexo != 1 & rethus_sexo != 2)
			
			*mdesc fechapregrado
			replace fechapregrado = 0 if mi(fechapregrado) // Replace to zero if never treated for csdid
			
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

			gen dist = year_RIPS - year_grado
			qui sum `outcome' if (dist == -1 & rethus_codigoperfilpre1 == "`ocupacion'")
			local mean = r(mean)			
			
			dis as err "Running event study for RIPS `ocupacion' in `outcome' for gender `gender'"	
		
			csdid2 `outcome', 			///
			i(personabasicaid) 			/// panel id variable
			t(year_RIPS) 				/// Time variable
			gvar(year_grado) 			/// Treatment time
			notyet 						/// Use not-yet treated as comparison
			long2 						/// Calculate results relative to -1
			asinr 						/// Calculate pre-treatment results as in R
			method(drimp)				// Use doubly robust improved method
			
			estat event, post 	// Aggregate estimation like an event-study
			
			* Save results in a dta file
			regsave using "${tables}\CS_results", append ci level(95) addlabel(outcome, `outcome', occupation, `ocupacion', gender, `gender', mean, `mean')
			
			csdid2 , clear
			
		}
		
	}
	
}


****************************************************************************
**# 					3. Non-pregnancy outcomes for PILA
****************************************************************************

use personabasicaid pregnancy using "${data}\Individual_balanced_all_RIPS", clear

replace pregnancy = 0 if pregnancy != 1
bys personabasicaid: egen ever_pregnant = max(pregnancy)
drop pregnancy
gduplicates drop

tempfile ever_pregnant
save `ever_pregnant'

* Specify outcomes in global outcomes
global outcomes sal_dias_cot_0  pila_salario_r_0 p_cotizaciones_0 pila_independientes 

foreach ocupacion in $ocupaciones {

	foreach outcome in $outcomes {
		
		foreach gender in $genders {
	
			use if inrange(year_grado,2011,2017) using "${data}\Individual_balanced_all_PILA", clear
			drop if (rethus_sexo != 1 & rethus_sexo != 2)
			
			merge m:1 personabasicaid using `ever_pregnant', keep(3) nogen
			drop if ever_pregnant == 1
			
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
			regsave using "${tables}\CS_results", append ci level(95) addlabel(outcome, `outcome'_np, occupation, `ocupacion', gender, `gender', mean, `mean')
			
			csdid2 , clear

		}
		
	}
	
}



****************************************************************************
**# 					4. Outcomes for specialists only
****************************************************************************

* Specify outcomes in global outcomes
global outcomes sal_dias_cot_0  pila_salario_r_0 p_cotizaciones_0 pila_independientes 

foreach ocupacion in $ocupaciones {

	foreach outcome in $outcomes {
		
		foreach gender in $genders {
			
			foreach posgrado in posg npos {

				use if inrange(year_grado,2011,2017) using "${data}\Individual_balanced_all_PILA", clear
				drop if (rethus_sexo != 1 & rethus_sexo != 2)
				
				*mdesc fechapregrado
				replace fechapregrado = 0 if mi(fechapregrado) // Replace to zero if never treated for csdid
				
				keep if rethus_codigoperfilpre1 == "`ocupacion'"
				keep personabasicaid fecha_pila fechapregrado `outcome' rethus_sexo rethus_codigoperfilpre1 posgrado_salud
				
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
				
				bys personabasicaid: egen posg = max(posgrado_salud)
				if "`posgrado'" == "posg" {
					keep if posg == 1
				}
				if "`posgrado'" == "npos" {
					keep if posg == 0
				}
				drop posg

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
				regsave using "${tables}\CS_results", append ci level(95) addlabel(outcome, `outcome'_`posgrado', occupation, `ocupacion', gender, `gender', mean, `mean')
				
				csdid2 , clear
				
			}

		}
		
	}
	
}


****************************************************************************
**# 				5. Estimations until 2019 (pre covid)
****************************************************************************

* PILA
global outcomes sal_dias_cot_0 pila_salario_r_0  

foreach ocupacion in $ocupaciones {

	foreach outcome in $outcomes {
		
		foreach gender in $genders {
	
			use if inrange(year_grado,2011,2017) using "${data}\Individual_balanced_all_PILA", clear
			drop if (rethus_sexo != 1 & rethus_sexo != 2)
			
			*mdesc fechapregrado
			replace fechapregrado = 0 if mi(fechapregrado) // Replace to zero if never treated for csdid
			
			keep if rethus_codigoperfilpre1 == "`ocupacion'"
			keep personabasicaid fecha_pila fechapregrado `outcome' rethus_sexo rethus_codigoperfilpre1
			keep if fecha_pila < 120
			
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
			regsave using "${tables}\CS_results_nocovid", `replace' ci level(95) addlabel(outcome, `outcome', occupation, `ocupacion', gender, `gender', mean, `mean')
			
			csdid2 , clear
			
			local replace append

		}
		
	}
	
}


* RIPS
global outcomes hosp service_mental_forever 
			
foreach ocupacion in $ocupaciones {

	foreach outcome in $outcomes {
		
		foreach gender in $genders {
	
			use personabasicaid year_grado year_RIPS fechapregrado `outcome' rethus_sexo rethus_codigoperfilpre1 if inrange(year_grado,2011,2017) & rethus_codigoperfilpre1 == "`ocupacion'" using "${data}\Individual_balanced_all_RIPS", clear
			drop if (rethus_sexo != 1 & rethus_sexo != 2)
			
			*mdesc fechapregrado
			replace fechapregrado = 0 if mi(fechapregrado) // Replace to zero if never treated for csdid
			keep if year_RIPS < 2020
			
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

			gen dist = year_RIPS - year_grado
			qui sum `outcome' if (dist == -1 & rethus_codigoperfilpre1 == "`ocupacion'")
			local mean = r(mean)			
			
			dis as err "Running event study for RIPS `ocupacion' in `outcome' for gender `gender'"	
		
			csdid2 `outcome', 			///
			i(personabasicaid) 			/// panel id variable
			t(year_RIPS) 				/// Time variable
			gvar(year_grado) 			/// Treatment time
			notyet 						/// Use not-yet treated as comparison
			long2 						/// Calculate results relative to -1
			asinr 						/// Calculate pre-treatment results as in R
			method(drimp)				// Use doubly robust improved method
			
			estat event, post 	// Aggregate estimation like an event-study
			
			* Save results in a dta file
			regsave using "${tables}\CS_results_nocovid", append ci level(95) addlabel(outcome, `outcome', occupation, `ocupacion', gender, `gender', mean, `mean')
			
			csdid2 , clear
			
		}
		
	}
	
}






log close
