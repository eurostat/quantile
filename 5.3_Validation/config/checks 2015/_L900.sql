put "title1 'Check #900 / %nrstr(&datum)';";
put "title2 '%nrstr(&ccnam) - %nrstr(&surtyp) survey %nrstr(&suryear)';";
put "title3 'Longitudinal-Error: DB075:The last rotational was not sent: (no additional rotational group for last year)';";
put "proc sql;";
put "Create table test1 as";
put "select distinct   db010,db020,count(distinct DB075) as n_db075_&RYYYY ";
put "from &ss%nrstr(&cc).&yy.d where db010=&RYYYY group by DB020, db010 ; ";
 
 
put "Create table test2 as ";
put "select distinct  db010,db020, ";
put "count(distinct DB075) as n_db075_&yyyy1 ";
put "from &ss%nrstr(&cc).&yy.d  where db010=&yyyy1  ";
put "group by DB020, db010  ; ";

 
put "Create table tempo as";
put "select a.DB010, a.n_db075_&RYYYY, b.n_db075_&yyyy1 from test1 as  a,  test2 as b";
put "where  a.n_db075_&RYYYY <= b.n_db075_&yyyy1;";
 
put "quit;";

put "proc sort data=tempo;";
put txt7;
put "run;";
    put "data tempox ;";
  put "set  tempo;";
 
put txt7;
 put "cnt +1;";

put txt8;
put "run;";
put "proc sql;";
 put "create table tempoxx as Select * from tempox";
  put "where cnt < &nrow;";
put "quit;";
put "data tempoxx (drop=cnt);";
put "set tempoxx;";
put "run;";
put "proc sql;";
put "Select * from tempo(obs=%nrstr(&errmax));";
put 'Insert into errtabl set cod = ' cod ', error = (select count(*) from tempo);';
put "QUIT;";


 put " data error1 (keep=cod time );";
 put "set tempo; ";
 put ' cod = ' cod' ;';
 put txt6;
 put "run;";
 
put "PROC SQL;";
 put "Create table sum1 as ";
put 'select cod , time, count(*) as Tyear from error1';
put "group by cod, time;";
	put "QUIT;";

put "proc transpose data=sum1 out=sumx prefix=Y_;";
   put" by cod ;";
   put " id time;";
   put " var Tyear;";
put "run;";
put 'data sumx;';
	put "set sumx;";
	put "drop _NAME_; ";
put "run;";
put "data Toterr;";
	put 'set Toterr sumx ;';
put "run;";

end;