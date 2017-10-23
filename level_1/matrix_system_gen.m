function [K, Lm, tId, T, To, sectionId, z] = matrix_system_gen(nfirst, nlast, ...
                                            rc, pm, nbr, min_points, xs_weight, stvec, tdim, lambda)
% UNDER CONSRUCTION
% Input: nfirst and nlast are zvalue of sections in rc
%        rc and pm are structs with specifications for accessing
%        collections of tile-specs and point-matches (that are related)
%        see exmple below.
%        (optional)
%        nbr: number of neighboring sections to consider
%        min_points: minimum number of points between two tiles
%        xs_weight: weight factor for cross-section point matches
%        stvec : 1 if using rc for regularization
%        tdim :  4: irigind, 6: affine
%        lambda : regularization parameter
% Output: sparse matrix K and vector Lm
%
% requires a starting value for section zvalues (nfirst) and the zvalue of
% the last section (nlast). nfirst and nlast can be the same value
% First a sectionID list is created in the order of zvalues (most of those
% are already ordered, but we need to be sure). This is why we need rc.
% Second all point matches within the sections and across sections will be
% downloaded from the pm database.
%
% % Example input:
% % rc.stack = 'v12_align';
% % rc.owner='flyTEM';
% % rc.project='FAFB00';
% % rc.server='http://tem-services.int.janelia.org:8080/render-ws/v1';
% %
% % pm.server = 'http://tem-services.int.janelia.org:8080/render-ws/v1';
% % pm.owner  = 'flyTEM';
% % pm.match_collection = 'v12_dmesh';
% % nbr = 3;
% % min_points = 5;
% % xs_weight = 1;
%
% Author: Khaled Khairy. Janelia Research Campus 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<5, nbr = 4;end  % number of neighbors to check
if nargin<6, min_points = 0;end
if nargin<7, xs_weight = 1;end
if nargin<8, stvec = 1;end
%% get the list of zvalues and section ids within the z range between nfirst and nlast (inclusive)
[zu, sID, sectionId] = get_section_ids(rc, nfirst, nlast);
%% get a list of tile ids and transform parameters (only needed if stvec == 1)
nTo = 5000 * numel(zu);
if stvec == 1
    To = zeros(nTo, tdim);
    toids = cell(nTo,1);
    options = weboptions;
    options.Timeout = 20;
    count = 1;
    for ix = 1:numel(zu)   % loop over unique z values
        urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%d/last-tile-transforms', ...
            rc.baseURL, rc.owner, rc.project, rc.stack, zu(ix));
        jt = webread(urlChar);
        for jix = 1:numel(jt)  % loop over tiles found to populate To;
            toids{count} = jt(jix).tileId;
            To(count,:) = str2double(strsplit(jt(jix).lastTransform.dataString));
            count = count + 1;
        end
    end
end
toids(count:end) = [];
To(count:end,:) = [];
%% generate matrix 
nT = 5000 * numel(zu);
T = zeros(nT, tdim);
for ix = 1:numel(ns)
    count = 1;
    % each section (montage)
    for six = 1:ns(ix)
        %disp([six count]);
        urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWithinGroup', ...
            pm.server, pm.owner, pm.match_collection, sID{ix}{six});
        try
            jj = webread(urlChar, options);
        catch err_fetch_pm
            kk_disp_err(err_fetch_pm)
            pause(1);
            jj = webread(urlChar,options); % try again
        end
        
        for jix = 1:numel(jj)
            disp([num2str(six) '_' num2str(jix) ' ' jj(jix).pGroupId ' ' jj(jix).qGroupId ' ' jj(jix).pId ' ' jj(jix).qId]);
        end

    end
end


