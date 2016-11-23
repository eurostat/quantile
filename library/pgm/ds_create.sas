/** 
## ds_create {#sas_ds_create}
Create a dataset/table from a common label template and a list of additional labels using a
`PROC SQL`.

	%ds_create(odsn, idsn=, var=, typ=, len=, idrop=, ilib=WORK, olib=WORK);
  
### Arguments
* `idsn` : (_option_) dataset storing the template of common dimensions; this table shall 
	contain, for each variable to be inserted in the output dataset, its type, length as well
	as its desired position; it is of the form: 
 variable | type | length | order
:--------:|:----:|-------:|-------:
 	 W    | num  |      8 |      1
	where the order is relative to the beginning (when >0) or the end of the table (when <0);
	default: `idsn` is not set and no template table will be used; 
* `var` : (_option_) dimensions, i.e. names of the (additional) fields/variables present in 
	the dataset; default: empty;
* `typ` : (_option_) types of the (additional) fields; must be the same length as `var`;
* `len` : (_option_) lengths of the (additional) fields; must be the same length as `var`; 
* `idrop` : (_option_) variable(s) from the input template dataset `idsn` to be dropped prior to 
	their insertion into `odsn`;
* `ilib` : (_option_) name of the library where the configuration file is stored; default to 
	the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) when not set;
* `olib` : (_option_) name of the output library where `dsn` shall be stored; by default: empty, 
	_i.e._ `WORK` is used.

### Returns
`odsn` : name of the final output dataset created. 

### Examples
Running for instance

	%let dimensions=A B C;
	%ds_create(odsn, var=&dimensions);

creates the table `odsn` as:
| A | B | C |
|---|---|---|
|   |   |   |  
where all fields `A, B, C` are of type `CHAR` and length 15.
Consider now the following table `TEMP` stored in the `WORK`ing library:
VARIABLE  | TYPE | LENGTH | ORDER
----------|------|-------:|-----:
	W     | num  |      8 | 1
	X     | num  |      8 | 2
	Y     | char |     15 | 3
	Z     | num  |      8 | -1
which impose to put the dimensions `W, X, Y` in the first three positions in the table, and `Z`
in the last position, then run the command:

	%ds_create(odsn, var=&dimensions, idsn=TEMP);

In output, the table `odsn` now looks like:
| W | X | Y | A | B | C | Z |
|---|---|---|---|---|---|---|
|   |   |   |   |   |   |   |
where the variables `W, X, Y, Z` types and lengths are taken from the `TEMP` table.

Run macro `%%_example_ds_create` for examples.

### Note
The dataset generated using the macro [%_indicator_contents](@ref cfg_indicator_contents) provides
a typical example of configuration table dataset.

### See also
[%ds_check](@ref sas_ds_check), [%silcx_ind_create](@ref sas_silcx_ind_create),
[%_indicator_contents](@ref cfg_indicator_contents).
*/ /** \cond */

