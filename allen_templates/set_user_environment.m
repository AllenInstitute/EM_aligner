function sl = set_user_environment(sl)

%always write to your own stacks
sl.target_collection.owner = getenv('USER');

%where to put log files
sl.solver_options.logging.logroot = getenv('EMA_LOGROOT');

%what render bin path to use
sl.source_collection.renderbinPath = getenv('EMA_RENDERBINPATH');
sl.target_collection.renderbinPath = getenv('EMA_RENDERBINPATH');

%service host
sl.source_collection.service_host = getenv('EMA_SERVICE_HOST');
sl.target_collection.service_host = getenv('EMA_SERVICE_HOST');
urlstr = strcat('http://',sl.source_collection.service_host,'/render-ws/v1');
sl.source_collection.baseURL = urlstr;
sl.target_collection.baseURL = urlstr;
sl.source_point_match_collection.server = urlstr;