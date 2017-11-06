function [err_sections] = filter_section_tiles_from_to(rc_filter_source, rctarget, rcsource, z, dir_temp, lambda)
% removes all tiles whose area (transformed) / area untransformed,
% deviates more than lambda. lambda is typically (default) 0.05

if nargin<4
    lambda = 1.0;
end
err_sections = zeros(numel(z),1);
verbose = 1;
translate_to_positive_space = 0;
complete = 0;
disableValidation = 0;

if numel(z)>32
    parfor_progress(numel(z));
    parfor zix = 1:numel(z)
        try
            L = Msection(rc_filter_source, z(zix)); % read the section with z-value z
            %     [L] = filter_based_on_tile_area(L, lambda);
            if isautoloader(rcsource, z(zix))
                center = 1.15;
            else
                center = 1.0;
            end
            [L, A, S, indx, delIds] = filter_based_on_tile_area_threshold(L, lambda, center);
            indx = [L.tiles(:).state];
            L.tiles((indx==-3))=[];
            
            delete_renderer_section(rctarget, z(zix), 0);
            ingest_section_into_renderer_database(L, rctarget, rcsource, dir_temp, ...
                translate_to_positive_space, complete, disableValidation);
        catch err_filter
            kk_disp_err(err_filter);
            err_sections(zix) = 1;
        end
        parfor_progress;
    end
    parfor_progress(0);
else
    for zix = 1:numel(z)
        try
            L = Msection(rc_filter_source, z(zix)); % read the section with z-value z
            %     [L] = filter_based_on_tile_area(L, lambda);
            if isautoloader(rcsource, z(zix))
                center = 1.12;
            else
                center = 1.0;
            end
            [L, A, S, indx, delIds] = filter_based_on_tile_area_threshold(L, lambda, center);
            indx = [L.tiles(:).state];
            L.tiles((indx==-3))=[];
            
            delete_renderer_section(rctarget, z(zix), 0);
            ingest_section_into_renderer_database(L, rctarget, rcsource, dir_temp, ...
                translate_to_positive_space, complete, disableValidation);
        catch err_filter
            kk_disp_err(err_filter);
            err_sections(zix) = 1;
        end
    end
    
    
    
end

if sum(err_sections)
    disp('the following sections had errors during filtering');
    disp(z(find(err_sections)));
end