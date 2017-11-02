%  collection fusion of rough alignment

clc;%clear all;

Fine_align_slab_definition;
kk_clock;

%%
for ix = 2:78

    
    if ix<2
        error('ix must be larger than or equal to 2');
    elseif ix==2
        %  use the first collection as fixed
        rcfixed                = rough_collection{1};%fine_collection{1};
    else
        rcfixed                = rcfixed_o;
    end
    % configure collection
    rcmoving                = fine_collection{ix};
    % configure output collection
    rcout                  = rcfixed_o;
    overlap = overlapvec(ix-1,:);
    
    
    %%%% just to check
    disp('-----------------------');
    disp(['Processing slab: ' num2str(ix)]);
    disp('-----------------------');
%     disp('Fixed:');disp(rcfixed);
%     disp('Moving:');disp(rcmoving);
%     disp('Out:');disp(rcout);
%     disp('Overlap:');disp(overlap);
%     disp('-----------------------');
    %%
    if ix ==2,
        collection_start = 1;
    else
        collection_start = 0;
    end
    [resp]= fuse_collections(rcsource, rcfixed, rcmoving, overlap, rcout, collection_start);
    
end
kk_clock;

%%
[mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, tidsvec] =...
    gen_section_based_tile_deformation_statistics(rcout, 1, 1000);
% delete_renderer_stack(rcout);
