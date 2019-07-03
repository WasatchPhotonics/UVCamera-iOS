# Overview

UVCamera is an iPhone program designed to let the operator take photos from both
the f/1.8 "wide-angle" and f/2.4 "telephoto" rear-facing cameras on the back of 
an iPhone XS.

# References

- [Swift 4 & iOS 11: Custom Camera View (Ep3 of Build a Custom Camera)](https://www.youtube.com/watch?v=7TqXrMnfJy8)
- [Accelerate and vImage](https://developer.apple.com/documentation/accelerate)

# Version History

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
