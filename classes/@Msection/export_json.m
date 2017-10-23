function str = export_json(obj, fn, force)
%void export_canvas set to json
% should look like this example

%  [{ "tileId" : "19", "transform" : { "className": "mpicbg.trakem2.transform.AffineModel2D", "dataString": "-0.999998 -0.00175975 0.00175975 -0.999998 3552.54 4032.52" } },
%  { "tileId" : "21", "transform" : { "className": "mpicbg.trakem2.transform.AffineModel2D", "dataString": "-0.999999 -0.00126332 0.00126332 -0.999999 1773.45 4000.13" } },
%  { "tileId" : "22", "transform" : { "className": "mpicbg.trakem2.transform.AffineModel2D", "dataString": "-0.999999 -0.00137386 0.00137386 -0.999999 1807.73 2026.78" } },
%  { "tileId" : "24", "transform" : { "className": "mpicbg.trakem2.transform.AffineModel2D", "dataString": "-0.999999 -0.00162851 0.00162851 -0.999999 -13.9462 1975.58" } },
%  { "tileId" : "20", "transform" : { "className": "mpicbg.trakem2.transform.AffineModel2D", "dataString": "-0.999995 0.00315403 -0.00315403 -0.999995 3580.91 2068.05" } },
%  { "tileId" : "25", "transform" : { "className": "mpicbg.trakem2.transform.AffineModel2D", "dataString": "-1 0 0 -1 0 0" } }
%  ]


if nargin<3, force = 0;end

str = sprintf('[');
for tix = 1:numel(obj.tiles)
    if ~force && obj.tiles(tix).state==1
        if isa(obj.tiles(tix).tform, 'affine2d')
            className = 'mpicbg.trakem2.transform.AffineModel2D';
            
            T = obj.tiles(tix).tform.T;
            T = [T(1) T(2) T(4) T(5) T(3) T(6)]; % rearrange to be renderer compatible
            if tix<numel(obj.tiles)
            str = [str sprintf('{"tileId" : "%s", "transform" : { "className": "%s", "dataString": "%.16f %.16f %.16f %.16f %.16f %.16f" } },\n',...
                obj.tiles(tix).renderer_id, className, T(1), T(2), T(3), T(4), T(5), T(6))];
            else
                            str = [str sprintf('{"tileId" : "%s", "transform" : { "className": "%s", "dataString": "%.16f %.16f %.16f %.16f %.16f %.16f"} }\n',...
                obj.tiles(tix).renderer_id, className, T(1), T(2), T(3), T(4), T(5), T(6))];
            end
        else
            error('Export of non-affine not implemented yet');
        end
    end
end
str = [str sprintf(']')];

fid = fopen(fn,'w');
fprintf(fid, str);
fclose(fid);











