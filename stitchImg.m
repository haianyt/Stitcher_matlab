function [ output ] = stitchImg( images,homos )
%STITCHIMG Summary of this function goes here
%   Detailed explanation goes here
length = size(images,2);

baseIndex = floor(length/2);
baseImg = images{baseIndex};

% for i = 1:length
%     figure;
%     imshow(images{i});
% end

minX=1;
minY=1;
maxX=size(baseImg,2);
maxY=size(baseImg,1);

H=eye(3);

for i = (baseIndex+1):length
    H=inv(homos{i-1})*H;
    box1 = [1  size(images{i},2) size(images{i},2)  1 ;
        1  1           size(images{i},1)  size(images{i},1) ;
        1  1           1            1 ] ;
    
    box1_ = H * box1 ;
    box1_(1,:) = box1_(1,:) ./ box1_(3,:) ;
    box1_(1,:) = box1_(2,:) ./ box1_(3,:) ;
   
    minX=min([minX box1_(1,:)]);
    minY=min([minY box1_(2,:)]);
    maxX=max([maxX box1_(1,:)]);
    maxY=max([maxY box1_(2,:)]);
    
    
    
end

H=eye(3);
for i = (baseIndex-1):1
    H=homos{i}*H;
    box1 = [1  size(images{i},2) size(images{i},2)  1 ;
        1  1           size(images{i},1)  size(images{i},1) ;
        1  1           1            1 ] ;
    
    box1_ = H * box1 ;
    box1_(1,:) = box1_(1,:) ./ box1_(3,:) ;
    box1_(1,:) = box1_(2,:) ./ box1_(3,:) ;
   
    minX=min([minX box1_(1,:)]);
    minY=min([minY box1_(2,:)]);
    maxX=max([maxX box1_(1,:)]);
    maxY=max([maxY box1_(2,:)]);
    
    
    
end



ur = minX:maxX ;
vr = minY:maxY ;

[u,v] = meshgrid(ur,vr);
transformedImgs={};

transformedImgs{baseIndex} = vl_imwbackward(im2double(baseImg),u,v) ;



H=eye(3);
for i = (baseIndex+1):length
    H=homos{i-1}*H;
    z_ = H(3,1) * u + H(3,2) * v + H(3,3) ;
    u_ = (H(1,1) * u + H(1,2) * v + H(1,3)) ./ z_ ;
    v_ = (H(2,1) * u + H(2,2) * v + H(2,3)) ./ z_ ;
    transformedImgs{i} = vl_imwbackward(im2double(images{i}),u_,v_) ;
end

H=eye(3);
for i = (baseIndex-1):1
    H=inv(homos{i})*H;
    z_ = H(3,1) * u + H(3,2) * v + H(3,3) ;
    u_ = (H(1,1) * u + H(1,2) * v + H(1,3)) ./ z_ ;
    v_ = (H(2,1) * u + H(2,2) * v + H(2,3)) ./ z_ ;
    transformedImgs{i} = vl_imwbackward(im2double(images{i}),u_,v_) ;
end

for i = 1:length
    figure;
    imshow(transformedImgs{i});
end

% H=inv(H);
% 
% z_ = H(3,1) * u + H(3,2) * v + H(3,3) ;
% u_ = (H(1,1) * u + H(1,2) * v + H(1,3)) ./ z_ ;
% v_ = (H(2,1) * u + H(2,2) * v + H(2,3)) ./ z_ ;
% im1_ = vl_imwbackward(im2double(im1),u_,v_) ;
% 
% 
% mass = ~isnan(im1_) + ~isnan(im2_);
% im1_(isnan(im1_)) = 0 ;
% im2_(isnan(im2_)) = 0 ;
% mosaic = (im1_ + im2_) ./ mass ;
% %     figure(2) ; clf ;
% %     imagesc(mosaic) ; axis image off ;
% %     title('Mosaic') ;

end

