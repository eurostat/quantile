
/*******************************************************************************************************************/
/*******************************************************************************************************************/
/*******************************************************************************************************************/
/*                                                                                                                 */
/* Name of the macro program: create_list                                                                          */
/* Subject           : Re-create the list of choices from the multiple choices prompt as it's done in SAS/EG 4.1   */
/*                                                                                                                 */
/* Parameters of the macro-program                                                                                 */
/* prompt_name       : Name of the prompt                                                                          */
/* ptype             : Type of the prompt --> string, interger, float, date, etc...                                */
/* penclose          : If the option 'Enclosed values with quotes' was selected in SAS/EG 4.1                      */
/* pmultipl          : If the prompt is a Multiple choices vprompt                                                 */
/* psepar            : specific separator, nothing if there is no specific separator, comma is the default         */
/*                                                                                                                 */
/* Creation date     : 03/02/2012   by OKBIOSA/SAS Support                                                         */
/* Modification date : __/__/____   by ___________________                                                         */
/*                                                                                                                 */
/*******************************************************************************************************************/
/*******************************************************************************************************************/
/*******************************************************************************************************************/

%macro create_list(prompt_name=,ptype=,penclose=,pmultipl=,psepar=) ;

	%if %symexist(&prompt_name._count) %then %do; /* test if the prompt is a multiple choice */

		%if &&&prompt_name._count. > 0 %then %do;

			%let go_parm = 1 ;

				%if %sysevalf("%substr(%sysfunc(trim(%sysfunc(left(&ptype.   )))), 1, 6)" ne "string") %then %let go_parm = 0;
				/* if prompt is not string then it's a numeric format */
				%if %sysevalf("%substr(%sysfunc(trim(%sysfunc(left(&penclose.)))), 1, 1)" eq "n"     ) %then %let go_parm = 0;
				/* if the selected values don't have to be enclosed then we use eg_whereparam in the numeric method */
				%if %sysevalf("%substr(%sysfunc(trim(%sysfunc(left(&pmultipl.)))), 1, 1)" ne "y"     ) %then %let go_parm = 2;
				/* if the prompt is not a multiple choice then we don't have to make a list*/
	 
				/* test with the 2 parameters to know if the elements of the list are quoted or not*/
				/* if elements are quoted then parameter go_parm = 0 */ 

				%if &go_parm < 2 %then %do;
				
				%global separator;

					%if &go_parm. = 1 %then %do; 
			                           %if %sysevalf(&psepar. = ) % then %do;
                                                 %let wherep = %_eg_WhereParam( origin, &prompt_name., IN, TYPE=S) ; 
												                        %end;
			                           %else %do;
									             %let separator = &psepar.;
                                                 %let wherep = %sysfunc(tranwrd(%sysfunc(compbl(%_eg_WhereParam(origin,&prompt_name.,IN,TYPE=S))),
                                                                                %str(,),
                                                                                %str(&separator.)));
											 %end;
			                                %end; /* type=s add quote for each element*/
					%if &go_parm. = 0 %then %do; 
			                           %if %sysevalf(&psepar. = ) % then %do;
                                                 %let wherep = %_eg_WhereParam( origin, &prompt_name., IN, TYPE=N) ; 
												                        %end;
			                           %else %do;
									             %let separator = &psepar.;
                                                 %let wherep = %sysfunc(tranwrd(%sysfunc(compbl(%_eg_WhereParam(origin,&prompt_name.,IN,TYPE=N)))
                                                                                ,%str(,)
                                                                                ,%str(&separator.)));
											 %end;

			                                %end; /* type=s don't add quote for each element */
						%if %sysevalf(%symexist(separator)) %then %symdel separator;

						/* the "where condition" created by the macro looks like: "(origin in ( elt1, elt2, ... ) )" */
						/* we only need the list "elt1, elt2, ..."                                                   */
						/* so we need to extract the list from the where condition created by the macro              */

						%let position_in = %sysfunc(find(&wherep., IN)) ; /* calculate the position of the "in" */
						%let length_in = %sysfunc(length(&wherep.)) ;     /* calculate the length of the string */ 
				       
						%if &&&prompt_name._count. > 1 %then %do;
							%let &prompt_name. = %sysfunc(substr(&wherep., %eval(&position_in + 4) , %eval(&length_in. - &position_in. - 5 ) )) ;
							 /* extract the string needed from the "where condition" */
					    %end; 
						%if &&&prompt_name._count. = 1 %then %do;
							%let &prompt_name. = %sysfunc(substr(&wherep., %eval(&position_in + 4) , %eval(&length_in. - &position_in. - 4 ) )) ;
							 /* extract the string needed from the "where condition" */
				        %end; 
				        %put &prompt_name.: &&&prompt_name. ;
				%end;
				%else %do;
						%put Prompt &prompt_name. is not created or re-created (not a multiple selection prompt).  ;/* case of no multiple values */
				%end;

		%end;
		%else %if &&&prompt_name._count. = 0 %then %do;
					%if %symexist(&prompt_name._count) %then %put No filter selected.  ;/* case of no filters selected */
					%put test existence: %symexist(&prompt_name._count) ;
		%end;

			/**********************************************************************************************/
			/* Deletion of the PROMPT_NAMEn. macro values            ---                            Begin */
			/**********************************************************************************************/
		    

			%if %sysevalf("%substr(%sysfunc(trim(%sysfunc(left(&pmultipl.)))), 1, 1)" eq "y") %then %do;

				data supprmacro_&prompt_name.; /* creation of a table with PROMPT_NAMEn and PROMPT_NAME_count macro values */ 
			    format supprmacro $100. ;
						%do j = 0 %to &&&prompt_name._count;
							    supprmacro = upcase("&prompt_name.&j");
								output;
						%end;
						supprmacro = upcase("&prompt_name._count");
						output;
			     run;

				data supprmacro_&prompt_name.; /* deletion of the PROMPT_NAMEn and PROMPT_NAME_count macro values */ 
				set supprmacro_&prompt_name.;
				if symexist(supprmacro) then call symdel(supprmacro); /* test if the macro exists and supress it if yes */
			   	run;

				proc datasets library = work nolist; DELETE supprmacro_&prompt_name. ; run; /* deletion of dataset to free space in the work */ 

			%end;

		   	/**********************************************************************************************/
			/* Deletion of the PROMPT_NAMEn. macro values            ---                            End */
			/**********************************************************************************************/

    %end;

	%else %if %sysevalf("%substr(%sysfunc(trim(%sysfunc(left(&pmultipl.)))), 1, 1)" eq "y") %then %put Prompt &prompt_name. is not created or re-created (no need to).  ;
	                                                                                            /* case of several program with this macro */
    %else %put Prompt &prompt_name. is not created or re-created (not a multiple selection prompt).  ;/* case of no multiple selection */


%mend create_list;

