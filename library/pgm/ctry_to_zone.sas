/**
## ctry_to_zone {#sas_ctry_to_zone}
Return the list of geographic area(s) (_e.g._, EU28) that contain(s), during a given period, at least 
one of the countries passed in an input list.

	%ctry_to_zone(&ctry, time=, _zone_=, cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG);

### Arguments				
* `ctry` : (list of) code(s) of the countries, _e.g._, AT, IT, etc...;
* `time` : (_option_) selected year; 
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by default,
	it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for further description, 
	see [%_countryxzone](@ref cfg_countryxzone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value 
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.

### Returns
`_zone_` : name of the output macro variable storing the desired list of geographic area(s). 

### Examples
Let us consider the following simple examples: 

	%let ozone=;
	%ctry_to_zone(AT BE, time=2004, _zone_ =ozone);

returns `ozone=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU07 EU09 EU10 EU12 EU15 EU25 EU27 EU28`,
while:

	%let ozone=;
	%ctry_to_zone(BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO HR, time=2015, _zone_ =ozone);

returns `ozone=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU07 EU09 EU10 EU12 EU15 EU25 EU27 EU28`.

Run macro `%%_example_ctry_to_zone` for more examples.

### Notes 
1. In short, this macro runs, when `time` is passed, the following procedures/macros:

       PROC TRANSPOSE data=&clib..&cds_ctryxzone out=tmp1 
		   name=ZONE
		   prefix=TIME_;
		   by GEO;
		run;

       PROC SQL noprint;
		   CREATE TABLE  tmp2  as SELECT distinct ZONE
		   FROM tmp1 
		   WHERE GEO in (%list_quote(&ctry)) and (TIME_2>&time and  TIME_1<=&time);
	   quit;

       %var_to_list(tmp2, ZONE, _varlst_=&_zone_);
2. The table in the configuration dataset `cds_ctryxzone` contains in fact for each country in the EU+EFTA 
geographic area the year of entrance in/exit of (when such case applies) any given euro zone. 
In particular, it means that `zone` needs to be defined as a field in the table `cds_ctryxzone`.

### Reference
Eurostat: Tutorial on ["Country codes and protocol order"](http://ec.europa.eu/eurostat/statistics-explained/index.php/Tutorial:Country_codes_and_protocol_order). 

### See also
[%ctry_in_zone](@ref sas_ctry_in_zone), [%zone_to_ctry](@ref sas_zone_to_ctry), 
[%_countryxzone](@ref cfg_countryxzone).
*/ /** \cond */

