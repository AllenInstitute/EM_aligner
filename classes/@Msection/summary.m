function obj = summary(obj)
%% summarize information about this layer
disp('------------- Layer summary -----------');
str = sprintf('Layer id: %d', obj.z);disp(str);
sm1 = 0;
s0  = 0;
s1  = 0;
for tix = 1:numel(obj.tiles),
    if obj.tiles(tix).state ==-1, sm1 = sm1+1;end
    if obj.tiles(tix).state ==0, s0 = s0+1;end
    if obj.tiles(tix).state ==1, s1 = s1+1;end
end
str = sprintf('Number of inlayer montaging rejections   : %d', sm1);disp(str);
str = sprintf('Number of crosslayer montaging rejections: %d', s0);disp(str);
str = sprintf('Number of active tiles                   : %d', s1);disp(str);
disp('-----------------------------');
disp('-------- Configuration: alignBK -----------');
disp('bin');disp(obj.regConf.alignBK.bin);
disp('dir_work');disp(obj.regConf.alignBK.dir_work);
disp('dir_parameter_files_layout');disp(obj.regConf.alignBK.dir_parameter_files_layout);
disp('layout_inname');disp(obj.regConf.alignBK.layout_inname);
disp('dir_parameter_files_matchparam');disp(obj.regConf.alignBK.dir_parameter_files_matchparam);
disp('dir_idb');disp(obj.regConf.alignBK.dir_idb);
disp('dir_montage');disp(obj.regConf.alignBK.dir_montage);
disp('scriptparams');disp(obj.regConf.alignBK.scriptparams);

disp('lsq_montage_temp');disp(obj.regConf.alignBK.lsq_montage_temp);
disp('job_out_option');disp(obj.regConf.alignBK.job_out_option);
disp('account');disp(obj.regConf.alignBK.account);



if ~isempty(obj.rprt)
    if ~isempty(obj.rprt.alignBK)
        disp('------------- alignBK montage results information -----------');
        if isfield(obj.rprt.alignBK, 'error')
        str = sprintf('Number of make-montages errors: %d', (obj.rprt.alignBK.error.makemontages));disp(str);
        str = sprintf('Number of pairwise registration (ssub) errors: %d', (obj.rprt.alignBK.error.pairwise_registration_ssub));disp(str);
        end
        if isfield(obj.rprt.alignBK, 'layer')
            str = sprintf('Number of psame errors: %d', (obj.rprt.alignBK.layer.errcount_pairwise));disp(str);
            str = sprintf('Number of psame files: %d', numel(obj.rprt.alignBK.layer.psame));disp(str);
        end
        if isfield(obj.rprt.alignBK, 'pair_data')
            str = sprintf('Number of pairs: %d', numel(obj.rprt.alignBK.pair_data));disp(str);
        end
    end
end