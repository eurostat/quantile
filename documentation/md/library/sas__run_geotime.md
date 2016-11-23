## _run_geotime {#sas__run_geotime}
Run a given macro for every single year and zone of any given periods and geographical areas.

	%_run_geotime(time, geo, process=, macro_arguments...);

### Arguments
* `time` : (list of) period(s)/year(s) considered for calculation; 
* `geo` : (list of) country(ies)/geographical zone(s) considered for calculation;                                              
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
