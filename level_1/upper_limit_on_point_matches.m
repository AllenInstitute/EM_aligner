function L = upper_limit_on_point_matches(L, up)
% for image tiles with row/col information
% removes point-matches to be lower in number per match than upper limit up
del_ix = [];
for pmix = 1:size(L.pm.M,1)
    M1 = L.pm.M{pmix,1};
    M2 = L.pm.M{pmix,2};
    W =  L.pm.W{pmix};
    if size(M1,1)>up
        rind = randi(size(M1,1),up,1);
        M1 = M1(rind,:);
        M2 = M2(rind,:);
        W = W(rind);
        L.pm.M{pmix,1} = M1;
        L.pm.M{pmix,2} = M2;
        L.pm.W{pmix} = W;
        L.pm.np(pmix) = up;
    end
end
