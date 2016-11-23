## zone_to_ctry {#sas_zone_to_ctry}
Return a list and/or a table composed of countries (geo) belonging to a given geographic area (_e.g._, EU28).

	%zone_to_ctry(zone, time=, _ctryclst_=, _ctrylst_=, ctrydsn=, cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG);

### Arguments
* `zone` : code of the zone, _e.g._, EU28, EA19, etc...;
* `time` : (_option_) selected year; if empty, all the countries that belong or once belonged 
	to the area are returned; default: not set;
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by default,
	it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for further description, 
	see [%_countryxzone](@ref cfg_countryxzone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.
 
### Returns
* `_ctryclst_` or `_ctrylst_` : (_option_) name of the macro variable storing the output list, either a list of 
	(comma separated) strings of countries ISO3166-codes in-between quotes when `_ctryclst_` is passed, 
	or an unformatted list when `_ctrylst_` is passed; those two options are incompatible;
* `ctrydsn` : (_option_) name of the output table (stored in `WORK`) where the list of countries found will be 
	stored; this option can be used contemporaneously with either of the options `_ctryclst_` or `_ctrylst_` above.

### Note 
The table in the configuration dataset `cds_ctryxzone` contains in fact for each country in the EU+EFTA 
geographic area the year of entrance in/exit of (when such case applies) any given euro zone. 
In particular, it means that `zone` needs to be defined as a field in the table `cds_ctryxzone`.

See [%ctry_in_zone](@ref sas_ctry_in_zone) for further description of this table.

### Examples
Let us consider the simple following example:

	%let ctry_glob=;
	%let zone=EU28;
	%let year=2010;
	%zone_to_ctry(&zone, year=&year, _ctryclst_=ctry_glob);
	
returns the (quoted) list of 28 countries: 
`ctry_glob=("BE","DE","FR","IT","LU","NL","DK","IE","UK","EL","ES","PT","AT","FI","SE","CY","CZ","EE","HU","LT","LV","MT","PL","SI","SK","BG","RO")` 
(since `HR` is missing), while we can change the desired format of the output list (using `_ctrylst_` 
instead of `_ctryclst_`):

	%zone_to_ctry(&zone, &year, _ctrylst_=ctry_glob);

to return `ctry_glob=BE DE FR IT LU NL DK IE UK EL ES PT AT FI SE CY CZ EE HU LT LV MT PL SI SK BG RO`. 
Let's consider other EU zones in 2015, for instance:

	%let zone=EFTA;
	%let year=2015;
	%zone_to_ctry(&zone, &year, _ctryclst_=ctry_glob);

returns `ctry_glob=("CH","NO","IS","LI")`, while:

	%let zone=EEA18;
	%zone_to_ctry(&zone, &year, _ctrylst_=ctry_glob);

returns `ctry_glob=AT BE DE DK EL ES FI FR IE IS IT LU NL NO PT SE UK LI`. Let us now consider the cases 
where the outputs are stored in tables, _e.g._:

	%zone_to_ctry(EA12, time=2015, ctrydsn=dsn);

will return in the dataset `dsn` (stored in `WORK` directory) the following table:
| zone | geo | year_in | year_out |  
|------|-----|---------|----------|
| EA12 | AT  |  1999   |  2500    |	   
| EA12 | BE  |  1999   |  2500    |     
| EA12 | DE  |  1999   |  2500    |     
| EA12 | ES  |  1999   |  2500    |     
| EA12 | FI  |  1999   |  2500    |     
| EA12 | FR  |  1999   |  2500    |     
| EA12 | IE  |  1999   |  2500    |     
| EA12 | IT  |  1999   |  2500    |     
| EA12 | LU  |  1999   |  2500    |     
| EA12 | NL  |  1999   |  2500    |     
| EA12 | PT  |  1999   |  2500    |     
| EA12 | EL  |  2001   |  2500    |     
while:

	%zone_to_ctry(EU28, ctrydsn=dsn);

will return (note the absence of `time`) in the dataset `dsn` the following table:
| zone | geo | 
|------|-----|
| EU28 |  AT |
| EU28 |  BE | 
| EU28 |  BG |
| EU28 |  CY |
| EU28 |  CZ |
| EU28 |  DE |
| EU28 |  DK |
| EU28 |  EE |
| EU28 |  EL |
| EU28 |  ES |
| EU28 |  FI |
| EU28 |  FR |
| EU28 |  HR |
| EU28 |  HU |
| EU28 |  IE |
| EU28 |  IT |
| EU28 |  LT |
| EU28 |  LU |
| EU28 |  LV |
| EU28 |  MT |
| EU28 |  NL |
| EU28 |  PL |
| EU28 |  PT |
| EU28 |  RO |
| EU28 |  SE |
| EU28 |  SI |
| EU28 |  SK |
| EU28 |  UK |
and finally:

	%zone_to_ctry(EFTA, time=2015, ctrydsn=dsn);

will return (note that `EFTA` is recognised) in the dataset `dsn` the following table:
zone | geo |year_in |year_out|
-----|-----|--------|--------|
EFTA | CH  |  1960  |  2500  |  
EFTA | NO  |  1960  |  2500  |  
EFTA | IS  |  1970  |  2500  |  
EFTA | LI  |  1991  |  2500  |  

Run macro `%%_example_zone_to_ctry` for more examples.

### See also
[%ctry_in_zone](@ref sas_ctry_in_zone), [%ctry_to_zone](@ref sas_ctry_to_zone), [%zone_replace](@ref sas_zone_replace),
[%_countryxzone](@ref cfg_countryxzone);.
