function obj = get_bounding_box(obj)
% calculate bounding box for Msection (x y)
% Sets obj.box to [minx maxx miny maxy]
% 
%
% Author: Khaled Khairy. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin==1, option = 0;end
npoints = 1000;
obj = update_tile_info(obj);
warning off;
X = [];
Y = [];
% this can be done much faster.
for tix = 1:numel(obj.tiles)
    if obj.tiles(tix).state>=1
        if strcmp(class(obj.tiles(tix).tform), 'affine2d')
            %T = maketform('affine',obj.tiles(tix).tform.T);
            T =  obj.tiles(tix).tform;
        elseif strcmp(class(obj.tiles(tix).tform), 'images.geotrans.PolynomialTransformation2D')
            T = zeros(3,3);
            T(1) = obj.tiles(tix).tform.A(2);
            T(2) = obj.tiles(tix).tform.A(3);
            T(3) = obj.tiles(tix).tform.A(1);
            T(4) = obj.tiles(tix).tform.B(2);
            T(5) = obj.tiles(tix).tform.B(3);
            T(6) = obj.tiles(tix).tform.B(1);
            T(9) = 1;
%             T = maketform('affine',T);
            T = affine2d(T);
        elseif strcmp(class(obj.tiles(tix).tform), 'nonlin2d')
            [tform, T] = get_affine_approximation(obj.tiles(tix).tform);
            %T = maketform('affine',T);
            T = affine2d(T);
        else
            error('Msection.get_bounding_box: cannot recognize transform');
            
        end
%         [x, y] = tformfwd(T, rand(npoints,1) * obj.tiles(tix).W, rand(npoints,1) * obj.tiles(tix).H);
        [x, y] = transformPointsForward(T, rand(npoints,1) * obj.tiles(tix).W, rand(npoints,1) * obj.tiles(tix).H);
        X = [X x];
        Y = [Y y];
    end
end
warning on;
obj.box = [min(X(:)) max(X(:)) min(Y(:)) max(Y(:))];