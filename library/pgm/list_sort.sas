/** 
## list_sort {#sas_list_sort}
Sort a list of numeric values in ascending or descending order.

	%list_sort(list, _list_=, order=asc, sep=%quote( ));

### Arguments
* `list` : list of numeric items that will be sorted;
* `order` : (_option_) string defining ascending (`asc`) or descending (`desc`) order; default: 
	`order=asc`; 
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` 
	is blank.
 
### Returns
`_list_` : output ordered list.

### Example
let us consider the following simple example:

	%let list=4.5 21 1 -1 0.2 -8 65 7.8;
	%let olist=;
	%list_sort(&list, _list_=olist);

it will return `olist=-8 -1 0.2 1 4.5 7.8 21 65`.

Run macro `%%_example_list_sort` for examples.

### Note
In short, this macro runs, in the case `order=asc`, the following operations:

	%list_to_var(&list, tmpval, tmpdsn, fmt=best32., sep=&sep);
	%ds_sort(tmpdsn, asc=tmpval);
	%var_to_list(tmpdsn, tmpval, _varlst_=&_list_, sep=&sep);

### See also
[%ds_sort](@ref sas_ds_sort), [%list_permutation](@ref sas_list_permutation), 
[%list_to_var](@ref sas_list_to_var), [%var_to_list](@ref sas_var_to_list).
*/ /** \cond */

%macro list_sort(list		/* Input list of numeric values 			(REQ) */
				, _list_=	/* Output ordered list 						(REQ) */
				, order=	/* String defining the order 				(OPT) */
				, sep=		/* String separator of items in the list	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(sep) %then 	%let sep=%quote( );
	%if %macro_isblank(order) %then %let order=ASC;

	%if %error_handle(ErrorInputParameter,
			%par_check(%upcase("&order"), type=CHAR, set="ASC" "DESC") NE 0, mac=&_mac,
			txt=%quote(!!! Wrong parameter ORDER: must be ASC or DESC !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _tmp; 	/* temporary dataset used to order the list */
	%let _tmp=_TMP&_mac;

	/* convert the list in a numeric variable of a table */
	%list_to_var(&list, value, &_tmp, fmt=best32., sep=&sep);

	/* sort the table */
	%ds_sort(&_tmp, 
		%if %upcase("&order")="ASC" %then %do;
			asc=value
		%end;
		%else %if %upcase("&order")="DESC" %then %do;
			desc=value
		%end;
		);
	/* convert back the variable into the desired list */
	%var_to_list(&_tmp, value, _varlst_=&_list_, sep=&sep);

	%work_clean(&_tmp);

	%exit:
%mend list_sort;


%macro _example_list_sort;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%local list olist rlist;
	%let olist=;

	%put;
	%put (i) Crash test with dummy parameters;
	%list_sort(&list, order=DUMMY, _list_=olist);
	%if %macro_isblank(olist) %then 	%put OK: TEST PASSED - Operation crashed;
	%else 								%put ERROR: TEST FAILED - Operation did not crash;
	
	%let list=4.5 21 1 -1 0.2 -8 65 7.8;
	%put;
	%put (ii) Sort the list &list;
	%list_sort(&list, _list_=olist);
	%let rlist=-8 -1 0.2 1 4.5 7.8 21 65;
	%if %quote(&olist) = %quote(&rlist) %then 	%put OK: TEST PASSED - Correctly sorted list: &rlist;
	%else 										%put ERROR: TEST FAILED - Wrongly sorted list: &olist;

	%put;
%mend _example_list_sort;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_sort;
*/

/** \endcond */
