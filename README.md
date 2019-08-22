# Overview

UVCamera is an iPhone program designed to let the operator take photos from both
the f/1.8 "wide-angle" and f/2.4 "telephoto" rear-facing cameras on the back of 
an iPhone XS.

# References

- [Swift 4 & iOS 11: Custom Camera View (Ep3 of Build a Custom Camera)](https://www.youtube.com/watch?v=7TqXrMnfJy8)
- [Accelerate and vImage](https://developer.apple.com/documentation/accelerate)

When an Android version floats up the priority stack, have a look at this:

- https://medium.com/androiddevelopers/using-multiple-camera-streams-simultaneously-bf9488a29482

# Version History

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
    - submitted for TestFlight
- 2019-07-19 1.1.3
    - resolved most constraint warnings
    - fixed screens for 6.5", 5.5"
    - better handling of non-dual-camera iPhones
    - first App Store submission [update: rejected]
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
