# Gaze Tracker

:warning:This package has not been tested with OpenCV 3.0+, we recommended using OpenCV 2.4 or similar:warning:

This ROS package predicts the object of a human's attention using a single monocular camera. This package was tested on Ubuntu 16.04 and ROS Kinetic.
## Setup
### Rail Object Detector
* Follow installation instructions for Darknet on [Rail Object Detector](https://github.com/GT-RAIL/rail_object_detector)<!--* Replace the package.xml file with [this](https://drive.google.com/open?id=1EzGQQhaIALdVx0TIQlaRfDJksBwPw-eR) one. -->
* Compile for CUDA support if you have a NVIDIA GPU for 10x speed improvement in object detection and gaze prediction. Recommended: CUDA 8.0, CUDNN 5.1
* Configure launch/gaze_predict.launch file with locations of configuration data for Darknet

### Face Recognition
We use a [dlib based face detector](https://github.com/ageitgey/face_recognition) in this package.

Install by running: ```pip install face_recognition```

### UI Dependencies
We provide a simple web interface to display the camera feed and gaze prediction locations. Run the following commands to setup the interface

#### JS
Run `npm install` in the [ui](./ui/) folder

#### ROS
Install the `rosbridge-server` and `web-video-server` packages
```
sudo apt-get install ros-<rosdistro>-rosbridge-server
sudo apt-get install ros-<rosdistro>-web-video-server
```

### Matlab & Caffe
* We recommend to install Matlab R2016b due to issues with OpenCV for other versions. Install the Computer Vision System Toolbox and Robotics System Toolbox.
* Install Caffe with CUDA support for a 10x speedup. Recommended: CUDA 8.0, CUDNN 5.1 
* Use gcc-4.9 for compiling matcaffe. Folow instructions [here](http://www.cs.jhu.edu/~cxliu/2016/compiling-matcaffe-on-ubuntu-1604.html).
* Type ```roboticsAddons``` into the Matlab console, and install the  ROS Custom Messages interface.
* Type ```rosgenmsg <path-to-workspace-src>```, follow the instructions and restart Matlab
* Install the [toolbox](https://github.com/pdollar/toolbox) for random forests
* Download the [model](http://gazefollow.csail.mit.edu/downloads/model.zip) trained by [Recasens et al.](http://people.csail.mit.edu/khosla/papers/nips2015_recasens.pdf), unzip it and place all files in the matlab folder.
* Change the path to your caffe, ros workspace and toolbox folders in `matlab/ros_demo.m`

## Running the system
* Edit `gaze_predict.launch` to have the correct image topic name for your system
* Run `gaze_predict.launch`
* Run `ros_demo.m` in Matlab


## Bibliography
If you find our work to be useful in your research, please cite:
```
@inproceedings{saran2018human,
  title={Human gaze following for human-robot interaction},
  author={Saran, Akanksha and Majumdar, Srinjoy and Short, Elaine Schaertl and Thomaz, Andrea and Niekum, Scott},
  booktitle={2018 IEEE/RSJ International Conference on Intelligent Robots and Systems (IROS)},
  pages={8615--8621},
  year={2018},
  organization={IEEE}
}
```
