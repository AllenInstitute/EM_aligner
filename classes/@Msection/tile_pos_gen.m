function obj = tile_pos_gen(obj)
% generate the arrays X and Y that contain the tile positions
for ix = 1:numel(obj.tiles)
    [ax ay] = get_pos(obj.tiles(ix));
    obj.X(ix) = ax;
    obj.Y(ix) = ay;
end
obj.X = obj.X(:);
obj.Y = obj.Y(:);