Notes from Brad's Omniscape code

# [Omniscape.py](https://github.com/bmcrae/omniscape/blob/master/OmniScape.py)

## <ins>Inputs</ins> 

1. `resisRasterBase`
    - Resistance surface input
2. `sourceRasterBase`
    - *optional*, raster separate from resistance used to determine source strengths for all-to-one CS
    - 0's indicate a pixel is not a source/target
    - If this is not used, then source strengths are set using inverse of `resisRasterBase`. Inverse is performed prior to any rescaling/transformation of resistance surface

---
## <ins>Options/functionality</ins>

### Basic options (that I see as priority)
1. `radius`
    - Search radius *in pixels* for max distance for source including in CS all-to-one mode
    - Could change this to meters or kilometers in Julia code
2. `blockSize`
    - Blocking of targets (grounds) to reduce computational load
    - Must be odd number so a pixel is at the center.
    - central pixel of square with length = `blockSize` (*in pixels*) is used as target in CS all-to-one.
3. `runTitle`
    - Job name, string.
4. `projectDir`
    - Working directory to use
5. `outputDirBase`
    - String prefix for outputs
6. `useSourceRaster`
    - Boolean, use source raster instead of resistance surface for specifying locations and strengths of sources?
6. `rCutoff`
    - Only applies if `useSourceRaster` = FALSE
    - Cutoff for resistance surface used to determine sources. Any pixel with raw, untransformed resistance value $\scriptsize{\leq}$ `rCutoff` will be a source.
7. `sourceInverseR`
    - Boolean
    - If not using source raster,set source strenghts to inverse of resistance surface (applied before resistance transformations)


### Non-essential options for first pass

1. `numTiles`/`tileNum`
    - Break up analysis into tiles. Makes resistance surfaces smaller, so moving window solves are faster.
    - An alternative is to just buffer out some extra distance beyond `radius` and set resistance values beyond that area to noData or clip the inputs (setting to noData would be easier, but might not be faster for Circuistcape). Going to use this approach in Omniscape.jl
2. `useMask`, `maskRasterBase`
    - Optional, mask all inputs prior to running Omniscape
    - This can be useful to insure inputs line up, but not including for now as this can be done manually prior to running.
3. `squareResistances`, `squareRootInputs`
    - Transformations that can be applied to inputs prior to running Omniscape
    - This can be done prior to calling Omniscape, so leaving out for the first pass at a Julia port.
4. `calcMaxCur`
    - Option to calculate max current instead of sum. Apparently shows tiling artifacts more clearly, so leaving out for now. Might want a better solution for this that avoids tiling artifacts from moving window before implementing this option


### Climate options

1. `useClimate`
    - Boolean, use climate method for identifying source nodes for all-to-one CS?
2. `matchClimatePCs`
    - Boolean, use principle compenents axes to determine threshold for source inclusion? 
    - If false, uses present-day temperature difference instead
3. `tDiff`
    - Include source pixels with temperature difference (compared to target) of this value
4. `tWindow`
    - How close to `tDiff` must a pixel's temperature difference be to be included as a source
5. `climateRasterBase`
    - The temperature raster used for calculating differences
6. `absClim`
    - Boolean, Connect sources with absolute value differences within `tDiff` $\footnotesize{\pm}$ `tWindow`
7. Climate principal components (rasters)
    - `t1PC1RasterBase`: Present day climate PC axis \#1 
    - `t1PC2RasterBase`: Present day climate PC axis \#2
    - `t2PC1RasterBase`: Future climate PC axis \#1
    - `t2PC1RasterBase`: Future climate PC axis \#1
8. `PCWindow`
    - (maximum?) Euclidean distance between (t1PC1, t1PC2) and (t2PC1, t2PC2) coordinate pairs.
    - Used for source inclusion for all-to-one CS


### Distance function
Alternative methods to simple `radius`, and allows adjustment of source strength according to distance

1. `useDistanceFunction`
    - Boolean, allows use for min and max distances for source node inclusion instead of simple `radius`

2. `minDist`
    - *in pixels*; Pixels closer than this distance will be given source strength of 0
3. `maxDist`
    - *in pixels*; Pixels further than this will be given source strength of 0
4. `distEq`
    - A distance equation, presumably for adjusting source strengths based on distance to target?


### Additional flow accumulation calculations

Used to create additional output based on flow accumulation to complement/be contrasted against cumulative current outputs. Lines 66-69 in [Omniscape.py](https://github.com/bmcrae/omniscape/blob/master/OmniScape.py)

### Voltages
This was a work-in-progress. Need to figure out the direction Brad was trying to go with this. Intended to simply calculate voltages?

### Options to fade currents
Primarily to address edge/tiling effects of breaking analysis into blocks. Alternative solution (using buffered and clipped resistance surfaces) may obviate the need for this.

### Other arguments
1. `removeArtifacts`
    - Boolean. Again, intended to address tiling issue. Need to figure out what is done when this is TRUE.
2. `quantilizeMaps`, `numQuantiles`
    - Bins currents into quantiles for diplay purposes
    - Would prefer to just give raw output, and not quantilize for the user.
    
    
3. `calcNull`
    - Boolean, do additional analysis with all resistance = 1
    - Related to "flow potential"
    - Used to normalize current outputs to identify conservation opportunities? 

4. `calcFANull`
    - Same as above but for flow accumulation
5. `saveSourceAndTargetCounts`
    - Boolean, save number of sources per target?
6. `doSourceAndTargetCountsOnly`
    - Calculate only counts, don't run Circuitscape

7. `printTimings`
    - Will probably set this to TRUE by default, and allow option for "suppress messages" or somthing like that.

8. `cleanUpBandFiles`
    - Boolean, not sure what this does. I think related to tiling

9. `useCustomCSPath`, `CSPath`
    - Specify location of Circuitscape installation





