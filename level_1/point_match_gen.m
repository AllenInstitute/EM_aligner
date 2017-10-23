function point_match_gen(sl, tile_pair_list)

% generate point-matches based on json input provided by fn and tile_fn
% tile_fn has one variable tile_pairs, an
% array of tile objects, in which each row is a pair of tiles to be compared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pm = sl.target_point_match_collection;
point_pair_thresh = sl.min_points;
finescale = sl.SURF_options.SURF_Scale;
%% calculate point correspondences
npairs = size(tile_pair_list,1);
M = cell(npairs,2);
adj = zeros(npairs,2);
W = cell(npairs,1);
np = zeros(npairs,1);
delpix = zeros(npairs,1, 'uint32');
%count = 1;
if isdeployed
    disp('Calculating point matches in depolyed application .... ');
end
parfor_progress(npairs);
parfor pix = 1: npairs
    try
   
    t1 = tile_pair_list(pix,1);
    t2 = tile_pair_list(pix,2);
    
    t1 = get_features(t1, 'true', finescale);
    t2 = get_features(t2, 'true', finescale);
    %%% reduce feature set to maximum
    % reduce feature set (and point set) if too many
    if size(t1.features,1)>t1.SURF_MaxFeatures
        indx = randi(size(t1.features,1), t1.SURF_MaxFeatures,1);
        t1.features(indx,:)=[];
        t1.validPoints(indx) = [];
    end
    if size(t1.features,1)>t1.SURF_MaxFeatures
        indx = randi(size(t1.features,1), t1.SURF_MaxFeatures,1);
        t1.features(indx,:)=[];
        t1.validPoints(indx) = [];
    end
    
    %%%%% use features to calculate point-correspondences
    f1 = t1.features;
    f2 = t2.features;
    vp1 = t1.validPoints;
    vp2 = t2.validPoints;
    [m1, m2, ~]  = im_pair_match_features(f1, vp1, f2, vp2);
    
    %%%% scale and store
    M(pix,:) = {[m1]/finescale,[m2]/finescale};
    adj(pix,:) = [pix pix+npairs];
    W(pix) = {[ones(size(m1,1),1) * 1/(1+ abs(t1.z-t2.z))]};
    np(pix)  = size(m1,1);
    
    %%%% mark for removal point-matches that don't have enough point pairs
    if size(m1,1)<point_pair_thresh
        delpix(pix) = 1;
    end
    catch err_pm_generation
        kk_disp_err(err_pm_generation);
        delpix(pix) = 1;
    end
    parfor_progress;
end
parfor_progress(0);
disp('Done!');


if isempty(M), error('No matches found');end;
delpix = logical(delpix);

disp(['Total number of tested pairs: ' num2str(size(tile_pair_list,1))]);
disp(['Total number of point-match sets: ' num2str(size(tile_pair_list,1)-sum(delpix))]);

M(delpix,:) = [];
adj(delpix,:) = [];
W(delpix) = [];
np(delpix) = [];

%% generate cross-layer json point-match data


for mix = 1:size(M,1)
    indx1 = adj(mix,1);
    indx2 = adj(mix,2);
    tid1 = [tile_pair_list(indx1).renderer_id];
    tid2 = [tile_pair_list(indx2).renderer_id];
    
    MP{mix}.pz = tile_pair_list(indx1).sectionId;
    MP{mix}.pId= tid1;
    MP{mix}.p  = M{mix,1};
    
    MP{mix}.qz = tile_pair_list(indx2).sectionId;
    MP{mix}.qId= tid2;
    MP{mix}.q  = M{mix,2};
    
    MP{mix}.w   = W{mix};
end
js = pairs2json(MP); % generate json blob to be ingested into point-match database

%% ingest

    disp('Ingesting point matches');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% ingest js into point matches database
    %%% this needs to be done using webwrite --- sosi ---  until then <sigh> we will use curl
    fn = [sl.scratch '/temp_jsoin_out_' num2str(randi(100000)) '.json'];
    fid = fopen(fn, 'w');
    fwrite(fid,js);
    fclose(fid);
    urlChar = sprintf('%s/owner/%s/matchCollection/%s/matches/', ...
        pm.server, pm.owner, pm.match_collection);
    cmd = sprintf('curl -X PUT --connect-timeout 30 --header "Content-Type: application/json" --header "Accept: application/json" -d "@%s" "%s"',...
        fn, urlChar);
    [a, resp]= evalc('system(cmd)');
    delete(fn);
%% delete parallel pool
% if isdeployed
% if sl.verbose, disp('Deleting parallel pool');end
% delete(poolobj);
% end












