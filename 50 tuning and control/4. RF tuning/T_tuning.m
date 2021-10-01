%% Jun 2019, Jacob Rogatinsky
% Sept. 2021, Revised by Blake Mitchell

% Initialize the escape key
hotkey('esc', 'escape_screen(); assignin(''caller'',''continue_'',false);');

global SAVEPATH GRATINGRECORD prespertr datafile

datafile = MLConfig.FormattedName;
USER = getenv('username');

if strcmp(USER,'maierlab')
    SAVEPATH = 'C:\MLData\temp';
else
    SAVEPATH = fileparts(which('T_tuning.m'));
end


%% Initial code
% Paradigm selection  
% 'cinteroc'        Grating contrast varies trial to trial, eye to eye
% 'rfori'           Grating orientation varies trial to trial
% 'rfsize'          Grating size varies trial to trial
% 'rfsf'            Grating spatial frequency varies trial to trial
% 'posdisparity'    Grating x-position (DE) varies from trial to trial
% 'phzdisparity'    Grating phase angle (DE) varies from trial to trial
% 'cone'            Grating colors vary trial to trial, eye to eye

paradigm = 'rfori';

timestamp = datestr(now); % Get the current time on the computer

% Set fixation point
fixpt = [0 0]; % [x y] in viual degrees
fixThreshold = 3; % degrees of visual angle

% define intervals for WaitThenHold
wait_for_fix = 3000;
initial_fix = 200; % hold fixation for 200ms to initiate trial

% Find screen size
scrsize = Screen.SubjectScreenFullSize / Screen.PixelsPerDegree;  % Screen size [x y] in degrees
setCoord(scrsize); % Send value to a global variable
lower_right = [(scrsize(1)*0.5-0.5) (scrsize(2)*(-0.5)+0.5)];

% Trial number increases by 1 for every iteration of the code
tr = tnum(TrialRecord);



if tr == 1 % on the first trial
    
    % generate grating record
    genGratingRecordML2(paradigm,TrialRecord);
    
    % generate fixation cross location
    genFixCross((fixpt(1)*Screen.PixelsPerDegree), (fixpt(2)*Screen.PixelsPerDegree));
    
    % Create a file to write grating information for each trial
    taskdir = SAVEPATH; %fileparts(which('T_RFtuning.m'));
    filename = strcat(taskdir,'/',datafile,'.g',upper(paradigm),'Grating_di');
    
    fid = fopen(filename, 'w');
    formatSpec =  '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\r\n';
    fprintf(fid,formatSpec,...
        'trial',...
        'horzdva',...
        'vertdva',...
        'grating_xpos',...
        'grating_ypos',...
        'other_xpos',...
        'other_ypos',...
        'grating_tilt',...
        'grating_sf',...
        'grating_contrast',...
        'grating_fixedc',...
        'grating_diameter',...
        'grating_eye',...
        'grating_varyeye',...
        'grating_oridist',...
        'gaborfilter_on',...
        'gabor_std',...
        'header',...
        'grating_phase',...
        'path',...
        'timestamp');
    
    fclose(fid);
    
elseif size(GRATINGRECORD,2) < tr
    %GENERATE NEW GRATING RECORD IF THIS TRIAL IS LONGER THAN CURRENT GRATINGRECORD
    genGratingRecordML2(paradigm,TrialRecord);
end
    
    


%% Assign values to each sine grating condition
% Set the conditions

