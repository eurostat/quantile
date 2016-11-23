/** 
## ctry_select {#sas_ctry_select}
Return a table storing the list of countries available in a given dataset and for a given
year, or a subsample of it. 

	%ctry_select(idsn, ctry_list, year, odsn, 
				 sampsize=0, force_overwrite=no, ilib=, olib=);

### Arguments
* `idsn` : input reference dataset;
* `ctry_list` : list of (comma-separated) strings of countries ISO-codes represented 
	in-between quotes (_.e.g._, produced as the output of `%zone_to_ctry`);
* `year` : year to consider for the selection of country;
* `sampsize` : (_option_) when >0, only a (randomly chosen) subsample of the countries 
	available in `idsn` is stored in the output table `odsn` (see below); default: 0, 
	_i.e._ no sampling is performed; see also the macro [%ds_sample](@ref sas_ds_sample);
* `force_overwrite` : (_option_) boolean argument set to yes when the table `odsn` is
	to be overwritten; default to `no`, _i.e._ the new selection is appended to the table
	if it already exists;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` 
	is used.
 
### Returns
`odsn` : name of the output table where the list of countries is stored.

### Example
Run macro `%%_example_ctry_select` for examples.

### See also
[%ds_sample](@ref sas_ds_sample).
*/ /** \cond */

%macro ctry_select(/*input*/  idsn, ctry_list, time, 
				   /*output*/ odsn,
				   /*option*/ sampsize=0, force_overwrite=no, ilib=, olib=);
	%if %macro_isblank(ilib) %then 	%let ilib=WORK; 
	%if %macro_isblank(olib) %then 	%let olib=&ilib; 

	%local _dsn s_dsn;
	%let _dsn=TMP_%upcase(&sysmacroname);

	/* looking through the dataset (idsn) in year (time), define among the countries of (ctry_list)
	 * the list (subset) of countries which are available */ 
	PROC SQL noprint;
		CREATE TABLE &_dsn as 
			SELECT distinct time, geo 
			FROM &ilib..&idsn as &idsn
			/* if ever, some day, we decide to compute aggregate of NUTS: 
			WHERE time = &time and substr(geo,1,2) in &ctry_list; 
			 * that will not happen anytime soon... */
			WHERE time = &time and geo in &ctry_list;
			/* check how many of those: not needed anymore 
			SELECT count(geo) as N into :ctry_part_n 
			from &olib..&odsn; */
		quit;

	/* possibly subsample: consider only a party of the available countries */
	%if &sampsize>0 %then %do;	
		%let s_dsn=s_&_dsn;
		/* perform the simple sampling */
		%let var=time geo; /* not really useful */
		%ds_sample(&_dsn, &s_dsn, sampsize=&sampsize, var=&var, method=SRS, rep=1, lib=WORK);
		/* "rename" */
		DATA &_dsn;
			SET &s_dsn;
		run;
		%work_clean(s_dsn)	
	%end;
	/* note that the case: sampsize=0 is regarded as if sampsize=nobs, i.e. all countries are selected */

	/* create or append the new observations */
	DATA &olib..&odsn;
		SET
		%if %ds_check(&odsn, lib=&olib)=0 /*%sysfunc(exist(&odsn))*/ and &force_overwrite=no %then %do;
			/* output the original dataset */
			&olib..&odsn
		%end;
		&_dsn;
	run;

	/* result is returned in &_ctry_part_ 
	%var_to_clist(&odsn, geo, lib=WORK, _varclst_=&_ctry_part_, num=&ctry_part_n, lib=&olib);
	* this is now done outside!
	*/

	/* clean */
	/*PROC DATASETS lib=WORK nolist; delete &_dsn; quit;*/
	%work_clean(&_dsn)

%mend ctry_select;


/* test the selection of countries */
%macro _example_ctry_select;  
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	libname rdb "&G_PING_C_RDB"; /* "&eusilc/IDB_RDB_TEST/C_RDB"; */ 

	%let ctry_tab=TMP%upcase(&sysmacroname);

	%let dsn=LI01;
	%put For the dataset dsn=&dsn ...;

	%let ctry_glob=("AT","BE","BG","CY","CZ","DE","DK","EE","ES","FI","FR","EL","HU","IE",
					"IT","LT","LU","LV","MT","NL","PL","PT","RO","SE","SI","SK","UK","HR");	
	/* instead of manually defining ctry_glob, we could use:
		%local ctry_glob;
		%zone_to_ctry(EU28, time=2016, _ctrylst_=ctry_glob);
	 */ 

	%let year1=2015;
	%put (i) The table &ctry_tab of countries present in &year1 is created;
	%ctry_select(&dsn, &ctry_glob, &year1, &ctry_tab, ilib=rdb);

	%let year2=2014;
	%put the table &ctry_tab of countries present in &year2 is appended;
	%ctry_select(&dsn, &ctry_glob, &year2, &ctry_tab, ilib=rdb);
	%ds_print(&ctry_tab);

	%local ctry_part;
	%var_to_list(&ctry_tab, geo, _varlst_=ctry_part);
	%put the list of EU28 countries available in years &year1 and &year2 is (note duplicated countries present in both years): &ctry_part;

	%work_clean(&ctry_tab);

	%put (ii) The table &ctry_tab of countries present in &year1 is reset like before;
	%ctry_select(&dsn, &ctry_glob, &year1, &ctry_tab, ilib=rdb);
	%ds_print(&ctry_tab);

	%let sampsize=3; 
	%put a list of &sampsize randomly chosen countries from &year2 is appended;
	%ctry_select(&dsn, &ctry_glob, &year2, &ctry_tab, sampsize=&sampsize, ilib=rdb);
	%ds_print(&ctry_tab);

	%var_to_list(&ctry_tab, geo, _varlst_=ctry_part);
	%put a list of countries available in year &year1 and randomly chosen in &year2 is: &ctry_part;

	%work_clean(&ctry_tab);
%mend _example_ctry_select;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ctry_select;  
*/

/** \endcond */
