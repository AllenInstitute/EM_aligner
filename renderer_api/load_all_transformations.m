function [T, map_id, tIds, section_id] = load_all_transformations(rc, zu, dir_scratch)
% fastest way to load tile transformations from a renderer collection for 
% z-values specified in vector zu.
% Requires specification of a scratch directory.
cd(dir_scratch);
fn_layout = [dir_scratch '/layout_file_' num2str(randi(100000000)) '.txt'];
% % Generate the layout file (the main input) using the Renderer service
url_collection = sprintf('%s/owner/%s/project/%s/stack/%s', ...
    rc.baseURL, rc.owner, rc.project, rc.stack);

%%% todo: get rid of curl command and use Matlab to do this.
str = sprintf('curl -o %s %s/zRange/%.2f,%.2f/layoutFile', ...
    fn_layout, url_collection, zu(1), zu(end));
[a,s] = system(str);
if rc.verbose
    disp(a);
    disp(s);
end
% confirm generation of layout file
if ~wait_for_file(fn_layout,30),
    disp(str);
    error(' Could not generate layout file');
end
% confirm that the layout file has all layers in it;
str = ['head -3 ' fn_layout];[a, c] = system(str);if rc.verbose, disp(c); end
str = ['tail -3 ' fn_layout];[a, c] = system(str);if rc.verbose, disp(c); end
fid = fopen(fn_layout, 'r');
% C = textscan(fid,'%n%s%n%n%n%n%n%n%n%n%n%s%n%n%n%s', 'delimiter', '\t');
C = textscan(fid,'%n%s%n%n%n%n%n%n%n%n%s%s%s%s%s%s', 'delimiter', '\t');
fclose(fid);
delete(fn_layout);
section_id = C{1};
tIds = C{2};
T = [C{3}(:) C{4}(:) C{5}(:) C{6}(:) C{7}(:) C{8}(:)];

parfor ix = 1:numel(tIds)
    count_vec(ix)= {ix};
    id_vec(ix) = tIds(ix);%tIds{ix};
end
map_id = containers.Map(id_vec, count_vec);

