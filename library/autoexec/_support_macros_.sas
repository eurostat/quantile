/** \cond */

/* Generic macros used in support to request for automatic environment settings and operation
* running.
* In practice, the following macros are available:
* 	* `set_geotime`,
* 	* `run_geotime(ids, yyyy, geo, isgeo=)`,
* 	* `run_time(ids, yyyy, geos)`,
* 	* `run_table(ids, years, geos)`,
*/
	
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/
/** !!! DON'T MODIFY THE SETUP FILE BELOW !!! **/
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/

%macro set_geotime;
	%put; 
	%put --------------------------------------------------------------------------;
	%put &sysmacroname - Retrieving geo and year parameters;
	%put --------------------------------------------------------------------------;
	%put; 

	%local typegeos zones ctries;
	%local geo igeo isgeo;

	/* retrieve the list of geos */
	%egp_prompt(prompt_name=geos, ptype=string, penclose=no, pmultipl=yes, psepar=);

	/*%let geos=%clist_unquote((&geos), mark=_empty_); /* note the use of () around the variable...*/
	%str_isgeo(&geos, _geo_=geos); 

	/* retrieve the lsit of years */
	%egp_prompt(prompt_name=years, ptype=integer, penclose=no, pmultipl=yes, psepar=);
	/*%let years=%clist_unquote((&years), mark=_empty_); /* note the use of () around the variable...*/


%mend set_geotime;


/* macro generating and updating the output table &ids for:
*	- a single year &yyyy, and 
* 	- a single country/zone &geo; 
* note that in the latter case (geo is a zone), several countries may be calculated */
%macro run_geotime(ids, yyyy, geo, isgeo=);			
	%put; 
	%put --------------------------------------------------------------------------;
	%put &sysmacroname - Operation for zone/country &geo and year &yyyy;
	%put --------------------------------------------------------------------------;
	%put; 

	%local ctry ictry ans;  
	%local Qctries Qctries_in;

	/* in the case of: */
	%if &isgeo=1 /* COUNTRY */ %then
		/* - a country: the "list" of countries is just the country itself (without quotes) 
	 	 * therefore, if geo=AT, then Qctries=AT */
		%let Qctries=&geo;	/* %let Qctries=%list_quote(&geo); */
	%else %if &isgeo=2 /* ZONE */ %then %do;
		/* - a zone: the "list" of countries is retrieved from the zone name using the macro 
		* %ctry_define, then applying an unquote procedure
		* therefore, if geo=EU28, then Qctries=BE DE FR IT LU NL DK IE UK ... */
		%ctry_define(&geo, &yyyy, _ctrylst_=Qctries);
		%let Qctries=%clist_unquote(&Qctries);
	%end;
		
	/* 1. create the dataset, e.g. the table with the name like the issue (&g_ds._&ids) to be stored
	 * 	in the library used for support data (sdb) - possibly already exist 
	 * 2. create a temporary WORKing table with the same name */

	%create(&g_ds._&ids, &yyyy, &geo, lib=sdb);


	/* retrieve the list of countries which have not been processed already */
	%ds_isempty(&g_ds._&ids, var=GEO, _ans_=ans);
	%if	&ans NE 1 %then %do; 
		/* first retrieve the list of countries present in the WORKing dataset (i.e. processed already) */
		%var_to_list(&g_ds._&ids, GEO, _varlst_=Qctries_in, distinct=yes);
		/* then update the list of countries with those still to be computed by difference */
		%let Qctries_in=%list_difference(&Qctries, &Qctries_in);		
		/* this is useful when you run the calculation for a zone, e.g. EU28, after already having
		 * made the calculation for countries that do belong to the zone */ 
	%end;
	%else /* no change */
		%let Qctries_in=&Qctries;
		/* retrieve the total number #{countries to be calculated}; this will be
		 *  - 1 if you passed a country that was not calculated already 
		 *  - #{countries in the zone} - #{countries already calculated} if you passed a zone */
	/* loop over the list of countries that have not been processed yet */
	%do ictry=1 %to %list_length(&Qctries_in); /* again: this may be 1 */
		/* retrieve the country in position ictry */
		%let ctry=%list_slice(&Qctries_in, ibeg=&ictry, iend=&ictry);
		
		/*%extract(&yyyy,&weight, (%list_quote(&ctry)), idb); old*/
		%extract(&yyyy,&weight, (%list_quote(&ctry)), idb,&var,l_idb);
		/*%compute(idb, &weight,&yyyy, &ctry, &g_ds._&ids, flag=&g_flag); old */
		%compute(idb, &weight,&yyyy, &ctry,&var, &g_ds._&ids, flag=&g_flag);
	 	%update(&g_ds._&ids, &yyyy, &ctry,&var, lib=sdb);
	
	  *	%work_clean(idb);
	%end; /* end of the "%do ictry=1 %to %list_length(&Qctries_in)" loop */

	/* only in the case you passed a zone, compute the aggregate */
	%if &isgeo=2 /* ZONE */ %then %do;
		/* note that the file should already exist */
		%aggregate(&g_ds._&ids, &yyyy, &geo, (%list_quote(&Qctries)), flag=&g_flag);
		%update(&g_ds._&ids, &yyyy, &geo, lib=sdb);
	%end;

*	%work_clean(&g_ds._&ids);

%mend run_geotime;

/* macro running the operation (generation+update) for:
 * 	- one single year &yyyy, and 
 * 	- all countries/zones in &geos */
%macro run_time(ids, yyyy, geos); 
	%put; 
	%put --------------------------------------------------------------------------;
	%put &sysmacroname - Loop over %list_length(&geos) zones/countries for year &yyyy;
	%put --------------------------------------------------------------------------;
	%put; 

	%local geo igeo isgeo typegeos;

	%str_isgeo(&geos, _ans_=typegeos); 
	
	/* loop over the list of input geo parameters */
	%do igeo=1 %to %list_length(&geos);

		%let geo=%scan(&geos, &igeo);
		%let isgeo=%scan(&typegeos, &igeo);
       
		%run_geotime(&ids, &yyyy, &geo, isgeo=&isgeo);

	%end; 

%mend run_time;

/* macro running the operation (generation+update) for:
 * 	- all years in &years, and 
 * 	- all countries/zones in &geos */
%macro run_table(ids, years, geos);
	%put; 
	%put --------------------------------------------------------------------------;
	%put &sysmacroname - Loop over %list_length(&years) years for table &ids;
	%put --------------------------------------------------------------------------;
	%put; 

	%local yyyy iy;
	
	/* loop over the list of input years */
	%do iy=1 %to %list_length(&years);

		%let yyyy=%scan(&years, &iy);
		%run_time(&ids, &yyyy, &geos);

	%end; 

%mend run_table;

/** \endcond */
