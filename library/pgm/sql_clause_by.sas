/** 
## sql_clause_by {#sas_sql_clause_by}
Generate a quoted text that can be interpreted by the `BY` clause of a SQL procedure.

	%sql_clause_by(dsn, var, _varby_=, lib=);

### Arguments
* `dsn` :
* `var` :
* `lib` :

### Returns
`_varby_` : 

### Examples
The simple example below:

	%_dstest6;
	%let var=a b z h;
	%let varby=;
	%sql_clause_by(_dstest6, a b z h, _varby_=varby);

returns `varby=a, b, h` since variable `z` is not present in `_dstest6`.

### See also
[%ds_select](@ref sas_ds_select), [%sql_clause_as](@ref sas_sql_clause_as), [%sql_clause_add](@ref sas_sql_clause_add), 
[%sql_clause_modify](@ref sas_sql_clause_modify), [%sql_clause_where](@ref sas_sql_clause_where)
*/ /** \cond */

%macro sql_clause_by(dsn
					, var
					, _varby_=
					, lib=
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* VAR, _VARAS_: check/set */
	%if %error_handle(ErrorMissingInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=%quote(!!! Missing input parameter VAR !!!))
			or
			%error_handle(ErrorMissingOutputParameter, 
				%macro_isblank(_varby_) EQ 1, mac=&_mac,		
				txt=%quote(!!! Missing output parameter _VARBY_ !!!)) %then  
		%goto exit;
	
	/* DSN/LIB: check/set */
	%if %macro_isblank(lib) %then 	%let lib=WORK;		

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i
		SEP REP
		_by
		_var; 
	%let SEP=%str( );
	%let REP=%str(,);
	%let _var=; 

	%do _i=1 %to %list_length(&var, sep=&SEP);
		%let _by=%scan(&var, &_i, &SEP);
		%if %error_handle(WarningInputParameter, 
				%var_check(&dsn, &_by, lib=&lib) EQ 1, mac=&_mac,		
				txt=%quote(! Variable %upcase(&_by) does not exist in dataset %upcase(&dsn) !),  
				verb=warn) %then 
			%goto next;
		%else 
			%let _var=&_var.&SEP&_by;
		/* %if %macro_isblank(_var) %then 	%let _var=&_by;
		%else								%let _var=&_var.&REP.&SEP.&_by;
		*/
		%next:
	%end;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_var) EQ 1, mac=&_mac,		
			txt=%quote(!!! None of the variables in %upcase(&var) was found in %upcase(&dsn) !!!)) %then
		%goto exit;

	%let _var=%list_quote(&_var, sep=&SEP, rep=&REP.&SEP, mark=_EMPTY_);

	data _null_;
		call symput("&_varby_","&_var");
	run;

	%exit:
%mend sql_clause_by;

%macro _example_sql_clause_by;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local var ovarby varby;

	%_dstest6;
	
	%let var=a b z h;
	%put;
	%put (i) Simple test over test dataset #6, with var=&var;
	%let varby=;
	%sql_clause_by(_dstest6, &var, _varby_=varby);
	%let ovarby=a, b, h;
	%if %quote(&varby) EQ %quote(&ovarby) %then 	%put OK: TEST PASSED - returns: %bquote(&ovarby);
	%else 											%put ERROR: TEST FAILED - wrong list returned;

	%work_clean(_dstest6);

	%put;
%mend _example_sql_clause_by;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_sql_clause_by; 
*/

/** \endcond */
