/** 
## sql_clause_modify {#sas_sql_clause_modify}
Generate a statement (text) that can be interpreted by the `MODIFY` clause of a SQL procedure.

	%sql_clause_modify(dsn, var, _varmod_=, fmt=, len=, lab=, lib=);

### Arguments
* `dsn` :
* `var` :
* `fmt` : 
* `len` : 
* `lab` : 
* `lib` :

### Returns
`_varmod_` : 

### Examples
The simple example below:

	%_dstest6;
	%let var=	d  		e;
    %let len=	20 		8;
	%let fmt=	$20. 	10.2; 
    %let lab=	d2 		e2;
	%let varmod=;
	%sql_clause_modify(_dstest6, &var, fmt=&fmt, lab=&lab, len=&len, _varmod_=varmod);

returns `varmod=d FORMAT=$20. LENGTH=20 LABEL='d2', e FORMAT=10.2 LENGTH=8 LABEL='e2'`.

### See also
[%ds_alter](@ref sas_ds_alter), [%sql_clause_add](@ref sas_sql_clause_add), [%sql_clause_as](@ref sas_sql_clause_as),
[%sql_clause_by](@ref sas_sql_clause_by), [%sql_clause_where](@ref sas_sql_clause_where),
[MODIFY](https://support.sas.com/documentation/cdl/en/lestmtsref/63323/HTML/default/viewer.htm#n0g9jfr4x5hgsfn17gtma5547lt1.htm).
*/ /** \cond */

