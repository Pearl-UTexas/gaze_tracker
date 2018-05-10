
function resp = ros_image_callback(~, message, resp)
    global prediction;

    global t;
    d = cputime-t;

    im = readImage(message.Image); %Read ros image
    im = imresize(im,0.5);
    
     %% Head detector
     %e = [157/size(im,2)  117/size(im,1)]; 
     %disp(message.Objects(1).Label)
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
     %size(bboxes)
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
     
     
     disp([num2str(size(bboxes,1)) ' faces detected']);
     e = [(bboxes(max_b,1)+bboxes(max_b,3)/2)/size(im,2) (bboxes(max_b,2)+bboxes(max_b,4)/2)/size(im,1)];     
     
     %% Compute Gaze 
     global saliency_type;
     global net;
     global centroid;
     global dims;
     if(strcmp(saliency_type,'default'))
         [x_predict,y_predict,hm,~] = predict_gaze(im,e);
         
         %Visualize Heatmaps
%          gaze_mask = net.blobs('importance_map').get_data();
%          gaze_mask = rot90(gaze_mask);
%          %gaze_mask = imresize(gaze_mask, [227,227], 'bicubic');
%          fused_gaze_mask = visualize(im,gaze_mask);
%          figure(2);
%          imshow(fused_gaze_mask);
         
%          sal_mask = net.blobs('conv5_red').get_data();        
%          disp('max-min');
%          disp(max(max(sal_mask)));
%          disp(min(min(sal_mask)));
%          sal_mask = imresize(sal_mask, [227,227], 'bicubic');
%          sal_mask = rot90(sal_mask);
%          fused_sal_mask = visualize(im,sal_mask);
%          figure(3);
%          imshow(fused_sal_mask);
%          
%          fused_hm = visualize(im, hm);
%          figure(4);
%          imshow(fused_hm);
         
     elseif(strcmp(saliency_type,'yolo'))
         % Get own saliency map [13x13]
         sal_full = ones(size(im,1),size(im,2),'single')*0;%*0.01;
         num_objects = size(message.Objects,1);
         for j=1:num_objects
             width = message.Objects(j).RightTopX/2 - message.Objects(j).LeftBotX/2;
             height = message.Objects(j).LeftBotY/2 - message.Objects(j).RightTopY/2; %25
             radius = 15;
             center = [message.Objects(j).CentroidX/2, message.Objects(j).CentroidY/2]; %x,y
             %center = [message.Objects(j).LeftBotX/2 + width/2, message.Objects(j).RightTopY/2 + height/2];
             %for x = message.Objects(j).LeftBotX/2:message.Objects(j).RightTopX/2
             %   for y = message.Objects(j).RightTopY/2:message.Objects(j).LeftBotY/2
             for x = center(1)-radius:center(1)+radius
                 for y = center(2)-radius:center(2)+radius
                    x_mod = double(abs(x-center(1)));
                    y_mod = double(abs(y-center(2)));
                    sal_full(y,x) = exp(-1*( x_mod*x_mod + y_mod*y_mod)/(2*radius*radius/3)); %625
                    %sal_full(y,x) = 1;
                    %sal_full(y,x) = exp(-1*( (power(x_mod,2)/(2*power(double(width),2)/3)) ...
                    %    + (power(y_mod,2)/(2*power(double(height),2)/3)) )); %2*5/3
                end
             end
         end
         %imagesc(sal_full);
         sal = zeros(13,13,1,1,'single');
         sal(:,:,1,1) = imresize(sal_full,[13,13],'bicubic');
         sal_rot = 10*sal;         
         %sal_rot = rot90(sal_rot,1); 
         %sal_rot = flip(sal_rot,1);
         sal_rot = rot90(sal_rot,3); 
         %imagesc(sal_rot);
         [x_predict,y_predict,hm,~] = predict_gaze_own(im,e,sal_rot);
         
         gaze_mask_s = net.blobs('importance_map').get_data();
         gaze_mask = imresize(gaze_mask_s, [227,227], 'bicubic');
         gaze_mask = rot90(gaze_mask);
         fused_gaze_mask = visualize(im, gaze_mask);
         figure(2);
         imshow(fused_gaze_mask);
         
