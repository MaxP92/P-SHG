function varargout = polarization_map(varargin)
% POLARIZATION_MAP MATLAB code for polarization_map.fig
%      POLARIZATION_MAP, by itself, creates a new 
%      POLARIZATION_MAP or raises the existing singleton.
%
%      POLARIZATION_MAP takes no input parameters.
%
%      POLARIZATION_MAP opens an additional window containing the
%      activeX controls for the motors and power meter. Do not close this
%      window, it will automatically close when closing 
%      POLARIZATION_MAP.
%
%      "File, properties" in POLARIZATION_MAP opens 
%      PROPERTIES_POLARIZATION_MAP. Here various properties of the program 
%      can be changed.
%
%      Push the "connect"-button to connect to the power meter and motors.
%      Push the "disconnect"-button if any manual operation of the power 
%      meter is desired
%
%      After connecting start the polarization measurements by pushing the 
%      "start"-button in POLARIZATION_MAP.
%
%      The "stop"-button will not make the program stop instantly. The code
%      checks regularly if the button has been pushed. The code will not
%      stop untill it reaches such a check-point.
%
%      When the measurements are finished the "Calibration"-button is
%      enabled. Pushing this button fits a theoretical model to the data
%      and determines the QWP and HWP angles that provide linearly and
%      circularly polarized light. The results are displayed in the figure
%      and tables in the lower half of the GUI.
%
%      After the polarization measurements are finished "file, save" is 
%      enabled, which allows saving of the data and the calibration if the 
%      calibration was performed.
%
%      Previous measurements can be loaded by selecting "file, open".
%
%      To do a single polarization measurement enter the desired QWP and
%      HWP angle and push the "Single measurement"-button. Thereafter the
%      measurement can be saved by selecting "file, save single".
%
%      Abbreviations:
%      QWP:         Quarter-wave plate
%      HWP:         Half-wave plate
%      WP:          Waveplates
%      LP:          Linear polarizer
%      CP:          Circular polarization
%      LP:          Linear polarization (Poor choise of abbreviations,
%                   however it will be clear from surrounding text)
%      EM:          Power meter
%
%      Symbols:
%      %!           Commands specific for our system (motors or power 
%                   meter) and HAS to be addapted to your system
%      %p           If a different brand of power meter is used these
%                   commands have to be addapted
%      %m           If a different brand of rotation motors are used these
%                   commands have to be addapted
%

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @polarization_map_OpeningFcn, ...
                   'gui_OutputFcn',  @polarization_map_OutputFcn, ...
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

% --- Executes just before polarization_map is made visible.
function polarization_map_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to polarization_map (see VARARGIN)

% Choose default command line output for polarization_map
handles.output = hObject;

handles.deco = 1; % init
path_comp = 'C:\Users\admin\Documents\Python\P-SHG-master';
if isdir(path_comp)
    handles.path_comp = path_comp;
else
    handles.path_comp ='C:\Users\pc\Documents\These\codes Matlab\P-SHG-master';
end
addpath(handles.path_comp);

str_l = {'micos', 'thorlabs', 'newport', 'tl_pm'}; % % change here if other instr dflt !!
hh={handles.LP_str_edt, handles.HWP_str_edt, handles.QWP_str_edt, handles.PM_str_edt};
for k=1:length(hh)
    if length(get(hh{k}, 'String')) <=3
        set(hh{k}, 'String',  str_l{k});
    end
end
handles.LP_str = get(handles.LP_str_edt, 'String'); %'micos';
handles.HWP_str = get(handles.HWP_str_edt, 'String'); %'thorlabs';
handles.QWP_str= get(handles.QWP_str_edt, 'String'); % 'newport';
handles.EM_str =  get(handles.PM_str_edt, 'String'); %'tl_pm';

strcell = get(handles.list_com, 'String');
com_str_qwp = strcell{3}; %'COM';
com_str_EM = strcell{1}; % 'COM';
com_str_LP = strcell{2}; % 'COM';
com_str_hwp = strcell{4};

serialInfo = instrhwinfo('serial');     % Finds available COM ports
avl= serialInfo.AvailableSerialPorts;
handles.avl_list=zeros(1,4);
ct = 0;
for com={com_str_EM, com_str_LP, com_str_qwp, com_str_hwp}
    if sum(strcmp(avl,com{1})) % available
        ct = ct+1;
        handles.avl_list(ct) = 1;
    else
        if length(com{1}) > 3
            fprintf(2, ['\n ' com{1} ' not available !!\n']) % 2 for red
        end
    end
end

handles.arr_2exclude = 0;

handles.timeout_read_EM = 1; % sec
handles.timeout_read_LP = 1;
handles.timeout_read_QWP = 1;
handles.tag_str_EM = 'thorpm_1';
handles.tag_str_LP = 'anal';
handles.tag_str_QWP = 'qwp';

handles.name_dev_list = {handles.EM_str, handles.QWP_str, handles.LP_str}; % both list should match
handles.baud_rate_list = {115200, 19200, 19200}; % both list should match

handles.baud_rate_EM = handles.baud_rate_list{1};
handles.baud_rate_LP = handles.baud_rate_list{3};
handles.baud_rate_QWP = handles.baud_rate_list{2};

% Sets the wavelength of the laser [nm]:
handles.wavelength = 810;

% Sets the acquisition time of each measurement with the power meter 
% [h m s]:
handles.meas_time = [0 0 1];
% Sets the frequency of the measurements with the power meter [1/s]:
handles.meas_freq = 10; 
% Sets the stepsize of the analyzer [deg]:
handles.LP_stepsize = 30;
% The range and resolution of the HWP and QWP [deg] (this will determine 
% for which WP angles the polarization will be measured):
handles.HWP_range = [0, 60];
handles.QWP_range = [0, 150];
handles.HWP_resolution = 30;
handles.QWP_resolution = 30;

handles.sn_list = [];

% Opens a window containing all the activex controls necessary:
handles.actx_figure = figure('Name', 'ActiveX');

%  \\\\ Top right is the power meter PM100: ////
% % handles.EM = actxcontrol('LabMaxLowLevelControl.LabMaxLowLevCtl.1', [300 200 300 200]); %p
% com_count = 1;
% com_str = ['COM',num2str(com_count)];
if handles.avl_list(1)% [com_str_EM, com_str_LP, com_str_qwp, com_str_hwp]
    handles.EM = open_com_mp(com_str_EM, handles.baud_rate_EM, handles.tag_str_EM, handles.timeout_read_EM, 0 );
    disp('EM instr here')
end

% % MP !!!!!
% \\\\ Newport ESP ////

if strcmp(handles.LP_str , 'thorlabs')
    % % Top left is the analyzer:
%    handles.LP = actxcontrol('MGMOTOR.MGMotorCtrl.1', [0 200 300 200]); %m
    handles.sn_list{end+1} = 83845971; %!
    handles.LP = open_actX([0 200 300 200], handles.sn_list{end});
    handles.HWP.HWSerialNum = handles.sn_list{end}; %!
    handles.avl_list(2) = 1;

else
    handles.sn_list{end+1} = 0;
   if handles.avl_list(2)% [com_str_EM, com_str_LP, com_str_qwp, com_str_hwp]
        handles.LP = open_com_mp(com_str_LP, handles.baud_rate_LP, handles.tag_str_LP, handles.timeout_read_LP, 1);
       disp('LP instr here')

   end
% motor1ID=fscanf(handles.LP,'%s');
% set(handles.motor1Field,'String',motor1ID);
end

%  \\\\ Micos QWP rot //// % m
% serialInfo = instrhwinfo('serial');     % Finds available COM ports
% if ~isempty(serialInfo.AvailableSerialPorts)
%     for k=1:length(serialInfo.AvailableSerialPorts)
%         s_port(k)=serialInfo.AvailableSerialPorts(k);   % Saves in a vector the available COM ports
%     end
% % %     set(handles.comPortsPopupMenu,'String',s_port);   % Writes in a popupmenu the s_port elements
% end
%read and display motorIDs
if strcmp(handles.QWP_str , 'thorlabs')
    % % Bottom right is the QWP:
    handles.sn_list{end+1} = 83845971; %!
    handles.QWP = open_actX([0 0 300 200], handles.sn_list{end});
%     handles.QWP = actxcontrol('MGMOTOR.MGMotorCtrl.1', [0 0 300 200]); %m
    handles.QWP.HWSerialNum = handles.sn_list{end}; %!
    handles.avl_list(3) = 1;
else
    handles.sn_list{end+1} = 0;
    if handles.avl_list(3)% [com_str_EM, com_str_LP, com_str_qwp, com_str_hwp]
        handles.QWP = open_com_mp(com_str_qwp, handles.baud_rate_QWP, handles.tag_str_QWP, handles.timeout_read_QWP, 1);
       disp('QWP instr here')

    end
end

    % Bottom left is the HWP: (Thorlabs)
if strcmp(handles.HWP_str , 'thorlabs')
    handles.sn_list{end+1} = 83842617; %!
    handles.HWP = open_actX([0 0 400 400], handles.sn_list{end});
% %     handles.HWP = actxcontrol('MGMOTOR.MGMotorCtrl.1', [0 0 400 400]); %m
    if ~isempty(handles.HWP)
        disp('tl instr here')
        handles.HWP.HWSerialNum = handles.sn_list{end}; %!
        handles.avl_list(4) = 1;
    end  
else
    handles.sn_list{end+1} = 0;
    if handles.avl_list(4)% [com_str_EM, com_str_LP, com_str_qwp, com_str_hwp]
        handles.HWP = open_com_mp(com_str_hwp, handles.baud_rate_HWP, handles.tag_str_HWP, handles.timeout_read_HWP, 1);
        disp('HWP instr here')
    end
end


% Labels the axes of the figure that will contain the results:
axes(handles.axes_result)
set(handles.axes_result,'XAxisLocation','top','fontsize',8,'box','on');
xlabel('QWP [deg]')
ylabel('HWP [deg]')

% Sets the series number for the motors and energy meter:

handles.dev_on_list = [0, 0, 0, 0]; % dflt

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = polarization_map_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% -------------------------------------------------------------------------
% ------------------- FUNCTIONS IN THE GUI: -------------------------------
% --- Executes on button press in push_disconnect.

% --- Executes on button press in push_connect.
function push_connect_Callback(hObject, eventdata, handles)
% hObject    handle to push_connect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Connects to the motors and power meter:
instr_l = {handles.EM, handles.LP, handles.QWP, handles.HWP};     
ins_str = {handles.EM_str, handles.LP_str, handles.QWP_str, handles.HWP_str};
names={'EM', 'LP', 'QWP','HWP'};
for ii=0:3
    handles = connect_actx(handles, ins_str, names, ii, instr_l{ii+1}, 1);
    guidata(hObject, handles);
