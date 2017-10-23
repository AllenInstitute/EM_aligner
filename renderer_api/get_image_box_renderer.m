function [im, v, url, resp_str] = get_image_box_renderer(rc, z, Wbox, scale, fn_id)
% Returns the image of a specified box in collection rc
% use Renderer client for complete box
%   /v1/owner/{owner}/project/{project}/stack/{stack}/z/{z}/box/{x},{y},{width},{height},{scale}/jpeg-image
%
% Future work: Call java code directly
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% default the renderer binary to Janelia's setup
if ~isfield(rc, 'renderbinPath')
    rc.renderbinPath = '/groups/flyTEM/flyTEM/render/bin';
end

if nargin<5, fn_id = [];end
%%% check input
maxD = 500000;
if Wbox(3)*scale>maxD || Wbox(4)*scale>maxD, error('box too large');end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

v = [];
fn = [tempdir 'tile_image_' generate_uuid '_' fn_id '.jpg'];
url = sprintf('%s/owner/%s/project/%s/stack/%s/z/%s/box/%.0f,%.0f,%.0f,%.0f,%s/render-parameters?filter=true',...
    rc.baseURL, rc.owner, rc.project, rc.stack, num2str(z), ...
    Wbox(1), ...
    Wbox(2), ...
    Wbox(3), ...
    Wbox(4), ...
    num2str(scale));



% we will try multiple times
cmd = sprintf('%s/render.sh --memory 7g --out %s --parameters_url "%s"',rc.renderbinPath, fn, url);
[a, resp_str] = system(cmd);
file_ready = 0;
count = 1;
while ~(file_ready) && count<2000
    pause(0.1);
    file_ready = [exist(fn,'file')==2];
    count = count + 1;
end
try
    pause(2.0);
    im = imread(fn, 'jpeg');
    %if nargout>1, v = webread(url);end
catch err_reading_image
    kk_disp_err(err_reading_image);
    disp('Retrying');
    pause(1.0);
    im = imread(fn, 'jpeg');
end
im = rgb2gray(im);
delete(fn);