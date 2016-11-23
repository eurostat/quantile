## list_replace {#sas_list_replace}
Find and replace all the occurrences of (an) element(s) in a list.

	%let rlist=%list_replace(list, old, new, startind=1, startpos=1, casense=no, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `old` : (list of) string(s) defining the pattern(s)/element(s) to replace for in the input list `list`;
* `new` : (list of) string(s) defining the replacement pattern(s)/element(s) in the output list `rlist`;
	this list must be of length 1 or same length as `old`;
* `startind` : (_option_) specifies the index of the item in `list` at which the search should start; 
	incompatible with option `startind` above; default: `startind`, _i.e._ it is not considered;
* `startpos` : (_option_) specifies the position in `list` at which the search should start; default: 
	`startpos=1`; incompatible with option `startind` above; default: `startpos`, _i.e._ it is not 
	considered;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ all lower- and upper-case occurrences of the pattern in `old` will be replaced;
* `sep` : (_option_) character/string separator in input `list`; default: `%%quote( )`, _i.e._ `sep` is 
	blank.
 
### Returns
`rlist` : output list of indexes where all the elements of `old` present in `list` have been replaced by
	the corresponding elements in `new` (_i.e._ in the same position in both `old` and `new` lists). 

### Examples
Let us consider a simple example:

	%let list=NL UK AT DE AT BE AT;
	%let rlist=%list_replace(&list, AT DE, FR IT);

which returns `rlist=NL UK FR IT FR BE FR`. 	

Run macro `%%_example_list_replace` for more examples.

### Notes
1. Three configurations are accepted for the input lists `old` and `new` of lengths `n` and `m` 
respectively:
	 + `n=1` and `m>=1`: all the occurrences of the single item present in `old` will be replaced by the 
	 list `new`, or
	 + `m=1` and `n>=1`: items in list `old` will be all replaced by the single  item in `new`, or 
	 + `n=m`: the `i`th item of `old` will be replaced by the `i`th item of `new`; 
otherwise, when `n ^= m`, an error is reported. 
2. In practice, when you run a single change on a list, _e.g._ something like:

       %let rlist=%list_replace(&list, &old, &new);
with both `old` and `new` of same length, one should verify that for:

    %let olist=%list_ones(%list_count(&list, &old), item=&new);
	%let ind=%list_find(&list, &old);
the following equality holds: `%list_index(&rlist, &ind) = &olist`.  			

### See also
[%list_find](@ref sas_list_find), [%list_index](@ref sas_list_index), [%list_remove](@ref sas_list_remove), 
[%list_count](@ref sas_list_count), [%list_length](@ref sas_list_length),
[FIND](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002267763.htm).
