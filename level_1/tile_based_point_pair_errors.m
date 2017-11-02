function [mL, tpr, resout, tile_err] = tile_based_point_pair_errors(mL, A, xout, j, minconf, maxconf)
%
[netix] = get_edge_tiles(mL);
% generate point-pair residual information per tile
res = A*xout;
tpr = cell(numel(mL.tiles),1);
resout = [];
% initialize
for ix = 1:numel(mL.tiles)
    tpr{ix} = [];
end


% aggregate absolute point-pair error for each tile
count = 1;
for ix = 1:size(mL.pm.M,1)
    indx1 = mL.pm.adj(ix,1);
    indx2 = mL.pm.adj(ix,2);
    if mL.tiles(indx1).state==1 && mL.tiles(indx2).state==1
        vecu = count:count+mL.pm.np(ix)-1;
        vecv = count+mL.pm.np(ix):count+2*mL.pm.np(ix)-1;
        npoints = numel(vecu);
        rx = sum(abs(res(vecu)),1)/npoints;
        ry = sum(abs(res(vecv)),1)/npoints;
        tpr{indx1} = [tpr{indx1};rx ry];
        tpr{indx2} = [tpr{indx2};rx ry];
        dr = sqrt(rx.*rx + ry.*ry);
        resout = [resout; dr(:)];
    end
    count = count + 2* mL.pm.np(ix);
end

% average the error
delix = [];
for ix = 1:numel(mL.tiles)
        if isempty(tpr{ix})
        mL.tiles(ix).confidence = [-50 -50];
        tile_err(ix,:) = [-999 -999];%full(sum(tpr{ix},1)/size(tpr{ix},1));
        delix = [delix;ix];
        elseif netix(ix)==1
            tile_err(ix,:) = [nan nan];
            delix = [delix;ix];
        else
        
        tile_err(ix,:) = full(sum(tpr{ix},1)/size(tpr{ix},1));
    mL.tiles(ix).confidence = full(sum(tpr{ix},1)/size(tpr{ix},1));
        end

end

tile_err(delix,:) = [];


%% split into z and display
%         ml = split_z(mL);
%         [obj, h, rh, A, minconf, maxconf] = show_map_confidence(ml(j), [1], minconf, maxconf);
%
