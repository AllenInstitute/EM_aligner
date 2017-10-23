function [zu, sID, sectionId, z, ns, zuf] = get_section_ids(rc, nfirst, nlast)
urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/sectionData', ...
    rc.baseURL, rc.owner, rc.project, rc.stack);
options = weboptions('Timeout', 120);
try
    js = webread(urlChar, options);
catch err_webread
    disp('get_section_ids: failed to read... retrying');
    js = webread(urlChar, options);
    disp('Success!');
end
    
sectionId = {js(:).sectionId};
[z, ia]   = sort(([js(:).z]));
sectionId = sectionId(ia);

if nargin==1,   % then find all sections in this collection
    nfirst = min(z(:));
    nlast = max(z(:));
    disp(['Section range (z values): ' num2str(nfirst) ' to ' num2str(nlast)]);
end
indx = find(z>=nfirst & z<=nlast);
sectionId = sectionId(indx);% determine the sectionId list we will work with
z         = z(indx);        % determine the zvalues (this is also the spatial order)

% we need unique values, and we need to know how many sectionId's correspond to each unique z value
% usually it is one, but sometimes we have hi/lo dose or other regions
[zuf, ia, ic] = unique(floor(z));
[zu, ia, ic] = unique(z);
count = 1;
sID = {};
for zix = 1:numel(zu)
    ns(zix) =  numel(find(ic==zix));
    vec = {};
    for six = 1:ns(zix)
        vec{six} = sectionId{count};
        sID{zix} = vec;
        count = count + 1;
    end
end
