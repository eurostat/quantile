/** 
## aggregate_unit {#sas_aggregate_unit}
Set the `"unit"` field (whose name is either unit or currency) for the aggregate of 
a given dataset whenever it exists.

	%let flag=%aggregate_unit(dsn);

### Arguments
`dsn` : name of the considered dataset.

### Returns
`flag` : name of the so-called `"unit"` field returned (whenever it exists for the considered
	dataset). 

### Note
The presence of a "unit" field depends on the (name of the) dataset and is "hard"-encoded 
in the program, namely:
	- `currency` is returned when tab is in (`DI10,DI02`),
	- `unit` is returned when tab is in (`DI03,DI04,DI05,DI07,DI08,DI09,DI13,DI13b,DI14,DI14b`), 
	- nothing is returned (_i.e._, `flag=`) otherwise.
	
This macro program is used for calculating and building the aggregate indicators. See also
macro [`aggregate_join`](@ref sas_aggregate_join) and the keyword parameter `flag_unit`.
 
### Examples
Run macro `%%_example_aggregate_unit`.

### See also
[`aggregate_join`](@ref sas_aggregate_join)
*/ /** \cond */

%macro aggregate_unit(/*input*/  tab);

	%let Utab=%upcase(&tab);
	%let _flag_unit=; /* ' '*/

 	%if &Utab=DI10 or &Utab=DI02 %then %do; 
		%let _flag_unit=currency;	
	%end;
	%else %if &Utab=DI03 or &Utab=DI04 or &Utab=DI05 or &Utab=DI07 or &Utab=DI08 or &Utab=DI09 
			or &Utab=DI13 or &Utab=DI13B or &Utab=DI14 or &Utab=DI14B %then %do; 
		%let _flag_unit=unit;	
	%end;
	
	&_flag_unit

%mend aggregate_unit;


%macro _example_aggregate_unit;
	%local flag;

	%let dsn=DI02;
	%put (i) When considering the dataset &dsn ...;
	%if %aggregate_unit(&dsn)=currency %then 	%put OK: TEST PASSED - Dataset &dsn: returns "currency";
	%else 										%put ERROR: TEST FAILED - Dataset &dsn: wrong returns;

	%let dsn=di13b;
	%put (ii) When considering the dataset &dsn ...;
	%if %aggregate_unit(&dsn)=unit %then 	%put OK: TEST PASSED - Dataset &dsn: returns "unit";
	%else 									%put ERROR: TEST FAILED - Dataset &dsn: wrong returns;

	%let dsn=;
	%put (iii) When considering the dataset &dsn ...;
	%if %macro_isblank(%aggregate_unit(&dsn)) %then 	%put OK: TEST PASSED - Dataset &dsn: nothing returned;
	%else 												%put ERROR: TEST FAILED - Dataset &dsn: something returned;

%mend _example_aggregate_unit;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_aggregate_unit;  
*/

/** \endcond */
