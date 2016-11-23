## str_isgeo {#sas_str_isgeo}
Define if a (list of) string(s) can be the ISO-code of a country (_e.g._, BE, AT, BG,...) or a 
geographic area (_e.g._, EU28, EA19, ...), and update this list with geographic areas/countries only.

	%str_isgeo(geo, _ans_=, _geo_=, cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG, sep=%quote( ));

### Arguments
* `geo` : a list of string(s) which shall represent(s) and ISO-code or a geographical zone;
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by default,
	it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for further description, 
	see [%_countryxzone](@ref cfg_countryxzone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set;
* `sep` : (_option_) character/string separator in input `geo` list; default: `%%quote( )`, _i.e._ `sep` is 
	blank.

### Returns
* `_ans_` : (_option_) name of the macro variable storing the list of same length as `geo` where the i-th item
	provides the answer of the test above for the i-th item in `geo`, _i.e._:
		+ `1` if it is the ISO-code of a country (_e.g._, `geo=DE`, `geo=CH`, `geo=TR`, ...),
		+ `2` if it is the code/acronym of a geographic area  (_e.g._, `geo=EU28`, or `geo=EFTA`,..),
		+ `0` otherwise;
	either this option or the next one (`_geo_`) must be set so as to run the macro;
* `_geo_` : (_option_) name of the macro variable storing the updated list from which all non-geographical areas 
	or countries have been removed; `_geo_` stores, in this order, first countries, then geographical zones. 

### Examples
Let us consider the following simple example: 

	%let ans=;
	%let geo=;
	%str_isgeo(AT BE DUMMY EU28 FR EA19, _ans_=ans, _geo_=geo);

which returns `ans=1 1 0 2 1 2` and `geo=AT BE FR EU28 EA19`.

Run macro `%%_example_str_isgeo` for more examples.

### Note 
Testing all at once if a list `geo` of strings are actual geographic codes (instead of testing it 
separately for each item of the list) avoids the burden of multiple IO operations on the input 
`cds_ctryxzone` configuration dataset.

### References
1. Official Journal of the European Union, no. [L 328, 28.11.2012](http://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=OJ:L:2012:328:FULL&from=EN).
2. Eurostat _Statistics Explained_ [webpage](http://ec.europa.eu/eurostat/statistics-explained/index.php/Glossary:Protocol_order) 
on protocol order and country code.

### See also
[%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_to_zone](@ref sas_ctry_to_zone), [%ctry_in_zone](@ref sas_ctry_in_zone),
[%_countryxzone](@ref cfg_countryxzone).
