/** 
## list_ones {#sas_list_ones}
Create a simple list of replicated items with given length.

	%let list=%list_ones(len, item=, sep=%quote( ));

### Arguments
* `len` : desired length of the output list;
* `item` : (_option_) item to replicate in the list; default: `item=1`, _i.e._ the list 
	will be composed of 1 only;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`.
 
### Returns
`list` : output list where `item` is replicated and concatenated `len` times.

### Examples
Simple examples like:

	%let res1= %list_ones(5);
	%let res2= %list_ones(3, a);

return `res1=1 1 1 1 1` and `res2=a a a` respectively, while it is also possible:

	%let x=1 2 3;
	%let res1=%list_ones(5, item=&x);

returns `res1=1 2 3 1 2 3 1 2 3 1 2 3 1 2 3`.

Run macro `%%_example_list_ones` for more examples.

### See also
[%list_append](@ref sas_list_append), [%list_index](@ref sas_list_index).
*/ /** \cond */

%macro list_ones(len 	/* Lenght of output list 					(REQ) */
				, item= /* Element to replicate in output list 		(OPT) */ 
				, sep=	/* Character/string used as list separator 	(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%local _list; /* output list */
	/* set default output to empty */
	%let _list=;

	%if %error_handle(ErrorInputParameter, 
			%par_check(&len, type=INTEGER, range=0) NE 0, mac=&_mac,	
			txt=!!! Parameter LEN must be a strictly positive integer !!!) %then
		%goto exit;

	%if %macro_isblank(sep) %then 	%let sep=%quote( );
	%if %macro_isblank(item) %then 	%let item=1;

	/* loop over desired length */
	%let _list=&item;
	%do i=1 %to %eval(&len -1);
		%let _list=&_list.&sep.&item;
	%end;
	
	%exit:
	&_list
%mend list_ones;

%macro _example_list_ones;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put;
	%put (i) Crash test;
	%if %macro_isblank(%list_ones(0)) %then	%put OK: TEST PASSED - Empty list returned;
	%else 									%put ERROR: TEST FAILED - Non empty list returned;

	%put;
	%let item=nessuno;
	%let len=1;
	%put (ii) Initialise a list of lenght &len with item &item;
	%if %list_ones(&len, item=&item)=&item %then	%put OK: TEST PASSED - List of length 1 equal to the item;
	%else 											%put ERROR: TEST FAILED - Wrong list of length 1;

	%put;
	%let len=5;
	%put (iii) Define a default list of lenght &len;
	%let res=1 1 1 1 1;
	%if %list_ones(&len)=&res %then		%put OK: TEST PASSED - Default list of length &len: return &res;
	%else 								%put ERROR: TEST FAILED - Wrong default list of length &len returned;

	%put;
%mend _example_list_ones;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_list_ones; 
*/

/** \endcond */
