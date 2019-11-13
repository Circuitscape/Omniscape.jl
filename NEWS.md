# News / Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Adding
- Option to do climate-based connectivity
- Parallelism via multi-threading (done in [threads](https://github.com/Circuitscape/Omniscape.jl/tree/threads) branch)

- Omniscape now accepts any nodata value in input files

## [v0.1.2]
- Fixed an issue with target identification and source strength allocation

## [v0.1.1]
- Fixed bug that prevented use on Windows systems
- Some general code housekeeping

## v0.1.0
- Omniscape algorithm with parallel processing
- method for block artifact correction
- option to use resistance surface to assign source weights

[Unreleased]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.0...master
[v0.1.1]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.0...v0.1.2
[v0.1.1]: https://github.com/circuitscape/Omniscape.jl/compare/v0.1.0...v0.1.1
