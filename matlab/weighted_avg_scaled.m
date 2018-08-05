function [predicted_obj, scores, idx] = weighted_avg_scaled(yolo_objects, gaze_map, im_size)
im_width = im_size(2); % no. of columns
im_height = im_size(1); % no. of rows

num_objects = size(yolo_objects,1);
if(num_objects<1)
    predicted_obj = '';
    disp('No yolo objects detected');
    return;
end
scores = zeros(num_objects,1);

% upsample gaze map dimensions to image size
gaze_map = imresize(gaze_map, [im_height, im_width], 'bicubic');

for j=1:num_objects
    if(strcmp(yolo_objects(j).Label,'spoon') || strcmp(yolo_objects(j).Label,'plate'))
        continue;
    end

    % dimensions of an object for the full image
    obj_width = yolo_objects(j).RightTopX/2 - yolo_objects(j).LeftBotX/2;
    obj_height = yolo_objects(j).LeftBotY/2 - yolo_objects(j).RightTopY/2; %25
    obj_center = [yolo_objects(j).CentroidX/2, yolo_objects(j).CentroidY/2];
    obj_area = obj_width * obj_height;    
    
    % compute score within bounding box
    for c=obj_center(1)-obj_width/2: obj_center(1)+obj_width/2
        for r=obj_center(2)-obj_height/2 : obj_center(2)+obj_height/2
            %j
            scores(j) = scores(j) + gaze_map(r,c);
        end
    end
   
    scores(j) = scores(j)/double(obj_area);
end

[~,idx] = max(scores);
predicted_obj = yolo_objects(idx).Label;



