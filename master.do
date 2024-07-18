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

cap which repkit  
if _rc == 111{
    ssc install repkit
}

****************************************************************************
* Globals
****************************************************************************

* Set path to reproducibility package (where ado and code are located)
global main "Z:\Christian Posso\_banrep_research\proyectos\Life_Health_Lane"

* Point adopath to the ado folder in the reproducibility package
repado, adopath("${main}/ado") mode(strict)


* Code folder within rep package
global do_files "${main}\code"



****************************************************************************
* Run all do files
****************************************************************************

do "${do_files}\Step 1 - RIPS creation.do"
do "${do_files}\Step 2 - RIPS variables.do"
do "${do_files}\Step 3 - PILA creation and variables.do"
do "${do_files}\Step 4 - PILA append and balance.do"
do "${do_files}\Step 5 - Summary stats.do"
do "${do_files}\Step 6 - CS estimations.do"
do "${do_files}\Step 7 - CS figures.do"
do "${do_files}\Step 7.1 - CS figures relative.do"
do "${do_files}\Step 7.3 - CS figures (no-covid).do"
