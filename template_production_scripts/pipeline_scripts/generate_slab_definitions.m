function [] = generate_slab_definitions(nfirst, nlast, slab_defs_fn, opts_fn)
    % Generate slab definitions

    %% automatic generation of rough slab definitions (sections and scale for montage scapes)
    if nargin < 1, error('Missing start section'); end
    if nargin < 2, error('Missing end section'); end
    if nargin < 3, error('Missing output file'); end

    if ischar(nfirst)
        nfirst = str2double(nfirst);
    end
    if ischar(nlast)
        nlast = str2double(nlast);
    end

    slab_options = struct();
    rs_source_opts = struct();
    rs_target_opts = struct();
    if nargin >= 4
        slab_options = loadjson(fileread(opts_fn));
        if isfield(slab_options, 'rs_source')
            rs_source_opts = slab_options.rs_source;
        end
        if isfield(slab_options, 'rs_target')
            rs_target_opts = slab_options.rs_target;
        end
    end

    rs_source_opts.stack = eval_field(rs_source_opts, 'stack', 'v14_rough', true);
    rs_source_opts.owner = eval_field(rs_source_opts, 'owner', 'flyTEM', true);
    rs_source_opts.project = eval_field(rs_source_opts, 'project', 'test2', true);
    rs_source_opts.service_host = eval_field(rs_source_opts, 'service_host', '10.40.3.162:8080', true);
    rs_source_opts.baseURL = ['http://' rs_source_opts.service_host '/render-ws/v1'];
    rs_source_opts.verbose = eval_field(rs_source_opts, 'verbose', 1, false);

    rs_target_opts.stack_pattern = eval_field(rs_target_opts, 'stack_pattern', 'v14_rough_<si>', true);
    rs_target_opts.owner = eval_field(rs_target_opts, 'owner', 'flyTEM', true);
    rs_target_opts.project = eval_field(rs_target_opts, 'project', 'test2', true);
    rs_target_opts.service_host = eval_field(rs_target_opts, 'service_host', '10.40.3.162:8080', true);
    rs_target_opts.baseURL = ['http://' rs_target_opts.service_host '/render-ws/v1'];
    rs_target_opts.verbose = eval_field(rs_target_opts, 'verbose', 1, false);

    thickness = eval_field(slab_options, 'thickness', 50); % slab thickness
    overlap = eval_field(slab_options, 'overlap', 10); % slab overlap
    max_image_area = eval_field(slab_options, 'max_image_area', 1.575*10^8); % maximum montage-scape image area (HxW)
    min_scale = eval_field(slab_options, 'min_scale', 0.02);
    max_scale = eval_field(slab_options, 'max_scale', 0.1);

    disp(rs_source_opts)

    %% get section bounds
    % get /v1/owner/{owner}/project/{project}/stack/{stack}/z/{z}/bounds
    [zu1, ~, ~, ~, ~] = get_section_ids(rs_source_opts, nfirst, nlast);
    box = [];
    parfor ix = 1:numel(zu1)
        urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%d/bounds', ...
            rs_source_opts.baseURL, rs_source_opts.owner, rs_source_opts.project, rs_source_opts.stack, zu1(ix));
        wo = weboptions('Timeout', 120);
        j = webread(urlChar, wo);
        box(ix,:) = [j.minX j.maxX j.minY j.maxY];
    end

    %% partition into overlaping slabs
    slab_defs = {};
    count = 0;
    zend = nlast;
    done = false;
    while ~done
        %% create the slab definition
        if count == 0
            current_slab = struct();
            current_slab.slab_start = 1;
        else
            previous_slab = current_slab;
            current_slab = struct();
            current_slab.slab_start = previous_slab.slab_end - overlap;
        end
        count = count + 1;
        current_slab.slab = count;
        current_slab.slab_end = current_slab.slab_start + thickness -1;
        if current_slab.slab_end >= zend
            current_slab.slab_end = zend;
            done = true;
        end
        current_slab.run_rough_align = false;

        %% determine the scale factor
        vec = find(zu1 >= current_slab.slab_start & zu1 <= current_slab.slab_end);
        R = [box(vec,2)-box(vec,1) box(vec,4)-box(vec,3)];
        max_slab_section_area = max(R(:,1).*R(:,2));
        current_slab.slab_scale_factor = max_image_area / max_slab_section_area;
        if current_slab.slab_scale_factor > max_scale, current_slab.slab_scale_factor = max_scale;end
        if current_slab.slab_scale_factor < min_scale, current_slab.slab_scale_factor = min_scale; end

        %% setup slab's stack
        current_slab.slab_collection = struct();

        stack_name = rs_target_opts.stack_pattern;
        stack_name = strrep(stack_name, '<si>', sprintf('%.5d', current_slab.slab));
        stack_name = strrep(stack_name, '<sstart>', sprintf('%.5d', current_slab.slab_start));
        stack_name = strrep(stack_name, '<send>', sprintf('%.5d', current_slab.slab_end));
        stack_name = strrep(stack_name, '<sscale>', strrep(num2str(current_slab.slab_scale_factor), '0.', ''));

        current_slab.slab_collection.stack = stack_name;
        current_slab.slab_collection.owner = rs_target_opts.owner;
        current_slab.slab_collection.project = rs_target_opts.project;
        current_slab.slab_collection.service_host = rs_target_opts.service_host;
        current_slab.slab_collection.baseURL = rs_target_opts.baseURL;
        current_slab.slab_collection.verbose = rs_target_opts.verbose;

        slab_defs{count} = current_slab;

    end

    disp(slab_defs)
    savejson('', slab_defs, slab_defs_fn)

end
