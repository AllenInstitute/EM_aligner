function resp = isautoloader(rc,z)
urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
    rc.baseURL, rc.owner, rc.project, rc.stack,z );
j = webread(urlChar);
sl = j(1).transforms.specList;   % spec list
resp = 0;
if numel(sl)==4
    resp = 1;
end   % four transformations means autoloader