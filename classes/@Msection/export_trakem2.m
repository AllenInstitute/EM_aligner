function export_trakem2(obj, filename)
% export to TrakEM2 readable format
% Author: Khaled Khairy (Janelia SciComp) -- June 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
obj = update_tile_info(obj);
obj = get_bounding_box(obj);
% X = obj.tiles(1).tform.T(3,1);
% Y = obj.tiles(1).tform.T(3,2);

X = zeros(numel(obj.tiles), 1);
Y = zeros(numel(obj.tiles), 1);
H = 0;
W = 0;
for ix = 1:numel(obj.tiles)
    X(ix) = obj.tiles(ix).tform.T(3,1);
    Y(ix) = obj.tiles(ix).tform.T(3,2);
    %     tim = get_warped_image(tiles(ix));
    if obj.tiles(ix).W > W, W = obj.tiles(ix).W ;end
    if obj.tiles(ix).H > H, H = obj.tiles(ix).H ;end
end
% % shift all images such that X and Y positions are relative to World zero
for ix = 1:numel(obj.tiles)
    obj.tiles(ix).tform.T(3,1) = obj.tiles(ix).tform.T(3,1)-min(X);
    obj.tiles(ix).tform.T(3,2) = obj.tiles(ix).tform.T(3,2)-min(Y);
end

%%% generate the structs
oid = 0;

p.id = num2str(oid);oid = oid+1;
p.title = 'Project';
p.mipmaps_folder = 'trakem2.mipmaps/';
p.n_mipmap_threads='8';


tls.oid=num2str(oid);oid = oid+1;
tls.transform='matrix(1,0,0,1,0,0)';
tls.title='Top level';
tls.layer_width=num2str(range(X)+W);
tls.layer_height=num2str(range(Y)+H);

tl.oid=num2str(oid);oid = oid+1;
tl.thickness='0';
tl.z=num2str(obj.z);
counter = 1;
for tix = 1:numel(obj.tiles)
    if obj.tiles(tix).state
        tp(counter).layer_id = obj.z;
        tp(counter).oid=obj.tiles(tix).id;%oid;oid = oid + 1;
        tp(counter).width=num2str(obj.tiles(tix).W);
        tp(counter).height=num2str(obj.tiles(tix).H);
        T = obj.tiles(tix).tform.T;      % transformation dependent
        tp(counter).transform=['matrix(' num2str(T(1)) ',' num2str(T(4)) ',' num2str(T(2)) ',' num2str(T(5)) ',' num2str(T(3)) ',' num2str(T(6)) ')'];
        tp(counter).title=[num2str(obj.z) '.' num2str(obj.tiles(tix).id) '-1_68.46.2'];
        tp(counter).type='0';
        tp(counter).file_path=obj.tiles(tix).path;
        tp(counter).o_width=num2str(obj.tiles(tix).W);
        tp(counter).o_height=num2str(obj.tiles(tix).H);
        counter = counter + 1;
    end
    
end

%% write
write_trakem2_xml(filename, p, tls, tl, tp);








































