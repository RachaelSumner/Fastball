% FastBall_Standard

% CREATED:
% Rachael Sumner, September 2020

% EDITED:


% NOTES:

% Requires https://github.com/widmann/ppdev-mex for triggers, else add your
% own and remove all trigger related code (commented in PARADIGM)

%%

PsychDefaultSetup(2);

% Trigger setup % 

try 
    ppdev_mex('Open',1); % Initilise triggering
catch
    warning('ppdev_mex did not execute correctly - Any triggers will not work'); 
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%     ESSENTIAL PERSONALISATION   %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% PATHS

SaveFile = % Path to save data to

FolderofStandards = ; % Path to standards
FolderofDeviants = ; % Path to deviants

% Creates list of files. Optional: change extension.
Standards = dir([FolderofStandards '*.png']); 
Deviants = dir([FolderofDeviants '*.png']); 


% TRIAL DETAILS

numTrials = 100; % How many trials do you want?
numDeviants = 20; %How many deviants (round up to nearest 5)? Will be evenly spaced. 


%PRESENTATION 

ScreenRefreshRate = ; % Screen refresh rate in Hz
PresentationRate = ; %Wait time for stimulus presentation and ISI in seconds. 
% Note: in general this should be callibrated to the screen refresh rate, and your computers time delay for loading the image. 
% e.g. PresentationRate = ((((1000/ScreenRefreshRate)*Positive integer that makes answer within these brackets closest to desired Hz)*0.001) - Any error remaining)/2; 
%   If desired PresentationRate = 166 Hz:
%       For a 60Hz Screen the Positive integer should be 10, for a 144 Hz screen it is 24 
%       Error remaining can be determined by desired Hz - mean(Results.Duration)

% STIMULUS SIZE

ImSq = [0 0 516 700]; % Image size - relative. [0 0 wide tall] 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%
%%%%%BASIC SCREEN SETUP

Priority(1);
ListenChar(2); %prevent keyboard input going to the MATLAB window

screens = Screen('Screens'); %For projecting to external screen. Get the number of screens in the computer setup
screenNumber = max(screens); %Can change to 0 for single screen. Otherwise displays on the most external screen (grab max number)

[window, windowRect] = Screen('OpenWindow', screenNumber);

HideCursor;

ScreenRect = Screen ('Rect', window);

black = BlackIndex(window);  % Retrieves the CLUT color code for black.
white = WhiteIndex(window);  % Retrieves the CLUT color code for white.
grey = white / 2;  % Computes the CLUT color code for grey.

[xCenter, yCenter] = RectCenter(windowRect); %Finds centre of the screen - Used in Screen('DrawDots',...) for fixation dot

PauseKey = 'p';
QuitKey = 'q';


%%%%%BASIC TRIAL SETUP

isStandard = ones(numTrials,1) % number of standards

IndexTheStandard = Shuffle([1:length(Standards)],1);
IndexTheDeviant = Shuffle([1:length(Deviants)],1);

k=5; % every kth image is a deviant 
for i = 1:length(isStandard)
       
    isStandard(k) = 2;
    
    k = k+ 5;
end

isTrial = isStandard(1:numTrials);

[ImSz, ~, ~] = CenterRect(ImSq, windowRect);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

ImagesUsed = [];
D=1;

MakeImages =[];


for i = 1:numTrials
    
    if isTrial(i) ==1  
        
    [img, ~, alpha] = imread([FolderofStandards Standards(i).name]); 
    image = Screen('MakeTexture', window, img)

    
    MakeImages{i}.img = img;
    MakeImages{i}.alpha = alpha;
    MakeImages{i}.image = image;

   
    ImagesUsed{i} = Standards(i).name;
    
    elseif isTrial(i) ==2  
        
    [img, ~, alpha] = imread([FolderofDeviants Deviants(D).name]); 
    image = Screen('MakeTexture', window, img);

    MakeImages{i}.img = img;
    MakeImages{i}.alpha = alpha;
    MakeImages{i}.image = image;
        
    ImagesUsed{i} = Deviants(D).name;

    D = D+1;
    
    end
      
end   

%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% PARADIGM %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Participant = input('please enter the study ID: ', 's');
PsychDefaultSetup(2);

Screen ('FillRect', window, white);
DrawFormattedText(window, 'Focus on the centre of the screen \n\nYou will see lots of flashing pictures \n\nPress space bar to Start', 'center','center', black);
Screen('Flip', window);
KbStrokeWait;

for trial = 1:numTrials

    Duration1{trial}  = GetSecs;

    Screen('DrawTexture', window, MakeImages{trial}.image, [],ImSz);
    Screen('Flip', window);
    
    
    % Send Trigger % 

    if isTrial(trial) ==1    % 1 = standard    
        lptwrite(1, 10)            
    elseif isTrial(trial) ==2   % 2 = deviant
        lptwrite(1, 5)
    end
   
    %               %
    
    WaitSecs(PresentationRate); 
    
    Duration2{trial}  = GetSecs;
    
    Screen('Flip', window);
    lptwrite(1, 0)
       
    WaitSecs(PresentationRate);   
       
end

Screen('Flip', window);
WaitSecs(1);


Type = []
for i = 1:length(isTrial)
    
    if isTrial(i) == 1
        Type{i} = 'Standard'
        
    elseif isTrial(i) == 2
        Type{i} = 'Deviant'
        
    end
end

Results.Type = Type;
Results.ImagesUsed = ImagesUsed;
Results.Duration = cellfun(@minus,Duration1, Duration2);

results_file_name = [SaveFile,'FastBall_',num2str(Participant)];
save(results_file_name,'Results')


%%%%END
ppdev_mex('Close',1); %Close port (for triggers)
Screen ('CloseAll');
ShowCursor;
ListenChar (0);
Priority(0)
