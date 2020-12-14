# How It Works

The Omniscape algorithm works by applying Circuitscape iteratively through the landscape in a moving window with a user-specified radius. Omniscape requires two basic inputs: a resistance raster, and a source strength raster. The resistance raster defines the traversal cost for every pixel in the landscape. The source strength raster defines for every pixel the relative amount of current to be injected into that pixel. A diagram of the moving window, adapted and borrowed from McRae et al. 2016, is shown in figure 1 below.

```@raw html
<img src='../figs/moving_window.png' width=350)> <br><em><b>Figure 1</b>: An illustration of a moving window iteration in the Omniscape algorithm.</em><br><br>
```

The algorithm works as follows:
1. The window centers on a pixel in the source strength surface that has a source strength greater than 0 (or a user specified threshold). This is referred to as the target pixel.
2. The source strength and resistance rasters are clipped to the circular window.
3. Every source pixel within the search radius that also has a source strength greater than 0 is identified. These are referred to as the source pixels.
4. Circuitscape is run using the clipped resistance raster in “advanced” mode, where the target pixel is set to ground, and the source pixels are set as current sources. The total amount of current injected is equal to the source strength of the target pixel, and is divvied up among the source pixels in proportion to their source strengths.
5. Steps 1-4 are repeated for every potential target pixel. The resulting current maps are summed to get a map of cumulative current flow.

The Omniscape algorithm evaluates connectivity between every possible pair of pixels in the landscape that are a) valid sources (i.e. have a source strength greater than 0 or other user-specified threshold) and b) no further apart than the moving window radius.
