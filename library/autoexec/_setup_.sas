/**
## _setup_ {#sas__setup_}
Setup file used for defining environment variables and default macro settings.

### Usage
It is useful to define a global `G_PING_SETUPPATH` variable with the path of the directory where 
this file is installed, then run the following instructions:

	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc;
	%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";

Following, a bunch of macros for default settings is made available, _e.g._: 
* `%%_setup_local_or_server_`: retrieve the data repository (on local or server: see comment
	on variable `G_PING_ROOTPATH` below),
* `%%_default_setup_auto_`: define the locations of the different macros used in the library
	and append these locations to `SASAUTOS`, 
* `%%_default_setup_env_`: define a set of environment variables with dataset location, 
* `%%_default_setup_var_`: define various default variables names,
* `%%_default_setup_par_`: define various default parameters.

In particular, you  will be able to run all those macros together with the default setup macro:

	%_default_setup_;

### Outputs
Say that your installation path is `G_PING_SETUPPATH` as defined above. Then, running the default
settings macro `%%_default_setup_` as described above will in particular set the following global 
variables:
* `G_PING_ROOTPATH` (and `G_PING_PROJECT`) as the path to your project repository _e.g._ you will have. 
  		- `G_PING_ROOTPATH=/ec/prod/server/sas/0eusilc` if you run on the server, or
 		- `G_PING_ROOTPATH=z:` if you run in local and if `z` has been mounted as 
		  `\\s-isis.eurostat.cec\0eusilc`,
* `SASMain` and `SASServer` as the locations of the SAS server and the SAS distribution. 

### References
1. Carpenter, A.L. (2002): ["Building and using macro libraries"](http://www2.sas.com/proceedings/sugi27/p017-27.pdf).
2. Jensen, K. and Greathouse, M. (2000): ["The autocall macro facility in the SAS for Windows environment"](http://www2.sas.com/proceedings/sugi25/25/cc/25p075.pdf).
*/ /** \cond */

/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/
/** !!! POSSIBLY CHANGE SAS SERVER TO YOUR LOCAL SERVER !!! **/
/** !!!       POSSIBLY CHANGE TO YOUR OWN PROJECT       !!! **/
/** !!!       POSSIBLY CHANGE YOUR ROOT DIRECTORY       !!! **/
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/
	
/* Environment variables for SAS setup/install */
%global SASMain
		SASServer
		SASext;
%let SASMain=/ec/prod/server/sas;
%let SASServer=%sysfunc(pathname(sasroot));
%*let SASServer=&SASMain/bin/SAS92/SASFoundation/9.2/;
%let SASext=sas;

/* project name */
%global G_PING_PROJECT;
%let G_PING_PROJECT=EUSILC;

/* root directory */
%global G_PING_ROOTDIR;
%let G_PING_ROOTDIR=0eusilc;
/* note that the root path will be determined automatically */	

/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/
/** !!! DON'T MODIFY THE SETUP FILE BELOW !!! **/
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/

%global 
		/* Full path to data, as well as processes (programs and projects)
		 * We suppose that processes are located "close" to the data */
		G_PING_ROOTPATH /* set through macro _setup_local_or_server_ below */
		/* legacy: EUSILC was used in the past, we still use it */
		&G_PING_PROJECT /* in practice: &G_PING_PROJECT := EUSILC, and &EUSILC = &G_PING_ROOTPATH  */
		; 	

%global G_PING_IS_IN_TEST
		G_PING_IS_LEGACY; /* set through the call to macro _default_env_ below */