%macro ds_create(odsn			/* Name of final output dataset 						(REQ) */
				, idsn=			/* Dataset of common variables		(OPT) */
				, var=			/* Dimensions, i.e. names of variables 					(REQ) */
				, typ=			/* Types of the dimensions 								(OPT) */
				, len=			/* Lenghts of the dimensions 							(OPT) */
				, idrop=		/* Name of variable(s) to drop 							(OPT) */
				, olib=			/* Name of the library storing configuration file		(OPT) */
				, ilib=			/* Name of the output library where odsn will be stored (OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local nvar			/* number of additional dimensions/labels */
		ntyp			/* number of additional lengths */
		nlen			/* number of additional types */
		DEF_VAR_LENGTH	
		DEF_VAR_TYPE
		_i _j _k		/* loop increments */
		cvar			/* common dimensions/labels (from configuration file) */
		cord			/* order of common dimensions/labels */
		ctyp			/* types of common dimensions/labels */
		clen			/* lengths of common dimensions/labels */
		ncvar			/* number of common dimensions/labels */
		_ord			/* scanned order */
		_lab			/* scanned label */
		_typ			/* scanned type */
		_len			/* scanned length */
		_ENTRY_;		/* boolean flag set when one dimension is written in the table */

	/* set the constant variables that may depend on externally defined variables */
	%if %symexist(G_PING_VAR_LENGTH) %then 		%let DEF_VAR_LENGTH=&G_PING_VAR_LENGTH;
	%else										%let DEF_VAR_LENGTH=15;
	%if %symexist(G_PING_VAR_TYPE) %then 		%let DEF_VAR_TYPE=&G_PING_VAR_TYPE;
	%else										%let DEF_VAR_TYPE=char;

	%let nvar=%list_length(&var); /*%sysfunc(countw(&var));*/

	/* LEN, TYP: check the input types/lengths variables, pluis compatibility */
	%if %macro_isblank(typ) %then 	%let typ=&DEF_VAR_TYPE;
	%let ntyp=%list_length(&typ);
	%if &ntyp=1 and &ntyp^=&nvar %then 
		%let typ=%list_ones(&nvar, item=&typ);

	%if %macro_isblank(len) %then 	%let len=&DEF_VAR_LENGTH;
	%let nlen=%list_length(&len);
	%if &nlen=1 and &nlen^=&nvar %then 
		%let len=%list_ones(&nvar, item=&len);

	%if %error_handle(ErrorInputParameter, 
			%list_length(&typ) NE &nvar or %list_length(&len) NE &nvar, mac=&_mac,
			txt=%quote(!!! Incompatible parameters TYP and/or LEN with VAR !!!)) %then 
		%goto exit; 

	/* ODSN, OLIB: check the output dataset */
	%if %macro_isblank(olib) %then %let olib=WORK;
	%if %error_handle(ExistingOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,
			txt=%quote(! Output table already exist !), verb=warn) %then 
		%goto warning1;
	%warning1:

	/* IDSN, ILIB: check the configuration file, and compatibility with IDROP */
	%if %macro_isblank(ilib) %then %let ilib=WORK;

	%if %error_handle(MissingConfigurationFile, 
			%macro_isblank(idsn) EQ 1, mac=&_mac,
			txt=%quote(! No dataset of common dimensions passed - Only VAR will be included !), 
			verb=warn) %then %do;
		%if %error_handle(MissingConfigurationFile, 
				%macro_isblank(idrop) EQ 0, mac=&_mac,
				txt=%quote(! Parameter IDROP ignored when IDSN is not passed !), 
				verb=warn) %then
			%goto warning2;
		%warning2:
		%goto skip;
	%end;
	%else %if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,
			txt=%quote(!!! Input dataset %upcase(idsn) not found !!!)) %then 
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _tmp; 			/* temporary table */
	%let _tmp=TMP&_mac;

	PROC SQL noprint;
		CREATE TABLE WORK.&_tmp AS
		SELECT *
		FROM &ilib..&idsn
		ORDER BY (case when order<0 then 1 else 0 end), order;
	quit;

	%var_to_list(&_tmp, 1/* DIMENSION or VARIABLE: we are being flexible */, _varlst_=cvar);
	%if not %macro_isblank(idrop) %then %do;
		%let cvar=%list_difference(&cvar, &idrop);
	%end;
	%let ncvar=%list_length(&cvar); /* maybe nil */
	%var_to_list(&_tmp, TYPE, 	_varlst_=ctyp);
	%var_to_list(&_tmp, LENGTH, _varlst_=clen);
	%var_to_list(&_tmp, ORDER, 	_varlst_=cord);
	%work_clean(&_tmp);
	%goto build;

	%skip: 
	%let cvar=;	
	%let cord=;	
	%let ctyp=;	
	%let clen=;	
	%let ncvar=-1;
	%goto build;

	%build: 
	%let _ENTRY_=0;

	/* create the output table if it does not already exist */
	PROC SQL noprint;
		CREATE TABLE &olib..&odsn 
			(
			/* insert all common labels (ie. from configuration file) with positive order */
			%do _i=1 %to &ncvar;
				%let _ord=%scan(&cord, &_i, %str( ));
				/* we shall check whether _ord<0, in which case it means that the dimension/label
				* shall be inserted at the end of the tables 
				*/
				%if &_ord<0 %then 	%goto break;
				%let _lab=%scan(&cvar, &_i, %str( ));
				%let _typ=%scan(&ctyp, &_i, %str( ));
				%let _len=%scan(&clen, &_i, %str( ));
				%if &_ENTRY_=0 %then %do;
					&_lab 	&_typ
				%end;
				%else %do;
					, &_lab &_typ
				%end;
				%if &_len^= %then %do;
					(&_len)
				%end;
				%let _ENTRY_=1;
				/* special setting: if we arrive here when _i=ncvar, it means we did not "break"
				* ie cord is always >0; in particular we will need to enter the next loop on common
				* dimension: we force the value of _i so as to ensure so */
				%if &_i=&ncvar %then %let _i=%eval(_i+1);
			%end;
			%break:
			/* insert all additional labels */
			%do _j=1 %to &nvar;
				%let _lab=%scan(&var, &_j, %str( ));
				%let _typ=%scan(&typ, &_j, %str( ));
				%let _len=%scan(&len, &_j, %str( ));
				%if &_ENTRY_=0 %then %do;
					&_lab 	&_typ
				%end;
				%else %do;
					, &_lab	&_typ
				%end;
				%if &_len^= %then %do;
					(&_len)
				%end;
				%let _ENTRY_=1;
			%end;
			/* insert all common labels with negative order */
			%do _k=&_i %to &ncvar;
				%let _lab=%scan(&cvar, &_k, %str( ));
				%let _typ=%scan(&ctyp, &_k, %str( ));
				%let _len=%scan(&clen, &_k, %str( ));
				%if &_ENTRY_=0 %then %do;
					&_lab 	&_typ
				%end;
				%else %do;
					, &_lab &_typ
				%end;
				%if &_len^= %then %do;
					(&_len)
				%end;
				%let _ENTRY_=1;
			%end;
			%quit:
			);
	quit;
	
	%exit:
