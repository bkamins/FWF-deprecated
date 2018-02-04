__precompile__()

"""
FWF is a simple package for working with fixed width format files.
"""
module FWF

function parsefwf_line(line, widths::AbstractVector{Int})
    buf = Vector{SubString{String}}(uninitialized, length(widths))
    i = 0
    j = -1
    idx = 1
    malformed = false
    e = endof(line)
    for k in 1:length(widths)
        w = widths[k]
        j = nextind(line, i, w)
        if j > e
            j = e
            malformed = true
        end
        buf[idx] = SubString(line, i+1, j)
        i = j
        idx += 1
    end
    (buf, malformed)
end

function nextline(source, widths, skipblank)
    line = readline(source)
    while skipblank && isempty(line) && !eof(source)
        line = readline(source)
    end
    # special case if we skip blanks and find only empty lines
    skipblank && isempty(line) && eof(source) && return (Vector{SubString{String}}[], false)
    parsefwf_line(line, widths)
end

function emiterror(msg, errorlevel)
    errorlevel == :error && error(msg)
    errorlevel == :warn && warn(msg)
end

"""
`read(source, widths; header, stripheader, skip, nrow, skipblank, keep, parsers, errorlevel)`
`read(source, ranges; header, stripheader, skip, nrow, skipblank, parsers, errorlevel)`
`read(source, blank; header, stripheader, skip, nrow, skipblank, parsers, errorlevel)`
Reads fixed wdith format file or stream `source` assuming that its fields have:
* widths `widths` (where you can specify by `keep` which columns are kept);
* character `ranges` specifying column ranges to be fetched;
* autodetected widths assuming `blank` is a column separator.
Decodes what is possible to decode from a file (`errorlevel` handles reaction
to malformed input data).

Returns a `NamedTuple` with fields:
* `data`: vector of vectors containing data
* `names`: names of data columns as `Symbol`

If you use DataFrames the return value `ret` can be simply changed to a `DataFrame`
by writing `DataFrame(ret...)`.

Parameters:
* `source::Union{IO, AbstractString}`: stream or file name to read from
  (only file name is accepted when autodetection of columns is required)
* `widths::AbstractVector{Int}`: vector of column widths
* `ranges::AbstractVector{Tuple{Int,Int}}: vector of tuples of column ranges
* `blank::Base.Chars=Base._default_delims`: characters that are assumed to be blanks for
  autodetection of columns in the data;
* `header::Bool=true`: does `source` contain a header; if not a default header is created
* `stripheader::Union{Nothing, Base.Chars}: characters to strip from header
* `skip::Int=0`: number of lines to skip at the beginning of the file
* `nrow::Int=0`: number of rows containing data to read; `0` means to read all data
* `skipblank::Bool=true`: if empty lines shoud be skipped
* `keep::AbstractVector{Bool}=[true...]`: which columns should be retained in the result
* `parsers::AbstractVector{Function}=[identity...]`: list of parsers functions;
   must have the same number of elements as `widths`; by default no parsing is performed;
   you can use FWF.impute later if you want to autodetect numeric columns in the data
* `errorlevel::Symbol`: if `:error` then error is emited if malformed line is encoutered,
  if `:warn` a warning is printed; otherwise nothing happens
"""

function read(source::IO, widths::AbstractVector{Int};
              header::Bool=true, stripheader::Union{Nothing, Base.Chars}=Base._default_delims,
              skip::Int=0, nrow::Int=0, skipblank::Bool=true,
              keep::AbstractVector{Bool}=[true for i in 1:length(widths)],
              parsers::AbstractVector{Function}=[identity for i in 1:length(widths)],
              errorlevel::Symbol=:warn)
    length(parsers) == length(widths) || throw(ArgumentError("wrong number of parserss"))
    length(keep) == length(widths) || throw(ArgumentError("wrong length of keep"))
    all(x -> x > 0, widths) || throw(ArgumentError("field widths must be positive"))
    for i in 1:skip
        line = readline(source)
    end
    if header
        pline, malformed = nextline(source, widths, skipblank)
        if malformed || length(pline) == 0
            emiterror("Header was required and is malformed", errorlevel)
        end
        sline = stripheader === nothing ? pline : strip.(pline, stripheader)
        head = Symbol.(sline)
    else
        head = Symbol.(["x$i" for i in 1:length(widths)])
    end

    rawdata = [SubString{String}[] for i in 1:length(widths)]
    row = 0
    while (row < nrow || nrow == 0) && !eof(source)
        row += 1
        pline, malformed = nextline(source, widths, skipblank)
        # below row does not count header and blank lines if skipblank is on
        malformed && emiterror("Malformed actual data line number $row", errorlevel)
        for i in 1:length(pline)
            push!(rawdata[i], pline[i])
        end
    end
    # TODO: properly handle Missing in Union; to be fixed in Julia 0.7 hopefully
    data = Any[parsers[i].(rawdata[i]) for i in 1:length(rawdata)]
    (data=data[keep], names=head[keep])
