function l = reduce_to_tile_subset(L, tixs)
%%% This is already higly optimized, but can use some work on parfor's indxL calculation for speedup.
%%%Please don't modify unless you know what
%%% you're doing




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% reduce to tile subset preserving point-match and adjacency information


%disp(L);
l = Msection(L.tiles(tixs));
adj_old = L.pm.adj;
adj_new = zeros(size(adj_old));
del_ix = zeros(size(adj_new,1),1);

for tix = 1:numel(tixs)
    adj_new(adj_old==tixs(tix)) = tix;
end
del_ix(adj_new(:,1)==0) = 1;
del_ix(adj_new(:,2)==0) = 1;
pm = L.pm;
del_ix = find(del_ix);
pm.M(del_ix,:) = [];
pm.adj = adj_new;
pm.adj(del_ix,:) = [];
pm.W(del_ix) =[];
pm.np(del_ix) = [];
l.pm = pm;


% % make a new section based on the given cluster
% l = Msection(L.tiles(tixs));%% generate a section object based on the largest cluster
% % generate the pm struct based on the old one from L
% l.G = subgraph(L.G, (tixs));
% if isfield(L.pm, 'adj')
%     %% convert graph edges into linear index ids that point into l.tiles
%     CC = table2cell(l.G.Edges(:,1));
%     nCC = size(CC,1);
%     C = [CC{:}];
%     %C = reshape(C, nCC, 2);
%     C1 = C(1:2:end);
%     C2 = C(2:2:end);
%     clear M adj W;
%     lmap_renderer_id = l.map_renderer_id;
%     Lmap_renderer_id = L.map_renderer_id;
%     Lpmadj = L.pm.adj;
%     LpmM = L.pm.M;
%     LpmW = L.pm.W;
%     del_ix = zeros(numel(C1),1);
%     %%% sosi: slow
%     for tix = 1:numel(C1)
%         indxL      = find(ismember(Lpmadj,[Lmap_renderer_id(C1{tix}) Lmap_renderer_id(C2{tix})],'rows'));
%         if isempty(indxL),
%             indxL      = find(ismember(Lpmadj,[Lmap_renderer_id(C2{tix}) Lmap_renderer_id(C1{tix})],'rows'));
%         end
%         if isempty(indxL),
%             disp(tix);
%             disp([C1{tix} ' ' C2{tix}]);
%             disp([Lmap_renderer_id(C1{tix}) Lmap_renderer_id(C2{tix})])
%             error('indxL should never be empty');
%         end
%         M(tix,:)   = [LpmM(indxL,1) LpmM(indxL,2)];
%         adj(tix,:) = [lmap_renderer_id(C1{tix}) lmap_renderer_id(C2{tix})];
%         W(tix)     = LpmW(indxL);
%     end
%     
%     
%     l.pm.M   = M;
%     l.pm.adj = adj;
%     l.pm.W   = W';
% end
% obj = update_adjacency(l);



















% %%%%%%%% Requires regenration of point matches afterwards -------------------
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% delix = setdiff(1:numel(obj.tiles), tixs);
% obj.tiles = obj.tiles(tixs);
% obj = update_adjacency(obj);
% obj = update_XY(obj);
% obj = generate_hash_tables(obj);
% obj.edge_tiles = [];
% indx1 = [];
% indx2 = [];
% if isfield(obj.pm, 'adj')
% %     for ix = 1:numel(tixs)
% %         %disp(ix);
% %         i = find(obj.pm.adj(:,1)==tixs(ix));
% %         j = find(obj.pm.adj(:,2)==tixs(ix));
% %
% %
% %         deli = [];
% %         delj = [];
% %         for iix = 1:numel(i)
% %             if isempty(intersect(tixs, obj.pm.adj(i(iix),1)))
% %                 deli = [deli iix];
% %             end
% %         end
% %         for jix = 1:numel(j)
% %             if isempty(intersect(tixs, obj.pm.adj(j(jix),1)))
% %                 delj = [delj jix];
% %             end
% %         end
% %
% %
% %         i(deli) = [];
% %         j(delj) = [];
% %         indx1 =[indx1; i]; % store tile pair indices that we want to keep
% %         indx2 =[indx2; j];
% %     end
%
%
%     % which tile-pairs are affected (those will be deleted from M, adj and
%     % W
%     indx = [indx1;indx2];
%     obj.pm.M = obj.pm.M(indx,:);
%     obj.pm.adj = obj.pm.adj(indx,:);
%     if isfield(obj.pm, 'W')
%         obj.pm.W = obj.pm.W(indx);
%     end
%
%     %%% make sure that only unique adjacent pairs are used
%     [obj.pm.adj, ia, ic] = unique(obj.pm.adj, 'rows');
%     obj.pm.M = obj.pm.M(ia,:);
%     if isfield(obj.pm, 'W')
%         obj.pm.W = obj.pm.W(ia);
%     end
%     %% now make sure that tiles are referenced properly in adj;
%     a = unique(obj.pm.adj(:));
%     for ix = 1:numel(a);
%         indx = find(obj.pm.adj(:)==a(ix));
%         obj.pm.adj(indx)=ix;
%     end
% end