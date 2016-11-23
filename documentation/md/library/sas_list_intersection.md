## list_intersection {#sas_list_intersection}
Calculate the intersection (list of common items) between two unformatted lists of char.

	%let isec=%list_intersection(list1, list2, casense=no, unique=yes, sep=%quote( ));

### Arguments
* `list1, list2` : two lists of unformatted strings;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive comparison/matching; 
	default: `casense=no`, _i.e._ upper-case "intersection" items in both lists are matched;
* `unique` : (_option_) boolean flag (`yes/no`) set in combination with `casense=no` so as to return 
	unique values from the input lists, independently of the case; in practice when `unique=no`, when
	two items present in the input lists with distinct (lower- and upper-) cases match through their 
	upper-case versions (_i.e._, `casense=no`), both will be kept in the intersection list; default: 
	`unique=yes`;
* `sep` : (_option_) character/string used as a separator in the input lists; default: `sep=%%quote( )`, 
	_i.e._ the input `list1` and `list2` are both blank-separated lists of items.
 
### Returns
`isec` : output list of strings, namely the list of items obtained as the intersection `list1 /\ list2`, 
	_i.e._ items common to both lists are preserved.

### Examples
We first show some simple examples of use: 

	%let list1=A B C D E F A;
	%let list2=C A B Z A;
	%let isec1=%list_intersection(&list1, &list2);
	
returns: `isec1=A B C`, while:

	%let isec2=%list_intersection(&list2, &list1);
	
returns a different: `isec2=C A B`.	Then, also note the use of case sensitiveness:
 
	%let list1=a B C D e F A;
	%let list2=C A b Z A;
	%let isec1=%list_intersection(&list1, &list2, casense=yes);
	
returns: `isec1=C A`. As for the use of the flag `unique`, note that: 

	%let isec2=%list_intersection(&list1, &list2);
	%let isec3=%list_intersection(&list1, &list2, unique=no);
	
return: `isec2=a B C` and `isec3=a B C A b` respectively, while:

	%let isec4=%list_intersection(&list2, &list1);
	%let isec5=%list_intersection(&list2, &list1, unique=no);
	
return: `isec4=C A b` and `isec5=C A b a B` respectively.

Run macro `%%_example_list_difference` for more examples.

### Notes
1. As shown in the first example above, the order the lists are passed to the macro matters. Namely, the  
items, that are common to both lists `list1` and `list2`, will be ordered in `isec` according to their
order of appearance in the first list `list1`. For that reason, `isec1` and `isec2` above differ; still, 
it can be checked that:

    %let res=%list_compare(&isec1,&isec2);
will return `res=0`, hence the sets supported by `isec1` and `isec2` are identical. Similarly, in the last
example above:

    %let res=%list_compare(&isec2,&isec4);
will return `res=0` as well (only the order of the elements in the intersection lists differs).
2. Items present multiple times in input lists `list1` and `list2` are reported only once in the output
intersection `isec`. For that reason, the item `A` in the first example above appears only once in `isec1` 
and `isec2`. Items present multiple times with both lower- and upper-cases in the input lists will be 
reported only once in the output list iif `unique=yes` and `casense=yes`.
3. The parameter `unique` is ignored when `casense=no`. 

### See also
[%list_difference](@ref sas_list_difference), [%list_compare](@ref sas_list_compare), [%list_append](@ref sas_list_append), 
[%list_find](@ref sas_list_find), [%list_unique](@ref sas_list_unique),
[FINDW](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a002978282.htm).
