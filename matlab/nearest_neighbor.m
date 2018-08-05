function [predicted_obj, scores, idx] = nearest_neighbor(yolo_objects, default_gaze, im_size)

x_predict = default_gaze(1);
y_predict = default_gaze(2);

g = floor([x_predict y_predict].*[im_size(2) im_size(1)]); 

num_objects = size(yolo_objects,1);
if(num_objects<1)
    predicted_obj = '';
    disp('****No yolo objects detected***');
    return;
end
scores = ones(num_objects,1)*10000000;

for j=1:num_objects
    if(strcmp(yolo_objects(j).Label,'spoon') || strcmp(yolo_objects(j).Label,'plate'))
        continue;
    end
    % dimensions of an object for the full image
    obj_width = yolo_objects(j).RightTopX/2 - yolo_objects(j).LeftBotX/2;
    obj_height = yolo_objects(j).LeftBotY/2 - yolo_objects(j).RightTopY/2; %25
    obj_center = [yolo_objects(j).CentroidX/2, yolo_objects(j).CentroidY/2];
    
    % compute closest distance of predicted gaze point to object's bounding
    % box
    dist1 = pdist([g(1), g(2); double(obj_center(1)-obj_width/2), double(obj_center(2)-obj_height/2)]);
    dist2 = pdist([g(1), g(2); double(obj_center(1)-obj_width/2), double(obj_center(2)+obj_height/2)]);
    dist3 = pdist([g(1), g(2); double(obj_center(1)+obj_width/2), double(obj_center(2)-obj_height/2)]);
    dist4 = pdist([g(1), g(2); double(obj_center(1)+obj_width/2), double(obj_center(2)+obj_height/2)]);
    scores(j) = min([dist1, dist2, dist3, dist4]);
    
end
    [~,idx] = min(scores);
    predicted_obj = yolo_objects(idx).Label;
end