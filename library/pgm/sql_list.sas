/** 
## sql_list {#sas_sql_list}
Transform an unformatted list of items into a SQL-compatible list of comma-separated 
and/or quote-enhanced items. 

	%let sqllist = %sql_list(list, type=);

### Note
This is nothing else than a wrapper to [%list_quote]\(@ref sas_list_quote), where parentheses
`()` are added around the output list, _i.e._ the command `%let sqllist = %%sql_list(&list)` is 
equivalent to:

	%let sqllist = (%list_quote(&list, sep=%quote( ), rep=%quote(,), mark=%str(%")));

when `list` is of type `CHAR`, otherwise, when `list` if of type `NUMERIC`:

	%let sqllist = (%list_quote(&list, sep=%quote( ), rep=%quote(,), mark=_EMPTY_));

### Examples
The simple examples below:

	%let list1=DE AT BE NL UK SE;
	%let olist1=%sql_list(&list1);
	%let list2=1 2 3 4 5 6;
	%let olist2=%sql_list(&list2);

return `olist1=("DE","AT","BE","NL","UK","SE")` and `olist2=(1,2,3,4,5,6)` respectively.

### See also
[%list_quote](@ref sas_list_quote).
*/ /** \cond */

%macro sql_list(list	/* List of items to transform into a SQL query list (REQ) */
				, type=	/* Type to force for the items in the list 			(OPT) */
				);	
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if not %macro_isblank(type) %then %do;
		%if %upcase(&type)=_SKIP_ %then goto skiptype;
		%if %upcase(&type)=NUM or %upcase(&type)=N %then 				%let type=NUMERIC;
		%else %if %upcase(&type)=CHARACTER or %upcase(&type)=C %then 	%let type=CHAR;
		%else %if %error_handle(ErrorInputParameter, 
				%par_check(%upcase(&type), type=CHAR, set=NUMERIC CHAR) NE 0, mac=&_mac,
				txt=%quote(!!! Wrong type/value for input parameter TYPE !!!)) %then 
			%goto exit; 
	%end;
	%else;
		%let type=%datatyp(%list_index(&list, 1));
	
	%let ttest=%list_ones(%list_length(&list), item=0);
	%if %error_handle(ErrorInputParameter, 
			%par_check(&list, type=&type) NE %quote(&ttest), mac=&_mac,
			txt=%quote(!!! Items in input LIST should all be of the same type !!!)) %then 
		%goto exit; 

	%skiptype:
	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%if %upcase("&type")="NUMERIC" %then %do;
		(%list_quote(&list, sep=%quote( ), rep=%quote(,), mark=_EMPTY_))
	%end;
	%else %do; /* also include the _SKIP_ case */
		(%list_quote(&list, sep=%quote( ), rep=%quote(,), mark=%str(%")))
	%end;

	%exit:
%mend sql_list;


%macro _example_sql_list;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let list=DE AT BE NL UK SE;
	%put;
	%put (i) SQL quote of an arbitrary list=&list ...;
	%let oclist=("DE","AT","BE","NL","UK","SE");
	%if %sql_list(&list) EQ &oclist %then 	%put OK: TEST PASSED - Returns: %bquote(&oclist);
	%else 									%put ERROR: TEST FAILED - Wrong list returned;

	%let list=1 2 3 4 5 6;
	%put;
	%put (ii) SQL quote of an arbitrary list=&list ...;
	%let oclist=(1,2,3,4,5,6);
	%if %quote(%sql_list(&list)) EQ %quote(&oclist) %then 	%put OK: TEST PASSED - Returns: %bquote(&oclist);
	%else 											%put ERROR: TEST FAILED - Wrong list returned;

	%put;
%mend _example_sql_list;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_sql_list; 
*/

/** \endcond */
