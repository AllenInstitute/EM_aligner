function obj = rotate(obj, x, y, deg)
%% rotate Msection object around x, y by angle deg

for tix = 1:numel(obj.tiles)
    obj.tiles(tix) = rotate(obj.tiles(tix), x, y, deg);
end
%obj = get_bounding_box(obj);