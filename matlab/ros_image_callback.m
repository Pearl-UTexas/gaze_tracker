
function resp = ros_image_callback(~, message, resp)
    global objectLabel;
    global frame_count;

    im = readImage(message.Image); %Read ros image  
    im = imresize(im,0.5);
    
     %% Face detector
     if(size(message.Faces,1)==0)
         disp('No face detected');
     	return
     end     
     
     bboxes = message.Faces.Data;
     bboxes = bboxes';
     for j=1:size(bboxes,1)
        width = bboxes(j,4)-bboxes(j,2);
        height = bboxes(j,3)-bboxes(j,1);
        bboxes(j,:) = [bboxes(j,2) bboxes(j,1) width height];       
     end

     bboxes = floor(bboxes/2);
     max_b = 1;
     
     if(size(bboxes,1)>1)
         max_area = bboxes(1,3) * bboxes(1,4);
         for j=2:size(bboxes,1)
             area = bboxes(j,3) * bboxes(j,4);
             if(area>max_area)
                max_area = area;
                max_b = j;
             end
         end
     end
          
     %disp([num2str(size(bboxes,1)) ' faces detected']);
     e = [(bboxes(max_b,1)+bboxes(max_b,3)/2)/size(im,2) (bboxes(max_b,2)+bboxes(max_b,4)/2)/size(im,1)];  
     
     global window_size;
     global face_output;
     if(window_size~=0)
         % Face detection smoothing
         [e, face_output] = smoothing(e, face_output);
     end
     
     %% Compute Gaze 
     global saliency_type;
     global net;

     % default gaze coordinate output from Recasens et al.
     if(strcmp(saliency_type,'default'))
         [x_predict,y_predict,hm,~] = predict_gaze(im,e);
         gaze_mask_ = net.blobs('importance_map').get_data();
         
     % snapping default output to closest yolo bounding box
     elseif(strcmp(saliency_type,'nearest-neighbor'))            
         [x_predict,y_predict,hm,~] = predict_gaze(im,e);
         gaze_mask_ = net.blobs('importance_map').get_data(); 
         
         % snap to closest bounding box
         [objectLabel, ~, idx] = nearest_neighbor(message.Objects,[x_predict, y_predict], size(im));
         
         %get coordinates of chosen bounding box
         if(objectLabel)
            x_predict = double(message.Objects(idx).CentroidX)/(2*size(im,2));
            y_predict = double(message.Objects(idx).CentroidY)/(2*size(im,1));
         end
         
         disp(['Object of attention (referential gaze): ' objectLabel])
     
     % using the gaze mask weights inside yolo bounding boxes
     elseif(strcmp(saliency_type,'weighted-avg'))  
         [x_predict,y_predict,hm,~] = predict_gaze(im,e);
         gaze_mask_ = net.blobs('importance_map').get_data();  % 13x13 mask
         gaze_mask = rot90(gaze_mask_);
         [objectLabel, ~, idx] = weighted_avg_scaled(message.Objects, gaze_mask, size(im));
         
         %get coordinates of chosen bounding box
         if(objectLabel)
            x_predict = double(message.Objects(idx).CentroidX)/(2*size(im,2));
            y_predict = double(message.Objects(idx).CentroidY)/(2*size(im,1));
         end
         
         disp(['Object of attention (referential gaze): ' objectLabel])

     end
   
     %% scaled Gaze and Head coordinates
     g = floor([x_predict y_predict].*[size(im,2) size(im,1)]); 
     e = floor(e.*[size(im,2) size(im,1)]);

     
     %% Mutual Gaze computation
     [mutual_flag, mutual_value] = mutual_gaze(gaze_mask_);
     disp(['Mutual Gaze: ' num2str(mutual_flag)]);
     
     %% Smoothing of gaze coordinates
     global gaze_output;
     if(strcmp(saliency_type,'default'))
         if(window_size~=0)
             % Gaze coordinates output Smoothing
             [g, gaze_output] = smoothing(g, gaze_output); 
         end
         disp(['Gaze coordinates: ' num2str(g(1)) ', ' num2str(g(2))])
     end
     
     
     %% Publish outputs
     resp.Coordinates.Data = [g,e];
     resp.Mutual.Data = mutual_flag;
     resp.NearestObject.Data = objectLabel;   
     resp.MutualValue.Data = mutual_value;
     resp.FrameCount.Data = frame_count;
     
 end
