# Gaze Tracker

:warning:This package has not been tested with OpenCV 3.0+, we recommended using OpenCV 2.4 or similar:warning:

This package is a deep learning based human gaze tracker.
## Setup
### Rail Object Detector
1) Follow installation instructions for [Rail Object Detector](https://github.com/GT-RAIL/rail_object_detector)
2) Compile for CUDA support if you have a NVIDIA GPU for 10x speed improvement in object detection
3) Configure Darknet with training data (in libs/darknet)
4) Copy launch file from our samples directory and edit darknet paths to match those on your system

### Face Recognition
We use [this](https://github.com/ageitgey/face_recognition) dlib based face detector in this package.

Install by running: ```pip install face_recognition```

### Matlab
Need to install Matlab for the gaze detection portion of the system. 
We recommend install Matlab R2016b due to issues with OpenCV for other versions. This script also requires you to have the Computer Vision and [what else?] toolboxes installed.

## Running the system
1) Edit gaze_predict.launch to have the correct image topic name for your system and correct rail_object_detector launch file nname
2) Run gaze_predict.launch 
3) Run [matlab file name] on Matlab
