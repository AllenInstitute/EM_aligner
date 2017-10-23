function export_layout_txt(obj, fn, mode, force)
%% writes to file tile transform data (assuming affines) as a layout.txt file
% fn is a file name or an iopen file id
% mode = 0 ---> exports with temca_conf information
% mode = 1 ---> exports in compatibility mode, i.e. without temca column
% force = 0 default ---> only valid tiles (state>=1) will be written
% force = 1 ----> all tiles are exported
%
% Author: Khaled Khairy. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parse input and open file for writing if needed
if ischar(fn), 
    fid = fopen(fn,'w');
else
    fid = fn;
end
if nargin<3,  mode = 0; disp('Exporting layout file with temca_conf');end
if nargin>=3, mode = 1; disp('Exporting Bill-format layout file ---- no temca_conf');end
if nargin<4, force = 0;end

%% do the actual export
for ix = 1:numel(obj.tiles)
    if obj.tiles(ix).state>=1 || force          % only export those that are turned on
        if mode==0
            fprintf(fid, '%d\t%d\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%d\t%d\t%d\t%s\t%d\n',...
                obj.tiles(ix).z, obj.tiles(ix).id, ...
                obj.tiles(ix).tform.T(1,1), obj.tiles(ix).tform.T(2,1), obj.tiles(ix).tform.T(3,1),...
                obj.tiles(ix).tform.T(1,2), obj.tiles(ix).tform.T(2,2), obj.tiles(ix).tform.T(3,2),...
                obj.tiles(ix).col,...
                obj.tiles(ix).row, obj.tiles(ix).cam, obj.tiles(ix).path, obj.tiles(ix).temca_conf);
            
        elseif mode==1
            fprintf(fid, '%d\t%d\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%.6f\t%d\t%d\t%d\t%s\n',...
                obj.tiles(ix).z,...
                obj.tiles(ix).id, ...
                obj.tiles(ix).tform.T(1,1), obj.tiles(ix).tform.T(2,1), obj.tiles(ix).tform.T(3,1),...
                obj.tiles(ix).tform.T(1,2), obj.tiles(ix).tform.T(2,2), obj.tiles(ix).tform.T(3,2),...
                obj.tiles(ix).col,...
                obj.tiles(ix).row,...
                obj.tiles(ix).cam,...
                obj.tiles(ix).path);
        end
    end
end
if ischar(fn), %strcmp(class(fn), 'char')
    fclose(fid);
end
