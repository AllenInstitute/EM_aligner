function [obj, A, S] = filter_based_on_tile_area(obj, lambda)
% Marks spurious tiles (highly deformed) with a state of -3, based on
% deviation from mean of a distribution of tile perimeter.
% This is a heuristic, since highly deformed tiles tend to be long and thin
% perimeter is a better indicator than surface area.
% Input
% consider merging with detect_spurious_tiles.m
% Used by "concatenate_tiles.m"
%
%
% Author: Khaled Khairy. FlyTEM team project. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<2
    lambda = 1.0;
elseif isstruct(lambda)
    lambda = lambda.lambda;
end
%disp(['filtering outliers based on perimeter using lambda = ' num2str(lambda)]);
A = [];
S = [];
obj = update_tile_info(obj);		% we don't need adjacency information in this file, but make sure tile info is up to date

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
    % check polygon area
    A(ix) = polyarea(P(:,1), P(:,2));
    % add polygonperimeter
    s = 0;
    s = s + sqrt((P(1,1)-P(2,1)).^2 + (P(1,2)-P(2,2)).^2);
    s = s + sqrt((P(2,1)-P(3,1)).^2 + (P(2,2)-P(3,2)).^2);
    s = s + sqrt((P(3,1)-P(4,1)).^2 + (P(3,2)-P(4,2)).^2);
    s = s + sqrt((P(1,1)-P(4,1)).^2 + (P(1,2)-P(4,2)).^2);
    S(ix) = s;
    % translation
    %trans(ix,:) =[x y]; 
end

%[mu,sig] = normfit(S); % estimates mean and standard deviation

sig = std(S);
mu = median(S);


indx = [find(S<(mu-lambda*sig)) find(S>(mu+lambda*sig))];
indx = [indx find(A<(median(A)-lambda*std(A))) find(A>(median(A)+lambda*std(A)))];
for ix = 1:numel(indx)
    %disp(['Outlier tile found: ' num2str(indx(ix)) ' .... setting state to -3.']);
    
    obj.tiles(indx(ix)).state = -3;
end

