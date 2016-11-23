/* Set of rules (defined as functions and subroutines) for setting of geographic 
zones/countries and time/year variables prior to the upload of RDB2 indicators.

Syntax
------
	keep_zone = rule_geo_ignore(geo, time);
	call rule_geo_delete(geo, ivalue);

Note
----
Rules concern the skipping of given indicators/aggregates over some geographic zones for some 
periods, e.g. for:
	- EU15, EU25, EA, EA12, EA13, EA15, NMS10, EA16 over time < 2005,
	- EU27, RO, NMS12 over time < 2007,
data are ignored (not calculated), while for:
	- EU15, EU25, NMS10, NMS12, EA12, EA13, EA15, EA16, EA17 overall, 
data are set to missing.

Examples
--------
run _test_rules_zone for examples of use.
	
Credit
------ 
Bernard, B. <mailto: bernard.bruno@ec.europa.eu> 
Grazzini, J. <mailto: jacopo.grazzini@ec.europa.eu>
Grillo, M. <mailto: Marina.Grillo@arhs-developments.com>
*/

/* %macro rules_zone; */
PROC FCMP
outlib=WORK.funcs.rules; 


/** Ignore some geographic zones for given period */
function rule_geo_ignore(geo$, time);
	if      geo='EU15'  and time < 2005  then return(0);
	else if geo='EU25'  and time < 2005  then return(0);
 	else if geo='EU27'  and time < 2007  then return(0);
	else if geo='EA'    and time < 2005  then return(0);
	else if geo='EA12'  and time < 2005  then return(0);
	else if geo='EA13'  and time < 2005  then return(0);
	else if geo='EA15'  and time < 2005  then return(0);
	else if geo='NMS10' and time < 2005  then return(0);
	else if geo='EA16'  and time < 2005  then return(0);
	else if geo='NMS12' and time < 2007  then return(0);
	else if geo='RO'    and time < 2007  then return(0);
	/* if (geo in ("EU15", "EU25", "EA", "EA12", "EA13", "EA15", "NMS10", "EA16") and time < 2005)
	 or (geo in ("EU27", "RO", "NMS12") and time < 2007) then return(0); */
    else return(1); 
endsub;

/** Blank/delete specific geographic zones */
subroutine rule_geo_delete(geo$, refval$);
	/* note: refval is a char as values sent to Eurobase are char */
	outargs refval;
	if geo in ('EU15','EU25','NMS10','NMS12','EA12','EA13','EA15','EA16','EA17') then refval=':';
	/* else: do nothing */ 
endsub;

run;
/*%mend rules_zone;*/


%macro _test_rules_zone;
	options cmplib=WORK.funcs;

	DATA geotime;
		array refvals{9} $ _TEMPORARY_ ("1",    "2",    "3",    "4",    "5",    "6",    "7",    "8",    "9");
		array geos{9} $5 _TEMPORARY_   ('EU27', 'EU25', 'EA13', 'EU27', 'EU15', 'EA12', 'EA12', 'EU15', 'NMS12' );
		array years{9} _TEMPORARY_     (2006,   2004,   2001,   2007,   2004,   2007,   2002,   2015,   2015 );
		drop n;
		do n = 1 to 9;
			geo = geos{n};
			time = years{n};
			ivalue = refvals{n};
		output;
		end;
	run;

	DATA geotime;
		retain old_geo;
		set geotime;
		old_geo=geo;
		keep_or_not = rule_geo_ignore(geo, time); /* deals with case 1 t0 7 */
		call rule_geo_delete(geo, ivalue); /* deals with case 8 & 9 */
	run;	

%mend _test_rules_zone;
/* %_test_rules_zone; */