%global	
		/* Full path of the raw data directory 															*
		* default:	&G_PING_ROOTPATH/5.3_Validation/data													*/
		G_PING_RAWDB
		/* Full path of the BDB database  																*
		* default:	&G_PING_ROOTPATH/5.5_Extraction/data/BDB												*/
		G_PING_BDB
		/* Full path of the PDB database  																*
		* default:	&G_PING_ROOTPATH/5.5_Extraction/data/PDB												*/
		G_PING_PDB
		/* Full path of the IDB_RDB directory  															*
		* default:	&G_PING_ROOTPATH																		*/
		G_PING_IDBRDB
		/* Full path of the C_IDB (cross-sectional) database  											*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/C_IDB												*/
		G_PING_C_IDB
		/* Full path of the E_IDB (early data) database  												*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/E_IDB												*/
		G_PING_E_IDB
		/* Full path of the C_IDB (longitudinal)  database  											*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/L_IDB												*/
		G_PING_L_IDB
		/* Full path of the C_RDB database  															*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/C_RDB												*/
		G_PING_C_RDB
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/C_RDB2												*/
		G_PING_C_RDB2
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/C_RDB1												*/
		G_PING_C_RDB1
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/E_RDB												*/
		G_PING_E_RDB
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/E_RDB1												*/
		G_PING_E_RDB1
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/L_RDB												*/
		G_PING_L_RDB
		/* Full path of the raw database  																*
		* default:	&G_PING_ROOTPATH/5.5_Estimation/data/L_RDB1												*/
		G_PING_L_RDB1
		/* Full path of the SUF database  																*
		* default:	&G_PING_ROOTPATH/7.2_Dissemination/SUF/													*/
		G_PING_SUFDB
		/* Full path of the PUF database  																*
		* default:	&G_PING_ROOTPATH/7.2_Dissemination/PUF													*/
		G_PING_PUFDB
		/* Full path of the UDB database  																*
		* default:	&G_PING_SUFDB/data																		*/
		G_PING_UDB
		/* Full path of the log directory																*
		* default:	&G_PING_ROOTPATH/log/																	*/
		G_PING_LOGDB
		/* Full path of the directory with data to upload												*
		* default:	&G_PING_IDBRDB/7.1_Upload/data															*/
		G_PING_LOADDB
		/* Full path of the directory with test datasets												*
		* default:	&G_PING_ROOTPATH/test/data																*/
		G_PING_TESTDB
		;	
/* note: all these variables are defined by default in macro _default_env_ below */

%global 
		/* Name of the variable defining countries; 
		* default: GEO */
		G_PING_LAB_GEO
		/* Name of the variable defining geographic zones/areas/; 
		* default: ZONE */
		G_PING_LAB_ZONE
		/* Name of the variable defining the temporal frame; 
		* default: TIME */
		G_PING_LAB_TIME
		/* Name of the variable defining the common unit; 
		* default: UNIT */
		G_PING_LAB_UNIT
		;
/* note: all these variables can be set to default values by running macro _default_var_ below */

