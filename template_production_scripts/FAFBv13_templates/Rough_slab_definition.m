%% automatic generation of rough slab definitions (sections and scale for montage scapes)
% slabs will be of equal size
% Generates: nfirstvec, nlastvec, scalevec, overlapvec, nslabs
%% configure
nfirst = 1;
nlast  = 7062;
dslab = 50; % slab thickness
slo = 10; % slab overlap
max_image_area = 1.575*10^8; %84.5*10^6;% maximum montage-scape image area (HxW)
max_scale = 0.1;
min_scale = 0.02;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

log_max_image_area = log(max_image_area);
disp(log_max_image_area);

% configure montage collection
rcsource.stack          = 'EXP_dmesh_montage_P1_peg';
rcsource.owner          ='flyTEM';
rcsource.project        = 'test';
rcsource.service_host   = '10.40.3.162:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

%% rough collection definition
rctarget_rough.stack          = '';
rctarget_rough.owner          ='flyTEM';
rctarget_rough.project        = 'test2';
rctarget_rough.service_host   = '10.40.3.162:8080';
rctarget_rough.baseURL        = ['http://' rctarget_rough.service_host '/render-ws/v1'];
rctarget_rough.verbose        = 1;


%% get section bounds
% get /v1/owner/{owner}/project/{project}/stack/{stack}/z/{z}/bounds
[zu1, sID1, sectionId1, z1, ns1] = get_section_ids(rcsource, nfirst, nlast);
box = [];
parfor ix = 1:numel(zu1)
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%d/bounds', ...
        rcsource.baseURL, rcsource.owner, rcsource.project, rcsource.stack, zu1(ix));
    woptions = weboptions('Timeout', 60);
    j = webread(urlChar, woptions);
    box(ix,:) = [j.minX j.maxX j.minY j.maxY];
end

%% determine Section Areas and plot
% R = [(1:numel(zu1))' box(:,2)-box(:,1) box(:,4)-box(:,3)];
% SectionArea = R(:,2).*R(:,3);
% indx = find(SectionArea==max(SectionArea));
% disp((SectionArea(indx)));
% 
% close allplot(log(SectionArea));
%% partition into overlaping slabs
nfirstvec = [];
nlastvec = [];
nfirstvec(1) = 1;
nlastvec(1) = nfirstvec + dslab-1;
count = 1;
zend = nlast;
while count
    nfirstvec = [nfirstvec nlastvec(count)-slo];
    count = count + 1;
    nlastvec = [nlastvec nfirstvec(count) + dslab];
    if nlastvec(count)>zend,
        nlastvec(count) = zend;
        count = 0;
    end
end
% %
overlapvec = [nfirstvec(2:end)' nlastvec(1:end-1)'];
nslabs = numel(nfirstvec);
%% determine scale factor for every slab 
for six = 1:nslabs
    vec = find((zu1>=nfirstvec(six) & zu1<= nlastvec(six)));
    R = [box(vec,2)-box(vec,1) box(vec,4)-box(vec,3)];
    MaxSlabSectionArea = max(R(:,1).*R(:,2));
    
    scalevec(six) = max_image_area/MaxSlabSectionArea;
    if scalevec(six)>max_scale, scalevec(six) = max_scale;end
    if scalevec(six)<min_scale, scalevec(six) = min_scale; end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
run_now_vec_rough = [ones(1,length(scalevec))];
nslabs = numel(nfirstvec);
%% additional configurations
dir_store_rough_slab = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_slab_rough_aligned';

%% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';


%% generate collections
rough_collection = {};
fine_collection = {};
for ixs = 1:nslabs
    rough_collection{ixs}       = rctarget_rough;
    rough_collection{ixs}.stack = ['PROD_ROUGH_MP1_RR_' num2str(nfirstvec(ixs)) '_' num2str(nlastvec(ixs))];
    rough_stack{ixs} = rough_collection{ixs}.stack;
    rough_collection{ixs}.nfirst = nfirstvec(ixs);
    rough_collection{ixs}.nlast  = nlastvec(ixs);

    % check stack existence
    
    rough_collection_exists = stack_exists(rough_collection{ixs});
    
    if rough_collection_exists,
        rough_collection_exists_str{ixs} = 'X';
    else
        rough_collection_exists_str{ixs} = 'O';
    end
    run_now_vec_rough(ixs) = ~rough_collection_exists;
    

end


%% %% disp
TB = table([1:nslabs]', [rough_stack(:)], [rough_collection_exists_str(:)],...
    nfirstvec', nlastvec', scalevec', ...
    run_now_vec_rough');
disp(TB)






































