/** 
## _egp_geotime {#sas__egp_geotime}
Create the ordered lists of countries and periods from the multiple choices prompt in the client 
SAS EG project (similar to SAS EG version prior to 4.1).

	%_egp_geotime(_time_=, _geo_=, pmultipl=yes);

### Arguments
* `_geo_` : name of the variable associated to the `geo` prompt, _i.e._ the one returned
	from the selection of a list of countries/zones; a prompt with this name must exist;                                             
* `_time_` : (_option_) name of the variable associated to the `time` prompt, _i.e._ the 
	one returned from the selection of periods/years for calculation; a prompt with this 
	name must exist;
* `pmultipl` : (_option_) boolean flag (`yes/no`) set for multiple option selection; default:
	`pmultipl=yes`.

### Returns
* in `&_time_`, the ordered list of periods;
* in `&_geo_`, the updated list of countries/zones, where the zones appear at the end.                                                             

### Example
Given the following prompt (with multiple selections) and the corresponding selections:
<img src="../../dox/img/_egp_geotime.png" width="70%" alt="!!! prompt geo/time !!!">
where the names of the prompt have been set respectively (from top to bottom, highlighted in red) 
to `geo` and `time`, the call:

	%_egp_geotime(_time_=time, _geo_=geo, pmultipl=yes);

will return: `geo=BE CY AT EU28` (`DUMMY` not selected and `EU28` put at the end of the list)
and `time=2004 2005 2010 2012 2013 2014` (list ordered).

### See also
[%_egp_prompt](@ref sas__egp_prompt), [%list_sort](@ref sas_list_sort),
[%_run_geotime](@ref sas__run_geotime).
*/ /** \cond */

%macro _egp_geotime(_time_=
					, _geo_=
					, pmultipl=yes
					);
	%local _mac; 
	%let _mac=&sysmacroname; 
	%macro_put(&_mac); 

	%local SEP;
	%let SEP=%quote();

	%if %error_handle(ErrorInputParameter,
			%par_check(%upcase("&pmultipl"), type=CHAR, set="YES" "NO") NE 0, mac=&_mac,
			txt=%quote(!!! Wrong value for boolean flag PMULTIPL !!!)) %then
		%goto exit;

	%if %error_handle(ErrorInputParameter,
			%macro_isblank(_geo_) EQ 1 and %macro_isblank(_time_), mac=&_mac,
			txt=%quote(!!! At least one of the parameters _GEO_ or _TIME_ needs to be set !!!)) %then
		%goto exit;

	%if not %macro_isblank(_geo_) %then %do;
		/* retrieve the list of geos */
		%if not %symexist(&_geo_) %then %do;
			%global &_geo_;
		%end;
		%_egp_prompt(prompt_name=&_geo_, ptype=STRING, penclose=no, pmultipl=yes, psepar=);

		/*%let &_geo_=%clist_unquote((&&&_geo_), mark=_empty_); /* note the use of () around the variable...*/
		%str_isgeo(&&&_geo_, _geo_=&_geo_); 
	%end;

	%if not %macro_isblank(_time_) %then %do;
		/* retrieve the list of years */
		%if not %symexist(&_time_) %then %do;
			%global &_time_;
		%end;

		%_egp_prompt(prompt_name=&_time_, ptype=INTEGER, penclose=no, pmultipl=yes, psepar=);
		/*%let &_time_=%clist_unquote((&&&_time_), mark=_empty_); */
		%list_sort(&&&_time_, _list_=&_time_); 

	%end;

	%exit:
%mend _egp_geotime;


%macro _example__egp_geotime;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put !!! &sysmacroname: Not yet implemented !!!;

	/* build an example based on two prompts:
	%symdel geo time;
	%_egp_geotime(_geo_=geo, _time_=time);
	%put geo=&geo -time=&time; */
	
%mend _example__egp_geotime;

/** \endcond */
