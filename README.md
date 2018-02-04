FWF
===

[![Build Status](https://travis-ci.org/bkamins/FWF.jl.svg?branch=master)](https://travis-ci.org/bkamins/FWF.jl)
[![codecov.io](http://codecov.io/github/bkamins/FWF.jl/coverage.svg?branch=master)](http://codecov.io/github/bkamins/FWF.jl?branch=master)

*A simple package for working with fixed width format files*

This is work in progress.

The module does not export any methods. Usage is documented in docstrings.
The module does not have any depenencies, but is designed to allow for a simple
integration with other packages like *DataFrames*.
It is designed for rather small data as it is not optimized for speed (yet).

Available functions:
* reading file: `FWF.read`
* writing file: `FWF.write`
* scan for field widths: `FWF.scan`
* convert data fields ranges to widths and keep flags: `FWF.range2width`
* impute field types after reading data: `FWF.impute`

