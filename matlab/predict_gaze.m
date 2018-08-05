function [x_predict,y_predict,hm_results,net] = predict_gaze(img,e,net)
    % Written by Adria Recasens (recasens@mit.edu)
    
    addpath(genpath('/data/vision/torralba/datasetbias/caffe-cudnn3/matlab/'));
    
    definition_file = ['deploy_demo.prototxt'];
    binary_file = ['binary_w.caffemodel'];

    s = RandStream('mt19937ar','Seed',sum(10000*clock));
    RandStream.setGlobalStream(s);
    
   filelist = cell(1,3);   
   filelist(:,1) = {img};

   alpha = 0.3;
   w_x = floor(alpha*size(img,2));
   w_y = floor(alpha*size(img,1));
   if(mod(w_x,2)==0)
        w_x = w_x +1;
   end

   if(mod(w_y,2)==0)
        w_y = w_y +1;
   end
   
   im_face = ones(w_y,w_x,3,'uint8');
   im_face(:,:,1) = 123*ones(w_y,w_x,'uint8');
   im_face(:,:,2) = 117*ones(w_y,w_x,'uint8');
   im_face(:,:,3) = 104*ones(w_y,w_x,'uint8');
   center = floor([e(1)*size(img,2) e(2)*size(img,1)]);
   d_x = floor((w_x-1)/2);
   d_y = floor((w_y-1)/2);

   bottom_x = center(1)-d_x;
   delta_b_x = 1;
   if(bottom_x<1)
        delta_b_x =2-bottom_x;
        bottom_x=1;
    end
    top_x = center(1)+d_x;
    delta_t_x = w_x;
    if(top_x>size(img,2))
         delta_t_x = w_x-(top_x-size(img,2));
         top_x = size(img,2);
    end
    bottom_y = center(2)-d_y;
    delta_b_y = 1;
    if(bottom_y<1)
        delta_b_y =2-bottom_y;
        bottom_y=1;
    end
    top_y = center(2)+d_y;
    delta_t_y = w_y;
    if(top_y>size(img,1))
         delta_t_y = w_y-(top_y-size(img,1));
         top_y = size(img,1);
    end
    
    im_face(delta_b_y:delta_t_y,delta_b_x:delta_t_x,:) = img(bottom_y:top_y,bottom_x:top_x,:);
    filelist(:,2) = {im_face};

    f = zeros(1,1,169,'single');
    z = zeros(13,13,'single');
    x = floor(e(1)*13)+1;
    y = floor(e(2)*13)+1;
    z(x,y) =1;
    f(1,1,:) = z(:);
    filelist(:,3) = {f};

    use_gpu = 1;
    device_id = 2;

    transform_data =[1 1 0];

    
    if(~exist('net','var'))
        if use_gpu
         caffe.set_mode_gpu();
         gpu_id = 0;  % we will use the first gpu in this demo
         caffe.set_device(gpu_id);
        else
          caffe.set_mode_cpu();
        end
        net = caffe.Net(definition_file, binary_file, 'test');
    end

    image_mean_cell = {'places_mean_resize.mat','imagenet_mean_resize.mat','imagenet_mean_resize.mat'};

    input_dim_all = [1 3 227 227 1 3 227 227 1 169 1 1];

    ims = cell(size(filelist,2),1);
    for j=1:3
        filelist_i = filelist(1,j);
        filelist_i = filelist_i{1};
        input_dim = input_dim_all(1+(j-1)*4:j*4);
        b = cell(1, 1);
        img_size = [input_dim(3) input_dim(4) input_dim(2)];
        image_mean = image_mean_cell{j};
             
        if(transform_data(j))
                tmp = load(image_mean);
                image_mean = tmp.image_mean;
                image_mean = imresize(image_mean, [img_size(1) img_size(2)]);
                img = zeros(size(image_mean, 1), size(image_mean, 2), 3, 'single');
                if(ischar(filelist_i))
                    try
                        img = single(imread(filelist_i));
                    catch e1
                       system(['convert ' filelist_i ' -colorspace rgb ' filelist{i}]);
                       try
                           img = single(imread(filelist_i));
                       end
                    end
                else
                        img = single(filelist_i);
                end
                if(size(img, 4)~=1), img = img(:,:,:,1); end
                img = imresize(img, [size(image_mean, 1) size(image_mean, 2)], 'bilinear');
                if(size(img, 3)==1), img = cat(3, img, img, img); end
                img = img(:, :, [3 2 1])-image_mean;
                b{1} = permute(img, [2 1 3]);

        else
                b{1} = filelist_i;
        end
         b = cat(4, b{:}); 
        ims{j} = b;   
    end
    
    f_val = net.forward(ims);

    fc_0_0 = f_val{1}';
    fc_1_0= f_val{2}';
    fc_m1_0 = f_val{3}';
    fc_0_1 = f_val{4}';
    fc_0_m1 = f_val{5}';

      hm = zeros(15,15);
      count_hm = zeros(15,15);
      f_0_0 = reshape(fc_0_0(1,:),[5 5]); f_0_0 = exp(alpha*f_0_0)/sum(exp(alpha*f_0_0(:)));
      f_1_0= reshape(fc_1_0(1,:),[5 5]);  f_1_0 = exp(alpha*f_1_0)/sum(exp(alpha*f_1_0(:)));
      f_m1_0 = reshape(fc_m1_0(1,:),[5 5]); f_m1_0 = exp(alpha*f_m1_0)/sum(exp(alpha*f_m1_0(:)));
      f_0_m1 =reshape(fc_0_m1(1,:),[5 5]);  f_0_m1 = exp(alpha*f_0_m1)/sum(exp(alpha*f_0_m1(:)));
      f_0_1 = reshape(fc_0_1(1,:),[5 5]); f_0_1 = exp(alpha*f_0_1)/sum(exp(alpha*f_0_1(:)));
      
      f_cell = {f_0_0,f_1_0,f_m1_0,f_0_m1,f_0_1};
      v_x = [0 1 -1 0 0];
      v_y = [0 0 0 -1 1];
      for k=1:5
        delta_x = v_x(k);
        delta_y = v_y(k);
        f = f_cell{k};
        for x=1:5
            for y=1:5
                i_x = 1+3*(x-1) - delta_x; i_x = max(i_x,1);
                if(x==1)
                    i_x=1;
                end
                i_y = 1+3*(y-1) - delta_y; i_y = max(i_y,1);
                if(y==1)
                    i_y =1;
                end
                f_x = 3*x-delta_x; f_x = min(15,f_x);
                if(x==5)
                    f_x = 15;
                end
                f_y = 3*y-delta_y; f_y = min(15,f_y);
                if(y==5)
                    f_y = 15;
                end
                hm(i_x:f_x,i_y:f_y) = hm(i_x:f_x,i_y:f_y)+f(x,y);
                count_hm(i_x:f_x,i_y:f_y) = count_hm(i_x:f_x,i_y:f_y)+1;
            end
        end
      end
      
      hm_base = hm./count_hm;
      hm_results = imresize(hm_base', [size(img,1) size(img,2)],'bicubic');
      [maxval,idx]=max(hm_results(:));
      [row,col]=ind2sub(size(hm_results), idx);
      y_predict = row/size(hm_results,1);
      x_predict = col/size(hm_results,2);

end