end
for ii=0:3
    if (handles.dev_on_list(ii+1) && ii >0) % % not EM
        home_mot_mp(ins_str{ii+1}, instr_l{ii+1}); % home simultaneously
    end
end
for ii=0:3
    handles = connect_actx(handles, ins_str, names, ii, instr_l{ii+1}, 2);
    guidata(hObject, handles);
end
c= sum(handles.dev_on_list);
% % % Homes the motors:
% % % % c(1) = handles.LP.MoveHome(0,1); %m
% % % % c(2) = handles.HWP.MoveHome(0,1); %m
% % % % c(3) = handles.QWP.MoveHome(0,1); %m
% % 
% % if sum(c) ~= 0
% %     handles = disconnect_actx(handles);
% %     warning('Could not connect to the motors.');
% %     handles.dev_on_list(4) = 0;
% %     return
% % end
handles.deco = 0;
% If something went wrong:
if ~c % c = 0
    % Update handles structure
    guidata(hObject, handles);
    return;
end

% Enables the start, stop and single measurement button:
set(handles.push_start,'Enable','on');
set(handles.push_stop,'Enable','on');
set(handles.push_single,'Enable','on');

% Disables to the connect button and the properties menu:
set(hObject,'Enable','off');
% % set(handles.menu_prop,'Enable','off');
% Enables to the disconnect button:
set(handles.push_disconnect,'Enable','on')

% Update handles structure
guidata(hObject, handles);

function push_disconnect_Callback(hObject, eventdata, handles)
% hObject    handle to push_disconnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Disconnects from the motors and power meter:
handles = disconnect_actx(handles);

% Disables the start, stop and single measurement button:
set(handles.push_start,'Enable','off');
set(handles.push_stop,'Enable','off');
set(handles.push_single,'Enable','off');

% Enables to the connect button and properties menu:
set(handles.push_connect,'Enable','on');
set(handles.menu_prop,'Enable','on');
% Disables the disconnect button:
set(hObject,'Enable','off');


% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in push_start.
function push_start_Callback(hObject, eventdata, handles)
% hObject    handle to push_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Removes all previous results:
set(handles.path_disp, 'String', '');
handles = clear_results(handles);

% Sets the stop variable to false:
setappdata(0 , 'stop', 0);

% Creates a HWP and QWP matrix containing all combinations of QWP and HWP 
% angles:
vectQWP = handles.QWP_range(1):handles.QWP_resolution:handles.QWP_range(2);
if isempty(vectQWP)
    vectQWP = handles.QWP_range(1); handles.QWP_resolution =10;
end
vectHWP = handles.HWP_range(1):handles.HWP_resolution:handles.HWP_range(2);
if isempty(vectHWP)
    vectHWP = handles.HWP_range(1); handles.HWP_resolution =10;
end
[handles.QWP_values, handles.HWP_values] = ndgrid(...
    vectQWP,...
    vectHWP);
[k,l] = size(handles.QWP_values);
% Creates a matrix that will contain all the analyzer and intensity
% measurements:
handles.LP_values = 0:handles.LP_stepsize:180;
n = length(handles.LP_values);
handles.intensity_measurements = zeros(k,l,n);
% The fitted parameters from the ellipticity analysis will be stored in
% these parameters:
handles.fitted_parameters.E_max = zeros(k,1);
handles.fitted_parameters.E_min = zeros(k,1);
handles.fitted_parameters.pol_angle = zeros(k,1);

% Creates a figure into which all the fittings will be plotted, so the user
% can see the progression of the measurements:
handles.overview_figure = figure(101); set(handles.overview_figure,'position',[10,50,(k*75)+75,(l*75)+75]);