%macro ctry_to_zone(ctry			    /* list of countries       								    (REQ) */
					, dsn			    /* Name of the output table 							    (REQ) */
					, _zone_=		    /* Name of the output list of zone          			    (REQ) */
					, time=				/* Year of interest										    (REQ) */
					, cds_ctryxzone=	/* Configuration dataset storing geographical areas		    (OPT) */
					, clib=				/* Name of the library storing configuration file		    (OPT) */
					);
	%local _mac;
	%let   _mac=&sysmacroname;

	%local _ans		/* temporary answer variable */
		   _dsn
		    LABGEO
		   _METHOD_;    /* dummy flag */
	/* initialise some of those variables */
	%let _METHOD_=BEST;
	%let _dsn=TMP_%upcase(&sysmacroname);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&time, type=INTEGER, range 1995) NE 0, mac=&_mac,		
			txt=!!! Parameter TIME is of type INTEGER !!!) %then
		%goto exit;
	
	/* set the default file of geographical zones/areas */
	%if %macro_isblank(clib) %then %do; 			
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end; 

	%if %macro_isblank(cds_ctryxzone) %then %do; 			
		%if %symexist(G_PING_COUNTRYxZONE) %then 	%let cds_ctryxzone=&G_PING_COUNTRYxZONE;
		%else										%let cds_ctryxzone=COUNTRYxZONE;
	%end; 

	/* set the default geo variable */
	%if %symexist(G_PING_LAB_GEO) %then 		%let LABGEO=&G_PING_LAB_GEO;
	%else										%let LABGEO=geo;

	%if &_METHOD_=BEST %then %do;

       PROC TRANSPOSE data=&clib..&cds_ctryxzone out=&_dsn.1 
			name=ZONE
			prefix=TIME_;
			by &LABGEO;
		run;

        PROC SQL noprint;
			CREATE TABLE  &_dsn.2  as SELECT distinct ZONE
			FROM &_dsn.1 
			WHERE &LABGEO in (%list_quote(&ctry)) 
			%if not %macro_isblank(time) and "&time"^="." %then %do;
				and (TIME_2>&time and  TIME_1<=&time)
			%end;
			;
			quit;

 		%ds_isempty(&_dsn.2, var=ZONE, _ans_=_ans);  
    	%if %error_handle(ErrorInputDataset, 
				&_ans EQ 1, mac=&_mac, 
				txt=%bquote(!!! Dataset %upcase(&_dsn.2) empty: no country/zone matched !!!)) %then %do
			%let &_zone_=&lzone; /* abusivo... */
		    %goto quit;
		%end;

   		 %var_to_list(&_dsn.2, ZONE, _varlst_=&_zone_);
		
		 %quit:
		 %work_clean(&_dsn.1, &_dsn.2);
		 %goto exit;
	%end;

	/* dummy method */
	%else %if &_METHOD_=DUMMY %then %do;
		%local _i _k	/* loop increments */
			zone		/* list of possible/existing zones */
			_zone		/* temporary tested zone */
			lzone; 		/* output list of desired zones */
		%let lzone=;
		* retrieve all existing/possible zones;
		%ds_contents(&cds_ctryxzone, _varlst_=zone, lib=&clib);
		%let zone = %list_slice(&zone, ibeg=2); * get rid of GEO variable;	
		* test for each zone if any of the listed countries belongs to it;
		%do _i=1 %to %list_length(&zone);
			%let _zone=%scan(&zone, &_i);
			%do _k=1 %to %list_length(&ctry);
				%ctry_in_zone(%scan(&ctry, &_k), &_zone, _ans_=_ans, time=&time, var=&LABGEO, cds_ctryxzone=&cds_ctryxzone, clib=&clib);
				%if &_ans=1 and %list_find(&lzone, &_zone) <=0 %then %do;
					%let lzone=&lzone &_zone;
				%end;
			%end;
		%end;
		%let &_zone_=&lzone;
	%end;

	%exit:
%mend ctry_to_zone;


%macro _example_ctry_to_zone;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local val ctry ozone;

	%let ctry=DUMMYZONE;      /* country not in &cds_ctryxzone dataset */   
	%let year=2010;
	%put (i) for ctry=&ctry and year=&year ...;
	%ctry_to_zone(&ctry, time=&year, _zone_ =val);
	%let ozone=;
	%if &val EQ &ozone  %then 	%put OK: TEST PASSED - Dummy test: returns nothing;
	%else 				        %put ERROR: TEST FAILED - Dummy test: returns something;

	%let ctry= AT BE;
	%let year=2004;
	%put;
	%put (ii) for ctry=&ctry and year=&year ...;
	%ctry_to_zone(&ctry, time=&year, _zone_ =val);
	%let ozone=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU07 EU09 EU10 EU12 EU15 EU25 EU27 EU28;
	%if &val EQ &ozone %then 	%put OK: TEST PASSED - returns: %bquote(&ozone);
	%else 						%put ERROR: TEST FAILED - wrong list returned;

    %let year=2015;
	%let ctry=BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO HR;
	%put;
	%put (iii) for ctry=&ctry and year=&year ...;
	%ctry_to_zone(&ctry, time=&year, _zone_ =val);
	%let ozone=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU07 EU09 EU10 EU12 EU15 EU25 EU27 EU28;
	%if &val EQ &ozone %then 	%put OK: TEST PASSED - returns: %bquote(&ozone);
	%else 						%put ERROR: TEST FAILED - wrong list returned; 

	%let year=2014;
	%let ctry=MK;      /* existing country code but not in &cds_ctryxzone dataset */
	%let val=;  /*reset ... */  
	%put;
	%put (iv) for ctry=&ctry and year=&year ...;
	%ctry_to_zone(&ctry, time=&year, _zone_ =val);
	%if %macro_isblank(val) %then 	%put OK: TEST PASSED - returns: %bquote(&ozone);
	%else 							%put ERROR: TEST FAILED - wrong list returned; 
 
	%put;
%mend _example_ctry_to_zone;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ctry_to_zone;  
*/

/** \endcond */
