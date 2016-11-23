/**
## silc_var_deprivation {#sas_silc_var_deprivation}
Compute common EU-SILC material deprivation variables for longitudinal dataset. 

	% silc_var_deprivation(survey, geo, time, odsn, 
					idir=, olib=, n=3, n_sev=4, n_ext=5, 
					cds_transxyear=&G_PING_TRANSMISSIONxYEAR, clib=&G_PING_LIBCFG);
 
### Arguments
* `survey` : type of the survey; this can be any of the character values defined through the 
	global variable `G_PING_SURVEYTYPES`, _i.e._:
		+ `X`. `C` or `CROSS` for a cross-sectional survey,
		+ `L` or `LONG` for a longitudinal survey,
		+ `E` or `EARLY` for an early survey,
* `geo` 	: countries list;
* `time` 	: year  list;
* `odsn` 	: (_option_) name of output dataset;
* `n` 		: (_option_) number of items used as threshold for deprived condition; by default, 
	`n` is set to the value of the global variable `G_PING_DEPR_N` (_i.e._, `n=3`);
* `n_sev` 	: (_option_) number of items used as threshold for severe deprived condition; by 
	default, `n_sev` is set to the value of the global variable `G_PING_DEPR_N_SEV` (_i.e._, 
	`n_sev=4`);
* `n_ext`	: (_option_) number of items used as threshold for extreme deprived condition; by 
	default, `n_ext` is set to the value of the global variable `G_PING_DEPR_N_EXT` (_i.e._, 
	`n_ext=5`);
* `olib`    : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is used.

### Returns
In dataset `dsn`, the variables `deprived`, `sev_dep` and `ext_dep` defined over the population 
as follows:
+ for material deprivation `deprived`:
| value | description |  condition              | 
|:-----:|:------------|:------------------------|
|	0	| not deprived|	lack <  `n` item(s)     |
|	1	| deprived    |	lack >= `n` item(s)     |

+ for severe material deprivation `sev_dep`:
| value | description |  condition              | 
|:-----:|:------------|:------------------------|
|	0	| not deprived|	lack <  `n_sev` item(s) |
|	1	| deprived    | lack >= `n_sev` item(s) |
		
+ for extreme material deprivation  `ext_dep`:
| value | description |  condition              | 
|:-----:|:------------|:------------------------|
|	0	| not deprived| lack <  `n_ext` item(s) |
|	1	| deprived    |	lack >= `n_ext` item(s) |
		
### Examples
We can run the macro `%%silc_var_deprivation` with:

    %let geo=AT;
    %let time=2010;
    %silc_var_deprivation(dsn, &geo, &time);

returns in `dsn` the following values for the `deprived`, `sev_sep` and `ext_dep` variables:
| HB010 | HB020 | HB030 | deprived | sev_dep | ext_dep|
|-------|-------|-------|----------|---------|--------| 
| 2010  |  AT   |2658500|	0      |   	0    |   0    |
| 2010  |  AT   |2658700|   1      |    0    |   0    |
| ...   |  ..   |  ...  |  ...     |   ...   |  ...   |  
Similarly, we can run the macro with:

	%let geo=AT BE;
	%let time=2013;
	%let n_ext=8;
	%silc_var_deprivation(dsn, &geo, &time, n_ext=&n_ext);

returns in `dsn` the following values for the `deprived`, `sev_sep` and `ext_dep` variables:
| HB010 | HB020 | HB030 | deprived | sev_dep | ext_dep|
|-------|-------|-------|----------|---------|--------| 
| 2010  |  AT   |2658500|	0      |   	0    |   0    |
| 2010  |  BE   |4924400|   0      |    0    |   0    |
| 2011  |  AT   |2658500|	0      |   	0    |   0    |
| 2011  |  BE   |4924400|   0      |    0    |   0    |
| ...   |  ..   |  ...  |  ...     |   ...   |  ...   |  

Run `%%_example_silc_var_deprivation` for more examples.

### See also
[%ds_check](@ref sas_ds_check), [%macro_isblank](@ref sas_macro_isblank).
*/ /** \cond */

