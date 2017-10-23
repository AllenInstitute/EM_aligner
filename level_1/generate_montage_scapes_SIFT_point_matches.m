function [Lin, needs_correction, fn_matches, zsetd, zrange, t, ...
    dir_spark_work, cmd_str, fn_ids, missing_images, existing_images] = ...
    generate_montage_scapes_SIFT_point_matches(ms, run_now, precalc_ids, precalc_matches, precalc_path)
%% Returns an Msection object with registered montage-scapes as tiles
% Depends on :
%               - spark installation at Janelia
%               - script (provided in "external" folder to generate montage scapes and calculate point-matches using spark
%                 (code-base: Stephan Saalfeld, scritp/packaged Eric Trautman)
% Input:
%               - ms: a struct with fields specifying spark job and sift parameters. For example:
% ms.service_host                 = rctarget_montage.service_host;
% ms.owner                        = rctarget_montage.owner;
% ms.project                      = rctarget_montage.project;
% ms.stack                        = rctarget_montage.stack;
% ms.first                        = num2str(nfirst);
% ms.last                         = num2str(nlast);
% ms.fd_size                      = '8';
% ms.min_sift_scale               = '0.55';
% ms.max_sift_scale               = '1.0';
% ms.steps                        = '3';
% ms.scale                        = '0.05';
% ms.similarity_range             = '3';
% ms.skip_similarity_matrix       = 'y';
% ms.skip_aligned_image_generation= 'y';
% ms.base_output_dir              = '/nobackup/flyTEM/spark_montage';
% ms.run_dir                      = ['scale_' ms.scale];
% ms.script                       = '../external/generate_montage_scape_point_matches.sh';
%
%
% Author: Khaled Khairy: Janelia Research Campus. Copyright 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
check_input(ms);
needs_correction = 0;
waitTime = 30;
zsetd = [];
zrange = [];
cmd_str = '';
dir_spark_work = '';
t = tile;
if nargin<2, run_now = 1;end
if ~isfield(ms, 'number_of_spark_nodes'), ms.number_of_spark_nodes = num2str(2);end
%% clean up any previous jobs
dir_spark_work = [ms.base_output_dir '/' ms.project '/' ms.stack  '/' ms.run_dir];
if run_now
    kk_mkdir(dir_spark_work);
    %% construct and submit point-match calculation for montage scapes
    cmd_str = [ms.script ' ' ms.service_host ' ' ms.owner ' ' ms.project ' '...
        ms.stack ' ' ms.first ' ' ms.last ' ' ms.fd_size ' ' ...
        ms.min_sift_scale ' ' ms.max_sift_scale ' ' ms.steps ' ' ...
        ms.scale ' ' ms.similarity_range ' ' ms.skip_similarity_matrix ' ' ...
        ms.skip_aligned_image_generation ' ' ms.base_output_dir ' ' ...
        ms.run_dir];% ' ' ms.number_of_spark_nodes];
    [a, resp_str] = system(cmd_str);
    disp(resp_str);
end
if nargin<3
    %% wait for files to finish generating
    f = dir([dir_spark_work '/solver_*']);
    dir_solver = [dir_spark_work '/' f.name];
    fn_matches = [dir_solver '/matches.txt'];
    while exist(fn_matches,'file')~=2
        f = dir([dir_spark_work '/solver_*']);
        dir_solver = [dir_spark_work '/' f.name];
        fn_matches = [dir_solver '/matches.txt'];
        if ~isempty(f)
            disp(['Waiting for file: ' dir_solver '/matches.txt']);
            pause(30);
        else
            disp(['Waiting for file: ' dir_solver '*/matches.txt']);
            pause(waitTime);
        end
    end
    fn_ids     = [dir_solver '/ids.txt'];
else
    fn_ids = precalc_ids;
    fn_matches = precalc_matches;
    dir_spark_work = precalc_path;
end

