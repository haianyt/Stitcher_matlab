%main %


dataDir = 'images/';
files = dir(strcat(dataDir, '*.JPG'));

images = readImageFromDir(files,dataDir);

length = size(images,2);



weights={};
for i = 1:length
    w=size(images{i},1);
    h=size(images{i},2);
    Xr=[1,floor(h/2),h];
    Yr=[1,floor(w/2),w];
    [X,Y] = meshgrid(Xr,Yr);
    V = [ 0 0 0 ;
          0 1 0 ;
          0 0 0 ];
      
%     V = [ 1 1 1 ;
%           1 1 1 ;
%           1 1 1 ];
    [Xq,Yq] = meshgrid(1:h,1:w);
    weight = interp2(X,Y,V,Xq,Yq);
    weight_(:,:,1)=weight;
    weight_(:,:,2)=weight;
    weight_(:,:,3)=weight;
    
    weights{i}= cylinderProjection(weight_);
    images{i} = cylinderProjection(images{i});
end

% im1 = cylinderProjection(im1);
% im2 = cylinderProjection(im2);


grayscaleImgs={};

for i = 1:length
    if size(images{i},3) > 1, grayscaleImgs{i} = rgb2gray(im2single(images{i})) ; else grayscaleImgs{i} = images{i} ; end
end

% if size(im1,3) > 1, im1g = rgb2gray(im1) ; else im1g = im1 ; end
% if size(im2,3) > 1, im2g = rgb2gray(im2) ; else im2g = im2 ; end


% --------------------------------------------------------------------
%                                                         SIFT matches
% --------------------------------------------------------------------

siftFeaturesVec={};

for i = 1:length
    [f,d] = vl_sift(grayscaleImgs{i});
    siftFeaturesVec{i} = {f,d};
end

% [f1,d1] = vl_sift(grayscaleImgs{i}) ;
% [f2,d2] = vl_sift(im2g) ;

homographys={}
for i = 1:(length-1)
    sift1 = siftFeaturesVec{i};
    sift2 = siftFeaturesVec{i+1};
    f1=sift1{1};
    f2=sift2{1};
    d1=sift1{2};
    d2=sift2{2};
    
    [matches, scores] = vl_ubcmatch(d1,d2) ;

    numMatches = size(matches,2) ;

    X1 = f1(1:2,matches(1,:)) ; X1(3,:) = 1 ;
    X2 = f2(1:2,matches(2,:)) ; X2(3,:) = 1 ;
    
    
    [H,ok] = estimateHomography(X1,X2);
    
    H = refineHomography(ok,X1,X2,H);
    homographys{i}=H;
    
end

% [matches, scores] = vl_ubcmatch(d1,d2) ;
% 
% numMatches = size(matches,2) ;
% 
% X1 = f1(1:2,matches(1,:)) ; X1(3,:) = 1 ;
% X2 = f2(1:2,matches(2,:)) ; X2(3,:) = 1 ;

% --------------------------------------------------------------------
%                                         RANSAC with homography model
% --------------------------------------------------------------------

% [H,ok] = estimateHomography(X1,X2);

% --------------------------------------------------------------------
%                                                  Optional refinement
% --------------------------------------------------------------------

% H = refineHomography(ok,X1,X2,H);

% residual = residualFact(ok,X1,X2);
% 
% 
% if exist('fminsearch') == 2
%   H = H / H(3,3) ;
%   opts = optimset('Display', 'none', 'TolFun', 1e-8, 'TolX', 1e-8) ;
%   H(1:8) = fminsearch(residual, H(1:8)', opts) ;
% else
%   warning('Refinement disabled as fminsearch was not found.') ;
% end

% --------------------------------------------------------------------
%                                                         Show matches
% --------------------------------------------------------------------

im1 = images{1};
im2 = images{2};
weight1=weights{1};
weight2=weights{2};
H = homographys{1};


dh1 = max(size(im2,1)-size(im1,1),0) ;
dh2 = max(size(im1,1)-size(im2,1),0) ;

figure(1) ; clf ;
subplot(2,1,1) ;
imagesc([padarray(im1,dh1,'post') padarray(im2,dh2,'post')]) ;   %向下添加黑色像素
o = size(im1,2) ;
line([f1(1,matches(1,:));f2(1,matches(2,:))+o], ...
     [f1(2,matches(1,:));f2(2,matches(2,:))]) ;
title(sprintf('%d tentative matches', numMatches)) ;
axis image off ;

subplot(2,1,2) ;
imagesc([padarray(im1,dh1,'post') padarray(im2,dh2,'post')]) ;
o = size(im1,2) ;
line([f1(1,matches(1,ok));f2(1,matches(2,ok))+o], ...
     [f1(2,matches(1,ok));f2(2,matches(2,ok))]) ;
title(sprintf('%d (%.2f%%) inliner matches out of %d', ...
              sum(ok), ...
              100*sum(ok)/numMatches, ...
              numMatches)) ;
axis image off ;

drawnow ;

% --------------------------------------------------------------------
%                                                               Mosaic
% --------------------------------------------------------------------

homos=homographys;




length = size(images,2);

baseIndex = floor((1+length)/2);
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
            1  1                 size(images{i},1)  size(images{i},1);
            1  1                 1                  1 ] ;
    
    box1_ = H * box1 ;
    box1_(1,:) = box1_(1,:) ./ box1_(3,:) ;
    box1_(2,:) = box1_(2,:) ./ box1_(3,:) ;
   
    minX=min([minX box1_(1,:)]);
    minY=min([minY box1_(2,:)]);
    maxX=max([maxX box1_(1,:)]);
    maxY=max([maxY box1_(2,:)]);
    
    
