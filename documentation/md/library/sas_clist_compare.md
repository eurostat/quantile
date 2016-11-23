## clist_compare {#sas_clist_compare}
Compare two lists of comma-separated and quote-enhanced items, _i.e_ check whether the items 
in one list differ from those in another not taking into account any order or repetition(s).
	
	%let ans=%clist_compare(clist1, clist2, casense=no, mark=%str(%"), sep=%quote(,));

### Arguments
* `clist1, clist2` : two lists of items comma-separated by a delimiter (_e.g._, quotes) and in 
	between parentheses;
* `casense` : (_option_) boolean flag (`yes/no`) set to perform cases sensitive search/matching; default:
	`casense=no`, _i.e._ the upper-case elements in both lists are matched;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep=%%quote(,)`, _i.e._ the input `clist1` and
	`clist2` are both comma-separated lists of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) 
	for further details.
 
### Returns
`ans` : the boolean result of the comparison test, i.e.:
		+ `0` when both lists are equal: `list1 = list2`,
		+ `-1` when `clist1` items are all included in `clist2` (but the opposite does not stand):
			say it otherwise: `list1 < list2`,
		+ `1` when `clist2` items are all included in `clist1` (but the opposite does not stand):
			say it otherwise: `list1 > list2`,
		+ empty (_i.e._ `ans=`) when they differ.

### Examples

	%let clist1=("DE","AT","BE","NL","UK","SE");
	%let ans=%clist_compare(&clist1, &clist1);

returns `ans=0`, while:

	%let clist2=("AT","BE","NL");
	%let ans=%clist_compare(&clist1, &clist2);
	
returns `ans=1`.

Run macro `%%_example_clist_compare` for more examples.

### Note
The macro will not return exactly what you want if the symbol £ appears somewhere in the list.

### See also
[%list_compare](@ref sas_list_compare), [%clist_unquote](@ref sas_clist_unquote).
