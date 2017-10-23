function [netix] = get_edge_tiles(obj)
% assumes that update_adjacency has been called prior to this.
% returns a logical vector with ones for edge tiles
%
% Author: Khaled Khairy. Janelia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

etix = zeros(numel(obj.tiles),1);


Pvec = cell(numel(obj.tiles),1);
tiles = obj.tiles;
map_display_fac = obj.map_display_fac;

parfor ix = 1:numel(obj.tiles)
    if tiles(ix).state == 1,
        x = 0;
        y = 0;
        Px = [x; x + tiles(ix).W/map_display_fac; x + tiles(ix).W/map_display_fac; x];
        Py = [y; y; y + tiles(ix).H/map_display_fac; y+tiles(ix).H/map_display_fac];
        %%% transform the points and then plot the patch
        if strcmp(class(tiles(ix).tform), 'affine2d')
            P = [Px(:) Py(:) [1 1 1 1]']*tiles(ix).tform.T;
        else
            P = transformPointsInverse(tiles(ix).tform,[Px Py]);
        end
        Pvec(ix) = {P};
    end
end


%%%% loop over all tile polygons and record those for which at least some
%%%% points on its periphery do not lie within any of its neighbors

netix = etix;
%tiles = obj.tiles;
if isempty(obj.A)
    obj = update_adjacency(obj);
end
A = obj.A;
parfor tix = 1:numel(obj.tiles)
    if tiles(tix).state == 1,
        if etix(tix)==0, % then we have a tile with more than three neighbors
            neighbor_vec = find(A(tix,:)==1); % indices of the neighbors
            neighbor_vec = [neighbor_vec find(A(:,tix)==1)']; % indices of the neighbors
            neighbor_vec([tiles(neighbor_vec).state]<1) = [];  % remove neighbors that don't matter
            P = Pvec{tix}; % those are the corner points
            P = P(:,1:2);
            p12 = [(P(1,1)+P(2,1))/2 (P(1,2)+P(2,2))/2];
            p23 = [(P(2,1)+P(3,1))/2 (P(2,2)+P(3,2))/2];
            p34 = [(P(3,1)+P(4,1))/2 (P(3,2)+P(3,2))/2];
            p41 = [(P(4,1)+P(1,1))/2 (P(4,2)+P(1,2))/2];
            test_points = [P;p12;p23;p34;p41];               % tile points to be tested for
            in = zeros(size(test_points,1),1);
            %%
            for nix = 1:numel(neighbor_vec)  % loop over neighbors
                    Pn = Pvec{neighbor_vec(nix)};   % the neighbor polygon points
                    Pn = Pn(:,1:2);
                    for pix = 1:size(test_points,1)  % loop over candidate points
%                         disp([tix nix pix]);
                        p = test_points(pix,:);
                        if inpolygon(p(1),p(2), Pn(:,1), Pn(:,2)),
                            in(pix) = 1;
                        end
                    end
            end
            if any(in==0),
                netix(tix)=1;
            else
                netix(tix) = 0;
            end
        end
    end
end


































