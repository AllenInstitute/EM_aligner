function [dist] = show_trace(rc, fn, h)
% %% define the renderer collection
% rc.stack          = 'v14_align_tps_03';
% rc.owner          ='flyTEM';
% rc.project        = 'FAFB00';
% rc.service_host   = '10.40.3.162:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 1;
dist = [];
%% read a reference trace in local coordinates
fid = fopen(fn, 'r');
C = textscan(fid,'%n%n%n%n%n%n%n%s', 'delimiter', '\t');
fclose(fid);
tileIds = C{8};
indx1 = C{1};
indx2 = C{7};
x = num2str(C{3});
y = num2str(C{4});
z = C{5};
%% convert to world coordinates
npoints = size(x,1);
delix = zeros(npoints,1, 'logical');
xout = zeros(npoints,1);
yout = zeros(npoints,2);
parfor ix = 1:npoints
    
    [xread, yread, err] = local_to_world(rc, tileIds{ix}, x(ix,:), y(ix,:));
    if err
        delix(ix) = 1;
    else
        xout(ix) = xread;
        yout(ix) = yread;
        delix(ix) = 0;
    end
end
yout = yout(:,1);

disp(['Number of invalid points: ' num2str(sum(delix))]);

% indx1(delix) = [];
% indx2(delix) = [];
% x(delix) = [];
% y(delix) = [];
% z(delix) = [];
% npoints = size(x,1);
%%
if nargin<3
figure;
end
dist = [];
thresh = 5000;
for ix = 1:npoints
    if ~delix(ix)
        i1 = find(indx2==indx2(ix),1);  % finds linear index of parent with the id (indx2(ix))
        ip = find(indx1==indx2(i1));
        xp = xout(ip);
        yp = yout(ip);
        zp = z(ip);
        distance = sqrt((xp-xout(ix)).^2 + (yp-yout(ix)).^2 + (zp-z(ix)).^2);
        %     disp(distance);
        if distance<thresh
            plot3([xp xout(ix)], [yp yout(ix)], [zp z(ix)], 'b');hold on; %drawnow;
            dist = [dist distance];
        end
    end
end
az = -92.3;
el = -18;
view(az, el);