%macro silc_var_deprivation(survey		/* Type of survey								(REQ) */
							, time	    /* Year  of interest    	                    (REQ) */
							, geo       /* Countries of interest                        (REQ) */
							, odsn 		/* Name of  output dataset	                    (REQ) */
							, n=    	/* Threshold of deprived condition              (OPT)*/
							, n_sev=   	/* Threshold of several deprived  condition     (OPT)*/
							, n_ext=   	/* Threshold of extreme deprived condition    	(OPT)*/
							, idir=
			        		, olib=     /* Name of the output library  					(OPT) */
							, cds_transxyear=
							, clib=
							);
    %local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _igeo     	/* loop increment */
 		idsn
		_idsn
	   	_geo        	/* temporary single variable for country */
		_dsn    	   	/* temporary dataset */
		yy 
		path
		_path;	
	%let _dsn=_TMP&_mac;

	/* GEO, TIME: check that both parameters have been actually passed */
  	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(geo) EQ 1, mac=&_mac,		
			txt=!!! Parameter GEO must be passed !!!)
    		or %error_handle(ErrorInputParameter, 
				%macro_isblank(time) EQ 1, mac=&_mac,		
				txt=!!! Parameter TIME must be passed !!!)
			or %error_handle(ErrorInputParameter, 
				%macro_isblank(odsn) EQ 1, mac=&_mac,		
				txt=!!! Parameter ODSN must be passed !!!) %then
    	%goto exit;

	/* N, N_SEV, N_EXT: check/set input threhold parameters */
	%if %macro_isblank(n)  %then %do;
		%if %symexist(G_PING_VAR_DEPR_N) %then 		%let n=&G_PING_VAR_DEPR_N;
		%else										%let n=3;
	%end;
	%if %macro_isblank(n_sev)  %then %do;
		%if %symexist(G_PING_VAR_DEPR_N_SEV) %then 	%let n_sev=&G_PING_VAR_DEPR_N_SEV;
		%else										%let n_sev=4;
	%end;
	%if %macro_isblank(n_ext)  %then %do;
		%if %symexist(G_PING_VAR_DEPR_N_EXT) %then 	%let n_ext=&G_PING_VAR_DEPR_N_EXT;
		%else										%let n_ext=5;
	%end;

	/* OLIB, ODSN: check/set output dataset */
	%if %macro_isblank(olib)     %then 	    	%let olib=WORK;
	%if %error_handle(ExistingOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,
			txt=%quote(! Output table already exist - Will be overwritten !), verb=warn) %then 
		%goto warning;
	%warning:
	
	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%silc_db_locate(&survey, &time, &geo, db=H, _path_=path, _ds_=idsn, dir=&idir, 
					cds_transxyear=&cds_transxyear, clib=&clib);

	/* loop over the list of input geo */
	%do _igeo=1 %to %list_length(&geo); 

		%let _geo=%scan(&geo, &_igeo);
		%let _idsn=%scan(&idsn, &_igeo);
		%let _path=%scan(&path, &_igeo, %quote( ));

		libname _ilib "&_path"; 

    	%if %error_handle(WarningInputLibrary, 
		   		%lib_check(_ilib) NE 0, mac=&_mac,		
	  	   		txt=%quote(! Input library %upcase(_ilib) not recognised - Skip !), verb=warn) 
				or %error_handle(WarningInputParameter, 
					%ds_check(&_idsn, lib=_ilib) NE 0, mac=&_mac,		
			   		txt=%quote(! File %upcase(&_idsn) does not exist - Skip !), verb=warn) %then
	    	%goto next;

   		PROC SQL noprint;
	     	CREATE TABLE WORK.&_dsn  AS 	
			SELECT DISTINCT HB010, 
				HB020, 
				HB030, 
		      	(case when sum(L1, L2, L3, L4, L5, L6, L7, L8, L9) ge &n  then 1 else 0 end) as deprived,
		      	(case when sum(L1, L2, L3, L4, L5, L6, L7, L8, L9) ge &n_sev then 1 else 0 end) as sev_dep,
		      	(case when sum(L1, L2, L3, L4, L5, L6, L7, L8, L9) ge &n_ext then 1 else 0 end) as ext_dep
	     	FROM 
				(
				SELECT DISTINCT *,
			   		%if &time<2009 %then %do;
				      (case when HS010=1 or HS020=1 or HS030=1 then 1 else 0 end) as L1,
			 		%end;
			 		%else %do;
		 		      (case when HS011=1 or HS021=1 or HS031=1 then 1 else 0 end) as L1,
					%end;
				      (case when HS040=2 then 1 else 0 end) as L2,
					  (case when HS050=2 then 1 else 0 end) as L3,
					  (case when HS060=2 then 1 else 0 end) as L4,
					  (case when HS070=2 then 1 else 0 end) as L5,
					  (case when HS080=2 then 1 else 0 end) as L6,
					  (case when HS100=2 then 1 else 0 end) as L7,
					  (case when HS110=2 then 1 else 0 end) as L8,
					  (case when HH050=2 then 1 else 0 end) as L9
		  	 	FROM _ilib.&_idsn
				)
		quit;

		libname _ilib clear;

		DATA &olib..&odsn; 
     	  	 SET
	     	 %if %ds_check(&odsn, lib=&olib) eq 0 %then %do;
         	    &olib..&odsn
	     	 %end;
		     	WORK.&_dsn; 	
		run;
		%next:
	%end; 

	%work_clean(&_dsn);

	%exit:
%mend silc_var_deprivation;


%macro _example_silc_var_deprivation;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local geo time odsn;

	%let geo=;
	%let time=2013;
	%put;
	%put (i) Dummy test with GEO is missing;
	%silc_var_deprivation(L, &time, &geo);

  	%let geo=AT;
	%let time=;
	%put;
	%put (ii) Dummy test with TIME missing;
	%silc_var_deprivation(L, &time, &geo);

  	%let geo=AT;
	%let time=2013;
	%let odsn=;
	%put;
	%put (ii) Dummy test with ODSN is missing;
	%silc_var_deprivation(L, &time, &geo, &odsn);

	%let odsn=_TMP_DEPRIVATION; /* sorry, I am too long, come disse Rocco... */

	%let geo=AT;
	%let time=2013;
	%put;
	%put (iii) Calculate material deprivation variables for year=&time and a single geo=&geo;
	%silc_var_deprivation(L, &time, &geo, &odsn._1);
   	%ds_print(&odsn._1, head=10);

	%let geo_=AT BE;
	%let time=2013;
	%let n_ext=8;
	%put;
	%put (iv) Calculate material deprivation variables for year=&time and geo=&geo, and n_ext=&n_ext;
	%silc_var_deprivation(L, &time, &geo, &odsn._2, n_ext=&n_ext);
	DATA &odsn._2;
		 SET &odsn._2;
	     _time=lag1(HB010);  
    run;
	DATA &odsn._2(drop=_time);
		 SET &odsn._2;
	 	 WHERE _time ne HB010;
	run;
	PROC SORT data=&odsn._2;
		 BY  HB010 HB020;
	run;
   	%ds_print(&odsn._2, head=10);
	
	%put;
 
    %work_clean(&odsn._1, &odsn._2);
%mend _example_silc_var_deprivation;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_var_deprivation;
*/

/** \endcond */
