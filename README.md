[![CI](https://github.com/JuliaIO/CRC32.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaIO/CRC32.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/JuliaIO/CRC32.jl/branch/main/graph/badge.svg?token=9lwiWxEZjM)](https://codecov.io/gh/JuliaIO/CRC32.jl)

# CRC32

CRC32 is a [Julia package](https://docs.julialang.org/en/v1/stdlib/Pkg/) for computing the [CRC-32 checksum](https://en.wikipedia.org/wiki/Cyclic_redundancy_check) as defined by
the ISO 3309 / ITU-T V.42 / CRC-32-IEEE standards, designed as a drop-in replacement for
Julia's [CRC32c standard library](https://docs.julialang.org/en/v1/stdlib/CRC32c/) (which computes the CRC-32**c** checksum).   A wider variety of CRC checksum algorithms is provided by the [CRC.jl package](https://github.com/andrewcooke/CRC.jl), and cryptographic checksums can be found in [MD5.jl](https://github.com/JuliaCrypto/MD5.jl) and [SHA.jl](https://github.com/JuliaCrypto/SHA.jl).

* *Note:* This JuliaIO/CRC32.jl package is completely independent of the older [fhs/CRC32.jl package](https://github.com/fhs/CRC32.jl) by [Fazlul Shahriar](https://github.com/fhs), which is no longer maintained (and much slower).  If you run `add CRC32` in [Julia's package manager](https://docs.julialang.org/en/v1/stdlib/Pkg/) you will get JuliaIO/CRC32.jl, *not* fhs/CRC32.jl.

It exports a single function, `crc32`, described below (analogous to [`CRC32c.crc32c`](https://docs.julialang.org/en/v1/stdlib/CRC32c/#CRC32c.crc32c)).

The implementation uses the [`libdeflate_crc32` function](https://github.com/ebiggers/libdeflate/blob/92e6a0db9fa848d742f9eb286c92afc60f2c3dda/libdeflate.h#L346) from [Eric Biggers's `libdeflate` library](https://github.com/ebiggers/libdeflate).
This implementation is heavily optimized, and on x86-64 and arm64 hardware its speed is approximately on par with the `CRC32c.crc32c` function from the Julia standard library.

## `crc32(data, [crc])` and `crc32(io, [crc])`:

```jl
crc32(data, crc::UInt32=0x00000000)
```

Compute the CRC-32 checksum (ISO 3309, ITU-T V.42, CRC-32-IEEE) of the given `data`, which can be
an `Array{UInt8}`, a contiguous subarray thereof, an `AbstractVector{UInt8}`, or a `String`.
Optionally, you can pass a starting `crc` integer to be mixed in with the checksum.
The `crc` parameter can be used to compute a checksum on data divided into chunks: performing
`crc32(data2, crc32(data1))` is equivalent to the checksum of `[data1; data2]`.

There is also a method `crc32(io, nb, crc)` to checksum `nb` bytes from
a stream `io`, or `crc32(io, crc)` to checksum all the remaining bytes.
Hence you can do [`open(crc32, filename)`](@ref) to checksum an entire file,
or `crc32(seekstart(buf))` to checksum an [`IOBuffer`](@ref) without
calling [`take!`](@ref).

For a `String`, note that the result is specific to the UTF-8 encoding
(a different checksum would be obtained from a different Unicode encoding).

## Authors

Steven G. Johnson, based on API code from the Julia CRC32c standard
library (also [originally contributed](https://github.com/JuliaLang/julia/pull/18297) by SGJ).   The [`libdeflate_crc32` function](https://github.com/ebiggers/libdeflate/blob/master/lib/crc32.c) was developed by Eric Biggers.

The Julia code in this package (and its antecedents in the Julia CRC32c standard library) is free/open-source software under the MIT License (see `LICENSE` file).
The backing `libdeflate` library is [also under MIT licence](https://github.com/ebiggers/libdeflate/blob/master/COPYING).
