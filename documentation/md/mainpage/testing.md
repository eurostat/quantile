## Testing {#mainpage_testing}

### Implement test and describe examples

1. Testing with known, provided data and known results, check for correct results (white box testing)
2. Testing with unknown data and unknown results, check for plausible results (black box testing)
3. Testing with all variations of argument input parameters, check their effects,
testing with existing but known erroneous data and argument parameters (fool proof testing), check for appropriate responses, 
error reports and their consistent layout and verify whether all parameters are being checked on validity 
(legal SAS names, limited options, numbers, etc.), verify checks on existence of specified dataset(s) and variables within
 dataset(s), also verify checks on non-existence of newly to create permanent dataset(s), and/or an indication that these may 
 be overwritten if existing, verify possible cross checks between input parameters

 
  WHITE BOX TESTING

Testing with known, provided data and known results, check for correct results (white box testing). First of all a macro 
should be tested in the context it was meant for. Appropriate, legal parameters should be specified for its arguments, 
preferably default parameter values. These can be dataset names, libnames, variable names, format names, (macro specific) 
option keywords to indicate the macro’s actions, etc.. Valid and appropriate, existing datasets should be used of which the 
contents are known. It should be clear what the result of the macro processing should be in terms of output datasets or output 
listings. These should be verified for correctness and possibly checked against other known correct results.


This is the main kind of testing that a developer carries out too while developing his macros. These tests of course should 
be completely successful; that is the goal of the macro
BLACK BOX TESTING
Testing with unknown data and unknown results, check for plausible results (black box testing).


Black box testing should carried out by trying all input options one at a time, while all the time normal output should be produced. 
This does not necessarily include all possible combinations of input options under all possible circumstances. It may be virtually 
impossible to check all possible variations in the functionality of a complex macro. During development new features have been added 
one by one and tested in their target environment mainly, while testing them in other situations might be either redundant or not 
applicable. So is validation, though during the validation process it may be difficult to judge sufficiently reliably in which situations 
additional checking is superfluous. Thus during validation checking actually should be performed at least as or even more extensively than 
during development. 
 
### Run tests and examples