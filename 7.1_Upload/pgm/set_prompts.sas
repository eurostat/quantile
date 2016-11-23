/*

%macro prompt_RBD;
* %global action CTRY geo mode tabs years;
%create_list(prompt_name=action,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=CTRY,ptype=string,penclose=yes,pmultipl=yes,psepar=) ;	
%create_list(prompt_name=geo,ptype=string,penclose=yes,pmultipl=yes,psepar=) ;	
%create_list(prompt_name=mode,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=tabs,ptype=string,penclose=no,pmultipl=yes,psepar=!) ;	
%create_list(prompt_name=years,ptype=integer,penclose=no,pmultipl=yes,psepar=) ;	
%mend prompt_RBD;


%macro prompt_RBD2;
%create_list(prompt_name=action,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=CTRY,ptype=string,penclose=yes,pmultipl=yes,psepar=) ;	
%create_list(prompt_name=dec,ptype=integer,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=flagval,ptype=string,penclose=no,pmultipl=yes,psepar=!) ;	
%create_list(prompt_name=fm,ptype=float,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=geo,ptype=string,penclose=yes,pmultipl=yes,psepar=) ;	
%create_list(prompt_name=mode,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=page,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=Section,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=tab,ptype=string,penclose=no,pmultipl=no,psepar=) ;	
%create_list(prompt_name=tabs,ptype=string,penclose=no,pmultipl=yes,psepar=!) ;	
%create_list(prompt_name=years,ptype=integer,penclose=no,pmultipl=yes,psepar=) ;	
%create_list(prompt_name=yyyy,ptype=integer,penclose=no,pmultipl=no,psepar=) ;	
%mend;
*/