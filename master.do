/*************************************************************************
 *************************************************************************			       	
	        Life in the Health Lane Replication master do
			 
1) Created by: Pablo Uribe                      Daniel Márquez
			   Yale University                  Harvard Business School
			   p.uribe@yale.edu                 dmarquezm20@gmail.com
				
2) Date: July 2024

3) Objective: Replicate all the paper's exhibits. Exact replicability is
              ensured by using constant packages versions
              
*************************************************************************
*************************************************************************/	

version 17
set graphics off

cap which repkit  
if _rc == 111{
    ssc install repkit
}

****************************************************************************
* Globals
****************************************************************************
* Set path for original datasets in BanRep
if "`c(hostname)'" == "SM201439" global pc "C:"
else global pc "\\sm093119"

global data 		"${pc}\Proyectos\Banrep research\Returns to Health Sector\Data"
global urgencias 	"${pc}\Proyectos\Data"
global data_rethus 	"${pc}\Proyectos\Banrep research\f_ReturnsToEducation Health sector\Data"
global pila_og      "\\sm134796\D\Originales\PILA\1.Pila mensualizada\PILA mes cotizado"
global ipc          "\\sm037577\D\Proyectos\Banrep research\c_2018_SSO Servicio Social Obligatorio\Project SSO Training\Data"
global RIPS 		"\\sm134796\E\RIPS\Stata"
global RIPS2 		"\\wmedesrv\gamma\rips"


* Set path to reproducibility package (where ado and code are located)
* Include username and change global to where repo folder is located
if inlist("`c(username)'", "Pablo Uribe", "danie", "pu42") {
    
    global root	"~\Documents\GitHub\Life_Health_Lane"
    local external = 1
    
}
else {
    
    global root	"Z:\Christian Posso\_banrep_research\proyectos\Life_Health_Lane"
    local external = 0
    
}

* Create folders if non-existent
cap mkdir "${root}\Logs"
cap mkdir "${root}\Tables"
cap mkdir "${root}\Figures"
cap mkdir "${root}\Output"

* Point adopath to the ado folder in the reproducibility package
repado, adopath("${root}\ado") mode(strict)


* Code folder within rep package
global do_files "${root}\code"
global logs     "${root}\Logs"
global figures 	"${root}\Figures"
global tables   "${root}\Tables"
global output   "${root}\Output"

****************************************************************************
* Run all do files
****************************************************************************

if `external' == 0 { // These only run at BanRep due to confidentiality
    
    do "${do_files}\Step 1 - RIPS creation.do"
    do "${do_files}\Step 2 - RIPS variables.do"
    do "${do_files}\Step 3 - PILA creation and variables.do"
    do "${do_files}\Step 4 - PILA append and balance.do"
    do "${do_files}\Step 5 - Summary stats.do"
    do "${do_files}\Step 6 - CS estimations.do"
    
}

* These can be run from any PC with access to /Output
do "${do_files}\Step 7 - CS figures.do"
do "${do_files}\Step 7.1 - CS figures relative.do"
do "${do_files}\Step 7.2 - CS figures (no-covid).do"
