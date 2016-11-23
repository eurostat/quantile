/* Set of rules (defined as macros) based on the considered indicators for testing
prior to the upload of LDB indicators.

Syntax
------
	%let ind=%rule_tab_rename(tab);
	%let years=rule_tab_adhoc(tab, years);
	%rule_tab_filter(dsn, tab);

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
	; /* do nothing */
	&years 
%mend rule_tab_adhoc;

%macro rule_tab_filter(dsn, tab);

	%let Utab=%upcase(&tab);

 	%if &Utab=LI21 or &Utab=LI23 or &Utab=LI24 or &Utab=LI51 %then %do; 
		DATA &dsn;
			set &dsn;
			where time > 2006;
		run;	
	%end;
	/* %else: do nothing */

	%if &Utab=LI21 or &Utab=LI23 or &Utab=LI24 or &Utab=LI51 or &Utab=DI30A or &Utab=DI30B or &Utab=DI30C %then %do; 
		DATA &dsn;
			set &dsn;
			if (time in (2008,2009,2010) and geo="FR") then delete;
		run;	
	%end;
	/* %else: do nothing */

%mend rule_tab_filter;


%macro _test_rules_indicator;
;
%mend _test_rules_indicator;