% %% obtain cross-section point-matches
% xPM = {};
% n   = {};
% for pmix = 1:nbr
%     [xPM{pmix}, n{pmix}] = get_cross_section_pm(pmix+1, pm, sID, map_id, min_points, xs_weight);%% get point matches to immediate neighbor
% end
% 
% %% insert point-matches to generate final M, adj, W and np
% M   = [];
% adj = [];
% W   = [];
% np = [];
% for ix = 1:numel(zu)   % loop over sections
%     %disp(ix);
%     M = [M;PM(ix).M];
%     adj = [adj;PM(ix).adj];
%     W   = [W;PM(ix).W];
%     np   = [np;PM(ix).np(:)];
%     for nix = 1:nbr   % loop over neighboring sections
%         %disp([ix nix]);
%         if  ~(numel(xPM{nix})==1 && isempty(xPM{nix}.M))
%             if numel(xPM{nix})>=ix
%                 if ~isempty(xPM{nix}(ix).M)
%                     M = [M;xPM{nix}(ix).M];
%                     adj = [adj;xPM{nix}(ix).adj];
%                     W = [W;xPM{nix}(ix).W];
%                     np = [np;xPM{nix}(ix).np(:)];
%                 end
%             end
%         end
%     end
% end
% 
% %% place point match information into Msection object L
% L.pm.M = M;
% L.pm.adj = adj;
% L.pm.W = W;
% L.pm.np = np;
% 
% %% %%%%%%%%%%%%%%%%%%%%%%%%% diagnostics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % section adjacency point-match count matrix
% pm_mx = diag(n1);
% for nbrix = 1:nbr
%     if ~isempty(n{nbrix})
%         if ~(sum(n{nbrix}(:,1))==0),
%             pm_mx = pm_mx + diag(n{nbrix}(:,1),nbrix);
%         end
%     end
% end
% 
% %% %%%%%%%%%%%%%%%%%%%%%%%%%% Check consistency %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if any(sum(pm_mx)==0), disp('Warning: defective pm connectivity matrix');end
% % L.pm.adj are unique: report error if not
% % --------- sosi: invesitgate how duplicates could arise in the first place
% [bb, indx] = unique(L.pm.adj,'rows');
% if ~(size(bb,1)==size(L.pm.adj,1))
%     error('Rows in L.pm.adj should be unique');
% end
% 
% % All renderer_id pairs must correspond to an adjacency pair: if not then report error
% L.G = graph(L.pm.adj(:,1), L.pm.adj(:,2), L.pm.np, {L.tiles(:).renderer_id});
% CC = table2cell(L.G.Edges(:,1));
% %nCC = size(CC,1);
% C = [CC{:}];
% %C = reshape(C, nCC, 2);
% C1 = C(1:2:end);
% C2 = C(2:2:end);
% clear C CC;
% Lmap_renderer_id = L.map_renderer_id;
% Lpmadj = L.pm.adj;
% indxL = zeros(numel(C1),1);
% parfor tix = 1:numel(C1)
%     %disp([num2str(tix) ' '  C1{tix} ' ' C2{tix}]);
%     r    = find(ismember(Lpmadj,[Lmap_renderer_id(C1{tix}) Lmap_renderer_id(C2{tix})],'rows'));
%     if isempty(r)
%         indxL(tix) = 0;
%     else
%         indxL(tix) = r;
%     end
% end
% 
% indxL_indx = find(indxL==0);
% for tix = 1:numel(indxL_indx)
%     %disp(tix);
%     if indxL(indxL_indx(tix)) == 0
%         ind      = find(ismember(Lpmadj,[Lmap_renderer_id(C2{indxL_indx(tix)}) Lmap_renderer_id(C1{indxL_indx(tix)})],'rows'));
%         % swap the two in this case
%         temp = L.pm.adj((ind),1);
%         L.pm.adj(((ind)),1) = L.pm.adj(((ind)),2);
%         L.pm.adj(((ind)),2) = temp;
%         
%         temp = L.pm.M{((ind)),1};
%         L.pm.M{((ind)),1} = L.pm.M{((ind)),2};
%         L.pm.M{((ind)),2} = temp;
%     end
%     %     if indxL(indxL_indx(tix))==0
%     %         disp(indxL_indx(tix));
%     %         disp([C1{indxL_indx(tix)} ' ' C2{indxL_indx(tix)}]);
%     %         disp([Lmap_renderer_id(C1{indxL_indx(tix)}) Lmap_renderer_id(C2{indxL_indx(tix)})])
%     %         error('indxL should never be empty');
%     %     end
% end
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%
% function [xPM, np_vec] = get_cross_section_pm(n, pm, sID, map_id, min_points, xs_weight)
% % assumes sectionId contains sections sorted by z
% % small xs_weight means less weight for cross-layer point-match
% if nargin<6, xs_weight = 1;end
% np_vec = [];
% xPM.M = {};
% xPM.adj = [];
% xPM.W = {};
% xPM.np = [];
% options = weboptions;
% options.Timeout = 20;
% sec_ix = 1;
% if numel(sID)>=n
%     np_vec = zeros(numel(n:numel(sID)),1);
%     fac = (1/n * xs_weight);   % small fac ==> less weight for cross-layer point matches
%     
%     for ix = n:numel(sID)
%         np_vec(sec_ix) = 0;
%         count = 1;
%         for six1 = 1:numel(sID{ix})
%             for six2 = 1:numel(sID{ix-(n-1)})
%                 urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWith/%s', ...
%                     pm.server, pm.owner, pm.match_collection, sID{ix-(n-1)}{six2}, sID{ix}{six1});
%                 j = webread(urlChar, options);
%                 
%                 %         np_vec(ix-(n-1)) = numel(j);
%                 for jix = 1:numel(j)
%                     if size(j(jix).matches.p',1)>=min_points
%                         if isKey(map_id, j(jix).pId) && isKey(map_id, j(jix).qId)
%                             xPM(ix-(n-1)).M{count,1}   = j(jix).matches.p';
%                             xPM(ix-(n-1)).M{count,2}   = j(jix).matches.q';
%                             xPM(ix-(n-1)).adj(count,:) = [map_id(j(jix).pId) map_id(j(jix).qId)];
%                             xPM(ix-(n-1)).W{count,1}   = fac * j(jix).matches.w';         % relative weights of point matches within this group
%                             xPM(ix-(n-1)).np(count)  = size(j(jix).matches.p',1);    %  we are recording the number of point matches between those two tiles
%                             count = count + 1;
%                             np_vec(sec_ix) = np_vec(sec_ix) +  1;
%                             
%                         end
%                     end
%                 end
%                 %pause(0.2);
%             end
%         end
%         sec_ix = sec_ix + 1;
%     end
% end










































