function [] = ros_kinect_callback(~, message)
disp('******');
global centroid;
global dims;

im = readImage(message); %Read ros image
im = imresize(im,0.5);

size(im)

imshow(im);
hold on;
for i=1:size(dims,1)
    width = dims(i,1); height = dims(i,2);
    %disp([centroid(1,1)-width/2, centroid(1,2)-height/2,width, height])
    rectangle('Position',[centroid(i,1)-width/2, centroid(i,2)-height/2,width, height], 'LineWidth',3, 'EdgeColor','blue');
end