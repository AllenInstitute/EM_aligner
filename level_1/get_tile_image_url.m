function tile_image_url = get_tile_image_url(rc, tileId, url_options, get_jpg, scale)
if nargin<5; scale = 1; end
cmd = sprintf('/groups/flyTEM/flyTEM/render/bin/get_tile_url.sh --baseDataUrl %s --owner %s --project %s --stack %s --tileId %s', rc.baseURL, rc.owner, rc.project, rc.stack, tileId);
% Using these if statements allows the default values to be used when
% necessary
if isfield(url_options, 'normalizeForMatching'), cmd = [cmd ' --normalizeForMatching ' url_options.normalizeForMatching]; end
if isfield(url_options, 'renderWithFilter'), cmd = [cmd ' --renderWithFilter ' url_options.renderWithFilter]; end
if isfield(url_options, 'renderWithoutMask'), cmd = [cmd ' --renderWithoutMask ' url_options.renderWithoutMask]; end
if isfield(url_options, 'fullScaleWidth'), cmd = [cmd ' --fullScaleWidth ' url_options.fullScaleWidth]; end
if isfield(url_options, 'fullScaleHeight'), cmd = [cmd ' --fullScaleHeight ' url_options.fullScaleHeight]; end
[~,tile_image_url] = system(cmd);
tile_image_url = regexprep(tile_image_url,'\r\n|\n|\r',''); % remove carriage return
if scale~=1, tile_image_url = [tile_image_url, '&scale=' num2str(scale)]; end
% If want the actual jpg (eg. for imread from webpage):
if get_jpg, tile_image_url = strrep(tile_image_url, 'render-parameters', 'jpeg-image'); end
end