## COUNTRY_ORDER {#cfg_country_order}
Provide the protocal order of EU countries.

### Contents
A table named after the value `&G_PING_COUNTRY_ORDER` (_e.g._, `COUNTRY_ORDER`) shall be defined 
in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain the 
protocol order (_i.e._, order of dissemination in table) of EU+Non-EU countries. 

In practice, the table looks like this:
geo  | ORDER
-----|-------
EU28 |	0
EU27 |	0.1
EU25 |	0.2
EU15 |	0.3
NMS12|	0.4
NMS10|	0.5
EA19 |	0.6
EA18 |	0.7
EA17 |	0.8
EA16 |	0.9
BE   |	1
BG   |	2
CZ   |	3
DK   |	4
DE   |	5
EE   |	6
IE   |	7
EL   |	8
ES   |	9
FR   |	10
HR   |	11
IT   |	12
CY   |	13
LV   |	14
LT   |	15
LU   |	16
HU   |	17
MT   |	18
NL   |	19
AT   |	20
PL   |	21
PT   |	22
RO   |	23
SI   |	24
SK   |	25
FI   |	26
SE   |	27
UK   |	28
IS   |	29
NO   |	30
CH   |	31
MK   |	32
RS   |	33
TR   |	34

### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%_country_order(cds_ctry_order=A, cfg=B, clib=C);

In order to generate the protocol order of countries only (without any mention to geographical areas),
it is necessary to set an additional keyword parameter:

	%_country_order(cds_ctry_order=A, cfg=B, clib=C, zone=no);

Note that, by default, the command `%%_country_order;` runs:

	%_country_order(cds_ctry_order=&G_PING_COUNTRY_ORDER, 
					cfg=&G_PING_ESTIMATION/config, 
					clib=&G_PING_LIBCFG, zone=yes);

### Example
Generate the table `COUNTRY_ORDER` in the `WORK` directory:

	%_country_order(clib=WORK);

### Reference
Eurostat _Statistics Explained_ [webpage](http://ec.europa.eu/eurostat/statistics-explained/index.php/Glossary:Protocol_order) 
on protocol order and country code.

### See also
[%str_isgeo](@ref sas_str_isgeo).
