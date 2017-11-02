function [M, adj, W, np, discard] = system_solve_helper_load_point_matches(...
    zu, opts, pm, map_id, sID, ntiles, r, c)
% load all available point matches
% ilter them,
% and after that select points randomly to limit the size of
% point-matches block
% opts needs the following fields:
%  opts.Width (optional)
%  opts.Height (optional)
%  opts.inverse_dz (optional)
%  opts.nbrs
%  opts.min_points
%  opts.max_points
%  opts.pmopts
%  opts.filter_point_matches
% Example opts.pmopts:
% % configure point-match filter
% opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
% opts.pmopts.MaximumRandomSamples = 5000;
% opts.pmopts.DesiredConfidence = 99.9;
% opts.pmopts.PixelDistanceThreshold = 1;

% check inputs and set defaults
if nargin<7  % then we don't use row/col information
    r = [];
    c = [];
end
if ~isfield(opts,'do_cross_only'), opts.do_cross_only = false; end
if ~isfield(opts, 'outside_group'), opts.outside_group = false; end
if ~isfield(opts, 'Width')  % if not set, then assume FAFB
    opts.Width = 2160;
    opts.Height = 2560;
end
if ~isfield(opts, 'inverse_dz')
    opts.inverse_dz = 1;
end
spmd
    warning('off', 'vision:obsolete:obsoleteFunctionality');
end

if ~isfield(pm,'verbose')
    for i = 1:numel(pm)
        pm(i).verbose = 1;
    end
end
if pm(end).verbose
    disp('** STEP 2:  Load point-matches ....');
    disp(' ... predict sequence of PM requests to match sequence required for matrix A');
end

sID_all = {};
if opts.outside_group
    fac = {};
else
    fac = [];
end
ismontage = [];
count  = 1;
for ix = 1:numel(zu)   % loop over sections  -- can this be made parfor?
    %disp(['Setting up section: ' sID{ix}]);
    sID_all{count,1} = sID{ix};
    sID_all{count,2} = sID{ix};
    ismontage(count) = 1;
    if opts.outside_group 
        fac{count} = 1;
    else
        fac(count) = 1;
    end
    count = count + 1;
    if opts.outside_group
        %disp(['cross-layer: ' num2str(ix) ' ' sID{ix} ' -- ' num2str(nix) ' ' sID{ix+nix}]);
        second_index = min(ix+opts.nbrs, numel(zu));
        sID1 = sID{ix};
        if ix~=second_index
            sID_all{count,1} = sID1;
            sID_all{count,2} = sID{second_index}; %what to do about reacquires
            ismontage(count) = 0;
            z_range = ix+1:second_index;
            current_sID_range = cellfun(@(sIDs)(sIDs{:}), sID(z_range),'uniformOutput', false);
            current_keys = strcat([sID1{1} '_'], current_sID_range);
            current_values = opts.xs_weight./(z_range -ix + 1);
            fac{count} = containers.Map(current_keys,current_values);
            count = count + 1;
        end
    else
        for nix = 1:opts.nbrs
            if (ix+nix)<=numel(zu)
                %disp(['cross-layer: ' num2str(ix) ' ' sID{ix} ' -- ' num2str(nix) ' ' sID{ix+nix}]);
                sID_all{count,1} = sID{ix};
                sID_all{count,2} = sID{ix+nix};
                ismontage(count) = 0;
                if opts.inverse_dz
                    fac(count) = opts.xs_weight/(nix+1);
                else
                    fac(count) = opts.xs_weight;
                end
                count = count + 1;
            end
        end
    end
end
% clear sID
% % perform pm requests

if pm(end).verbose
    disp('Loading point-matches from point-match database ....');
end

wopts = weboptions;
wopts.Timeout = 20;

