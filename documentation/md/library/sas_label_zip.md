## label_zip {#sas_label_zip}
Zip items from a start and end item list following inclusion/exclusion rules so as to correspond to 
the formatted categories of a single label.

	%let cat=%label_zip(start, end, sexcl=, eexcl=, type=, sep=%str( ));

### Arguments
* `start` : (list of) starting item(s), _i.e._ the lower bound of values to consider in the categories
	of a label;
* `end` : (list of) ending item(s), _i.e._ the upper bound of category; must be the same length as 
	`start` above; the items in `end` are possibly equals to those in `start` when a single value is 
	to be considered;
* `sexcl` : (_option_) list of boolean flag(s) (`Y/N`) set to exclude items from the starting list;
	when the item in i-th position in `sexcl` is set to `Y`, then the item in the same position in 
	`start` will be excluded from the label (_i.e._ regarded as lower bound); when set, must be the 
	same length as `start` above; default: not set, as if it was set to `N` for all items in `start`;
* `eexcl` : (_option_) ibid for excluding items of the ending list from the categories associated to
	the label; default: not set, as if it was set to `N` for all items in `end`;
* `type` : (_option_) flag set to the type of the considered lists, _i.e._ either numeric (`N`) or 
	char (`C`); default: 'N', _i.e._ the lists are processed as if they were of NUMERIC type;
* `sep` : (_option_) character/string separator in input list; default: `%%str( )`.
 
### Returns
`cat` : concatenated list (_i.e._, comma-separated whenever the length of input `start` and `end` 
	lists is >1) of items zipped from `start` and `end`; when considering lists of length 1, say it
	otherwise: `start=s` and `end=e`, then the zipping rule writes:
		* `s` if `s=e`, or
		* `s-e` if `s<>e` and `sexcl=N, eexcl=N`, or
		* `s<-e` if `s<>e` and `sexcl=Y, eexcl=N`, or
		* `s-<e` if `s<>e` and `sexcl=N, eexcl=Y`, or
		* `s<-<e` if `s<>e` and `sexcl=Y, eexcl=Y`,

	if the label if of type 'N'. This can be easily extended for labels of type 'C', and extrapolated
	for lists of length >1 so as to be read like a category label.

### Examples
Given two NUMERIC start/end lists and the corresponding exclusion rules:

	%let start= 1  2  4     3  8;
	%let end=   1  2  HIGH  5  10;
	%let sexcl= N  N  Y     Y  N;
	%let eexcl= N  N  N     Y  N;

it is possible to retrieve the categorisation of the derived label using:

	%let cat=%label_zip(&start, &end, sexcl=&sexcl, eexcl=&eexcl);

which returns `cat=1, 2, 4<-HIGH, 3<-<5, 8-10`.	In the case of a CHAR lists, we can run:

	%let start=000 OTHER 1 A B;
	%let end=&start;
	%let cat=%label_zip(&start, &end, type=C);		

which returns `cat=`"000", "OTHER", "1", "A", "B".

Run macro `%%_example_label_zip` for more examples.

### Notes
1. This can be used to define the unique categorization associated to a single label. Say it otherwise,
given the format `myformat` below, with one label `A` only, stored in a table `TMP`:

	PROC FORMAT library=WORK.formats cntlout=TMP;	
  		VALUE myformat 
			1-3, 5, 10<-HIGH = "A";
	run;
It is then possible to retrieve the categorisation of `A` since the following commands:

	%let start=; %let end=; %let sexcl=; %let eexcl;
	%var_to_list(TMP, START, _varlst_=start);
	%var_to_list(TMP, END, _varlst_=end);
	%var_to_list(TMP, SEXCL, _varlst_=sexcl);
	%var_to_list(TMP, EEXCL, _varlst_=eexcl);
	%let list=%label_zip(&start, &end, sexcl=&sexcl, eexcl=&eexcl);		
will return `list=1-3, 5, 10<-HIGH`. 
2. Note the following possible use of `%%list_` based macros:

	   %let labels=%list_append(
				%list_append(
					%list_sequence(start=1, end=36, step=5), 
					%list_sequence(start=5, end=40, step=5), 
					zip=%str(-)
					), 
				%list_quote(
					%list_append(
						%list_ones(%list_length(&start), item=Y), 
						%list_append(&start, &end, zip=%str(_)),
						zip=_EMPTY_
						),
					rep=_BLANK_
					), 
				zip=%str(=)
				);
which returns `labels=`1-5="Y1_5" 6-10="Y6_10" 11-15="Y11_15" 16-20="Y16_20" 21-25="Y21_25" 26-30="Y26_30" 31-35="Y31_35" 36-40="Y36_40".

### References
Smiley, C.A. (1999): ["A fast format macro – How to quickly create a format by specifying the endpoints"](http://www2.sas.com/proceedings/sugi24/Coders/p096-24.pdf).

### See also
[%list_append](@ref sas_list_append), [PROC FORMAT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a002473464.htm).
