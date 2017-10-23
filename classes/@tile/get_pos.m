function [x, y] = get_pos(obj)
% returns the approximate center point of the tile 
% Needs application of transformation to determine center of mass

if strcmp(class(obj.tform), 'affine2d')
    x = obj.tform.T(3,1) + obj.W/2;
    y = obj.tform.T(3,2) + obj.H/2;
elseif strcmp(class(obj.tform), 'images.geotrans.PolynomialTransformation2D')
    x = obj.tform.A(1) + obj.W/2;
    y = obj.tform.B(1) + obj.H/2;
else
    warning('Could not obtain tile position');
end
