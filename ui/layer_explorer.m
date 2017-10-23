function varargout = layer_explorer(varargin)
% LAYER_EXPLORER MATLAB code for layer_explorer.fig
%      LAYER_EXPLORER, by itself, creates a new LAYER_EXPLORER or raises the existing
%      singleton*.
%
%      H = LAYER_EXPLORER returns the handle to a new LAYER_EXPLORER or the handle to
%      the existing singleton*.
%
%      LAYER_EXPLORER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LAYER_EXPLORER.M with the given input arguments.
%
%      LAYER_EXPLORER('Property','Value',...) creates a new LAYER_EXPLORER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before layer_explorer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to layer_explorer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help layer_explorer

% Last Modified by GUIDE v2.5 06-Jul-2015 16:03:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @layer_explorer_OpeningFcn, ...
                   'gui_OutputFcn',  @layer_explorer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before layer_explorer is made visible.
function layer_explorer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to layer_explorer (see VARARGIN)a
axis(handles.axes1);
cla;
set(gcf,'toolbar','figure');

if ~isempty(varargin),
    handles.L = varargin{1};
    handles.L = handles.L(1);
else
    disp('Using sample data');
end

%%% populate the menu

str(1) = {'Tile states'};
if ~isempty(handles.L.rprt)
    if isfield(handles.L.rprt, 'alignBK')
        %%% then list the different types of scalar fields
        %%% we can show
        str(2) = {'Pairwise FAIL occurrences'};
        str(3) = {'Pairwise --STAT: ImproveControlPts: Initial affine correlation'};
        str(4) = {'Pairwise --STAT: ImproveControlPts: Final affine correlation'};
        str(5) = {'Pairwise --STAT: ImproveControlPts: Initial deformable mesh correlation'};
        str(6) = {'Pairwise --STAT: ImproveControlPts: Final deformable mesh correlation'};
        
        str(7) = {'Pairwise --Approx: LowRes  R'};
        str(8) = {'Pairwise --Approx: FullRes  R'};
        str(9) = {'Pairwise --Approx: Relative peak distance-from-center error'};
    end
    
end

set(handles.popupmenu1, 'String', str);


%%%%%%%%%% Choose default command line output for layer_explorer
handles.output = hObject;
axes(handles.axes1);
set(handles.axes1, 'Units', 'normalized');
%%% update the layer object
handles.L = update_XY(handles.L); 
handles.L = update_adjacency(handles.L);
handles.L = get_bounding_box(handles.L);
handles.scale = 0.5;
handles.force_mosaic = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% starting plot
%%% Plot the tiles:

if ~isempty((handles.L.mosaic))
    
    im = handles.L.mosaic;
    RI = imref2d(size(im));
    RI.XWorldLimits = [handles.L.box(1) handles.L.box(2)];
    RI.YWorldLimits = [handles.L.box(3) handles.L.box(4)];
    imh = imshow(im,RI);
    alpha_data = ones(size(im))*0.1;
    % set the y-axis back to normal.
    set(gca,'ydir','normal');
    hold on;
    handles.L = show_map(handles.L);
else
    %handles.L = show_map_with_mosaic(handles.L, 0.05, 0, 'transparent', 0);
    %handles.L = show_map(handles.L);
    % handles.L = get_bounding_box(handles.L);
    handles.L = show_map(handles.L, 'registered only');
end
axis on;


if ~isempty(handles.L.box)
set(handles.axes1,'xlim',handles.L.box(1:2),'ylim',handles.L.box(3:4))
end
handles.show_text = 0;
handles.disp_style = 'opaque';
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes layer_explorer wait for user response (see UIRESUME)
  uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = layer_explorer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.L;
% The figure can be deleted now
delete(handles.figure1);

% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
axes(handles.axes1);
Z = get(gca,{'xlim','ylim'});  % Get axes limits.
cla;
legend off;
popup_sel_index = get(handles.popupmenu1, 'Value');
switch popup_sel_index
    case 1
        show_tile_state(handles.L);
    case 2
        show_pairwise_fail(handles.L);
    case 3
        show_pairwise(handles.L, 1);
    case 4
        show_pairwise(handles.L, 2);
    case 5
        show_pairwise(handles.L, 3);
    case 6
        show_pairwise(handles.L, 4);
    case 7
        show_pairwise(handles.L, 5);
    case 8
        show_pairwise(handles.L, 6);
    case 9
        show_pairwise(handles.L, 7);    
end
set(gca,{'xlim','ylim'},Z);

% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'h_selected'),
    if exist('handles.h_selected')
    set(handles.h_selected, 'Visible', 'off');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    view button
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[x,y] = ginput(1);
tix =get_tile_index(handles.L, x, y);
if ~isempty(tix)
    tix = tix(1);       % for the unlikely situation that we have two or more
    axes(handles.axes1);
    hold on;
    if handles.L.tiles(tix).W==0, handles.L = update_tile_info(handles.L);end 
     
    x = 0;
    y = 0;%handles.L.tiles(tix).tform.T(3,2);
    Px = [x; x + handles.L.tiles(tix).W/handles.L.map_display_fac; x + handles.L.tiles(tix).W/handles.L.map_display_fac; x];
    Py = [y; y; y + handles.L.tiles(tix).H/handles.L.map_display_fac; y+handles.L.tiles(tix).H/handles.L.map_display_fac];
    
    if strcmp(class(handles.L.tiles(tix).tform), 'affine2d')
        
    P = [Px(:) Py(:) [1 1 1 1]']*handles.L.tiles(tix).tform.T;
    
    else
         P = transformPointsInverse(handles.L.tiles(tix).tform,[Px Py]);
    end
    handles.h_selected = patch( P(:,1), P(:,2), [0 0.7 0.7], 'FaceAlpha', 0.2);
    
    hold off;
    h_view = figure;
    if strcmp(class(handles.L.tiles(1).tform), 'affine2d') % assuming all transformations to be of the same type
        disp('Using affine matrix');
     show_tile(handles.L, tix, handles.scale);
    else
        disp('Using render_poly');
        show_tile(handles.L, tix, 0, handles.scale);
    end
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Select a tile to be discarded (status set to zero)');
[x,y] = ginput(1);
tix =get_tile_index(handles.L, x, y);
if ~isempty(tix)
    tix = tix(1);       % for the unlikely situation that we have two or more
    handles.L.tiles(tix).state = 0;
    axes(handles.axes1);
    hold on;
%     rectangle('Position', ...
%                 [handles.L.tiles(tix).tform.T(3,1) handles.L.tiles(tix).tform.T(3,2) ...
%                 handles.L.tiles(tix).W/handles.L.map_display_fac handles.L.tiles(tix).H/handles.L.map_display_fac], ...
%                 'Curvature', [0.8, 0.4], 'LineWidth', 2, 'LineStyle', '--', ...
%                 'FaceColor', [1 0 0]);
            
    x = 0;
    y = 0;%handles.L.tiles(tix).tform.T(3,2);
    Px = [x; x + handles.L.tiles(tix).W/handles.L.map_display_fac; x + handles.L.tiles(tix).W/handles.L.map_display_fac; x];
    Py = [y; y; y + handles.L.tiles(tix).H/handles.L.map_display_fac; y+handles.L.tiles(tix).H/handles.L.map_display_fac];
    P = [Px(:) Py(:) [1 1 1 1]']*handles.L.tiles(tix).tform.T;
    handles.h_selected = patch( P(:,1), P(:,2), [0 0.7 0.7], 'FaceAlpha', 0.2);
     
    hold off;  
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Select a tile to be retained (status set to one)');
[x,y] = ginput(1);
tix =get_tile_index(handles.L, x, y);

disp(tix);
if ~isempty(tix)
    tix = tix(1);       % for the unlikely situation that we have two or more
    handles.L.tiles(tix).state = 1;
    axes(handles.axes1);
    hold on;
%     rectangle('Position', ...
%                 [handles.L.tiles(tix).tform.T(3,1) handles.L.tiles(tix).tform.T(3,2) ...
%                 handles.L.tiles(tix).W/handles.L.map_display_fac handles.L.tiles(tix).H/handles.L.map_display_fac], ...
%                 'Curvature', [0.8, 0.4], 'LineWidth', 2, 'LineStyle', '--', ...
%                 'FaceColor', [0.5 0.5 0.5]);
    
    x = 0;
    y = 0;%handles.L.tiles(tix).tform.T(3,2);
    Px = [x; x + handles.L.tiles(tix).W/handles.L.map_display_fac; x + handles.L.tiles(tix).W/handles.L.map_display_fac; x];
    Py = [y; y; y + handles.L.tiles(tix).H/handles.L.map_display_fac; y+handles.L.tiles(tix).H/handles.L.map_display_fac];
    P = [Px(:) Py(:) [1 1 1 1]']*handles.L.tiles(tix).tform.T;
    handles.h_selected = patch( P(:,1), P(:,2), [0 0.7 0.7], 'FaceAlpha', 0.2);
    
hold off;  
end
% Update handles structure
guidata(hObject, handles);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end

% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.show_text ==0
    for ix = 1:numel(handles.L.tiles)
        X = handles.L.X;%tiles(ix).tform.T(3,1) + handles.L.tiles(ix).W/2;
        Y = handles.L.Y;%tiles(ix).tform.T(3,2) + handles.L.tiles(ix).H/2;
        %disp([X Y]);
        text(X,Y, num2str(ix), 'BackgroundColor', 'y', 'FontSize', 18);
        handles.show_text = 1;
    end
else
    axes(handles.axes1);
    Z = get(gca,{'xlim','ylim'});  % Get axes limits.
    cla;
    legend off;
    popup_sel_index = get(handles.popupmenu1, 'Value');
    switch popup_sel_index
        case 1
%             handles.L = update_XY(handles.L);
%             handles.L = update_adjacency(handles.L);
%             
%             %%% Plot the tiles:
%             
%             handles.L = show_map_with_mosaic(handles.L, 0.01, 0, 'opaque', 0);
%             
            %             show_tile_state(handles.L);
        case 2
            show_pairwise_fail(handles.L);
        case 3
            show_pairwise(handles.L, 1);
        case 4
            show_pairwise(handles.L, 2);
        case 5
            show_pairwise(handles.L, 3);
        case 6
            show_pairwise(handles.L, 4);
        case 7
            show_pairwise(handles.L, 5);
        case 8
            show_pairwise(handles.L, 6);
        case 9
            show_pairwise(handles.L, 7);
    end
    set(gca,{'xlim','ylim'},Z);
    handles.show_text = 0;
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% select a group of tiles


[pl,xs,ys] = selectdata('sel','lasso');
handles.x = vertcat(xs{:});
handles.y = vertcat(ys{:});
hold on;
plot(handles.x, handles.y,'y*');
%% determine the selected tiles
tix = zeros(numel(handles.x),1);
for pix = 1:numel(handles.x)
tix(pix) =get_tile_index(handles.L, handles.x(pix), handles.y(pix));
end
tix = unique(tix);
handles.Ls1 = Msection(handles.L.tiles(tix));
handles.Ls2 = handles.L;
handles.Ls2.tiles(tix) = [];
handles.Ls2.mosaic = [];

% save the files
[file,path] = uiputfile('Ls1.mat','Save file name for selection');
if (file)
L = handles.Ls1;
save([path file], 'L');
end
[file,path] = uiputfile('Ls2.mat','Save file name for inverse selection');
if (file)
L = handles.Ls2;
save([path file], 'L');
end


% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%

if strcmp(handles.disp_style, 'transparent')  % then toggle to opaque
    handles.L = show_map_with_mosaic(handles.L, handles.scale, handles.force_mosaic, 'opaque');
    handles.disp_style = 'opaque';
    handles.force_mosaic = 0;
else
    handles.disp_style = 'transparent';
    handles.L = show_map_with_mosaic(handles.L, handles.scale,handles.force_mosaic, 'transparent');
    handles.force_mosaic = 0;
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'h_selected'),
    if exist('handles.h_selected')
    set(handles.h_selected, 'Visible', 'off');
    end
end
[x,y] = ginput(1);
tix =get_tile_index(handles.L, x, y);
if ~isempty(tix)
    tix = tix(1);       % for the unlikely situation that we have two or more
    axes(handles.axes1);
    hold on;
    if handles.L.tiles(tix).W==0, handles.L = update_tile_info(handles.L);end 
     
    x = 0;
    y = 0;%handles.L.tiles(tix).tform.T(3,2);
    Px = [x; x + handles.L.tiles(tix).W/handles.L.map_display_fac; x + handles.L.tiles(tix).W/handles.L.map_display_fac; x];
    Py = [y; y; y + handles.L.tiles(tix).H/handles.L.map_display_fac; y+handles.L.tiles(tix).H/handles.L.map_display_fac];
    
    if strcmp(class(handles.L.tiles(tix).tform), 'affine2d')
        
    P = [Px(:) Py(:) [1 1 1 1]']*handles.L.tiles(tix).tform.T;
    
    else
         P = transformPointsInverse(handles.L.tiles(tix).tform,[Px Py]);
    end
    handles.h_selected = patch( P(:,1), P(:,2), [0 0.7 0.7], 'FaceAlpha', 0.2);
    
    hold off;
    h_view = figure;
    if strcmp(class(handles.L.tiles(1).tform), 'affine2d') % assuming all transformations to be of the same type
        disp('Using affine matrix');
     show_tile(handles.L, tix, 1);
    else
        disp('Using render_poly');
        show_tile(handles.L, tix, 0,0.05,1);
    end
end
% Update handles structure
guidata(hObject, handles);



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
handles.scale = str2double(get(hObject,'String'));
handles.force_mosaic = 1;
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
