
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/
/** !!!         SET YOUR OWN PATHS          !!! **/
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/

%global G_PING_SUPPORT; 

%macro _project_setup;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		/* if you want to use the default setup: */
		%_default_setup_;
		/* or: setup your own environment, for instance:
			%_default_setup_auto_;
			%_default_setup_env_(legacy=yes, test=no);
			%_default_setup_var_;
		*/

		/* if you want to make some changes:
		* - in the SASAUTOS paths to programs/libraries/catalogs:
			options MAUTOSOURCE SASAUTOS =(SASAUTOS 
								<path_to_your_programs_catalogs>
								);
		* - in the default environment variables:
			%let G_C_RDB=<your own path to RDB directory>;
			%let G_RAW=<your own path to RAW data>;
			...;
		* note: G_ROOTPATH environment variable is set automatically
		* - in the default parameter values:
			%let G_AGG_POP_THRESH=<your own threshold for aggregates>;
			%let G_INDICATOR_CODES_RDB=<your own file of indicators>;
			...;
		*/
	%end;
%mend _project_setup;

%_project_setup;

%let G_PING_SUPPORT=&G_PING_ROOTPATH/7.5_Support;

/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/
/** !!! DON'T MODIFY THE SETTING FILE BELOW !!! **/
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/

%put --------------------------------------------------------------------------;
%put Setup and support paths set...;
%put --------------------------------------------------------------------------;

/* some global variables used along the project */
%global g_egp
		g_egpdir
		g_prglist
		g_issue 
		g_ds;

%macro _project_autoname(_egp_=, _dir_=, _issue_=);
	%let _mac=&sysmacroname;
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_egp_) EQ 1 or %macro_isblank(_issue_) EQ 1,		
			txt=!!! output variables _EGP_ and _ISSUE_ need to be set !!!, mac=&_mac) %then 
		%goto exit;

	%local _issue _egp _l;

	%let _egp=%_egp_path(path=base, dashreplace=yes);
	/*%let _dir=%_egp_path(path=base);*/
	%let _dir=&G_PING_ROOTPATH/%_egp_path(path=drive);

	%let _l=%index(&_egp,_);
	%if &_l>1 %then	%do;
		%let _issue=%substr(&_egp, 1, %eval(&_l-1));
	%end;
	%else %do;		
		%let _l=%index(&_egp,.);
		%let _issue=%substr(&_egp, 1, %eval(&_l-1));
	%end;

	%let _issue=%lowcase(&_issue);

	data _null_;
		call symput("&_egp_","&_egp");
		call symput("&_dir_","&_dir");
		call symput("&_issue_","&_issue");
	run;
    
	%exit:
%mend _project_autoname;

/* set the project name and the related issue, e.g. EUSILCPROD<XXX> where
* <XXX> is the request number */
%_project_autoname(_egp_=g_egp, _dir_=g_egpdir, _issue_=g_issue);
/* we suggest the output datasets is called like the issue */

%put --------------------------------------------------------------------------;
%put Project: 		&g_egp;
%put Issue: 		&g_issue;
%put Repository: 	&g_egpdir;
%put --------------------------------------------------------------------------;


%macro _prg_find(issue, _prglist_=);
	%let _mac=&sysmacroname;
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_prglist_) EQ 1,		
			txt=!!! output variable _prglist_ needs to be set !!!, mac=&_mac) %then 
		%goto exit;

	%local _dir _dsn _ext _file _prglist;
	
	%let _dir=&g_egpdir;
	%let _ext=&SASext;
	%let _dsn=TMP_PRG_FIND;
	
	%let _file=%quote(&_dir./)%quote(%lowcase(&issue));

	/*
	%let _file=%quote(&_dir./)%quote(%lowcase(&issue));
	%dir_ls(&_file.*.&_ext, dsn=&_dsn);
	%var_to_list(&_dsn, base, _varlst_=_prglist);
	*/
	%let _prglist=%file_ls(&_dir, match=%lowcase(&issue), ext=&_ext, beg=yes);

	data _null_;
		call symput("&_prglist_","&_prglist");
	run;

	%work_clean(&_dsn);

	%exit:
%mend;

/* define the list of programs in relation with this project/issue 
* programs need indeed to be saved outside the project and linked to it */
%_prg_find(&g_issue, _prglist_=g_prglist);


%macro prg_check;
	%let _mac=&sysmacroname;
	%if %error_handle(ErrorInputParameter, 
			%list_length(g_prglist) EQ 0,		
			txt=!!! No programs related to this project have been found !!!, mac=&_mac) %then 
		%goto error;
	%else	
		%goto quit;

	%error:
	%put ERROR: ... PROGRAM ABORTED ...;

	%quit:
%mend;

%prg_check;

%put --------------------------------------------------------------------------;
%put List of associated programs: 	&g_prglist;
%put --------------------------------------------------------------------------;


/* Set the number of programs = number of output datasets 
* you can possibly leave it blank, it will then be determined automatically from the number
* of SAS programs in the support PGM directory 
* however, we should still have Nds=Nprg */

%global G_PING_SUPPORT_CREATE
		G_PING_SUPPORT_IMPORT
		G_PING_SUPPORT_COMPUTE
		G_PING_SUPPORT_EXPORT
		;	

%macro _default_suffnames_;
	%let G_PING_SUPPORT_CREATE=	create;
	%let G_PING_SUPPORT_IMPORT=	import;
	%let G_PING_SUPPORT_COMPUTE=compute;
	%let G_PING_SUPPORT_EXPORT=	export;
%mend;

%_default_suffnames_;

%global g_nds;

%macro _ds_count(ds, _nds_=);
	%let _mac=&sysmacroname;
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_nds_) EQ 1,		
			txt=!!! output variable _nds_ needs to be set !!!, mac=&_mac) %then 
		%goto exit;

	%local _dir _dsn _nprg _file _suff _ext;
	
	%let _dir=&g_egpdir;
	%let _suff=;/*_&G_PING_SUPPORT_CREATE;*/
	%let _ext=&SASext;
	%let _dsn=TMP_DS_COUNT;

	/*
	%let _file=%quote(&_dir./&ds.&_suff);
	%dir_ls(&_file.*.&_ext, dsn=&_dsn);
	%ds_count(&_dsn, _nobs_=_nprg);
	*/
	%let  _nprg=%list_length(%file_ls(&_dir, match=&ds.&_suff, ext=&_ext, beg=yes));
	data _null_;
		call symput("&_nds_","&_nprg");
	run;

	%work_clean(&_dsn);

	%exit:
%mend _ds_count;

%let g_ds=&g_issue;
%_ds_count(&g_ds, _nds_=g_nds);

%put --------------------------------------------------------------------------;
%put Gerneric dataset name: 		&g_ds;
%put Number of output datasets: 	&g_nds;
%put --------------------------------------------------------------------------;


%macro _par_check;
	%let _mac=&sysmacroname;
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(g_ds) EQ 1 or &g_nds EQ 0,		
			txt=!!! Datasets and programs variables not set: check that programs exist !!!, mac=&_mac) %then 
		%goto errabort;
	%else	
		%goto exit;

	%errabort:
	/*%abort return;
	*/
	%exit:
%mend _par_check;

%_par_check;

%put --------------------------------------------------------------------------;
%put Parameters set...;
%put --------------------------------------------------------------------------;

%put &g_ds;