function [width, height] = get_section_bounds_stack(rc,zrange)
%% find section-based bounds for a collection

nfirst = zrange(1);
nlast = zrange(2);

% % configure fixed collection
% rc.stack          = ['kk_13_pm7'];
% rc.owner          ='flyTEM';
% rc.project        = 'FAFBv14_kk';
% rc.service_host   = '10.40.3.162:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 0;

width = [];
height = [];
parfor z = nfirst:nlast
    try
    [Wbox, ~, ~] = get_section_bounds_renderer(rc, z);
    width(z) = Wbox(3);
    height(z) = Wbox(4);
    catch err_get_box
        disp(z);
    end
end
    