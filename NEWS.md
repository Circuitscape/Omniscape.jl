# News / Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
- closed [#53](https://github.com/Circuitscape/Omniscape.jl/issues/53)
- Added option to reclassify categorical resistance surfaces using a user-provide reclass table [#56](https://github.com/Circuitscape/Omniscape.jl/pull/56)
- Fixed a minor error that sometimes prevented last row/column of targets from being solved and accumulating current [07e1704](https://github.com/Circuitscape/Omniscape.jl/commit/07e170411b17dc2979f83bc583d3262a53f7322b)

## [v0.3.0]
- closed [#46](https://github.com/Circuitscape/Omniscape.jl/issues/46)
- closed [#40](https://github.com/Circuitscape/Omniscape.jl/issues/40), added experimental 32-bit option
- switched to using Circuitscape's tiff reading functions, bumped Circuitscape version dependency to 5.6

## [v0.2.2]
- Closed [#43](https://github.com/Circuitscape/Omniscape.jl/issues/43) related to GeoTiff writing.

## [v0.2.1]
- Fixed a bug in `read_raster` with NoData value parsing for Float32 tif rasters.

## [v0.2.0]
- Conditional target/source matching (e.g. only connect pairs of pixels that have similar climates).
- Parallelism via multi-threading.
- Reduced overhead in parallel processing, added batching. ([#10](https://github.com/Circuitscape/Omniscape.jl/issues/10))
- Changed how BLAS number of threads is set. ([#25](https://github.com/Circuitscape/Omniscape.jl/pull/25))
- Julia dep is now 1.4. (see [#13](https://github.com/Circuitscape/Omniscape.jl/issues/13) for why)
- Major reductions in memory usage. ([#33](https://github.com/Circuitscape/Omniscape.jl/issues/33), and [#36](https://github.com/Circuitscape/Omniscape.jl/issues/36))
- Updated some .ini argument names related to output write options and conditional connectivity options.
- Omniscape can now read and write both .tif and .asc files. ([#34](https://github.com/Circuitscape/Omniscape.jl/pull/34))
- Added option to supply conductance instead of resistance surface as input. ([#30](https://github.com/Circuitscape/Omniscape.jl/pull/30))

## [v0.1.4]
- Fixed [#19](https://github.com/Circuitscape/Omniscape.jl/issues/19) (NaNs in normalized current flow map). Current and flow potential equal to 0 resulted in 0/0, causing NaNs. NaNs are now replaced with 0.
- Closed [#20](https://github.com/Circuitscape/Omniscape.jl/issues/20). Added option to allow masking of outputs according to nodata values in resistance.

## [v0.1.3]
- Updated Circuitscape compat to v5.5.5. The rename of zlib in Julia 1.3 caused a break in GZip on Windows, which broke Circuitscape (which broke Omniscape). GZip released a patch, v0.5.1, fixing the issue. Circuitscape patch release v5.5.5 has an updated compat entry of 0.5.1 for GZip, which fixes the issue downstream.

## [v0.1.2]
- Fixed an issue with target identification and source strength allocation
- Omniscape now accepts any nodata value in input files

## [v0.1.1]
- Fixed bug that prevented use on Windows systems
- Some general code housekeeping

## v0.1.0
- Omniscape algorithm with parallel processing
- method for block artifact correction
- option to use resistance surface to assign source weights

[Unreleased]: https://github.com/circuitscape/Omniscape.jl/compare/v0.3.0...main
[v0.3.0]: https://github.com/circuitscape/Omniscape.jl/compare/v0.2.2...v0.3.0
[v0.2.2]: https://github.com/circuitscape/Omniscape.jl/compare/v0.2.1...v0.2.2
[v0.2.1]: https://github.com/circuitscape/Omniscape.jl/compare/v0.2.0...v0.2.1
[v0.2.0]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.4...v0.2.0
[v0.1.4]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.3...v0.1.4
[v0.1.3]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.2...v0.1.3
[v0.1.2]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.0...v0.1.2
[v0.1.1]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.0...v0.1.1
