put "title1 'Check #135 / %nrstr(&datum)';";
put "title2 '%nrstr(&ccnam) - %nrstr(&surtyp) survey %nrstr(&suryear)';";
put "title3 'Structural - Error: RB110 must be 2 in the new household for a sample person moved from another household ';";
put "PROC SQL;";
put "Create table tempo as";
put "select a.RHID,a.RB010,a.RB030,a.RB100,a.RB110,a.RB120,b.RHID as _RHID,b.RB010 as  _RB010,b.RB030 as _RB030,b.RB110 as _RB110, c.DB010, c.DB030, c.DB135 ";
put "from (&ss%nrstr(&cc).&yy.r as a left join &ss%nrstr(&cc).&yy.r as b on a.RB030 = b.RB030 and a.RHID ne b.RHID and a.RB010 = b.RB010)";
put "left join &ss%nrstr(&cc).&yy.d as c on b.RHID = c.DB030 and b.RB010 = c.DB010";
put "where a.RB100 = 1 and a.RB110 = 5 and a.RB120 = 1 and b.RB110 ne 2 and c.DB135 = 1;";
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
put "Insert into errtabl set cod = 135 , error = (select count(*) from tempo);";
put "QUIT;";

put "proc sql;";
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







