function cm = get_center_of_mass(obj)
            cm = zeros(numel(obj.tiles),2);
            for tix = 1:numel(obj.tiles)
                cm(tix,:) = obj.tiles(tix).tform.T([3 6]);
            end
            cm = sum(cm,1)/numel(obj.tiles);