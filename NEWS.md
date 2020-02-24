# News / Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Conditional target/source matching (e.g. only connect pairs of pixels that have similar climates).
- Parallelism via multi-threading.
- Reduced overhead in parallel processing, added batching [#10](https://github.com/Circuitscape/Omniscape.jl/issues/10)
- Changed how BLAS number of threads is set ([#25](https://github.com/Circuitscape/Omniscape.jl/pull/25)) to get closer to number of physical cores and improve efficiency.
- Closed [#13](https://github.com/Circuitscape/Omniscape.jl/issues/13)
- Julia dep is now 1.4

### Monitor progress toward release
- [Release v0.2.0](https://github.com/Circuitscape/Omniscape.jl/milestone/2)

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

[Unreleased]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.4...master
[v0.1.4]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.3...v0.1.4
[v0.1.3]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.2...v0.1.3
[v0.1.2]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.0...v0.1.2
[v0.1.1]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.0...v0.1.1
