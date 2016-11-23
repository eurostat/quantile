## COUNTRYxZONE {#cfg_countryxzone}
Configuration file for correspondance between countries and geographical areas.

### Contents
A table named after the value `&G_PING_COUNTRYxZONE` (_e.g._, `COUNTRYxZONE`) shall be defined 
in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain for 
every country in the EU+EFTA geographic area:
* its year of entrance in, and
* its year of exit of (when such case applies) 

any given euro zone (_e.g._, eurozones EA18, EA19, EU27, EU28 + EFTA). 

In practice, the table looks like this:
geo |  EA  | EA12 | EA13 | EA16 | EA17 | EA18 | EA19 | EEA  | EEA18| EEA28| EEA30| EU15 | EU25 | EU27 | EU28 | EFTA | EU07 | EU09 | EU10 | EU12 
----|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------
AT  | 1999 | 1999 | 1999 | 1999 | 1999 | 1999 | 1999 | 1994 | 1994 | 1994 | 1994 | 1995 | 1995 | 1995 | 1995 | 1960 |   .  |   .  |   .  |   .
AT  | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 1995 |   .  |   .  |   .  |   .
BE  | 1999 | 1999 | 1999 | 1999 | 1999 | 1999 | 1999 | 1994 | 1994 | 1994 | 1994 | 1957 | 1957 | 1957 | 1957 |   .  | 1957 | 1957 | 1957 | 1957
BE  | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 | 2500 |   .  | 2500 | 2500 | 2500 | 2500
... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... |  ... 

### Creation and update
Consider an input CSV table called `A.csv`, with the following structure (where all areas/observations 
considered under `ZONE` are the areas/variables - uniquely - reported in the table above):
geo | COUNTRY|	ZONE | YEAR_IN | YEAR_OUT 
----|--------|-------|---------|----------
AT	|Austria|	EA	 |  1999   |  2500
AT	|Austria|	EA12 |  1999   |  2500
AT	|Austria|	EA13 |  1999   |  2500
AT	|Austria|	EA16 |  1999   |  2500
... |  ...  |   ...  |   ...   |  ...
AT	|Austria|	EU25 |	1995   |  2500
AT	|Austria|	EU27 |	1995   |  2500
AT	|Austria|	EU28 |	1995   |  2500
BE	|Belgium|	EA	 |  1999   |  2500
BE	|Belgium|	EA12 |  1999   |  2500
BE	|Belgium|	EA13 |  1999   |  2500
BE	|Belgium|	EA16 |  1999   |  2500
... | ...   |   ...  |   ...   |  ...
and stored in a directory named `B`. In order to create/update the SAS table `A`, as described above, in 
library `C`, it is then enough to run:

	%_countryxzone(cds_zonexyear=A, cfg=B, clib=C);

Note that, by default, the command `%%_countryxzone;` runs:

	%_countryxzone(cds_ctryxzone=&G_PING_COUNTRYxZONE, 
				   cfg=&G_PING_AGGREGATES/config, 
				   clib=&G_PING_LIBCFG);

### Example
Generate the table `COUNTRYxZONE` in the `WORK` directory:

	%_countryxzone(clib=WORK);

### See also
[%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_to_zone](@ref sas_ctry_to_zone), [%str_isgeo](@ref sas_str_isgeo),
[%_zonexyear](@ref cfg_zonexyear).