end

function read(source::AbstractString, widths::AbstractVector{Int};
              header::Bool=true, stripheader::Union{Nothing, Base.Chars}=_default_delims,
              skip::Int=0, nrow::Int=0, skipblank::Bool=true,
              keep::AbstractVector{Bool}=[true for i in 1:length(widths)],
              parsers::AbstractVector{Function}=[identity for i in 1:length(widths)],
              errorlevel::Symbol=:warn)
    open(source) do handle
        read(handle, widths, header=header, skipheader=skipheader, skip=skip, nrow=nrow,
             skipblank=skipblank, keep=keep, parsers=parsers, errorlevel=errorlevel)
    end
end

function read(source::Union{IO, AbstractString}, ranges::AbstractVector{Tuple{Int,Int}};
              header::Bool=true, stripheader::Union{Nothing, Base.Chars}=_default_delims,
              skip::Int=0, nrow::Int=0, skipblank::Bool=true,
              parsers::AbstractVector{Function}=[identity for i in 1:length(widths)],
              errorlevel::Symbol=:warn)
    widths, keep = range2width(ranges)
    read(source, widths, header=header, skipheader=skipheader, skip=skip, nrow=nrow,
         skipblank=skipblank, keep=keep, parsers=parsers, errorlevel=errorlevel)
end

# only AbstractString is allowed as we have to scan the file twice
function read(source::AbstractString, blank::Base.Chars=Base._default_delims;
              header::Bool=true, stripheader::Union{Nothing, Base.Chars}=_default_delims,
              skip::Int=0, nrow::Int=0, skipblank::Bool=true,
              parsers::AbstractVector{Function}=[identity for i in 1:length(widths)],
              errorlevel::Symbol=:warn)
    widths, keep = range2width(scan(source, blank, skip=skip, nrow=nrow, skipblank=skipblank))
    read(source, widths, header=header, skipheader=skipheader, skip=skip, nrow=nrow,
         skipblank=skipblank, keep=keep, parsers=parsers, errorlevel=errorlevel)
end

"""
`impute(vs, na)

Takes a string vector `vs` and tries to convert it to `Int` or `Float64` if possible.
Handles `missing` in `vs` and also converts `na` to `missing`.
On failure returns original string.

Parameters:
* `vs::AbstractVector{<:Union{AbstractString, Missing}}`: data to perform imputation for
* `na::Union{AbstractString,Regex}`: string or pattern that is to be
  converted to `missing`, e.g. `""` or `"NA"`. By default `r"^\s*(NA)?\s*$"`
"""
function impute(vs::AbstractVector{<:Union{AbstractString, Missing}},
                na::Union{AbstractString,Regex}=r"^\s*(NA)?\s*$")
    length(vs) == 0 && return vs
    can_int = true
    can_float = true
    for s in vs
        if !(ismissing(s) || contains(s, na))
            isa(tryparse(Int, s), Nothing) && (can_int = false)
            isa(tryparse(Float64, s), Nothing) && (can_float = false)
        end
    end
    if can_int
        # TODO: properly handle Missing in Union; to be fixed in Julia 0.7 hopefully
        return [ismissing(s) || contains(s, na) ? missing : parse(Int, s) for s in vs]
    end
    if can_float
        # TODO: properly handle Missing in Union; to be fixed in Julia 0.7 hopefully
        return [ismissing(s) || contains(s, na) ? missing : parse(Float64, s) for s in vs]
    end
    vs
end

"""
`scan(source, blank; skip, nrow, skipblank)

Reads fixed wdith format file or stream `source`.
Returns `Vector{Tuple{Int,Int}}` with autotetected fields in `source`.
Detects only fields that exist in all checked lines.

Parameters:
* `source::Union{IO, AbstractString}`: stream or filename to read from
* `blank::Base.Chars=Base._default_delims`: which characters are considered non-data
* `skip::Int=0`: number of lines to skip at the beginning of the file
* `nrow::Int=0`: number of rows containing data to read; `0` means to read all data
* `skipblank::Bool=true`: if empty lines shoud be skipped
"""
function scan(source::IO, blank::Base.Chars=Base._default_delims;
              skip::Int=0, nrow::Int=0, skipblank::Bool=true)
    for i in 1:skip
        line = readline(source)
    end

    allblank = Int[]
    maxwidth = 0
    firstline = true
    row = 0
    while row < nrow || nrow == 0
        line = readline(source)
        while skipblank && isempty(line) && !eof(source)
            line = readline(source)
        end
        isempty(line) && eof(source) && break
        thisblank = Int[]
        for (i, c) in enumerate(line)
            c in blank && push!(thisblank, i)
        end
        if firstline
            allblank = thisblank
            firstline = false
        else
            allblank = intersect(thisblank, allblank)
        end
        maxwidth = max(maxwidth, length(line))
        row += 1
    end
    allblank[end] < maxwidth && push!(allblank, maxwidth+1)
    last_blank = 0
    range = Tuple{Int,Int}[]
    maxwidth == 0 && return range
    for this_blank in allblank
        if this_blank > last_blank + 1
            push!(range, (last_blank+1, this_blank-1))
        end
        last_blank = this_blank
    end
    range
