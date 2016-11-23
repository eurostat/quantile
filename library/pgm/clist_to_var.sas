/** 
## clist_to_var {#sas_clist_to_var}

Insert into a (possibly already existing) dataset a variable formatted as a list 
of (_e.g._, comma-separated and quote-enhanced) values.

	%clist_to_var(clist, var, dsn, mark=%str(%"), sep=%quote(,), lib=WORK);

### Arguments
* `clist` :  list of formatted (_e.g._, comma-separated, quote-enhanced, parentheses-enclosed) 
	items;
* `var` : name of the variable to use in the dataset;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%%str(%"), and" `sep=``%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details;
* `lib` : (_option_) output library; default (not passed or ''): `lib` is set to `WORK`.

### Returns
`dsn` : output dataset; if the dataset already exists, then observations with missing
	values everywhere except for the variable `var` (possibly not present in `dsn`) will 
	be appended to the dataset.
	
### Examples

	%let clist=("DE", "UK", "SE", "IT", "PL", "AT");
 	%clist_to_var(&clist, geo, dsn);	
	
returns in `WORK.dsn` the following table:
	Obs|geo
	---|---
	 1 | DE
	 2 | UK
	 3 | SE
	 4 | IT
	 5 | PL
	 6 | AT

Run macro `%_example_clist_to_var` for more examples.

### Note
If the dataset already exists and there are no numeric, or character variables  in it, 
then the following warning will be issued:

    WARNING: Defining an array with zero elements.

This message is not an error. See [%list_to_var](@ref sas_list_to_var).

### See also
[%list_to_var](@ref sas_list_to_var), [%var_to_clist](@ref sas_var_to_clist), [%clist_unquote](@ref sas_clist_unquote). 
*/ /** \cond */

%macro clist_to_var(clist 	/* List of items comma-separated by a delimiter and between parentheses (REQ) */
					, var 	/* Variable to write the items in 										(REQ) */
					, dsn 	/* Output dataset 														(REQ) */
					, mark=	/* Character/string used to quote items in input lists 					(OPT) */
					, sep=	/* Character/string used as list separator 								(OPT) */
					, lib=	/* Output library 														(OPT) */
					);

    /* all default settings are operated in the macros called below 
	%if %macro_isblank(lib) %then %let lib=WORK;
	%if %macro_isblank(mark) %then 	%let mark=%str(%");
	%if %macro_isblank(sep) %then 	%let sep=%str(,); */

	%local REP; /* replacement of list separator - used for conversions */
	%let REP=%quote(£); /* most unlikely to be used in a list: there is something good about the Brexit... */

	/* first transform into easy-to-manipulate list, then run the existing list_to_var macro 
	* by setting all variables with those passed to clist_to_var */
	%list_to_var(%clist_unquote(&clist, mark=&mark, sep=&sep, rep=&REP), 
				&var, &dsn, sep=&REP, lib=&lib);
	/* done! */

%mend clist_to_var;

%macro _example_clist_to_var;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let dsn=_tmp_example_clist_to_var;

	%let clist=("DE", "UK", "SE", "IT", "PL", "AT");	

	%put;
	%put (i) Create a (empty) dataset &dsn from the list GEO=&clist ...;
	%clist_to_var(&clist, geo, &dsn);
 	%ds_print(&dsn);
	
	%put;
	%put (ii) Append to test dataset _dstest33 from the list GEO=&clist ...;
	%_dstest33;
	%clist_to_var(&clist, geo, _dstest33);
 	%ds_print(_dstest33);

	/* do some cleansing */
	%work_clean(&dsn, _dstest33);
%mend _example_clist_to_var;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_clist_to_var; 
*/

/** \endcond */
