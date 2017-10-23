function obj = rotate(obj, x, y, deg)
%% rotate the tile, around x y by deg degrees

if strcmp(class(obj.tform), 'affine2d')
    R = [cosd(deg) -sind(deg) 0; sind(deg) cosd(deg) 0; x y 1];
    Tr = obj.tform.T * R;
    Tr([3 6]) = Tr([3 6]) + [x y];
    obj.tform.T = Tr;
else
    disp('tile.rotate: Rotation only implemented for affine2d');
end