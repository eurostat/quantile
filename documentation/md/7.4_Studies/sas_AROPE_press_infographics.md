## AROPE_press_infographics {#sas_AROPE_press_infographics}
Perform ad-hoc extraction for infographics publication on _AROPE_ on the occasion of the 
_International Day for the Eradication of Poverty_. 

	%AROPE_press_infographics(year, geo=, ilib=, idir=, odsn=, olib=);

### Arguments
* `year` : a (single) year of interest;
* `geo` : (_option_) a list of countries or a geographical area; default: `geo=EU28`;
* `ilib` : (_option_) name of the input library where to look for _AROPE_ indicators (see 
	note below); incompatible with `idir`; by default, `ilib` will be set to the value 
	`G_PING_LIBCRDB` (_e.g._, library associated to the path `G_PING_C_RDB`); 
* `idir` : (_option_) name of the input directory where to look for _AROPE_ indicators passed 
	instead of `ilib`; incompatible with `ilib`; by default, it is not used; 
* `odsn` : (_option_) generic name of the output datasets; default: `odsn=PC_POP_AROPE`;
* `olib` : (_option_) name of the output library; by default, when not set, `olib=WORK`;

### Returns
Two datasets are generated:
* `&odsn._TOTAL_&yy` contains the _AROPE_ table with shares of total population,
* `&odsn._RESULTS_&yy` contains the _AROPE_ table with combined shares by sex, by age, 
	by working status (from 2015 publication onwards) by household composition, and 
	by education attainment level,

(where `yy` represents the last two digits of `year`) all stored in the library passed 
through `olib`.

### Example
In order to (re)generate the tables `PC_POP_AROPE_14`, `PC_POP_AROPE_RESULTS_14` and `PC_POP_AROPE_TOTAL_14`, 
used for the graphic representations of the 2014 infographics publication below: 

<img src="../../dox/img/AROPE_press_infographics.png" border="1" width="60%" alt="AROPE infographics">

you can simply launch:

	%AROPE_press_infographics(2014);
	%ds_export(PC_POP_AROPE_RESULTS_14, fmt=csv);
	%ds_export(PC_POP_AROPE_TOTAL_14, fmt=csv);

### Note
The publication is based on the following _AROPE_ indicators:
* _PEPS01_ for the total shares, shares by sex and shares by age,
* _PEPS02_ for the shares by working status,
* _PEPS03_ for the shares by household composition,
* _PEPS04_ for the shares by education attainment level. 

### References
1. Website of the UN initiative for the _International Day for the Eradication of Poverty_: 
http://www.un.org/en/events/povertyday.
2. Websites of infographics publications on _AROPE_: 
[2015](http://ec.europa.eu/eurostat/news/themes-in-the-spotlight/poverty-day) and
[2016](http://ec.europa.eu/eurostat/news/themes-in-the-spotlight/poverty-day-2016).

### See also
[%AROPE_press_news](@ref sas_AROPE_press_news).
