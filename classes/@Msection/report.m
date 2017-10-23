function obj = report(obj)
% Report results of in-layer montage according to the selected method.
%
% Usage: obj = report(obj)
% the property obj.method determines the registration and reporting function.
% 
% 
% *Available methods:
% 'alignBK',          ---> BK pipeline (implemented by calling BK binaries)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(obj.method, 'alignBK')               % use first part of BK pipeline
    obj = alignBK_report(obj);
else
    disp('Method not recognized');
end