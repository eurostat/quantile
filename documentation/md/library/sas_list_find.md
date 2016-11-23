## list_find {#sas_list_find}
Find all the occurrences of an element in a list and returns the indices of its position in that 
list.

	%let ind=%list_find(list, item, startind=1, startpos=1, casense=no, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `item` : a string defining the pattern/element to look for in input `list`;
* `startind` : (_option_) specifies the index of the item in `list` at which the search should start; 
	incompatible with option `startind` above; default: `startind`, _i.e._ it is not considered;
* `startpos` : (_option_) specifies the position in `list` at which the search should start and the direction
	of the search (see argument of function `find`); default: `startpos=1`; incompatible with option
	`startind` above; default: `startpos`, _i.e._ it is not considered;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case pattern `match` will be searched/matched;
* `sep` : (_option_) character/string separator in input `list`; default: `%%quote( )`, _i.e._ `sep` is 
	blank.
 
### Returns
`ind` : output list of indexes, _i.e._ the positions of the element `item` in the list if it is found,
	and empty variable (_i.e_, `ind=`) otherwise. 

### Examples
Let us consider a simple example:

	%let list=NL UK AT DE AT BE AT;
	%let ind=%list_find(&list, AT);

which returns `ind=3 5 7`, while: 	

	%let ind=%list_find(&list, AT, startind=4);

only returns `ind=5 7`.

Run macro `%%_example_list_find` for more examples.

### See also
[%list_index](@ref sas_list_index), [%list_slice](@ref sas_list_slice), [%list_count](@ref sas_list_count), 
[%list_remove](@ref sas_list_remove), [%list_length](@ref sas_list_length),
[FIND](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002267763.htm),
[FINDW](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002978282.htm).