%global 
		/* Threshold used to decide whether to compute an aggregate or not for a given indicator and	*
		* a given area: the cumulated population of available countries for this indicator is tested	*
	 	* against the total population of the considered area. 											*
		* default: 0.7 which means that an indicator will be computed whenever the population of 		*   
	 	* available countries sums up to more than 70% of the total population of the area 				*/
		G_PING_AGG_POP_THRESH
		/* Names of the files which contain the list of indicator codes and their description 			*/
 		G_PING_INDICATOR_CODES_RDB 		/* default: INDICATOR_CODES_RDB 									*/
		G_PING_INDICATOR_CODES_RDB2 		/* default: INDICATOR_CODES_RDB2 									*/
		G_PING_INDICATOR_CODES_LDB 		/* default: INDICATOR_CODES_LDB 									*/
		G_PING_INDICATOR_CODES_EDB		/* default: INDICATOR_CODES_EDB 									*/
		/* Name of the file which contain the protocol order of EU countries' 							*
		* default: COUNTRY_ORDER 																		*/
		G_PING_COUNTRY_ORDER
		/* Name of the file with the list of files with country zones 									*/
		G_PING_COUNTRYXZONE			/* default: COUNTRYxZONE											*/
		G_PING_COUNTRYXZONEYEAR		/* default: COUNTRY_COUNTRYxZONEYEAR 								*/
		/* Name of the file with the list of yearly populations per country 							*
		* default: POPULATIONxCOUNTRY 																	*/
		G_PING_POPULATIONXCOUNTRY							/* note the use of capital X in the name... */
		/* Name of the file with the history of zones 													*
		* default: ZONExYEAR 																			*/
		G_PING_ZONEXYEAR									/* note the use of capital X in the name... */
		/* Name of the file storing the type of transmission file per year 								*/
		G_PING_TRANSMISSIONxYEAR
		/* Name of the file storing the common dimensions of indicators */
		G_PING_INDICATOR_CONTENTS
		/* Name of the file storing the correspondance between EU-SILC variables and Eurobase dimensions*/
		G_PING_VARIABLE_DIMENSION
		/* Specific separator used as a delimiter between the values listed as output					*
	 	* by a multiple-choices prompt; see also prompt_list.sas 										*
		* default: _ 																					*/
		G_PING_LIST_SEPARATOR
		/* Format commonly adopted for export (note: SAS servers are UNIX, xls/xlsx should be avoided).	*
		* default: csv 																					*/
	 	G_PING_FMT_CODE
		/* String specifying the identity operator (that sends a variable to itself).					*
		* default: _ID_ 																					*/
		G_PING_IDOP
		/* Error handling macro variables */
		G_PING_ERROR_MSG					/* default: empty 											*/
		G_PING_ERROR_CODE				/* default: empty 												*/
		G_PING_ERROR_MACRO				/* default: empty 												*/
		; 	
/* note: all these variables can be set to default values by running macro _default_par_ below */

%global 
		/* Full path of the library directory 															*
		* default:	&G_PING_ROOTPATH/library								   							*/
		G_PING_LIBRARY
		/* Full path of the autoexec directory 															*
		* default: &G_PING_ROOTPATH/library/autoexec/													*/ 
		G_PING_LIBAUTO
		/* Full path of the directory with generic programs												*
		* default: &G_PING_ROOTPATH/library/pgm/ 														*/ 
		G_PING_LIBPGM
		/* Full path for the default library of configuration files (e.g. used for environment			*
		* settings)																						*
		* default: value of &G_PING_ROOTPATH/library/config 											*/ 
		G_PING_LIBCONFIG
		/* Variable set to the full path for the default catalog of format files 						*
		* default: value of &G_PING_ROOTPATH/library/catalog 											*/ 
		G_PING_CATFORMAT
		/* Full path of the test directory																*
		* default: &G_PING_ROOTPATH/test/ 																*/ 
		G_PING_LIBTEST
		/* Full path of the programs in test directory													*
		* default: &G_PING_ROOTPATH/test/pgm 															*/ 
		G_PING_LIBTESTPGM
		/* Full path of the data in test directory														*
		* default: &G_PING_ROOTPATH/test/data 															*/ 
		G_PING_LIBTESTDATA
		; 	
/* note: all these variables can be set to default values by running macro _default_par_ below */

%global 
		/* Variable set to the name (reference) of the library of configuration files 					*
		* default: value of SILCFMT 																	*/ 
		G_PING_LIBCFG 
		/* Variable set to the name (reference) of the catalog library of format files					*
		* default: value of CATFMT 																	*/ 
		G_PING_LIBRAW
		G_PING_CATFMT 
		G_PING_LIBPDB
		G_PING_LIBBDB
		G_PING_LIBCIDB
		G_PING_LIBEIDB
		G_PING_LIBLIDB
		G_PING_LIBCRDB
		G_PING_LIBCRDB2
		G_PING_LIBCERDB
		G_PING_LIBCLRDB
		G_PING_LIBLOG
		;

%global 
	G_PING_INTEGRATION
	G_PING_VALIDATION
	G_PING_EXTRACTION
	G_PING_ESTIMATION
	G_PING_AGGREGATES
	G_PING_ANALYSIS
	G_PING_DISSEMINATION
	G_PING_UPLOAD
	G_PING_STUDIES
	G_PING_ANONYMISATION
	;


