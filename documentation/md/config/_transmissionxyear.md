## TRANSMISSIONxYEAR {#cfg_transmissionxyear}
Configuration file for the yearly definition of format (longitudinal, cross-sectional or reconsilied/regular)
of microdata transmission files.

### Contents
A table named after the value `&G_PING_TRANSMISSIONxYEAR` (_e.g._, `TRANSMISSIONxYEAR`) shall be defined 
in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain for 
every type of file transmitted ("early", "cross-sectional" or "longitudinal") and every single year:
* format of the file actually transmitted: longitudinal (`l`), cross-sectional (`c`) or reconsilied/regular 
(`r`).

In practice, the table looks like this (can change owing to updates):
 geo | transmission |  Y2003 | Y2004  |  Y2005 |  Y2006 |  Y2007 |  Y2008 |  Y2009 |  Y2010 |  Y2011 |  Y2012 |  Y2013 |  Y2014 | Y2015  |
:---:|:------------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|
  .  |      L	   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    r   |    r   |
  .  |      X	   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    r   |    r   |
  .  |      E	   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    e   |    e   |    e   |
 AT  |      L	   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    r   |    r   |
 AT  |      X	   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    r   |    r   |
 AT  |      E	   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    e   |    e   |    e   |
 BE  |      L	   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    l   |    r   |    r   |
 BE  |      X	   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    c   |    r   |    r   |
 BE  |      E	   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    .   |    e   |    e   |    e   |
 ... |      ...	   |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |   ...  |

### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%_transmissionxyear(cds_transxyear=A, cfg=B, clib=C);

Note that, by default, the command `%%_transmissionxyear;` runs:

	%_transmissionxyear(cds_transxyear=&G_PING_TRANSMISSIONxYEAR, 
						cfg=&G_PING_INTEGRATION/config, 
						clib=&G_PING_LIBCFG);

### Example
Generate the table `TRANSMISSIONxYEAR` in the `WORK` directory:

	%_transmissionxyear(clib=WORK);

### See also
[%silc_db_locate](@ref sas_silc_db_locate).