%mend ds_create;


%macro _example_ds_create;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local _cds _dsn labels rlabels olabels types rtypes otypes lengths rlengths olengths;
	%let _dsn=TMP&sysmacroname;
	%work_clean(&_dsn);

	%let labels=A B C;
	%put;
	%put (i) Create an ad-hoc table from parameter labels only; 
	%ds_create(&_dsn, var=&labels);
	%let olabels=%sysfunc(compbl(	A 	B 	C	));
	%let otypes=%sysfunc(compbl(	2	2	2	));
	%let olenghts=%sysfunc(compbl(	15	15	15	));
	%ds_contents(&_dsn, _varlst_=rlabels, _lenlst_=rlengths, _typlst_=rtypes, varnum=yes);
	%if %quote(&olabels)=%quote(&rlabels) and %quote(&olenghts)=%quote(&rlengths) and %quote(&otypes)=%quote(&rtypes) %then 	
		%put OK: TEST PASSED - Dataset correctly created with (ordered and typed) fields: %upcase(&olabels);
	%else 					
		%put ERROR: TEST FAILED - Wrong dataset creation with fields: &rlabels;
	%work_clean(&_dsn);

	%let _cds=cTMP&sysmacroname;
	%let types=char num char;
	%let lengths=15 8 15;
	DATA &_cds;
		LABEL="value"; 	TYPE="num "; 	LENGTH=8; 	ORDER=-3; output;
		LABEL="flag"; 	TYPE="char"; 	LENGTH=20; 	ORDER=-2; output;
		LABEL="n"; 		TYPE="num"; 	LENGTH=8; 	ORDER=-1; output;
		LABEL="geo"; 	TYPE="char"; 	LENGTH=15; 	ORDER=1; output;
		LABEL="time"; 	TYPE="num"; 	LENGTH=8; 	ORDER=2; output;
	run;
	%put;
	%put (ii) Create a dataset table from an ad-hoc configuration file;
	%ds_create(&_dsn, var=&labels, len=&lengths, typ=&types, idsn=&_cds, ilib=WORK);
	%let olabels=%sysfunc(compbl(	geo time 	A 	B 	C 	value 	flag 	n	));
	%let otypes=%sysfunc(compbl(	2	1		2	1	2	1		2		1	));
	%let olenghts=%sysfunc(compbl(	15	8		15 	8 	15	8		20		8	));
	%ds_contents(&_dsn, _varlst_=rlabels, _lenlst_=rlengths, _typlst_=rtypes, varnum=yes);
	%if %quote(&olabels)=%quote(&rlabels) and %quote(&olenghts)=%quote(&rlengths) and %quote(&otypes)=%quote(&rtypes) %then 	
		%put OK: TEST PASSED - Dataset correctly created with (ordered and typed) fields: %upcase(&olabels);
	%else 					
		%put ERROR: TEST FAILED - Wrong dataset creation with fields: &rlabels;
	%ds_print(&_cds);
	%ds_print(&_dsn); /* empty.... */

	%put;
	%put (iii) Create a dataset table from the ad-hoc configuration file (default: INDICATOR_CONTENTS in LIBCFG);
	%let labels=	AGE		SEX		HHTYP;
	%let types=		char	char	char;
	%let lengths=	15		15		15;
	%ds_create(&_dsn, var=&labels, len=&lengths, typ=&types, idsn=INDICATOR_CONTENTS, ilib=LIBCFG);
	%let olabels=%sysfunc(compbl(	geo time 	AGE SEX HHTYP 	unit 	ivalue 	iflag 	unrel 	n nwgh ntot	totwgh 	lastup 	lastuser	));
	%let otypes=%sysfunc(compbl(	2 	1 		2 	2 	2 		2 		1 		2 		1 		1 1	   1 	1 		2 		2			));
	%let olenghts=%sysfunc(compbl(	15 	8 		15 	15 	15 		8 		8 		8 		8 		8 8	   8 	8 		8 		8			));
	%ds_contents(&_dsn, _varlst_=rlabels, _lenlst_=rlengths, _typlst_=rtypes, varnum=yes);
	%put %quote(&olabels);
	%put %quote(&rlabels);
	%put %quote(&olenghts);
	%put %quote(&rlengths);
	%put %quote(&otypes);
	%put %quote(&rtypes);
	%if %quote(&olabels)=%quote(&rlabels) and %quote(&olenghts)=%quote(&rlengths) and %quote(&otypes)=%quote(&rtypes) %then 	
		%put OK: TEST PASSED - Dataset correctly created with (ordered and typed) fields: %upcase(&olabels);
	%else 					
		%put ERROR: TEST FAILED - Wrong dataset creation with fields: &rlabels;
	%ds_print(INDICATOR_CONTENTS, lib=LIBCFG);
	%ds_print(&_dsn); /* empty.... */

	%work_clean(&_cds, &_dsn);
	%exit:
%mend _example_ds_create;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_ds_create; 
*/

/** \endcond */





