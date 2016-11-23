## list_compare {#sas_list_compare}
Compare two lists of characters/strings, _i.e_ check whether the items in one list differ
from those in another not taking into account any order or repetition(s).

	%list_compare(list1, list2, casense=no, sep=%quote( ));

### Arguments
* `list1, list2` : two lists of items;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case elements in both lists are matched;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ 
	items are separated by a blank.

### Returns
`ans` : the boolean result of the comparison test of the "sets" associated to the input lists, 
	i.e.:
		+ `0` when both lists are equal: `list1 = list2`,
		+ `-1` when `list1` items are all included in `list2` (but the opposite does not stand):
			say it otherwise: `list1 < list2`,
		+ `1` when `list2` items are all included in `list1` (but the opposite does not stand):
			say it otherwise: `list1 > list2`,
		+ ` ` (_i.e._ `ans=`) when they differ.

### Examples
Simple examples (with `casense=yes` by default):

	%let list1=NL UK DE AT BE;
	%let list2=DE AT BE NL UK SE;
	%let ans=%list_compare(&list1, &list2);
	
returns `ans=-1`, while:

	%let ans=%list_compare(&list2, &list1);

returns `ans=1`, and:

	%let list1=NL UK DE AT BE;
	%let list2=DE NL AT UK BE;
	%let ans=%list_compare(&list1, &list2);

returns `ans=0`. We also further use the case sensitiviness (`yes/no`) for comparison:

	%let list1=NL uk de AT BE;
	%let list2=DE NL at UK be;
	%let ans1=%list_compare(&list1, &list2, casense=yes);
	%let ans2=%list_compare(&list1, &list2);

return `ans1=` (_i.e._ list differ) and `ans2=0` (_i.e._ lists are equal with default `casense=no`).

Run macro `%%_example_list_compare` for examples.

### Notes
* If one of the lists is empty, then the result is empty (set to `ans=`).
* If elements are duplicated in a list, `%%list_compare` may still return `0`, for instance:

        %let list1=NL DE AT BE;
	    %let list2=DE AT NL BE NL BE;
	    %let ans=%list_compare(&list1, &list2);
returns `ans=0`...	

### See also
[%clist_compare](@ref sas_clist_compare), [%list_remove](@ref sas_list_remove), [%list_count](@ref sas_list_count), 
[%list_slice](@ref sas_list_slice),
[TRANWRD](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000215027.htm),
[FINDW](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002978282.htm).