%macro sql_clause_modify(dsn
					, var
					, _varmod_=
					, fmt=
					, len=
					, lab=
					, lib=
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* VAR, _VARMOD_: check/set */
	%if %error_handle(ErrorMissingInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=%quote(!!! Missing input parameter VAR !!!))
			or
			%error_handle(ErrorMissingOutputParameter, 
				%macro_isblank (_varmod_) EQ 1, mac=&_mac,		
				txt=!!! Missing output parameter _VARMOD_ !!!) %then
		%goto exit;

	%local SEP
		_modlen;	/* number of variables to modify */
	%let SEP=%str( );

	%let _modlen=%list_length(&var, sep=&SEP);

	/* FMT: check/set */
	%if not %macro_isblank(fmt) %then %do;
		%if %error_handle(ErrorInputParameter,
			%list_length(&fmt, sep=&SEP) NE &_modlen, mac=&_mac,
			txt=!!! Parameters VAR and FORM must be of same length !!!) %then	
		%goto exit;
	%end;

	/* LEN: check/set */
	%if not %macro_isblank(len) %then %do;
		%if %error_handle(ErrorInputParameter,
			%list_length(&len, sep=&SEP) NE &_modlen, mac=&_mac,
			txt=!!! Parameters VAR and LEN must be of same length !!!) %then	
		%goto exit;
	%end;

	/* LAB: check/set */
	%if not %macro_isblank(lab) %then %do;
		%if %error_handle(ErrorInputParameter,
			%list_length(&lab, sep=&SEP) NE &_modlen, mac=&_mac,
			txt=!!! Parameters VAR and LAB must be of same length !!!) %then	
		%goto exit;
	%end;

	/* DSN/LIB: check/set */
	%if %macro_isblank(lib) %then 	%let lib=WORK;		

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i
		REP 
		SEPZIP          /* separator character                                               */
		_var
		_typ
		_newvar
		_newtyp; 
	%let SEP=%str( );
	%let REP=%str(,);
	%let _newvar=; 

	%local _i
		SEP REP
		_var
		_fmt
		_newfmt
		_fmtlen		/* number of format to apply to the list of variables to modify      */
		_len
		_newlen
		_nlen
		_lab
		_newlab
		_lablen		/* number of labels to apply to the list of variables to modify      */
		_newvar; 
	%let SEP=%str( );
	%let REP=%str(,);
	%let SEPZIP=%quote(/UNLIKELYSEPARATOR/);
	%let _newvar=; 
	%let _newfmt=; 
	%let _newlen=; 
	%let _newlab=; 

	/* trim: get rid of those variables which are not in the input dataset */
	%do _i=1 %to %list_length(&var, sep=&SEP);
		%let _var=%scan(&var, &_i, &SEP);
		%if not %macro_isblank(fmt) %then		%let _fmt=%scan(&fmt, &_i, &SEP);
		%if not %macro_isblank(len) %then		%let _len=%scan(&len, &_i, &SEP);
		%if not %macro_isblank(lab) %then		%let _lab=%scan(&lab, &_i, &SEP);
		%if %error_handle(WarningInputParameter, 
				%var_check(&dsn, &_var, lib=&lib) EQ 1, mac=&_mac,		
				txt=%quote(! Variable %upcase(&_var) does not exist in dataset %upcase(&dsn) !),  
				verb=warn) %then 
			%goto next;
		%else %do;
			%let _newvar=&_newvar.&SEP.&_var;
			%if not %macro_isblank(fmt) %then	%let _newfmt=&_newfmt.&SEP.&_fmt;
			%if not %macro_isblank(len) %then	%let _newlen=&_newlen.&SEP.&_len;
			%if not %macro_isblank(lab) %then	%let _newlab=&_newlab.&SEP.&_lab;
		%end;
		%next:
	%end;

	/* shape */
	%if not %macro_isblank(_newfmt) %then %do;
		%let _fmtlen=%list_length(&_newfmt, sep=&SEP);
		%let _newfmt=%list_append(%list_ones(&_fmtlen, item=FORMAT), &_newfmt, zip=%str(=));
		%let _newvar=%list_append(&_newvar, %quote(&_newfmt), zip=&SEPZIP);
	%end;
	%if not %macro_isblank(_newlen) %then %do;
		%let _nlen=%list_length(&_newlen, sep=&SEP);
		%let _newlen =%list_append(%list_ones(&_nlen, item=LENGTH), &_newlen, zip=%str(=));
		%let _newvar =%list_append(%quote(&_newvar), %quote(&_newlen), zip=&SEPZIP);
	%end;
	%if not %macro_isblank(_newlab) %then %do;
		%let _lablen=%list_length(&_newlab, sep=&SEP);
		%let _newlab=%list_quote(&_newlab, rep=_EMPTY_, mark=%str(%'));
		%let _newlab=%list_append(%list_ones(&_lablen, item=LABEL), &_newlab, zip=%str(=));
		%let _newvar =%list_append(%quote(&_newvar), %quote(&_newlab), zip=&SEPZIP);
	%end;
	%let _newvar=%sysfunc(tranwrd(%quote(&_newvar), %str( ), %str(, )));
	%let _newvar=%sysfunc(tranwrd(%quote(&_newvar), &SEPZIP, %str( )));

	/* return */
	data _null_;
		call symput("&_varmod_","&_newvar");
	run;
	/*	%let &_varmod_=%bquote(&_newvar);*/

	%exit:
%mend sql_clause_modify;

%macro _example_sql_clause_modify;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local var ovarmod varmod;

	%_dstest6;

	%let var=d  	e;
    %let len=20 	8;
	%let fmt=$20. 	10.2; 
    %let lab=d2 	e2;
	%put;
	%put (i) Simple test over dataset #6, reformatting variable %sysfunc(compbl(%quote(var=&var with len=&len, fmt=&fmt and renaming with lab=&lab)));
	%let varmod=;
	%sql_clause_modify(_dstest6, &var, fmt=&fmt, lab=&lab, len=&len, _varmod_=varmod);
	%let ovarmod=%quote(d FORMAT=$20. LENGTH=20 LABEL='d2', e FORMAT=10.2 LENGTH=8 LABEL='e2');
	%if %quote(&varmod) EQ %quote(&ovarmod) %then 	%put OK: TEST PASSED - returns: %bquote(&ovarmod);
	%else 											%put ERROR: TEST FAILED - wrong list returned;

	%work_clean(_dstest6);

	%put;
%mend _example_sql_clause_modify;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_sql_clause_modify; 
*/

/** \endcond */