%macro _setup_local_or_server_(_root_=);
	/* The %_setup_local_or_server_ macro retrieves the data repository. 
	This is and updated version of SAS team implementation of local_or_server.
	In particular, the SAS EG predefined variable _SASSERVERNAME is used for defining 
	if SAS is ran in local or on a local server (e.g., G_PING_SASMain which is in our case 
	/ec/prod/server/sas/), instead of SYSSCP (which defines the running operating 
	system).  
	*/
 	%if "&_root_"="' '" or &_root_= %then %do;
		%put;
		%put --------------------------------------------------------------------------;
		%put ERROR(&G_PING_PROJECT): _setup_local_or_server_;
		%put !!! Output macro variable _root_ not set !!!;
		%put --------------------------------------------------------------------------;
		%put;
		%goto exit;
	%end;

	/* we will test for the location of this file */
	%let TESTROOTFILE=/library/autoexec/_setup_.&SASext;

	/* initialise */
	%local _path;
	%let _path=;  
	
	/* but you may run in local... let's check */
	%if %symexist(_SASSERVERNAME) %then %do; /* e.g.: you are running on SAS EG */
		%if &_SASSERVERNAME='Local' %then %do; 
			/* Look for a given file 
			 * unfortunately &_SASPROGRAMFILE is not recognised...
			 */
			%let file_to_check=&TESTROOTFILE;
			/* it will look for...itself! */

			/* drives to look through */
			%let lst=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z;
			/* we start at Z for our setup... that's the one we use by default! */
			%let start=%sysfunc(indexc(%sysfunc(compress(&lst)),A));
			%let finish=%sysfunc(indexc(%sysfunc(compress(&lst)),Z));

			%if &sysscp = WIN %then %do;  /* local windows */
				%let file_to_check=%sysfunc(translate(&file_to_check, \, /));
				%do i = &start %to &finish;
					%let drv = %scan(&lst,&i);
					%if %sysevalf(%sysfunc(fileexist(&drv.:&file_to_check))) %then
						/* maybe on your drive...? */                        
						%let _path=&drv.:;
					%else %if %sysevalf(%sysfunc(fileexist(&drv.:\home\&file_to_check))) %then
						/* let us give it a second chance: maybe on your home directory...? */
						%let _path=&drv.:\home;
					%if &_path^= %then %goto quit;
				%end;
			%end;
			%else %do; /* e.g., local linux/solaris server */
				%do i = &start %to &finish;
					%let drv = %scan(&lst,&i);
					%if %sysevalf(%sysfunc(fileexist(/&drv./&file_to_check))) %then
						/* maybe on your drive...? */                        
						%let _path=/&drv;
					%else %if %sysevalf(%sysfunc(fileexist(/&drv./local/&file_to_check))) %then 
						/* let us give it a second chance: maybe on your local directory...? */                        
						%let _path=/&drv./local;
					%if &_path^= %then %goto quit;
				%end;
			%end;
			%goto quit; /* skip the next "%let" instruction */
		%end;

	%end;

	/* at this stage:
	 * - either you do not run on SAS EG (_SASSERVERNAME is not defined), 
	 * - or you run on the server: _SASSERVERNAME=SASMain 
	 * in both cases we define _path as the following */
	%let _path=&SASMain/&G_PING_ROOTDIR;

	%quit:
	/* "return" the path */
	data _null_;
		call symput("&_root_","&_path");
	run;

	%exit:
%mend _setup_local_or_server_;

/* Set the path of the working directory: 
 * 		- Are you working using SAS local or SAS server? 
 * This is set automatically, roughly running:
 * 		%if &_SASSERVERNAME='SASMain' %then %do;
 * 		 	%let G_PING_ROOTPATH=/ec/prod/server/sas/0eusilc;
 * 		%end;
 * 		%else %do;
 * 			%let G_PING_ROOTPATH=z:;
 * 		%end;
 */
 %_setup_local_or_server_(_root_=G_PING_ROOTPATH);
