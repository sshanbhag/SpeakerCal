%--------------------------------------------------------------------------
% SpeakerCal_tdtexit.m
%--------------------------------------------------------------------------
%
% closes TDT devices nicely
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Sharad Shanbhag
% sharad.shanbhag@einstein.yu.edu
%--------------------------------------------------------------------------
% Created: 1 March, 2012
% 				Created from HeadphoneCal_tdtexit.m
% 
% Revisions:
%--------------------------------------------------------------------------



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean up the RP circuits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('...closing TDT devices...');
status = PA5close(PA5L);
status = PA5close(PA5R);
status = RPclose(iodev);

	
