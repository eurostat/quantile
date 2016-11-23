/** 
## TRANSMISSIONxYEAR {#cfg_transmissionxyear}
Configuration file for the yearly definition of format (longitudinal, cross-sectional or reconsilied/regular)
of microdata transmission files.

### Contents
A table named after the value `&G_PING_TRANSMISSIONxYEAR` (_e.g._, `TRANSMISSIONxYEAR`) shall be defined 
in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain for 
every type of file transmitted ("early", "cross-sectional" or "longitudinal") and every single year:
* format of the file actually transmitted: longitudinal (`l`), cross-sectional (`c`) or reconsilied/regular 
(`r`).

In practice, the table looks like this (can change owing to updates):
 geo | transmission |  Y2003 | Y2004  |  Y2005 |  Y2006 |  Y2007 |  Y2008 |  Y2009 |  Y2010 |  Y2011 |  Y2012 |  Y2013 |  Y2014 | Y2015  |
:---:|:------------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|
  .  |      L	   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    r   |    r   |
  .  |      X	   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    r   |    r   |
  .  |      E	   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    e   |    e   |    e   |
 AT  |      L	   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    r   |    r   |
 AT  |      X	   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    r   |    r   |
 AT  |      E	   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    e   |    e   |    e   |
 BE  |      L	   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    r   |    r   |
 BE  |      X	   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    r   |    r   |
 BE  |      E	   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    e   |    e   |    e   |
 ... |      ...	   |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |

### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%_transmissionxyear(cds_transxyear=A, cfg=B, clib=C);

Note that, by default, the command `%%_transmissionxyear;` runs:

	%_transmissionxyear(cds_transxyear=&G_PING_TRANSMISSIONxYEAR, 
						cfg=&G_PING_INTEGRATION/config, 
						clib=&G_PING_LIBCFG);

### Example
Generate the table `TRANSMISSIONxYEAR` in the `WORK` directory:

	%_transmissionxyear(clib=WORK);

### See also
[%silc_db_locate](@ref sas_silc_db_locate).
*/ /** \cond */


%macro _transmissionxyear(cds_transxyear=, cfg=, clib=);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(cds_transxyear) %then %do;
		%if %symexist(G_PING_TRANSMISSIONxYEAR) %then 	%let cds_transxyear=&G_PING_TRANSMISSIONxYEAR;
		%else											%let cds_transxyear=TRANSMISSIONxYEAR;
	%end;
	
	%if %macro_isblank(clib) %then %do;
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end;

	%if %macro_isblank(cfg) %then %do;
		%if %symexist(G_PING_INTEGRATION) %then 		%let cfg=&G_PING_INTEGRATION/config;
		%else											%let cfg=&G_PING_ROOTPATH/5.1_Integration/config;
	%end;

	%local FMT_CODE;
	%if %symexist(G_PING_FMT_CODE) %then 		%let FMT_CODE=&G_PING_FMT_CODE;
	%else										%let FMT_CODE=csv;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/
	
	%file_import(&cds_transxyear, fmt=&FMT_CODE, _ods_=&cds_transxyear, 
				idir=&cfg, olib=&clib, getnames=yes);

%mend _transmissionxyear;


%macro _example_transmissionxyear;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Generate the table &G_PING_TRANSMISSIONxYEAR of transmission files types per year; 
	%_transmissionxyear(clib=WORK);
	%ds_print(&G_PING_TRANSMISSIONxYEAR);

	%work_clean(&G_PING_TRANSMISSIONxYEAR);

	%put;
%mend _example_transmissionxyear;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_transmissionxyear;
*/

/** \endcond */
%_transmissionxyear;
