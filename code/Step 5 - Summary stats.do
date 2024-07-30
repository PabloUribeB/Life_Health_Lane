/*************************************************************************
 *************************************************************************			       	
					Summary statistics
			 
1) Created by: Pablo Uribe                      Daniel Márquez
			   Yale University                  Harvard Business School
			   p.uribe@yale.edu                 dmarquezm20@gmail.com
				
2) Date: December 2023

3) Objective: Calculate the summary statistics for our sample.
			  This do file can only be ran at BanRep's servers.

4) Output:	- hist_graduates_all.pdf
			- hist_graduates_sample.pdf
			- Descriptives.xls
*************************************************************************
*************************************************************************/	
clear all

****************************************************************************
*Globals and matrices rows and columns
****************************************************************************

global ocupaciones Bact Nurse Phys Dent                   // Rethus
global rethus_rows " "Whole sample"  "Males" "Females" "  // Rethus

global d_outcomes service consul proce urg hosp mentaldiag // RIPS

global cp_outcomes 	daysworked wage // PILA
global dp_outcomes 	postgrad edad   // PILA

* Table 2 rownames
global t2_outcomes " "Monthly days worked" "Formal real monthly wage" "Health-related postgrad. enrollment" "Age at graduation date" "Accessed a health service" "Medical consultations" "Medical procedures" "ER visits" "Hospitalizations" "Received mental diagnosis" "

set scheme white_tableau

cap log close
log using "${logs}\Step_5.smcl", replace


****************************************************************************
**#						1. RETHUS
****************************************************************************
use "${data}\master_rethus.dta", clear

gen profesionales = 1

	
* All
keep if inrange(year_grado, 2011, 2017)
drop if (rethus_sexo != 1 & rethus_sexo != 2)


