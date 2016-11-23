/* Set of rules (defined as a macro) for defining the keys/encoding name of
an indicator when sent to Eurobase. 

Syntax
------
	%let keys=rule_keys(dsn);

Inputs
------
- dsn : a dataset name;
  
Returns
-------
- keys : the string used to identify a dataset when submitting it to Eurobase.

Examples
--------
run _test_rule_keys for examples of use, e.g.:
	- for indicator DI05, the keys are "ID_KEYS=SAS,ILC,DI05",
 	- for indicator hlth_silc_18, the keys are "ID_KEYS=HLTH_SILC_18",
	- ...

Credit
------ 
Grazzini, J. <mailto: jacopo.grazzini@ec.europa.eu>
*/

%let HLTH_CODE=hlth_silc;

%macro rule_key_code(tab, _keys_=);

	%let Utab=%upcase(&tab);

	%if %substr(&Utab,1,2)=OT %then 	 	%let Utab=OTH%substr(&Utab,3,2);
	%else %if %substr(&Utab,1,2)=PN %then 	%let Utab=ILC_&Utab;
	%else %if &Utab=SIC5 			%then 	%let Utab=LI22;
	%else %if &Utab=OV9B1 			%then 	%let Utab=SIP8;
	%else %if &Utab=OV9B2 			%then 	%let Utab=SIS4;

	%let keys="SAS,ILC,&Utab"; /* common case */

	%let len=%length(&HLTH_CODE);
	%if %length(&Utab) > &len  %then %do;
		%if %sysfunc(substr(&Utab,1,&len))=%upcase(&HLTH_CODE) %then %do; 
			%let keys="&Utab";
		%end;
	%end;

	data _null_;
		call symput("&_keys_",&keys);
	run;
	/* %quote(&keys) */
%mend rule_key_code;


%macro _test_rules_key;	
	%local k;

	%let tab=DI05;		
	%put (i) test the keys output for a common variable: &tab;
	%rule_key_code(&tab,_keys_=k);
	%put for variable &tab, the Eurobase keys are &k;

	%let tab=hlth_silc_18;		
	%put (ii) test the keys output for a health related variable: &tab;
	%rule_key_code(&tab,_keys_=k);
	%put for variable &tab, the Eurobase keys are &k;

	%let tab=OV9B1;		
	%put (iii) test the keys output for a special variable: &tab;
	%rule_key_code(&tab,_keys_=k);
	%put for variable &tab, the Eurobase keys are &k;
%mend _test_rules_key;
/* %_test_rules_key; */
