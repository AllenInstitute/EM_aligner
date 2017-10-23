function res = stack_read_only(rc)
% returns 1 if stack COMPLETE, 0 if not (this could also be the case
% if the stack does not exist)
%
% Depends on Eric T.'s Renderer service
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

urlChar = sprintf('%s/owner/%s/project/%s/stack/%s', rc.baseURL, rc.owner, rc.project, rc.stack);

try
    web_resp = webread(urlChar);
    if strcmp(web_resp.state, 'READ_ONLY')
        res = 1;
    else
        res = 0;
    end
    
catch err_stack
    kk_disp_err(err_stack);
    res = 0;
end

