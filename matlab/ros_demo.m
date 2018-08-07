 % Prediction of human's object of attention
 addpath(genpath('/home/pearl/caffe/matlab/'))
 addpath(genpath('/home/pearl/catkin_ws/src/gaze_tracker/matlab'))
 addpath(genpath('/home/pearl/toolbox/'))
 
 global gaze_output;
 global face_output;
 global window_size;
 global mutual_gaze_type;
 global saliency_type;
 global frame_count;
 global centroid;
 global dims;
 global kinect_image;
 global objectLabel;
 
 kinect_image = [];
 gaze_output = [];    
 face_output = [];
 window_size = 3; %average current frame prediction with last 3 frames
 frame_count = 0;
 centroid = [];
 dims = [];
 objectLabel='';
 
 mutual_gaze_type ='random-forest'; % options: 'random-forest', 'variance', 'entropy', 'distance'
 saliency_type = 'weighted-avg'; % options: 'default', 'nearest-neighbor', 'weighted-avg' 
 
 global net;    
 definition_file = 'deploy_demo.prototxt';
 binary_file = 'binary_w.caffemodel';
 use_gpu = 1;

 if use_gpu
    caffe.set_mode_gpu();
    gpu_id = 0;  % use the first gpu in this demo
    caffe.set_device(gpu_id);
 else
    caffe.set_mode_cpu();
 end
 net = caffe.Net(definition_file, binary_file, 'test');
 disp('Network loaded');
 
 %% ROS callback
 rosinit('http://localhost:11311/');
 server = rossvcserver('/gaze_predict','gaze_tracker/GazePredict',@ros_image_callback);