/*  However if you want to force to another directory, change the path below
 *		%let G_PING_ROOTPATH=; 
 */

%let &G_PING_PROJECT=&G_PING_ROOTPATH;
 /* You will then have:
 *   - &G_PING_PROJECT:=EUSILC=/ec/prod/server/sas/0eusilc if you run on the  server, or
 *   - &G_PING_PROJECT:=EUSILC=z:  if you run on local
 */


/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/
/** !!! DEFINE YOUR OWN DEFAULT SETTINGS BELOW !!! **/
/** !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! **/

%macro _default_setup_auto_; 

	options MRECALL;
	options MAUTOSOURCE;
	options SASAUTOS =(SASAUTOS 
						/*"&G_PING_ROOTPATH/library/autoexec/"*/
						"&G_PING_ROOTPATH/library/pgm/" 		
						"&G_PING_ROOTPATH/library/test" 			
						"&G_PING_ROOTPATH/5.1_Integration/pgm/"
						"&G_PING_ROOTPATH/5.3_Validation/pgm/"
						"&G_PING_ROOTPATH/5.5_Extraction/pgm/"
						"&G_PING_ROOTPATH/5.5_Estimation/pgm/"
						"&G_PING_ROOTPATH/5.7_Aggregates/pgm/"
						"&G_PING_ROOTPATH/6.3_Analysis/pgm/"
						"&G_PING_ROOTPATH/6.4_Anonymisation/pgm/"
						"&G_PING_ROOTPATH/7.1_Upload/pgm/"
						"&G_PING_ROOTPATH/7.3_Dissemination/pgm/"
						"&G_PING_ROOTPATH/7.4_Studies/pgm/"
						"&G_PING_ROOTPATH/7.4_Visualisation/pgm/"
						);
	options NOMRECALL;

%mend _default_setup_auto_;

