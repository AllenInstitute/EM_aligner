function js0 = pairs2json(MP, fn)
%%%% Generate json for the point-matches database
%%%% MP is a cell array of structs. Each MP{i} is a struct with fields:
%%%% pz (int/double), pID(string), qz(int/double), qID(string), p(nx1 array
%%%% of doubles), q(nx1 array of doubles), w(nx1 array of doubles), where n
%%%% is the number of point-matches between the two members of the pair i.
%%%% Author: Khaled Khairy (Matlab interface) / Eric Trautman (database API)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% export into json format: Example provided below
% % % % [
% % 	{
% % 		"pGroupId": 5000, "pId": "141105110201045084.5000.0", "qGroupId": 5000, "qId": "141105110201044084.5000.0",
% % 		"matches": {
% % 			"p": [[218.381,314.314,539.9903,637.5202,220.5199,324.0478,540.3186,651.2964,216.6469,320.9579,541.8329,649.4054,217.0877,310.6382,538.7107,643.5172],[206.6645,414.5656,199.149,416.9566,768.3255,964.2351,757.7109,963.1666,1319.6962,1524.8796,1318.303,1522.785,1880.3481,2095.9019,1872.7755,2089.9514]],
% % 			"q": [[2206.0427,2301.9486,2527.4682,2624.9715,2208.2546,2311.7495,2527.8701,2638.812,2204.4565,2308.7354,2529.4577,2636.996,2204.9712,2298.497,2526.4105,2631.1861],[262.7627,470.6612,255.2673,473.0719,824.4008,1020.3087,813.8063,1019.2603,1375.7485,1580.9299,1374.3754,1578.8555,1936.3774,2151.9281,1928.8249,2145.9982]],
% % 			"w": [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
% % 		}
% % 	},
% % 	{
% % 		"pGroupId": 5000, "pId": "141105110201045084.5000.0", "qGroupId": 5000, "qId": "141105110201045083.5000.0",
% % 		"matches": {
% % 			"p": [[551.472,727.4471,1141.4178,1320.3223,1751.3955,1941.3025,2338.6354,2542.889],[152.873,298.1803,147.6203,299.8514,155.4318,292.3579,148.013,291.6111]],
% % 			"q": [[313.4874,488.5205,905.4174,1084.9902,1518.7232,1709.7313,2109.6105,2314.9363],[1962.8206,2106.8419,1956.8254,2107.9079,1964.4591,2100.2502,1957.1487,2099.1307]],
% % 			"w": [1,1,1,1,1,1,1,1]
% % 		}
% % 	}
% % ]
js0 = [];
npairs = numel(MP);
if nargin==1
    js0 = '[';
    for mix = 1:npairs
        js1 = sprintf(...
            '\n\t{\n\t\t"pGroupId": "%s", "pId": "%s", "qGroupId": "%s", "qId": "%s",\n\t\t"matches": {\n', ...
            MP{mix}.pz, MP{mix}.pId, MP{mix}.qz, MP{mix}.qId);
        str1 = sprintf('\t\t\t"p": [[');
        for pxix = 1:size(MP{mix}.p,1)
            %             str1 = [str1 num2str(MP{mix}.p(pxix,1))];
            str1 = [str1 sprintf('%.16f', MP{mix}.p(pxix,1))];
            if pxix<size(MP{mix}.p,1), str1 = [str1 ','];end
        end
        str1 = [str1 '],['];
        
        for pix = 1:size(MP{mix}.p,1)
            %             str1 = [str1 num2str(MP{mix}.p(pix,2))];
            str1 = [str1 sprintf('%.16f', MP{mix}.p(pix,2))];
            if pix<size(MP{mix}.p,1), str1 = [str1 ','];end
        end
        str1 = [str1 ']],'];
        
        str2 = sprintf('\n\t\t\t"q": [[');
        for qix = 1:size(MP{mix}.q,1)
            %             str2 = [str2 num2str(MP{mix}.q(qix,1))];
            str2 = [str2 sprintf('%.16f', MP{mix}.q(qix,1))];
            if qix<size(MP{mix}.q,1), str2 = [str2 ','];end
        end
        str2 = [str2 '],['];
        
        for qix = 1:size(MP{mix}.q,1)
            %             str2 = [str2 num2str(MP{mix}.q(qix,2))];
            str2 = [str2 sprintf('%.16f', MP{mix}.q(qix,2))];
            if qix<size(MP{mix}.q,1), str2 = [str2 ','];end
        end
        str2 = [str2 ']],'];
        
        if ~isfield(MP{mix}, 'w')
         w = ones(size(MP{mix}.q,1),1);
        else
            w = MP{mix}.w{1};
        end
        str3 = sprintf('\n\t\t\t"w": [');
        for qix = 1:size(MP{mix}.q,1)
            %             str3 = [str3 num2str(w(qix))];
            str3 = [str3 sprintf('%.16f', w(qix))];
            if qix<size(MP{mix}.q,1), str3 = [str3 ','];end
        end
        str3 = [str3 ']'];
        if ~(mix==npairs),
            str3 = sprintf('%s\n\t\t}\n\t},', str3);
        else
            str3 = sprintf('%s\n\t\t}\n\t}', str3);
        end
        
        js0 = [js0 js1 str1 str2 str3];
        
    end
    js0 = [js0 sprintf('\n]')];
    
elseif nargin>1
    
    disp('Writing to file:');
    disp(fn);
    fid = fopen(fn, 'w');
    fprintf(fid, '[');
    for mix = 1:npairs
        js1 = sprintf(...
            '\n\t{\n\t\t"pGroupId": "%s", "pId": "%s", "qGroupId": "%s", "qId": "%s",\n\t\t"matches": {\n', ...
            MP{mix}.pz, MP{mix}.pId, MP{mix}.qz, MP{mix}.qId);
        str1 = sprintf('\t\t\t"p": [[');
        for pxix = 1:size(MP{mix}.p,1)
            %             str1 = [str1 num2str(MP{mix}.p(pxix,1))];
            str1 = [str1 sprintf('%.16f', MP{mix}.p(pxix,1))];
            if pxix<size(MP{mix}.p,1), str1 = [str1 ','];end
        end
        str1 = [str1 '],['];
        
        for pix = 1:size(MP{mix}.p,1)
            %             str1 = [str1 num2str(MP{mix}.p(pix,2))];
            str1 = [str1 sprintf('%.16f', MP{mix}.p(pix,2))];
            if pix<size(MP{mix}.p,1), str1 = [str1 ','];end
        end
        str1 = [str1 ']],'];
        
        str2 = sprintf('\n\t\t\t"q": [[');
        for qix = 1:size(MP{mix}.q,1)
            %             str2 = [str2 num2str(MP{mix}.q(qix,1))];
            str2 = [str2 sprintf('%.16f', MP{mix}.q(qix,1))];
            if qix<size(MP{mix}.q,1), str2 = [str2 ','];end
        end
        str2 = [str2 '],['];
        
        for qix = 1:size(MP{mix}.q,1)
            %             str2 = [str2 num2str(MP{mix}.q(qix,2))];
            str2 = [str2 sprintf('%.16f', MP{mix}.q(qix,2))];
            if qix<size(MP{mix}.q,1), str2 = [str2 ','];end
        end
        str2 = [str2 ']],'];
        
        if ~isfield(MP{mix}, 'w')
            w = ones(size(MP{mix}.q,1),1);
        else
            w = MP{mix}.w{1};
        end
        
        str3 = sprintf('\n\t\t\t"w": [');
        for qix = 1:size(MP{mix}.q,1)
            %             str3 = [str3 num2str(w(qix))];
            str3 = [str3 sprintf('%.16f', w(qix))];
            if qix<size(MP{mix}.q,1), str3 = [str3 ','];end
        end
        str3 = [str3 ']'];
        if ~(mix==npairs),
            str3 = sprintf('%s\n\t\t}\n\t},', str3);
        else
            str3 = sprintf('%s\n\t\t}\n\t}', str3);
        end
        
        fprintf(fid,'%s%s%s%s', js1,str1, str2, str3);
        
    end
    fprintf(fid,'\n]');
    fclose(fid);
end
