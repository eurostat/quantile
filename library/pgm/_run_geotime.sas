/** 
## _run_geotime {#sas__run_geotime}
Run a given macro for every single year and zone of any given periods and geographical areas.

	%_run_geotime(time, geo, timeloop=yes, geoloop=yes, process=, macro_arguments...);

### Arguments
* `time` : (list of) period(s)/year(s) considered for calculation; 
* `geo` : (list of) country(ies)/geographical zone(s) considered for calculation;  
* `timeloop, geoloop` : (_option_) boolean flags (`yes/no`) set to specify whether loops over
	`time` and `geo` respectively should be considered, or 
	
* `process` : (_option_) name of the macro that will be ran for every `geo` area and `time`
	period; this macro must stick to the following usage:

		%&process(&year, &geo, &ctries, &macro_arguments);
	where `year` is one period taken from `time`, and `ctries` is the list of countries 
	included in the area represented by `geo`, while `geo` is the same as above; default: 
	`process` is set to a macro `_process_geotime` which must be defined; in practice, the
	macro is ran using `%%macro_execute`;
* `macro_arguments...` : (_option_) whatever additional (positional or keyword) arguments 
	taken by the macro `%&process`.

### Returns
... whatever the original macro `%&process` returns.

### Notes
1. In short, this macro essentially runs a loop over considered period/geographical areas,
_e.g._:

	%do _iy=1 %to %list_length(&time);		
	    %let _yyyy=%scan(&time, &_iy);
		%do _ig=1 %to %list_length(&geo); 
	        %let _geo=%scan(&geo, &_ig);
		    %zone_to_ctry(&_geo, time=&_yyyy, _ctrylst_=_ctry);
		    %macro_execute(&process, &_yyyy, &_geo, &_ctry, &arguments);
		%end;
	%end; 
2. In the case the macro `%&process` takes both positional and keyword arguments, then the above 
keyword argument `process=` to `%_run_geotime` macro shall be inserted after the positional 
arguments of `%&process` in the list `macro_arguments`. Say it otherwise, let us say that a 
given macro `%_process` is used as follows:

	%_process(year, geo, ctries, a, b, c=, d=);
then the generic running of this function shall be written as:

	%_run_geotime(time, geo, a, b, process=_process, c=, d=);

### See also
[%macro_execute](@ref sas_macro_execute), [%_process_geotime](@ref sas__process_geotime), 
[%str_to_keyvalue](@ref sas_str_to_keyvalue).
*/ /** \cond */


%macro _run_geotime/parmbuff;
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	%local process	/* macro to run */
		KEY			/* keyword for finding process */
		SEP			/* string separator used in syspbuff */
		DEBUG; 		/* boolean flag used for debug mode */
	%if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
	%else								%let DEBUG=0;
	%let process=;
	%let SEP=%str(,);
	%let KEY=process;

	/* get rid of the parentheses */
	%let syspbuff=%sysfunc(substr(&syspbuff, 2, %eval(%sysfunc(length(&syspbuff))-2)));

	%local geo		/* geographical area(s) */
		time		/* period/year(s) */
		arguments;	/* list of arguments to be passed to the macro */

	/* retrieve GEO and TIME variables (in this order) */
	%let time=%scan(%quote(&syspbuff), 1, &SEP);
	%let geo=%scan(%quote(&syspbuff), 2, &SEP);
		
	/* retrieve the arguments */
 	%let syspbuff=%list_slice(%quote(&syspbuff), ibeg=3, sep=&SEP);
	%str_to_keyvalue(%quote(&syspbuff), key=&KEY, _value_=process, _str_=arguments, sep=%quote(,));

	%local _ans	/* temporary test answer */
		_iy 	/* loop increment for year */
		_ig		/* loop increment for country */
		ntime	/* number of periods considered */
		ngeo	/* number of countries considered */
		_yyyy	/* scanned year from TIME */
		_geo	/* scanned country/zone from GEO */
		_ctry;	/* list of countries retrieved from _geo */

	/* retrieve the list of correct geos */
	%str_isgeo(&geo, _geo_=geo); 

	/* retrieve the list of ordered years */
	%list_sort(&time, _list_=time); 
	
	/* compute the length of the resulting lists (unchanged for time, possibly shorter
	* for geo) */
	%let ngeo=%list_length(&geo);
	%let ntime=%list_length(&time);

	%if %macro_isblank(process) %then %do;
		%if %symexist(G_PING_MPROCESS_GEOTIME) %then	%let process=&G_PING_MPROCESS_GEOTIME;
		%else											%let process=_process_geotime;
	%end;

	%macro_exist(&process, _ans_=_ans);
	%if %error_handle(ErrorInputProcess, 
			&_ans = 0, mac=&_mac,		
			txt=!!! Process defined as %upcase(&process) not found !!!) %then
		%goto exit;
	
	%macro_put(&_mac, txt=%quote(Loop over a &ntime-period));

	/* run the operation (generation+update) for:
	 * 	- all years in &TIME, and 
	 * 	- all countries/zones in &geos */
	%do _iy=1 %to &ntime;		/* loop over the list of input TIME */

		%let _yyyy=%scan(&time, &_iy);

		%macro_put(&_mac, txt=%quote(Loop over &ngeo zones/countries for year &_yyyy)); 

		/* run the operation (generation+update) for:
		 * 	- one single year &_yyyy, and 
		 * 	- all countries/zones in &geos */
		%do _ig=1 %to &ngeo; 		/* loop over the list of countries/zones */

			%let _geo=%scan(&geo, &_ig);
			%zone_to_ctry(&_geo, time=&_yyyy, _ctrylst_=_ctry);
			%macro_execute(&process, &_yyyy, &_geo, &_ctry, &arguments);
		%end; 

	%end; 

	%exit:
%mend _run_geotime;

%macro _example__run_geotime;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	
	%macro dummy(time, geo, ctry, arg);
		%put process geo=&geo / time=&time / ctry=&ctry / arg=&arg;
	%mend dummy;

	%let year=2010 2011 2013;
	%let geo=AT BE EU28;

	%_run_geotime(&year, &geo, process=dummy, whatever);
%mend;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_run_geotime; 
*/

/** \endcond */
