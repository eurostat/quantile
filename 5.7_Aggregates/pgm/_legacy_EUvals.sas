/** \cond */
%MACRO EUVALS(eu, ms); /* legacy */
	%if %symexist(EUSILC) %then 	%let SETUP_PATH=&EUSILC;
	%else 		%let SETUP_PATH=/ec/prod/server/sas/0eusilc; 
	%include "&SETUP_PATH/library/autoexec/_setup_.sas";
	%include "&SETUP_PATH/Estimation/pgm/ctry_define.sas";
	%include "&SETUP_PATH/Estimation/pgm/ctry_select.sas";
	%include "&SETUP_PATH/Estimation/pgm/ctry_population.sas";
	%include "&SETUP_PATH/Estimation/pgm/population_compare.sas";
	%include "&SETUP_PATH/Estimation/pgm/zone_build.sas";
	%include "&SETUP_PATH/Estimation/pgm/zone_weight.sas";
	%include "&SETUP_PATH/Estimation/pgm/zone_compute.sas";

	%aggregate(&tab, &eu, &yyyy, &tab, grpdim=&grpdim, ctry_glob=&ms, flag=&flag, 
			   pop_file=' ', take_all=no, nyear_back=0, sampsize=0, max_sampsize=0, 
	     	   thres_presence=, thres_reach=' ', lib=rdb);

				
%mend EUVALS;

/** \endcond */