* Graduates per year
tw 	hist year_grado, freq disc xlab(2011(1)2017) barw(0.5) fcolor(gs13) ///
lcolor(gs11) xtitle("Year of graduation") ylabel(#10,format(%12.0fc))
graph export "${figures}\hist_graduates_sample.pdf", replace
	
* Graduates per half (Figure 1)
replace fechapregrado = hofd(dofm(fechapregrado))
format fechapregrado %th

tw 	hist fechapregrado, freq disc xlab(102(1)115) barw(0.5) fcolor(gs13) ///
lcolor(gs11) xtitle("Semester of graduation") ylabel(#10,format(%12.0fc)) xlab(, angle(45))
graph export "${figures}\hist_graduates_sample_half.pdf", replace


* Calculate statistics
sum profesionales
local B_1_1 = strtrim("`: di %10.0fc r(N)'")
local b_1_1 = r(N)
local P_1_1 = "(" + strtrim("`:di %5.0f r(N) / `b_1_1' * 100'") + "\%)"

sum profesionales if rethus_sexo == 1
local B_2_1 = strtrim("`: di %10.0fc r(N)'")
local P_2_1 = "(" + strtrim("`:di %5.2f r(N) / `b_1_1' * 100'") + "\%)"

sum profesionales if rethus_sexo == 2
local B_3_1 = strtrim("`: di %10.0fc r(N)'")
local P_3_1 = "(" + strtrim("`:di %5.2f r(N) / `b_1_1' * 100'") + "\%)"

texresults3 using "${tables}\numbers.txt", texmacro(samplerethus) 			///
result(`B_1_1') replace // Only for internal use. Comment for publication.


replace rethus_codigoperfilpre1 = "Bact" 	if rethus_codigoperfilpre1 == "P01"
replace rethus_codigoperfilpre1 = "Phys" 	if rethus_codigoperfilpre1 == "P07"
replace rethus_codigoperfilpre1 = "Nurse" 	if rethus_codigoperfilpre1 == "P03"
replace rethus_codigoperfilpre1 = "Dent" 	if rethus_codigoperfilpre1 == "P09"


local f = 2
foreach ocupacion in $ocupaciones {
	
	sum profesionales if (rethus_codigoperfilpre1 == "`ocupacion'")
	local B_1_`f' = strtrim("`: di %10.0fc r(N)'")
	local P_1_`f' = "(" + strtrim("`:di %5.2f r(N) / `b_1_1' * 100'") + "\%)"
	
	local mean    = r(N) * 100
	texresults3 using "${tables}\numbers.txt", texmacro(mean`ocupacion') 	///
	result(`mean') round(0) unit append // Only for internal use. Comment for publication.
	
	local ++f
	
}

* Males
local f = 2
foreach ocupacion in $ocupaciones {
	
	sum profesionales if (rethus_codigoperfilpre1 == "`ocupacion'" & rethus_sexo == 1)
	local B_2_`f' = strtrim("`: di %10.0fc r(N)'")
	local P_2_`f' = "(" + strtrim("`:di %5.2f r(N) / `b_1_1' * 100'") + "\%)"
	
	local ++f
	
}

* Females
local f = 2
foreach ocupacion in $ocupaciones {
	
	sum profesionales if (rethus_codigoperfilpre1 == "`ocupacion'" & rethus_sexo == 2)
	local B_3_`f' = strtrim("`: di %10.0fc r(N)'")
	local P_3_`f' = "(" + strtrim("`:di %5.2f r(N) / `b_1_1' * 100'") + "\%)"

	local ++f
	
}


**** Table 1

texdoc init "${tables}/table1.tex", replace force	

tex \begin{tabular}{lccccc}
tex \toprule

tex & All professions & Bacteriologists & Nurses & Physicians & Dentists \\
tex \midrule



local i = 1
foreach var of global rethus_rows{
    
    if `i' == 3         local space
    else                local space "\addlinespace"
    
	tex `var' & `B_`i'_1' & `B_`i'_2' & `B_`i'_3' & `B_`i'_4' & `B_`i'_5' \\
    tex          & `P_`i'_1' & `P_`i'_2' & `P_`i'_3' & `P_`i'_4' & `P_`i'_5' \\ `space'
	
    local ++i
	
}

tex \bottomrule
tex \end{tabular}
texdoc close

	
****************************************************************************
**#						2. PILA
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

rename 	(sal_dias_cot_0 pila_salario_r_0 posgrado_salud) (daysworked wage postgrad)


** All sample
preserve

	collapse (mean) $cp_outcomes (max) $dp_outcomes , by(personabasicaid)

    local f = 1
	foreach outcome in $cp_outcomes $dp_outcomes {

        qui sum `outcome'
    
		if inlist("`outcome'", "wage"){
			local mean  = strtrim("`:di %11.0fc r(mean)'")
            local sd    = strtrim("`:di %11.0fc r(sd)'")
            local nmean = strtrim("`:di %11.0fc r(mean)'")
		}
		else if inlist("`outcome'", "daysworked", "edad"){
			local mean  = strtrim("`:di %06.3fc r(mean)'")
            local sd    = strtrim("`:di %06.3fc r(sd)'")
            local nmean = strtrim("`:di %06.2fc r(mean)'")
		}
		else{
			local mean  = strtrim("`:di %06.3fc r(mean)'")
            local sd    = strtrim("`:di %06.3fc r(sd)'")
            local nmean = strtrim("`:di %06.2fc r(mean) * 100'")
		}

		local m_`f'_1  = "`mean'"
		local sd_`f'_2 = "`sd'"
		
		texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome') 	///
		result(`nmean') round(0) unit append // Only for internal use. Comment for publication.
		local ++f
		
	}

restore


*** Gender

collapse (mean) $cp_outcomes (max) $dp_outcomes , by(personabasicaid rethus_sexo)

* Males
local f = 1
foreach outcome in $cp_outcomes $dp_outcomes {

    qui sum `outcome' if rethus_sexo == 1

    if inlist("`outcome'", "wage"){
        local mean  = strtrim("`:di %11.0fc r(mean)'")
        local sd    = strtrim("`:di %11.0fc r(sd)'")
        local nmean = strtrim("`:di %11.0fc r(mean)'")
    }
    else if inlist("`outcome'", "daysworked", "edad"){
        local mean  = strtrim("`:di %06.3fc r(mean)'")
        local sd    = strtrim("`:di %06.3fc r(sd)'")
        local nmean = strtrim("`:di %06.2fc r(mean)'")
    }
    else{
        local mean  = strtrim("`:di %06.3fc r(mean)'")
        local sd    = strtrim("`:di %06.3fc r(sd)'")
        local nmean = strtrim("`:di %06.2fc r(mean) * 100'")
    }

    local m_`f'_3  = "`mean'"
    local sd_`f'_4 = "`sd'"
    
    texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome'M) 	///
    result(`nmean') round(0) unit append // Only for internal use. Comment for publication.
    
    local ++f
}


* Females
local f = 1
foreach outcome in $cp_outcomes $dp_outcomes {

    qui sum `outcome' if rethus_sexo == 2

    if inlist("`outcome'", "wage"){
        local mean  = strtrim("`:di %11.0fc r(mean)'")
        local sd    = strtrim("`:di %11.0fc r(sd)'")
        local nmean = strtrim("`:di %11.0fc r(mean)'")
    }
    else if inlist("`outcome'", "daysworked", "edad"){
        local mean  = strtrim("`:di %06.3fc r(mean)'")
        local sd    = strtrim("`:di %06.3fc r(sd)'")
        local nmean = strtrim("`:di %06.2fc r(mean)'")
    }
    else{
        local mean  = strtrim("`:di %06.3fc r(mean)'")
        local sd    = strtrim("`:di %06.3fc r(sd)'")
        local nmean = strtrim("`:di %06.2fc r(mean) * 100'")
    }
   
    local m_`f'_5  = "`mean'"
    local sd_`f'_6 = "`sd'"

    texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome'F) 	///
    result(`nmean') round(0) unit append // Only for internal use. Comment for publication.
    local ++f
    
}


local new_row = `f' // Save current row position
		

****************************************************************************
**#						3. RIPS
****************************************************************************

use "${data}\Individual_balanced_all_RIPS.dta", clear
keep if (year_grado >= 2011 & year_grado <= 2017)
drop if (rethus_sexo != 1 & rethus_sexo != 2)

rename 	service_mental mentaldiag
				
local f = `new_row'

* All sample
preserve

	collapse (max) $d_outcomes , by(personabasicaid)

	foreach outcome in $d_outcomes {
		
		qui sum `outcome'
		local m_`f'_1  = strtrim("`:di %5.3fc r(mean)'")
		local sd_`f'_2 = strtrim("`:di %5.3fc r(sd)'")
		
		local mean     = `m_`f'_1' * 100
		texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome') 	///
		result(`mean') round(0) unit append // Only for internal use. Comment for publication.
		
		local ++f
		
	}

restore

** Gender

collapse (max) $d_outcomes , by(personabasicaid rethus_sexo)

local f = `new_row'
foreach outcome in $d_outcomes {
    
    * Males
    qui sum `outcome' if rethus_sexo == 1
    local m_`f'_3  = strtrim("`:di %5.3fc r(mean)'")
    local sd_`f'_4 = strtrim("`:di %5.3fc r(sd)'")
    
    local mean     = `m_`f'_3' * 100
    texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome'M) 	///
    result(`mean') round(0) unit append // Only for internal use. Comment for publication.
    
    
    * Females
    qui sum `outcome' if rethus_sexo == 2
    local m_`f'_5  = strtrim("`:di %5.3fc r(mean)'")
    local sd_`f'_6 = strtrim("`:di %5.3fc r(sd)'")
    
    local mean     = `m_`f'_5' * 100
    texresults3 using "${tables}\numbers.txt", texmacro(mean`outcome'F) 	///
    result(`mean') round(0) unit append // Only for internal use. Comment for publication.
    local ++f
}



**** Table 2
texdoc init "${tables}/table2.tex", replace force	

tex \begin{tabular}{lcccccc}
tex \toprule

tex & \multicolumn{2}{c}{Whole sample} & \multicolumn{2}{c}{Males}     & \multicolumn{2}{c}{Females} \\
tex \cmidrule(l){2-3} \cmidrule(l){4-5} \cmidrule(l){6-7}

tex & Mean & SD & Mean & SD & Mean & SD \\
tex \midrule



local i = 1
local j = 1
foreach var of global t2_outcomes {
	
	if `i' == 1       local panel "tex \multicolumn{7}{l}{\textit{Panel A: PILA (2008-2022)}} \\"
    else if `i' == 5  local panel "tex \multicolumn{7}{l}{\textit{Panel B: RIPS (2009-2022)}} \\"
    else              local panel
    
    if `j' == 4       local space "\addlinespace"
    else              local space
    
    
    `panel'
	tex `var' & `m_`i'_1' & `sd_`i'_2' & `m_`i'_3' & `sd_`i'_4' & `m_`i'_5' & `sd_`i'_6' \\ `space'
	
    local ++i
	local ++j
}

tex \bottomrule
tex \end{tabular}
texdoc close



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

	gen graduates = 1

	gen w_range = .
	replace w_range = 1 if (pila_salario_r_0 <= mw)
	replace w_range = 2 if (pila_salario_r_0 >  mw		& pila_salario_r_0 <= (mw * 2))
	replace w_range = 3 if (pila_salario_r_0 > (mw * 2) 	& pila_salario_r_0 <= (mw * 3))
	replace w_range = 4 if (pila_salario_r_0 > (mw * 3)  	& pila_salario_r_0 <= (mw * 5))
	replace w_range = 5 if (pila_salario_r_0 > (mw * 5))
	
	collapse (sum) graduates, by(rethus_codigoperfilpre1 fecha_pila w_range)
	format fecha_pila %th
    
	save "${output}\wage_ranges", replace
	export excel using "${output}\wage_ranges.xlsx", firstrow(variables) sheet("All") sheetreplace

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

save "${output}\wage_ranges", replace
export excel using "${output}\wage_ranges.xlsx", firstrow(variables) sheet("All") sheetreplace


****************************************************************************
**#						3.2. Age descriptives
****************************************************************************

* Age at the graduation figure
use "${data}\Individual_balanced_all_PILA.dta", clear
drop if (rethus_sexo != 1 & rethus_sexo != 2)

collapse (mean) edad, by(year_grado rethus_codigoperfilpre1)
keep if inrange(year_grado,2011,2017)

tw 	(connected edad year_grado if rethus_codigoperfilpre1 == "P01", color(gs11)   m(O) msize(medsmall))			///
	(connected edad year_grado if rethus_codigoperfilpre1 == "P03", color(gs9)    m(S) msize(medsmall))			///
	(connected edad year_grado if rethus_codigoperfilpre1 == "P07", color(gs6)    m(D) msize(medsmall))			///
	(connected edad year_grado if rethus_codigoperfilpre1 == "P09", color(gs1)    m(T) msize(medsmall)),		///
	xtitle(Year) ytitle(Age at graduation date)	ylab(#10) xlab(2011(1)2017)										///
	legend(order(4 "Dentists" 3 "Physicians" 2 "Nurses" 1 "Bacteriologists") position(6) col(4))				///
	graphregion(fcolor(white))
	
graph export "${figures}\age_at_graduation.pdf", replace	

* Outcomes by age
use "${data}\Individual_balanced_all_PILA.dta", clear
drop if (rethus_sexo != 1 & rethus_sexo != 2)
drop edad

global outcomes sal_dias_cot_0 posgrado_salud pila_salario_r_0 l_pila_salario_r_0 		///
				p_cotizaciones_0 pila_independientes pila_salario_r_max_0

replace fecha_pila = yofd(dofh(fecha_pila))
replace birth      = yofd(birth)		
				
gen	dist           = fecha_pila - birth

collapse (mean) ${outcomes}, by(dist rethus_codigoperfilpre1)
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
	
	graph export "${figures}\Outcomes by age\\`outcome'_by_age.png", replace

}

log close
