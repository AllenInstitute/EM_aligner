function [L, tIds, PM, pm_mx, sectionId, z, time_pm_load] = load_point_matches(nfirst, ...
    nlast, rc, pm, nbr, min_points, xs_weight, max_points)
% loads point-matches (montage and crosslayer) from one point-match struct or more if pm is an array
% of point-match structs. Returns Msection object with both tiles and point-matches
% arranged in a way that point-matches can directly be used to populate a system matrix A
%
% Input: nfirst and nlast are zvalue of sections in rc
%        rc and pm are structs with specifications for accessing
%        collections of tile-specs and point-matches (that are related)
%        see exmple below.
%        (optional)
%        nbr: number of neighboring sections to consider
%        min_points: minimum number of points between two tiles
%        xs_weight: weight factor for cross-section point matches
% Output: Msection object L with field pm (which is a struct with fields M, adj, W and np), and tileIds
%         M: is a cell array of size npx2, e.g. a set of point matches is given by M{1,1} for xy of
%         the first set of points and M{1,2} for xy of the matching points
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

if nargin < 5, nbr = 4; end  % number of neighbors to check
if nargin < 6, min_points = 0; end
if nargin < 7, xs_weight = 1; end
if nargin < 8, max_points = inf; end
verbose = 0;
if isfield(pm(1), 'verbose')
    verbose = pm(1).verbose;
end

% %% get the list of zvalues and section ids within the z range between nfirst and nlast (inclusive)
% urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/sectionData', ...
%     rc.baseURL, rc.owner, rc.project, rc.stack);
% js = webread(urlChar);
% sectionId = {js(:).sectionId};
% [z, ia]   = sort(([js(:).z]));
% sectionId = sectionId(ia);
%
%
% indx = find(z>=nfirst & z<=nlast);
% sectionId = sectionId(indx);% determine the sectionId list we will work with
% z         = z(indx);        % determine the zvalues (this is also the spatial order)
%
% % we need unique values, and we need to know how many sectionId's correspond to each unique z value
% % usually it is one, but sometimes we have hi/lo dose or other regions
% [zu, ia, ic] = unique(z);
% count = 1;
% sID = {};
% for zix = 1:numel(zu)
%     ns(zix) =  numel(find(ic==zix));
%     vec = {};
%     for six = 1:ns(zix)
%         vec{six} = sectionId{count};
%         sID{zix} = vec;
%         count = count + 1;
%     end
% end
[zu, sID, sectionId, z, ns] = get_section_ids(rc, nfirst, nlast);
%% get a list of all tiles for those sections
options = weboptions;
options.Timeout = 60;
clear t;
tilecount = [];
parfor ix = 1:1:numel(zu)
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%d/tile-specs', ...
        rc.baseURL, rc.owner, rc.project, rc.stack, zu(ix));
    if rc.verbose
        if rc.verbose, disp(['Read ' urlChar]); end
    end
    j = webread(urlChar, options);
    jt = tile;
    tilecount(ix) = numel(j);
    for jix = 1:numel(j)
        jt(jix) = tile(j(jix));
        jt(jix).z = zu(ix);
        
    end
    t(ix).jt = jt;
end
ntiles = sum(tilecount);
% concatenate all tile ids
tIds = cell(ntiles,1);
tiles(ntiles) = tile;
cnt = 1;
for ix = 1:numel(zu)
    tIds(cnt:cnt+tilecount(ix)-1) = {t(ix).jt.renderer_id};
    tiles(cnt:cnt+tilecount(ix)-1) = t(ix).jt;
    cnt = cnt + tilecount(ix);
end

% loop over tiles to set tile id
for ix = 1:numel(tiles)
    tiles(ix).id = ix;
    tiles(ix).owner = rc.owner;
    tiles(ix).project = rc.project;
    tiles(ix).stack = rc.stack;
end
L = Msection(tiles);
%L = update_tile_sources(L, rc);

