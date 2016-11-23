/**  
## datetime_current {#sas_datetime_current}
Returns a formatted timestamp string from the current datetime.

	%let dt=datetime_current(stamp=, sep=_);

### Arguments
`sep` : (_option_) flag setting the returned time stamp to `second` (`s`), minute (`mn`), `hour` 
	(`h`), `day` (`d`), `month` (`mth`) or `year` (`y`) only; default: not considered;
`sep` : (_option_) parameter defining the separator between day and time (see below); default: 
	`sep=_` (simple underscore).
  
### Returns
`dt` : the current datetime formatted in the following way: `<day><sep><time>`.

### Example
Display the current datetime:

	%put Current datetime is: %datetime_current();

or the current year:

	%put Current year is: %datetime_current(stamp=year);

Run macro `%%_example_datetime_current`.

### References
1. [SAS date, time, and datetime functions](http://support.sas.com/documentation/cdl/en/etsug/63939/HTML/default/viewer.htm#etsug_intervals_sect014.htm).
2. [About SAS date, time, and datetime values](http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#a002200738.htm).
3. [SAS date, time, and datetime functions](http://www.sfu.ca/sasdoc/sashtml/ets/chap3/sect13.htm).
4. Carpenter, A.L. (2005): ["Looking for a Date? A tutorial on using SAS dates and times"](http://analytics.ncsu.edu/sesug/2005/TU04_05.PDF).
5. Milum, J. (2008): ["How to read, write, and manipulate SAS dates"](http://analytics.ncsu.edu/sesug/2008/HOW-063.pdf).
6. Morgan, D. (2015): ["The essentials of SAS dates and times"](http://support.sas.com/resources/papers/proceedings15/1334-2015.pdf).

### See also

*/ /** \cond */

%macro datetime_current(stamp= 	/* Flag setting time stamp to second, hour, day or year only 	(OPT) */
					, sep=		/* Separator used between day and time 							(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %symexist(G_PING_LIST_SEPARATOR) %then 	%let DEF_SEP=&G_PING_LIST_SEPARATOR;
	%else 									%let DEF_SEP=_; 
	%if %macro_isblank(sep) %then 	%let sep=&DEF_SEP;

	%local date	/* date of today */
		time	/* current time */
		clock 	/* associated timing */
		STAMPS; /* accepted time divisions */
	%let STAMPS=YEAR Y MONTH MTH DAY D HOUR H MINUTE MN SECOND S;

	%if %macro_isblank(stamp) %then %do;
		/* method 1 */
		%let date=%sysfunc(date(), date.); /* today */
		%let time=%sysfunc(time(), time.);
		%let clock = %sysfunc(compress(%sysfunc(translate(%quote(&time), " ", ":"))));
		/* method 2
		%let dt      = %sysfunc(datetime(),datetime.);
		%let ipos=%sysfunc(find(%quote(&dt), :));
		%let day=%scan(%quote(&dt),1, :);
		%let len=%length(&dt);
		%let hour=%substr(%quote(&dt), &ipos, %eval(&len-&ipos+1));
		%let hour = %sysfunc(compress(%sysfunc(translate(%quote(&hour), " ", ":"))));
		%let dt=&day._&hour;
		method 3
		%let dt = %sysfunc(datetime());
	   	%let d=%sysfunc(datepart(&dt));
	   	%let t=%sysfunc(timepart(&dt));
	   	%let h=%sysfunc(hour(&t));
	   	%let m=%sysfunc(minute(&t));
	   	%let s=%sysfunc(second(&t));
		/* to return timestamp in the form yyyy-mm-dd-hh-ss.sss 
	   	%let dt =%sysfunc(putn(&d,yymmdd10.))&sep.%sysfunc(putn(&h,z2.))&sep.%sysfunc(putn(&m,z2.))&sep.%sysfunc(putn(&s,z6.3));
		*/
		/* return the output formatted datetime */
		&date.&sep.&clock
	%end;
	%else %do;
		%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&stamp), type=CHAR, set=&STAMPS) NE 0, mac=&_mac,		
			txt=!!! Wrong input value for parameter STAMP: must be in &STAMPS !!!) %then
		%goto exit;

		%let dt = %sysfunc(datetime());
		/* %let date=%sysfunc(date()); 
		%let time=%sysfunc(time()); */
	   	%let date=%sysfunc(datepart(&dt));
	   	%let time=%sysfunc(timepart(&dt));

		%local p;
		%let p=%sysfunc(substr(%upcase(&stamp),1,1));

		%if &p=S %then %do;
			%sysfunc(second(&time))
		%end;
		%else %if &p=M %then %do;
			%if %upcase(&stamp)=MONTH or %upcase(&stamp)=MTH %then %do;
				%sysfunc(month(&date))
			%end;
			%else /* %if %upcase(&stamp)=MINUTE or %upcase(&stamp)=MN */ %do;
				%sysfunc(minute(&time))
			%end;
		%end;
		%else %if &p=H %then %do;
			%sysfunc(hour(&time))
		%end;
		%else %if &p=D %then %do;
			%sysfunc(day(&date))
		%end;
		%else %if &p=Y %then %do;
			%sysfunc(year(&date))
		%end;
	%end;

	%exit:
%mend datetime_current;

%macro _example_datetime_current;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%let dt=;
	%put;
	%put (i) Display current datetime;
	%put    * with function 'datetime': %sysfunc(datetime(),datetime.);
	%put    * with macro 'datetime_current' is: %datetime_current();

	%put;
	%put (ii) Display various date/time stamps;
	%put    * year=%datetime_current(stamp=year);
	%put    * month=%datetime_current(stamp=month);
	%put    * hour=%datetime_current(stamp=hour);
	%put    * minute=%datetime_current(stamp=minute);
	%put    * second=%datetime_current(stamp=second);

%mend _example_datetime_current;

/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_datetime_current; 
*/

/* more testing: 
%global adate;
%macro fdate(fmt);
   data _null_;
      call symput("adate",left(put("&sysdate"d,&fmt)));
   run;
%mend fdate;

%fdate(worddate.)
%put "Tests for &adate";
*/

/** \endcond */
