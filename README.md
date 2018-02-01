FWF
===

[![Build Status](https://travis-ci.org/bkamins/FWF.jl.svg?branch=master)](https://travis-ci.org/bkamins/FWF.jl)
[![codecov.io](http://codecov.io/github/bkamins/FWF.jl/coverage.svg?branch=master)](http://codecov.io/github/bkamins/FWF.jl?branch=master)

*A simple package for working with fixed width format files*

This is work in progress.

The module does not export any methods. Usage is documented in docstrings.
The module does not have any depenencies, but is designed to allow for a simple
integration with other packages like *DataFrames*.

Available functions:
* reading file: `FWF.read`
* writing file: `FWF.write`
* scan for field widths: `FWF.scan`
* impute field types after reading data: `FWF.impute`
* parsers dictionary: `FWF.PARSERS`