disp('Reading point-match information from:');
disp(fn_ids);
disp(fn_matches);
disp(dir_spark_work);
%% check that all image files exist
montage_scape_gen_error = 0;
fn_ims = {};
missing_images = [];
existing_images = [];
counter = 1;
for imix = str2double(ms.first):str2double(ms.last)
    fn_im = sprintf('%s/layer_images/%.1f.png', dir_spark_work,imix);
    fn_ims{counter} = fn_im;
    if exist(fn_im,'file')~=2
        missing_images = [missing_images imix];
        disp([num2str(imix) ' -- Missing montage scape image: ' fn_im]);
        montage_scape_gen_error = 1;
    else
        existing_images = [existing_images imix];
    end
    counter = counter + 1;
end
if montage_scape_gen_error,
    warning('Not all montage scapes were generated.');
end


%% read montage-scape image metainformation from fn_ids and point-matches
disp('Reading data ...');tic
fid = fopen(fn_ids,'r');if fid==-1, error('Failed to open stack layout file.');end
IDS     = textscan(fid,'%u64%s', 'delimiter', '');
fclose(fid);
%%% typecast the uint64 to double to get actual z-values
z = typecast(IDS{1}, 'double');
IDS{1} = double(IDS{1});
%% read point matches
fid = fopen(fn_matches,'r');if fid==-1, error('Failed to open stack layout file.');end
MATCHES = textscan(fid,'%n%n%n%n%n%n', 'delimiter', '\t');
fclose(fid);

%% generate Msection object with one tile/layer. each tile is a montage scape

tiles = tile;
parfor tix = 1:numel(IDS{1})
    t = tile;
    t.z = tix;
    t.id = IDS{1}(tix);
    t.renderer_id = num2str(IDS{1}(tix));
    if run_now
        t.path = IDS{2}{tix};
    else
        t.path = fn_ims{tix};
    end
    t.rot = 0;
    t.fetch_local = 1;
    tiles(tix) = t;
end
L = Msection(tiles);

%% generate point-matches--- pairs variable
delta = 0;
pairs = [ones(numel(MATCHES{1}),1) MATCHES{1}(:) MATCHES{2}(:)+delta MATCHES{3}(:)+delta ones(numel(MATCHES{1}),1) MATCHES{4}(:) MATCHES{5}(:)+delta MATCHES{6}(:)+delta];
options.verbose = 0;
options.minpmblock = 0;
options.minpmblock_cross = 0;

%% concatenate point_matches
if isempty(pairs),
    warning('No point-matches found');
    Lin = L;
    pm = [];
    needs_correction = -1;
    ll = split_z(Lin);
    zp = [ll(:).z] + str2double(ms.first)-1;
    zz = (str2double(ms.first):str2double(ms.last)) ;
    setd = setdiff(zz,zp);
    if ~montage_scape_gen_error,
        zsetd = z(setd-str2double(ms.first)+1);
        if ~isempty(setd),
            disp('Disconnected montage scapes: index');
            disp([setd(:) zsetd]);
            %disp(z(setd));
            warning('Montage scapes must form a fully connected set');
            needs_correction = 1;
        end
    end
    clear t;
    t(size(IDS,1)) = tile;
    for ix = 1:size(IDS{1},1)
        t(ix).z = ix;
        t(ix).sectionId = num2str(ix);
        t(ix).id = IDS{1}(ix);
        t(ix).renderer_id = num2str(IDS{1}(ix));
        t(ix).path = IDS{2}{ix};
    end
    
