# This file is a part of Julia. License is MIT: https://julialang.org/license

"""
Module for computing the CRC-32 checksum (ISO 3309, ITU-T V.42, CRC-32-IEEE),
analogous to the Julia `CRC32c` standard-library module for CRC-32c.

See [`CRC32.crc32`](@ref) for more information.
"""
module CRC32

####################################################################
# exported API, based on code in julia/stdlib/CRC32c/src/CRC32c.jl

export crc32

# contiguous byte arrays compatible with C `unsigned char *` API of zlib
const ByteArray = Union{Array{UInt8},
                        Base.FastContiguousSubArray{UInt8,N,<:Array{UInt8}} where N,
                        Base.CodeUnits{UInt8, String}, Base.CodeUnits{UInt8, SubString{String}}}

"""
    crc32(data, crc::UInt32=0x00000000)

Compute the CRC-32 checksum (ISO 3309, ITU-T V.42, CRC-32-IEEE) of the given `data`, which can be
an `Array{UInt8}`, a contiguous subarray thereof, or a `String`.  Optionally, you can pass
a starting `crc` integer to be mixed in with the checksum.  The `crc` parameter
can be used to compute a checksum on data divided into chunks: performing
`crc32(data2, crc32(data1))` is equivalent to the checksum of `[data1; data2]`.

There is also a method `crc32(io, nb, crc)` to checksum `nb` bytes from
a stream `io`, or `crc32(io, crc)` to checksum all the remaining bytes.
Hence you can do [`open(crc32, filename)`](@ref) to checksum an entire file,
or `crc32(seekstart(buf))` to checksum an [`IOBuffer`](@ref) without
calling [`take!`](@ref).

For a `String`, note that the result is specific to the UTF-8 encoding
(a different checksum would be obtained from a different Unicode encoding).
"""
function crc32 end

crc32(a::ByteArray, crc::UInt32=0x00000000) = _crc32(a, crc)
crc32(s::Union{String, SubString{String}}, crc::UInt32=0x00000000) = _crc32(s, crc)

"""
    crc32(io::IO, [nb::Integer,] crc::UInt32=0x00000000)

Read up to `nb` bytes from `io` and return the CRC-32 checksum, optionally
mixed with a starting `crc` integer.  If `nb` is not supplied, then
`io` will be read until the end of the stream.
"""
crc32(io::IO, nb::Integer, crc::UInt32=0x00000000) = _crc32(io, nb, crc)
crc32(io::IO, crc::UInt32=0x00000000) = _crc32(io, crc)
crc32(io::IOStream, crc::UInt32=0x00000000) = _crc32(io, crc)

####################################################################
# Low-level code, based on code from julia/base/util.jl but
# using Zlib's crc32 function (which is standardized by LSB).

import Zlib_jll: libz
unsafe_crc32(a, n, crc) = ccall((:crc32, libz), Culong, (Culong, Ptr{UInt8}, Csize_t), crc, a, n) % UInt32

_crc32(a::ByteArray, crc::UInt32=0x00000000) =
    unsafe_crc32(a, length(a) % Csize_t, crc)

function _crc32(s::Union{String, SubString{String}}, crc::UInt32=0x00000000)
    unsafe_crc32(s, sizeof(s) % Csize_t, crc)
end

function _crc32(io::IO, nb::Integer, crc::UInt32=0x00000000)
    nb < 0 && throw(ArgumentError("number of bytes to checksum must be ≥ 0, got $nb"))
    # use block size 24576=8192*3, since that is the threshold for
    # 3-way parallel SIMD code in the underlying jl_crc32 C function.
    buf = Vector{UInt8}(undef, min(nb, 24576))
    while !eof(io) && nb > 24576
        n = readbytes!(io, buf)
        crc = unsafe_crc32(buf, n % Csize_t, crc)
        nb -= n
    end
    return unsafe_crc32(buf, readbytes!(io, buf, min(nb, length(buf))) % Csize_t, crc)
end
_crc32(io::IO, crc::UInt32=0x00000000) = _crc32(io, typemax(Int64), crc)
_crc32(io::IOStream, crc::UInt32=0x00000000) = _crc32(io, filesize(io)-position(io), crc)

# optimized (copy-free) crc of IOBuffer (see similar crc32c function in base/iobuffer.jl)
const ByteBuffer = Base.GenericIOBuffer{<:ByteArray}
_crc32(buf::ByteBuffer, crc::UInt32=0x00000000) = _crc32(buf, bytesavailable(buf), crc)
function _crc32(buf::ByteBuffer, nb::Integer, crc::UInt32=0x00000000)
    nb < 0 && throw(ArgumentError("number of bytes to checksum must be ≥ 0, got $nb"))
    isreadable(buf) || throw(ArgumentError("read failed, IOBuffer is not readable"))
    nb = min(nb, bytesavailable(buf))
    crc = GC.@preserve buf unsafe_crc32(pointer(buf.data, buf.ptr), nb % Csize_t, crc)
    buf.ptr += nb
    return crc
end

####################################################################

end