end

H=eye(3);
for i = (baseIndex-1):-1:1
    H=homos{i}*H;
    box1 = [1  size(images{i},2) size(images{i},2)  1 ;
        1  1           size(images{i},1)  size(images{i},1) ;
        1  1           1            1 ] ;
    
    box1_ = H * box1 ;
    box1_(1,:) = box1_(1,:) ./ box1_(3,:) ;
    box1_(2,:) = box1_(2,:) ./ box1_(3,:) ;
   
    minX=min([minX box1_(1,:)]);
    minY=min([minY box1_(2,:)]);
    maxX=max([maxX box1_(1,:)]);
    maxY=max([maxY box1_(2,:)]);
    
    
    
end



ur = minX:maxX ;
vr = minY:maxY ;

[u,v] = meshgrid(ur,vr);
transformedImgs={};
transformedWeights={};

'transform the images'

transformedImgs{baseIndex} = vl_imwbackward(im2double(baseImg),u,v) ;
transformedWeights{baseIndex}=vl_imwbackward(im2double(weights{baseIndex}),u,v);
transformedImgs{baseIndex}(isnan(transformedImgs{baseIndex})) = 0 ;
transformedWeights{baseIndex}(isnan(transformedWeights{baseIndex})) = 0 ;

H=eye(3);
for i = (baseIndex+1):length
    'transform the image'
    H=homos{i-1}*H;
    z_ = H(3,1) * u + H(3,2) * v + H(3,3) ;
    u_ = (H(1,1) * u + H(1,2) * v + H(1,3)) ./ z_ ;
    v_ = (H(2,1) * u + H(2,2) * v + H(2,3)) ./ z_ ;
    transformedImgs{i} = vl_imwbackward(im2double(images{i}),u_,v_) ;
    transformedWeights{i} = vl_imwbackward(im2double(weights{i}),u_,v_) ;
    transformedImgs{i}(isnan(transformedImgs{i})) = 0 ;
    transformedWeights{i}(isnan(transformedWeights{i})) = 0 ;
end

H=eye(3);
for i = (baseIndex-1):-1:1
    H=inv(homos{i})*H;
    z_ = H(3,1) * u + H(3,2) * v + H(3,3) ;
    u_ = (H(1,1) * u + H(1,2) * v + H(1,3)) ./ z_ ;
    v_ = (H(2,1) * u + H(2,2) * v + H(2,3)) ./ z_ ;
    transformedImgs{i} = vl_imwbackward(im2double(images{i}),u_,v_) ;
    transformedWeights{i} = vl_imwbackward(im2double(weights{i}),u_,v_) ;
    transformedImgs{i}(isnan(transformedImgs{i})) = 0 ;
    transformedWeights{i}(isnan(transformedWeights{i})) = 0 ;
   
end

% mosaic = (im1_.*weight1_+im2_.*weight2_)./(weight1_+weight2_);

result=transformedImgs{1}.*0;
weight=0;

% for i = i:length
%     result=transformedImgs{i}.*transformedWeights{i};
%     figure;
%     imshow(result);
% end

for i = 1:length
    result=result+(transformedImgs{i}.*transformedWeights{i});
    
    weight=weight+transformedWeights{i};
end

resultImg=result./weight;
% 
% 
figure;
imshow(resultImg);







% box1 = [1  size(im1,2) size(im1,2)  1 ;
%         1  1           size(im1,1)  size(im1,1) ;
%         1  1           1            1 ] ;
% box1_ = H * box1 ;
% box1_(1,:) = box1_(1,:) ./ box1_(3,:) ;
% box2_(1,:) = box1_(2,:) ./ box1_(3,:) ;
% ur = min([1 box1_(1,:)]):max([size(im2,2) box1_(1,:)]) ;
% vr = min([1 box1_(2,:)]):max([size(im2,1) box1_(2,:)]) ;
% 
% [u,v] = meshgrid(ur,vr);
% im2_ = vl_imwbackward(im2double(im2),u,v) ;
% weight2_=vl_imwbackward(weight2,u,v);
% 
% H=inv(H);
% 
% z_ = H(3,1) * u + H(3,2) * v + H(3,3) ;
% u_ = (H(1,1) * u + H(1,2) * v + H(1,3)) ./ z_ ;
% v_ = (H(2,1) * u + H(2,2) * v + H(2,3)) ./ z_ ;
% im1_ = vl_imwbackward(im2double(im1),u_,v_) ;
% weight1_ = vl_imwbackward(weight1,u_,v_);
% 
% % mass = ~isnan(im1_) + ~isnan(im2_);
% weight1_(isnan(im1_)) = 0 ;
% weight2_(isnan(im2_)) = 0 ;
% im1_(isnan(im1_)) = 0 ;
% im2_(isnan(im2_)) = 0 ;
% 
% 
% mosaic = (im1_.*weight1_+im2_.*weight2_)./(weight1_+weight2_);
% % mosaic = (im1_ + im2_) ./ mass ;
% figure(2) ; clf ;
% imagesc(mosaic) ; axis image off ;
% title('Mosaic') ;


