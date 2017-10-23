function res = stack_exists(rc)
% returns 1 if stack exists, 0 otherwise
%
% Depends on Eric T.'s Renderer service
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

urlChar = sprintf('%s/owner/%s/project/%s/stack/%s', rc.baseURL, rc.owner, rc.project, rc.stack);

try
    web_resp = webread(urlChar);
    res = 1;
catch err_stack
    %kk_disp_err(err_stack);
    res = 0;
end
    
