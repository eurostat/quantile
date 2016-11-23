/*
*/

%let LENGHT_IVALUE=50; /* lenght of the reference value (as it is returned as a string) */

%macro ncfile_write(ncfile, dsn, tab, geo, yyyy);

	/* define the fields of the indicator to write in the file
	 */
	%local dimcol;
	%local dimcolC;
	%define_dimensions(&tab, lib=&lib, _dimcol_=dimcol, _dimcolC_=dimcolC);
	%let dimcol=%rule_dimcol(&tab, %quote(&dimcol));
	%let dimcolC=%rule_dimcolC(&tab, %quote(&dimcolC));
	
	/* define the keys/encoding name of the indicators sent to Eurobase
	 * typically, indicators keys are encoded  as "SAS,ILC,<indicator_name>", except
 	 * health indicators encoded as "HLTH_SILC_<indicator_number>" 	          */ 
	%local idkeys;
	%rules_key(&tab, _keys_=idkeys);

	/* create NC file */	
	%local ebfile;
	filename ebfile "&ncfile" TERMSTR=&EBFILE_TERMSTR;

	/* DATA _null_;
		set &lib..&tab(where=(time in (&yyyy) and rule_fmt_geo2cc(geo) in (&geo))) end=last;
	run; */

	DATA _null_;
		set &dsn end=last;
		/* set &lib..&tab(where=(time in (&yyyy) and rule_fmt_geo2cc(geo) in (&geo))) end=last; */

		length refval $ &LENGHT_IVALUE; 
		file ebfile;
		
		if _N_ = 1 then do;
			put "&EBFILE_HEADER";
			put "&EBFILE_KEYS=&idkeys";
			put "&EBFILE_FIELDS=&dimcolC";
			put "&EBFILE_MODE=&mode";
		end;
		
		/* write the data only no exception (based on geo/time) applies */
		if rule_geo_ignore(geo, time) then do; 
			/* deal with NUTS? geo names
		 	 * concerned indicators are: PEPS11, LI41, MDDD21, LVHL21 (for RDB) or LVHO04N (for RDB2) */
			call rule_fmt_gr2el(geo);
			/* effectively write down the reference value */
			call rule_ref_value(ivalue, iflag, unrel, unit, refval);
			/* apply the delete rule for given zones */
			call rule_geo_delete(geo, refval);
			/* add more rules ? */
	        put &dimcol refval;
		end;
		/* else do nothing */

		if last then put "&EBFILE_TAIL";
	run;

%mend ncfile_write;


%macro _test_ncfile_write;
;
%mend _test_ncfile_write;

