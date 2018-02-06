# using FWF
using Test

@testset "read" begin
    d, n = FWF.read("data/test1.txt", [8,8,8,8,8])
    @test d == [["     0.8", "   0.103", "  0.3164"],
                ["  0.4093", "  0.4704", "    0.16"],
                ["     0.7", "    0.12", "    0.85"],
                ["  0.4868", "    0.09", "    0.88"],
                ["   0.846", "    0.15", "     0.4"]]
    @test n == [ :a, :bb, :ccc, :dddd, :eeeee]
    d, n = FWF.read("data/test1.txt", [8,8,8,8,8], skipblank=false, skip=1)
    @test d == [["", "     0.8", "   0.103", "  0.3164"],
                ["", "  0.4093", "  0.4704", "    0.16"],
                ["", "     0.7", "    0.12", "    0.85"],
                ["", "  0.4868", "    0.09", "    0.88"],
                ["", "   0.846", "    0.15", "     0.4"]]
    @test n == [:a, :bb, :ccc, :dddd, :eeeee]
    d, n = FWF.read("data/test1.txt", [8,8,8,8,8], stripheader=nothing)
    @test d == [["     0.8", "   0.103", "  0.3164"],
                ["  0.4093", "  0.4704", "    0.16"],
                ["     0.7", "    0.12", "    0.85"],
                ["  0.4868", "    0.09", "    0.88"],
                ["   0.846", "    0.15", "     0.4"]]
    @test n == [Symbol("a       "),
                Symbol("bb      "),
                Symbol("ccc     "),
                Symbol("dddd    "),
                Symbol("eeeee   ")]
    d, n = FWF.read("data/test1.txt", ' ', header=false, skip=2)
    @test d == [["   0.8", " 0.103", "0.3164"],
                ["0.4093", "0.4704", "  0.16"],
                [" 0.7", "0.12", "0.85"],
                ["0.4868", "  0.09", "  0.88"],
                ["0.846", " 0.15", "  0.4"],
                [" 0.79", " 0.15", "0.349"]]
    @test n == [:x1, :x2, :x3, :x4, :x5]
    d, n = FWF.read("data/test2.txt", [8,8,8,8,8], skipblank=false)
    @test d ==  [["   0.477", "  0.8395", "", "  0.4477"],
                 ["     0.3", "  0.2405", "", "    0.57"],
                 ["  0.2039", "     0.3", "", "       0"],
                 ["     0.5", "   0.526", "", "  0.0512"],
                 ["    0.77", "       1", "", "    0.93"]]
    @test n == [:a, :bb, :ccc, :dddd, :eeeee]
    d, n = FWF.read("data/test3.txt", [1,1,1,1,1],keep=[true,false,true,false,true])
    @test d ==  [["1", "1", " "], ["2", "2", "2"], ["3", "", "3"]]
    @test n == [:a, :b, :c]
    d, n = FWF.read("data/test3.txt", [1:1, 3:3, 5:5])
    @test d ==  [["1", "1", " "], ["2", "2", "2"], ["3", "", "3"]]
    @test n == [:a, :b, :c]
    d, n = FWF.read("data/test3.txt", ' ')
    @test d ==  [["1", "1", " "], ["2 3", "2", "2 3"]]
    @test n == [:a, Symbol("b c")]
end

@testset "range2width" begin
    @test FWF.range2width(UnitRange{Int}[]) == (width=Int[], keep=Int[])
    @test FWF.range2width([1:1, 3:3, 4:5]) == (width = [1, 1, 1, 2],
                                               keep = Bool[true, false, true, true])

    @test_throws ArgumentError FWF.range2width([-1:3])
    @test_throws ArgumentError FWF.range2width([1:3, 3:4])
    @test_throws ArgumentError FWF.range2width([1:3, 4:3])

    test_widths = rand(1:10, 100)
    test_ranges = [1:test_widths[1]]
    for w in test_widths[2:end]
        push!(test_ranges, (test_ranges[end].stop+1):(test_ranges[end].stop+w))
    end
    w, k = FWF.range2width(test_ranges)
    @test w == test_widths
    @test all(k)

    test_ranges = [2:(test_widths[1]+1)]
    for w in test_widths[2:end]
        push!(test_ranges, (test_ranges[end].stop+2):(test_ranges[end].stop+w+1))
    end
    w, k = FWF.range2width(test_ranges)
    @test w[k] == test_widths
    @test all(w[.!k] .== 1)
end

