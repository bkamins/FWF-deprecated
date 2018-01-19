# using FWF
using Test

s = """
a b c
1 2 3a
4 5 6
7 8 x
"""
x = FWF.read(IOBuffer(test), [2,2,1], parsers=[:str, :int, :float])
@test x.names == [:a, :b, :c]
@test isequal(x.data, [["1", "4", "7"],[2, 5, 8],[3.0, 6.0, missing]])

io = IOBuffer(UInt8[], false, true)
m = [1 2 3
     4 5 6
     7 missing 9]
FWF.write(io, m)
s = String(take!(io))
ref = """
1 2 3
4 5 6
7   9
"""
@test s == ref