path = nan;
grating_tilt = GRATINGRECORD(tr).grating_tilt;
grating_eye = GRATINGRECORD(tr).grating_eye;
grating_phase = GRATINGRECORD(tr).grating_phase;
grating_sf = GRATINGRECORD(tr).grating_sf;
grating_tf = GRATINGRECORD(tr).grating_tf;
grating_contrast = GRATINGRECORD(tr).grating_contrast;
grating_diameter = GRATINGRECORD(tr).grating_diameter;
grating_xpos = GRATINGRECORD(tr).grating_xpos(1,:);
grating_ypos = GRATINGRECORD(tr).grating_ypos(1,:);
other_xpos  = GRATINGRECORD(tr).grating_xpos(2,:);
other_ypos  = GRATINGRECORD(tr).grating_ypos(2,:);
stereo_xpos = GRATINGRECORD(tr).stereo_xpos(1,:);
other_stereo_xpos = GRATINGRECORD(tr).stereo_xpos(2,:);
grating_header = GRATINGRECORD(tr).header;
grating_varyeye = GRATINGRECORD(tr).grating_varyeye;
grating_fixedc = GRATINGRECORD(tr).grating_fixedc;
grating_oridist = GRATINGRECORD(tr).grating_oridist;
grating_outerdiameter = GRATINGRECORD(tr).grating_outerdiameter;
grating_space = GRATINGRECORD(tr).grating_space;
grating_isi = GRATINGRECORD(tr).grating_isi;
grating_stimdur = GRATINGRECORD(tr).grating_stimdur;

X = (Screen.Xsize / Screen.PixelsPerDegree) / 4;
Y = grating_ypos;
% xloc_left = (-0.25*scrsize(1)+grating_xpos(2,1));   % Left eye x-coordinate
% xloc_right = (0.25*scrsize(1)+grating_xpos(1,1));   % Right eye x-coordinate

gray = [0.5 0.5 0.5];
color1 = gray + (grating_contrast(1) / 2);
color2 = gray - (grating_contrast(1) / 2);

%% Scene 0. Blank screen

bck0 = ImageGraphic(null_);
bck0.List = { {'graybackground.png'}, [0 0], [0 0 0], Screen.SubjectScreenFullSize };

% Set the timer
cnt0 = TimeCounter(bck0);
cnt0.Duration = 50;
scene0 = create_scene(cnt0);

%% Scene 1. Fixation

% Set fixation to the left eye for tracking
fix1 = SingleTarget(eye_); % Initialize the eye tracking adapter
fix1.Target = [(-0.25*scrsize(1))+fixpt(1) fixpt(2)]; % Set the fixation point
fix1.Threshold = fixThreshold; % Set the fixation threshold

bck1 = ImageGraphic(fix1);
bck1.List = { {'graybackgroundcross.png'}, [0 0], [0 0 0], Screen.SubjectScreenFullSize };

wth1 = WaitThenHold(bck1); % Initialize the wait and hold adapter
wth1.WaitTime = wait_for_fix; % Set the wait time
wth1.HoldTime = initial_fix; % Set the hold time

scene1 = create_scene(wth1); % Initialize the scene adapter
run_scene(scene1,[35,11]); % Run scene

error_type = 0;
if ~wth1.Success             % If the WithThenHold failed (either fixation is not acquired or broken during hold),
    if wth1.Waiting          %    check whether we were waiting for fixation.
        error_type = 1; 
        run_scene(scene0,[97,36]); 
    else
        error_type = 2;      % If we were not waiting, it means that fixation was acquired but not held,
        run_scene(scene0,[97,36]);
    end                      %    so this is a "break fixation (3)" error.
else
    eventmarker(8);         % 8 = fixation occurs
end


%% Scene 2. Gratings
% list of objects


