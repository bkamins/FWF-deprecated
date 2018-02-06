FWF
===

[![Build Status](https://travis-ci.org/bkamins/FWF.jl.svg?branch=master)](https://travis-ci.org/bkamins/FWF.jl)
[![codecov.io](http://codecov.io/github/bkamins/FWF.jl/coverage.svg?branch=master)](http://codecov.io/github/bkamins/FWF.jl?branch=master)

*A simple package for working with fixed width format files*

This package is ready for friendly tests.

The module does not export any methods. Usage is documented in docstrings.
The module does not have any depenencies, but is designed to allow for a simple
integration with other packages like *DataFrames*.
It is designed for rather small data as it is not optimized for speed (yet).

Available functions:
* reading file: `FWF.read` (performs no conversion of read data except optional stripping of header); accepted formats of field widths specification:
    1. a vector of field widths, e.g. `[1,2,3]`, with optional setting of `keep` keyword argument which fields should be retained
    2. a vector of `UnitRanges` indicating start and stop index of a field, e.g. `[1:2, 4:7, 9:10]`
    3. a character indicating field separator, e.g. `'|'`, in which case `FWF.read` autodetects fields in data 
* scan for field widths: `FWF.scan` (can be done automatically by `FWF.read`)
* convert data fields ranges to widths and keep flags: `FWF.range2width`
* writing file: `FWF.write`
* impute field types after reading data: `FWF.impute` (often needed as `FWF.read` does not transform the data read)

