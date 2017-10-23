function write_trakem2_xml(newxml, p, tls, tl, tp)
%% this function assumes one project and one layer set
% Under construction -- use with caution
% Author: Khaled Khairy (JFRC SiComp)

docNode = com.mathworks.xml.XMLUtils.createDocument('trakem2');
docRootNode = docNode.getDocumentElement;
% docRootNode.setAttribute('attr_name','attr_value');
%% add the project
project = docNode.createElement('project');
project = populate_attributes(p,project);
docRootNode.appendChild(project);

%% add the t2_layer_set
tls_elem = docNode.createElement('t2_layer_set');
tls_elem = populate_attributes(tls,tls_elem);
docRootNode.appendChild(tls_elem);

% %% add the t2_calibration
% tc_elem = docNode.createElement('t2_calibration');
% tc_elem = populate_attributes(tc,tc_elem);
% tls_elem.appendChild(tc_elem);


%% add the t2_layer (s)
for lyrix = 1:numel(tl)
    tl_elem = docNode.createElement('t2_layer');
    tl_elem = populate_attributes(tl(lyrix),tl_elem);
    
    if isa(tl(lyrix).z,'char')  
        z = str2double(tl(lyrix).z);
    else
        z = tl(lyrix).z;
    end
    if isfield(tp(1), 'layer_id')
    indx = logical(z==[tp(:).layer_id]);  % assumes that z for tile is layer_id
                                          % bad for case where tiles can
                                          % have different layer ids than
                                          % the z of tl.
    else
        indx = logical(z==[tp(:).TLid]);
    end
%     %%%% sosi -----> needs improvement to circumvent the for-loop

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lyr_patches = tp(logical(indx));
    for pix = 1:numel(lyr_patches)
        pat_elem = docNode.createElement('t2_patch');
        pat_elem = populate_attributes(lyr_patches(pix), pat_elem);
        tl_elem.appendChild(pat_elem);
    end
    tls_elem.appendChild(tl_elem);
end

%% save the file
xmlwrite('temp.txt',docNode);

%% delete first line and then prepend with trakem2 specific text: -- this is not elegant but matlab has limitations on xmlwrite
fid = fopen('temp.txt','rb');
fgetl(fid);
str = textscan(fid, '%s');      % generates a cell array of strings
x = str{1};
% write this to a new temporary file
fid=fopen(newxml,'wt');
for i=1:numel(x)
         fprintf(fid,'%s\n',x{i});
end
fclose(fid);

fid = fopen( 'trakem2_prepend.txt', 'rb' );
str = fread(fid, [1, inf], 'char');
fclose(fid);
prepend2file(str, newxml, 1);
%%
function prepend2file( string, filename, newline )
%newline:  is an optional boolean, that if true will append a \n to the end 
% of the string that is sent in such that the original text starts on the 
% next line rather than the end of the line that the string is on 
% string:  a single line string 
% filename:  the file you want to prepend to 
      tempFile = 'kk_temp.txt';
      fw = fopen( tempFile, 'wt' );
      if nargin < 3
          newline = false;
      end
      if newline
          fwrite( fw, sprintf('%s\n', string ) );
      else
          fwrite( fw, string );
      end
      fclose( fw );
      appendFiles( filename, tempFile );
      copyfile( tempFile, filename );
      delete(tempFile);
%% append readFile to writtenFile
function status = appendFiles( readFile, writtenFile )

      fr = fopen( readFile, 'rt' );

      fw = fopen( writtenFile, 'at' );

      while feof( fr ) == 0

          tline = fgetl( fr );

          fwrite( fw, sprintf('%s\n',tline ) );

      end

      fclose(fr);

      fclose(fw);
%%
function element = populate_attributes(S, element)

info_fields = fieldnames(S);
for ix = 1:numel(info_fields)   % loop over the fields we need
    if ~isempty(getfield(S,info_fields{ix}))
  element.setAttribute(info_fields{ix}, num2str(getfield(S,info_fields{ix})));
    end
end


























