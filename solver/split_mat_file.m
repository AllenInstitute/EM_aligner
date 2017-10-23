% Copyright (C) 2015 by Howard Hughes Medical Institute.
%

function split_mat_file(input_mat_file, num_workers)    
prefixName = input_mat_file(1:(length(input_mat_file)-4));
    mat = load(input_mat_file);
% function split_mat_file(A, b, ncpus)

    num_col = size(mat.A, 2);
    tiles_per_worker = round(num_col/6./ncpus);
    disp(['tiles_per_worker=' num2str(tiles_per_worker)]);
    for i=1:ncpus
        col_min = 1 + 6*(i-1)*tiles_per_worker;
        if i < ncpus
            col_max = col_min   + 6*tiles_per_worker-1;
        else
            col_max = size(mat.A, 2);
        end
        A = mat.A(:, col_min:col_max);
        b = mat.b(col_min:col_max);
        disp(['i=' num2str(i) ' col_min=' num2str(col_min) ' col_max=' num2str(col_max) ...
            ' size(A)=' num2str(size(A)) ' size(b)=' num2str(size(b))]);
        output_mat_file = strcat(prefixName,'_', num2str(i), '.mat');
        save(output_mat_file, 'A', 'b', '-v7.3')
    end
