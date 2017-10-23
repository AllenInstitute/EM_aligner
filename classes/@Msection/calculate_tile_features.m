function obj = calculate_tile_features(obj, filter, force, scale)
% generate features for all tiles in Msection obj
% force = 1: calcualtes features even if the features have already been
% calculated before. Replaces old feature set. default = 0;
% filter can be 'bkgrd1', 'bkgrd2', 'bkgrd3', 'histeq', or 'none' (default), or any
% other filter applicable by tile.get_image

if nargin<2, filter = 'true';end
if nargin<3, force  = 0;end
if nargin<4, scale = 1.0;end
disp('Calculating image features using parfor...');
tiles = tile;
tiles = obj.tiles;
%parfor_progress(numel(mL2_tiles));
ntiles = numel(tiles);
parfor ix = 1:ntiles
    %disp(['Calculating feature set: ' num2str(ix) ' of ' num2str(ntiles)]);
    %disp(ix);
    if isempty(tiles(ix).features) || force
         t = get_features(tiles(ix), filter, scale);
        % reduce feature set (and point set) if too many
        if size(t.features,1)>tiles(ix).SURF_MaxFeatures
            indx = randi(size(t.features,1), tiles(ix).SURF_MaxFeatures,1);
            t.features(indx,:)=[];
            t.validPoints(indx) = [];
        end
        tiles(ix) = t;
    end
 %   parfor_progress;
end
%parfor_progress(0);
disp('Done!');
obj.tiles = tiles;