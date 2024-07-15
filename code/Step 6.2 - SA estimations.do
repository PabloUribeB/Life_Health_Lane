/*************************************************************************
 *************************************************************************			       	
	        Sun and Abraham estimation for RIPS only
			 
1) Created by: Pablo Uribe                      Daniel Márquez
			   Yale University                  Harvard Business School
			   p.uribe@yale.edu                 dmarquezm20@gmail.com
				
2) Date: December 2023

3) Objective: Estimate the before and after regressions
			  This do file can only be ran at BanRep's servers.

4) Output:	- BA_results.dta
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


* P01 Bacteriologists, P03 Nurses, P07 Physicians, P09 Dentists
global ocupaciones P01 P03 P07 P09
global genders all female male


****************************************************************************
**# 				1. Staggered command estimation
****************************************************************************

global outcomes service_mental_forever service_mental2_forever 			///
				consul_mental_forever consul_mental2_forever

local replace replace
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
		
			local stagopts i(personabasicaid) t(year_RIPS) g(year_grado)
			staggered `outcome', `stagopts' estimand(eventstudy) eventTime(0/4) use_last_treated_only
			*outreg2 using "ST_results.xls", append ctitle(Model 2)
			
			regsave using "${tables}\ST_results", `replace' ci level(95) addlabel(outcome, `outcome', occupation, `ocupacion', gender, `gender', mean, `mean')
			
			local replace append
			
		}
		
	}
	
}


