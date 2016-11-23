## sql_list {#sas_sql_list}
Transform an unformatted list of items into a SQL-compatible list of comma-separated 
and/or quote-enhanced items. 

	%let sqllist = %sql_list(list, type=);

### Note
This is nothing else than a wrapper to [%list_quote]\(@ref sas_list_quote), where parentheses
`()` are added around the output list, _i.e._ the command `%let sqllist = %%sql_list(&list)` is 
equivalent to:

	%let sqllist = (%list_quote(&list, sep=%quote( ), rep=%quote(,), mark=%str(%")));

when `list` is of type `CHAR`, otherwise, when `list` if of type `NUMERIC`:

	%let sqllist = (%list_quote(&list, sep=%quote( ), rep=%quote(,), mark=_EMPTY_));

### Examples
The simple examples below:

	%let list1=DE AT BE NL UK SE;
	%let olist1=%sql_list(&list1);
	%let list2=1 2 3 4 5 6;
	%let olist2=%sql_list(&list2);

return `olist1=("DE","AT","BE","NL","UK","SE")` and `olist2=(1,2,3,4,5,6)` respectively.

### See also
[%list_quote](@ref sas_list_quote).
