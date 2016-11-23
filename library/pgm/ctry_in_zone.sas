/** 
## ctry_in_zone {#sas_ctry_in_zone}
Check whether a country (defined by its ISO code) belongs to a given geographic zone 
(_e.g._, EU28) in a year-time period.

	%ctry_in_zone(ctry, zone, _ans_=, time=, cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG);

### Arguments
* `ctry` : ISO3166-code of a country (cases GB/UK and GR/EL handled);
* `zone` : code of a geographical zone, _e.g._ EU28, EA19, etc...;
* `time` : (_option_) selected time; if empty, it is tested whether the country ever belonged to area;
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by default,
	it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for further description, 
	see [%_countryxzone](@ref cfg_countryxzone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value 
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.

### Returns
`_ans_` : name of the macro variable where storing the output of the test, _i.e._ the boolean
	result (1: yes/ 0: no) of the question: _"does ctry belong to the geographical area zone?"_.

### Examples
Let's first check whether HR was part of the EU28 area in 2009:

	%let ans=;
	%ctry_in_zone(HR, EU28, time=2009, _ans_=ans);
	
returns `ans=0`. Now, what about 2014?
	
	%ctry_in_zone(HR, EU28, time=2014, _ans_=ans); 

returns `ans=1`.

Considering recent Brexit, we may also ask about UK future in the EU28 area:

	%ctry_in_zone(UK, EU28, time=2018, _ans_=ans);

still returns `ans=1`, for how long however...

Run macro `%%_example_ctry_in_zone` for more examples.

### Note 
The table `cds_ctryxzones` contains in fact for each country in the EU+EFTA 
geographic area the year of entrance in/exit of (when such case applies) any given euro zone. 
In particular, it means that the zone defined by `zone` needs to be defined as a field in the table.
Note that when using the default settings, a table `COUNTRYxZONE` must exist in `LIBCFG`. 

### See also
[%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_to_zone](@ref sas_ctry_to_zone), [%str_isgeo](@ref sas_str_isgeo),
[%_countryxzone](@ref cfg_countryxzone).
*/ /** \cond */

%macro ctry_in_zone(ctry				/* Country ISO code												(REQ) */
					, zone				/* Code of a geographical area in the EU 						(REQ) */
					, _ans_=			/* Name of the macro variable storing the result of the test 	(REQ) */
					, time=				/* Considered year 												(OPT) */
					, var=				/* Name of the geo variable in the configuration table 			(OPT) */
					, cds_ctryxzone=	/* Configuration dataset storing geographical areas				(OPT) */
					, clib=				/* Name of the library storing configuration file				(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_ans_) EQ 1, mac=&_mac,		
			txt=!!! Output macro variable _ANS_ not set !!!) %then 
		%goto exit;

	/* set the default geo variable, i.e. the name of the variable of the table `cds_ctryxzone` 
	* from where to extract country names from
	* by default, it is named set to the value `&G_PING_LAB_GEO`, otherwise `GEO`		*/
	%local LABGEO;	/* default name of the geo variable */
	%if %symexist(G_PING_LAB_GEO) %then 		%let LABGEO=&G_PING_LAB_GEO;
	%else										%let LABGEO=geo;

	/* set the default file of geographical zones/areas */
	%if %macro_isblank(clib) %then %do; 			
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end; 

	%if %macro_isblank(cds_ctryxzone) %then %do; 			
		%if %symexist(G_PING_COUNTRYxZONE) %then 	%let cds_ctryxzone=&G_PING_COUNTRYxZONE;
		%else										%let cds_ctryxzone=COUNTRYxZONE;
	%end; 

	/* perform some existence checks */
	%if %error_handle(ErrorInputParameter, 
			%var_check(&cds_ctryxzone, &zone, lib=&clib) EQ 1, mac=&_mac, 
			txt=!!! Geographic zone %upcase(&zone) not defined !!!) 
		or %error_handle(ErrorInputParameter, 
			%var_check(&cds_ctryxzone, &LABGEO, lib=&clib) EQ 1, mac=&_mac, 
			txt=!!! Field %upcase(&LABGEO) not defined in %upcase(&cds_ctryxzone) !!!) %then 
		%goto exit; 

	%if &ctry=GR %then 			%let ctry=EL;
	%else %if &ctry=GB %then 	%let ctry=UK;

	%let nfound=;
	PROC SQL noprint;
		SELECT distinct count(&LABGEO) into :nfound
		FROM &clib..&cds_ctryxzone
		WHERE &LABGEO="&ctry"
		%if not %macro_isblank(time) and "&time"^="." %then %do;
			HAVING (max(&zone)>&time) & (min(&zone)<=&time)
		%end;
		;
	quit;
	
	%local _ans;
	%let _ans=0;
	%if not %macro_isblank(nfound) %then %do;
		%let _ans=1;
	%end;

	/* return the answer */
	data _null_;
		call symput("&_ans_","&_ans");
	run;

	%exit:	
%mend ctry_in_zone;


%macro _example_ctry_in_zone;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local zone ctry year;
	%let ans=;

	%let zone=DUMMYZONE;
	%let ctry=FR; 
	%let year=2003;
	%put (i) Was ctry=&ctry part of the zone=&zone area in time=&year?;
	%ctry_in_zone(&ctry, &zone, _ans_=ans, time=&year);
	%if &ans= %then 	%put OK: TEST PASSED - Dummy test: returns nothing;
	%else 				%put ERROR: TEST FAILED - Dummy test: returns something;
											
	%let zone=EU28;
	%let ctry=HR; 

	%let year=2010;
	%put (ii) In time=&year, was ctry=&ctry included in zone=&zone?...;
	%ctry_in_zone(&ctry, &zone, _ans_=ans, time=&year);
	%if &ans=0 %then 	%put OK: TEST PASSED - False, &ctry not part of &zone in &year: returns 0;
	%else 				%put ERROR: TEST FAILED - False, &ctry not part of &zone in &year: returns 1;
	
	%let year=;
	%put (iii) Has ctry=&ctry ever been included in zone=&zone (no year passed)?...;
	%ctry_in_zone(&ctry, &zone, _ans_=ans, time=&year);
	%if &ans=1 %then 	%put OK: TEST PASSED - False, &ctry has been (or is) part of &zone: returns 1;
	%else 				%put ERROR: TEST FAILED - False, &ctry has been (or is) part of &zone: returns 0;
	
	%let year=2014;
	%put (iv) In time=&year, was ctry=&ctry included in zone=&zone?...;
	%ctry_in_zone(&ctry, &zone, _ans_=ans, time=&year);
	%if &ans=1 %then 	%put OK: TEST PASSED - False, &ctry not part of &zone in &year: returns 1;
	%else 				%put ERROR: TEST FAILED - False, &ctry not part of &zone in &year: returns 0;

%mend _example_ctry_in_zone;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ctry_in_zone;  
*/

/** \endcond */
