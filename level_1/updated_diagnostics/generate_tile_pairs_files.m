function generate_tile_pairs_files( rc, zs, parent_directory, cross_distance )
%--------------------------------------
% set up global parameters
%--------------------------------------
if nargin<4
    cross_distance = 50; 
end

if isempty(zs)
   zs = get_section_ids(rc); 
end
stack_min_z=zs(1);                           % minimum z value for layers to include in potential tile pairs 
stack_max_z=zs(end);            % maximum z value for layers to include in potential tile pairs


% base command for running the tile pair client
base_cmd='/groups/flyTEM/flyTEM/render/pipeline/bin/run_ws_client.sh 1G org.janelia.render.client.TilePairClient';
system('mkdir -p logs');

%--------------------------------------
% genrate within-layer and outside-layer potential pairs
%--------------------------------------

% z-res is 2, 4 layers for 8

% xyNeighborFactor is used to determine radial distance from tile center to look for potential pairs
%David Ackermand: adding --excludePairsInMatchCollection flag so that only those missing tile pairs are checked

p1=sprintf('--baseDataUrl http://10.40.3.162:8080/render-ws/v1 --owner %s --project %s', rc.owner, rc.project);
p2=sprintf('--baseOwner %s --baseProject %s --baseStack %s --stack %s', rc.owner, rc.project, rc.stack, rc.stack);

for cross=0:1
    if cross
        z_step=1000;
        filter_opts='--xyNeighborFactor 0.1 --excludeCornerNeighbors false --excludeSameLayerNeighbors true --excludeCompletelyObscuredTiles true';
        pair_gen_log=['logs/tile_pairs-' datestr(datetime(),'yyyymmdd_HHMMss') '.log'];
        system(['mkdir -p ' parent_directory '/pairs_cross']);
        pairs_dir = [parent_directory '/pairs_cross'];
        distance=cross_distance;
    else
        z_step=5000;
        filter_opts='--xyNeighborFactor 0.6 --excludeCornerNeighbors false --excludeSameLayerNeighbors false --excludeCompletelyObscuredTiles true';
        pair_gen_log=['logs/tile_pairs-' datestr(datetime(),'yyyymmdd_HHMMss') '.log'];
        pairs_dir = [parent_directory '/pairs_montage'];
        system(['mkdir -p ' parent_directory '/pairs_montage']);
        distance=0;                             % distance in z from each layer to look for potential tile pairs
    end
    z_starts = stack_min_z: z_step:stack_max_z-1;
    parfor i=1:numel(z_starts)
        z=z_starts(i);
        min_z=z;
        max_z=z + z_step + distance;  % ensure overlap
        p3=sprintf('--minZ %s --maxZ %s',num2str(min_z), num2str(max_z));
        json=sprintf('%s/tile_pairs_%s_z_%6.6d_to_%6.6d_dist_%s.json.gz', pairs_dir, rc.stack, min_z, max_z, num2str(distance));       
        system([base_cmd ' ' p1 ' ' p2 ' ' p3 ' ' filter_opts ' --zNeighborDistance '  num2str(distance) ' --toJson ' json ' | tee -a ' pair_gen_log]);
    end
end


end

