function [obj, A, S, indx, delIds] = filter_based_on_tile_area_threshold(obj, da, center)
% deletes spurious tiles (highly deformed)  based on
% deviation from tile area and perimeter ratio from expected.
% This is a heuristic, since highly deformed tiles tend to be long and thin
% perimeter is a better indicator than surface area in some cases.
%
%
% Author: Khaled Khairy. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<2
    da = 0.05;
end
if nargin<3
    center = 1.0;  % expected area ratio (determinant of affine)
end


%disp(['filtering outliers based on deviation from 1.0 using delta +- of ' num2str(da)]);
A = [];
S = [];
obj.update_tile_info_switch = -1;
obj = update_tile_info(obj);		% we don't need adjacency information in this file, but make sure tile info is up to date
Ao = obj.tiles(1).W*obj.tiles(1).H;
So = obj.tiles(1).W * 2 + obj.tiles(1).H * 2;
% assuming all tiles have the same transformation model
if strcmp(class(obj.tiles(1).tform), 'affine2d')
    affine = 1;
else 
    affine = 0;
end



tiles = obj.tiles;
map_display_fac = obj.map_display_fac;

%%% determine polygonal areas
parfor ix = 1:numel(tiles)
    if affine
        x = tiles(ix).tform.T(3,1);
        y = tiles(ix).tform.T(3,2);
    else
        x = 0;
        y = 0;
    end
    Px = [x; x + tiles(ix).W/map_display_fac; x + tiles(ix).W/map_display_fac; x];
    Py = [y; y; y + tiles(ix).H/map_display_fac; y+tiles(ix).H/map_display_fac];
    
    %%% transform the points
    if strcmp(class(tiles(ix).tform), 'affine2d')
        P = [Px(:) Py(:) [1 1 1 1]']*tiles(ix).tform.T;
    else
        P = transformPointsInverse(tiles(ix).tform,[Px Py]);
    end
    d(ix) = det(tiles(ix).tform.T);
    % check polygon area
    A(ix) = polyarea(P(:,1), P(:,2))/Ao;
    % add polygonperimeter
    s = 0;
    s = s + sqrt((P(1,1)-P(2,1)).^2 + (P(1,2)-P(2,2)).^2);
    s = s + sqrt((P(2,1)-P(3,1)).^2 + (P(2,2)-P(3,2)).^2);
    s = s + sqrt((P(3,1)-P(4,1)).^2 + (P(3,2)-P(4,2)).^2);
    s = s + sqrt((P(1,1)-P(4,1)).^2 + (P(1,2)-P(4,2)).^2);
    S(ix) = s/So;
    % translation
    %trans(ix,:) =[x y]; 
end

% indx = find(abs(1-A)>da);
% indx = [indx find(abs(1-S)>da)];


indx = find(abs(center-d)>da);
delIds = {obj.tiles(indx).renderer_id};
obj.tiles(indx) =[];





























