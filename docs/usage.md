## <a name="Usage"></a>Usage


### `SAS` programs

Compute the quartiles of a randomly generated vector (with normal distribution) using default parameters of the `quantile` function:
~~~sas
DATA test;
DO i = 1 TO 1000;
  x = rand('NORMAL');
  output;
END;
DROP i;
RUN;

%quantile(x, idsn = test, _quantiles_ = q_x);

%PUT &q_x;
~~~

Do change the algorithm used for estimation:
~~~sas
%quantile(x, type = 5, idsn = test, _quantiles_ = q_x);

%PUT &q_x;
~~~

Now compute the quintiles:
~~~sas
%quantile(x, probs = 0.2 0.4 0.6 0.8, idsn = test, _quantiles_ = q_x);

%PUT &q_x;
~~~

### `Python` programs

Compute the quartiles of a randomly generated vector (with normal distribution) using default parameters of the `quantile` function:
~~~py
>>> import numpy as np
>>> x = np.random.rand(1000)
>>> from quantile import quantile
>>> q = quantile(x)
>>> plot(q)
~~~

Do change the algorithm used for estimation:
~~~py
>>> q = quantile(x, typ=5)
>>> plot(q)
~~~

Now compute the quintiles:
~~~py
>>> q = quantile(x, probs=[.2,.4,.6,.8])
>>> plot(q)
~~~

Consider comparing the results obtained using both already existing `scipy.mquantiles` and the new implementation:
~~~py
>>> probs = [.2,.4,.6,.8]
>>> typ = 8
>>> q1 = quantile(x, probs=probs, typ=typ, method='DIRECT')
>>> plot(q1)
>>> q2 = quantile(x, probs=probs, typ=typ, method='INHERIT')
>>> plot(q2)
~~~

It is possible to run ("call") exactly the same estimations on an input file of sampled data, _e.g._:
~~~py
>>> ifile = "tests/sample1.csv"
>>> from io_quantile import IO_Quantile
>>> Q=IO_Quantile(probs=probs, typ=typ, method='DIRECT'); 
>>> q = Q(ifile)
~~~

An instance of the class `IO_Quantile` is associated to one possible configuration of the quantile estimation. Usually, you will define another instance to perform the estimation with different parameters, _e.g._ using specialised quantiles:
~~~py
>>> probs = "P100"
>>> Q=IO_Quantile(probs=probs, typ=7); 
>>> q = Q(ifile)
~~~

But then it is possible to run the same estimation algorithm over different input files using that same, already defined, instance:
~~~py
>>> ifile2 = "tests/sample2.csv"
>>> q = Q(ifile)
>>> q1 = Q(ifile2)
~~~

Note the definition of the `IO_Quartile` class that specifically runs estimation of quartiles, and also enables you to plot the associated boxplot:
~~~py
>>> from matplotlib import pyplot
>>> from io_quantile import IO_Quartile
>>> Qu=IO_Quartile(typ=7); 
>>> q = Qu(ifile)
>>> Qu.plot(ifile)
>>> pyplot.show()
~~~


### `R` programs
