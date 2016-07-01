function [ outputImg ] = cylinderProjection( inputImg )
%CYLINDERPROJECTION Summary of this function goes here
%   Detailed explanation goes here

W = size(inputImg,2);
H = size(inputImg,1);
theta = pi/4;
f = W/(2*tan(theta/2));



ur = 1:f*theta;
vr = 1:H;
[u,v] = meshgrid(ur,vr);

u_ = f*tan((u-f*atan(W/(2*f)))/f)+W/2;
v_ = (v-H/2).*sqrt((u_-W/2).^2+f.^2)/f+H/2;
outputImg = vl_imwbackward(im2double(inputImg),u_,v_) ;


end