if k >0; vectx = 1:k; % QWP
else; vectx = 1; %k =1;
end
if l >0; vecty = 1:l; % QWP
else; vecty = 1; %l =1;
end
x=0;
tic;
while x < vectx(end) % QWP
     y = 0;
    x = x+1;
    fprintf('x is at %d/%d, %d \n', x, vectx(end), handles.QWP_values(x,1));
    while y < vecty(end) % % HWP
        y = y+1;
        if (sum(size(handles.arr_2exclude)==size(handles.HWP_values')) && handles.arr_2exclude(y, x)) % % line, col
            if handles.arr_2exclude(y, x) == 1 % % if 2, just skip but don't erase existing one
                h = subplot('Position',[x/(vectx(end)+1),(vecty(end)-y)/(vecty(end)+1),1/(vectx(end)+1),1/(vecty(end)+1)]);
                axis('equal'); set(h,'xtick',[],'ytick',[],'box','off','xcolor','w','ycolor','w')
            end
            continue % skip this one
        end
        fprintf('y is at %d/%d, %d\n', y, vecty(end), handles.HWP_values(x,y));
        % Rotates the QWP and HWP to specific angles:
% %         handles.QWP.MoveAbsoluteRot(0,handles.QWP_values(x,y),0,3,1); %m
        move_rot_mp(handles.QWP_str, handles.QWP, handles.QWP_values(x,y));
        move_rot_mp(handles.HWP_str, handles.HWP, handles.HWP_values(x,y));
% %         handles.HWP.MoveAbsoluteRot(0,handles.HWP_values(x,y),0,3,1); %m
        
        % Measures the polarization:
        [handles, I] = ellipticity_analyzer(handles);
        handles.intensity_measurements(x,y,:) = I;
        
        % Plots the results:
        [handles,~] = plot_polarization(handles, x, y);
        
        % Gives the GUI time to update:
        pause(0.1)
        % In order for the stop button to function we have to check 
        % throughout the code if it has been pushed:
        guidata(hObject, handles);

        if getappdata(0,'stop')
            % Update handles structure
            fprintf(2, 'stop detected inside calib : end.\n');
            % Ends the calibration:
            save_util( handles, 'C:\Users\admin\Desktop\', 'res_temp.mat');
            return;
        end
    end
    save_util( handles, 'C:\Users\admin\Desktop\', 'res_temp.mat');
    if x == vectx(end) % the end
        try %#ok<TRYNC>
            toc; 
        end 
        guidata(hObject, handles);
        [handles, vectx, vecty, handles.arr_2exclude, flag] = add_polar_afterend_mp(handles, vectx, vecty, handles.arr_2exclude, n);
        if ~flag
            break; % outside while X
        else
            x=0; % y=0;
            tic;
        end
    end
end

% Enables the save and calibration option:
set(handles.menu_save,'Enable','on');
set(handles.push_cali,'Enable','on');
% Dissables the "save single"-button:
set(handles.menu_save_single,'Enable','off');

% Enables the posibility to view different parameters of the measured
% polarization map:
set(handles.popup_result,'Enable','on');
set(handles.flip_QWP_chck,'Enable','on');
set(handles.flip_HWP_chck,'Enable','on');
handles = image_result(handles);
save_util( handles, 'C:\Users\admin\Desktop\', 'res_temp.mat'); % saving just in case

% Update handles structure
guidata(hObject, handles);

function [handles, vectx, vecty, arr_2exclude, flag] = add_polar_afterend_mp(handles, vectx, vecty, arr_2exclude, n)
% % called by push_start_Callback
% % 
vectx0=vectx;  % % k
vecty0 = vecty; % % l
prompt = {'Add polar to right (QWP+)', 'Add polar to bottom (HWP+)',...
    'Add polar to left (QWP-)', 'Add polar to top (HWP-)' };
dlg_title = 'Add polar(s) ?'; def = {'0', '0', '0', '0'}; % dflt
answer = inputdlg(prompt, dlg_title, 1, def);
if isempty(answer)
    answer = def;
end
add_right = str2double(answer{1}); add_btm = str2double(answer{2});
add_left = str2double(answer{3}); add_top = str2double(answer{4});
if (add_right || add_btm)
    answer = inputdlg({'vectQWP[stR:stpR:endR]', 'vectHWP[stB:stpB:endB]'}, 'RIGHT and BOTTOM', 1,...
        {sprintf('[%d:%d:%d]', handles.QWP_range(2)+handles.QWP_resolution, handles.QWP_resolution,handles.QWP_range(2)+handles.QWP_resolution),...
        sprintf('[%d:%d:%d]', handles.HWP_range(2)+handles.QWP_resolution, handles.HWP_resolution,handles.HWP_range(2)+handles.QWP_resolution)});
    QWP_range = str2num(answer{1});  %#ok<ST2NM>
    HWP_range = str2num(answer{2});  %#ok<ST2NM>
    % % str2double gives NaN !!
    %             [QWP_add1, HWP_add1] = ndgrid(...
    %             QWP_range(1):QWP_range(2):QWP_range(3),...
    %             HWP_range(1):HWP_range(2):HWP_range(3));
    if length(HWP_range) == 1; vectHWP1 = HWP_range;
    else
        if HWP_range(1) == handles.HWP_range(2); HWP_range(1) = HWP_range(1)+HWP_range(2); % % no rep
        end
        if length(HWP_range) == 2; HWP_range(end+1) = HWP_range(end);
        end
        vectHWP1 = HWP_range(1):HWP_range(2):HWP_range(3);
    end
    if length(QWP_range) == 1;  vectQWP1 = QWP_range; 
    else
        if QWP_range(1) == handles.QWP_range(2); QWP_range(1) = QWP_range(1)+QWP_range(2); % % no rep
        end
        if length(QWP_range) == 2; QWP_range(end+1) = QWP_range(end);
        end
        vectQWP1 = QWP_range(1):QWP_range(2):QWP_range(3);
    end
    
else; vectQWP1 = [];  vectHWP1 = [];
end
if (add_left || add_top)
    answer = inputdlg({'vectQWP[stL:stpL:endL]', 'vectHWP[stT:stpT:endT]'}, 'LEFT and TOP', 1,...
        {sprintf('[%d:%d:%d]', handles.QWP_range(2)-handles.QWP_resolution, handles.QWP_resolution, handles.QWP_range(2)-handles.QWP_resolution),...
        sprintf('[%d:%d:%d]', handles.HWP_range(2)-handles.HWP_resolution, handles.HWP_resolution, handles.HWP_range(2)-handles.HWP_resolution)});
    QWP_range = str2num(answer{1});  %#ok<ST2NM>
    HWP_range = str2num(answer{2});  %#ok<ST2NM>
    % % str2double gives NaN !!
    %             [QWP_add0, HWP_add0] = ndgrid(...
    %             QWP_range(1):QWP_range(2):QWP_range(3),...
    %             HWP_range(1):HWP_range(2):HWP_range(3));
    if length(HWP_range) == 1; vectHWP0 = HWP_range;
    else
        if HWP_range(1) == handles.HWP_range(2); HWP_range(1) = HWP_range(1)+HWP_range(2); % % no rep
        end
        if length(HWP_range) == 2; HWP_range(end+1) = HWP_range(end);
        end
        vectHWP0 = HWP_range(1):HWP_range(2):HWP_range(3);
    end
    if length(QWP_range) == 1;  vectQWP0 = QWP_range; 
    else
        if QWP_range(1) == handles.QWP_range(2); QWP_range(1) = QWP_range(1)+QWP_range(2); % % no rep
        end
        if length(QWP_range) == 2; QWP_range(end+1) = QWP_range(end);
        end
        vectQWP0 = QWP_range(1):QWP_range(2):QWP_range(3);
    end
else;  vectQWP0 = []; vectHWP0 = [];
end
if (add_right || add_btm || add_left || add_top)
    flag = 1;
    if ~isempty(vectQWP0) % add_left
        vectx0=vectx0+length(vectQWP0);  % % k
    end
    if ~isempty(vectHWP0) % add_top
        vecty0=vecty0+length(vectHWP0);  % % k
    end

    vectQWP = [vectQWP0, handles.QWP_range(1):handles.QWP_resolution:handles.QWP_range(2), vectQWP1];
    vectHWP = [vectHWP0, handles.HWP_range(1):handles.HWP_resolution:handles.HWP_range(2), vectHWP1];
    [handles.QWP_values, handles.HWP_values] = ndgrid(vectQWP, vectHWP);
    [k,l] = size(handles.QWP_values); vectx = 1:k; vecty = 1:l;
    int0 = handles.intensity_measurements; handles.intensity_measurements = zeros(k,l,n);
    handles.intensity_measurements(vectx0, vecty0, :) =int0;
    % The fitted parameters from the ellipticity analysis will be stored in
    % these parameters:
    E_max0 = handles.fitted_parameters.E_max ; handles.fitted_parameters.E_max = zeros(k,1);
    handles.fitted_parameters.E_max(vectx0, vecty0, :) = E_max0;
    E_min0 = handles.fitted_parameters.E_min ; handles.fitted_parameters.E_min = zeros(k,1);
    handles.fitted_parameters.E_min(vectx0, vecty0, :) = E_min0;
    pol_angle0 = handles.fitted_parameters.pol_angle ; handles.fitted_parameters.pol_angle = zeros(k,1);
    handles.fitted_parameters.pol_angle(vectx0, vecty0, :) = pol_angle0;
    
    arr_2exclude = zeros(size( handles.HWP_values')); arr_2exclude(vecty0, vectx0) = 2; % % 1 is esclude from beginning
    set(handles.overview_figure,'position',[10,50,(k*75)+75,(l*75)+75]);
    
    if (add_left || add_top)
        ll=get(handles.overview_figure, 'children'); % axes list
        for kk=1:length(ll)
            x= 1+floor((kk-1)/vecty(end)); y = mod(kk,vecty(end)) + (~mod(kk,vecty(end)))*vecty(end);
            set(ll(kk), 'Position',[x/(vectx(end)+1), (vecty(end)-y)/(vecty(end)+1), 1/(vectx(end)+1), 1/(vecty(end)+1)]);
        end
    end
else
    flag = 0;
end

% --- Executes on button press in push_stop.
function push_stop_Callback(hObject, eventdata, handles)
% hObject    handle to push_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Sets the stop variable to true, this variable is accessible from all
% functions:
setappdata(0 , 'stop', 1);

% --- Executes on button press in push_single.
function push_single_Callback(hObject, eventdata, handles)
% hObject    handle to push_single (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Retrieves the HWP and QWP angle for the polarization measurement:
d = handles.table_single_settings.Data;
QWP = d(1); HWP = d(2);
% Rotates the QWP and HWP to specific angles:
% % handles.QWP.MoveAbsoluteRot(0,QWP,0,3,1); %m
% % handles.HWP.MoveAbsoluteRot(0,HWP,0,3,1); %m
move_rot_mp(handles.QWP_str, handles.QWP, QWP);
move_rot_mp(handles.HWP_str, handles.HWP, HWP);
% The analyzer angles:
handles.LP_values = 0:handles.LP_stepsize:180;
% Does the intensity measurement:
[handles, I] = ellipticity_analyzer(handles);

% Stores the single measurement:
handles.intensity_single = I;
handles.QWP_single = QWP;
handles.HWP_single = HWP;
handles.LP_single = handles.LP_values;

% Plots the result:
handles = plot_single(handles, I);

% Enables the "save single":
set(handles.menu_save_single,'Enable','on');

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in push_cali.
function push_cali_Callback(hObject, eventdata, handles)
% hObject    handle to push_cali (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Does the phase and reflection fitting:
handles = find_phase_and_reflection(handles);
% Determines the QWP and HWP angles that give linear and circular
% polarization at the imaging plane:
handles = solve_for_LP_and_CP(handles);

if get(handles.flip_QWP_chck, 'Value')
    [handles.table_CP.Data(1, :), handles.table_LP.Data(:, 1)] = flip_wp_mp(handles.table_CP.Data(1, :), handles.table_LP.Data(:, 1), get(handles.axes_result, 'xlim'));
    disp('I flipped QWP');
end
if get(handles.flip_HWP_chck, 'Value')
    [handles.table_CP.Data(2, :), handles.table_LP.Data(:, 2)] = flip_wp_mp(handles.table_CP.Data(2, :), handles.table_LP.Data(:, 2), ...
get(handles.axes_result, 'ylim'));
    disp('I flipped HWP');
end

% Plots the data:
handles = image_result(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes on selection change in popup_result.
function popup_result_Callback(hObject, eventdata, handles)
% hObject    handle to popup_result (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Images the polarization map as selected by the popup menu:
handles = image_result(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popup_result_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_result (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -------------------------------------------------------------------------
% ------------------- CALIBRATION FUNCTIONS: ------------------------------

% --- Measures the ellipticity of the EM wave at the detector:
function [handles,I] = ellipticity_analyzer(handles)
% handles    structure with handles and user data (see GUIDATA)
% I          the measured intensity [W] for all analyzer angles stored as
%            an array

% The angles of the analyzer for which the intensity will be measured:
LP = handles.LP_values;
% Checks the start position:
% % start_pos = handles.LP.GetPosition_Position(0); %m
start_pos = get_pos_mp(handles.LP_str, handles.LP);
% For a linear polarizer 180 degrees = 0 degrees:
if start_pos >= 180
    start_pos = 360-start_pos;
end
% Changes the order if the start position is closer to 180deg than 0deg:
if start_pos > 90
    LP = LP(end:-1:1);
    change_order = 1;
else
    change_order = 0;
end

% Empty array to enter the measured intensity:
I = zeros(1,length(LP));

% Time required to take one measurement:
t = sum(handles.meas_time.*[3600 60 1]);

% Measures the intensity as a function of the angles of the analyzer:
for i = 1:length(LP)
    % Moves the analyzer to the correct angle:
%     handles.LP.MoveAbsoluteRot(0,LP(i),0,3,1); %m
    move_rot_mp(handles.LP_str, handles.LP, LP(i))
    % Asks the power meter to take a measurement:
% %     handles.EM.SendCommandOrQuery(0,'CONFigure:STATistics:STARt'); 
    % Wait for the power meter to finish:
     pause(t);
    % Acquires the measurement (will be an array containing: AV, DEV, MIN, 
    % MAX, DOSE, MISSED, SEQ):
% %     handles.EM.SendCommandOrQuery(0,'STATistics:FETCh:NEXT?'); 
% %     r = str2num(handles.EM.GetNextString(0)); 
% %     % Check if the measurement has been received:
% %     while isempty(r)
% %         handles.EM.SendCommandOrQuery(0,'STATistics:FETCh:NEXT?'); 
% %         r = str2num(handles.EM.GetNextString(0)); 
% %     end
    % Sets the intensity equal to the average:
    maxj = round(handles.meas_freq*(handles.meas_time(1)*3600+handles.meas_time(2)*60+handles.meas_time(3))); % h m s
    tmp = zeros(1, maxj);
    for jj =1:maxj
        if (isfield(handles, 'libdaq') && ~isempty(handles.libdaq)) % % 
            tmp(jj) = daq_read_mp(handles.libdaq, handles.EM, handles);
        else
            tmp(jj) = str2double(query(handles.EM,':POWER?')); %r(1); % p
        end
    end
% %     disp(tmp) % it's ok, there is no latencies
    I(i) = median(tmp); % it's a median
end
% If the LP order was inverted:
if change_order == 1
    % Inverts the order of the measured intensities:
    I = I(end:-1:1);
end

function val = daq_read_mp(libdaq, EM, handles)
% % handles.EM = taskh.AI_10;

timeout = 1; numchanAI = 1; numsample = 1;
 val =DAQmxReadAnalogF64(handles.libdaq, EM,handles.DAQmx_Val_Auto,timeout, handles.DAQmx_Val_GroupByScanNumber,numchanAI,numsample);

% --- Plots the polarization of the laser for a given HWP and QWP angle
% --- combination as part of the polarization map:
function [handles,p] = plot_polarization(handles, i, j)
% handles    structure with handles and user data (see GUIDATA)
% i, j       the index of the QWP and HWP of the current measurement
% p          the parameters from the fitting

% Retrieves the correct measurement based on the current QWP and HWP angle:
I = squeeze(handles.intensity_measurements(i,j,:))';
LP = handles.LP_values;
% Adds the inverted datapoints such that the measurement is
% centro-symmetric:
I = [I I];
LP = [LP LP+180];
% Converts the intensity and angles from polar coordinates to cartesian
% coordinates:
[x,y] = pol2cart(deg2rad(LP),I);
% Does a curve fitting to determine the maximum and minimum electric
% amplitude and the rotation of the distribution:
p = lsqcurvefit(@intensity_fitting,[1,0.5,0],LP,I);
% Creates the fitted curve:
LP_fit = 0:360;
I_fit = (p(1)*cosd(LP_fit-p(3))).^2 + (p(2)*sind(LP_fit-p(3))).^2;
[x_fit,y_fit] = pol2cart(deg2rad(LP_fit),I_fit);

% Plots the fitted curve and the data points:
axes(handles.axes_single);
plot(x,y,'b.',x_fit,y_fit,'r')
axis('equal')

% Stores the fitted parameters:
E = sort(p(1:2));
handles.fitted_parameters.E_max(i,j) = E(2);
handles.fitted_parameters.E_min(i,j) = E(1);
% The fitted angle is always the angle between the x-axis and p(1), while 
% we want the angle between the x-axis and the maximum component of the 
% electric field. Therefor if p(1) is the minimum component we should add 
% 90 degrees to the angle:
if E(1) == p(1)
    p(3) = p(3)+90;
end
% Converts the angle to the range 0-180degrees:
p(3) = p(3) - floor(p(3)/180)*180;
handles.fitted_parameters.pol_angle(i,j) = p(3);

% Enters the measurement in the single measurement table:
handles.table_single_settings.Data = [handles.QWP_values(i,j) ...
    handles.HWP_values(i,j)];
handles.table_single_results.Data = [E(1)^2 E(2)^2 round(p(3))];

% Plots the polarization in the overview image:
figure(handles.overview_figure)
[k,l] = size(handles.QWP_values);
h = subplot('Position',[i/(k+1),(l-j)/(l+1),1/(k+1),1/(l+1)]);
plot(x,y,'b.',x_fit,y_fit,'r');
% fact = 0.22;
% axis([-fact, fact, -fact, fact])
% set other fact
% get(gcf, 'Children');
% for ii=1:28
%     axes(ans(ii));  fact = 2; axis([-fact, fact, -fact, fact])
% end
% uiopen('E:\MAXIME\Carac microscope\Polar control�e\polar measurement\stage_path_nothing\HWP_QWP_ellipticity.fig',1)
axis('equal')
set(h,'xtick',[],'ytick',[],'box','off','xcolor','w','ycolor','w')
if j == 1 && i == ceil(k/2)
    title({'QWP [deg]';num2str(handles.QWP_values(i,j))},'fontweight','normal')
elseif j == 1
    title(num2str(handles.QWP_values(i,j)),'fontweight','normal')
end
if i == 1 && j == ceil(l/2)
    ylabel({'HWP [deg]';num2str(handles.HWP_values(i,j))})
    set(h,'ycolor','k')
elseif i == 1
    ylabel(num2str(handles.HWP_values(i,j)))
    set(h,'ycolor','k')
end

% --- Plots the polarization of the laser for a single measurement:
function [handles] = plot_single(handles, I)
% handles    structure with handles and user data (see GUIDATA)
% I          the intensity measurements

% The analyzer angles:
LP = handles.LP_values;
% Adds the inverted datapoints such that the measurement is
% centro-symmetric:
I = [I I];
LP = [LP LP+180];
% Converts the intensity and angles from polar coordinates to cartesian
% coordinates:
[x,y] = pol2cart(deg2rad(LP),I);
% Does a curve fitting to determine the maximum and minimum electric
% amplitude and the tilt of the distribution:
p = lsqcurvefit(@intensity_fitting,[1,0.5,0],LP,I);
% Creates the fitted curve:
LP_fit = 0:360;
I_fit = (p(1)*cosd(LP_fit-p(3))).^2 + (p(2)*sind(LP_fit-p(3))).^2;
[x_fit,y_fit] = pol2cart(deg2rad(LP_fit),I_fit);

% Plots the fitted curve and the data points:
axes(handles.axes_single);
plot(x,y,'b.',x_fit,y_fit,'r')
axis('equal')

% The maximum and minimum electric field component:
E = sort(p(1:2));
% The fitted angle is always the angle between the x-axis and p(1), while 
% we want the angle between the x-axis and the maximum component of the 
% electric field. Therefor if p(1) is the minimum component we should add 
% 90 degrees to the angle:
if E(1) == p(1)
    p(3) = p(3)+90;
end
% Converts the angle to the range 0-180degrees:
p(3) = p(3) - floor(p(3)/180)*180;

% Enters the results in the table:
handles.table_single_results.Data = [E(1)^2 E(2)^2 round(p(3))];

fprintf('\n ell %.3f\n', E(1)^2/E(2)^2);

% --- Determines the phase and reflection introduced by optical elements in
% --- the microscope:
function [handles] = find_phase_and_reflection(handles)
% handles    structure with handles and user data (see GUIDATA)

% Gathers the input variables for the fitting:
[k,l] = size(handles.QWP_values);
LP = repmat(reshape(handles.LP_values,1,1,[]),k,l);
QWP = repmat(handles.QWP_values,1,1,length(handles.LP_values));
HWP = repmat(handles.HWP_values,1,1,length(handles.LP_values));
X = [HWP(:) QWP(:) LP(:)];
I = handles.intensity_measurements;
% Fits the polarization measurements:
P = lsqcurvefit(@polarization_fitting,[0.1,1,0,0,0,0],...
    X,I(:));

% The found parameters:
% Max intensity:
handles.fitted_parameters.I0 = P(1);
% The reflection coefficient:
handles.fitted_parameters.gamma = P(2);
% The angular difference between the reflection axis and the HWP (at 0deg):
handles.fitted_parameters.HWP_diff = P(3);
% The angular difference between the reflection axis and the QWP (at 0deg):
handles.fitted_parameters.QWP_diff = P(4);
% The angular difference between the reflection axis and the LP (at 0deg):
handles.fitted_parameters.LP_diff = P(5);
% The induced phase along the reflection axis:
handles.fitted_parameters.delta = P(6);

% --- Finds the HWP and QWP combinations that create LP and CP light:
function [handles] = solve_for_LP_and_CP(handles)
% handles    structure with handles and user data (see GUIDATA)

% The parameters from the phase and reflection fitting:
delta = handles.fitted_parameters.delta;
gamma = handles.fitted_parameters.gamma;
QWP_diff = handles.fitted_parameters.QWP_diff;
HWP_diff = handles.fitted_parameters.HWP_diff;

% Solves theoretical model for circularly polarized light:
% Equation 1:
syms phi;
x = atan(-gamma*sind(delta)/(gamma*cosd(delta)*tan(phi)-1)); %#ok<NODEF>
y = atan((gamma*cosd(delta)-tan(phi))/(gamma*sind(delta)*tan(phi)));
phi = solve(x == y,phi,'IgnoreAnalyticConstraints',true); %k = 1;  % !!!
phi = eval(phi);
WP_diff(1:2) = rad2deg(eval(x));
QWP_rel(1:2) = rad2deg(phi);
% Equation 2:
syms phi;
x =  atan(-gamma*sind(delta)/(gamma*cosd(delta)*tan(phi)+1));
y = atan((gamma*cosd(delta)+tan(phi))/(gamma*sind(delta)*tan(phi)));
phi = solve(x == y,phi,'IgnoreAnalyticConstraints',true); 
% k = 1;  % !!!
phi = eval(phi);
WP_diff(3:4) = rad2deg(eval(x));
QWP_rel(3:4) = rad2deg(phi);
HWP_rel = (WP_diff + QWP_rel)/2;
% The results:
HWP_circ = HWP_rel + HWP_diff;
QWP_circ = QWP_rel + QWP_diff;
HWP_circ = (HWP_circ-90*floor(HWP_circ/90));
QWP_circ = (QWP_circ-180*floor(QWP_circ/180));
% Enters the results in appropriate table:
if handles.QWP_values(1) > 180
    QWP_circ = QWP_circ + 180; % %  mp !!!
end
% HWP_circ = HWP_circ + handles.HWP_values(1); % %  mp !!!
if handles.HWP_values(1) > 180
    HWP_circ = HWP_circ + 180; % %  mp !!!
end
handles.table_CP.Data = [QWP_circ;HWP_circ];

% Solves theoretical model for LP light:
WP_diff = (0:1:180);
QWP_rel = zeros(2,length(WP_diff));
for i = 1:length(WP_diff)
    QWP_rel(1,i) = 0.5*atand(-tand(delta)*sind(2*WP_diff(i)));
    QWP_rel(2,i) = 0.5*(180+atand(-tand(delta)*sind(2*WP_diff(i))));
end
HWP_rel = 0.5*([WP_diff;WP_diff]+QWP_rel);
% The results:
HWP_LP = HWP_rel(:) + HWP_diff;
QWP_LP = QWP_rel(:) + QWP_diff;
HWP_LP = (HWP_LP-90*floor(HWP_LP/90));
QWP_LP = (QWP_LP-180*floor(QWP_LP/180));

% The polarization angle and intensity is also of interest for the settings 
% that create linearly polarized light:
I_LP = zeros(length(HWP_LP),1);
angle_LP = zeros(length(HWP_LP),1);
% For all HWP and QWP combinations that provide linearly polarized light:
for i = 1:length(HWP_LP)
    % The variables:
    LP = 0:10:360; n = length(LP);
    QWP = repmat(QWP_LP(i),1,n);
    HWP = repmat(HWP_LP(i),1,n);
    X = [HWP(:) QWP(:) LP(:)];
    % The parameters:
    P(1) = handles.fitted_parameters.I0;
    P(2) = handles.fitted_parameters.gamma;
    P(3) = handles.fitted_parameters.HWP_diff;
    P(4) = handles.fitted_parameters.QWP_diff;
    P(5) = handles.fitted_parameters.LP_diff;
    P(6) = handles.fitted_parameters.delta;
    % Finds the intensity distribution as a function of the analyzer (LP):
    I = polarization_fitting(P,X);
    % Does a fitting of the intensity to get more precise results:
    p = lsqcurvefit(@intensity_fitting,[1,0.5,0],LP,I');
    % Finds the maximum intensity:
    E = sort(p(1:2));
    I_LP(i) = E(2)^2;
    % The fitted angle is always the angle between the x-axis and p(1),  
    % while we want the angle between the x-axis and the maximum component 
    % of the electric field. Therefor if p(1) is the minimum component we 
	% should add 90 degrees to the angle:
    if E(1) == p(1)
        p(3) = p(3)+90;
    end
    p(3) = p(3) - floor(p(3)/180)*180;
    angle_LP(i) = round(p(3));
end
% Sorts the values based on the polarization angle:
[angle_LP,i] = sort(angle_LP); % i = 1:length(HWP_LP)

% QWP_LP(i) = QWP_LP(i) + handles.QWP_values(1); % %  mp !!!
% HWP_LP(i) = HWP_LP(i) + handles.HWP_values(1); % %  mp !!!
if handles.QWP_values(1) > 180
    QWP_LP(i) = QWP_LP(i) + 180; % %  mp !!!
end
if handles.HWP_values(1) > 180
    HWP_LP(i) = HWP_LP(i) + 180; % %  mp !!!
end

% Stores the linearly polarized data in the appropriate table:
handles.table_LP.Data = [QWP_LP(i) HWP_LP(i) I_LP(i) angle_LP]; % i = 1:length(HWP_LP)

% --- Deletes all previous results:
function [handles] = clear_results(handles)
% handles    structure with handles and user data (see GUIDATA)

% Sets all table values to zero:
handles.table_single_results.Data = [];
handles.table_CP.Data = [];
handles.table_LP.Data = [];
handles.fitted_parameters = [];

% Removes the previous fitted ellipses and other results:
cla(handles.axes_single)
cla(handles.axes_result)

% Disables the appropriate buttons and options:
set(handles.menu_save,'Enable','off');
set(handles.push_cali,'Enable','off');
set(handles.popup_result,'Enable','off');
set(handles.flip_QWP_chck,'Enable','off');
set(handles.flip_HWP_chck,'Enable','off');

for ii=2:5
    try  %#ok<TRYNC>
        close(ii); % figs, not GUI
    end
end

% --- Images a calibrated parameter in the result window:
function [handles] = image_result(handles)
% handles    structure with handles and user data (see GUIDATA)

% Collects which result should be imaged:
v = get(handles.popup_result,'value');

switch v
    case 1 % Intensity:
        E_min = handles.fitted_parameters.E_min;
        E_max = handles.fitted_parameters.E_max;
        r = E_min.^2 + E_max.^2;
        c = [0 max(r(:))];
        cm = 'jet';
    case 2 % Minimum intensity:
        E_min = handles.fitted_parameters.E_min;
        r = E_min.^2;
        c = [0 max(r(:))];
        cm = 'jet';
    case 3 % Maximum intensity:
        E_max = handles.fitted_parameters.E_max;
        r = E_max.^2;
        c = [0 max(r(:))];
        cm = 'jet';
    case 4 % Ratio between min and max I:
        E_min = handles.fitted_parameters.E_min;
        E_max = handles.fitted_parameters.E_max;
        r = E_min./E_max;
        c = [0 1];
        cm = 'jet';
    case 5 % Maximum intensity angle:
        r = handles.fitted_parameters.pol_angle;
        c = [0 180];
        cm = 'hsv';
end
% [k,l] = size(r); % !!!
% Plots the result:
axes(handles.axes_result)
x = handles.QWP_values(:,1)';
y = handles.HWP_values(1,:);
imagesc(handles.axes_result, x, y, r', c)
axis equal; axis tight;
xlabel('QWP [deg]'); ylabel('HWP [deg]');
set(gca,'XAxisLocation','top','XTick',x(1:2:end),'YTick',y(1:2:end))
colormap(cm); colorbar;

% Checks if the calibration has been done:
if isempty(handles.table_CP.Data) || isempty(handles.table_LP.Data)
    % If no, the function is terminated here
    return;
end

% Plots the data for circularly and linearly polarized light:
D_CP = handles.table_CP.Data;
D_LP = handles.table_LP.Data;

hold(handles.axes_result, 'on');
plot(handles.axes_result, D_CP(1,:),D_CP(2,:),'ko', D_LP(:,1), D_LP(:,2), 'kx','linewidth',2);
xx1 = (x(1)>180)*180;  yy1 = floor(y(1)/90)*90;
axis([xx1-5, xx1+180+5, yy1-5, yy1+90+5]) %  mp !!!
set(gca,'XTick',xx1:max(20,abs(x(2)-x(1))):max(xx1+180, x(end)), ...
    'YTick',yy1:max(20,abs(y(2)-y(1))):max(yy1+90, y(end))) %  mp !!!
legend('Circular polarization','Linear polarization');
hold(handles.axes_result, 'off');

% -------------------------------------------------------------------------
% ------------------- Functions that are used for fitting -----------------

% --- The intensity fitting to determine the polarization:
function I = intensity_fitting(p,a)
% p         The parameters that will be fitted. Here p(1) and p(2) are two
%           perpendicular electric amplitudes. Where the one is the maximum 
%           and the other the minimum amplitude. p(3) is the angle between 
%           the x-axis and the direction of p(1) (independent of if this is 
%           the minimum or maximum).
% a         An array containing an overview of the analyzer angles for 
%           which the intensity was measured 
% I         An array containing the intensities that correspond to the 
%           given input angles and fitted parameters.

I = (p(1)*cosd(a-p(3))).^2 + (p(2)*sind(a-p(3))).^2;

% --- The relation between intensity, analyzer, HWP and QWP angles and
% --- microscope specific parameters:
function I = polarization_fitting(P,X)
% P         Microscope parameters
% X         The variables (i.e. HWP, QWP and analyzer angles)
% I         An array containing the intensities that correspond to the 
%           given input angles and parameters.

% The variables:
HWP = X(:,1); QWP = X(:,2); LP = X(:,3);

% The paramters:
I0 = P(1); gamma = P(2); HWP_diff = P(3); 
QWP_diff = P(4); LP_diff = P(5); delta = P(6);

% The relative angles:
theta = HWP-HWP_diff; phi = QWP-QWP_diff; alpha = LP-LP_diff;

% The function describing how the intensity depends on the analyzer, QWP
% and HWP angle:
d1 = -gamma*(cosd(delta)*sind(phi).*sind(2*theta-phi) + ...
    sind(delta)*cosd(phi).*cosd(2*theta-phi));
d2 = -gamma*(sind(delta)*sind(phi).*sind(2*theta-phi) - ...
    cosd(delta)*cosd(phi).*cosd(2*theta-phi));
d3 = sind(phi).*cosd(2*theta-phi);
d4 = cosd(phi).*sind(2*theta-phi);

I = I0*((d1.^2 + d2.^2).*(cosd(alpha).^2) + ...
    (d3.^2 + d4.^2).*(sind(alpha).^2) + ...
    2*(d1.*d3 + d2.*d4).*sind(alpha).*cosd(alpha));

% -------------------------------------------------------------------------
% ----------- Connecting and disconnecting the activeX controls: ----------

% --- Connects to the motors and power meter:
function handles = connect_actx(handles, ins_str, names, ii, instr, part)
% handles    structure with handles and user data (see GUIDATA)
% connected  boolean stating if the connection was successfull

% Connects to the power meter:
% handles.EM.Initialize(); %p

% Sets the communication mode to USB:
% set(handles.EM,'CommunicationMode',1); %p
% Checks the serial number:
% % if isempty(handles.EM.SerialNumber(0)) %p
% %     handles = disconnect_actx(handles);
% %     warning('Could not connect to the power meter.');
% %     connected = 0;
% %     return
% % else
% %     connected = 1;
% % end
% if (isfield(handles, 'EM') && ~handles.dev_on_list(1))  %p
%     handles.dev_on_list(1) = stctrl_instr_mp(handles, handles.EM_str, handles.EM);
%     disp('EM instr ON')
% %     connected = 1;
% end
% not used : units are always watt, acq time not settable !!!!!

% % Sets the units to watt:
% handles.EM.SendCommandOrQuery(0,'CONFigure:MEASure W'); %p

% % Sets the laser wavelength:
% handles.EM.SendCommandOrQuery(0,'CONFigure:WAVElength:CORRection ON'); %p
% handles.EM.SendCommandOrQuery(0,['CONFigure:WAVElength:WAVElength ' ...
%     num2str(handles.wavelength)]); %p

% % Sets the acquisition time of the power meter:
% handles.EM.SendCommandOrQuery(0,['CONFigure:STATistics:BSIZe:TIME ' ...
%     num2str(handles.meas_time(1),'%02.0f') ...
%     ':' num2str(handles.meas_time(2),'%02.0f') ...
%     ':' num2str(handles.meas_time(3),'%02.0f')]); %p

% % Sets the frequency of the power meter:
% handles.EM.SendCommandOrQuery(0,['CONFigure:STATistics:RATE:FREQuency ' ...
%     num2str(handles.meas_freq)]); %p

% % Determines if the data sent from the machine should have any headers:
% handles.EM.SendCommandOrQuery(0,'CONFigure:READings:HEADers OFF'); %p
% % Sets that we want the last available record and not a stream:
% handles.EM.SendCommandOrQuery(0,'CONFigure:READings:CONTinuous LAST'); %p

% % Changes the display to the statistics mode:
% handles.EM.SendCommandOrQuery(0,'CONFigure:DISPlay:STATistics'); %p
% % Enables the collection of statistical data for sending to the host:
% handles.EM.SendCommandOrQuery(0,'STATistics:INITiate'); %p
% % Collects all data in case there is any registered:
% handles.EM.SendCommandOrQuery(0,'STATistics:FETCh:ALL?'); %p
% handles.EM.GetNextString(0); %p

% Initializes the motors:
% % handles.LP.StartCtrl; %m
% % handles.HWP.StartCtrl; %m
% % handles.QWP.StartCtrl; %m

% % instrs=[handles.LP, handles.QWP, handles.HWP];
switch part
    case 1
        if (isfield(handles, names{ii+1}) && ~handles.dev_on_list(ii+1))
            disp(['checking ' ins_str{ii+1} ' ...']);
            try
                [connected, handles] = stctrl_instr_mp(handles, ins_str{ii+1}, instr);
            catch ME
                fprintf('ERR devices %s \n', ins_str{ii+1});
                rethrow(ME);
            end
            handles.dev_on_list(ii+1) = connected; % EM, LP, QWP, HWP
        end
    case 2
        if handles.dev_on_list(ii+1)
            if strcmp(ins_str{ii+1},'thorlabs')
                pause(0.5) % Gives the GUI time to update:
            elseif (ii == 0 && isfield(handles, 'funclistNIdaq')) % % effct-meter NI
                handles = daq_openchan_mp(handles);
                fprintf('DAQ read is %f\n', daq_read_mp(handles.libdaq, handles.EM, handles));
            else
                wait_move(instr, ins_str{ii+1});
                if strcmp(ins_str{ii+1},'newport')
                    disp(query(instr,'1TP?\r'));
                elseif strcmp(ins_str{ii+1},'micos')
                    disp(query(instr,'1 npos ')); % get pos
                end
            end
            fprintf('\n %s instr ON \n', ins_str{ii+1})
        end
end

% --- Disconnects the motors and power meters:
function [handles] = disconnect_actx(handles)
% handles    structure with handles and user data (see GUIDATA)

% Stops the motors:
% % handles.LP.StopCtrl; %m
% % handles.HWP.StopCtrl; %m
% % handles.QWP.StopCtrl; %m
if handles.avl_list(2)% [com_str_EM, com_str_LP, com_str_qwp, com_str_hwp]
    close_com_mp(handles.LP_str, handles.LP, handles.dev_on_list(2));
    disp('LP discon.');
    handles.avl_list(2) = 0;
    handles.dev_on_list(2) = 0;
end
if handles.avl_list(4)
    close_com_mp(handles.HWP_str, handles.HWP, handles.dev_on_list(4));
    disp('HWP discon.');
    handles.avl_list(4) = 0;
    handles.dev_on_list(4) = 0;

end
if handles.avl_list(3)
    close_com_mp(handles.QWP_str, handles.QWP, handles.dev_on_list(3));
    disp('QWP discon.');
    handles.avl_list(3) = 0;
    handles.dev_on_list(3) = 0;

end

% Disables the collection of data:
% handles.EM.SendCommandOrQuery(0,'STATistics:ABORt'); %p
% % Discontect the meter:
% handles.EM.DeInitialize(); %p
handles = disco_EM_mp(handles);

handles.deco = 1;

function handles = disco_EM_mp(handles)

% if handles.avl_list(1)
if (isfield(handles, 'libdaq') && ~isempty(handles.libdaq)) % % 
    if isa(handles.EM, 'lib.pointer')
        err = calllib(handles.libdaq,'DAQmxClearTask',handles.EM);
        DAQmxCheckError(handles.libdaq, err);
    end
    % % unload library
    if libisloaded(handles.libdaq); unloadlibrary(handles.libdaq) % checks if library is loaded
    end
else
    fclose(handles.EM);%p
end
disp('EM discon.');
handles.avl_list(1) = 0;
handles.dev_on_list(1) = 0;
% end

function handles = daq_openchan_mp(handles)

if isa(handles.EM, 'lib.pointer')
    err = calllib(handles.libdaq,'DAQmxClearTask',handles.EM);
    DAQmxCheckError(handles.libdaq,err);
end
if strcmp(handles.devNIread, 'Dev2') % % 6259
    mode = 'RSE';
elseif strcmp(handles.devNIread, 'Dev1') % % 6110
    mode = 'pseudodiff';
end
taskh.AI_10 = DAQmxCreateAIVoltageChan(handles.libdaq, 'Dev1/ai0', 0, 10, mode); % % change here Vmin Vmax in V !!
% configure AI sampling rate/clock
	% C function:
	% int32 DAQmxCfgSampClkTiming (TaskHandle taskHandle,const char source[],float64 rate,int32 activeEdge,int32 sampleMode,uInt64 sampsPerChanToAcquire);
source = ''; % empty means to use onboard clock
rate = 0.1e6; % sampling rate in Hz
sampsPerChanToAcquire = 2;
[err,~] = calllib(handles.libdaq,'DAQmxCfgSampClkTiming',taskh.AI_10,...
	source,rate,handles.DAQmx_Val_Rising,handles.DAQmx_Val_FiniteSamps,sampsPerChanToAcquire);
DAQmxCheckError(handles.libdaq,err);
[err,~] = calllib(handles.libdaq,'DAQmxTaskControl',taskh.AI_10,handles.DAQmx_Val_Task_Verify);
DAQmxCheckError(handles.libdaq,err);
handles.EM = taskh.AI_10;

% -------------------------------------------------------------------------
% -------------------------- MENU FUNCTIONS: ------------------------------

% --------------------------------------------------------------------
function menu_open_Callback(hObject, eventdata, handles)
% hObject    handle to menu_open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Lets the user select the matlab file that will be opened:
[file, path] = uigetfile('*.mat','Select the MATLAB file containing the results');
% Checks if the action is canceled:
if file == 0
    return;
end
% Clears all previous results:
handles = clear_results(handles);

pp = [path file];
% Loads the variables to the workspace:
load(pp); %#ok<LOAD>
ppp=pp(pp~= ' '); disp(pp);
set(handles.path_disp, 'String', ppp(end-95:end-3)); %(end-49:end));

try
    handles.QWP_values = measured_parameters.QWP;
    handles.HWP_values = measured_parameters.HWP;
    handles.intensity_measurements = measured_parameters.I;
    handles.LP_values = measured_parameters.LP;
    handles.fitted_parameters = fitted_parameters.polarization;
    if isfield(fitted_parameters,'map')
        if isfield(fitted_parameters.map,'I0')
            handles.fitted_parameters.I0 = fitted_parameters.map.I0;
            handles.fitted_parameters.gamma = fitted_parameters.map.gamma;
            handles.fitted_parameters.HWP_diff = fitted_parameters.map.HWP_diff;
            handles.fitted_parameters.QWP_diff = fitted_parameters.map.QWP_diff;
            handles.fitted_parameters.LP_diff = fitted_parameters.map.LP_diff;
            handles.fitted_parameters.delta = fitted_parameters.map.delta;
            if get(handles.calc_res_if_open_chck, 'Value') % % calc res if just load
                handles = solve_for_LP_and_CP(handles);
            else
                res = 2-menu('load .txt res ?', 'yes', 'no');
                if res == 1 % not 2
                    [file1, path1] = uigetfile(fullfile(path, '*.txt'),'Select the TXT of treated');
                    cd(path1);
                    fid=fopen(file1);
                    tline = fgetl(fid); 
                    ct =0; circdata = []; linpoldata = [];
                    while ischar(tline)
                        ct = ct+1;
                        %     disp(tline)
                        if (ct > 2 && ct <= 6)
                            circdata(:, end+1 ) = cell2mat(textscan(tline, '%f %f', 'delimiter', ' ')); %#ok<AGROW>
                        elseif ct > 8
                            linpoldata(end+1, :) = cell2mat(textscan(tline, '%f %f %f %f', 'delimiter', ' ')); %#ok<AGROW>
                        end
                        tline = fgetl(fid);
                    end
                    handles.table_CP.Data = circdata;
                    handles.table_LP.Data = linpoldata;
                    fclose(fid);
                end
            end
        end
    end
catch ME
    disp('Could not load the data');
    disp(ME.message);
    return;
end

% Enables the save option:
set(handles.menu_save,'Enable','on');
set(handles.push_cali,'Enable','on');
% Enables the posibility to image results:
set(handles.popup_result,'Enable','on');
set(handles.flip_QWP_chck,'Enable','on');
set(handles.flip_HWP_chck,'Enable','on');
handles = image_result(handles);

% Update handles structure
guidata(hObject, handles);

function handles = combine_results(handles, measured_parameters, fitted_parameters, axis)

list1 = {handles.QWP_values, handles.HWP_values, handles.intensity_measurements, ...
    handles.fitted_parameters.E_max, handles.fitted_parameters.E_min, handles.fitted_parameters.pol_angle};
list_add = { measured_parameters.QWP, measured_parameters.HWP, measured_parameters.I, fitted_parameters.polarization.E_max, ...
    fitted_parameters.polarization.E_min, fitted_parameters.polarization.pol_angle};
for ii = 1:length(list_add)
    if axis > 0
        list1{ii} = cat(abs(axis), list1{ii}, list_add{ii});
    else
        list1{ii} = cat(abs(axis), list_add{ii}, list1{ii});
    end
end
handles.QWP_values = list1{1};
handles.HWP_values = list1{2}; 
handles.intensity_measurements = list1{3};
handles.fitted_parameters.E_max = list1{4};
handles.fitted_parameters.E_min = list1{5}; 
handles.fitted_parameters.pol_angle = list1{6};
if isfield(fitted_parameters,'map')
    if isfield(fitted_parameters.map,'I0')
        handles.fitted_parameters.I0 = fitted_parameters.map.I0;
        handles.fitted_parameters.gamma = fitted_parameters.map.gamma;
        handles.fitted_parameters.HWP_diff = fitted_parameters.map.HWP_diff;
        handles.fitted_parameters.QWP_diff = fitted_parameters.map.QWP_diff;
        handles.fitted_parameters.LP_diff = fitted_parameters.map.LP_diff;
        handles.fitted_parameters.delta = fitted_parameters.map.delta;
    end
end


% --------------------------------------------------------------------
function menu_save_Callback(hObject, eventdata, handles)
% hObject    handle to menu_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Lets the user choose file name and folder:
[file, path] = uiputfile('*.mat','Save Results As');
% Checks if the action is canceled:
if file == 0
    return;
end

save_util( handles, path, file);
flip_str = '';
if get(handles.flip_QWP_chck, 'Value')
    flip_str = sprintf('%s_flipQWP', flip_str);
end
if get(handles.flip_HWP_chck, 'Value')
    flip_str = sprintf('%s_flipHWP', flip_str);
end
if ~isempty(handles.table_CP.Data) && ~isempty(handles.table_LP.Data)
    % Opens a file to write the HWP and QWP values to:
    FID = fopen([path file(1:end-4) flip_str '.txt'],'w');
    % Stores the circular polarization settings:
    t = 'Circular polarization:\nQWP [deg] HWP [degrees]\n';
    fprintf(FID, t);
    d = handles.table_CP.Data;
    f = '%d %d\n';
    fprintf(FID,f,d);
    % Stores the linear polarization settings:
    t = 'Linear polarization:\nQWP [deg] HWP [degrees] Intensity [W] Polarization angle [deg]\n';
    fprintf(FID, t);
    d = handles.table_LP.Data;
    f = '%d %d %f %d\n';
    fprintf(FID,f,d');
    fclose(FID);
end

function save_util( handles, path, file)
% Collects the variables that will be saved:
measured_parameters.QWP = handles.QWP_values;
measured_parameters.HWP = handles.HWP_values;
measured_parameters.I = handles.intensity_measurements;
measured_parameters.LP = handles.LP_values; %#ok<STRNU>
fitted_parameters.polarization.E_max = handles.fitted_parameters.E_max;
fitted_parameters.polarization.E_min = handles.fitted_parameters.E_min;
fitted_parameters.polarization.pol_angle = handles.fitted_parameters.pol_angle;
if isfield(handles.fitted_parameters,'I0')
    if ~isempty(handles.fitted_parameters.I0)
        fitted_parameters.map.I0 = handles.fitted_parameters.I0;
        fitted_parameters.map.gamma = handles.fitted_parameters.gamma;
        fitted_parameters.map.HWP_diff = handles.fitted_parameters.HWP_diff;
        fitted_parameters.map.QWP_diff = handles.fitted_parameters.QWP_diff;
        fitted_parameters.map.LP_diff = handles.fitted_parameters.LP_diff;
        fitted_parameters.map.delta = handles.fitted_parameters.delta; %#ok<STRNU>
    end
end
% Saves the results:
save([path file],'measured_parameters','fitted_parameters');


% --------------------------------------------------------------------
function menu_save_single_Callback(hObject, eventdata, handles)
% hObject    handle to menu_save_single (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Lets the user choose file name and folder:
[file, path] = uiputfile('*.mat','Save Single Measurement As');

% Collects the variables that will be saved:
I = handles.intensity_single; %#ok<NASGU>
LP = handles.LP_single; %#ok<NASGU>
QWP = handles.QWP_single; %#ok<NASGU>
HWP = handles.HWP_single; %#ok<NASGU>
% Saves the variables:
save([path file],'I','LP','QWP','HWP');
  
% --------------------------------------------------------------------
function menu_prop_Callback(hObject, eventdata, handles)
% hObject    handle to menu_prop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Collects all the parameters that can be changed:
if (strcmp(handles.LP_str , 'thorlabs') && isa(handles.LP, 'COM.MGMOTOR_MGMotorCtrl_1'))
    in.HWSerialNum(1,1) = handles.LP.HWSerialNum;
else
    in.HWSerialNum(1,1) = 0;
end
if (strcmp(handles.HWP_str , 'thorlabs') && isa(handles.HWP, 'COM.MGMOTOR_MGMotorCtrl_1'))
    in.HWSerialNum(2,1) = handles.HWP.HWSerialNum;
else
    in.HWSerialNum(2,1) = 0;
end
if (strcmp(handles.QWP_str , 'thorlabs') && isa(handles.QWP, 'COM.MGMOTOR_MGMotorCtrl_1'))
    in.HWSerialNum(3,1) = handles.QWP.HWSerialNum;
else
    in.HWSerialNum(3,1) = 0;
end
in.LP_stepsize = handles.LP_stepsize;
in.wavelength = handles.wavelength;
in.meas_time = handles.meas_time;
in.meas_freq = handles.meas_freq;
in.HWP_resolution = handles.HWP_resolution;
in.QWP_resolution = handles.QWP_resolution;
in.HWP_range = handles.HWP_range;
in.QWP_range = handles.QWP_range;
in.arr_2exclude = handles.arr_2exclude;

% Calls the properties editor:
out = properties_polarization_map(in);
% Checks if the action was canceled:
if isempty(out)
    return
end

% Stores all the data that could be changed:
if (strcmp(handles.LP_str , 'thorlabs') && isa(handles.LP, 'COM.MGMOTOR_MGMotorCtrl_1'))
    handles.LP.HWSerialNum = out.HWSerialNum(1);
end
if (strcmp(handles.HWP_str , 'thorlabs') && isa(handles.HWP, 'COM.MGMOTOR_MGMotorCtrl_1'))
    handles.HWP.HWSerialNum = out.HWSerialNum(2);
end
if (strcmp(handles.QWP_str , 'thorlabs') && isa(handles.QWP, 'COM.MGMOTOR_MGMotorCtrl_1'))
    handles.QWP.HWSerialNum = out.HWSerialNum(3);
end
handles.LP_stepsize = out.LP_stepsize;
handles.wavelength = out.wavelength;
handles.meas_time = out.meas_time;
handles.meas_freq = out.meas_freq;
handles.HWP_resolution = out.HWP_resolution;
handles.QWP_resolution = out.QWP_resolution;
handles.HWP_range = out.HWP_range;
handles.QWP_range = out.QWP_range;
handles.arr_2exclude = out.arr_2exclude;
disp('in main');
disp(cat(2, [NaN; (handles.HWP_range(1):handles.HWP_resolution:handles.HWP_range(2))'], ...
cat(1, (handles.QWP_range(1):handles.QWP_resolution:handles.QWP_range(2)), handles.arr_2exclude))); 

% Update handles structure
guidata(hObject, handles);

% --------------------------------------------------------------------
function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% -------------------------------------------------------------------------
% ------------------- WHEN THE GUI IS CLOSED: -----------------------------

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Disconnects all activex controls if they are not already deactivated:
if ~handles.deco
    handles = disconnect_actx(handles);
end
% Closes the figure containing the activex controls:
if isvalid(handles.actx_figure)
    close(handles.actx_figure);
end
% Hint: delete(hObject) closes the figure
delete(hObject);


function move_rot_mp(str_mot, mot_obj, mot_value)
% 2018.8 Maxime Pinsard
% to move the rotation stage depending on their neture

% disp(ok)

    switch str_mot
        case 'micos' % DT80
            fprintf(mot_obj,'%f 1 nm ', mot_value);
            wait_move(mot_obj, str_mot);
        case 'newport' % ESP100
            fprintf(mot_obj, '1PA%d\r', mot_value); % move to
            wait_move(mot_obj, str_mot);
        case 'thorlabs' % Z rot
            mot_obj.MoveAbsoluteRot(0, mot_value,0,3,1); 
    end

function mot_value = get_pos_mp(str_mot, mot_obj)
% 2018.8 Maxime Pinsard
% to get the pos depending on their neture

    % disp(ok)

    switch str_mot
        case 'micos' % DT80
            mot_value = str2double(query(mot_obj,'1 npos '));
        case 'newport' % ESP100
            mot_value = str2double(query(mot_obj, '1TP')); % mm
        case 'thorlabs' % Z rot
            mot_value = mot_obj.GetPosition_Position(0); %m

    end
    
function home_mot_mp(str_mot, mot_obj)
% 2018.8 Maxime Pinsard

    switch str_mot
        case 'micos' % DT80
            fprintf(mot_obj,'1 ncal ');

        case 'newport' % ESP100
            fprintf(mot_obj, '1OR'); % no \r
            
        case 'thorlabs' % Z rot
            if mot_obj.GetPosition_Position(0)>0 %m
                mot_obj.MoveHome(0,1);
            end
    end
    
function wait_move(mot_obj, id)
    ct=0;
    while ct<17 
        switch id 
            case 'newport'
                a = query(mot_obj, '1MD?\r');
                if (~isempty(a) && str2double(a)) % 0 if it's moving
                    break % outside while 
                end
            case 'micos'
                a = query(mot_obj, '1 nst ');
                if (~isempty(a) && ~str2double(a)) % 1 if it is moving
                    break
                end
        end
        pause(0.3)
        ct = ct+1;
    end
    
function [connected, handles] = stctrl_instr_mp(handles, str_mot, mot_obj)
% % 2018.8 Maxime Pinsard

    if (~strcmp(str_mot, 'thorlabs') && ~strcmp(str_mot , 'nidaq'))
        try
            fopen(mot_obj);  %p
        catch ME
            if strcmp(ME.identifier, 'MATLAB:serial:fopen:opfailed') % not connected
                warning('Could not connect to the device %s', str_mot);
                connected = 0; %p
                return
            else
                rethrow(ME);
            end
        end
    end
    connected = 1;
    switch str_mot
        case 'micos' % DT80
            lastwarn(''); % Clear last warning message
            disp(query(mot_obj,'1 gnv ')) % velocity
            [warnMsg, ~] = lastwarn;
            if ~isempty(warnMsg)
                fprintf(2, ['\n ' str_mot ' not available !!\n']);
                connected = 0;
            end
        case 'newport' % ESP100
             lastwarn(''); % Clear last warning message
             disp(query(mot_obj,'1ID?\r'));
             [warnMsg, ~] = lastwarn;
            if ~isempty(warnMsg)
                fprintf(2, ['\n ' str_mot ' not available !!\n']);
                connected = 0;
            end
            fprintf(mot_obj, '1MO'); % puts the motor on
        case 'thorlabs' % Z rot
            mot_obj.StartCtrl;
        case 'tl_pm' % power meter
            lastwarn(''); % Clear last warning message
            disp(query(mot_obj,'*IDN?')) %p
            disp(query(mot_obj,':HEAD:INFO?')); % S/N, ID-Text, short description, Maximum Power)
            [warnMsg, ~] = lastwarn;
            if ~isempty(warnMsg)
                fprintf(2, ['\n ' str_mot ' not available !!\n']);
                connected = 0;
            end
        case 'nidaq'
            ss=get(handles.list_com, 'String');
            handles = daq_conn_mp(handles, ss{1});
    end

function handles = daq_conn_mp(handles, mot_obj)
% % d = daq.getDevices;
% % if isempty(d)
% %     fprintf(2, 'No NI devices.\n'); 
% % else
d={'Dev1', 'Dev2'}; % % find a way to look for devices !!
if (length(d) < str2double(mot_obj(end))) % % Dev#
    fprintf(2, 'Not enough devices\n');
    return;
elseif ~strcmp(mot_obj(1:end-1), 'Dev')% %#ok<COLND>
    fprintf(2, 'Wrong string for daq devices (should be Dev#)\n');
    return;
else % good !
    handles.devNIread = mot_obj;
end
lib = 'myni';	% library alias
if (libisloaded(lib) && ~isfield(handles, 'funclistNIdaq')) 
    unloadlibrary(lib);
end
if (~libisloaded(lib)) % %  || ~isfield(handles, 'funclistNIdaq')) 
    disp('Matlab: Load nicaiu.dll ...')
    setenv('MW_MINGW64_LOC','C:\mingw-w64\x86_64-5.3.0-posix-seh-rt_v4-rev0\mingw64'); % !!
    path_NI = 'C:\Program Files (x86)\National Instruments\NI-DAQ\DAQmx ANSI C Dev\include';
    warning('off','MATLAB:loadlibrary:TypeNotFound')
    try
        handles.funclistNIdaq = loadlibrary(fullfile('C:\Windows\System32', 'nicaiu.dll'),fullfile(path_NI, 'nidaqmx.h'),'alias',lib);
        disp('... Matlab: NI dll loaded');
% %             % %% load all DAQmx constants
    catch ME
        if strcmp(ME.identifier, 'MATLAB:loadlibrary:FileNotFound')
            error('No NIDAQ lib installed (at least not found) !');
        else; rethrow(ME); 
        end
    end
    warning('on','MATLAB:loadlibrary:TypeNotFound')
    %if you do NOT have nicaiu.dll and nidaqmx.h
    %in your Matlab path,add full pathnames or copy the files.
    %libfunctions(lib,'-full') % use this to show the... 
    %libfunctionsview(lib)     % included function
end
if libisloaded(lib)
    addpath(fullfile(handles.path_comp, 'DAQmx_examples'));
    handles.libdaq = lib;
    NIconstants; % % do I need that ?
    handles.DAQmx_Val_Rising = DAQmx_Val_Rising;
    handles.DAQmx_Val_Task_Verify = DAQmx_Val_Task_Verify;
    handles.DAQmx_Val_Auto = DAQmx_Val_Auto;
    handles.DAQmx_Val_GroupByScanNumber = DAQmx_Val_GroupByScanNumber;
    handles.DAQmx_Val_FiniteSamps = DAQmx_Val_FiniteSamps;
end
% % end
    
function mot_obj = open_com_mp(com_str, baud_rate, tag_str, timeout_read, term_char)
% 2018.8 Maxime Pinsard

    mot_obj = serial(com_str,...
        'BaudRate',baud_rate,...
        'DataBits',8, ...
        'Parity','none', ...
        'StopBits',1, ...
        'tag',tag_str,...
        'Timeout', timeout_read);  %the terminator is "line feed" automatically
    if term_char
        set(mot_obj,'Terminator','CR');
    end
    
function reinit_com_mp(port_str)
% 2018.8 Maxime Pinsard

        % if fail
    ports = instrfind('Port', port_str);
    
    if ~isempty(ports)
        disp(ports)
        fclose(ports);
    end

function close_com_mp(str_mot, mot_obj, dev_on)
% 2018.8 Maxime Pinsard

   switch str_mot
        case 'micos' % DT80
            fclose(mot_obj);
        case 'newport' % ESP100
            if dev_on 
                try fprintf(mot_obj, '1MF'); % off motor
                    pause(0.5);
                catch ME; fprintf(2, ME.message);
                end
            end
            fclose(mot_obj);
        case 'thorlabs' % Z rot
            try mot_obj.StopCtrl;
            catch ME; fprintf(2, ME.message);
            end
        case 'tl_pm' % power meter
           
    end

% --- Executes on button press in clean_sel_push.
function clean_sel_push_Callback(hObject, eventdata, handles)
% hObject    handle to clean_sel_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ind = get(handles.list_com, 'Value');
strcell = get(handles.list_com, 'String');

if strcmp(strcell{ind}(1:end-1), 'Dev')
    if (isfield(handles, 'libdaq') && isa(handles.EM, 'lib.pointer'))
        err = calllib(handles.libdaq,'DAQmxClearTask',handles.EM);
        DAQmxCheckError(handles.libdaq, err);
    end
elseif length(strcell{ind})> 3 % com smthg
    reinit_com_mp(strcell{ind})
end
handles.dev_on_list(ind) = 0;

% --- Executes on selection change in list_com.
function list_com_Callback(hObject, eventdata, handles)
% hObject    handle to list_com (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_com contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_com


% --- Executes during object creation, after setting all properties.
function list_com_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_com (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function QWP_str_edt_Callback(hObject, eventdata, handles)
% hObject    handle to QWP_str_edt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of QWP_str_edt as text
%        str2double(get(hObject,'String')) returns contents of QWP_str_edt as a double


% --- Executes during object creation, after setting all properties.
function QWP_str_edt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to QWP_str_edt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PM_str_edt_Callback(hObject, eventdata, handles)
% hObject    handle to PM_str_edt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PM_str_edt as text
%        str2double(get(hObject,'String')) returns contents of PM_str_edt as a double

strcom = get(handles.list_com,'String');
if strcmp(get(handles.PM_str_edt,'String'), 'nidaq')
    strcom{1} = 'Dev1';
    chg_sel_push_Callback(handles.chg_sel_push, eventdata, handles)
else
    strcom{1} = 'COM5';
end
set(handles.list_com,'String', strcom);


% --- Executes during object creation, after setting all properties.
function PM_str_edt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PM_str_edt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LP_str_edt_Callback(hObject, eventdata, handles)
% hObject    handle to LP_str_edt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LP_str_edt as text
%        str2double(get(hObject,'String')) returns contents of LP_str_edt as a double


% --- Executes during object creation, after setting all properties.
function LP_str_edt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LP_str_edt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function HWP_str_edt_Callback(hObject, eventdata, handles)
% hObject    handle to HWP_str_edt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of HWP_str_edt as text
%        str2double(get(hObject,'String')) returns contents of HWP_str_edt as a double


% --- Executes during object creation, after setting all properties.
function HWP_str_edt_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to HWP_str_edt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chg_sel_push.
function chg_sel_push_Callback(hObject, eventdata, handles) %#ok<*INUSL,*DEFNU>
% hObject    handle to chg_sel_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
num= 0;% dflt
ind = get(handles.list_com, 'Value');
strcell = get(handles.list_com, 'String');

if length(strcell{ind})> 3 % com smthg
    reinit_com_mp(strcell{ind});
    
    switch ind
        case 1
            handles.EM_str =  get(handles.PM_str_edt, 'String'); %'tl_pm';
            if (~strcmp(handles.EM_str , 'thorlabs') && ~strcmp(handles.EM_str , 'nidaq'))
                handles.baud_rate_EM = handles.baud_rate_list{strcmp(handles.name_dev_list, handles.EM_str)};
                handles.EM = open_com_mp(strcell{ind}, handles.baud_rate_EM, handles.tag_str_EM, handles.timeout_read_EM, 0);
                num= 1;
%             elseif strcmp(handles.EM_str , 'nidaq')
%                 handles.EM =  strcell{ind};
            end
        case 2
            handles.LP_str = get(handles.LP_str_edt, 'String');   % 'micos';
            if ~strcmp(handles.LP_str , 'thorlabs')
                handles.baud_rate_LP = handles.baud_rate_list{strcmp(handles.name_dev_list, handles.LP_str)};
                handles.LP = open_com_mp(strcell{ind}, handles.baud_rate_LP, handles.tag_str_LP, handles.timeout_read_LP, 1);
                num= 2;
            end

        case 3
            handles.QWP_str= get(handles.QWP_str_edt, 'String'); %'newport';
            if ~strcmp(handles.QWP_str , 'thorlabs')
                handles.baud_rate_QWP = handles.baud_rate_list{strcmp(handles.name_dev_list, handles.QWP_str)};
                handles.QWP = open_com_mp(strcell{ind}, handles.baud_rate_QWP, handles.tag_str_QWP, handles.timeout_read_QWP, 1);
                num= 3;
            end
        case 4
%             handles.HWP =  % activeX
            handles.HWP_str = get(handles.HWP_str_edt, 'String'); %'thorlabs';
            if ~strcmp(handles.HWP_str , 'thorlabs')
                handles.baud_rate_HWP = handles.baud_rate_list{strcmp(handles.name_dev_list, handles.HWP_str)};
                handles.HWP = open_com_mp(strcell{ind}, handles.baud_rate_HWP, handles.tag_str_HWP, handles.timeout_read_HWP, 1);
                num= 4;
            end

    end
    
    if num
        serialInfo = instrhwinfo('serial');     % Finds available COM ports
        avl= serialInfo.AvailableSerialPorts; 
        if sum(strcmp(avl,strcell{ind})) % available
            handles.avl_list(num)=1; % % [com_str_EM, com_str_LP, com_str_qwp, com_str_hwp]
        end
    end
end

% Update handles structure
guidata(hObject, handles);



function chg_com_edt_Callback(hObject, eventdata, handles)
% hObject    handle to chg_com_edt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of chg_com_edt as text
%        str2double(get(hObject,'String')) returns contents of chg_com_edt as a double

ind = get(handles.list_com, 'Value');
str_all = get(handles.list_com, 'String' );
str_all{ind} = get(hObject,'String');
set(handles.list_com, 'String', str_all);
set(hObject,'String', 'chg here');


% --- Executes during object creation, after setting all properties.
function chg_com_edt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chg_com_edt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function instr = open_actX(vect, sn)
try
    instr = actxcontrol('MGMOTOR.MGMotorCtrl.1', vect); %m
    instr.HWSerialNum = sn; %!
catch ME
    if strcmp(ME.identifier, 'MATLAB:COM:InvalidProgid')
        fprintf(2, 'NO TL MTR\n');
    else; rethrow(ME);
    end
    instr = [];
end

% --- Executes on button press in reopen_activeX_push.
function reopen_activeX_push_Callback(hObject, eventdata, handles)
% hObject    handle to reopen_activeX_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(findobj('type','figure','name','Activex'))
    handles.actx_figure = figure(1); set(handles.actx_figure, 'Name', 'ActiveX');
    ct = 0;
    for k =1:length(handles.sn_list)
        ct = ct+1;
        if handles.sn_list{k} ~= 0
            switch ct
                case 1
                    handles.LP = open_actX([0+(k-1)*100, 0+max(0,(k-2)*100), 400, 400], handles.sn_list{k});
                    handles.LP.StartCtrl;
                    handles.avl_list(2) = 1;
                case 2
                    handles.QWP = open_actX([0+(k-1)*100, 0+max(0,(k-2)*100), 400, 400], handles.sn_list{k});
                    handles.QWP.StartCtrl;
                    handles.avl_list(3) = 1;
                case 3
                    handles.HWP = open_actX([0+(k-1)*100, 0+max(0,(k-2)*100), 400, 400], handles.sn_list{k});
                    handles.HWP.HWSerialNum = handles.sn_list{k};
                    handles.HWP.StartCtrl;
                    handles.avl_list(4) = 1;
            end
        end
    end
end

guidata(hObject, handles);


% --- Executes on button press in merge_results_push.
function merge_results_push_Callback(hObject, eventdata, handles)
% hObject    handle to merge_results_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

kk=0;
while 1 % infinite
    kk = kk+1;
    [file, path] = uigetfile('*.mat', sprintf('Select the MATLAB file containing the results #%d (cancel to quit)', kk));
    % Checks if the action is canceled:
    if file == 0; break; end
    % Loads the variables to the workspace:
    load([path file]); %#ok<LOAD>
    answer = menu('dir to add to actual', 'right (after)', 'bottom(after)', 'left(before)', 'top(before)');
    if answer <= 1; axis = 1;
    elseif answer == 2; axis = 2;
    elseif answer == 3; axis = -1;
    elseif answer == 4; axis = -2;
    end
    handles = combine_results(handles, measured_parameters, fitted_parameters, axis);
    [handles] = image_result(handles);
end

guidata(hObject, handles);


% --- Executes on button press in flip_QWP_chck.
function flip_QWP_chck_Callback(hObject, eventdata, handles)
% hObject    handle to flip_QWP_chck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of flip_QWP_chck

D_CP = handles.table_CP.Data; 
D_LP = handles.table_LP.Data;
% flip = get(hObject,'Value');
% % if flip  
% % end
[handles.table_CP.Data(1, :), handles.table_LP.Data(:, 1)] = flip_wp_mp(D_CP(1, :), D_LP(:, 1), get(handles.axes_result, 'xlim'));

popup_result_Callback(handles.popup_result, eventdata, handles);
disp('I flipped QWP');

function [v_CP, v_LP] = flip_wp_mp(v_CP, v_LP, lim)

v_CP = lim(2) - v_CP + lim(1);
v_LP = lim(2) - v_LP + lim(1);

% --- Executes on button press in flip_HWP_chck.
function flip_HWP_chck_Callback(hObject, eventdata, handles)
% hObject    handle to flip_HWP_chck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of flip_HWP_chck

[handles.table_CP.Data(2, :), handles.table_LP.Data(:, 2)] = flip_wp_mp(handles.table_CP.Data(2, :), handles.table_LP.Data(:, 2), ...
get(handles.axes_result, 'ylim'));
popup_result_Callback(handles.popup_result, eventdata, handles);
disp('I flipped HWP');


% --- Executes on button press in calc_res_if_open_chck.
function calc_res_if_open_chck_Callback(hObject, eventdata, handles)
% hObject    handle to calc_res_if_open_chck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of calc_res_if_open_chck


% --- Executes on button press in disc_EM_push.
function disc_EM_push_Callback(hObject, eventdata, handles)
% hObject    handle to disc_EM_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% disp(get(handles.disc_EM_push, 'String'))
if strcmp(get(handles.disc_EM_push, 'String'), 'disc EM')
    handles = disco_EM_mp(handles);
    set(handles.disc_EM_push, 'String', 'conn. EM');
    set(handles.push_single, 'Enable', 'off');
    set(handles.push_start,  'Enable', 'off');
else % conn
    handles = connect_actx(handles, {handles.EM_str}, {'EM'}, 0, handles.EM, 1);
    handles = connect_actx(handles, {handles.EM_str}, {'EM'}, 0, handles.EM, 2);
    set(handles.disc_EM_push, 'String', 'disc EM');
    if sum(handles.dev_on_list) >= 4
        set(handles.push_single, 'Enable', 'on');
        set(handles.push_start,  'Enable', 'on');
    end
end
guidata(hObject, handles);
