function prediction = nearest_neighbor(yolo_objects, default_gaze)

x_predict = default_gaze(1);
y_predict = default_gaze(2);

g = floor([x_predict y_predict].*[size(im,2) size(im,1)]); 

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
    
    % compute closest distance of predicted gaze point to object's bounding
    % box
    dist1 = pdist([g(1), g(2); obj_center(1)-obj_width/2, obj_center(2)-obj_height/2]);
    dist2 = pdist([g(1), g(2); obj_center(1)-obj_width/2, obj_center(2)+obj_height/2]);
    dist3 = pdist([g(1), g(2); obj_center(1)+obj_width/2, obj_center(2)-obj_height/2]);
    dist4 = pdist([g(1), g(2); obj_center(1)+obj_width/2, obj_center(2)+obj_height/2]);
    scores(j) = min([dist1, dist2, dist3, dist4]);
end
    [~,prediction] = min(scores);
end