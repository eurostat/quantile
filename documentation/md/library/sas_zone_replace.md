## zone_replace {#sas_zone_replace}
Return a list composed of countries only (geo) belonging to a given geographic area (_e.g._, EU28).

	%zone_replace(geo, time=, _ctrylst_=, _ctryclst_=, , cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG);

### Arguments
* `geo` : a list of string(s) which shall represent(s) ISO-codes or geographical zones;
* `time` : (_option_) selected year; if empty, all the countries that belong or once belonged 
	to the area are returned; default: not set;
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by 
	default, it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for further 
	description, see [%_countryxzone](@ref cfg_countryxzone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the 
	value `&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.
 
### Returns
`_ctrylst_` or `_ctryclst_` : (_option_) name of the macro variable storing the output list, where 
	all geographical areas present in `geo` have been replaced by the corresponding list of countries; 
	it is encoded , either a list of (comma separated) strings of countries ISO3166-codes in-between 	
	quotes when `_ctryclst_` is passed, or an unformatted list when `_ctrylst_` is passed; those two 
	options are incompatible.

### Note 
The table in the configuration dataset `cds_ctryxzone` contains in fact for each country in the 
EU+EFTA geographic area the year of entrance in/exit of (when such case applies) any given euro zone. 
In particular, it means that `zone` needs to be defined as a field in the table `cds_ctryxzone`.

### Examples
Let us consider the simple following example:

	%let ctry_glob=;
	%zone_replace(FR EFTA IT, time=2015, _ctryclst_=ctry_glob);

returns the (quoted) list `ctry_glob=("FR","CH","NO","IS","LI","IT")`. 

Run macro `%%_example_zone_replace` for more examples.

### See also
[%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_to_zone](@ref sas_ctry_to_zone), 
[%ctry_in_zone](@ref sas_ctry_in_zone), [%_countryxzone](@ref cfg_countryxzone).
