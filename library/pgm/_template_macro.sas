/** \cond */  /* (this line shall be deleted) */
/** (!!! keep this line free !!!)
## your_macro {#sas_your_macro}
(Put here a brief description of the macro/program purpose, for instance:)
Does a great job.

	%your_macro(a, b, _c_, d=, e=1, f=lib);

### Arguments
(Put below the description of the main input arguments, for instance:)
* `a` : first input parameter;
* `b` : second input parameter;
* `d` : (_option_) some parameter; default: `d` is not used;
* `e` : (_option_) numeric parameter; default: `e=1`;
* `f` : (_option_) library parameter; default: `f=lib`.

### Returns
(Ibid, with output arguments, for instance:)
`_c_` : output parameter.

### Examples
(Provide some practical example of use, including some sample code, for instance:)
Run macro `%%_example_your_macro`.

### Note
(Additional notes/comments/issues to point out, for instance:)
Visit the link <http://www.your_macro.html>.

### See also
(Mention here other related macros/programs, for instance:) 
[another_macro](@ref sas_another_macro), [another_program](@ref sas_another_program).
(!!! Keep the line below as it appears !!!)
*/ /** \cond */ 

/* main macro your_macro */
%macro your_macro(/*input*/	 a, b, 
				  /*output*/ _c_, 
				  /*option*/ d=, e=1, f=lib);
	/* various checkings */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_c_) EQ 1,		
			txt=!!! Output macro variable %upcase(_c_) not set !!!) %then
		%goto exit;

	/* some default settings */
	%if %macro_isblank(d) %then 	%let d=a; 

	/*
	 * core of your macro: whatever you want to do
	 */
	%local _c;
	%let _c=%eval(&a + &b/&e);
	%let _c = &d.&_c;

	/* return some output */
	data _null_;
		call symput("&_c_","&_c");
	run;

	%exit:
%mend your_macro;

/* example of use of macro your_macro */
%macro _example_your_macro;
	/* specify the working path. When running separately, the example may not "access"
	 * all environment settings that are generally passed through an autoexec. Therefore,
	 * it needs to be set here if not earlier. Plus, we make some arbitrary decision here
	 * about where to look for the setup file */
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	/* inputs: set some local parameters of your own */
	%local a b e f;
	%let a=1;
	%let b=2;
	%let d=b;
	%let e=1;
	%let f=dummy;
	/* output: define the expected results */
	%local o_cres cres;

	/* run and test your macro with these parameters */
	%let o_cres=b1;
	%put;
	%put (i) Show some example with selecte input &a, &b, &d, &e, &f, and expected result &o_cres;
	%your_macro(&a, &b, _c_=cres, d=&d, e=&e, f=&f);
	%if &cres EQ &o_cres %then 	%put OK: TEST PASSED - result &o_cres returned;
	%else 						%put ERROR: TEST FAILED - wrong result returned;

	/* note that in the case of the '_c_' parameter, we passed the name of the macro
	variable (c) and not its value (&c) */
	%put display your result: c=&cres;

%mend _example_your_macro;

/* (You will uncomment this line when you run your example) */
/* 
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_your_macro;  
*/

/* (!!! Keep the line below as it appears !!!) */
/** \endcond */