%macro _default_setup_env_(legacy=yes, test=no); /* default locations */

	%let G_PING_LIBRARY=		&G_PING_ROOTPATH/library; 
	%let G_PING_LIBAUTO=		&G_PING_LIBRARY/autoexec; 
	%let G_PING_LIBPGM=			&G_PING_LIBRARY/pgm; 
	%let G_PING_LIBDATA=		&G_PING_LIBRARY/data; 
	%let G_PING_LIBCONFIG=		&G_PING_LIBRARY/config;
	%let G_PING_CATFORMAT=		&G_PING_LIBRARY/catalog;

	*%let LIBCFG=&G_PING_LIBCONFIG;

	%let G_PING_INTEGRATION=	&G_PING_ROOTPATH/5.1_Integration;
	%let G_PING_VALIDATION=		&G_PING_ROOTPATH/5.3_Validation;
	%let G_PING_EXTRACTION=		&G_PING_ROOTPATH/5.5_Extraction;
	%let G_PING_ESTIMATION=		&G_PING_ROOTPATH/5.5_Estimation;
	%let G_PING_AGGREGATES=		&G_PING_ROOTPATH/5.7_Aggregates;
	%let G_PING_ANALYSIS=		&G_PING_ROOTPATH/6.1_Analysis;
	%let G_PING_ANONYMISATION=	&G_PING_ROOTPATH/6.4_Anonymisation;
	%let G_PING_STUDIES=		&G_PING_ROOTPATH/7.4_Studies;
	%let G_PING_UPLOAD=			&G_PING_ROOTPATH/7.1_Upload;
	%let G_PING_DISSEMINATION=	&G_PING_ROOTPATH/7.3_Dissemination;

	%let G_PING_LIBTEST=		&G_PING_ROOTPATH/test; 
	%let G_PING_LIBTESTPGM=		&G_PING_LIBTEST/pgm;
	%let G_PING_LIBTESTDATA=	&G_PING_LIBTEST/data; /* see G_PING_TESTDB */

	%let legacy=%sysfunc(lowcase(&legacy));
	%let G_PING_IS_LEGACY=&legacy;
	%let test=%sysfunc(lowcase(&test));
	%let G_PING_IS_IN_TEST=&test;

	%if &legacy=yes %then %do; 

		%if &test=yes %then %do;
			%let G_PING_IDBRDB=	&G_PING_ROOTPATH/IDB_RDB_TEST;
		%end;
		%else %do;
			%let G_PING_IDBRDB=	&G_PING_ROOTPATH/IDB_RDB;
		%end;

		%let db_raw=			&G_PING_ROOTPATH/main;
		%let db_valid=			&G_PING_ROOTPATH/main;
		%let db_extr=			&G_PING_IDBRDB;
		%let db_estim=			&G_PING_IDBRDB;
		%let db_upload=			&G_PING_IDBRDB/newcronos;

		%let G_PING_BDB=		&G_PING_ROOTPATH/BDB;
		%let G_PING_PDB=		&G_PING_ROOTPATH/pdb;

	%end;
	%else %do;

		%if &test=yes %then %do;
			%let G_PING_IDBRDB=	&G_PING_ROOTPATH/test;
		%end;
		%else %do;
			%let G_PING_IDBRDB=	&G_PING_ROOTPATH;
		%end;

		%let db_raw=			&G_PING_IDBRDB/5.1_Integration/data;
		%let db_valid=			&G_PING_IDBRDB/5.3_Validation/data;
		%let db_extr=			&G_PING_IDBRDB/5.5_Extraction/data;
		%let db_estim=			&G_PING_IDBRDB/5.5_Estimation/data;
		%let db_upload=			&G_PING_IDBRDB/7.1_Upload/data;

		%let G_PING_BDB=		&db_extr/BDB;
		%let G_PING_PDB=		&db_extr/PDB; 

	%end;

	%let G_PING_TESTDB=			&G_PING_LIBTEST/data; /* &G_PING_LIBTESTDATA */

	%let G_PING_RAWDB=			&db_raw;

	%let G_PING_C_IDB=			&db_extr/C_IDB; 
	%let G_PING_E_IDB=			&db_extr/E_IDB; 
	%let G_PING_L_IDB=			&db_extr/L_IDB; 

	%let G_PING_C_RDB=			&db_estim/C_RDB; 
	%let G_PING_C_RDB2=			&db_estim/C_RDB2; 
	%let G_PING_E_RDB=			&db_estim/E_RDB; 
	%let G_PING_L_RDB=			&db_estim/L_RDB; 

	%let G_PING_C_RDB1=			&db_estim/C_RDB1; 
	%let G_PING_L_RDB1=			&db_estim/L_RDB1; 
	%let G_PING_E_RDB1=			&db_estim/E_RDB1; 

	%let G_PING_LOGDB=			&db_estim/log; 

	%let G_PING_LOADDB=			&db_upload;

	%let G_PING_UDB=			&G_PING_DISSEMINATION/data;
	%let G_PING_SUFDB=			&G_PING_UDB/SUF;
	%let G_PING_PUFDB=			&G_PING_UDB/PUF;

%mend _default_setup_env_;


%macro _default_setup_lib_;
	libname LIBCFG "&G_PING_LIBCONFIG";
	libname SILCFMT "&G_PING_LIBCONFIG"; /* that's our own: legacy */
	%let G_PING_LIBCFG=LIBCFG;

	libname LIBRAW "&G_PING_RAWDB";
	%let G_PING_LIBRAW=LIBRAW;

	libname LIBPDB "&G_PING_PDB";
	%let G_PING_LIBPDB=LIBPDB;
	libname LIBBDB "&G_PING_BDB";
	%let G_PING_LIBBDB=LIBBDB;

	libname LIBCIDB "&G_PING_C_IDB";
	%let G_PING_LIBCIDB=LIBCIDB;
	libname LIBEIDB "&G_PING_E_IDB";
	%let G_PING_LIBEIDB=LIBEIDB;
	libname LIBLIDB "&G_PING_L_IDB";
	%let G_PING_LIBLIDB=LIBLIDB;

	libname LIBCRDB "&G_PING_C_RDB";
	%let G_PING_LIBCRDB=LIBCRDB;
	libname LIBCRDB2 "&G_PING_C_RDB2";
	%let G_PING_LIBCRDB2=LIBCRDB2;
	libname LIBCERDB "&G_PING_E_RDB";
	%let G_PING_LIBCERDB=LIBCERDB;
	libname LIBCLRDB "&G_PING_L_RDB";
	%let G_PING_LIBCLRDB=LIBCLRDB;

	libname LIBLOG "&G_PING_LOGDB";
	%let G_PING_LIBLOG=LIBLOG;

	libname CATFMT "&G_PING_CATFORMAT"; 
	%let G_PING_CATFMT=CATFMT;
