function predicted_obj = weighted_avg(yolo_objects, gaze_map, im_size)
im_width = im_size(1);
im_height = im_size(2);

%normalize the gaze map
%norm_gaze_map = gaze_map - min(gaze_map(:));
%norm_gaze_map = norm_gaze_map ./ max(norm_gaze_map(:));

num_objects = size(yolo_objects,1);
scores = zeros(num_objects);

for j=1:num_objects
    % dimensions of an object for the full image
    obj_width = yolo_objects(j).RightTopX/2 - yolo_objects(j).LeftBotX/2;
    obj_height = yolo_objects(j).LeftBotY/2 - yolo_objects(j).RightTopY/2; %25
    obj_center = [yolo_objects(j).CentroidX/2, yolo_objects(j).CentroidY/2];
    
    % downsample object dimensions to 13x13
    obj_width = ceil(obj_width * 13/im_width);
    obj_height = ceil(obj_height * 13/im_height);
    obj_center = [ceil(obj_center(1) *13/im_height), ceil(obj_center(2)*13/im_width)];
    obj_area = obj_width * obj_height;
    
    % compute score within bounding box
    for c=obj_center(1)-obj_width/2: obj_center(1)+obj_width/2
        for r=obj_center(2)-obj_height/2 : obj_center(2)+obj_height/2
            scores(j) = scores(j) + gaze_map(r,c);
        end
    end
    scores(j) = scores(j)/obj_area;
end

[~,predicted_obj] = max(scores);



