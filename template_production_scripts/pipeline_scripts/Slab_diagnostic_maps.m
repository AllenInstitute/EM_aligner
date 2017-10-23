function [] = Slab_diagnostic_maps(slabs_to_process, todos, start_sections, end_sections, diag_base_dir, saved_slabs_dir)

    if nargin < 2, todos = []; end
    if nargin < 3, start_sections = []; end
    if nargin < 4, end_sections = []; end       
    if nargin < 5, diag_base_dir = '/nobackup/flyTEM/khairy/FAFB00v13/map_diagrams'; end
    if nargin < 6, saved_slabs_dir = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_slabs'; end

    %% Get the slab definition
    Slab_definition;

    %% Process the selected slabs
    if ischar(slabs_to_process)
        slabs_to_process = eval(slabs_to_process);
    end
    if ischar(todos)
        todos = eval(todos);
    end
    if ischar(start_sections)
        start_sections = eval(start_sections);
    end
    if ischar(end_sections)
        end_sections = eval(end_sections);
    end
    for si = 1:numel(slabs_to_process)
        %% Process current slab
        slab = slabs_to_process(si);

        slab_name = ['slab_' sprintf('%d_sections_%d_to_%d', slab, nfirstvec(slab), nlastvec(slab))];
        if run_now_vec_rough(slab) == 1 && run_now_vec_fine(slab)
            fprintf('Skip %s since it has not been processed yet\n', slab_name);
            continue;
        end
        fprintf('Generate diagrams for %s\n', slab_name);
        slab_dir = [diag_base_dir '/' slab_name];
        mkdir(slab_dir);
        if si <= numel(start_sections) && start_sections(si) >= nfirstvec(slab) && start_sections(si) <= nlastvec(slab)
            sstart = start_sections(si);
        else
            sstart = 0;
        end
        if si <= numel(end_sections) && end_sections(si) >= nfirstvec(slab) && end_sections(si) <= nlastvec(slab)
            send = end_sections(si);
        else
            send = 0;
        end
        if si <= numel(todos)
	    todo = todos(si);
	else
	    todo = 0;
        end
        generate_diagnostic_diagrams(slab, nfirstvec(slab), nlastvec(slab), todo, sstart, send, saved_slabs_dir, slab_dir);
        fprintf('Finished generating diagrams for %s\n', slab_name);
    end
end
