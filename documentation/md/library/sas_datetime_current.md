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

