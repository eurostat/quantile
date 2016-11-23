## ctry_to_zone {#sas_ctry_to_zone}
Return the list of geographic area(s) (_e.g._, EU28) that contain(s), during a given period, at least 
one of the countries passed in an input list.

	%ctry_to_zone(&ctry, time=, _zone_=, cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG);

### Arguments				
* `ctry` : (list of) code(s) of the countries, _e.g._, AT, IT, etc...;
* `time` : (_option_) selected year; 
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by default,
	it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for further description, 
	see [%_countryxzone](@ref cfg_countryxzone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value 
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.

### Returns
`_zone_` : name of the output macro variable storing the desired list of geographic area(s). 

### Examples
Let us consider the following simple examples: 

	%let ozone=;
	%ctry_to_zone(AT BE, time=2004, _zone_ =ozone);

returns `ozone=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU07 EU09 EU10 EU12 EU15 EU25 EU27 EU28`,
while:

	%let ozone=;
	%ctry_to_zone(BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO HR, time=2015, _zone_ =ozone);

returns `ozone=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU07 EU09 EU10 EU12 EU15 EU25 EU27 EU28`.

Run macro `%%_example_ctry_to_zone` for more examples.

### Notes 
1. In short, this macro runs, when `time` is passed, the following procedures/macros:

       PROC TRANSPOSE data=&clib..&cds_ctryxzone out=tmp1 
		   name=ZONE
		   prefix=TIME_;
		   by GEO;
		run;

       PROC SQL noprint;
		   CREATE TABLE  tmp2  as SELECT distinct ZONE
		   FROM tmp1 
		   WHERE GEO in (%list_quote(&ctry)) and (TIME_2>&time and  TIME_1<=&time);
	   quit;

       %var_to_list(tmp2, ZONE, _varlst_=&_zone_);
2. The table in the configuration dataset `cds_ctryxzone` contains in fact for each country in the EU+EFTA 
geographic area the year of entrance in/exit of (when such case applies) any given euro zone. 
In particular, it means that `zone` needs to be defined as a field in the table `cds_ctryxzone`.

### Reference
Eurostat: Tutorial on ["Country codes and protocol order"](http://ec.europa.eu/eurostat/statistics-explained/index.php/Tutorial:Country_codes_and_protocol_order). 

### See also
[%ctry_in_zone](@ref sas_ctry_in_zone), [%zone_to_ctry](@ref sas_zone_to_ctry), 
[%_countryxzone](@ref cfg_countryxzone).
