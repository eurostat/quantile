/* Set of rules (defined as macros) based on the considered indicators for testing
prior to the upload of RDB indicators.

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
	%let Utab=%upcase(&tab);

	%if       &Utab=PNS2			%then  	%let tab=PNP2; /* rename it already with capital letters... */
	%else %if &Utab=PNS11 			%then 	%let tab=PNP10;
	%else %if &Utab=PNP11 			%then 	%let tab=PNP3;

	&tab
%mend rule_tab_rename;

%macro rule_tab_adhoc(tab, years);
	; /* do nothing */
	&years 
%mend rule_tab_adhoc;

%macro rule_tab_filter(dsn, tab);

	%let Utab=%upcase(&tab);

	%if &Utab=OTH01 or &Utab=OTH02 or &Utab=OTH03 or &Utab=OTH04 or &Utab=OTH05 or &Utab=OTH06 %then %do; 
	/* because we suppose that rule_ind_filter is applied after rule_ind_rename, the test is made
	 * already on "OTH*"-like variables, and not just "OT*"-like ones (e.g., testOTH01 instead of OT01)
		%if &Utab=OT01 or &Utab=OT02 or &Utab=OT03 or &Utab=OT04 or &Utab=OT05 or &Utab=OT06 %then %do; 
	 * that's why the code above has been modified */
		DATA &dsn;
			set &dsn;
			where indic_il = "LI_R_MD60";
			indic_il = "TOTAL";
			ivalue = totpop;
			output;
			indic_il = "POOR";
			ivalue = poorpop;
			output;
		run;
	%end;

	%else %if &Utab=PN30 %then %do; 
		DATA &dsn;
			set &dsn;
			ivalue = totpop;
		run;
	%end;

	%else %if &Utab=PN31 %then %do; 
		DATA &dsn;
			set &dsn;
			where tenure not in ("OWN_NL", "OWN_L"); 
			ivalue = totpop;
		run;
	%end;

	%else %if &Utab=PN21 %then %do; 
		DATA &dsn;
			set &dsn;
			where tenure not in ("OWN_NL", "OWN_L"); 
		run;
	%end;

	%else %if &Utab=PNP2 %then %do; 
		DATA &dsn;
			set &dsn;
			where indic_il = ("R_GE65_LT65"); 
		run;
	%end;

	%else %if &Utab=PNS2 %then %do; 
		DATA &dsn;
			set &dsn;
			where indic_il = ("R_GE60_LT60"); 
		run;
	%end;

	%else %if &Utab=PNP9 %then %do; 
		DATA &dsn;
			set &dsn;
			where hhtyp = "A1"; 
		run;
	%end;

	%else %if &Utab=PNP10 %then %do; 
		DATA &dsn;
			set &dsn;
			where indic_il = ("R_GE65_LT65") and hhtyp = "A1"; 
		run;
	%end;

	%else %if &Utab=PNS11 %then %do; 
		DATA &dsn;
			set &dsn;
			where indic_il in ("R_GE60_LT60","R_GE75_LT75") and hhtyp = "A1"; 
		run;
	%end;

	%else %if &Utab=LI22 %then %do; 
		DATA &dsn;
			set &dsn;
			where geo not in ("EU25", "EU27",  "NMS10", "NMS12", "BG", "RO", "FR"); 
		run;
	%end;

	/* %else %if &Utab=LVHO07A or &Utab=LVHO07B or &Utab=LVHO07A or &Utab=LVHO07C or &Utab=LVHO07D or 
		&Utab=LVHO07E or &Utab=LVHO08A or &Utab=LVHO08B %then %do; 
		DATA &dsn;
			set &dsn;
			where geo ne ("DE");
		run;
	%end; */

	/* else: do nothing */
%mend rule_tab_filter;


%macro _test_rules_indicator;
;
%mend _test_rules_indicator;