end

function scan(source::AbstractString, blank::Base.Chars=Base._default_delims;
     skip::Int=0, nrow::Int=0, skipblank::Bool=true)
    open(source) do handle
        scan(handle, blank, skip=skip, nrow=nrow, skipblank=skipblank)
    end
end

"""
`range2width(r::AbstractArray{Tuple{Int, Int}})`

Converts a vector of field ranges into a pair of field widths and keep vector.

Example:
```
julia> range2width([(1,1), (3,3), (4,5)])
(width = [1, 1, 1, 2], keep = Bool[true, false, true, true])
```
"""
function range2width(r::AbstractArray{Tuple{Int, Int}})
    width = Int[]
    keep = Bool[]
    old_hi = 0
    for (lo, hi) in r
        lo > hi && throw(ArgumentError("lo may not be greater than hi in range"))
        if lo ≤ old_hi
            lo < 1 && throw(ArgumentError("ranges must be positive"))
            throw(ArgumentError("ranges must be non overlapping"))
        elseif lo > old_hi + 1
            push!(width, lo - old_hi - 1)
            push!(keep, false)
        end
        push!(width, hi-lo+1)
        push!(keep, true)
        old_hi = hi
    end
    (width=width, keep=keep)
end

stringmissing(v, na::String) = ismissing(v) ? na : string(v)

function width(data::AbstractVector, name, na)
    width = isa(name, Nothing) ? 0 : length(stringmissing(name, na))
    for d in data
        width = max(width, length(stringmissing(d, na)))
    end
    width
end

function widths(data::AbstractVector, names::Union{Nothing,AbstractVector}, na)
    if !isa(names, Nothing) && length(data) != length(names)
        error("data and name lengths must be identical")
    end
    [width(v, isa(names, Nothing) ? nothing : names[i], na) for (i, v) in enumerate(data)]
end

function writefwf_line(sink::IO, values::Vector{String}, widths::Vector{Int}, blank::Char)
    for i in 1:length(values)-1
        s = values[i]
        print(sink, s * (blank^(widths[i] - length(s))))
    end
    println(sink, values[end])
end

"""
`write(sink, data, names; space, blank, na)`

Writes `data` with header `names` to a file or stream `sink` in fixed width format.

Parameters:
* `sink::Union{IO, AbstractString}`: file or stream to write to
* `data::Union{AbstractVector, AbstractMatrix}`: matrix or vector of vectors containing data
  if overly short vectors are encountered then it is assumed that they contain missing data
  after their end
* `names::Union{Nothing,AbstractVector}=nothing`: column names, if `nothing` then no header
  is written
* `space::Int=1`: number of `blanks` to insert to separate columns of data
* `blank::Char=' '`: character to fill blank space with
* `na::AbstractString=""`: string to be written when missing value is encountered
"""
function write(sink::IO, data::AbstractVector, names::Union{Nothing,AbstractVector}=nothing;
               space::Int=1, blank::Char=' ', na::AbstractString="")
    space > 0 || error("space must be positive")
    w = widths(data, names, na) .+ space
    if !isa(names, Nothing)
        writefwf_line(sink, stringmissing.(names, na), w, blank)
    end
    for i in 1:maximum(length.(data))
        values = [length(data[j]) < i ? "" : stringmissing(data[j][i], na) for j in 1:length(data)]
        writefwf_line(sink, values, w, blank)
    end
end

function write(sink::AbstractString, data::AbstractVector,
               names::Union{Nothing,AbstractVector}=nothing;
               space::Int=1, blank::Char=' ', na::AbstractString="")
    open(sink, "w") do handle
        write(handle, data, names, space=space, blank=blank, na=na)
    end
end

function write(sink::IO, data::AbstractMatrix, names::Union{Nothing,AbstractVector}=nothing;
               space::Int=1, blank::Char=' ', na::AbstractString="")
    write(sink, [view(data, :, i) for i in 1:size(data, 2)], names,
          space=space, blank=blank, na=na)
end

function write(sink::AbstractString, data::AbstractMatrix,
               names::Union{Nothing,AbstractVector}=nothing; space::Int=1, blank::Char=' ',
               na::AbstractString="")
    open(sink, "w") do handle
        write(handle, data, names, space=space, blank=blank, na=na)
    end
end

end # module
