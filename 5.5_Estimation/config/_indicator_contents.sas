/** 
## INDICATOR_CONTENTS {#cfg_indicator_contents}
Provide a common contents as a set of generic dimensions to be included in an indicator table,
together with their types, lengths, and positions in the table.

### Contents
A table named after the value `&G_PING_INDICATOR_CONTENTS` (_e.g._, `INDICATOR_CONTENTS`) shall be 
defined in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain 
the common variables/dimensions used in all indicators created in production. 

In practice, the table looks like this:
 dimension | type | length | order
:---------:|:----:|----- -:|--------:
  geo      | char |	  15   |	1
  time	   | num  |	   4   |	2
  unit	   | char |	   8   |   -9
  ivalue   | num  |	   8   |   -8
  iflag	   | char |	   8   |   -7
  unrel	   | num  |	   8   |   -6
  n	       | num  |	   8   |   -5
  nwgh     | num  |	   8   |   -5
  ntot	   | num  |	   8   |   -4
  ntotwgh  | num  |	   8   |   -3
  lastup   | char |	   8   |   -2
  lastuser | char |	   8   |   -1     

### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%_indicator_contents(cds_ind_con=A, cfg=B, clib=C);

Note that, by default, the command `%%_indicator_contents;` runs:

	%_indicator_contents(cds_ind_con=&G_PING_INDICATOR_CONTENTS, 
					cfg=&G_PING_ESTIMATION/config, 
					clib=&G_PING_LIBCFG, zone=yes);

### Example
Generate the table `INDICATOR_CONTENTS` in the `WORK` directory:

	%_indicator_contents(clib=WORK);

### See also
[%_variablexindicator](@ref cfg_variablexindicator), [%_variable_dimension](@ref cfg_variable_dimension).
*/ /** \cond */

%macro _indicator_contents(cds_ind_con=, cfg=, clib=);

	%if %macro_isblank(cds_ind_con) %then %do;
		%if %symexist(G_PING_INDICATOR_CONTENTS) %then 	%let cds_ind_con=&G_PING_INDICATOR_CONTENTS;
		%else											%let cds_ind_con=INDICATOR_CONTENTS;
	%end;
	
	%if %macro_isblank(clib) %then %do;
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end;

	%if %macro_isblank(cfg) %then %do;
		%if %symexist(G_PING_ESTIMATION) %then 		%let cfg=&G_PING_ESTIMATION/config;
		%else										%let cfg=&G_PING_ROOTPATH/5.5_Estimation/config;
	%end;

	%local FMT_CODE;
	%if %symexist(G_PING_FMT_CODE) %then 		%let FMT_CODE=&G_PING_FMT_CODE;
	%else										%let FMT_CODE=csv;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	/* method 1: hand-create it */
	%local l_GEO		
		GEO_LENGTH		
		l_TIME		
		TIME_LENGTH			
		l_UNIT			
		UNIT_LENGTH		
		l_VALUE			
		l_UNREL			
		l_N				
		l_NWGH			
		l_NTOT			
		l_NTOTWGH	
		l_IFLAG			
		IFLAG_LENGTH;
	%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
	%else										%let l_GEO=geo;
	%if %symexist(G_PING_GEO_LENGTH) %then 		%let GEO_LENGTH=&G_PING_GEO_LENGTH;
	%else										%let GEO_LENGTH=15;
	%if %symexist(G_PING_LAB_TIME) %then 		%let l_TIME=&G_PING_LAB_TIME;
	%else										%let l_TIME=time;
	%if %symexist(G_PING_TIME_LENGTH) %then 	%let TIME_LENGTH=&G_PING_TIME_LENGTH;
	%else										%let TIME_LENGTH=4;
	%if %symexist(G_PING_LAB_UNIT) %then 		%let l_UNIT=&G_PING_LAB_UNIT;
	%else										%let l_UNIT=unit;
	%if %symexist(G_PING_UNIT_LENGTH) %then 	%let UNIT_LENGTH=&G_PING_UNIT_LENGTH;
	%else										%let UNIT_LENGTH=8;
	%if %symexist(G_PING_LAB_VALUE) %then 		%let l_VALUE=&G_PING_LAB_VALUE;
	%else										%let l_VALUE=ivalue;
	%if %symexist(G_PING_LAB_UNREL) %then 		%let l_UNREL=&G_PING_LAB_UNREL;
	%else										%let l_UNREL=unrel;
	%if %symexist(G_PING_LAB_N) %then 			%let l_N=&G_PING_LAB_N;
	%else										%let l_N=n;
	%if %symexist(G_PING_LAB_NTOT) %then 		%let l_NTOT=&G_PING_LAB_NTOT;
	%else										%let l_NTOT=ntot;
	%if %symexist(G_PING_LAB_NWGH) %then 		%let l_NWGH=&G_PING_LAB_NWGH;
	%else										%let l_NWGH=nwgh;
	%if %symexist(G_PING_LAB_TOTWGH) %then 		%let l_NTOTWGH=&G_PING_LAB_TOTWGH;
	%else										%let l_NTOTWGH=ntotwgh;
	%if %symexist(G_PING_LAB_IFLAG) %then 		%let l_IFLAG=&G_PING_LAB_IFLAG;
	%else										%let l_IFLAG=iflag;
	%if %symexist(G_PING_IFLAG_LENGTH) %then 	%let IFLAG_LENGTH=&G_PING_IFLAG_LENGTH;
	%else										%let IFLAG_LENGTH=8;

	DATA &clib..&cds_ind_con;
		length LABEL $15;
		length TYPE $4;
		LABEL="&l_GEO"; 	TYPE="char"; 	LENGTH=&GEO_LENGTH; 	ORDER=1; 	output;
		LABEL="&l_TIME "; 	TYPE="num"; 	LENGTH=&TIME_LENGTH; 	ORDER=2; 	output;
		LABEL="&l_UNIT"; 	TYPE="char"; 	LENGTH=&UNIT_LENGTH; 	ORDER=-10; 	output;
		LABEL="&l_VALUE"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-9; 	output;
		LABEL="&l_IFLAG"; 	TYPE="char"; 	LENGTH=&IFLAG_LENGTH; 	ORDER=-8; 	output;
		LABEL="&l_UNREL"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-7; 	output;
		LABEL="&l_N"; 		TYPE="num"; 	LENGTH=8; 				ORDER=-6; 	output;
		LABEL="&l_NWGH"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-5; 	output;
		LABEL="&l_NTOT"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-4; 	output;
		LABEL="&l_NTOTWGH"; TYPE="num"; 	LENGTH=8; 				ORDER=-3; 	output;
		LABEL="lastup"; 	TYPE="char"; 	LENGTH=8; 				ORDER=-2; 	output;
		LABEL="lastuser"; 	TYPE="char"; 	LENGTH=8; 				ORDER=-1; 	output;
	run;

	/*
	%file_import(&cds_ind_con, fmt=&FMT_CODE, _ods_=&cds_ind_con, 
				idir=&cfg, olib=&clib, getnames=yes);
	*/

%mend _indicator_contents;


%macro _example_indicator_contents;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Create the table &G_PING_VARIABLE_DIMENSION with variable<=>dimension correspondances in WORK library; 
	%_indicator_contents(clib=WORK);
	%ds_print(&G_PING_VARIABLE_DIMENSION);

	%put;
%mend _example_indicator_contents;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_indicator_contents;
*/

/** \endcond */