% %%%%%%%%%%%% check consistency
% % check that all renderer_ids in L are unique (this means that all tiles are unique)
% % if not then flag which ones are not
% rids = {L.tiles(:).renderer_id};
% [un idx_last idx] = unique(rids);
% uqindx = accumarray(idx(:),(1:length(idx))',[],@(x) {sort(x)});
% for ix = 1:numel(uqindx)
%     if numel(uqindx{ix})>1,
%         id = L.tiles(uqindx{ix}(1)).renderer_id;
%         disp([num2str(numel(uqindx{ix})) ' copies of id: ' id ' found.']);
%     end
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% map renderer ids to their index position in L
clear count_vec ;
clear id_vec ;
clear tiles;
clear t;

parfor ix = 1:numel(tIds)
    count_vec(ix)= {ix};
    id_vec(ix) = tIds(ix);
end
map_id = containers.Map(id_vec, count_vec);
%%
tic_pm = tic;
%% get point matches for each section (montage)

PM.M = {};
PM.adj = [];
PM.W = {};
PM.np = [];
n1 = [];
for ix = 1:numel(ns)
    %disp(ix);
    count = 1;
    n1(ix) = 0;
    for six = 1:ns(ix)
        
        jj = get_pms_montage(pm, sID{ix}{six}, options);
        
%         urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWithinGroup', ...
%             pm.server, pm.owner, pm.match_collection, sID{ix}{six});
%         %disp(sID{ix}{six});
%         if verbose > 0
%             disp(urlChar);
%         end
%         try
%             jj = webread(urlChar, options);
%         catch err_fetch_pm
%             kk_disp_err(err_fetch_pm)
%             pause(1);
%             jj = webread(urlChar,options); % try again
%         end
        if iscell(jj)
            jj = jj{:};
        end
        n1(ix) = n1(ix) + numel(jj);
        for jix = 1:numel(jj)
            if verbose > 1
                logInfo = struct();
                logInfo.info = 'Number of point matches before filtering for min and max points';
                logInfo.pId = jj(jix).pId;
                logInfo.qId = jj(jix).qId;
                logInfo.nMatches = numel(jj(jix).matches.w);
                disp(logInfo);
            end
            pmCountIndex = count;
            if size(jj(jix).matches.p',1) >= min_points
                if isKey(map_id, jj(jix).pId) && isKey(map_id, jj(jix).qId)
                    if numel(jj(jix).matches.p(1,:)) > max_points
                        indx = randi(numel(jj(jix).matches.p(1,:))-1, max_points,1);
                        PM(ix).M{count,1}   = [jj(jix).matches.p(1:2,indx)]';
                        PM(ix).M{count,2}   = [jj(jix).matches.q(1:2,indx)]';
                        PM(ix).adj(count,:) = [map_id(jj(jix).pId) map_id(jj(jix).qId)];
                        PM(ix).W{count,1}   = jj(jix).matches.w(indx)';         % relative weights of point matches within this group
                        PM(ix).np(count)    = max_points;
                    else
                        PM(ix).M{count,1}   = [jj(jix).matches.p]';
                        PM(ix).M{count,2}   = [jj(jix).matches.q]';
                        PM(ix).adj(count,:) = [map_id(jj(jix).pId) map_id(jj(jix).qId)];
                        PM(ix).W{count,1}   = jj(jix).matches.w';         % relative weights of point matches within this group
                        PM(ix).np(count)    = size(jj(jix).matches.p',1);
                    end
                    count = count + 1;
                end
            end
            if verbose > 1
                logInfo = struct();
                logInfo.info = 'Number of point matches after filtering for min and max points';
                logInfo.pId = jj(jix).pId;
                logInfo.qId = jj(jix).qId;
                logInfo.nMatches = PM(ix).np(pmCountIndex);
                disp(logInfo);
                if verbose > 3
                    disp(table(...
                        PM(ix).M{pmCountIndex,1}(:,1), PM(ix).M{pmCountIndex,1}(:,2), ...
                        PM(ix).M{pmCountIndex,2}(:,1), PM(ix).M{pmCountIndex,2}(:,2), ...
                         'VariableNames', {'Px', 'Py', 'Qx', 'Qy'}));
                end
            end
        end
    end
    %%%% get point matches across those individual section ids
    for isix = 1:ns(ix)
        for jsix = isix+1:ns(ix)
            
            jj = get_pms_cross_layer(pm, sID{ix}{isix}, sID{ix}{jsix}, options);
            
%             urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWith/%s', ...
%                 pm.server, pm.owner, pm.match_collection, sID{ix}{isix}, sID{ix}{jsix});
%             %disp([sID{ix}{isix} ' ---- ' sID{ix}{jsix}]);
%%%             j = webread(urlChar, options);
%             try
%                 jj = webread(urlChar, options);
%             catch err_fetch_pm
%                 kk_disp_err(err_fetch_pm)
%                 pause(1);
%                 jj = webread(urlChar,options); % try again
%             end
            
            
            n1(ix) = n1(ix) + numel(jj);
            for jix = 1:numel(jj)
                if size(jj(jix).matches.p',1)>=min_points
                    if isKey(map_id, jj(jix).pId) && isKey(map_id, jj(jix).qId)
                        if numel(jj(jix).matches.p(1,:))>max_points
                            indx = randi(numel(jj(jix).matches.p(1,:))-1, max_points,1);
                            PM(ix).M{count,1}   = [jj(jix).matches.p(1:2,indx)]';
                            PM(ix).M{count,2}   = [jj(jix).matches.q(1:2,indx)]';
                            PM(ix).adj(count,:) = [map_id(jj(jix).pId) map_id(jj(jix).qId)];
                            PM(ix).W{count,1}     = jj(jix).matches.w(indx)';         % relative weights of point matches within this group
                            PM(ix).np(count)    = max_points;
                        else
                            PM(ix).M{count,1}   = [jj(jix).matches.p]';
                            PM(ix).M{count,2}   = [jj(jix).matches.q]';
                            PM(ix).adj(count,:) = [map_id(jj(jix).pId) map_id(jj(jix).qId)];
                            PM(ix).W{count,1}     = jj(jix).matches.w';         % relative weights of point matches within this group
                            PM(ix).np(count)    = size(jj(jix).matches.p',1);
                        end
                        
                        count = count + 1;
                    end
                end
            end
            
        end
    end
    
    
end


%% obtain cross-section point-matches
xPM = {};
n   = {};
if nbr > 0 && verbose > 0
    disp('Obtaining cross-layer point_matches');
end
parfor pmix = 1:nbr
    %disp('------- call to next neighbor tier ------------');
    [xPM{pmix}, n{pmix}] = get_cross_section_pm(pmix+1, ...
        pm, sID, map_id, min_points, xs_weight, max_points);%% get point matches to immediate neighbor
end
time_pm_load = toc(tic_pm);
%disp('Generating final point match struct');
%% generate final M, adj, W and np
M   = [];
adj = [];
W   = [];
np = [];
for ix = 1:numel(zu)   % loop over sections
    if verbose > 0
        disp(zu(ix));
    end
    if ~isempty(PM(ix).M)
    M = [M;PM(ix).M];
    adj = [adj;PM(ix).adj];
    W   = [W;PM(ix).W];
    np   = [np;PM(ix).np(:)];
    end
    for nix = 1:nbr   % loop over neighboring sections
        if  ~(numel(xPM{nix})==1 && isempty(xPM{nix}.M))
            if numel(xPM{nix})>=ix
                if ~isempty(xPM{nix}(ix).M)
                    %disp(['Assemble PM: ' num2str(ix) ' ' sID{ix} ' -- ' num2str(nix) ' ' sID{ix+nix}]);
                    M = [M;xPM{nix}(ix).M];
                    adj = [adj;xPM{nix}(ix).adj];
                    W = [W;xPM{nix}(ix).W];
                    np = [np;xPM{nix}(ix).np(:)];
                end
            end
        end
    end
    if verbose > 0
        disp(['Section ' num2str(zu(ix)) ' -> ' num2str(sum(np)) ' point matches']);
    end
    if verbose > 2
        logInfo = struct();
        logInfo.section = zu(ix);
        tileMatchCounts = cellfun(@numel, M, 'UniformOutput', false);
        logInfo.tileMatchCounts = table([adj(:, 1), adj(:, 2), [tileMatchCounts{:,1}]']);
        disp(logInfo);
        disp(logInfo.tileMatchCounts)
    end
end

%% place point match information into Msection object L
L.pm.M = M;
L.pm.adj = adj;
L.pm.W = W;
L.pm.np = np;
L.pm.verbose = verbose;
% %% tiles that are not connected to any other tiles must be eliminated
% adjids = {L.tiles(adj(:)).renderer_id};
%% %%%%%%%%%%%%%%%%%%%%%%%%% diagnostics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% section adjacency point-match count matrix
pm_mx = diag(n1);
for nbrix = 1:nbr
    if ~isempty(n{nbrix})
        if ~(sum(n{nbrix}(:,1))==0),
            pm_mx = pm_mx + diag(n{nbrix}(:,1),nbrix);
        end
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%% Check consistency %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if any(sum(pm_mx)==0), disp('Warning: defective pm connectivity matrix');end
% L.pm.adj are unique: report error if not
% --------- sosi: invesitgate how duplicates could arise in the first place
[bb, indx] = unique(L.pm.adj,'rows');
if ~(size(bb,1)==size(L.pm.adj,1))
    error('Rows in L.pm.adj should be unique');
end