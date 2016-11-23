/* Set of rules (as functions and subroutines) for setting the reference value of a
RDB2 indicator taking into account its reliability and associated flags.

Syntax
------
	call rule_ref_value(ivalue, iflag, unrel, unit, refval);

Note
----
The reference value is returned as a string, e.g. of the form ivalue+iflag.

Examples
--------
run _test_rules_reference for examples of use.
	
Credit
------ 
Bernard, B. <mailto: bernard.bruno@ec.europa.eu> 
Grazzini, J. <mailto: jacopo.grazzini@ec.europa.eu>
Grillo, M. <mailto: Marina.Grillo@arhs-developments.com>
*/

%global FORMAT_IVALUE; 
%let FORMAT_IVALUE=10.1; /* format definition */

/*%macro rules_reference;*/
PROC FCMP
outlib=WORK.funcs.rules; 

subroutine rule_ref_value(ivalue, iflag$, unrel, unit$, refval$); 
	/* note: refval is a char as values sent to Eurobase are char */
	outargs refval;

	/* added the condition for unit=THS_PER */
	if unrel = 0 then do;
		if      ivalue =.            then refval = "0.0";
		else if round(ivalue,0.1)=0  then refval = "0.0n";
		else if unit ='THS_PER'      then refval = round(ivalue)||iflag; 
		else                              refval = compress(put(ivalue,&FORMAT_IVALUE)||iflag); /* compress ???????? */            
	end;

	else if unrel = 1 then do; 
		if      ivalue =.            then refval = "0u"; 
		else if unit ='THS_PER'      then refval = compress(round(ivalue)||iflag||"u"); 
		else                              refval = compress(put(ivalue,&FORMAT_IVALUE)||iflag||"u"); 
	end;

	else if unrel = 2 then do; 
		if ivalue =. and ntot=0      then refval = ":z";
		else                              refval = ":u";
	end;

	else if unrel in (3,4) then do; 
		if      ivalue =.            then refval = "0e"; 
		else if unit ='THS_PER'      then refval = compress(round(ivalue)||iflag||"e"); 
    	else                              refval = compress(put(ivalue,&FORMAT_IVALUE)||iflag||"e");
	end;
 
	else if unrel = 5 then refval = ":";
	/* s-flag replaced by e-flag oon 5th Feb 2013 */

	/* return (refval); */
endsub;

run;
/*%mend rules_reference;*/


%macro _test_rules_reference;

	options cmplib=WORK.funcs;

	DATA ebdsn;  
		array geos{10} $4 _TEMPORARY_  ('EU15',    'EU25',    'EA13',   'DE',     'FR',      'EL',     'IT',      'DK',     'SE',     'BG' );
		array values{10}  _TEMPORARY_  (1000,      20000,     3.5454,   .,        500.22,    6.343,    7.,        .,        9.99,     100.0 );
		array iflags{10} $ _TEMPORARY_ ("b",       " ",       " ",      " ",      "b",       "b",      " ",       " ",      "b",      " " );
		array unrels{10}  _TEMPORARY_  (0,         0,         1,        4,        1,         0,        2,         3,        0,        5 );
		array units{10} $ _TEMPORARY_  ("THS_PER", "THS_PER", "PC_POP", "PC_POP", "THS_PER", "PC_POP", "PC_POP",  "PC_POP", "PC_POP", "THS_PER" );
		drop n;
		do n = 1 to 10;
			geo = geos{n};
			ivalue = values{n};
			iflag = iflags{n};
			unrel = unrels{n};
			unit = units{n};
		output;
		end;
	run;

	DATA ebdsn;
		set ebdsn;
		length refval $ 50;
		call rule_value_flag(ivalue, iflag, unrel, unit, refval);
		/* see rule_geotime.sas
		call rule_value_delete(geo, refval); */
	run;	

%mend _test_rules_reference;
/* %_test_rules_reference; */



