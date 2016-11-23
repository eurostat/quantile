## list_remove {#sas_list_remove}
Remove one or more items from an unformatted list. 

	%let res=%list_remove(list, item, casense=no, sep=%quote( ));

### Arguments
* `list` : a list of blank separated strings;
* `item` : (list of) item(s) to remove from the list;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the all (low-case or upper-case) occurrences of the pattern `item` will be removed;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` 
	is blank.
 
### Returns
`res` : output list where all occurences of the item(s) present in both `item` and `list` lists 
	have been removed.

### Examples

	%let list=DE AT BE NL AT SE;
	%let mylist=%list_remove(&list, AT);
	
returns: `mylist=DE BE NL SE`, while similarly:
 
	%let list=0 0.1 1 2 3 3.5 4;
	%let mylist=%list_remove(&list, 0.1 3 4);
	
returns: `mylist=0 1 2 3 3.5`.

Run macro `%%_example_list_remove` for more examples.

### See also
[%list_count](@ref sas_list_count), [%list_compare](@ref sas_list_compare), [%list_slice](@ref sas_list_slice), 
[%list_append](@ref sas_list_append).
