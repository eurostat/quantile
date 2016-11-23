/** 
## aggregate_flag {#sas_aggregate_flag}
Set the flag of the aggregated indicator depending on the zone/year considered
for the estimation and the number of countries actually used in the estimation.

	%aggregate_flag(zone, ctry_glob, year, ctry_tab, _flag_=);

### Arguments
* `zone` : code of a geographical area, _e.g._, EU28, EA19, etc...;
* `ctry_glob` : list of (comma-separated, quote-enclosed) strings representing the ISO-codes 
	of all the countries that belong to the area represented by zone;
* `year` : year of interest;
* `ctry_tab` : list (similar to `ctry_glob`) of (comma-separated, quote-enclosed) strings 
	representing the ISO-codes of the countries that will be actually used for the estimation
	of the aggregated indicator.

### Returns
* `_flag_` : name of the macro variable used to store the flag of the aggregated indicator (_e.g._,
	`s` for estimated). 

### Note
Two types of checked are performed:	
	- one type based on the actual zone/year combination,
	- another type based on the number of countries used in the estimation (`ctry_tab`).
 
### Examples
Run macro `%%_example_aggregate_flag`.
*/ /** \cond */

%macro aggregate_flag(/*input*/  zone, ctry_glob, year, ctry_tab, 
					  /*output*/ _flag_=' ');

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_flag_) EQ 1,		
			txt=!!! output macro variable _flag_ need to be set !!!) %then 
		%goto exit;

	%local _flag;
	%let _flag=;

	/* check based on number of countries of current year used for the estimation */
	%local nzone npart time_part;
	%let nzone=%clist_length(&ctry_glob, sep=%str(%"));
	%var_to_list(&ctry_tab, time, _varlst_=time_part, num=&nzone, len=2);
	%local npart;
	%let npart=%list_count(&time_part, &year);
	%if &npart ne &nzone %then %do;
		%let _flag=s; 
		%goto quit;
	%end;

	/* hard checks based on the zone/time considered */
	%if (&zone=EU27 AND &year<2007) %then %do; 
		%let _flag=s; 
		%goto quit;
	%end;

	%quit:
	data _null_;
		call symput("&_flag_","&_flag");
	run;

	%exit:
%mend aggregate_flag;

%macro _example_aggregate_flag;
;
%mend _example_aggregate_flag;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_aggregate_flag;  
*/

/** \endcond */
