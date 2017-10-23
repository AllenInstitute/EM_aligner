function [m12_1, m12_2, v, err_log] = point_match_gen_SIFT_qsub(url1, url2, opts)
% Return point-matches based on SIFT features   --- still under development
%
% Depends on Eric T.'s packaging of Saalfeld's code that uses SIFT and filters point matches
%
% Future plans:
%
% This function is still being testd. In the future it will exercise the full range of parameters
% and use arrays of tile pairs.
% Access to Renderer functions will be using Java directly within Matlab
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verbose = 0;
err_log = {};
v = [];
% URLs could be anything that the Renderer can interpret accoring to its API.
% for example tile urls should look like this:
% url1 = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/render-parameters?filter=true',...
%                 t1.server, t1.owner, t1.project, t1.stack, t1.renderer_id);
% url2 = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/render-parameters?filter=true',...
%                 t2.server, t2.owner, t2.project, t2.stack, t2.renderer_id);

%http://10.37.5.60:8080/render-ws/v1/owner/flyTEM/project/test/stack/EXP_v12_SURF_rough_1_4/tile/151215054802009008.3.0/render-parameters?filter=true
% command issued to system
%/groups/flyTEM/flyTEM/render/bin/gen-match.sh --memory 7G --numberOfThreads 8 --baseDataUrl "${BASE_DATA_URL}" --owner trautmane --collection test_match_gen ${TILE_URL_PAIRS} | tee -a log.txt


%%%% configure SIFT and point match decisions
if nargin<3,
opts.SIFTfdSize        = 8;
opts.SIFTmaxScale      = 0.8;
opts.SIFTminScale      = 0.2;
opts.SIFTsteps         = 3;

opts.matchMaxEpsilon     = 20;
opts.matchRod            = 0.92;
opts.matchMinNumInliers  = 10;
opts.matchMinInlierRatio = 0.0;

end


% generate proper UUID in the future (e.g. uuid = generate_uuid() ) whic uses Java
tm = clock;
file_code           = [num2str(tm(6)) '_' num2str(randi(1000000000000))];
dir_temp_pm         = '/groups/flyTEM/home/khairyk/mwork/temp';
dir_temp_script     = '/groups/flyTEM/home/khairyk/mwork/temp';

fn_script           = [dir_temp_script '/script_' file_code '.sh'];
fn_pm               = [dir_temp_pm '/matches_' file_code '.json'];
%fn_log              = [dir_temp_script '/log_' file_code '.txt'];

% fn_pm = ['/scratch/khairyk/matches_' file_code '.json'];
% fn_log = ['/scratch/khairyk/log_' file_code '.txt'];

%% configure script parameters
base_cmd            = '/groups/flyTEM/flyTEM/render/bin/gen-match.sh ';
str_memory          = '--memory 11G ';
str_n_threads       = '--numberOfThreads 8 ';
str_base_data_url   = '--baseDataUrl http://tem-services:8080/render-ws/v1 ';
str_owner           = '--owner khairyk ';
str_collection      = '--collection test_match_gen ';

str_SIFTfdSize      = sprintf('--SIFTfdSize %d ', opts.SIFTfdSize);
str_SIFTmaxScale    = sprintf('--SIFTmaxScale %.1f ', opts.SIFTmaxScale);
str_SIFTminScale    = sprintf('--SIFTminScale %.2f ', opts.SIFTminScale);
str_SIFTsteps       = sprintf('--SIFTsteps %d ', opts.SIFTsteps);

str_matchMaxEpsilon = sprintf('--matchMaxEpsilon %d ', opts.matchMaxEpsilon);
str_matchRod        = sprintf('--matchRod %.2f ', opts.matchRod);
str_matchMinNumInliers = sprintf('--matchMinNumInliers %d ', opts.matchMinNumInliers);
str_matchMinInlierRatio= sprintf('--matchMinInlierRatio %.2f ', opts.matchMinInlierRatio);

%% construct command to call Eric T.'s script
str_pairs           = [url1 ' ' url2 ' '];
str_parameters      = [' --matchStorageFile ' fn_pm];
sift_str            = [base_cmd str_memory str_n_threads str_base_data_url str_owner str_collection str_pairs str_SIFTfdSize str_SIFTmaxScale str_SIFTminScale str_SIFTsteps str_matchMaxEpsilon str_matchRod str_matchMinNumInliers str_matchMinInlierRatio str_parameters];
resp                 = write_script(fn_script, sift_str);
if verbose, disp(resp);end
if exist(fn_pm,'file'), delete fn_pm;end

