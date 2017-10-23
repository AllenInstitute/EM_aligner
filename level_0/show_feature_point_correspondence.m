function show_feature_point_correspondence(t1, t2, M)
% just displays feature points correspondence between a pair of tile 
I1 = get_image(t1);
I2 = get_image(t2);
 figure; showMatchedFeatures(I1, I2, M{1,1}, M{1,2}, 'montage');