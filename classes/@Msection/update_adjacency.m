function obj = update_adjacency(obj)
% update tile adjacency matrix
% Usage: obj = update_adjacency(obj)
% Assumes equal tile dimensions..... sosi
%
% Note: 
%       - depends on statistics toolbox because of pdist2
% Author: Khaled Khairy Janelia Research Campus -- 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

LARGE = 30000;
if numel(obj.tiles)<LARGE
obj.update_tile_info_switch = -1; % just use the first tile's W and H for all
%obj = update_tile_info(obj);
H = obj.tiles(1).H;
W = obj.tiles(1).W;
obj = update_XY(obj); x1 = obj.X(:); y1 = obj.Y(:);
%[x1, y1] = get_tile_centers_tile_array(obj.tiles);
a = [x1(:) y1(:)];%[obj.X(:) obj.Y(:)];

d = pdist2(a,a);        % depends on statistic toolbox  -------- Sosi: not good for large numbers of tiles

%d = pdist2plus(a,a);
dthresh = sqrt(H^2 + W^2) * obj.dthresh_factor;   % diagonal of the tile times factor
obj.A = sparse(triu(d<dthresh,1));
elseif isa(obj.G,'graph')
    obj.A = adjacency(obj.G);
else
    obj.A = [];
    %warning(['No adjacency matrix was generated -- LARGE set to ' num2str(LARGE)]);
end

function [D,T] = pdist2plus(p1,p2)
%This function returns distance matrices that are equivalent to the output
%from pdist2(p1,p2,'euclidean'), but also returns a matrix of angles that
%each point pair defines
%p1 - N x 2 matrix of x and y coordinates
%p2 - M x 2 matrix of x and y coordinates
%D  - Euclidean distance matrix between each point pair
%T  - Angle defined by each point pair in radians, counter clockwise from
%the x-axis

if size(p1,2) ~= 2 || size(p2,2) ~= 2
    error('Inputs p1 and p2 must have 2 and only 2 columns');
end

p1x = repmat(p1(:,1) ,[1,size(p2,1)]);
p1y = repmat(p1(:,2) ,[1,size(p2,1)]);
p2x = repmat(p2(:,1)',[size(p1,1),1]);
p2y = repmat(p2(:,2)',[size(p1,1),1]);

p = p1x-p2x + 1i*(p1y-p2y);
D = abs(p);
% T = angle(p);