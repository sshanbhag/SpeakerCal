%--------------------------------------------------------------------------
% SpeakerCal_caldata_init.m
%--------------------------------------------------------------------------
%	Script for SpeakerCal program to initialize/allocate caldata
%	structure for speaker calibration
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Sharad Shanbhag
% sshanbhag@neomed.edu
%--------------------------------------------------------------------------
% Created: 1 March, 2012, branched from HeadphoneCal
%
% Revisions:
%--------------------------------------------------------------------------

%---------------------------------------------------------------
%---------------------------------------------------------------
% Setup data storage variables and paths
%---------------------------------------------------------------
%---------------------------------------------------------------
caldata.time_str = datestr(now, 31);			% date and time
caldata.timestamp = now;							% timestamp
caldata.adFc = iodev.Fs;							% analog input rate
caldata.daFc = iodev.Fs;							% analog output rate
caldata.nrasters = Nfreqs;							% number of freqs to collect
caldata.range = F;									% freq range (matlab string)
caldata.reps = cal.Nreps;							% reps per frequency
caldata.settings = cal;
caldata.atten = cal.StartAtten;					% initial attenuator setting
caldata.max_spl = cal.Maxlevel;					% maximum spl
caldata.min_spl = cal.Minlevel;					% minimum spl
caldata.frfile = '';

% set up the arrays to hold the data
Nchannels = 2;

%initialize the caldata structure arrays for the calibration data
tmpcell = cell(Nchannels, Nfreqs);
tmparr = zeros(Nchannels, Nfreqs);
caldata.freq = Freqs;
caldata.mag = tmparr;
caldata.phase = tmparr;
caldata.dist = tmparr;
caldata.mag_stderr = tmparr;
caldata.phase_stderr = tmparr;

%---------------------------------------------------------------
%---------------------------------------------------------------
% Fetch the l and r headphone mic adjustment values for the 
% calibration frequencies using interpolation
%---------------------------------------------------------------
%---------------------------------------------------------------
if ~exist('frdata', 'var')
	frdata.lmagadjval = ones(size(caldata.freq));
	frdata.rmagadjval = ones(size(caldata.freq));
	frdata.lphiadjval = zeros(size(caldata.freq));
	frdata.rphiadjval = zeros(size(caldata.freq));
	frdata.DAscale = DAscale;
else
	frdata.lmagadjval = interp1(frdata.freq, frdata.ladjmag, caldata.freq);
	frdata.rmagadjval = interp1(frdata.freq, frdata.radjmag, caldata.freq);
	frdata.lphiadjval = interp1(frdata.freq, frdata.ladjphi, caldata.freq);
	frdata.rphiadjval = interp1(frdata.freq, frdata.radjphi, caldata.freq);	
end
caldata.DAscale = frdata.DAscale;
caldata.frdata = frdata;

if DEBUG
	magsdbug = mags;
	phisdbug = phis;
end
	