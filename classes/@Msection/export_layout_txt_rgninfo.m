function export_layout_txt_rgninfo(obj, fn, force)
% consider mergin with export_layout_txt.m
%% writes to file fn the data for all patches in layer z as a layout.txt file
% fn is a file name or file id of a file we can write to.
%
% Author: Khaled Khairy. Janelia Reseaarch Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ischar(fn), %strcmp(class(fn), 'char')
    fid = fopen(fn,'w');
else
    fid = fn;
end
%%
if nargin<3, force = 0;end
rgn = 1;
for ix = 1:numel(obj.tiles)
    if obj.tiles(ix).state>=1 || force
    fprintf(fid, '%d\t%d\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\n',...
        obj.tiles(ix).id, ...
        rgn,...
        obj.tiles(ix).tform.T(1,1), obj.tiles(ix).tform.T(2,1), obj.tiles(ix).tform.T(3,1),...
        obj.tiles(ix).tform.T(1,2), obj.tiles(ix).tform.T(2,2), obj.tiles(ix).tform.T(3,2));
    end
end
if ischar(fn), %strcmp(class(fn), 'char')
    fclose(fid);
end
