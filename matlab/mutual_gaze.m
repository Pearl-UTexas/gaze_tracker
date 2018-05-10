function mutual_flag = mutual_gaze()

global mutual_gaze_type;
mutual_flag = false;
     
global net;
gaze_mask_s = net.blobs('importance_map').get_data();
%gaze_mask = imresize(gaze_mask_s, [227,227], 'bicubic');
%gaze_mask = rot90(gaze_mask);
A = gaze_mask_s;
%imagesc(gaze_mask);
     
% Variance based method
if(strcmp(mutual_gaze_type,'variance'))
    variance = var(reshape(A(:,:),[],1))
    if(variance<0.009)
        mutual_flag = true;
    end
end

% Entropy based method
if(strcmp(mutual_gaze_type,'entropy'))
    ent = entropy(double(A))
    if(ent>5.5)
        mutual_flag = true;
    end
end
     
% Manhattan Distance based method
if(strcmp(mutual_gaze_type,'manhattan'))
    normA = A - min(A(:));
    norm_gaze_mask = normA ./ max(normA(:)); % *
    mutual_metric = 0;
    size(norm_gaze_mask)
    for x1=1:size(norm_gaze_mask,1)
        for y1=1:size(norm_gaze_mask,2)
            for x2=1:size(norm_gaze_mask,1)
                for y2=1:size(norm_gaze_mask,2)
                    if(x1==x2 && y1==y2)
                        continue
                    else
                        d = sqrt((y2-y1)^2+(x2-x1)^2);
                        mutual_metric = mutual_metric + norm_gaze_mask(x1,y1)*norm_gaze_mask(x2,y2)*d;
                    end
                end
            end
        end
    end
    mutual_metric = mutual_metric/(size(norm_gaze_mask,1)*size(norm_gaze_mask,2))
    if(mutual_metric>190) %190
        mutual_flag = true;
    end
end