function varargout = SpeakerCal(varargin)
% SPEAKERCAL M-file for SpeakerCal.fig
%      SPEAKERCAL, by itself, creates a new SPEAKERCAL or raises the existing
%      singleton*.
%
%      H = SPEAKERCAL returns the handle to a new SPEAKERCAL or the handle to
%      the existing singleton*.
%
%      SPEAKERCAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPEAKERCAL.M with the given input arguments.
%
%      SPEAKERCAL('Property','Value',...) creates a new SPEAKERCAL or raises the
%      existing singleton*.  
%

%-------------------------------------------------------------------------
% Calibration Algorithm:
% 
% First, the sound level from the microphone is checked.  If the level 
% (measured in dB SPL) is too low, the value of the attenuator is
% decreased.  If it is too high, attenuation is increased.
% 
% Then, the calibration tone at given frequency is played from the
% speakers.  The tone is scaled to the maximum output level of the D/A 
% converter.
% 
% A phased lock loop (fitsinvec() function) is used to determine the 
% magnitude and phase of the response measured by the microphone.
% 
% The magnitude is then divided by the scaling factor
% from the microphone calibration.  This adjusts for the discrepancy
% between the earphone microphone (Knowles) and the reference
% (Bruel & Kjaer) microphone which is the reference, flat response.
% Phase is adjusted by subtracting the reference phase from the measured
% phase.
% 
% The magnitude is then converted to the RMS value 
% 
%-------------------------------------------------------------------------

% Last Modified by GUIDE v2.5 02-Nov-2010 18:21:33

