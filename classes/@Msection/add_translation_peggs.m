function [L] = add_translation_peggs(L, peg_npoints, peg_weight, valid_scope)
%%% add one really large tile that encompasses the entire box and add weak point-match peggs
%%% valid_scope = 'limited' to only include tiles that have point matches, or 'all'
if nargin<4, valid_scope = 'limited';end
n = peg_npoints; % number of fictitious points
fac = peg_weight; % weight of these points

L = get_bounding_box(L); % [xmin xmax ymin ymax];
L = update_XY(L);
t = tile;
t.id = -888;
t.H = L.tiles(1).H;%L.box(4)-L.box(3);
t.W = L.tiles(1).W;%L.box(2)-L.box(1);

[L, P, Pix, pcell, bocell] = update_XY(L, n); % generate points for each tile and "peg" onto the large tile
%[x1, y1] = get_tile_centers_tile_array(L.tiles);



%% generate new point-match entries
if strcmp(valid_scope, 'limited')
    tvalid = unique(L.pm.adj(:));
else
    tvalid = 1:numel(L.tiles);
end

if ~isempty(tvalid)
    M = cell(numel(tvalid),2);
    W = cell(numel(tvalid),1);
    adj = zeros(numel(tvalid),2);
    largetileix = numel(L.tiles) + 1;
    np = zeros(1, numel(tvalid));
    for ix = 1:numel(tvalid)  % loop over tiles that are registered as having point-matches to other tiles
        pt = pcell{tvalid(ix)};
        %         M{ix,1} = -p;
        %         M{ix,2} =  0*p;
        
        %         p = rand(peg_npoints, 2) + [x1(ix) y1(ix)];
        M{ix,1} = bocell{tvalid(ix)}(:,[1 2]);
        M{ix,2} = pt;
        %disp([M{ix,1} M{ix,2}]);
        adj(ix,:) = [tvalid(ix) largetileix];
        np(ix) = n;
        W{ix} = ones(1,n) * fac;
    end
    L.pm.M = [L.pm.M;M];
    L.pm.adj = [L.pm.adj;adj];
    L.pm.W = [L.pm.W;W];
    L.pm.np = [L.pm.np;np'];
end
L.tiles(end+1) = t;

