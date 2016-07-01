function images = readImageFromDir( files, dataDir )
%READIMAGEFROMDIR Summary of this function goes here
%   Detailed explanation goes here

    len = length(files);

    images={}
    for i = 1 : len
        
        im = imread(strcat(dataDir, files(i).name));
        
        [a,b,c] = size(im);
        
        images{i} = imresize(im,[round(a/4),round(b/4)]);
        
    end



end

