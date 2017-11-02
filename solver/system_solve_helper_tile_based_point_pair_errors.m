function [tile_err, rms, delix] = system_solve_helper_tile_based_point_pair_errors(pm, res, ntiles, flag)
% returns average point-pair error per tile.
% Input:
%    pm: point-match struct
%    res: a vector of residuals 
%   
% flag: when 1 (default), will not consider connections with less than 0.5 weight average
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<4, flag = 1;end
tpr = cell(ntiles,1);

% initialize
for ix = 1:ntiles
    tpr{ix} = [];
end


% aggregate absolute point-pair error for each tile
count = 1;
for ix = 1:size(pm.M,1)
    indx1 = pm.adj(ix,1);
    indx2 = pm.adj(ix,2);
    W = sum(pm.W{ix})/pm.np(ix);
    if flag,
        if W<0.5, 
            W = 0;
        end
    end
    
    vecu = count:count+pm.np(ix)-1;
    vecv = count+pm.np(ix):count+2*pm.np(ix)-1;
    rx = sum((res(vecu)),1)/pm.np(ix);
    ry = sum((res(vecv)),1)/pm.np(ix);
    dr = sqrt(rx.*rx + ry.*ry);
    
    tpr{indx1} = [tpr{indx1};rx ry dr W];
    tpr{indx2} = [tpr{indx2};rx ry dr W];
    

    
    count = count + 2*pm.np(ix);
end

% average the error
delix = zeros(ntiles,1, 'logical');
tile_err = zeros(ntiles,2);
rms = zeros(ntiles,1);
parfor ix = 1:ntiles
    if isempty(tpr{ix})
        tile_err(ix,:) = [-999 -999];%full(sum(tpr{ix},1)/size(tpr{ix},1));
        rms(ix) = -999;
        delix(ix) = 1;
    else
        n = size(tpr{ix},1);
        tile_err(ix,:) = full(sum(tpr{ix}(:,1:2),1)/n);
        n = double(W>0);
        rms(ix) = sqrt(full(sum(tpr{ix}(:,3).*tpr{ix}(:,3).*tpr{ix}(:,4)))/n);
    end
end
tile_err(delix,:) = [];
rms(delix) = [];
