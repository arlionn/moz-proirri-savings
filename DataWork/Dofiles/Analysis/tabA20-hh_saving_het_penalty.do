
/*******************************************************************************
*																 			   *
* 				"Transforming Agriculture through Savings:					   *
*	 			  Experimental Evidence from Mozambique			   		       *
*																			   *
*				 Heterogeneous effect by penalty outcomes					   *
*																 			   *
********************************************************************************
	
		WRITTEN BY:  	Matteo Ruzzante [mruzzante@worldbank.org]
		
		REQUIRES:   	"${dt_fin}/PROIRRI Financial Literacy - Savings paper data.dta"
						
		CREATES:	   	Table A20: Impact on Savings – Heterogeneity by Penalty Outcomes
						"${out_tab}/tabA20-hh_saving_het_penalty.tex"
														
* ---------------------------------------------------------------------------- */
	
	* Load data
	use 	"${dt_fin}/PROIRRI Financial Literacy - Savings paper data.dta", clear
			
	* Estimate regression including treatment interacted with the average share of penalty outcomes reported at the community level
	* The outcome variables are, as usual, the saving dummy and the box pick-up value in each quarter of the intervention
	forv  quarter = 1/4 {
				
		eststo 	   v`quarter' 	   	 : reg	   bp_v`quarter'_d_saved treatment el_penalty_mean, cl(associd)
		sum    						  		   bp_v`quarter'_d_saved if e(sample) == 1 & treatment == 0
		estadd scalar control_mean 		= r(mean)
		estadd scalar control_sd   		= r(sd)
		estadd local 		  provFE 	  ""
		
		eststo	   v`quarter'_prov   : reghdfe bp_v`quarter'_d_saved treatment el_penalty_mean, cl(associd) abs(prov)
		estadd     local 	  provFE "\checkmark"
	}
	
	#d	;
		esttab 	v1 v1_prov  		 		
				v2 v2_prov
				v3 v3_prov
				v4 v4_prov
				
				using "${out_tab}/dummy.tex",
				
				replace tex
				se nocons fragment
				nodepvars nonumbers nomtitles nolines
				noobs nonotes alignment(c)
				coeflabel(treatment  	  "\addlinespace[0.75em] Treatment"
						  el_penalty_mean "Treatment $\times$ Share of penalties reported in the scheme")
				stats(	  N r2_a control_mean control_sd provFE,
				  lab(	  "\addlinespace[0.75em] Number of observations"
						  "Adjusted R-squared"
						  "\addlinespace[0.75em] Mean dep.\ var.\ control group"
						  "SD dep.\ var.\ control group"
						  "\addlinespace[0.75em] Province fixed effects")
				  fmt(0 %9.3f %9.3f %9.3f)
					 )
				star(* 0.10 ** 0.05 *** 0.01)
				b(%9.3f) se(%9.3f)	
		;
	#d	cr
	
	est clear
	
	forv  quarter = 1/4 {
		
		eststo 	    v`quarter' 	   	    : reg	  bp_v`quarter'_boxvalue treatment el_penalty_mean, cl(associd)
		sum    						  			  bp_v`quarter'_boxvalue if e(sample) == 1 & treatment == 0
		estadd scalar control_mean 		= r(mean)
		estadd scalar control_sd   		= r(sd)
		estadd local 		   provFE 	  ""
	
		eststo	    v`quarter'_prov     : reghdfe bp_v`quarter'_boxvalue treatment el_penalty_mean, cl(associd) abs(prov)
		estadd      local 	   provFE 	  "\checkmark"
	}
	
	#d	;
		esttab 	v1 v1_prov  		 		
				v2 v2_prov
				v3 v3_prov
				v4 v4_prov
				
				using "${out_tab}/MZN.tex",
				
				replace tex
				se nocons fragment
				nodepvars nonumbers nomtitles nolines
				noobs nonotes alignment(c)
				coeflabel(treatment    	  "\addlinespace[0.75em] Treatment"
						  el_penalty_mean "Treatment $\times$ Share of penalties reported in the scheme")
				stats(	  N r2_a control_mean control_sd provFE,
				  lab(	  "\addlinespace[0.75em] Number of observations"
						  "Adjusted R-squared"
						  "\addlinespace[0.75em] Mean dep.\ var.\ control group"
						  "SD dep.\ var.\ control group"
						  "\addlinespace[0.75em] Province fixed effects")
				  fmt(0 %9.3f %9.0f %9.0f)
					 )
				star(* 0.10 ** 0.05 *** 0.01)
				b(%9.0f) se(%9.0f)
		;
	#d	cr
	
	* Initiate final LaTeX file
	file open test  		   using "${out_tab}/todelete.tex", ///
		 text write replace
		
	* Append estimations in unique LaTeX file 								
	foreach  			panel    in 				dummy MZN 	{			
		
		file open 	   `panel' using "${out_tab}/`panel'.tex" , ///
			 text read
																				
		* Loop over lines of the LaTeX file and save everything in a local		
		local 		   `panel' ""														
			file  read `panel' line										
		while r(eof) == 0 { 														
			local 	   `panel' ///
				   `" ``panel'' `line' "'								
			file read  `panel' line										
		}																		
			file close `panel'											
		
		erase 	     				 "${out_tab}/`panel'.tex" 								
	}																			
	
	* Append all locals as strings, add footnote and end of LaTeX environments
	#d	;
		file write test
			 
			 "&\multicolumn{2}{c}{1st quarter} &\multicolumn{2}{c}{2nd quarter} &\multicolumn{2}{c}{3rd quarter} &\multicolumn{2}{c}{4th quarter} \\	   			  " _n
			 " \cmidrule(lr){2-3} 				\cmidrule(lr){4-5} 				 \cmidrule(lr){6-7} 			  \cmidrule(lr){8-9}					   			  " _n
			 "&(1) &(2) 					   &(3) &(4) 						&(5) &(6)						 &(7) &(8) 						  \\ \hline \\[-1.8ex]" _n
			 
			 "&\multicolumn{8}{c}{\textbf{Panel A -- Probability to Save}}   \\ [0.5ex] \hline    		  " _n
			 " `dummy'    													 \\ 		\hline \\[-1.8ex] " _n
			 "&\multicolumn{8}{c}{\textbf{Panel B -- Savings per Household}} \\ [0.5ex] \hline    		  " _n
			 " `MZN' 						    							 \\ \hline  \hline \\[-1.8ex] " _n
		;
	#d	cr
	
	file close test
	
	* Clean up table
	filefilter  "${out_tab}/todelete.tex" 		  			    ///
				"${out_tab}/tabA20-hh_saving_het_penalty.tex" , ///
				from("[1em]") to("") replace	
	erase 		"${out_tab}/todelete.tex" 	
	
	* Add link to the file (filefilter does not provide it automatically)
	di as text `"Open final file in LaTeX here: {browse "${out_tab}/tabA20-hh_saving_het_penalty.tex":${out_tab}/tabA20-hh_saving_het_penalty.tex}"'

	
***************************** End of do-file ***********************************