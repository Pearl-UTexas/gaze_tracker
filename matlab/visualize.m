function [fused_heatmap] = visualize(im, heatmap)

figure(1);
colormap('jet');
imagesc(heatmap);
set(gca,'YDir','normal')
set(gca,'XTick',[]); % Remove the ticks in the x axis!
set(gca,'YTick',[]); % Remove the ticks in the y axis
set(gca,'Position',[0 0 1 1]); % Make the axes occupy the hole figure
heatmap_img = getframe(gcf);
heatmap_r = imresize(heatmap_img.cdata, [size(im,1), size(im,2)], 'bicubic');
fused_heatmap = imfuse(rgb2gray(im),heatmap_r,'blend');