M   = {};
adj = {};
W   = {};
np = {};  % store a vector with number of points in point-matches (so we don't need to loop again later)
parfor ix = 1:size(sID_all,1)   % loop over sections
    %disp([sID_all{ix,1}{1} ' ' sID_all{ix,2}{1} ' ' num2str(ismontage(ix))]);
    % when loading point matches, load all available point
    % then filter them, and after that select points randomly to limit the size of
    % point-matches block
    if ismontage(ix)
        if opts.do_cross_only
            m = []; a = []; w = []; n = []; xnp = [];
        else
            [m, a, w, n, xnp] = load_montage_pm(pm, sID_all{ix,1}, map_id,...
                opts.min_points, inf, wopts, r, c);
        end
    else
        if opts.outside_group
            [m, a, w, n, xnp] = load_cross_section_pm(pm, sID_all{ix,1}, sID_all{ix,2}, ...
                map_id, opts.min_points, inf, wopts, fac{ix}, 0, opts.outside_group);
        else
            [m, a, w, n, xnp] = load_cross_section_pm(pm, sID_all{ix,1}, sID_all{ix,2}, ...
                map_id, opts.min_points, inf, wopts, fac(ix));
        end
    end
    
    
    %%% filter set of point-matches for this pair
    if opts.filter_point_matches
        if sum(n)
            %%% additional consistency filtering is done only on montages
            %%% that are regular (i.e. don't have re-acquires)
            if ismontage(ix) && numel(sID_all{ix,1})==1
                filter_consistency = 1;
                Width = opts.Width;
                Height = opts.Height;
            else
                filter_consistency = 0;
                Width = [];
                Height = [];
            end
            [m, w, a, n] = filter_pm_local(m, w, a, n, opts.pmopts, filter_consistency, Width, Height);
        end
    end
    % loop over point-match sets: reduce to max_points if necessary
    delix = [];
    for pmix = 1:size(m,1)    % loop over point-match sets
        pmm = m(pmix,:);
        pmm1 = pmm{1};
        if size(pmm1,1)>opts.max_points  % do we have more than opts.max_points point-matches in the set pmix
            indx = randi(size(pmm1,1)-1, opts.max_points,1);  % define random indices
            pmm2 = pmm{2};
            pmm1 = pmm1(indx,:);
            pmm2 = pmm2(indx,:);
            m(pmix,:) = {pmm1,pmm2};
            pmw = w{pmix};
            w{pmix} = pmw(indx);
            n(pmix) = length(w{pmix});
        end
        
        if size(pmm1,1)<opts.min_points % if we have insufficient points
            delix = [delix pmix];
        end
    end
    if ~isempty(delix)
        m(delix,:) = [];
        w(delix) = [];
        n(delix) = [];
        a(delix,:) = [];
    end
    
    M(ix) = {m};
    adj(ix) = {a};
    W(ix) = {w};
    np(ix) = {n};
end

if isempty(np)
    error('No point-matches found');
end
clear sID_all

if pm(end).verbose
    disp('... concatenating point matches ...');
end

% concatenate
M = vertcat(M{:});
adj = vertcat(adj{:});
W   = vertcat(W{:});
np  = [np{:}]';

%%% additionally we return the vector of disconnected tiles that
%%% might need to be discarded
discard = setdiff(1:ntiles, unique(adj(:)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [M, W, adj, np] = filter_pm_local(M, W, adj, np, opts, montage_flag, width, height)
warning off;

if nargin < 2
    opts.NumRandomSamplingsMethod = 'Desired confidence';
    opts.MaximumRandomSamples = 3000;
    opts.DesiredConfidence = 99.5;
    opts.PixelDistanceThreshold = 1;
end

verbose = 0;

%% filter point matches using RANSAC
%warning('off', 'vision:obsolete:obsoleteFunctionality');
geoTransformEst = vision.GeometricTransformEstimator; % defaults to RANSAC
geoTransformEst.Method = 'Random Sample Consensus (RANSAC)';%'Least Median of Squares';%'Random Sample Consensus (RANSAC)'; %
geoTransformEst.Transform = 'Nonreflective similarity';%'Affine'; % Valid values: 'Affine',
geoTransformEst.NumRandomSamplingsMethod = opts.NumRandomSamplingsMethod;% 'Desired confidence';
geoTransformEst.MaximumRandomSamples = opts.MaximumRandomSamples;%3000;
geoTransformEst.DesiredConfidence = opts.DesiredConfidence; %99.5;
geoTransformEst.PixelDistanceThreshold = opts.PixelDistanceThreshold; %0.01;


% M = pm.M;
% W = pm.W;
% adj = pm.adj;
% np  = pm.np;
del_ix = zeros(size(M,1),1);
parfor pmix = 1:size(M, 1)
    %warning('off', 'vision:obsolete:obsoleteFunctionality');
    m = M(pmix,:);
    if size(m{1},1)<2   % less than two points is useless
        del_ix(pmix) = pmix;
    else
        m1 = m{1};
        m2 = m{2};
        [tform_matrix, inlierIdx] = step(geoTransformEst, m{2}, m{1});
        m1 = m1(inlierIdx,:);
        m2 = m2(inlierIdx,:);
        M(pmix,:) = {m1,m2};
        w = W{pmix};
        if verbose > 1
            if sum(inlierIdx) < numel(inlierIdx)
                disp(['Eliminated: ' num2str(sum(~(inlierIdx))) ' points between ' mat2str(adj(pmix, :)) ' - remaining ' num2str(sum(inlierIdx))]);
            end
        end
        if sum(inlierIdx) == 0
            if verbose > 1
                disp(['Marked for deletion the link between ' mat2str(adj(pmix, :))])
            end
            del_ix(pmix) = pmix;
        end
        W{pmix} = w(inlierIdx);
        np(pmix) = length(W{pmix});
    end
end
del_ix(del_ix==0) = [];
M(del_ix,:) = [];
W(del_ix) = [];
adj(del_ix,:) = [];
np(del_ix) = [];

if montage_flag  % additional filterig for montages is required/can be done
    [M, W, adj, np] = filter_pm_consistency(M, W, adj, np, 8, width, height);
end
function [M, W, adj, np] = filter_pm_consistency(M, W, adj, np, thresh, w, h)
% for regular montages we need additionally to filter out point-match sets that
% are not consistent in their x y values
res = zeros(size(M,1), 2);
if ~isempty(w) && w>0
filter_by_bounds = 1;
else
    filter_by_bounds = 0;
end
delix = [];
f = 3.5;  % larger values mean narrower permissive region
for pix = 1:size(M,1)
    m1 = M{pix,1};
    m2 = M{pix,2};
    dx = [m1(:,1)-m2(:,1)];
    dy = [m1(:,2)-m2(:,2)];
    res(pix,:) = [std(dx) std(dy)];  % std should be small for high quality point-match sets
    
    if filter_by_bounds
        % further filter point-match sets that are obviously out of acceptable bounds
        % [1] point-matches are not allowed within a central rectangle: ratio f of the dimension
        if any( m1(:,1)<(w-w/f) & m1(:,1)>(w/f) & m1(:,2)<(h-h/f) & m1(:,2)>(h/f))
            delix = [delix; pix];
%           disp(['Deleting pair: ' num2str(pix) ' Point-match set self-consistent, but outside bounds.']);
        end
%         disp(['Section: ' num2str(L.z) ' -- Removing ' num2str(numel(delix)) ' point-match sets outside bounds']);
    end
    
end
delix = [delix; find(res(:,2)>thresh)];
delix = [delix; find(res(:,1)>thresh)];
delix = unique(delix(:));
M(delix,:) = [];
adj(delix,:) = [];
W(delix) = [];
np(delix) = [];
