function [resp, url] = delete_point_match_collection(pm)
% % example point-match struct
% pmfine.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pmfine.owner            = 'loogerl';
% pmfine.match_collection = 'mouse_371726_dapi_intensity_fine_04';


url = sprintf('%s/owner/%s/matchCollection/%s',...
    pm.server, pm.owner, pm.match_collection);

str = ['curl -X DELETE --header "Accept: application/json" "' url '"'];%http://tem-services.int.janelia.org:8080/render-ws/v1/owner/loogerl/matchCollection/mouse_371726_dapi_intensity_fine_04"';
try
resp = system(str);

catch err_pm_delete
    kk_disp_err(err_pm_delete);
end