function [str, a, resp] = generate_mini_stack(rc, scale, zscale, dir_out, minz, maxz, minx,...
    width,  n_spark_nodes, bill_to, spark_dir, max_images)
% generate a ministack using given collection
% Example usage to generate ministack for a full collection rcfine:
% [Wbox, bbox, url, minZ, maxZ] = get_slab_bounds_renderer(rcfine);
% 
% n_spark_nodes = 2;
% bill_to = 'hessh';
% spark_dir = '/groups/flyem/data/render/spark_output';
% dir_out = '/groups/flyTEM/home/khairyk/mwork/FIBSEM/mini_stacks'; % /groups/flyem/data/khairy_alignments/D08_09_ministack
% max_images = 5000;
% scale = 0.5;
% zscale = 0.5;
% minz = 1;
% maxz = 10;
% minx = Wbox(1);%11405;
% width = Wbox(3);% 2000
% str = generate_mini_stack(rcfine, scale, zscale, dir_out, minz, maxz, minx, width,  n_spark_nodes, bill_to);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<11
    spark_dir = '/groups/flyem/data/render/spark_output';
        max_images = 5000;
end
if nargin<2
    n_spark_nodes = 2;
    bill_to = 'hessh';
    spark_dir = '/groups/flyem/data/render/spark_output';
    dir_out = '/groups/flyTEM/home/khairyk/mwork/FIBSEM/mini_stacks';
    scale = 0.25;
    zscale = 1;
    minz = 1;
    maxz = 1295;
    minx = 1000;
    width = 2000;
end

str = sprintf('/groups/flyTEM/flyTEM/render/spark/render_scapes.sh --sparkNodes %d --sparkBillTo %s --sparkDir %s  --baseDataUrl %s  --owner %s --project %s --stack %s  --rootDirectory %s --maxImagesPerDirectory %d  --scale %.2f --zScale %.2f --minZ %d --maxZ %d --minX %d --width %d',...
    n_spark_nodes, bill_to, spark_dir, rc.baseURL, ...
    rc.owner, rc.project, rc.stack, dir_out, max_images, ...
    scale, zscale, minz, maxz, minx, width);
% disp(str);
[a, resp] = system(str);


