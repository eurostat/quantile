/* Set of rules (as functions and subroutines) for setting the reference value of a
RDB indicator taking into account its reliability and associated flags.

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

%global FORMAT_IVALUE LENGHT_IVALUE; 
%let FORMAT_IVALUE=10.1; /* format definition */
%let FORMAT_IVALUE_SPECIAL=12.; /* special format definition */

/* WHERE?!!!
%if &tab=LI01 %then %let rd=12.;
%else %if &tab=PNP2 or &tab=PNP3 or &tab=PNS2 or &tab=PNP10 or &tab=PNP11 or &tab=PNS11 %then %let rd=10.2;
%else %let rd=10.1;
*/

/*%macro rules_reference;*/
PROC FCMP
outlib=WORK.funcs.rules; 

subroutine rule_ref_value(ivalue, iflag$, unrel, unit$, refval$); 
	/* note: refval is a char as values sent to Eurobase are char */
	outargs refval, ivalue;

	if ivalue=. then ivalue=0;

	if unit in ("THS_PER", "THS_CD08") or indic_il in ("TC", "MEI_E", "MED_E") then do;
		if      unrel = 0 then refval = put(ivalue,&FORMAT_IVALUE_SPECIAL)||iflag;
		else if unrel = 1 then refval = compress(put(ivalue,&FORMAT_IVALUE_SPECIAL)!!iflag!!"u"); 
		else if unrel = 2 then refval = ":u";
		else if unrel = 3 then refval = compress(put(ivalue,&FORMAT_IVALUE_SPECIAL)||iflag||"e"); 
	end;

	else do;
		if      unrel = 0 then refval = put(ivalue,&FORMAT_IVALUE)||iflag;
		else if unrel = 1 then refval = compress(put(ivalue,&FORMAT_IVALUE)!!iflag!!"u"); 
		else if unrel = 2 then refval = ":u";
		else if unrel = 3 then refval = compress(put(ivalue,&FORMAT_IVALUE)||iflag||"e"); 
	end;
	/*  s-flag replaced by e-flag on 5th Feb 2013   */

endsub;

run;
/*%mend rules_reference;*/


%macro _test_rules_reference;
;
%mend _test_rules_reference;
/* %_test_rules_reference; */



