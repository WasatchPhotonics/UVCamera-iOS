# Overview

UV Camera is an iPhone app designed to use the dual-rear cameras of an iPhone XS
(or better), in combination with a custom UV filter inserted into the optical path
of one camera, to enhance and highlight UV signal within a visual image.

Visually, it turns this (where left side of paper is treated with spray-on UV-absorbant sunscreen):

![VIS](https://github.com/WasatchPhotonics/UVCamera-iOS/raw/master/website/images/before.jpeg)

...into this:

![UV](https://github.com/WasatchPhotonics/UVCamera-iOS/raw/master/website/images/after.jpeg)

This is the basic image processing pipeline:

![Processing](https://github.com/WasatchPhotonics/UVCamera-iOS/raw/master/website/images/processing.png)

# References

- [Swift 4 & iOS 11: Custom Camera View (Ep3 of Build a Custom Camera)](https://www.youtube.com/watch?v=7TqXrMnfJy8)

When an Android version floats up the priority stack, have a look at this:

- https://medium.com/androiddevelopers/using-multiple-camera-streams-simultaneously-bf9488a29482

# Backlog

If we’re specifically looking to find UV absorbance, and as an approximation 
we’re using shadows which are particularly or uniquely dark in the (380, 410nm) 
to represent that, then we should be able to bring those out using something like
this:

WHERE:

- Suv = Shadows exclusively in the range (380, 410nm) (not appearing in Svis)
- Svis = Shadows anywhere in VIS (410, 740nm)
- Sf = Shadows in filtered camera (380, 410nm)
- Sgr = Shadows in green, red region (500, 740nm)
- Sb = Shadows in blue region (380, 500nm)
- Sb’ = Shadows in blue region, above filter (410, 500nm)

PROCEDURE:

- generate Sf: copy filtered orig; drop green, red channels; grayscale; invert; 
  increase contrast (will show white for shadows in (380, 410); black for light 
  in (380, 410))
- generate Sgr: copy unfiltered orig; drop blue channel; grayscale; invert; 
  increase contrast (white for shadows in (500, 740); black for light in (500, 740))
- generate Sb: copy unfiltered orig; drop green, red channels; grayscale; invert;
  increase contrast (white for shadows in (380, 500); black for light in (380, 500))
- compute Sb’: Sf - Sb (white for shadows in (410, 500); black for light in (410, 500))
- compute Svis = Sgr + Sb’ (white for shadows in (410, 740); black for light in (410, 740))
- compute Suv = Sf - Svis (white for shadows exclusively in (380, 410))

So then if we tint Suv and blend it atop the original unfiltered image, we should
be highlighting regions which are especially low in UV.

# Version History

- 2019-10-15 2.0.1
    - fighting memory issues (too many debug saves)
    - kinda sorta seems to work?
- 2019-10-15 2.0.0
    - redesigned image processing pipeline for UV absorbance
    - added UIImage.copy, .dropBlue, .caption
    - runs, not spectrally evaluated
- 2019-08-23
    - migrated to GitHub
    - docs
- 2019-08-22 1.3.0
    - added normalize3()
    - added BlueFilter
    - successful testing with SPF-100 samples
- 2019-08-22 1.2.4
    - moved default preview session from NFOV to WFOV
    - added adjustContrast()
    - migrating to non-subtractive (filtered) UV acquisition
- 2019-08-21 1.2.3
    - moved UV filter from WFOV to NFOV
    - added UIImage.invert()
- 2019-07-22 1.2.2
    - added Launch Screen, online help
    - submitted for TestFlight (approved)
- 2019-07-19 1.1.3
    - resolved most constraint warnings
    - fixed screens for 6.5", 5.5"
    - better handling of non-dual-camera iPhones
    - first App Store submission (rejected)
- 2019-07-03 0.0.5
    - 3.5x speedup (removed manual pixel math)
- 2019-07-02 0.0.4
    - basic image-processing in place
- 2019-06-11 0.0.3
    - convert to mono
    - crop f/1.8 image to 50%
    - subtract images
- 2019-03-19 0.0.2
    - able to screenshot previews from both cameras
- 2019-03-19 0.0.1
    - stubbing views
