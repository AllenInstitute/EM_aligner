function L = remove_diagonal_point_matches(L)
% for image tiles with row/col information
% removes point-matches corresponding to diagonally overlapping tiles
    del_ix = [];
    for pmix = 1:size(L.pm.M,1)
        r1 = L.tiles(L.pm.adj(pmix,1)).row;
        r2 = L.tiles(L.pm.adj(pmix,2)).row;
        c1 = L.tiles(L.pm.adj(pmix,1)).col;
        c2 = L.tiles(L.pm.adj(pmix,2)).col;
        if (abs(r1-r2)==1 && abs(c1-c2)==1)
            del_ix = [del_ix;pmix];
        end
    end
    L.pm.M(del_ix,:) = [];
    L.pm.adj(del_ix,:) = [];
    L.pm.W(del_ix) = [];
    L.pm.np(del_ix) = [];