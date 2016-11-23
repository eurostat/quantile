

%macro rule_tab_rename(tab);
	; /* do nothing */
	&tab
%mend rule_tab_rename;

%macro rule_tab_adhoc(tab, years);
	; /* do nothing */
	&years 
%mend rule_ind_adhoc;

%macro rule_ind_filter(dsn, tab);
	;	/* do nothing */
%mend rule_ind_filter;


%macro _test_rules_indicator;
;
%mend _test_rules_indicator;
