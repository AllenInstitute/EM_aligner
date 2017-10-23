function point_match_gen_pairs_SURF(config_fn, tile_fn)
% Intended for deployment:
% generate point-matches based on json input provided by fn and tile_fn
% tile_fn has one variable tile_pairs, an
% array of tile objects, in which each row is a pair of tiles to be compared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% read json input
sl = loadjson(fileread(config_fn));

if sl.verbose,
    disp('----------  Point-match generation process started');
    kk_clock();
    disp(['------- Using input file: ' config_fn]);
    disp('-------  Using SURF options:');disp(sl.SURF_options);
    disp('-------  Using source collection:');disp(sl.source_collection);
    disp('-------  Using target point-match collection:');disp(sl.target_point_match_collection);
end

load(tile_fn, 'tile_pairs');
tile_pair_list = tile;
tile_pair_list = tile_pairs;
point_pair_thresh = sl.min_points;
finescale = sl.SURF_options.SURF_Scale;

%%%%%%% start parallel pool
% if isdeployed
%  delete(gcp('nocreate'));
%  if sl.verbose, disp('Starting parallel pool');end
% % 
% %       defaultProfile = parallel.defaultClusterProfile;
% %       myCluster = parcluster(defaultProfile);
% %       parpool(myCluster);
%        parpool(8);
%        poolobj = gcp('nocreate');
%  if sl.verbose, disp(['Parallel pool created. Pool size: ' num2str(poolobj.NumWorkers)]);end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% end
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
tic
% below for loop is ready for parfor -- figure out how to do this in deployed mode
for pix = 1: npairs
    try
    if sl.verbose,
        disp(['Point matching: ' num2str(pix) ' of ' num2str(npairs)]);
    end
    
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
    end
end
toc
disp('Done!');


if isempty(M), error('No matches found');end;
delpix = logical(delpix);
if sl.verbose
disp(['Total number of tested pairs: ' num2str(size(tile_pair_list,1))]);
disp(['Total number of point-match sets: ' num2str(size(tile_pair_list,1)-sum(delpix))]);
end
M(delpix,:) = [];
adj(delpix,:) = [];
W(delpix) = [];
np(delpix) = [];

%% generate cross-layer json point-match data

counter = 1;
for mix = 1:size(M,1)
    indx1 = adj(mix,1);
    indx2 = adj(mix,2);
    tid1 = [tile_pair_list(indx1).renderer_id];
    tid2 = [tile_pair_list(indx2).renderer_id];
    
    MP{counter}.pz = tile_pair_list(indx1).sectionId;
    MP{counter}.pId= tid1;
    MP{counter}.p  = M{mix,1};
    
    MP{counter}.qz = tile_pair_list(indx2).sectionId;
    MP{counter}.qId= tid2;
    MP{counter}.q  = M{mix,2};
    
    MP{counter}.w   = W{mix};
    counter = counter + 1;
end
js = pairs2json(MP); % generate json blob to be ingested into point-match database

%% ingest
pm = sl.target_point_match_collection;
if sl.verbose
    disp('Ingesting point matches');
end
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












