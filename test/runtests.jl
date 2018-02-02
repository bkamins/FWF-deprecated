# using FWF
using Test

s = """
a b c
1 2 3a
4 5 6
7 8 x
"""
x = FWF.read(IOBuffer(test), [2,2,1], parsers=[:str, :int, :float])
@test isequal(x.data, [["1", "4", "7"],[2, 5, 8],[3.0, 6.0, missing]])
@test x.names == [:a, :b, :c]

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

# add tests for all scenarios

@testset "range2width" begin
    @test FWF.range2width(Tuple{Int, Int}[]) == (width=Int[], keep=Int[])
    @test FWF.range2width([(1,1), (3,3), (4,5)]) == (width = [1, 1, 1, 2],
                                                 keep = Bool[true, false, true, true])

    @test_throws ArgumentError FWF.range2width([(-1,3)])
    @test_throws ArgumentError FWF.range2width([(1,3), (3,4)])
    @test_throws ArgumentError FWF.range2width([(1,3), (4,3)])

    test_widths = rand(1:10, 100)
    test_ranges = [(1, test_widths[1])]
    for w in test_widths[2:end]
        push!(test_ranges, (test_ranges[end][2]+1, test_ranges[end][2]+w))
    end
    w, k = FWF.range2width(test_ranges)
    @test w == test_widths
    @test all(k)

    test_ranges = [(2, test_widths[1]+1)]
    for w in test_widths[2:end]
        push!(test_ranges, (test_ranges[end][2]+2, test_ranges[end][2]+w+1))
    end
    w, k = FWF.range2width(test_ranges)
    @test w[k] == test_widths
    @test all(w[.!k] .== 1)
end

@testset "impute" begin
    @test impute(["a", "b", "c"]) == ["a", "b", "c"]
    @test impute(["a", "b", "NA"]) == ["a", "b", "NA"]
    @test impute(["1", "2", "3"]) == [1, 2, 3]
    @test eltype(impute(["1", "2", "3"])) == Int
    @test impute(["1", "2.0", "3"]) == [1.0, 2.0, 3.0]
    @test eltype(impute(["1", "2.0", "3"])) == Float64
    @test impute(["1", "2", "NA"]) == [1, 2, missing]
    @test impute(["1", "2", " NA "]) == [1, 2, missing]
    @test impute(["1", "2.0", ""]) == [1.0, 2.0, missing]
    @test impute(["1", "2.0", "\t "]) == [1.0, 2.0, missing]
    @test impute(["1", "2.0", "\t ", "a"]) == ["1", "2.0", "\t ", "a"]
end

