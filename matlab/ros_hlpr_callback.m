function [] = ros_hlpr_callback(~, message)
%disp('************');
% numObjects = size(message.Objects,1)
global centroid;
global dims;
% message.Objects(1,1).BbCenter.X
% for i=1:numObjects
%     centroid(i,:) = [message.Objects(i,1).BbCenter.X, message.Objects(i,1).BbCenter.Y];
%     dims(i,:) = [message.Objects(i,1).BbDims.X, message.Objects(i,1).BbDims.Y];
% end
% 
% for i=numObjects:size(centroid,1)
%     centroid(i,:)=[];
% end
% 
% for i=numObjects:size(dims,1)
%     dims(i,:)=[];
% end

array_size = size(message.Data,1);
numObjects = array_size/4;
obj = 0;
for i=1:4:array_size
    obj = obj + 1;
    %disp(message.Data(i));
    centroid(obj,:) = [message.Data(i)/2, message.Data(i+1)/2];
    dims(obj,:) = [message.Data(i+2)/2, message.Data(i+3)/2];
end

% empty the trailing array
% numObjects
% size(centroid,1)
% size(dims,1)
if(size(centroid,1)>numObjects)
    for i=numObjects+1:size(centroid,1)
        centroid(numObjects+1,:)=[];
    end
end
if(size(dims,1)>numObjects)
    for i=numObjects+1:size(dims,1)
        dims(numObjects+1,:)=[];
    end
end

assert(size(dims,1)==size(centroid,1));
