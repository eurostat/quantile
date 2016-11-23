## str_to_keyvalue {#sas_str_to_keyvalue}
Retrieve and discard the (key,value) pairs present in a given string/list.

	%str_to_keyvalue(str, key=, value=, _key_, _value_=, _item_=, _str_=, op=%quote(=), sep=%quote( ));

### Arguments
* `str` : strings of items that may be defined as `(key,value)` pairs of the form `A&opB` where
	`op` is defined below; 
* `key` : (_option_) string(s) defining the keys to look for in the input string; a key is defined
	as the left-hand side of the `(key,value)` pair `A&opB`, _i.e._ `A`; when passed, only those
	`(key,value)` pairs associated to keys in `key` are retrieved; when not passed (_i.e._ left
	blank), the macro retrieves all possible keys present in the input string;
* `value` : (_option_) string(s) defining the values to look for in the input string; a value is
	defined as the right-hand side of the `(key,value)` pair `A&opB`, _i.e._ `B`; when passed, the
	values retrieved from the input string are matched against those in `value`; by default, `value`
	is not considered;
* `op` : (_option_) separator character of `(key,value)` pairs in input string `str`; default:
	`op=%quote(=)`;
* `sep` : (_option_) character/string separator in input list; default: `%%quote( )`, _i.e._ `sep` is 
	blank.

### Returns
* `_key_` : (_option_) name of the variable storing the (list of) key(s) found in `(key,value)` pairs 
	present of `str` and that match the criteria on `key` and `value` parameters above;
* `_value_` : (_option_) ibid with value(s); 
* `_item_` : (_option_) name of the variable storing the `(key,value)` zipped pairs that match the 
	criteria on `key` and `value` parameters above; 
* `_str_` : (_option_) updated string from which all `(key,value)` pairs that macth the criteria
	on `key` and `value` parameters are discarded.

### Examples
Let us consider the following simple examples:

	%let str=A, B, K=C, D;
	%let ovalue=;
	%let ostr=;
	%let oitem=;
	%str_to_keyvalue(%quote(&str), key=K, _value_=ovalue, _str_=ostr, _item_=oitem, sep=%quote(,));

which sets: `ovalue=C`, `item=K=C` and `ostr=A,B,D`. Let us also consider the following case:

	%let str=A, B, K1=C, D, K2=E, K3=, F, K4=G;
	%let okey=;
	%let ovalue=;
	%let ostr=;
	%let oitem=;
	%str_to_keyvalue(%quote(&str), value=C F G, _value_=ovalue, _key_=okey, _str_=ostr, _item_=oitem, sep=%quote(,));

sets: `ovalue=C G`, `okey=K1 K4`, `item=K1=C,K4=G` and `ostr=A,B,D,K2=E,K3=,F`, while

	%str_to_keyvalue(%quote(&str), _value_=ovalue, _key_=okey, _str_=ostr, _item_=oitem, sep=%quote(,));

sets: `ovalue=C E _EMPTY_ G`, `okey=K1 K2 K3 K4`, `item=K1=C,K2=E,K3=,K4=G` and `ostr=A,B,D,F`.

Run macro `%%_example_str_to_keyvalue` for more examples.

### Notes
1. This macro assumes that the `(key,value)` pairs in the input string parameter `str` are unique!
2. Zipped `(key,value)` pairs returned through `_item_` are built using 
[%list_append](@ref sas_list_append).
3. Output updated lists are (blank) compressed.

### See also
[%list_append](@ref sas_list_append).
