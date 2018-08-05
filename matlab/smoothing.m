function [avg_g, output_list] = smoothing(g, output_list)

% Smoothing outputs in a video over frames
global window_size;

% Shrink gaze window every frame
output_list =  [output_list; g];

if size(output_list,1) > window_size + 1 % 0 && nframes>smoothing_win
    output_list = output_list(end-window_size:end,:);
end  

%disp(size(output_list,1));
w = gausswin((window_size+1)*2-1);
w = w(1:window_size+1);
w = w/sum(w);
     

avg_g = [0,0];
win_len = size(output_list,1);
if win_len<window_size+1
    s = sum(output_list,1);
    avg_g(1) = s(1)/win_len;
    avg_g(2) = s(2)/win_len;
else
    for i=1:window_size+1
        avg_g(1) = avg_g(1) + output_list(i,1)*w(i);
        avg_g(2) = avg_g(2) + output_list(i,2)*w(i);
    end
end
     