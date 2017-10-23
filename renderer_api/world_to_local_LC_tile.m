function [pGroupId, p] = world_to_local_LC_tile(rcW, rcmontage, wp, wbm)
% converts a point wp in  world coordinates (defined by rcW), to local tile coordinates (in the state after tile has been subjected
% to LC, which is typically by applying the first three transformations in the transformation list).
% rcmontage could also be rcacquire/rcsource
% The main requirement is that the last transformation is either identity or only a translation, and
% only preceded by the three original tansformations (the first being LC).
% wbm: is the world coordinate box for the montage collection. It should be pre calculated as follows
% (example):
%
% Wboxm = zeros(numel(L_montaged), 4);
% bboxm = zeros(numel(L_montaged),4);
% parfor lix = 1:numel(L_montaged)
%    [ Wboxm(lix,:), bboxm(lix,:)] = get_section_bounds_renderer(rctarget_montage, z(lix));
% end
% bbm = [min(Wboxm(:,1)) min(Wboxm(2)) max(bboxm(:,3)) max(bboxm(:,4))];
% wbm = [bbm(1) bbm(2) bbm(3)-bbm(1) bbm(4)-bbm(2)];
%
% or obtained from rcW by getting the stack bounds (sosi---do this in the future)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = wp(1);
y = wp(2);
z = wp(3);
%disp([x y z]); % these are now world coordinates for this point
tm = clock;
file_code           = [num2str(tm(6)) '_' num2str(randi(1000000000000))];
fn = [file_code 'tmp.txt']; % curl writes to this file, which then gets read by Matlab
[pGroupId, p] = world_to_local_renderer(rcW,fn, [x y z]);
if ~isempty(pGroupId)
    % convert from local (raw) to world (acquire)
    x = p(1);
    y = p(2);
    p = local_to_world_renderer(rcmontage, pGroupId, fn, [x y]);
    % we are not done yet. we have to find the point in the tile coordinate system of the image produced after
    % the standard first three transormations only have been applied, i.e. without the last transformation
    % we know this last transformation is a translation only in the rctarget_montage collection.
    % therefore all we need to do is subtract this last translation, and then translate to world 0,0
    
    % get the required translation from tile spec
    url1 = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/render-parameters?filter=true',...
        rcmontage.baseURL, rcmontage.owner, rcmontage.project, rcmontage.stack, pGroupId);
    v = webread(url1);
    
    transform_string = v.tileSpecs.transforms.specList(end).dataString;
    C = strsplit(transform_string);
    
    % assuming we are dealing with affines, then the required information is extacted as stings  5 and 6
    % of C:
    dx = str2double(C{5});
    dy = str2double(C{6});
    
    p = [p(1)-wbm(1) p(2)-wbm(2)]-[dx dy];
end