@testset "impute" begin
    @test FWF.impute(["a", "b", "c"]) == ["a", "b", "c"]
    @test FWF.impute(["a", "b", "NA"]) == ["a", "b", "NA"]
    @test FWF.impute(["1", "2", "3"]) == [1, 2, 3]
    @test eltype(FWF.impute(["1", "2", "3"])) == Int
    @test FWF.impute(["1", "2.0", "3"]) == [1.0, 2.0, 3.0]
    @test eltype(FWF.impute(["1", "2.0", "3"])) == Float64
    @test isequal(FWF.impute(["1", "2", "NA"]), [1, 2, missing])
    @test isequal(FWF.impute(["1", "2", " NA "]), [1, 2, missing])
    @test isequal(FWF.impute(["1", "2.0", ""]), [1.0, 2.0, missing])
    @test isequal(FWF.impute(["1", "2.0", "\t "]), [1.0, 2.0, missing])
    @test FWF.impute(["1", "2.0", "\t ", "a"]) == ["1", "2.0", "\t ", "a"]
end

@testset "scan" begin
    @test FWF.scan("data/test1.txt") == [1:1, 3:19, 21:48]
    @test FWF.scan("data/test1.txt", skip=2) == [3:8, 11:16, 21:24, 27:32, 36:40, 44:48]
    @test FWF.scan("data/test1.txt", [' ';'a':'f']) == [3:8, 11:16, 21:24, 27:32, 36:40, 44:48]
    @test FWF.scan("data/test2.txt") == [1:1, 3:48]
    @test FWF.scan("data/test2.txt", skip=1) == [3:8, 11:16, 19:24, 27:32, 37:40, 43:48]
    @test FWF.scan("data/test2.txt", [' ';'a':'f']) == [3:8, 11:16, 19:24, 27:32, 37:40, 43:48]
    @test FWF.scan("data/test2.txt", nrow=1) == [1:1, 9:10, 17:19, 25:28, 33:37, 41:46]
    @test FWF.scan("data/test2.txt", 'X') == [1:48]
    @test FWF.scan("data/test2.txt", skipblank=false) == [1:48]
    @test isempty(FWF.scan("data/test2.txt", nrow=-1))
    @test FWF.scan("data/test3.txt") == [1:1, 3:5]
    @test FWF.scan("data/test3.txt", nrow=2) == [1:1, 3:3, 5:5]
    @test FWF.scan("data/test3.txt", nrow=3) == [1:1, 3:5]
end

@testset "write" begin
    data = [[1, 2, 31], ["abc", "defg"], [true, false, true], [1, 11, 111]]
    io = IOBuffer()
    FWF.write(io, data)
    @test String(take!(io)) == "1  abc  true  1\n2  defg false 11\n31      true  111\n"

    io = IOBuffer()
    FWF.write(io, data, ['a', 'b', missing, 'd'], space=3, blank='~', na="missing")
    @test String(take!(io)) == "a~~~~b~~~~~~~~~missing~~~d\n1~~~~abc~~~~~~~true~~~~~~1\n2~~~~defg~~~~~~false~~~~~11\n31~~~missing~~~true~~~~~~111\n"

    srand(1)
    data = round.(rand(3,5), 3)
    io = IOBuffer()
    FWF.write(io, data, 'a':'e', space=2, blank='|')
    @test String(take!(io)) == "a||||||b||||||c||||||d||||||e\n0.236||0.008||0.952||0.987||0.425\n0.347||0.489||1.0||||0.556||0.773\n0.313||0.211||0.252||0.437||0.281\n"

    data = convert(Matrix{Union{Missing, Float64}}, data)
    data[1,1] = missing
    data[2,2] = missing
    data[3,5] = missing
    io = IOBuffer()
    FWF.write(io, data, 'a':'e', space=2, blank='|')
    @test String(take!(io)) == "a||||||b||||||c||||||d||||||e\n|||||||0.008||0.952||0.987||0.425\n0.347|||||||||1.0||||0.556||0.773\n0.313||0.211||0.252||0.437||\n"

    io = IOBuffer()
    FWF.write(io, data, 'a':'e', space=2, blank='|', na="missing")
    @test String(take!(io)) == "a||||||||b||||||||c||||||d||||||e\nmissing||0.008||||0.952||0.987||0.425\n0.347||||missing||1.0||||0.556||0.773\n0.313||||0.211||||0.252||0.437||missing\n"

    io = IOBuffer()
    FWF.write(io, data, 'a':'e', space=0, blank='_', na="NA")
    @test String(take!(io)) == "a____b____c____d____e\nNA___0.0080.9520.9870.425\n0.347NA___1.0__0.5560.773\n0.3130.2110.2520.437NA\n"
end

