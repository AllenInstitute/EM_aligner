function tix = get_tile_index(obj, x, y)
% returns the indices of tile(s) that include the point x,y

%%% we need to find the tile index in which these coordinates lie
%%% - the strategy is to reduce the number of candidates using pdist2 and
%%% then loop over the candidates using inpolygon



%%% find candidates

% x = x(ones(size(obj.X,1),1),:);
% y = y(ones(size(obj.X,1),1),:);
invalid = 1;
%while invalid
d = pdist2([obj.X obj.Y],[x y]);    % distance between point x y and all tile positions
tix = find(d==min(d),1);
if obj.tiles(tix).state<1, 
    warning('Tile state < 1');
end
%end