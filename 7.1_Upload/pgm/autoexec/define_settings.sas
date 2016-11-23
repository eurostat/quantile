/** Set of static definitions: static paths and global macro variables
 */

/* options MAUTOLOCDISPLAY; */ 
%global legacy test;
%let legacy=1; 
%let test=1;

/* Set the path of the working directory: 
 * 	- Are you working using SAS local or SAS server? 
 * This is set automatically. However if you want to force to another directory,
 * change the path below
 */

%let EUSILC=%local_or_server; 
/* this is more or less running this:
 * 		%if &_SASSERVERNAME='SASMain' %then %do;
 * 		 	%let eusilc=/ec/prod/server/sas/0eusilc;
 * 		%end;
 * 		%else %do;
 * 			%let eusilc=z:;
 * 		%end;
 * e.g., you will have:
 *   - eusilc=/ec/prod/server/sas/0eusilc if you run on the  server, or
 *   - eusilc=z:  if you run on local
 */

%let LIBRARY=&EUSILC/library; 

%let SASServer=/ec/prod/server/sas/bin/SAS92/SASFoundation/9.2/;
/* %let SASServer=&SASMain/bin/SAS92/SASFoundation/9.2/;
 * note that SASMain is defined in local_or_server */

/* define the name of the temporary working table */
%global TMPDSN;
%let NOW=%sysfunc(compress(%sysfunc(translate(%sysfunc(datetime(),datetime.)," ",":"))));
%let TMPDSN=TMP&NOW;

/* Set the global variables for legacy or test: 
 *	- g_legacy: boolean value whether to use 'legacy' code structure (1) or not (0);
 *		default to 0;
 *	- g_test: boolean value whether to run processes in test repository (1) or not (0);
 *		default to 0
 * see macro (autocall) program setpathdb.
 */

/* Specific separator used as a delimiter between the values listed as output
 * by a multiple-choices prompt.
 * See also create_list.sas */
%global LIST_SEPARATOR;
%let LIST_SEPARATOR=:;

/* Strings used for formating the Eurobase file */
%global EBFILE_HEADER EBFILE_TAIL EBFILE_KEYS EBFILE_FIELDS EBFILE_MODE EBFILE_TERMSTR; 
%let EBFILE_HEADER=FLAT_FILE=STANDARD;
%let EBFILE_KEYS=ID_KEYS;
%let EBFILE_FIELDS=FIELDS;
%let EBFILE_MODE=UPDATE_MODE;
%let EBFILE_TERMSTR=CRLF;
%let EBFILE_TAIL=END_OF_FLAT_FILE;