%% qsub call
jbname = ['ST-' num2str(randi(10000))]; % just to generate somewhat unique names for jobs
account = '-A flyTEM';
% job_log = '-j y -o /groups/flyTEM/home/khairyk/mwork/temp';
job_log = '-j y -o /dev/null';
qsub_str = sprintf('qsub -l short=true -N %s %s %s -cwd -V -b y -pe batch 8 "%s" ',...
    jbname, account, job_log, fn_script);
manage_jobs('khairyk', {jbname}, {qsub_str}, {dir_temp_script}, 10, []);

% [a, resp_str] = system(qsub_str);
% if verbose, disp(resp_str);end
% wait_for_file(fn_pm, 400, verbose);  %%%  needs to  babysit better than that

if exist(fn_pm,'file')==2
%% read json file
try
    v = JSON.parse(fileread(fn_pm));
    
    %% extract point matches from json
    if ~isempty(v{1}.matches.p)
        m12_1 = [ [v{1}.matches.p{1}{:}]' [v{1}.matches.p{2}{:}]'];
        m12_2 = [ [v{1}.matches.q{1}{:}]' [v{1}.matches.q{2}{:}]'];
        % look at point matches
        max_n_show = 100000;
        if size(m12_2,1)>max_n_show,
            indx = randi(size(m12_2,1), max_n_show,1);
            m12_2 = m12_2(indx,:);
            m12_1 = m12_1(indx,:);
        end
        
    else
        if verbose, disp('No point-matches found');end
        err_log{end+1} = 'No point-matches found';
        m12_1 = [];
        m12_2 = [];
    end
catch err_reading_json_point_matches
    %kk_disp_err(err_reading_json_point_matches);
    
    err_log{end+1}('Error reading point-matches json file ---- skipping this file:');
    err_log{end+1}(fn_pm);
    err_log{end+1}('original qsub command :');
    err_log{end+1}(qsub_str);
    err_log{end+1}('No point-matches found');
    err_log{end+1} = qsub_str;
    m12_1 = [];
    m12_2 = [];
end
else
    m12_1 = [];
    m12_2 = [];
    err_log{end+1} = ['json file was not generated, giving up'];
end

err_log{end+1} = qsub_str;

%% cleanup
try
    delete(fn_script);
    if exist(fn_pm, 'file'), delete(fn_pm);end;
catch err_delete
    err_log{end+1} = 'Failed to delete file';
    kk_disp_err(err_delete);
end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% options from Eric T's original Email
% %     --SIFTfdSize
% %        SIFT feature descriptor size: how many samples per row and column
% %        Default: 8
% %     --SIFTmaxScale
% %        SIFT maximum scale: minSize * minScale < size < maxSize * maxScale
% %        Default: 0.85
% %     --SIFTminScale
% %        SIFT minimum scale: minSize * minScale < size < maxSize * maxScale
% %        Default: 0.5
% %     --SIFTsteps
% %        SIFT steps per scale octave
% %        Default: 3
% %   * --baseDataUrl
% %        Base web service URL for data (e.g. http://host[:port]/render-ws/v1)
% %   * --collection
% %        Match collection name
% %     --debugDirectory
% %        Directory to save rendered canvases for debugging (omit to keep rendered
% %        data in memory only)
% %     --fillWithNoise
% %        Fill each canvas image with noise before rendering to improve point match
% %        derivation
% %        Default: true
% %     --help
% %        Display this note
% %        Default: false
% %     --matchGroupIdAlgorithm
% %        Algorithm for deriving match group ids
% %        Default: FIRST_TILE_Z
% %        Possible Values: [FIRST_TILE_Z, COLLECTION]
% %     --matchIdAlgorithm
% %        Algorithm for deriving match ids
% %        Default: FIRST_TILE_ID
% %        Possible Values: [FIRST_TILE_ID, FIRST_TILE_Z, CANVAS_NAME]
% %     --matchMaxEpsilon
% %        Minimal allowed transfer error for matches
% %        Default: 20.0
% %     --matchMinInlierRatio
% %        Minimal ratio of inliers to candidates for matches
% %        Default: 0.0
% %     --matchMinNumInliers
% %        Minimal absolute number of inliers for matches
% %        Default: 10
% %     --matchRod
% %        Ratio of distances for matches
% %        Default: 0.92
% %     --matchStorageFile
% %        File to store matches (omit if macthes should be stored through web
% %        service)
% %     --numberOfThreads
% %        Number of threads to use for processing
% %        Default: 1
% %   * --owner
% %        Match collection owner
% %     --renderFileFormat
% %        Format for saved canvases (only relevant if debugDirectory is specified)
% %        Default: JPG
% %        Possible Values: [JPG, PNG, TIF]