% Begin initialization code - DO NOT EDIT
	gui_Singleton = 1;
	gui_State = struct('gui_Name',       mfilename, ...
					   'gui_Singleton',  gui_Singleton, ...
					   'gui_OpeningFcn', @SpeakerCal_OpeningFcn, ...
					   'gui_OutputFcn',  @SpeakerCal_OutputFcn, ...
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
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes just before SpeakerCal is made visible.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SpeakerCal_OpeningFcn(hObject, eventdata, handles, varargin)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Setup Paths
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	disp([mfilename ': checking paths'])
	pdir = ['C:\TytoLogy\TytoSettings\' getenv('USERNAME')];
	if isempty(which('RPload'))
		cdir = pwd;
		disp([mfilename ': loading paths using ' pdir]);
		if ~exist(pdir, 'dir')
			error('%s: Cannot locate paths!', mfilename);
		end
		cd(pdir);
		tytopaths
		cd(cdir);
	else
		disp([mfilename ': paths ok, launching programn'])
	end
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Initial Calibration settings
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%------------------------------------------------------------
		% first check to see if defaults file exists
		%------------------------------------------------------------
		defaultsfile = fullfile(pdir, [mfilename '_Defaults.mat']);
		
		if exist(defaultsfile, 'file')
			fprintf('Loading cal settings from defaults file %s ...\n', defaultsfile)
			load(defaultsfile, 'cal');
		else
			% no defaults found, so use internal values
			% Frequency range
			cal.Fmin = 3000;
			cal.Fstep = 100;
			cal.Fmax = 3500;
			% set the min and max allowable stimulus levels
			cal.Minlevel = 60;
			cal.Maxlevel = 70;
			% Set the starting attenuation value
			% (better to set too high instead of too low!!!!)
			cal.StartAtten = 90;
			% set the stepsize for adjusting attenuation
			cal.AttenStep = 2;
			% # reps per frequency
			cal.Nreps = 3;
			% Inter-stim interval in seconds
			cal.ISI = 200;
			% Auto save ear_cal.mat in experiment calibration data dir
			cal.AutoSave = 1;
			% set the 'side' to both channels;
			cal.Side = 3;
			% set the CheckCal flag in order to use a reference microphone to 
			% check the calibration.  
			% 0 == no check, 1 = Left, 2 = Right, 3 = Both
			cal.CheckCal = 0;
			% these are used to use a fixed attenuation level
			% will essentially generate a frequency response curve
			% for the speaker (with the microphone correction factor
			% from *_fr.mat file from CalibrateHeadphoneMic applied)
			cal.AttenFix = 0;
			cal.AttenFixValue = 90;
			% default fr response file for Knowles mics
			cal.mic_fr_file = '..\CalibrationData\FFamp_CIThp_24-Sep-2009_fr.mat';
	
		end
	
		% assign cal struct to the GUI handles structure for safe keeping
		handles.defaultsfile = defaultsfile;		
		handles.cal = cal;
		guidata(hObject, handles);
		
		% update user interface
		update_ui_str(handles.Fmin, handles.cal.Fmin);
		update_ui_str(handles.Fmax, handles.cal.Fmax);
		update_ui_str(handles.Fstep, handles.cal.Fstep);
		update_ui_str(handles.Minlevel, handles.cal.Minlevel);
		update_ui_str(handles.Maxlevel, handles.cal.Maxlevel);
		update_ui_str(handles.AttenStep, handles.cal.AttenStep);
		update_ui_str(handles.Nreps, handles.cal.Nreps);
		update_ui_str(handles.ISI, handles.cal.ISI);
		update_ui_val(handles.Side, handles.cal.Side);
		update_ui_val(handles.AutoSave, handles.cal.AutoSave);
		update_ui_val(handles.CheckCalCtrl, handles.cal.CheckCal + 1);
		update_ui_val(handles.AttenFixCtrl, handles.cal.AttenFix);
		update_ui_str(handles.AttenFixValueCtrl, handles.cal.AttenFixValue);
		set(handles.AttenFixCtrl, 'HitTest', 'on');
		set(handles.AttenFixCtrl, 'Enable', 'on');
		set(handles.AttenFixCtrl, 'Visible', 'on');
		if handles.cal.AttenFix
			set(handles.AttenFixValueCtrl, 'HitTest', 'on');
			set(handles.AttenFixValueCtrl, 'Enable', 'on');
			set(handles.AttenFixValueCtrl, 'Visible', 'on');
			set(handles.AttenFixValueCtrlText, 'HitTest', 'off');
			set(handles.AttenFixValueCtrlText, 'Enable', 'on');
			set(handles.AttenFixValueCtrlText, 'Visible', 'on');
		else
			set(handles.AttenFixValueCtrl, 'HitTest', 'off');
			set(handles.AttenFixValueCtrl, 'Enable', 'on');
			set(handles.AttenFixValueCtrl, 'Visible', 'off');
			set(handles.AttenFixValueCtrlText, 'HitTest', 'off');
			set(handles.AttenFixValueCtrlText, 'Enable', 'off');
			set(handles.AttenFixValueCtrlText, 'Visible', 'off');
		end
		update_ui_str(handles.MicFRFileCtrl, handles.cal.mic_fr_file);
		
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% set this to wherever the circuits are stored
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		iodev.Circuit_Path = 'H:\Code\TytoLogy\toolbox\TDT\Circuits\RX8_2\50KHz';
		iodev.Circuit_Name = 'RZ6_1Out1FilteredIn';
		iodev.REF = 0;
		iodev.status = 0;
		% Dnum = device number - this is for RZ6 (1)
		iodev.Dnum=1;
		handles.iodev = iodev;
		guidata(hObject, handles);		
		
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Update handles structure
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		handles.CalComplete = 0;
		handles.output = hObject;
		guidata(hObject, handles);		
		
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% UIWAIT makes SpeakerCal wait for user response (see UIRESUME)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% uiwait(handles.figure1);
%--------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Calibration callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------
function RunCalibration_ctrl_Callback(hObject, eventdata, handles)
	set(handles.RunCalibration_ctrl, 'Enable', 'off');
	set(handles.Abort_ctrl, 'Enable', 'on');
	set(handles.Abort_ctrl, 'Visible', 'on');
	set(handles.Abort_ctrl, 'HitTest', 'on');
	set(handles.Abort_ctrl, 'Value', 0);
	handles.CalComplete = 0;
	COMPLETE = 0;
	guidata(hObject, handles);
	
 	SpeakerCal_RunCalibration

	set(handles.RunCalibration_ctrl, 'Enable', 'on');
	set(handles.Abort_ctrl, 'Enable', 'off');
	set(handles.Abort_ctrl, 'Visible', 'off');
	set(handles.Abort_ctrl, 'HitTest', 'off');
	set(handles.Abort_ctrl, 'Value', 0);
	
	if COMPLETE
		handles.CalComplete = 1;
		save(handles.defaultsfile, 'cal');
	end
	guidata(hObject, handles);
%--------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save Calibration Button
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------
% Save the data 
function SaveCalibration_Callback(hObject, eventdata, handles)
	if handles.CalComplete
		[calfile, calpath] = uiputfile('*_cal.mat','Save headphone calibration data in file');
		if calfile ~= 0
			% save the sequence so we can match up with the RF data
			datafile = fullfile(calpath, calfile);
			caldata = handles.caldata;
			save(datafile, '-MAT', 'caldata');
		end
	end
%--------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUI control callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-------------------------------------------------------------------------
function FreqVal_Callback(hObject, eventdata, handles)
function LVal_Callback(hObject, eventdata, handles)
function LSPL_Callback(hObject, eventdata, handles)
function RVal_Callback(hObject, eventdata, handles)
function RSPL_Callback(hObject, eventdata, handles)
function LAttentext_Callback(hObject, eventdata, handles)
function RAttentext_Callback(hObject, eventdata, handles)
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function Fmin_Callback(hObject, eventdata, handles)
	tmp = read_ui_str(hObject, 'n');
	if ~between(tmp, 0, handles.cal.Fmax)
		warndlg('Min Freq must be between 0 & Fmax', 'Invalid Min Freq');
		update_ui_str(hObject, handles.cal.Fmin);
	else
		handles.cal.Fmin = tmp;
		guidata(hObject, handles);
	end
%-------------------------------------------------------------------------
	
%-------------------------------------------------------------------------
function Fmax_Callback(hObject, eventdata, handles)
	tmp = read_ui_str(hObject, 'n');
	if ~between(tmp, handles.cal.Fmin, 22000)
		warndlg('Max Freq must be between Fmin & 22,000', 'Invalid Max Freq');
		update_ui_str(hObject, handles.cal.Fmax);
	else
		handles.cal.Fmax = tmp;
		guidata(hObject, handles);
	end
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function Fstep_Callback(hObject, eventdata, handles)
	tmp = read_ui_str(hObject, 'n');
	maxstep = handles.cal.Fmax - handles.cal.Fmin;
	if ~between(tmp, 1, maxstep)
		warndlg('FreqStep must be between 1 & Fmax-Fmin', 'Invalid FreqStep');
		update_ui_str(hObject, handles.cal.Fstep);
	else
		handles.cal.Fstep = tmp;
		guidata(hObject, handles);
	end
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function Minlevel_Callback(hObject, eventdata, handles)
	tmp = read_ui_str(hObject, 'n');
	if ~between(tmp, 1, handles.cal.Maxlevel)
		warndlg('Min Level must be between 0 & Max Level', 'Invalid Min Level');
		update_ui_str(hObject, handles.cal.Minlevel);
	else
		handles.cal.Minlevel = tmp;
		guidata(hObject, handles);
	end
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function Maxlevel_Callback(hObject, eventdata, handles)
	tmp = read_ui_str(hObject, 'n');
	if ~between(tmp, handles.cal.Minlevel, 120)
		warndlg('Max Level must be between Min Level & 120 dB', 'Invalid Max Level');
		update_ui_str(hObject, handles.cal.Maxlevel);
	else
		handles.cal.Maxlevel = tmp;
		guidata(hObject, handles);
	end
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function AttenStep_Callback(hObject, eventdata, handles)
	tmp = read_ui_str(hObject, 'n');
	maxstep = handles.cal.Maxlevel - handles.cal.Minlevel;
	if ~between(tmp, 1, maxstep)
		warndlg('Atten Step must be between 1 & Max Level - Min Level', 'Invalid AttenStep');
		update_ui_str(hObject, handles.cal.AttenStep);
	else
		handles.cal.AttenStep = tmp;
		guidata(hObject, handles);
	end
%-------------------------------------------------------------------------
	
%-------------------------------------------------------------------------
function Nreps_Callback(hObject, eventdata, handles)
	tmp = read_ui_str(hObject, 'n');
	if ~between(tmp, 1, 30)
		warndlg('# reps must be between 1 & 30', 'Invalid # Reps');
		update_ui_str(hObject, handles.cal.Nreps);
	else
		handles.cal.Nreps = tmp;
		guidata(hObject, handles);
	end
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function ISI_Callback(hObject, eventdata, handles)
	tmp = read_ui_str(hObject, 'n');
	if ~between(tmp, 0, 1000)
		warndlg('Interval between stimuli must be between 0 & 1000', 'Invalid Interval');
		update_ui_str(hObject, handles.cal.ISI);
	else
		handles.cal.ISI = tmp;
		guidata(hObject, handles);
	end
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
function AutoSave_Callback(hObject, eventdata, handles)
	handles.cal.AutoSave = read_ui_val(hObject);
	guidata(hObject, handles);
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function Abort_ctrl_Callback(hObject, eventdata, handles)
	disp('ABORTING Calibration!')
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function CheckCalCtrl_Callback(hObject, eventdata, handles)
	handles.cal.CheckCal = read_ui_val(hObject)-1;
	guidata(hObject, handles);
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function AttenFixValueCtrl_Callback(hObject, eventdata, handles)
	tmp = read_ui_str(handles.AttenFixValueCtrl, 'n');
	if ~between(tmp, 0, 120)
		warndlg('fixed attenuation must be between 0 and 120', 'Invalid Fixed Attenuation');
		update_ui_str(hObject, handles.cal.AttenFixValue);
	else
		handles.cal.AttenFixValue = tmp;
		guidata(hObject, handles);
	end	
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function AttenFixCtrl_Callback(hObject, eventdata, handles)
	handles.cal.AttenFix = read_ui_val(hObject);
	% update user interface
	if handles.cal.AttenFix
		% update settings for fixed attenuation routine
		set(handles.AttenFixValueCtrl, 'HitTest', 'on');
		set(handles.AttenFixValueCtrl, 'Enable', 'on');
		set(handles.AttenFixValueCtrl, 'Visible', 'on');
		set(handles.AttenFixValueCtrlText, 'HitTest', 'off');
		set(handles.AttenFixValueCtrlText, 'Enable', 'on');
		set(handles.AttenFixValueCtrlText, 'Visible', 'on');
		handles.cal.AttenFixValue = read_ui_str(handles.AttenFixValueCtrl, 'n');
	else
		% update settings for normal routine
		set(handles.AttenFixValueCtrl, 'HitTest', 'off');
		set(handles.AttenFixValueCtrl, 'Enable', 'on');
		set(handles.AttenFixValueCtrl, 'Visible', 'off');
		set(handles.AttenFixValueCtrlText, 'HitTest', 'off');
		set(handles.AttenFixValueCtrlText, 'Enable', 'off');
		set(handles.AttenFixValueCtrlText, 'Visible', 'off');
	end
	guidata(hObject, handles);
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function MicFRFileCtrl_Callback(hObject, eventdata, handles)
	% get the fr file data
	tmpfile = read_ui_str(handles.MicFRFileCtrl);
	
	if ~exist(tmpfile, 'file')
		warndlg('Microphone calibration file not found!', 'SpeakerCal Warning');
		% revert to old value
		update_ui_str(handles.MicFRFileCtrl, handles.cal.mic_fr_file);
	else
		handles.cal.mic_fr_file = tmpfile;
		load(handles.cal.mic_fr_file, 'frdata');
		handles.cal.mic_fr = frdata;
		guidata(hObject, handles);
		update_ui_str(handles.MicFRFileCtrl, handles.cal.mic_fr_file);		
	end
%--------------------------------------------------------------------------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Menu Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------
function Menu_SaveCal_Callback(hObject, eventdata, handles)
	[calfile, calpath] = uiputfile('*_cal.mat','Save headphone calibration data in file');
	if calfile ~= 0
		% save the sequence so we can match up with the RF data
		datafile = fullfile(calpath, calfile);
		caldata = handles.caldata;
		save(datafile, '-MAT', 'caldata');
	end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function Menu_LoadFRData_Callback(hObject, eventdata, handles)
	% get the fr file data
	[frfile, frpath] = uigetfile('*_fr.mat', 'Load FR data for earphones...');
	if frfile ~= 0
		handles.cal.mic_fr_file = fullfile(frpath, frfile);
		load(handles.cal.mic_fr_file, 'frdata');
		handles.cal.mic_fr = frdata;
		guidata(hObject, handles);
		update_ui_str(handles.MicFRFileCtrl, handles.cal.mic_fr_file);
	end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function Menu_Close_Callback(hObject, eventdata, handles)
 	CloseRequestFcn(handles.figure1, eventdata, handles);
%--------------------------------------------------------------------------


%-------------------------------------------------------------------------
function TDTSettingsMenuCtrl_Callback(hObject, eventdata, handles)
	iodev = handles.iodev;
	fullcircuit = fullfile(iodev.Circuit_Path, [iodev.Circuit_Name '.rcx'])
	if ~exist(fullcircuit, 'file')
		warning('%s: circuit %s not found...', mfilename, fullcircuit)
		[fname, pname] = uigetfile('*.rcx', 'Select TDT RPvD circuit file');
		if fname == 0
			% user cancelled request
			return
		end
		% need to strip off .rcx from filename
		[tmp1, fname, fext, tmp2] = fileparts(fname)
		iodev.Circuit_Name = fname;
		iodev.Circuit_Path = pname;
		handles.iodev = iodev;
		guidata(hObject, handles);
		iodev
		
	else
		[fname, pname] = uigetfile('*.rcx', ...
								'Select TDT RPvD circuit file', ...
								fullcircuit);
		if fname == 0
			% user cancelled request
			return
		end
		% need to strip off .rcx from filename
		[tmp1, fname, fext, tmp2] = fileparts(fname);
		iodev.Circuit_Name = fname;
		iodev.Circuit_Path = pname;
		handles.iodev = iodev;
		guidata(hObject, handles);
		iodev
	end
%-------------------------------------------------------------------------



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUI I/O, misc Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = SpeakerCal_OutputFcn(hObject, eventdata, handles) 
	% Get default command line output from handles structure
	varargout{1} = handles.output;
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function CloseRequestFcn(hObject, eventdata, handles)
	pause(0.1);
	delete(hObject);
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% --- Executes on selection change in Side.
function Side_Callback(hObject, eventdata, handles)
%--------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------
function FreqVal_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function LVal_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function LSPL_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function RVal_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function RSPL_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function Fmin_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function Fmax_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function Fstep_CreateFcn(hObject, eventdata, handles)
function Minlevel_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function Maxlevel_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function AttenStep_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function Nreps_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function ISI_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function LAttentext_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function RAttentext_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
function Side_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		 set(hObject,'BackgroundColor','white');
	end
function CheckCalCtrl_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		 set(hObject,'BackgroundColor','white');
	end
function AttenFixValueCtrl_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		 set(hObject,'BackgroundColor','white');
	end
function MicFRFileCtrl_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
	    set(hObject,'BackgroundColor','white');
	end
%-------------------------------------------------------------------------
















