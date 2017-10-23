function boxim = get_image_box_bock_server(rendered_stack, scale_level, z, Wbox)
% reads image data from disk using rendered_stack, based on a collection defined in rcsource
% Wbox is [ x y W H];
%
% Note: reads at scale level scale_level in CATMAID convention
% rendered_stack.type = 'bock';
% rendered_stack.pth = 'https://neuropil.janelia.org/tracing/tiles/special/fafb_v12_align_tps_jpg85/';
% rendered_stack.dim = 1024;
% rendered_stack.ext = 'jpg';
% % desired image box
% scale_level = 0;
% z = 1;
% Wbox = [131000 61000 500 500];
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% configure
scale_level = round(scale_level); % sosi --- change to accommodate intermediate scale levels in the future
sd = 2^(scale_level);
dim = rendered_stack.dim;
%% determine set of rows and columns that must be loaded, as ranges [minrow mincol maxrow maxcol]

rowCol = [floor(Wbox(1)/dim/sd) floor(Wbox(2)/dim/sd) ceil((Wbox(1)+Wbox(3))/dim/sd) ceil((Wbox(2)+Wbox(4))/dim/sd)];
%disp(rowCol);
dimx = (rowCol(3)-rowCol(1) + 1) * dim;
dimy = (rowCol(4)-rowCol(2) + 1) * dim;
I = zeros(dimx, dimy);
for cix = rowCol(2):rowCol(4)
    for rix = rowCol(1):rowCol(3)
        try
%             fn = [rendered_stack.pth '/' num2str(scale_level) '/' num2str(z) '/' num2str(cix) '/' num2str(rix) '.' rendered_stack.ext];
%             im = imread(fn);
            
            %%% via http
            url = [rendered_stack.pth num2str(scale_level) '/' num2str(z) '/' num2str(cix) '/' num2str(rix) '.' rendered_stack.ext];
            im = webread(url);
            x1 = (rix-rowCol(1))*dim + 1;
            y1 = (cix-rowCol(2))*dim + 1;
            x2 = (rix-rowCol(1)+1)*dim;
            y2 = (cix-rowCol(2)+1)*dim;
            
            %             % sosi
            %             disp([rix cix]);
            %             disp(fn);
            %             disp([x1 x2 y1 y2]);
            %             %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            I(y1:y2, x1:x2) = im;
            
            
        catch err_get_image
            kk_disp_err(err_get_image);
            im = [];
        end
        
    end
end
% crop I to correspond to the desired region
mw = mod(Wbox,dim*sd);
xrange = round((mw(2):mw(2)+Wbox(4)-1)/sd);
yrange = round((mw(1):mw(1)+Wbox(3)-1)/sd);



try
    boxim = uint8(mat2gray(I(xrange, yrange))*255);
catch err_crop
    kk_disp_err(err_crop);
    disp('Empty box returned');
    boxim = [];
end
%% sosi
%
% [im, v, url] = get_image_box_renderer(rcsource, 1, Wbox, 1.0, pwd, 'xxx');
% figure;imshow(im);title('from renderer');

%%
function in = point_in_box(p,b)
% b = [xmin xmax ymin ymax]
% where (xmin,ymin) is the lower left corner
% and (xmax, ymax) is the upper left corner

 if b(2) > p(1) && p(1) > b(1) && b(4) > p(2) && p(2) > b(3)
     in  = 1;
 else
     in = 0;
 end




















