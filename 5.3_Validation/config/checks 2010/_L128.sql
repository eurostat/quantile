put "title1 'Check #128 / %nrstr(&datum)';";
put "title2 '%nrstr(&ccnam) - %nrstr(&surtyp) survey %nrstr(&suryear)';";
put "title3 'Structural - Error: RB250 - Personal data record is missing in P-file or RB250 not filled correctly ';";
put "PROC SQL;";
put "Create table tempo as";
put "select RB010,RB030,RB070,RB080,RB250,PB010,PB030 from &ss.%nrstr(&cc).&yy.r as a 
 full join &ss.%nrstr(&cc).&yy.p as b on RB030 = PB030 and RB010 = PB010 and a.RHID = b.PHID
 where (RB250 in (11,12,13,14) and PB030 = .) or ((RB250 not in (11,12,13,14)) and PB030 ne .);";
put "quit;";


put "proc sort data=tempo;";
put "by rb010;";
put "run;";
    put "data tempox ;";
  put "set  tempo;";
 
put "by rb010;";
 put "cnt +1;";
 
put "if first.db010 then cnt=1;";
put "run;";
put "proc sql;";
 put "create table tempoxx as Select * from tempox";
  put "where cnt < &nrow;";
put "quit;";
put "data tempoxx (drop=cnt);";
put "set tempoxx;";
put "run;";
put "proc sql;";
put "Select * from tempo(obs=%nrstr(&errmax)) as a
  order by RB010 desc,RB030;";
put "Insert into errtabl set cod = 128 , error = (select count(*) from tempo);";
put "QUIT;";

put "proc sql;";
	put 'Insert into errtabl set cod = ' cod ', error = (select count(*) from tempo);';

		put "QUIT;";

 put " data error1 (keep=cod time );";
 put "set tempo; ";
 put ' cod = ' cod' ;';
 put "time=RB010;";
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
