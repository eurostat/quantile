/** 
## ds_copy {#sas_ds_copy}
Create a working copy of a given dataset.

	%ds_copy(idsn, odsn, where=, groupby=, having=, mirror=COPY, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : a dataset reference;
* `groupby, where, having` : (_option_) expressions used to refine the selection when `mirror=COPY`,
	like in a `SELECT` statement of `PROC SQL` (`GROUP BY, WHERE, HAVING` clauses); these options are
	therefore incompatible with `mirror=LIKE`; note that `where` and `having` should be passed with 
	`%%quote`; see also [%ds_select](@ref sas_ds_select); default: empty;
* `mirror` : (_option_) type of `copy` operation used for creating the working dataset, _i.e._ either
	an actual copy of the table (`mirror=COPY`) or simply a copy of its structure (_i.e._, the output 
	table is shaped like the input ones, with same variables: `mirror=LIKE`); default: `mirror=COPY`; 
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
`odsn` : name of the output dataset (in `WORK` library) where a copy of the original dataset or its
	structure is stored.

### Example
For instance, we can run:

	%ds_copy(idsn, odsn, mirror=COPY, where=%quote(var=1000));

so as to retrieve:

	DATA WORK.&odsn;
		SET &ilib..&idsn;
		WHERE &var=1000; 
	run; 

See `%%_example_ds_copy` for more examples.

### Note
The command `%ds_copy(idsn, odsn, mirror=COPY, ilib=ilib, olib=olib)` consists in running:

	DATA &olib..&odsn;
		SET &ilib..&idsn;
	run; 

while the command `%ds_copy(idsn, odsn, mirror=LIKE, ilib=ilib, olib=olib)` is equivalent to:

	PROC SQL noprint;
		CREATE TABLE &olib..&odsn like &ilib..&idsn; 
	quit; 

### See also
[%ds_select](@ref sas_ds_select).
*/ /** \cond */

%macro ds_copy(idsn			/* Input dataset 							(REQ) */
			, odsn 			/* Output dataset 							(REQ) */ 
			, mirror=COPY	/* Boolean flag set to define the operation (OPT) */
			, where=		/* Where clause 							(OPT) */
			, groupby=		/* Group by clause 							(OPT) */
			, having=		/* Having clause 							(OPT) */
			, ilib=			/* Name of the input library 				(OPT) */
			, olib=			/* Name of the output library 				(OPT) */
			);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/
	
	/* ILIB/IDSN: check  the input dataset */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;

	/* some basic error checkings... */
	%if %error_handle(ErrorInputDataset, 
				%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,		
				txt=%quote(!!! Input dataset %upcase(&idsn) not found !!!)) 
			or
			%error_handle(ErrorInputParameter, 
				%par_check(%upcase(&mirror), type=CHAR, set=COPY LIKE) NE 0, mac=&_mac,	
				txt=!!! MIRRORing mode is either COPY or LIKE !!!) %then
		%goto exit;

	/* check that we are not processing the working dataset itself */
	%if %error_handle(ErrorInputParameter, 
			%quote(&ilib)=%quote(&olib) and %quote(&idsn)=%quote(&odsn), mac=&_mac,	
			txt=%quote(!!! Input dataset %upcase(&idsn) identified as output dataset !!!)) %then
		%goto exit;

	/* OLIB/ODSN/ possibly delete the working copy if it already exists */
	%if %macro_isblank(olib) %then 	%let olib=WORK;
	%if %error_handle(ExistingDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,
			txt=%quote(! Table %upcase(&odsn) already exists in output library !), verb=warn) %then 
		%work_clean(&odsn); 

	/* check the compatibility of the input parameters */
	%if %error_handle(ErrorInputParameter, 
			%upcase(&mirror) EQ LIKE and (%macro_isblank(where) EQ 0 or %macro_isblank(having) EQ 0 or %macro_isblank(groupby) EQ 0), mac=&_mac,	
			txt=%nrbquote(! Option MIRROR=LIKE incompatible with options WHERE, HAVING or GROUP BY - MIRROR ignored !), verb=warn) %then %do;
		%let mirror=COPY;
		%goto warning; /* dummy :) */
	%end;
	%warning:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%if %upcase(&mirror)=LIKE %then %do;
		PROC SQL noprint;
			CREATE TABLE &olib..&odsn like &ilib..&idsn; 
		quit; 
	%end;
	%else %if %upcase(&mirror)=COPY %then %do;
		%ds_select(&idsn, &odsn, groupby=&groupby, where=&where, having=&having, all=yes, ilib=&ilib, olib=&olib);
	%end;

	%exit:
%mend ds_working;

%macro _example_ds_copy;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put !!! In &sysmacroname: not yet implemented !!!;
%mend _example_ds_copy;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_copy; 
*/

/** \endcond */