if wth1.Success % If fixation was acquired and held
    obj = [23,24,25,26,27,28,29,30,31];
    presNum = 0;
    for ii = 1:(prespertr*2) - 1
        
        real_ind = (ii+1)/2;
        
        if rem(ii,2) == 1 % this function is basically saying every odd number of ii
            presNum = presNum + 1;
            fix2 = SingleTarget(eye_); % Initialize the eye tracking adapter
            fix2.Target = [(-0.25*scrsize(1))+fixpt(1) fixpt(2)]; % Set the fixation point
            fix2.Threshold = fixThreshold; % Set the fixation threshold
            
            pd = BoxGraphic(fix2);
            pd.EdgeColor = [1 1 1];
            pd.FaceColor = [1 1 1];
            pd.Size = [3 3];
            pd.Position = lower_right;
            
            % Create the right eye grating
            left_grat = SineGrating(pd);
            left_grat.Position = [stereo_xpos(presNum) grating_ypos(presNum)]; % 1st element is right eye
            left_grat.Radius = grating_diameter(presNum)/2;
            left_grat.Direction = grating_tilt(presNum);
            left_grat.SpatialFrequency = grating_sf(presNum);
            left_grat.TemporalFrequency = grating_tf(presNum);
            left_grat.Color1 = color1;
            left_grat.Color2 = color2;
            left_grat.Phase = grating_phase(presNum);
            left_grat.WindowType = 'circular';
            
            % Create the left eye grating
            right_grat = SineGrating(left_grat);
            right_grat.Position = [other_stereo_xpos(presNum) other_ypos(presNum)]; % 1st element is right eye
            right_grat.Radius = grating_diameter(presNum)/2;
            right_grat.Direction = grating_tilt(presNum);
            right_grat.SpatialFrequency = grating_sf(presNum);
            right_grat.TemporalFrequency = grating_tf(presNum);
            right_grat.Color1 = color1;
            right_grat.Color2 = color2;
            right_grat.Phase = grating_phase(presNum);
            right_grat.WindowType = 'circular';
            
            bck2 = ImageGraphic(right_grat);
            bck2.List = { {'graybackgroundcross.png'}, [0 0], [0 0 0], Screen.SubjectScreenFullSize };
            
            % Set the timer
            cnt2 = TimeCounter(bck2);
            cnt2.Duration = 25; %grating_stimdur;
            
            % Run the scene
            scene2 = create_scene(cnt2);
            run_scene(scene2,obj(ii));
            if ~fix2.Success         % The failure of WthThenHold indicates that the subject didn't maintain fixation on the sample image.
                error_type = 3;      % So it is a "break fixation (3)" error.
                run_scene(scene0,[97,36]); % blank screen | 97 = fixation broken, 36 = fix cross OFF
                break
            end
            
        else % blank scenes interwoven
            fix3 = SingleTarget(eye_); % Initialize the eye tracking adapter
            fix3.Target = [(-0.25*scrsize(1))+fixpt(1) fixpt(2)]; % Set the fixation point
            fix3.Threshold = fixThreshold; % Set the fixation threshold
           
            bck3 = ImageGraphic(fix2);
            bck3.List = { {'graybackgroundcross.png'}, [0 0], [0 0 0], Screen.SubjectScreenFullSize };
            
            % Set the timer
            cnt3 = TimeCounter(bck3);
            cnt3.Duration = 20; %grating_isi;
            
            % Run the scene
            scene3 = create_scene(cnt3);
            run_scene(scene3,obj(ii));
            if ~fix3.Success         % The failure of WthThenHold indicates that the subject didn't maintain fixation on the sample image.
                error_type = 3;      % So it is a "break fixation (3)" error.
                run_scene(scene0,[97,36]); % blank screen | 97 = fixation broken, 36 = fix cross OFF
                break
            end
        end
        
    end
    
end

if error_type == 0
    run_scene(scene0,[32,36]); 
    goodmonkey(100, 'NonBlocking',1,'juiceline',1, 'numreward',1, 'pausetime',0, 'eventmarker',96); % 100 ms of juice x 2
end

trialerror(error_type); 

%% Write info to file
taskdir = SAVEPATH; %fileparts(which('T_RFtuning.m'));
filename = strcat(taskdir,'\',datafile,'.g',upper(paradigm),'Grating_di');
    
for pres = 1:prespertr
    
    fid = fopen(filename, 'a'); % append
    formatSpec =  '%04u\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%u\t%f\t%s\t%f\t%f\t%f\r\n';
    fprintf(fid,formatSpec,...
        TrialRecord.CurrentTrialNumber,...
        X,... % needs DEV
        Y(pres),... % needs DEV
        grating_xpos(pres),...
        grating_ypos(pres),...
        other_xpos(pres),...
        other_ypos(pres),...
        grating_tilt(pres),...
        grating_sf(pres),...
        grating_contrast(pres),...
        grating_fixedc(pres),...
        grating_diameter(pres),...
        grating_eye(pres),...
        grating_varyeye(pres),...
        grating_oridist(pres),...
        0,...
        0,...
        grating_header,...
        grating_phase(pres),...
        0,...
        now);
    
    fclose(fid);
end

    
%% Give the monkey a break
set_iti(800); % Inter-trial interval in [ms]

%%