%mend _default_setup_lib_;


%macro _default_setup_var_;

	%let G_PING_LAB_GEO=	geo;
	%let G_PING_VAR_GEO=	B020;
	%let G_PING_LAB_TIME=	time; /* year? */
	%let G_PING_LAB_ZONE=	zone;
	%let G_PING_LAB_UNIT=	unit;
	%let G_PING_LAB_VALUE=	ivalue;
	%let G_PING_LAB_UNREL=	unrel;
	%let G_PING_LAB_N=		n;
	%let G_PING_LAB_NTOT=	ntot;
	%let G_PING_LAB_TOTWGH=	totwgh;
	%let G_PING_LAB_IFLAG=	iflag;

%mend _default_setup_var_;


%macro _default_setup_par_;

	%let G_PING_AGG_POP_THRESH=0.7; 

	%let indicator_generic=INDICATOR_CODES;
	%let G_PING_INDICATOR_CODES_RDB=	&indicator_generic._RDB;
	%let G_PING_INDICATOR_CODES_RDB2=	&indicator_generic._RDB2;
	%let G_PING_INDICATOR_CODES_LDB=	&indicator_generic._LDB;
	%let G_PING_INDICATOR_CODES_EDB=	&indicator_generic._EDB;

	%let G_PING_COUNTRY_ORDER=			COUNTRY_ORDER;
	%let G_PING_POPULATIONXCOUNTRY=		POPULATIONxCOUNTRY; 
	%let G_PING_ZONEXYEAR=				ZONExYEAR;

	%let countryx=COUNTRYx;
	%let G_PING_COUNTRYXZONE=			&countryx.ZONE;
	%let G_PING_COUNTRYXZONEYEAR=		&countryx.ZONEYEAR;

	%let G_PING_TRANSMISSIONxYEAR= 		TRANSMISSIONxYEAR;

	%let G_PING_INDICATOR_CONTENTS=		INDICATOR_CONTENTS;
	%let G_PING_VARIABLE_DIMENSION=		VARIABLE_DIMENSION;

	%let G_PING_IDOP=					_ID_; 
	%let G_PING_LIST_SEPARATOR=			_; /*:*/
	%let G_PING_FMT_CODE=				csv;

	%let G_PING_ERROR_MSG=;
	%let G_PING_ERROR_CODE=;
	%let G_PING_ERROR_MACRO=;

%mend _default_setup_par_;

%macro _default_setup_;
	%*include "&SASMain/&G_PING_ROOTDIR/library/autoexec/_setup_.sas";
	%_default_setup_auto_;
	%_default_setup_env_(legacy=yes, test=no); /* legacy environment and no test */
	%_default_setup_lib_;
	%_default_setup_var_;
	%_default_setup_par_;
%mend _default_setup_;

%macro _test_setup_;
	%*include "&SASMain/&G_PING_ROOTDIR/library/autoexec/_setup_.sas";
	%_default_setup_auto_;
	%_default_setup_env_(legacy=yes, test=yes); /* legacy and test environment */
	%_default_setup_lib_;
	%_default_setup_var_;
	%_default_setup_par_;
%mend _test_setup_;

/** \endcond */
