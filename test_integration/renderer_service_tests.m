function pass = renderer_service_tests(rc_base, rc)
% This function should only be executed when in ~/EM_aligner/unit_tests directory
% It assumes existence of a populated ~/EM_aligner/test_data/Msection_objects directory
% configure a Renderer-collection struct rc
% create a collection
% read an Msection object from test_data, 
% populate the collection with these tiles
% "complete" collection
% delete the collection
%
% output: pass should have the value 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pass = 0;
% base collection
% rc_base.owner             = 'flyTEM';
% rc_base.project           = 'FAFB00';
% rc_base.stack             = 'v12_acquire_merged';
% rc_base.service_host      = '10.37.5.60:8080';    % use of ip adress is preferred (no DNS lookup)--Note: 10.37.5.60 is a VM, 10.40.3.162 is tem-services
% rc_base.baseURL           = ['http://' rc_base.service_host '/render-ws/v1']; 
% rc_base.verbose           = 1;
% 
% % target collection
% rc.owner                  = 'flyTEM';
% rc.project                = 'test';
% rc.stack                  = 'UnitTest_collection';
% rc.service_host           = '10.37.5.60:8080';    % use of ip adress is preferred (no DNS lookup)--Note: 10.37.5.60 is a VM, 10.40.3.162 is tem-services
% rc.baseURL                = ['http://' rc.service_host '/render-ws/v1']; 
% rc.verbose                = 1;

%% create a new stack (collection)
disp('Creating new collection:');
disp(rc);
resp = create_renderer_stack(rc);
disp(resp);

pass = pass + 1;
pause(1);


%% load some tiles
load('../test_data/Msection_objects/Msection_region_FAFBv12_section_4_montage.mat'); % loads variable L

%% append tiles to collection
% translate to origin
% generate MET file name
% export to MET format
% 
L = translate_to_origin(L);
fn = [pwd '/X_A_' num2str(randi(1000000)) '.txt'];
export_MET(L, fn, 2, 2, 0);
v = 'v1';

disp('Appending tiles to collection');
resp = append_renderer_stack(rc, rc_base, fn, v);
disp(resp);
try delete(fn); catch err_delete, kk_disp_err(err_delete);end

pass = pass + 1;
%% complete the collection
disp('Completing collection.');
resp = renderer_stack_state_complete(rc);
disp(resp);

pass = pass + 1;
%% delete the stack (collection)
disp('Deleting collection: ');
disp(rc);
resp = delete_renderer_stack(rc);
disp(resp);

pass = pass + 1;
