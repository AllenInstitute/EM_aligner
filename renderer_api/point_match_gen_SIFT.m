function [m12_1, m12_2, v] = point_match_gen_SIFT(url1, url2)
% don't use ---- still under testing --- hardcoded paths
% Return point-matches based on SIFT features   --- still under development
%
% Depends on Eric T.'s packaging of Saalfeld's code that uses SIFT and filters point matches
% 
% This function is still being testd. In the future it will exercise the full range of parameters
% and use arrays of tile pairs.
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
m12_1 = [];
m12_2 = [];
v = [];
if nargin<3, run_local = 1;end

% URLs could be anything that the Renderer can interpret accoring to its API.
% for example tile urls should look like this:
% url1 = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/render-parameters?filter=true',...
%                 t1.server, t1.owner, t1.project, t1.stack, t1.renderer_id);
% url2 = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/render-parameters?filter=true',...
%                 t2.server, t2.owner, t2.project, t2.stack, t2.renderer_id);

%http://10.37.5.60:8080/render-ws/v1/owner/flyTEM/project/test/stack/EXP_v12_SURF_rough_1_4/tile/151215054802009008.3.0/render-parameters?filter=true
% command issued to system
%/groups/flyTEM/flyTEM/render/bin/gen-match.sh --memory 7G --numberOfThreads 8 --baseDataUrl "${BASE_DATA_URL}" --owner trautmane --collection test_match_gen ${TILE_URL_PAIRS} | tee -a log.txt

tm = clock;
file_code = [num2str(tm(6)) '_' num2str(randi(1000000000000))];

fn_pm = ['/groups/flyTEM/home/khairyk/mwork/temp/matches_' file_code '.json'];
fn_log = ['groups/flyTEM/home/khairyk/mwork/temp/log_' file_code '.txt'];

base_cmd = '/groups/flyTEM/flyTEM/render/bin/gen-match.sh ';
str_memory = '--memory 7G ';
str_n_threads = '--numberOfThreads 8 ';
str_base_data_url = '--baseDataUrl http://tem-services:8080/render-ws/v1 ';
str_owner = '--owner trautmane ';
str_collection = '--collection test_match_gen ';


str_pairs =[url1 ' ' url2];

str_parameters = [' --matchStorageFile ' fn_pm ' | tee -a ' fn_log];

str = [base_cmd str_memory str_n_threads str_base_data_url str_owner str_collection str_pairs str_parameters];


[a, resp_str] = system(str);
%disp(resp_str);
wait_for_file(fn_pm, 10);

%% read json file
try
    v = JSON.parse(fileread(fn_pm));
catch
    error('Error reading point-matches json file');
end


%% extract point matches from json
if ~isempty(v{1}.matches.p)
    m12_1 = [ [v{1}.matches.p{1}{:}]' [v{1}.matches.p{2}{:}]'];
    m12_2 = [ [v{1}.matches.q{1}{:}]' [v{1}.matches.q{2}{:}]'];
    % look at point matches
    max_n_show = 20;
    if size(m12_2,1)>max_n_show,
        indx = randi(size(m12_2,1), max_n_show,1);
        m12_2 = m12_2(indx,:);
        m12_1 = m12_1(indx,:);
    end

else
    warning('No point-matches found -- empty set returned');
end


%% cleanup
delete(fn_pm);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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