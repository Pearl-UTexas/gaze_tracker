 % Demo script to use the gaze following model
 % Written by Adria Recasens (recasens@mit.edu)
 addpath(genpath('/home/asaran/caffe/matlab/'))
 addpath(genpath('/data/vision/torralba/datasetbias/caffe-cudnn3/matlab/'));
 %faceDetector = vision.CascadeObjectDetector;
 max_sal = [];
  
 im = imread('boy.jpg');
 %Plug here your favorite head detector
 e = [157/size(im,2)  117/size(im,1)];
     
 % Get own saliency map [13x13]
 disp(size(im));
 sal_full = zeros(size(im,1),size(im,2),'single');
 radius = 25; %25
 center = [131, 240]; %x,y
 for x=center(1)-radius:center(1)+radius
	for y=center(2)-radius:center(2)+radius
	    x_mod = x-center(1);
        y_mod = y-center(2);
        exp(-1*( x_mod*x_mod + y_mod*y_mod)/(2*625/3))
	    sal_full(y,x) = exp(-1*( x_mod*x_mod + y_mod*y_mod)/(2*625/3)); %2*5/3
    end
 end
 
 sal = zeros(13,13,1,1,'single');
 sal(:,:,1,1) = imresize(sal_full,[13,13],'bicubic');
 sal = 10*sal;
 sal_rot = rot90(sal,3); 
 
 % Compute Gaze 
 [x_predict,y_predict,heatmap,net,ims] = predict_gaze_own(im,e,sal_rot);

 %Visualization
 g = floor([x_predict y_predict].*[size(im,2) size(im,1)]);
 line = [e(1) e(2) g(1) g(2)];
 %  im = insertShape(im,'line',line,'Color','red','LineWidth',8);    
 
 gaze_mask = net.blobs('importance_map').get_data();
 gaze_mask = imresize(gaze_mask, [227,227], 'bicubic');
 gaze_mask = rot90(gaze_mask);
 %HeatMap(gaze_mask)
 
 figure;
 colormap('jet');
 imagesc(gaze_mask);
 set(gca,'YDir','normal')
 set(gca,'XTick',[]); % Remove the ticks in the x axis!
 set(gca,'YTick',[]); % Remove the ticks in the y axis
 set(gca,'Position',[0 0 1 1]); % Make the axes occupy the hole figure
 gaze_mask_img = getframe(gcf);
 imwrite(gaze_mask_img.cdata, 'boy_gaze_imagesc_own.jpg')

 % Fusing saliency heatmap with image
 gaze_mask_fig_r = imresize(gaze_mask_img.cdata, [size(im,1), size(im,2)], 'bicubic');
 fused_gaze_mask = imfuse(rgb2gray(im),gaze_mask_fig_r,'blend');
 imwrite(fused_gaze_mask, 'boy_fused_gaze_mask_own.jpg');
 close all;
 
 
 

 %sal_mask = net.blobs('conv5_red').get_data();
 sal_mask = sal_rot;
 %save('sal_map.mat','sal_map');
 sal_mask = imresize(sal_mask, [227,227], 'bicubic');
 sal_mask = rot90(sal_mask);
 %max_sal_val = max(max(sal_map));
 %max_sal = [max_sal max_sal_val]; 

 figure;
 colormap('jet');
 imagesc(sal_mask);
 set(gca,'YDir','normal')
 set(gca,'XTick',[]); % Remove the ticks in the x axis!
 set(gca,'YTick',[]); % Remove the ticks in the y axis
 set(gca,'Position',[0 0 1 1]); % Make the axes occupy the hole figure
 sal_mask_img = getframe(gcf);
 imwrite(sal_mask_img.cdata, 'boy_sal_imagesc_own.jpg')

 % Fusing saliency heatmap with image
 sal_mask_fig_r = imresize(sal_mask_img.cdata, [size(im,1), size(im,2)], 'bicubic');
 fused_sal_mask = imfuse(rgb2gray(im),sal_mask_fig_r,'blend');
 imwrite(fused_sal_mask, 'boy_fused_sal_mask_own.jpg');
 close all;

 % Combined heatmap
 fc7_mask = net.blobs('fc_7').get_data();
 fc7_mask = imresize(fc7_mask, [227,227], 'bicubic');
 fc7_mask = rot90(fc7_mask);
 
 % Visualize combined heatmap
 figure;
 colormap('jet');
 imagesc(fc7_mask);
 set(gca,'YDir','normal')
 set(gca,'XTick',[]); % Remove the ticks in the x axis!
 set(gca,'YTick',[]); % Remove the ticks in the y axis
 set(gca,'Position',[0 0 1 1]); % Make the axes occupy the hole figure
 fc7_mask_img = getframe(gcf);
 imwrite(fc7_mask_img.cdata, 'boy_fc7_imagesc_own.jpg')

 % Fusing combined heatmap with image
 fc7_mask_fig_r = imresize(fc7_mask_img.cdata, [size(im,1), size(im,2)], 'bicubic');
 fused_fc7_mask = imfuse(rgb2gray(im),fc7_mask_fig_r,'blend');
 imwrite(fused_fc7_mask, 'boy_fused_fc7_mask_own.jpg');
 close all;

 image(im);
 hold on;
 e = floor(e.*[size(im,2) size(im,1)]);

 plot([e(1),g(1)],[e(2),g(2)],'Color','b','LineWidth',5);
 g
 gaze_img = getframe(gcf);
 imwrite(gaze_img.cdata, 'boy_gaze_own.jpg');
 %close all;
 %end
 
 %close all;
 %disp(max_sal);
