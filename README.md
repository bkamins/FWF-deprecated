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

## Available functions
* reading file: `FWF.read` (performs no conversion of read data except optional stripping of header); accepted formats of field widths specification:
    1. a vector of field widths, e.g. `[1,2,3]`, with optional setting of `keep` keyword argument which fields should be retained
    2. a vector of `UnitRanges` indicating start and stop index of a field, e.g. `[1:2, 4:7, 9:10]`
    3. a character indicating field separator, e.g. `'|'`, in which case `FWF.read` autodetects fields in data 
* scan for field widths: `FWF.scan` (can be done automatically by `FWF.read`)
* convert data fields ranges to widths and keep flags: `FWF.range2width`
* writing file: `FWF.write`
* impute field types after reading data: `FWF.impute` (often needed as `FWF.read` does not transform the data read)

## Example session

```julia
julia> x = reshape(1:20, 5, 4)
5×4 reshape(::UnitRange{Int64}, 5, 4) with eltype Int64:
 1   6  11  16
 2   7  12  17
 3   8  13  18
 4   9  14  19
 5  10  15  20

julia> fname = tempname(); FWF.write(fname, x, Symbol.('a':'d'), blank='-')

julia> readlines(fname)
6-element Array{String,1}:
 "a-b--c--d"
 "1-6--11-16"
 "2-7--12-17"
 "3-8--13-18"
 "4-9--14-19"
 "5-10-15-20"

julia> y = FWF.read(fname, '-', stripheader='-')
(data = Array{SubString{String},1}[["1", "2", "3", "4", "5"], ["6-", "7-", "8-", "9-", "10"], ["11", "12", "13", "14", "15"], ["16", "17", "18", "19", "20"]], names = Symbol[:a, :b, :c, :d])

julia> y.data
4-element Array{Array{SubString{String},1},1}:
 ["1", "2", "3", "4", "5"]
 ["6-", "7-", "8-", "9-", "10"]
 ["11", "12", "13", "14", "15"]
 ["16", "17", "18", "19", "20"]

julia> y.names
4-element Array{Symbol,1}:
 :a
 :b
 :c
 :d

julia> rm(fname, force=true)
```

