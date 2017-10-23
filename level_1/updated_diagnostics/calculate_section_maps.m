function  all_section_maps = calculate_section_maps(rc, zstart, zend, unique_z)
%% Generate section maps
% Calculates tile positions, using source renderer collection rcsource,
% renderer collection rc, zstart and zend.
% Output:
%   all_section_maps        Contains tile positions for all tiles in each section
% Author: Khaled Khairy, David Ackerman
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<4
    % Get the unique_z values and the section ids grouped by their z
    [unique_z, ~, ~, ~, ~] = get_section_ids(rc, zstart, zend);
end
% Initialize variables to store deformation for all sections
numel_unique_z = numel(unique_z);
all_section_maps  = cell(numel_unique_z,1);

webopts = weboptions('Timeout', 60);

% Loop over all unique z and print out progress
fprintf('Section Maps Progress:');
fprintf(['\n' repmat('.',1,numel(unique_z)) '\n\n']);
parfor z_index = 1:numel(unique_z)
    % call the Renderer API to fetch tile information from rc and rcsource
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
        rc.baseURL, rc.owner, rc.project, rc.stack,unique_z(z_index) );
    rc_data = webread(urlChar, webopts);
    
    % Initialize variables to store deformations for one section
    numel_rc_data = numel(rc_data);
    rc_positions_transformed = cell(numel_rc_data,1);
   
    % Loop over all rc tiles and calculate their deformed positions
    for rc_tile_index = 1:numel(rc_data)
        rc_tile = tile(rc_data(rc_tile_index));
        % make four corners for the tile
        x = 0;
        y = 0;
        rc_tile_position_x = [x; x + rc_tile.W; x + rc_tile.W; x];
        rc_tile_position_y = [y; y    ; y + rc_tile.H; y + rc_tile.H];
        %%% transform points
        if strcmp(class(rc_tile.tform), 'affine2d')
            rc_tile_position_transformed = [rc_tile_position_x(:) rc_tile_position_y(:) [1 1 1 1]']*rc_tile.tform.T;
        else
            rc_tile_position_transformed = transformPointsInverse(rc_tile.tform,[rc_tile_position_x Py]);
        end
        rc_positions_transformed{rc_tile_index} = {rc_tile_position_transformed};
    end
    % Calculate histogram and store section data in variable for all sections
    all_section_maps{z_index} = rc_positions_transformed;
    fprintf('\b|\n');
end

end

