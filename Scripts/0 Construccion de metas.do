/*------------------------------------------------------------------------------

Proyecto: 								 Compromiso de Desempeño-Directivos 2021
Autores: 								 Hugo Fernandez-Carlos Ramirez
										 UPP	
Ultima fecha de modificación:			 27/08/2021
Outputs:								 Lista de UE que participan de la UGEL
										 con sus metas
											
------------------------------------------------------------------------------*/

* Set 
clear all
set more off
cd "D:\CdD-Dir-Optimization"

* Programs

program identiplaza

 ** Identificación de la plaza original y sus espejo **
		
 		gen prior_tipo = 1
		replace prior_tipo = 2 if tiporegistro == "EVENTUAL"
		replace prior_tipo = 3 if tiporegistro == "PROYECTO"
		replace prior_tipo = 4 if tiporegistro == "CUADRO DE HORAS"
		replace prior_tipo = 5 if tiporegistro == "REEMPLAZO"
		
	 	gen prior_sitlab = 1
		replace prior_sitlab = 2 if sitlab == "F" | sitlab == "D" | sitlab == "E"  | sitlab == "T"
		replace prior_sitlab = 3 if sitlab == "C" | sitlab == "V"
		
		gen soplaza = !strpos(estplaza,"SG") & !strpos(estplaza,"CG") & !strpos(estplaza,"ABAND") //toma valor 1 si la plaza no tiene licencia sin goce, con goce o es una plaza abandonada 
		gen sestpla = estplaza == "ACTIV" //toma valor 1 si es activo
		hashsort -jornlab, gen(sjornlb) //ordenamiento ascendente
		
		*Priorización de plazas activas con personal
		
		duplicates tag descreg nombreooii codmod codplaza, g(dupli)
		
		bys descreg nombreooii codmod codplaza (prior_tipo - sjornlb): gen tipo_fin = _n  
       
		  label define tipo_fin 1"Plaza original" 2"Plaza espejo 1" 3"Plaza espejo 2" 4"Plaza espejo 3" 5"Plaza espejo 4"
		  label values tipo_fin tipo_fin		
		
			
tab tipo_fin dupli
		
end

/*----------------------------------------------------------------------------*/

* Registro RIE 
import excel using "Data\Raw\RIE_06_07_2021_V6.xlsx", clear first
ren *, l
ren id_requerimiento cod_rie
keep cod_rie codmod*

reshape long codmod, i(cod_rie) j(no_care)
drop if mi(codmod)
drop no_care
ren codmod cod_mod
g anexo = "0"

tempfile padron_rie
save `padron_rie'

*Nexus 
use "Data\Raw\nexus_33sira", clear
identiplaza
keep if tipo_fin == 1

gen plaza_dir = 1 ==(tiporegistro != "CUADRO DE HORAS" & real(codsubtipt)==11 & real(codcargo)==11002 & jornlab==40) 

keep if plaza_dir == 1 & sitlab == "E" & tiporegistro_diten == "ORGANICA"

collapse (sum) plaza_dir , by(codmod)
ren codmod cod_mod
g anexo = "0"

tempfile nexus
save `nexus', replace

*-------------------------------------------------------------------------------

use "D:\OneDrive\Bases de datos\Minedu compartido\Padron GG1", clear
merge 1:m cod_mod anexo using `padron_rie', keep(3) nogen
merge 1:1 cod_mod anexo using `nexus', keep(3) nogen

collapse (sum) plaza_dir, by(cod_rie)

tab plaza_dir