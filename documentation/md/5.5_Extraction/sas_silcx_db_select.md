## silcx_db_select {#sas_silcx_db_select}
Select and append data from cross-sectional bulk databases (_i.e._, raw H, P, D and R tables) given a period 
and/or a list of countries.

	%silcx_db_select(time, geo=, db=, odsn=, ilib=, olib=, cds_ctryxzone=, clib=);

### Arguments
* `time` : a (list of) selected year(s); default: not set;
* `geo` : (_option_) a (list of) string(s) which represent(s) ISO-codes or geographical zones;
* `db` : (_option_) database(s) to retrieve; it can be any of the character values defined through 
	the global variable `G_PING_BASETYPES` (_i.e._, `D, H, P, R`), so as to represent the 
	corresponding bulk databases (files) to append to the output dataset(s); 
* `ilib` : (_option_) name of the input library where the bulk database is stored; default to the 
	library associated to the full path given by the value `&G_PING_PDB`;
* `olib` : (_option_) name of the output library where the datasets passed through `odsn` (see 
	below) will be stored; default to `WORK`;
* `cds_ctryxzone, clib` : (_options_) configuration file storing the description of geographical 
	areas, and the library where it is stored; for further description of the table, see 
	[%_countryxzone](@ref cfg_countryxzone).
 
### Returns
`odsn` : output reference table(s) created as a concatenation (_i.e._ append operation) ot the bulk datasets
extracted from the databases in `db`; in practice, all bulk datasets (files) with generic name of the form 
`c&yy.&_db` where:
	+ `_db` is any element of `db` (_i.e._, either `D, H, P`, or `R`),
	+ `yy` is composed of the last two digits of any element of `time` (_i.e._, if `time=2014`, then `yy=14`),

are retrieved from the database library `ilib`.

### Examples
Run `%%_example_silcx_db_select` for examples.

### Reference
Carr, D.W. (2008): ["When PROC APPEND may make more sense than the DATA STEP"](http://www2.sas.com/proceedings/forum2008/085-2008.pdf).

### See also
[%silcx_ds_extract](@ref sas_silcx_ds_extract),
[%_countryxzone](@ref cfg_countryxzone).
