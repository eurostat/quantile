## ctry_in_zone {#sas_ctry_in_zone}
Check whether a country (defined by its ISO code) belongs to a given geographic zone 
(_e.g._, EU28) in a year-time period.

	%ctry_in_zone(ctry, zone, _ans_=, time=, cds_ctryxzone=COUNTRYxZONE, clib=LIBCFG);

### Arguments
* `ctry` : ISO3166-code of a country (cases GB/UK and GR/EL handled);
* `zone` : code of a geographical zone, _e.g._ EU28, EA19, etc...;
* `time` : (_option_) selected time; if empty, it is tested whether the country ever belonged to area;
* `cds_ctryxzone` : (_option_) configuration file storing the description of geographical areas; by default,
	it is named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`); for further description, 
	see [%_countryxzone](@ref cfg_countryxzone);
* `clib` : (_option_) name of the library where the configuration file is stored; default to the value 
	`&G_PING_LIBCFG`(_e.g._, `LIBCFG`) when not set.

### Returns
`_ans_` : name of the macro variable where storing the output of the test, _i.e._ the boolean
	result (1: yes/ 0: no) of the question: _"does ctry belong to the geographical area zone?"_.

### Examples
Let's first check whether HR was part of the EU28 area in 2009:

	%let ans=;
	%ctry_in_zone(HR, EU28, time=2009, _ans_=ans);
	
returns `ans=0`. Now, what about 2014?
	
	%ctry_in_zone(HR, EU28, time=2014, _ans_=ans); 

returns `ans=1`.

Considering recent Brexit, we may also ask about UK future in the EU28 area:

	%ctry_in_zone(UK, EU28, time=2018, _ans_=ans);

still returns `ans=1`, for how long however...

Run macro `%%_example_ctry_in_zone` for more examples.

### Note 
The table `cds_ctryxzones` contains in fact for each country in the EU+EFTA 
geographic area the year of entrance in/exit of (when such case applies) any given euro zone. 
In particular, it means that the zone defined by `zone` needs to be defined as a field in the table.
Note that when using the default settings, a table `COUNTRYxZONE` must exist in `LIBCFG`. 

### See also
[%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_to_zone](@ref sas_ctry_to_zone), [%str_isgeo](@ref sas_str_isgeo),
[%_countryxzone](@ref cfg_countryxzone).
