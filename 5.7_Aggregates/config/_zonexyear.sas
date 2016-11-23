/** 
## ZONExYEAR {#cfg_zonexyear}
Configuration file used to set years of existence/consideration of EU geographical areas.

### Contents
A table named after the value `&G_PING_ZONExYEAR` (_e.g._, `ZONExYEAR`) shall be defined 
in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain 
for EU geographical (aggregated) area:
* start and end year of use/existence of the area, 
* start and end year of actual use of the area in the computation. 

In practice, the table looks like this (can change owing to updates):
geo | YEAR_IN   |  YEAR_OUT  | YEAR_START |	YEAR_END   
----|-----------|------------|------------|----------
EU28|	2010	|	9999	 |	  2010    | 	9999
EU27|	2007	|	9999	 |	   .      | 	.		
EU25|	2004	|	9999	 |	   .      | 	.		
EU15|	1995	|	9999	 |	   .      | 	.	
EU	|	1957	|	9999	 |	  2003    | 	9999
EA19|	2015	|	9999	 |	  2005    | 	9999
EA18|	2014	|	9999	 |	   .      | 	.		
EA17|	2011	|	9999	 |	   .      | 	.		
EA16|	2009	|	9999	 |	   .      | 	.		
EA15|	2008	|	9999	 |	   .      | 	.		
EA13|	2007	|	9999	 |	   .      | 	.		
EA12|	1999	|	9999	 |	   .      | 	.		
EA	|	1999	|	9999	 |	  2003    | 	9999

### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%_zonexyear(cds_zonexyear=A, cfg=B, clib=C);

Note that, by default, the command `%%_zonexyear;` runs:

	%_zonexyear(cds_zonexyear=&G_PING_ZONExYEAR, 
				cfg=&G_PING_AGGREGATES/config, 
				clib=&G_PING_LIBCFG);

### Example
Generate the table `ZONExYEAR` in the `WORK` directory:

	%_zonexyear(clib=WORK);

### See also
[%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_to_zone](@ref sas_ctry_to_zone), [%str_isgeo](@ref sas_str_isgeo),
[%_countryxzone](@ref cfg_countryxzone).
*/ /** \cond */

%macro _zonexyear(cds_zonexyear=, cfg=, clib=);

	%if %macro_isblank(cds_zonexyear) %then %do;
		%if %symexist(G_PING_ZONExYEAR) %then 		%let cds_zonexyear=&G_PING_ZONExYEAR;
		%else										%let cds_zonexyear=ZONExYEAR;
	%end;
	
	%if %macro_isblank(clib) %then %do;
		%if %symexist(G_PING_LIBCFG) %then 			%let clib=&G_PING_LIBCFG;
		%else										%let clib=LIBCFG/*SILCFMT*/;
	%end;

	%if %macro_isblank(cfg) %then %do;
		%if %symexist(G_PING_AGGREGATES) %then 		%let cfg=&G_PING_AGGREGATES/config;
		%else										%let cfg=&G_PING_ROOTPATH/5.7_Aggregates/config;
	%end;

	%local FMT_CODE;
	%if %symexist(G_PING_FMT_CODE) %then 		%let FMT_CODE=&G_PING_FMT_CODE;
	%else										%let FMT_CODE=csv;

	%file_import(&cds_zonexyear, fmt=&FMT_CODE, _ods_=&cds_zonexyear, 
				idir=&cfg, olib=&clib, getnames=yes);

%mend _zonexyear;


%macro _example_zonexyear;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Generate the table &G_PING_ZONExYEAR of zone history in WORK library; 
	%_zonexyear(clib=WORK);
	%ds_print(&G_PING_ZONExYEAR);

	%work_clean(&G_PING_ZONExYEAR);

	%put;
%mend _example_zonexyear;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_zonexyear;
*/

/** \endcond */
