/* Set of rules (defined as macros) based on the considered indicators for testing
prior to the upload of RDB2 indicators.

Syntax
------
	%let ind=%rule_tab_rename(tab);
	%let years=rule_tab_adhoc(tab, years);
	%rule_tab_filter(dsn, tab);

Note
----
The calculation of indicators for ad-hoc modules are limited to the year of implementation 
of the module, hence the following restrictions on years/variables apply:
	- 2011: IGTP01 and IGTP02
	- 2012: HCMH01, HCMH02, HCMH03, HCMH04, HCMH05, and HCMH06; HCMHP04, HCMP05, HCMP06 ?
	- 2013: PW01, pw02, pw05, pw08, pw09; pw03, pw04, pw05, pw06, pw07? 

Examples
--------
run _test_rules_indicator for examples of use.
	
Credit
------ 
Bernard, B. <mailto: bernard.bruno@ec.europa.eu> 
Grazzini, J. <mailto: jacopo.grazzini@ec.europa.eu>
Grillo, M. <mailto: Marina.Grillo@arhs-developments.com>
*/


%macro rule_tab_rename(tab);
	; /* do nothing */
	&tab
%mend rule_tab_rename;

%macro rule_tab_adhoc(tab, years);

	%let Utab=%upcase(&tab);

	%let x=%sysfunc(compress(%sysfunc(translate(&years,':',','))));

	/* check if 2011 exists in the years list */
	%let ii=1; 
	%let y1=%scan(&x,&ii,:); 

	%do  %while(&y1 ne );
	    %if &y1=2011 %then %do; /* ad-hoc module 2011 */
			/* %if &Utab in ("IGTP01", "IGTP02") %then %do; */
			%if (&Utab=IGTP01 or &Utab=IGTP02) %then %do;
				%let years=2011;
				%goto exit;
			%end;
		%end;
		%else %if &y1=2012 %then %do; /* ad-hoc module 2012 */
			/* %if &Utab in ("HCMH01", "HCMH02", "HCMP03", "HCMP04", "HCMP05", "HCMP06") %then %do; */
			%if &Utab=HCMH01 or &Utab=HCMH02 or &Utab=HCMP03 or &Utab=HCMP04 or &Utab=HCMP05 or &Utab=HCMP06 %then %do;
				%let years=2012;
				%goto exit;
			%end;
		%end;
		%else %if &y1=2013 %then %do; /* ad-hoc module 2013 */
			/* %if &Utab in ("PW01", "PW02", "PW05", "PW08", "PW09") %then %do; */
			%if &Utab=PW01 or &Utab=PW02 or &Utab=PW05 or &Utab=PW08 or &Utab=PW09 %then %do;
				%let years=2013; 
				%goto exit;
			%end;
		%end;
		%let ii=%eval(&ii+1);                                  
		%let y1=%scan(&x,&ii,:); 
	%end; 

	%exit: /* nothing else than return after this flag */
	;

	&years 
%mend rule_tab_adhoc;

%macro rule_tab_filter(dsn, tab);
	;	/* do nothing */
%mend rule_tab_filter;


%macro _test_rules_indicator;

	%let years=2009, 2010, 2011, 2012, 2013, 2014;

	%let tab=pw01;
	%let yyyy=%rule_tab_adhoc(&tab, %quote(&years));
	%put (i)   for ad-hoc variable &tab, the year retrieved is: &yyyy;

	%let tab=HCmp04;
	%let yyyy=%rule_tab_adhoc(&tab, %quote(&years));
	%put (ii)  for ad-hoc variable &tab, the year retrieved is: &yyyy;

	%let tab=IGTP01;
	%let yyyy=%rule_tab_adhoc(&tab, %quote(&years));
	%put (iii) for ad-hoc variable &tab, the year retrieved is: &yyyy;

	%let tab=LI01;
	%let yyyy=%rule_tab_adhoc(&tab, %quote(&years));
	%put (iv)  for primary variable &tab, the years retrieved are still: &yyyy;

%mend _test_rules_indicator;
/* %_test_rules_indicator; */
