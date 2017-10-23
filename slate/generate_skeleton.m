function [sk, im] = generate_skeleton(rcsource, rendered_stack, dir_temp_render,...
    nz, zstart, x, y, w, h, scale, smoothing, use_dgvf, scale_level, debug)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Experiment: skeletonize orthogonal fibers
%
% Generates a skeleton by marching through frames
% rcsource: specifies the renderer collection
% rendered_stack: specifies where to find the stack on disk
% dir_temp_render: temporary directory only needed if using renderer client to generate images
% nz = number of steps (usually in z if structures are orthogonal)
% zstart: z coordinate
% x, y: starting x and y coordinates
% w, h: width and height of box to use to generate context for stepping
% scale: scaling of image in box
% use_dgvf: computes additional flow field to keep the node inside the original structure bounds
% (takes 2/3 times longer when set to 1
% scale_level: the CATMAID scale level used to fetch boxes
% debug: set to 1 to look at progress live
%
% 
%
%
% Author: Khaled Khairy. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = [x y];  % seed point in world coordinates
so = s;
im = zeros(w*scale,h*scale,nz);
sk = zeros(nz,2);
sk(1,: ) = s;
box = [s(1)-w/2 s(2)-h/2 w h];
for imix = 0:nz-1
    
    z1 = zstart+imix;
    z2 = z1 + 1;
    % read image 1
    %     im1 = get_image_box_renderer(rcsource, z1, box, scale, dir_temp_render, num2str(z1));
    %     im2 = get_image_box_renderer(rcsource, z2, box, scale, dir_temp_render, num2str(z2));
    
%     im1 = get_image_box_bock_server(rendered_stack, scale_level, z1, box);
%     im2 = get_image_box_bock_server(rendered_stack, scale_level, z2, box);
    
    im1 = get_image_box(rendered_stack, scale_level, z1, box);
    im2 = get_image_box(rendered_stack, scale_level, z2, box);
    
    if ~isempty(im1) && ~isempty(im2) && sum(im1(:)) && sum(im2(:))
        if debug
            figure(1);imshow(im1);hold on;plot(w/2*scale, h/2*scale, '*y');title(['im1: ' num2str(imix)]);drawnow;
        end
        
        im1 = imhistmatch(im1,im2);
        [D,movingReg] = imregdemons(im1,im2,[500 400 200],...
            'AccumulatedFieldSmoothing',smoothing, 'DisplayWaitbar', false);
        
        %     %%% sosi
        %    figure(1);imshow(im1);hold on;plot(w/2*scale, h/2*scale, '*y');title(['im1: ' num2str(imix)]);drawnow;
        
        
        dx = D(round(w/2), round(h/2), 1);
        dy = D(round(w/2), round(h/2), 2);
        
        s = s - [dx dy];  % update s based on demons
        pim2 = [w/2*scale-dx h/2*scale-dy]; % the point in im2 coordinates
        
        
        box = [s(1)-w/2 s(2)-h/2 w h];   % calculate new box position
        %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if use_dgvf==1
            % we are not done yet --- we need to make sure the point is not too close to a membrane
            % % now displace (i.e.step) under influence of potential of im2 to avoid membrane borders
            
            [un, vn, ~] = dgvf_calc(im2, 10000, 200, 0.00001, 1, 1, 1);  % calculate gradient of that potential
            
            % sosi
            %
            %     figure(1);plot(pim2(1), pim2(2), '*b');title(num2str(imix));drawnow;
            %
            %     figure(2);imshow(im2); hold on;disp(max(un(:)));quiver(un, vn, 3); plot(pim2(1), pim2(2), '*y');title(num2str(imix));drawnow;
            %
            % % take steps
            nsteps = 500;
            step_size = 2.0;
            for st = 1:nsteps
                
                % get local field
                
                xget = pim2(1);
                yget = pim2(2);
                
                dx = interp2(un, xget, yget);
                dy = interp2(vn, xget, yget);
                NV = sqrt((dx.^2+dy.^2));
                % apply local field by taking a step
                dv = ([dx dy]/NV) * step_size; % multiply the unit vector by the step_size
                pim2 = pim2 + dv;
                s = s + dv;   % update s by moving down the field direction dv
                
                
                % %         % sosi
                %         if mod(st,10)==0
                %             newx = pim2(2);
                %             newy = pim2(2);
                %             disp([newx newy]);
                %             figure(2); hold on;plot(newx, newy, '*k');title(num2str(st));drawnow;
                %
                %
                % %             new_box = [s(1)-w/2 s(2)-h/2 w h];
                % %             figure;im2_step = get_image_box_renderer(rcsource, z2, new_box, scale, dir_temp_render, num2str(z2));
                % %             imshow(im2_step);hold on;plot(w/2*scale, h/2*scale, '*y');title(num2str(st));drawnow;
                %         end
                
            end
            box = [s(1)-w/2 s(2)-h/2 w h];   % calculate new box position
            %disp(max(un(:)));quiver(un, vn, 3);
            %%% sosi
            %imshow(im2);hold on;plot(vec(1)*scale, vec(2)*scale, '*y');
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        
        % store coodinate of new seed point
        sk(imix+2, :) = [s(1) s(2)]; % world coordinates
        % store the image
        im(:,:, imix+1) = im1;
    end
end

im = mat2gray(im);
















































