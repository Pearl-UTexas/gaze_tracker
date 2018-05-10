function predicted_obj = spatial_bins(yolo_objects, gaze_map, im_size)

num_objects = size(yolo_objects,1);
scores = zeros(num_objects, 4);
scores_overall = zeros(num_objects);

for j=1:num_objects
    % dimensions of an object for the full image
    obj_width = yolo_objects(j).RightTopX/2 - yolo_objects(j).LeftBotX/2;
    obj_height = yolo_objects(j).LeftBotY/2 - yolo_objects(j).RightTopY/2; %25
    obj_center = [yolo_objects(j).CentroidX/2, yolo_objects(j).CentroidY/2];
    obj_area = obj_width * obj_height;
    
    % upsample gaze map dimensions to image size
    gaze_map = imresize(gaze_map, im_size, 'bicubic');
    
    % compute score within bounding box
    for c=obj_center(1)-obj_width/2 : obj_center(1)
        for r=obj_center(2)-obj_height/2 : obj_center(2)
            scores(j,1) = scores(j,1) + gaze_map(r,c);
        end
    end
    
    for c=obj_center(1)-obj_width/2 : obj_center(1)
        for r=obj_center(2) : obj_center(2)+obj_height/2
            scores(j,2) = scores(j,2) + gaze_map(r,c);
        end
    end
    
    for c=obj_center(1) : obj_center(1)+obj_width/2
        for r=obj_center(2)-obj_height/2 : obj_center(2)
            scores(j,3) = scores(j,3) + gaze_map(r,c);
        end
    end
    
    for c=obj_center(1) : obj_center(1)+obj_width/2
        for r=obj_center(2) : obj_center(2)+obj_height/2
            scores(j,4) = scores(j,4) + gaze_map(r,c);
        end
    end
    
    for i=1:4
        scores_overall(j) = scores_overall(j) + 0.25*scores(j,i);
    end    
    scores_overall(j) = scores_overall(j)/obj_area;
end

[~,predicted_obj] = max(scores_overall);

end