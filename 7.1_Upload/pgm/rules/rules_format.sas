/* Set of rules (defined as functions and subroutines) for formatting
variables.

Syntax
------
	cc = rule_fmt_geo2cc(geo, dsn)
	call rule_fmt_gr2el(geo);

Note
----
Rules concerned:
* extraction of the geo zone;
* change of naming for given geographic zones, e.g.: 
	- Greece naming is changed from GR to EL.

Examples
--------
run _test_rules_format for examples of use.
	
Credit
------ 
Grazzini, J. <mailto: jacopo.grazzini@ec.europa.eu>
*/

/*%macro rules_format;*/

PROC FCMP
outlib=WORK.funcs.rules; 

/** Retrieve name of country from geographic identifier (deals in particular with LVHO04N
 * which contains NUTS code) */
function rule_fmt_geo2cc(geo$) $; /* declare a function returning a country code */
	if length(geo)>2 then return(substr(geo,1,2)); else return(geo);
	/* if upcase(tab)=LVHO04N then return(substr(geo,1,2)); else return(geo); */
endsub;


/** Replace GR with EL for all occurencies */
subroutine rule_fmt_gr2el(geo$);       	
	outargs geo;
	len = length(geo); 
	if /* len =2 and */ geo='GR' then 
		geo='EL';
	else if len >2 and substr(geo,1, 2)='GR' then do;
   		GEOx='EL';
   		GEOrest=substr(geo,3,len);
   		geo=cats(GEOx, GEOrest); 
		/* no need for 'drop' as variable are local to the subroutine
		drop=len; drop= GEOx; drop= GEOrest; 
		*/
	end;
	/* else: do nothing */ 
endsub;

run;
/*%mend rules_format;*/

%macro _test_rules_format;
	options cmplib=WORK.funcs;

	DATA geofmt;
		array refvals{3} $ _TEMPORARY_ ("1",    "2",    "3");
		array geos{3} $5 _TEMPORARY_   ('GR',   'EL',   'GR02');
		drop n;
		do n = 1 to 3;
			geo = geos{n};
			ivalue = refvals{n};
		output;
		end;
	run;

	DATA geofmt;
		retain old_geo;
		set geofmt;
		old_geo=geo;
		call rule_fmt_gr2el(geo); 
	run;	

%mend _test_rules_format;
/* %_test_rules_format; */