else
    [Lin] = pairs_to_pm(L, options, pairs);
    %% add a weights vector to pm struct
    w = [];
    np = [];
    W = cell(size(Lin.pm.adj,1),1);
    for ix = 1:length(W)
        w = 1/abs(z(Lin.pm.adj(ix,1))-z(Lin.pm.adj(ix,2)))/3;
        npoints = size(Lin.pm.M{ix,1},1);
        W{ix} = ones(npoints,1) * w;
        np(ix) = npoints;
    end
    Lin.pm.W = W;
    Lin.pm.np = np;
    %% reduce point-matches to next nb neighbors
    delix = [];
    counter = 1;
    for pix = 1:size(Lin.pm.M,1)
        adj = Lin.pm.adj(pix,:);
        if abs(adj(1)-adj(2))>str2double(ms.similarity_range)
            delix(counter) = pix;
            counter = counter + 1;
        end
    end
    Lin.pm.np(delix) = [];
    Lin.pm.W(delix) = [];
    Lin.pm.adj(delix,:) = [];
    Lin.pm.M(delix,:) = [];
    
    %% check that all montage scapes are present in Lin by splitting in z and
    % checking that all z's are present
    ll = split_z(Lin);
    zp = [ll(:).z] + str2double(ms.first)-1;
    zz = (str2double(ms.first):str2double(ms.last)) ;
    setd = setdiff(zz,zp);
    if ~montage_scape_gen_error,
        zsetd = z(setd-str2double(ms.first)+1);
        if ~isempty(setd),
            disp('Disconnected montage scapes: index');
            disp([setd(:) zsetd]);
            %disp(z(setd));
            warning('Montage scapes must form a fully connected set');
            needs_correction = 1;
        end
    end
    % generate a graph and analyze which pieces are
    % disconnected (probably better)
    [L_vec, ntiles] = reduce_to_connected_components(Lin);
    if numel(L_vec)>1, needs_correction = 1;end
    for lix = 1:numel(L_vec)
        zr = [L_vec(lix).tiles(:).z];
        zrange(lix,:) = ([min(zr) max(zr)]);
    end
    [~, ai] = sort(zrange(:,2),'ascend');
    %
    disp('Available connected tiles:');
    disp(zrange(ai,:));
    
    %%%%% manually fix connectivity
    % make a stack of the original images
    clear t;
    t(size(IDS,1)) = tile;
    for ix = 1:size(IDS{1},1)
        t(ix).z = ix;
        t(ix).sectionId = num2str(ix);
        t(ix).id = IDS{1}(ix);
        t(ix).renderer_id = num2str(IDS{1}(ix));
        t(ix).path = IDS{2}{ix};
    end
    
    %%
    %Lin = update_adjacency(Lin);
    pm = Lin.pm;
end




%% %%%%%%%%%%%%%%%%%%%%%%%%%
function check_input(ms)
if exist(ms.script, 'file')~=2,
    error('Invalid script path');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% script parameter meanings
% % % % % # source data parameters
% % % % % SERVICE_HOST=$1 #"10.40.3.162:8080"      # use IP address for tem-services until DNS issue is resolved
% % % % % OWNER=$2 #"flyTEM"
% % % % % PROJECT=$3 #"test"
% % % % % STACK=$4 #"EXP_v12_SURF_montage_1245_1247"
% % % % % FIRST_Z=$5 #""                        # z value of first layer to generate (leave empty "" if first layer in stack is desired)
% % % % % LAST_Z=$6 #""                         # z value of last layer to generate (leave empty "" if last layer in stack is desired)
% % % % %
% % % % % # SIFT parameters
% % % % % FD_SIZE=$7 #"8" #"4"  # feature descriptor size
% % % % %                   # The SIFT-descriptor consists of n×n gradient histograms, each from a 4×4px block.
% % % % %                   # n is this value. Lowe (2004) uses n=4. We found larger descriptors with n=8
% % % % %                   # perform better for Transmission Electron Micrographs from serial sections
% % % % % MIN_SIFT_SCALE=$8 #"0.55" #"0.75"
% % % % % MAX_SIFT_SCALE=$9 #"1.0"
% % % % % STEPS=${10} #"3"          # Keypoint candidates are extracted at all scales between maximum image size and minimum image size.
% % % % %                    # This Scale Space is represented in octaves    each covering a fixed number of discrete scale steps
% % % % %                    # from σ0 to 2σ0. More steps result in more but eventually less stable keypoint candidates.
% % % % %                    # Tip: Keep 3 as suggested by Lowe (2004) and do not use more than 10.
% % % % %
% % % % % # output parameters
% % % % % SCALE=${11} #"0.05"                         # scale of layer montage images
% % % % % SIMILARITY_RANGE=${12} #"3"                # maximum number of adjacent layers for similarity comparisons
% % % % %
% % % % % unset SKIP_SIMILARITY_MATRIX
% % % % % SKIP_SIMILARITY_MATRIX=${13} #"y"           # to build similarity matrix, comment this line out
% % % % %
% % % % % unset SKIP_ALIGNED_IMAGE_GENERATION
% % % % % SKIP_ALIGNED_IMAGE_GENERATION=${14} #"y"    # to generate aligned montage images, comment this line out (warning: this is slow)
