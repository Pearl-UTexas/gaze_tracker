 % Demo script to use the gaze following model
 % Written by Adria Recasens (recasens@mit.edu)
 addpath(genpath('/home/siml/caffe/matlab/'))
 addpath(genpath('/home/siml/gaze_prediction/joint-attention-hri/'))
 
 global gaze_output;
 global face_output;
 global window_size;
 global t;
 global mutual_gaze_type;
 global saliency_type;
 global gaze_prediction_type;
 global frame_count;
 global centroid;
 global dims;
 global kinect_image;
 
 kinect_image = [];
 gaze_output = [];    
 face_output = [];
 window_size = 3; %average current frame prediction with last 3 frames
 frame_count = 0;
 centroid = [];
 dims = [];
 
 mutual_gaze_type = 'manhattan'; % options: 'variance', 'entropy', 'manhattan'
 saliency_type = 'default'; % options: 'default', 'yolo', 'hlpr'
 gaze_prediction_type = 'default'; %options: 'default', 'nearest-neighbor', 'normalized-sum-bb', 'spatial-bins', 'dist-from-mean'
 
 global net;    
 if(strcmp(saliency_type,'default'))
    definition_file = ['../model/deploy_demo.prototxt'];
 else
    definition_file = ['../model/deploy_own.prototxt'];
 end
 if(strcmp(saliency_type,'hlpr'))
    definition_file = ['../model/deploy_demo.prototxt'];
 end
 
 binary_file = ['../model/binary_w.caffemodel'];
 use_gpu = 1;

 if use_gpu
    caffe.set_mode_gpu();
    gpu_id = 0;  % we will use the first gpu in this demo
    caffe.set_device(gpu_id);
 else
    caffe.set_mode_cpu();
 end
 net = caffe.Net(definition_file, binary_file, 'test');
 disp('Network loaded');
 
 %% ROS portion
 rosshutdown
 rosinit('http://10.66.171.4:11311/');
 %rosinit('http://localhost:11311/');
 server = rossvcserver('/gaze_predict','object_detector/GazePredict',@ros_image_callback);
 pause(2);
 t = cputime;
 %sub = rossubscriber('/object_detector_bridge',{@ros_image_callback, pub}); 
 if(strcmp(saliency_type,'hlpr'))
     sub_features = rossubscriber('/bounding_boxes',@ros_hlpr_callback);
     sub_image = rossubscriber('/kinect/qhd/image_color_rect', @ros_kinect_callback);
 end
