/** 
## sql_clause_as {#sas_sql_clause_as}
Generate a quoted text that can be interpreted by the `AS` clause of a SQL procedure.

	%sql_clause_as(dsn, var, _varas_=, as=, op=, lib=);

### Arguments
* `dsn` :
* `var` :
* `as` :
* `op` :
* `lib` :

### Returns
`_varas_` : 

### Examples
The simple example below:

	%_dstest6;
	%let var= 	a 		b 		h
	%let as= 	ma 		B 		mh
	%let op= 	max 	_ID_ 	min
	%let varas=;
	%sql_clause_as(_dstest6, &var, as=&as, op=&op, _varas_=varas);

returns `varas=max(a) AS ma, b, min(h) AS mh`.

### See also
[%ds_select](@ref sas_ds_select), [%sql_clause_add](@ref sas_sql_clause_add), [%sql_clause_by](@ref sas_sql_clause_by), 
[%sql_clause_modify](@ref sas_sql_clause_modify), [%sql_clause_where](@ref sas_sql_clause_where)
*/ /** \cond */

%macro sql_clause_as(dsn	/* Input dataset 										(REQ) */
			, var			/* List of variables to operate the selection on 		(REQ) */
			, _varas_=		/* Name of the output macro variable					(REQ) */
			, as=			/* List of replacement names for the list of variables 	(OPT) */
			, op=			/* List of unary operations to run over input variables	(OPT) */
			, lib=			/* Name of the input library 							(OPT) */
			);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* VAR, _VARAS_: check/set */
  	%if  %error_handle(ErrorMissingInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=%quote(!!! Missing input parameter VAR !!!))
			or
			%error_handle(ErrorMissingOutputParameter, 
				%macro_isblank (_varas_) EQ 1, mac=&_mac,		
				txt=!!! Missing output parameter _VARAS_ !!!) %then
			%goto exit;

	%local SEP
		DEF_OP
		_varlen;
	%let SEP=%str( );

	/* define the identity operator (that leaves the variables AS is) */
	%if %symexist(G_PING_IDOP) %then		%let DEF_OP=&G_PING_IDOP; 
	%else									%let DEF_OP=_ID_;

	/* define the lenght of the variables passed */
	%let _varlen=%list_length(&var, sep=&SEP);

	/* AS: check/set */
	%if %macro_isblank(as) %then %do;
		%if %macro_isblank (op) /*and %macro_isblank(having) and %macro_isblank(where) */ %then 
			%let as=&var;
		/* %else: do nothing */
	%end;
	%else %if %error_handle(ErrorInputParameter, 
			%list_length(&as, sep=&SEP) NE &_varlen, mac=&_mac,		
			txt=!!! Incompatible AS and VAR parameters: lengths must be equal !!!) %then
		%goto exit;

	/* OP: check/set */
	%if %macro_isblank(op) %then 
		%let op=%list_ones(&_varlen, item=&DEF_OP, sep=&SEP);
	%else %if %error_handle(ErrorInputParameter, 
			%list_length(&op, sep=&SEP) NE &_varlen, mac=&_mac,		
			txt=!!! Incompatible OP and VAR parameters: lengths must be equal !!!) %then
		%goto exit;
	
	/* DSN/LIB: check/set */
	%if %macro_isblank(lib) %then 	%let lib=WORK;		

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i
		REP
		_var
		_op
		tmpvar
		newop
		newas
		newvar;
	%let REP=%str(,);
	%let tmpvar=; 
	%let newop=; 
	%let newas=;

	%do _i=1 %to &_varlen;
		%let _var=%scan(&var, &_i, &SEP);
		%if not %macro_isblank(op) %then		%let _op=%scan(&op, &_i, &SEP);
		%if not %macro_isblank(as) %then 		%let _as=%scan(&as, &_i, &SEP);
		%if %error_handle(WarningInputParameter, 
				%var_check(&dsn, &_var, lib=&lib) NE 0, mac=&_mac,		
				txt=%quote(! Variable %upcase(&_var) does not exist in dataset &dsn !), 
				verb=warn) %then 
			%goto next;
		%else %do;
			%let tmpvar=&tmpvar.&SEP&_var;
			%if not %macro_isblank(op) %then		%let newop=&newop.&SEP&_op;
			%if not %macro_isblank(as) %then		%let newas=&newas.&SEP&_as;
		%end;
		%next:
	%end;

	/* test whether at least one variable is present */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(tmpvar) EQ 1, mac=&_mac,		
			txt=%quote(!!! None of the variables in %upcase(&var) was found in %upcase(&dsn) !!!)) %then
		%goto exit;

	/* update VAR, _VARLEN, NEWOP, NEWAS */
	%let var=&tmpvar;
	%let _varlen=%list_length(&var, sep=&SEP);
	%if not %macro_isblank(newop) %then		%let op=%sysfunc(trim(&newop));
	%if not %macro_isblank(newas) %then		%let as=%sysfunc(trim(&newas));

	/* combine operations and variables */
	%let _newvar=;
	%do _i=1 %to &_varlen;
		%let _var=%scan(&var, &_i, &SEP);
		%if not %macro_isblank(op) %then					%let _op=%scan(&op, &_i, &SEP);
		%else 												%let _op=&DEF_OP;
		%if not %macro_isblank(as) %then					%let _as=%scan(&as, &_i, &SEP);
		%else 												%let _as=&_var;
		%if &_op=&DEF_OP %then %do;
			%if %upcase("&_var")^=%upcase("&_as") %then 	%let _var=&_var AS &_as;
			/* %else: no change */
		%end;
		%else							%let _var=&_op.(&_var) AS &_as;
		%if &_i=1 %then 				%let _newvar=&_var;
		%else 							%let _newvar=&_newvar.&REP.&SEP.&_var;
	%end;

	data _null_;
		call symput("&_varas_","&_newvar");
	run;

	%exit:
%mend sql_clause_as;

%macro _example_sql_clause_as;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local var as op ovaras varas;

	%_dstest6;
	
	%let var=	a 		b 		h;
	%let as=	ma 		B 		mh;
	%let op=	max 	_ID_ 	min;
	%put;
	%put (i) Simple test over test dataset #6, with %sysfunc(compbl(%quote(var=&var, as=&as and op=&op)));
	%let varas=;
	%sql_clause_as(_dstest6, &var, as=&as, op=&op, _varas_=varas);
	%let ovaras=max(a) AS ma, b, min(h) AS mh;
	%if %quote(&varas) EQ %quote(&ovaras) %then 	%put OK: TEST PASSED - returns: %bquote(&ovaras);
	%else 											%put ERROR: TEST FAILED - wrong list returned;

	%work_clean(_dstest6);

	%put;
%mend _example_sql_clause_as;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_sql_clause_as; 
*/

/** \endcond */
