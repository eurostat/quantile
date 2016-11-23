## POPULATIONxCOUNTRY {#cfg_populationxcountry}
Configuration file for population of EU countries.

### Contents
A table named after the value `&G_PING_POPULATIONxCOUNTRY` (_e.g._, `POPULATIONxCOUNTRY`) shall be defined 
in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain for 
every country in the EU+EFTA geographic area:
* total population for any year from 2003.

In practice, the table (_e.g._, what used to be `CCWGH60`) looks like this (can change owing to updates):
  GEO |  Y2003 | Y2004  |  Y2005 |  Y2006 |  Y2007 |  Y2008 |  Y2009 |  Y2010 |  Y2011 |  Y2012 |  Y2013 |  Y2014 | Y2015  
------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------
BE	  |10355844|10396421|10445852|10511382|10584534|10666866|10753080|10839905|11000638|11094850|11161642|11203992|11258434
BG	  |7845841 |7745147 |7688573 |7629371 |7572673 |7518002 |7467119 |7421766 |7369431 |7327224 |7284552 |7245677 |7202198
CZ	  |10203269|10195347|10198855|10223577|10254233|10343422|10425783|10462088|10486731|10505445|10516125|10512419|10538275
...   |  ...   |  ...   |  ...   |  ...   |  ...   |  ...   |  ...   |  ...   |  ...   |  ...   |  ...   |  ...   | ...

### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%_populationxcountry(cds_zonexyear=A, cfg=B, clib=C);

Note that, by default, the command `%%_populationxcountry;` runs:

	%_populationxcountry(cds_popxctry=&G_PING_POPULATIONxCOUNTRY, 
						 cfg=&G_PING_ESTIMATION/config, 
						 clib=&G_PING_LIBCFG);

### Example
Generate the table `POPULATIONxCOUNTRY` in the `WORK` directory:

	%_populationxcountry(clib=WORK);

### See also
[%ctry_population](@ref sas_ctry_population), [%zone_population](@ref sas_zone_population).
