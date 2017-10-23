classdef Msection
    % Msection  Summary:
    %           Represents a collection of image tiles that are (partially)
    %           overlapping. These can be one section (all have the same z)
    %           or span mutiple sections, in which case z is that of the
    %           first tile.
    %
    % Msection  Class variables:
    %   z                       - the z coordinate value
    %   tiles                   - array of tile objects
    %   A                       - adjacency matrix (sparse)
    %   method                  - the tile-tile registration method ('alignTEM')
    %
    % Msection  Class Instantiation:
    %           *Scenario 1: obj = Msection();                              %  no arguments: empty Msection object
    %           *Scenario 2: obj = Msection(rc, z);                         %  rc is a struct that defines a renderer collection. z is z-value in the renderer collection
    %           *Scenario 3: obj = Msection(tile_array);                    %  tile_array = array of tile objects
    %           *Scenario 4: obj = Msection(layout_original, z);            %  arg1 = full layout file path, arg2 = z section desired
    %
    % Msection  Example usage:
    %           >fn = '/scratch/myexperiments/layoutdata/layout.txt';       % full UNIX path to layout file
    %           >z = 2299;                                                  % select a 'z' section
    %           >L = Msection(fn,z);                                        % create the Msection object with tile information from 'z'
    %           >rL = register(L);                                          % perform registration (stitching) of tiles using currently configured   method
    %           >report(rL);                                                % generate a report summary of registration process
    %           >layer_explorer(rL);                                        % explore registration feedback, errors and perform rudementary editing
    %
    % Msection  Class methods (public):
    %           register
    %           report
    %           show_map                                                    % shows cartoon (rectangles) of the section layout
    %           show_map_tile                                               % shows neighborhood (connections) of a particular tile
    %           show_tile                                                   % shows the image of the tile and its neighbors overlayed
    %           mi_calc                                                     % calculates the mutual information criterion for each adjacent pair of tiles
    %           add_tile
    %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        z;                              % the z id (numeric a la Karsh) as it appears in the layout file
        stackID = 0;                    % identifying the section as belonging to stack with same ID
        sectionID;                      % Unique ID appearing in the renderer databasse
        tiles;                          % array of tiles
        G;
        A;                              % adjacency matrix
        original_layout_file = [];      % fully qualified unix path to layout file
        method = 'alignTEM';            % use alignTEM alignment method as default
        viewer = 'matlab';            % select which viewer to use to look at layer -- 'renderer' or 'matlab' ;
        regConf = [];                   % struct for the registration method configuration
        rprt = [];                      % struct to store all registration reports
        tile_show_limit = 20;           % limit of number of tiles to open when show_tile is called
        tile_show_method = 'overlay';   % method used to display the tiles -- default: overlay
        update_adjacency_switch = 1;    % switch indicating 1--> update adjacency matrix, 0 --> not needed
        update_tile_info_switch = -1;   % 1: update each tile individually one time, 0: no need to update, -1: update all to the data in the first tile
        map_display_fac = 1;            % size factor for rectangles representing tiles
        map_id;                         % maps: 'id' to index into the 'tiles' array
        map_renderer_id;                % maps: 'renderer_id' to index into 'tiles' array
        mosaic = [];                    % mosaic image of all tiles
        T = [1 0 0;0 1 0;0 0 1];        % generic identity transform
        X, Y, box;                      % housekeeping arrays
        pm;                             % point-matches struct
        n_points_pair_same = 10;        % number of points to generate for each image pair in a forward transformation (used by get_point_pairs);
        dthresh_factor = 1.2;           % factor for adjacency calculation. Adjacent tiles have a center that is diagonal*dthresh_fac removed from the center of the tile
        edge_tiles = [];                % logical vector of length numel(obj.tiles) to indicate edge tiles = 1 or non-edge = 0;
    end
    
    methods
        
        function obj = Msection(arg1, arg2, arg3)   % constructor
            % *Scenario 1: obj = Msection(); %no arguments: empty Msection object
            % *Scenario 2: obj = Msection(rc, z); %  rc is a struct that defines a renderer collection. z is z-value in the renderer collection
            % *Scenario 3: obj = Msection(tile_array); %  tile_array = array of tile objects
            % *Scenario 4: obj = Msection(layout_original, z); %arg1 = full layout file path, arg2 = z section desired
            % *Scenario 5: obj = Msection(rc, zstart, zfinish); % gets at range of z's into one Msection object
            if nargin~=0
                
                %%%% generate Msection object from array of tile objects
                if nargin==1
                    %%% in this case we are given an array of tiles
                    obj.z = arg1(1).z; % use z value provided in first tile
                    obj.tiles = arg1;
                    obj.original_layout_file = [];
                    obj = update_adjacency(obj);
                    obj = generate_hash_tables(obj);
                end
                
                %%%% import from renderer database
                if nargin==2 && isstruct(arg1)    % then we construct a section based on renderer information
                    % % Example rc (arg1)
                    % % rc.stack = 'v9_acquire_LC_merged_2';
                    % % rc.owner='flyTEM';
                    % % rc.project='FAFB00';
                    % % rc.server='http://tem-services.int.janelia.org:8080/render-ws/v1';
                    rc = arg1;
                    z  = arg2; % is the z position of the section
                    webopts = weboptions('TimeOut',30);
                    % % get a list of all tiles
                    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
                        rc.baseURL, rc.owner, rc.project, rc.stack, (z));
                    try
                    j = webread(urlChar, webopts);
                    catch err_reading
                        kk_disp_err(err_reading);
                        disp('Trying again...');
                        j = webread(urlChar, webopts);
                        disp('Success!');
                    end
                    % generate the tiles
                    jt = tile;
                    sectionID = j(1).layout.sectionId;
                    %disp('Loading section ... ');
                    parfor jix = 1:numel(j)
                        jt(jix) = tile(j(jix));
                        jt(jix).z = z;
                        jt(jix).project = arg1.project;
                        jt(jix).owner = arg1.owner;
                        jt(jix).stack = arg1.stack;
                    end
                    % loop over tiles to set tile id
                    parfor ix = 1:numel(jt)
                        jt(ix).id = ix;
                    end
                    obj = Msection(jt);
                    obj = update_tile_sources(obj, rc);
                    obj.sectionID = sectionID;
                    if ~isempty(obj.tiles), obj = update_tile_info(obj);end
                end
                
                %%%%%% import from layout file
                if nargin==2 && ischar(arg1)
                    %% in this case we construct a layer by directly reading the relevant z tile information from the layout file
                    obj = Msection;
                    obj = import_from_layout_txt(obj, arg1, arg2);
                    obj = generate_hash_tables(obj);
                    obj = update_adjacency(obj);
                    if ~isempty(obj.tiles), obj = update_tile_info(obj);end
                end
                %%%%%% import from Renderer collection over a range of z from arg2 to arg3
                if nargin==3 && isstruct(arg1)
                    %% in this case we construct a layer by directly reading the relevant z tile information from the layout file
                    obj = get_slab_tiles(arg1, arg2, arg3);
                    if ~isempty(obj.tiles), obj = update_tile_info(obj);end
                end
            end
            
            obj = configure_registration(obj);
            obj = tile_pos_gen(obj);
            %if nnz(obj.A)==0, warning('No adjacency information in A');end
        end
        function obj = translate_to_origin(obj, deltao)
            % mL = get_bounding_box(mL);
            if nargin==1, deltao = [0 0];end
            for ix = 1:numel(obj.tiles)
                if isa(obj.tiles(ix).tform,  'images.geotrans.PolynomialTransformation2D')
                    X(ix) = obj.tiles(ix).tform.A(1);
                    Y(ix) = obj.tiles(ix).tform.B(1);
                    
                else
                    X(ix) = obj.tiles(ix).tform.T(3);
                    Y(ix) = obj.tiles(ix).tform.T(6);
                    
                end
            end
            
            delta = -(5000 + max([obj.tiles(1).W obj.tiles(1).H]));
            dx = min(X(:)) + delta;%mL.box(1);
            dy = min(Y(:)) + delta;%mL.box(2);
            tiles = obj.tiles;
            for ix = 1:numel(tiles)
                if isa(obj.tiles(ix).tform,  'images.geotrans.PolynomialTransformation2D')
                    A = tiles(ix).tform.A;
                    B = tiles(ix).tform.B;
                    tform = tiles(ix).tform;
                    A(1) = A(1)-dx-deltao(1);
                    B(1) = B(1)-dy-deltao(2);
                    tform = images.geotrans.PolynomialTransformation2D(A,B);
                    tiles(ix).tform = tform;
                    
                else
%                 tiles(ix) = translate_tile(tiles(ix), [dx dy]);
                tiles(ix).tform.T([3 6]) = tiles(ix).tform.T([3 6])-[dx dy] - deltao;
                end
            end
            obj.tiles = tiles;
            
        end
    end
end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
