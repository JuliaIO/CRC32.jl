using CRC32
using Test

# based on julia/stdlib/CRC32/test/runtests.jl

@testset "CRC32.jl" begin
    # CRC32 checksum (test data generated from @andrewcooke's CRC.jl package)
    for (n,crc) in [(0, 0x00000000), (1, 0xa505df1b), (2, 0xb6cc4292), (3, 0x55bc801d), (4, 0xb63cfbcd), (5, 0x470b99f4), (6, 0x81f67724), (7, 0x70e46888), (8, 0x3fca88c5), (9, 0x40efab9e), (10, 0x2520577b), (11, 0x8222bee6), (12, 0x925fc655), (13, 0xb720698d), (14, 0xa6041d7e), (15, 0xf5a6aa3a), (16, 0x094c80f1), (17, 0x72014175), (18, 0x01a61a37), (19, 0xee00ad46), (20, 0x5789dff8), (21, 0x0ceef897), (22, 0x48b1b2c3), (23, 0x53f448f2), (24, 0x928e10a3), (25, 0xf9243b0f), (26, 0xbf262f5d), (27, 0x4d022d07), (28, 0x582a244c), (29, 0xce36a4cb), (30, 0x2475ff72), (31, 0xe1258797), (32, 0x87e6ec25), (33, 0xd5e8cd78), (34, 0x5969bfaa), (35, 0x463fbdb6), (36, 0xcc452258), (37, 0xfc7aa72e), (38, 0xdc251d18), (39, 0x64b8e7ad), (40, 0x4fb420c5), (41, 0x7bf1f5fe), (42, 0x53c708b5), (43, 0xc5e696c6), (44, 0x9218027d), (45, 0xb9fba67b), (46, 0xc9bab150), (47, 0x12713991), (48, 0x73c10dca), (49, 0xf81e0514), (50, 0x00f77475), (51, 0x4dbdfc5c), (52, 0x9126bb1b), (53, 0x0e45c4f9), (54, 0xd9d77568), (55, 0x290f749d), (56, 0x7497b79e), (57, 0x9ac44e71), (58, 0x3396b3db), (59, 0x723b9b46), (60, 0x62a04c34), (61, 0xabbcf765), (62, 0x2e10db06), (63, 0x8d29775e), (64, 0x2880fb99)]
        s = String(UInt8[1:n;])
        ss = SubString(String(UInt8[0:(n+1);]), 2:(n+1))
        @test crc32(UInt8[1:n;]) == crc == crc32(s) == crc32(ss) == crc32(codeunits(s)) == crc32(codeunits(ss))
    end

    # test that crc parameter is equivalent to checksum of concatenated data,
    # and test crc of subarrays:
    a = UInt8[1:255;]
    crc_256 = crc32(a)
    @views for n = 1:255
        @test crc32(a[n+1:end], crc32(a[1:n])) == crc_256
    end
    @test crc32(IOBuffer(a)) == crc_256
    let buf = IOBuffer()
        write(buf, a[1:3])
        @test crc32(seekstart(buf)) == crc32(a[1:3])
        @test crc32(buf) == 0x00000000
        @test crc32(seek(buf, 1)) == crc32(a[2:3])
        @test crc32(seek(buf, 0), 2) == crc32(a[1:2])
        @test crc32(buf) == crc32(a[3:3])
        @test_throws ArgumentError crc32(buf, -1)
    end
    let buf = IOBuffer(a, read=false)
        @test_throws ArgumentError crc32(buf)
    end

    let f = tempname()
        try
            write(f, a)
            @test open(crc32, f) == crc_256
            open(f, "r") do io
                @test crc32(io, 16) == crc32(a[1:16])
                @test crc32(io, 16) == crc32(a[17:32])
                @test crc32(io) == crc32(a[33:end])
                @test crc32(io, 1000) == 0x00000000
            end
            a = rand(UInt8, 30000)
            write(f, a)
            @test open(crc32, f) == crc32(a) == open(io -> crc32(io, 10^6), f)
        finally
            rm(f, force=true)
        end
    end

    # more test data generated from @andrewcooke's CRC.jl package
    for (s,crc) in [("m", 0xe101f268), ("265FK7ZaL4", 0xde12ba25), ("picosliZI4i8rje39N6aHwHJNC6anyvnEv9Fmrw7cqiiNexvagh05QyFJlikBFGUvZTpcvPOFqcYEegVfxx05918p8NBo366raIr", 0x075b8144), ("uKMNBMv0dKyjurd1IYsJ5E26wEgI7Cr0IxmxzoZK3B9VaKT1kaBOPT5wiKUIUmu5K9mdp16wUWwFtTmJe9hVsMSDyXocQz87C0VUvRWyMooUTcKUXJqNC3bs7On0fYvoVXadiKTJoampyBdIQQCo8HE5AXjdVlnduD2OMNt6Itv8xb3BrmzTJyISWvZ371zaXl0AXSEgSUPXzJrcjSa6fCwLGjdC7SlJv8UX4jG1WkF7dZw8H770dRywea318fsaGNkSwJXhYD0CI1pE6aKEUeInRQDSUVrmonZkg6nlRDfUQQSM0gOZb2VVmbpJYf24cFHGNjyHDFEeElrfmSYXPEXkk4CaZypa3lYAozMqFW18I6buetXN7HJR2nGMAhfFqUMb3KjEqsWn0i56OGZJefv0cLVez3yQLpdObG0MURqIqyHZk4o1kdzRai7M9z3o7Cmvbc2dVIQ9eT1XJ7QRSEMt62dOPlqkJs3th1e9pyOdEyiekavY1CYbJzmwke33XiGj1EQHsEDqYqBt0goIcSxd9vWFm6E1LPs5D4xPzFS7BiMtjhGnl3qcNx24qrVCK0RNo61q6NiRJiIbe39gt9g0WRrc8ylADPlXuyRznkgd78JnR6L7cFq8Mxpik1c682gr53M9GLNVw0wncsHsFW06PbqOeOHwhBhlLFYasbKYmY50snyV6BUnetLd8HZKg7eVJxvnZga2EvPbG8T7lL6jMMxivnC7gyPQ33UnH56l9usopsv7YYUe51mwMkfoo1kL5iG1bIxwt4PAhbAtVl29Rlzd9SYK6gxvzqazb2dpaoP8nm6wfNtJTf1CFH9fWo8tW6h37uqA9dVnhTZFu5JUulN2Ie7mjTw8XGNmmPUqMwVn2drOdoOpetQb4PowQcGQ3cDjmrTOhqyGhFb7uJewdZMozCnC9ZM1fXRFGg0BhGK7SoOodEenZV9ha2spynomj7kU3wBQCER7XNIi07HUibxzTYtZlJAUmuY2", 0x9b7ca9b1)]
        @test crc32(s) == crc
    end

    # Test large arrays work on 64 bit machines
    if Sys.WORD_SIZE == 64
        @test crc32(zeros(UInt8, 2^32)) == 0xd202ef8d #crc32(zeros(UInt8, 2^31), crc32(zeros(UInt8, 2^31)))
    end
end