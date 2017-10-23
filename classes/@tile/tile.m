classdef tile
    % tile  Summary: 
    %           Represents one image (tile) 
    % 
    %   tile constructors:
    %       *Scenario 1: obj = tile(js_struct); % struct; a json tile blob that was converted to a Matlab struct and passed as input argument
    %       *Scenario 2: obj = tile(z, id, t1, t2, t3, t4, t5, t6, col, row, cam, path, temca_conf, rotation, renderer_id); % the full tile configuration is expected explicitly (except for the mask which gets set separately (if at all)
    % 
    % Author: Khaled Khairy. khairyk@janelia.hhmi.org. FlyTEM team project.
    %         Janelia Research Campus. 2016
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        z;
        sectionId;
        id;
        renderer_id = '0';
        tform = affine2d;      % transformation
        confidence = [];       % store confidence interval on estimated parameters
        col;
        row;
        cam;
        path;
        mask = [];
        temca_conf = -999;
        rot;
        H = 0;
        W = 0;
        state = 1;             % 0 = this tile is marked for removal and should not be rendered (or has invalid transformation information)
        owner = 'flyTEM';
        project='FAFB00';
        stack = '';
        server = 'http://10.40.3.162:8080/render-ws/v1'; %'http://tem-services.int.janelia.org:8080/render-ws/v1'; % 
        features = [];        % store features information
        validPoints = [];     % point locations corresponding to features
        featuresMethod = 'SURF'; % method to be used for calculating features
        % surf paramters
        SURF_NumOctaves = 2;
        SURF_NumScaleLevels = 8;
        SURF_MetricThreshold = 1500;
        SURF_MaxFeatures = 5000;
        dir_temp_render = '/scratch/khairyk';% there is no elegant way to do this. [a resp] = system('whoami'); dir_temp_render = ['/scratch/' resp];
        renderer_client = '/groups/flyTEM/flyTEM/render/bin/render.sh';
        fetch_local = 0;
        scale = 1;

    end
    
    
    methods
        
        %% constructor
        function obj = tile(z, id, t1, t2, t3, t4, t5, t6,...
                col, row, cam, path, temca_conf, rotation, renderer_id)
            % *Scenario 1: obj = tile(js_struct); % struct; a json tile blob that was converted to a Matlab struct and passed as input argument
            % *Scenario 2: obj = tile(z, id, t1, t2, t3, t4, t5, t6, col,
            % row, cam, path, temca_conf, rotation, renderer_id); % the full tile configuration is expected explicitly (except for the mask which gets set separately (if at all)
            if (nargin==1 && isstruct(z))   % we are reading from a struct that was produced from json from Renderer db
                p = z;
                obj.z = p.z;
                obj.id = -999;
                obj.renderer_id = p.tileId;
                obj.H = p.height;
                obj.W = p.width;
                if isfield(p.layout, 'camera'), obj.cam = str2double(p.layout.camera);end
                if isfield(p.layout, 'imageCol'),obj.col = p.layout.imageCol;end
                if isfield(p.layout, 'imageRow'),obj.row = p.layout.imageRow;end
                if isfield(p.layout, 'rotation'),obj.rot = p.layout.rotation;end
                if isfield(p.layout, 'temca'),obj.temca_conf = str2double(p.layout.temca);end
                obj.sectionId = p.layout.sectionId;
                
                if strcmp(p.mipmapLevels.x0.imageUrl(1:4), 'file')
                    if isfield(p.mipmapLevels.x0, 'imageUrl'),
                        obj.path = p.mipmapLevels.x0.imageUrl(6:end);
                    end
                end
                if strcmp(p.mipmapLevels.x0.imageUrl(1:4), 'file')
                    if isfield(p.mipmapLevels.x0, 'maskUrl'),
                    obj.mask = p.mipmapLevels.x0.maskUrl(6:end);
                    end
                end
                % check if we have a list of transformations, in which case
                % we need
%                 if numel(p.transforms.specList)>1,
%                     p.transforms.specList = p.transforms.specList(end);
%                 end
                
                Tstr = p.transforms.specList(end).dataString;
                Tdouble    = str2double(strsplit(Tstr));

                if strcmp(p.transforms.specList(end).className, 'mpicbg.trakem2.transform.AffineModel2D')
                    T(3,3) = 1;
                    T(1,1) = Tdouble(1);
                    T(1,2) = Tdouble(2);
                    T(2,1) = Tdouble(3);
                    T(2,2) = Tdouble(4);
                    T(3,1) = Tdouble(5);
                    T(3,2) = Tdouble(6);
                    obj.tform.T = T;
                else
                    %warning('only affine implemented so far for reading from Renderer: truncating to affine');
                    if numel(Tdouble)==12 % then we have 2nd order polynpomial
                    T(3,3) = 1;
                    T(1,1) = Tdouble(2);
                    T(1,2) = Tdouble(8);
                    T(2,1) = Tdouble(3);
                    T(2,2) = Tdouble(9);
                    T(3,1) = Tdouble(1);
                    T(3,2) = Tdouble(7);
                    elseif numel(Tdouble)==20
                                           T(3,3) = 1;
                    T(1,1) = Tdouble(2);
                    T(1,2) = Tdouble(12);
                    T(2,1) = Tdouble(3);
                    T(2,2) = Tdouble(13);
                    T(3,1) = Tdouble(1);
                    T(3,2) = Tdouble(11);
                    end
                    obj.tform.T = T;
                end
            end
            if nargin>1
                obj.z = z;
                obj.id = id;
                T = zeros(3,3);
                T(3,3) = 1;
                T(1,1) = t1;
                T(2,1) = t2;
                T(3,1) = t3;
                T(1,2) = t4;
                T(2,2) = t5;
                T(3,2) = t6;
                obj.tform.T = T;
                obj.col = col;
                obj.row = row;
                obj.cam = cam;
                obj.path = path;
                obj.temca_conf = -999;
                obj.rot = 0;
                if nargin>12
                obj.temca_conf = temca_conf;
                end
                if nargin>13
                obj.rot = rotation;
                end
                if nargin>14
                    obj.renderer_id = renderer_id;
                end
                %if ~exist(obj.path,'file'), disp(['Tile not found: ' obj.path]);end
            end
        end
        %% 
        function im = get_mask(obj)
            try
            im = [];
            if ~isempty(obj.mask)
                im = imread(obj.mask);
            end
            catch err_mask
                disp('Error retrieving mask');
            end
        end
        
        %% image retrieval
        function im = get_image(obj, filter, scale)
            % will just read the path if obj.fetch_local==1
            % will use the renderer client script if obj.fetch_local==0;
            % will ask the renderer service to render if obj.fetch_local == -1
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if nargin<2, filter='false';end
            if nargin<3, scale = 1.0;end
            
            % below will set filter to true if any other filter (for post-filtering)
            % is selected. Will set all filters to false if filter == 'false'
            if nargin>=2 && ~strcmp(filter, 'false')
                post_filter = filter;
                filter = 'true';
            else
                post_filter = 'false';
                filter = 'false';
            end
            
            if obj.fetch_local==1
                im = imread(obj.path);
            elseif obj.fetch_local==0
                im = get_image_renderer_client(obj,scale, filter);
            elseif obj.fetch_local == -1
              im = get_image_renderer(obj, 1.0, filter);
            end
            if nargin==2 && ~isempty(im)
                if strcmp(post_filter, 'bkgrd1')
                    im = background_filter(im,1);
                elseif strcmp(post_filter, 'bkgrd2')
                    im = background_filter(im,2);
                elseif strcmp(post_filter, 'bkgrd3')
                    im = background_filter(im,3);
                elseif strcmp(post_filter, 'histeq')
                    im = histeq(im);
                elseif strcmp(post_filter, 'imadjust')
                    im = imadjust(im);
                end
            end
            %mask = get_mask(obj);
            %im(~mask) = 0;
        end
        %% Rendering by invoking a local client
        function im = get_image_renderer_client(obj, scale, filter)
            % filter must be a string, either "true" or "false"
%             url = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/render-parameters?scale=%s&filter=%s',...
%                 obj.server, obj.owner, obj.project, obj.stack, obj.renderer_id, num2str(scale), filter);
            exclude_mask = 'true';
            url = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/render-parameters?scale=%.1f&filter=%s&excludeMask=%s&normalizeForMatching=true',...
                obj.server, obj.owner, obj.project, obj.stack, obj.renderer_id, scale, filter, exclude_mask);

            fn = [obj.dir_temp_render '/tile_image_' num2str(randi(1000)) '_' obj.renderer_id '.jpg'];
            % we will try four times
            cmd = sprintf('%s --memory 7g --out %s --parameters_url "%s"', obj.renderer_client, fn, url);
            [a, resp_str] = system(cmd);
            file_ready = 0;
            count = 1;
            while ~(file_ready) && count<400
                pause(0.01);
                file_ready = [exist(fn,'file')==2];
                count = count + 1;
            end
            try
                pause(1.0);
                im = imread(fn, 'jpg');
            catch err_reading_image
                kk_disp_err(err_reading_image);
                disp('Retrying');
                pause(1.0);
                try
                im = imread(fn, 'jpg');
                catch err_reading_image2
                    disp('Giving up');
                    im = [];
                end
            end
            if size(im,3)==3
                im = rgb2gray(im);
            end
            try
                delete(fn);
            catch
            end
        end
        %% use Renderer service to fetch the image
        function im = get_image_renderer(obj, scale, filter)
            % filter must be a string, either "true" or "false"
            warning('Rendering server-side is not recommended');
            %url = 'http://tem-services.int.janelia.org:8080/render-ws/v1/owner/flyTEM/project/FAFB00/stack/v5_acquire/tile/150127175351050044.3826.0/scale/1.0/jpeg-image?filter=true';
            url = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/jpeg-image?scale=%s&filter=%s',...
                obj.server, obj.owner, obj.project, obj.stack, obj.renderer_id, num2str(scale), filter);

            options = weboptions('Timeout', 60);
            % we will try four times
            try
                im = webread(url, options);
            catch err_fetch_01
                disp('Try 1 failed: retrying');
                kk_disp_err(err_fetch_01);
                pause(1);
                try
                    im = webread(url,options);
                catch err_fetch_02
                    disp('Try 2 failed: retrying');
                    kk_disp_err(err_fetch_02);
                    pause(10);
                    try
                        im = webread(url,options);
                    catch err_fetch_03
                        disp('Try 3 failed: retrying');
                        kk_disp_err(err_fetch_03);
                        pause(15);
                        try
                        im = webread(url,options);
                        catch err_fetch_04
                            disp('Try 4 failed: giving up');
                            kk_disp_err(err_fetch_04);
                            error('Not able to fetch image from service');
                        end
                    end
                end
            end
            im = rgb2gray(im);
        end
        
        %%
        function [im,R] = get_warped_image(obj, scale)
            if nargin<2, scale = 1.0;end
            warning('"get_warped_image" is obsolete: using get_image_renderer unless fetching raw image from disk');
            R = [];
            if obj.fetch_local
                if ~exist(obj.path,'file'),
                    disp(['Tile not found: ' obj.path]);
                    im = [];
                else
                    %%% deal with case when tile is polynomial
                    if strcmp(class(obj.tform), 'images.geotrans.PolynomialTransformation2D') ...
                            ||strcmp(class(obj.tform), 'nonlin2d')
                        px = obj.W/2;
                        py = obj.H/2;
                     
                        bo = [0 0;obj.W 0;0 obj.H;obj.W obj.H];
                        p = transformPointsInverse(obj.tform,bo);
                        Wbox = [min(p(:,1)) min(p(:,2)) max(p(:,1))-min(p(:,1)) max(p(:,2))-min(p(:,2))];
                        disp('Warning: Scale is set at 0.2');
                        [im] =  render_poly_03(obj, scale, Wbox, 0, 0, [],[]);
                    else
                        [im,R] = imwarp(imread(obj.path), obj.tform, 'Interp', 'cubic');
                    end
                end
            else
                im = get_image_renderer(obj, 1.0, 'true');
            end
        end
        function url = get_url(obj)
            % returns the Renderer URL to be consumed by the Renderer service API
            url = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/render-parameters?filter=true',...
                obj.server, obj.owner, obj.project, obj.stack, obj.renderer_id);
        end
        function im = show(obj, filter)
            if nargin<2, filter = 'true';end
            warning off;
            im = get_image(obj, filter);
            imshow(im);
            warning on;
        end
        function im = show_warped(obj)
             warning off;
            im = get_warped_image(obj);
            imshow(im);
            warning on;
        end
        function F = show_fft(obj)
            F = fftshift(fft2(get_image(obj))); % Center FFT
            F = abs(F); % Get the magnitude
            F = log(F+1); % Use log, for perceptual scaling, and +1 since log(0) is undefined
            F = mat2gray(F); % Use mat2gray to scale the image between 0 and 1
            imshow(F,[]); % Display the result
        end
        function obj = set_info(obj)
            if obj.H==0,
                if ~isempty(obj.path)
                info = imfinfo(obj.path);     % slow
                obj.H = info.Height;
                obj.W = info.Width;
                end
            end
        end
    end
end