%          sal_mask = imresize(sal_rot, [227,227], 'bicubic');
%          %sal_mask = imresize(sal_full, [227,227], 'bicubic');
%          sal_mask = rot90(sal_mask);
%          fused_sal_mask = visualize(im,sal_mask);
%          figure(3);
%          imshow(fused_sal_mask);
%          
%          combined = gaze_mask_s.*sal_rot;
%          combined_rot = rot90(combined);
%          combined_full = imresize(combined_rot, [size(im,1), size(im,2)], 'bicubic');
%          fused_hm = visualize(im, combined_full);
%          figure(4);
%          imshow(fused_hm);
%          
%          [~,idx]=max(combined_full(:));
%          [row,column]=ind2sub(size(combined_full), idx);
%          x_predict = column/size(combined_full,2);
%          y_predict = row/size(combined_full,1);
         
         max_score = 0;
         scores = [];
         for j=1:num_objects
             message.Objects(j)
             width = message.Objects(j).RightTopX/2 - message.Objects(j).LeftBotX/2;
             height = message.Objects(j).LeftBotY/2 - message.Objects(j).RightTopY/2;
             center = [message.Objects(j).CentroidX/2, message.Objects(j).CentroidY/2];
             area = width*height;
             gaze_map = imresize(gaze_mask_s, [size(im,1), size(im,2)], 'bicubic');
             patch = gaze_map(message.Objects(j).RightTopY/2:message.Objects(j).LeftBotY/2, ...
                           message.Objects(j).LeftBotX/2:message.Objects(j).RightTopX/2);
             score = double(sum(patch(:)))/double(area);
             scores = [scores, score];
             if score>max_score
                 max_score = score;
                 x_predict = double(center(1))/size(im,2) ; y_predict = double(center(2))/size(im,1);
             end
         end
         scores
     
     elseif(strcmp(saliency_type,'weighted_avg'))
         disp('weighted average');    
         [x_predict,y_predict,hm,~] = predict_gaze(im,e);
         gaze_mask = net.blobs('importance_map').get_data();  % 13x13
         gaze_mask = rot90(gaze_mask);
         prediction = weighted_avg(message.Objects, gaze_mask, size(im));
     
     elseif(strcmp(saliency_type,'spatial_bins'))
         disp('spatial bins');
         [x_predict,y_predict,hm,~] = predict_gaze(im,e);
         gaze_mask = net.blobs('importance_map').get_data();  % 13x13
         gaze_mask = rot90(gaze_mask);
         prediction = spatial_bins(message.Objects, gaze_mask, size(im));
         
%      elseif(strcmp(saliency_type,'gaussian_dist'))
%          disp('distance from gaussian');
%          [x_predict,y_predict,hm,~] = predict_gaze(im,e);
%          gaze_mask = net.blobs('importance_map').get_data();  % 13x13
%          gaze_mask = rot90(gaze_mask);
%          prediction = gaussian_dist(message.Objects, gaze_mask, size(im));
         
     elseif(strcmp(saliency_type,'hlpr'))
         disp('hlpr');    
         [x_predict,y_predict,hm,~] = predict_gaze(im,e);
         imshow(im);
         hold on;
         for i=1:size(centroid,1)
             x = centroid(i,1)*size(im,2)
             y = centroid(i,2)*size(im,1)
             width = dims(i,1)*size(im,2);
             height = dims(i,2)*size(im,1);
             rectangle('Position',[x-width/2,y-height/2,width,height],'LineWidth',5);            
         end
     elseif(strcmp(saliency_type,'nearest-neighbor'))    
         disp('nearest neighbor');
         [x_predict,y_predict,hm,~] = predict_gaze(im,e);
         prediction = nearest_neighbor(message.Objects,[x_predict, y_predict]);
     end
   
     %% Visualization output
     g = floor([x_predict y_predict].*[size(im,2) size(im,1)]); 
     e = floor(e.*[size(im,2) size(im,1)]);
     %hold on;
     %plot([e(1),g(1)],[e(2),g(2)],'Color','b','LineWidth',5);
     
     %% Mutual Gaze computation
     mutual_flag = mutual_gaze();
     disp(mutual_flag);
     
     %% Smoothing
     global window_size;
     global face_output;
     global gaze_output;
     if(window_size~=0)
         % Face detection smoothing
         [e, face_output] = smoothing(e, face_output);  

         % Gaze output Smoothing
         [g, gaze_output] = smoothing(g, gaze_output);  
     end
     %start emptying output lists if time elapsed since last face detected
     %greater than some threshold
     
     %% Publish outputs
     resp.Coordinates.Data = [g,e];
     resp.Mutual.Data = mutual_flag;
     resp.NearestObject.Data = prediction;   
     
     t = cputime;
     %disp([num2str(d) ' ms'])
 
 end
