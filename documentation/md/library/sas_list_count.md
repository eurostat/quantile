## list_count {#sas_list_count}
Count the number of occurences of an element in a (blank separated) list. 

	%let count=%list_count(list, item, casense=no, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `item` : a string defining the pattern to count for the occurrence of appearance in input `list`;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case pattern `item` will be searched/matched;
* `sep` : (_option_) character/string separator in input `list`; default: `%%quote( )`, _i.e._ `sep` is 
	blank.
 
### Returns
`count` : output count number, _i.e._ the number of times the element `item` appears in the list; note 
	that when the element `item` is not found in the input list, it returns `count=0` as expected.

### Examples
Let us consider a simple example:

	%let list=NL UK AT DE AT BE AT;
	%let count=%list_count(&list, AT);

which returns `count=3`. 	

Run macro `%%_example_list_count` for more examples.

### See also
[%list_slice](@ref sas_list_slice), [%list_find](@ref sas_list_find), [%list_remove](@ref sas_list_remove), 
[%list_length](@ref sas_list_length).
