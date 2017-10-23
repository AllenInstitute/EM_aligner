function str = view_collection_dashboard(rc)

str1 = sprintf('http://%s/render-ws', rc.service_host);

str = sprintf('%s/view/stack-details.html?owner=%s&project=%s&stack=%s&dynamicRenderHost=renderer%%3A8080&catmaidHost=renderer-catmaid%%3A8000;',...
    str1, rc.owner, rc.project, rc.stack);
web(str);
%Example: 'http://tem-services.int.janelia.org:8080/render-ws/view/stack-details.html?owner=flyTEM&project=test&stack=EXP_test_montage_solver_1&dynamicRenderHost=renderer%3A8080&catmaidHost=renderer-catmaid%3A8000;