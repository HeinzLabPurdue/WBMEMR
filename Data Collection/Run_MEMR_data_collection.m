%% MEMR Data Collection Script
    %This should be the main script you run for MEMR data collection.
    
%Process:
%1. Loop through trials, levels (exit at end of trial using radio button)
    %View collected data every three trials (not including throwaway trial)
%2. Remove trials (if needed)
%3. Perform Artifact Rejection on raw data
%4. Check user satisfaction; if user not satisfied, add REVISIT flag
    %REVISIT flag checked in analysis code

%Saves:
%1. Raw data mat file (all trials)
%2. Removed trials raw data mat file (if trials removed)
%3. AR file (if trials removed, AR will be without removed trials)

%Before running code, MUST DO:
%Edit "Directory-related" to be specific to computer of use

%% Directory-related - FIRST!
%NOTE: EDIT directories to be specific to your computer
%Current folder is "Data Collection"

%Set USERdir automatically
%Hint for USERdir: use pwd when you have cd'd into correct directory of
%code, ignore "data collection" subfolder in pwd name
%If using mac computer..
if (ismac == 1) %MAC computer
    USERdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab/Users/Hannah');
else %if using WINDOWS computer..
    USERdir = strcat('Y:',filesep,'Users',filesep,'Hannah');
end
EXPname = 'MEMR';
CODEname = 'Data Collection'; 
ANALYSISname = 'Data Analysis';
DATAname = 'Data';
SUBFUNCTIONname = 'subfunctions';

ROOTdir=strcat(USERdir,filesep,EXPname);
DATAdir=strcat(ROOTdir,filesep,DATAname);
CODEdir = strcat(ROOTdir,filesep,CODEname);
CODEsub = strcat(ROOTdir,filesep,CODEname,filesep,SUBFUNCTIONname);
ANALYSISdir = strcat(ROOTdir,filesep,ANALYSISname);
ANALYSISsub = strcat(ROOTdir,filesep,ANALYSISname,filesep,SUBFUNCTIONname);
%Before every subfunction, change to subfunction folder

%% Plays clicks and noise, records response
% Initializing TDT
fig_num=99;
GB_ch=1;
FS_tag = 3;
Fs = 48828.125;
here = pwd;
cd(CODEsub);
%Call load_play_circuit function
[f1RZ,RZ,~]=load_play_circuit(FS_tag,fig_num,GB_ch);
cd(here);

%User input and checking
subj = input('Please subject ID:', 's');
earflag = 1;
flag = input('Please define experiment ("Pre" or "Post" Noise Exposure)'); %HG ADDED
while earflag == 1
    ear = input('Please enter which year (L or R):', 's');
    switch ear
        case {'L', 'R', 'l', 'r', 'Left', 'Right', 'left', 'right',...
                'LEFT', 'RIGHT'}
            earname = strcat(ear, 'Ear');
            earflag = 0;
        otherwise
            fprintf(2, 'Unrecognized ear type! Try again!');
    end
end
uiwait(warndlg('Set ER-10B+ GAIN to 40 dB','SET ER-10B+ GAIN WARNING','modal'));

%% DO FULL BAND FIRST
here = pwd;
cd(CODEsub);
%Call makeMEMRstim_500to8500Hz function
stim = makeMEMRstim_500to8500Hz; %calls function
cd(here);
stim.subj = subj;
stim.ear = ear;
pause(3);

%Set the delay of the sound
invoke(RZ, 'SetTagVal', 'onsetdel',0); % onset delay is in ms
playrecTrigger = 1;

%% Set attenuation and play
button = input('Do you want the subject to press a button to proceed? (Y or N):', 's');
switch button %animal experiments should select "No"
    case {'Y', 'y', 'yes', 'Yes', 'YES'}
        %getResponse(RZ);
        %fprintf(1, '\nSubject pressed a button...\nStarting Stimulation...\n');
        DELAY_sec=5; %for humans, increase this delay; for animals, delay is not needed
        fprintf(1, '\n%.f seconds until START...\n',DELAY_sec);
        pause(DELAY_sec)
        fprintf(1, '\nSubject waited %.f seconds ...\nStarting Stimulation...\n',DELAY_sec);
    otherwise
        fprintf(1, '\nStarting Stimulation...\n'); %Begin data collection
end

%Set resp characteristics
resplength = numel(stim.t);
stim.resp = NaN(stim.nLevels, stim.Averages, stim.nreps, resplength); %NaN
%stim.resp = zeros(stim.nLevels, stim.Averages, stim.nreps, resplength);

%Initialize AR
AR = 0; %0=No Artifact rejection, 1=Do Artifact rejection

%Create radio button selection
figRB = uifigure('Position',[680 678 398 271]);
bgRB = uibuttongroup(figRB,'Position',[5 80 390 160],'Title','Click to END Data Collection'); 
handles.rb1 = uiradiobutton(bgRB,'Position',[10 80 360 15]);
handles.rb2 = uiradiobutton(bgRB,'Position',[10 60 360 15]);
handles.rb1.Text = 'Continue Data Collection';
handles.rb2.Text = 'Stop Data Collection (will end after end of trial)'; 
set(handles.rb1,'Value',1); %preselected option
set(handles.rb2,'Value',0);

%For looping purposes
continueLOOPING = 1;
totalTrials = 0;

%At end of each trial (n=32), check if radio button has been switched
%If radio button has been switched, exit data collection
%Save stim with data up to that point
while (continueLOOPING == 1)
    for nTRIALS = 1: (stim.Averages + stim.ThrowAway) 
        disp('Trial number: ', nTRIALS);
        %Count total number of trials with data collected
        totalTrials = totalTrials + 1;
        for L = 1:stim.nLevels
            % Set attenuation on PA5 using Nel 2.0's PAset
            rc = PAset([0, 0, stim.clickatt, stim.noiseatt(L)]);
            %invoke(RZ, 'SetTagVal', 'attA', stim.clickatt);
            %invoke(RZ, 'SetTagVal', 'attB', stim.noiseatt(L));
            invoke(RZ, 'SetTagVal', 'nsamps', resplength);

            buffdataL = stim.click;
            buffdataR = squeeze(stim.noise(L, nTRIALS, :))';
            % Check for clipping and load to buffer
            if(any(abs(buffdataL(:)) > 1) || any(abs(buffdataR(:)) > 1))
                error('What did you do!? Sound is clipping!! Cannot Continue!!\n');
            end
            %Load the 2ch variable data into the RZ6:
            %invoke(RZ, 'WriteTagVEX', 'datain', 0, 'I16', (buffdata*2^15));
            invoke(RZ, 'WriteTagVEX', 'datainL', 0, 'F32', buffdataL);
            invoke(RZ, 'WriteTagVEX', 'datainR', 0, 'F32', buffdataR);
            pause(1.5);
            for k = 1:stim.nreps
                %Start playing from the buffer:
                invoke(RZ, 'SoftTrg', playrecTrigger);
                currindex = invoke(RZ, 'GetTagVal', 'indexin');
                while(currindex < resplength)
                    currindex=invoke(RZ, 'GetTagVal', 'indexin');
                end

                vin = invoke(RZ, 'ReadTagVex', 'dataout', 0, resplength,...
                    'F32','F64',1);
                %Accumluate the time waveform - no artifact rejection yet
                if (nTRIALS > stim.ThrowAway)
                    stim.resp(L, nTRIALS-stim.ThrowAway, k, :) = vin;
                end

                % Get ready for next trial
                invoke(RZ, 'SoftTrg', 8); % Reset OAE buffer

                %Notify user level completed
                fprintf(1, 'Done with Level #%d, Trial # %d \n', L, nTRIALS);
            end
        end  % levels
        pause(2);
               
       %Check if radio button has been switched to initiate STOP
       if ((get(handles.rb1,'Value') == 0) && (get(handles.rb2,'Value') == 1)) %END DATA COLLECTION selected
           continueLOOPING = 0; %EXIT WHILE LOOP
           break; %break out of while loop
       end

       %If data collection is continuing (i.e. radio button not changed), plot accordingly
        if nTRIALS>stim.ThrowAway %Every third trial (not including throwaway), plot all data collected
            if ~rem((nTRIALS-stim.ThrowAway),3)
                stimTEMP=stim;
                stimTEMP.resp=stim.resp(:,1:(nTRIALS-stim.ThrowAway),:,:);
                stimTEMP.Averages=nTRIALS-stim.ThrowAway;
                here = pwd;
                cd(CODEsub);
                %Calls analyzeMEM_Fn which plot the raw data up to point
                [~] = analyzeMEM_Fn(stimTEMP,AR); 
                cd(here)
                clear stimTEMP
            end
        end

    end
end
disp('Data collection is completed.')

%Count of how many trials were completed, save into stim
stim.totalTrials = totalTrials;

%% Info for conversion.. no averaging or conversion done online
mic_sens = 0.05; % V / Pa-RMS
mic_gain = db2mag(40);
P_ref = 20e-6; % Pa-RMS

DR_onesided = 1;

stim.mat2Pa = 1 / (DR_onesided * mic_gain * mic_sens * P_ref);

%% Save all RAW results
datetag = datestr(clock);
stim.date = datetag;
datetag(strfind(datetag,' ')) = '_';
datetag(strfind(datetag,':')) = '_';
%HG ADDED 4/6/20 -- ADDING IN _RAW in data name
%fname = strcat(respDir,'MEMR_', stim.subj, '_', stim.ear, '_', ...
    %datetag, '.mat');
fname = strcat(respDir,'MEMR_', stim.subj, '_', stim.ear, '_', ...
    datetag,'_raw.mat');

%HG ADDED 4/6/20
%Save directly into data folder
here = pwd;
cd(DATAdir);
chin = stim.subj;
Dlist=dir(chin);
if isempty(Dlist) %Chin folder does not exist yet
    fprintf('   ***Creating "%s" Directory (/pre and /post)\n',chin)
    mkdir(chin)
    cd(chin) %enter newly created chin folder
    mkdir('pre') %create pre subfolder
	mkdir('post') %create post subfolder
else
    cd(Chins2Run{ChinIND}) %enter previously created chin folder
end
%Pre and post subfolders should exist
cd(flag); %pre or post
%Will save directly into pre/post folder
%NOTE: USER must go in and transfer files into subfolder (e.g. 1weekPreTTS)

%First save raw data
disp('Saving RAW data ...')
fprintf('...into "%s" Subfolder\n',flag)
save(fname,'stim');

%% Final Analysis: remove trials (if necessary) and artifact rejection
%First, deal with removing trials
answer5 = questdlg('Would you like to remove trials from the raw dataset?'...
    ,'Remove trials?','Yes','No','Dont know');
switch answer5
    case {'Yes'}
        %User chooses trials to remove
        prompt = {'Enter trials you wish to remove from the dataset as comma-separated list with NO SPACES (i.e. 1,2,3).'};
        dlgtitle = 'Choose trials to remove';
        dims = [1 60];
        trialstoRemove_cell = inputdlg(prompt,dlgtitle,dims);
        
        %Call removeMEMRtrials_Fn to remove trials
        here = pwd;
        cd(CODEsub);
        stimREMOVED = removeMEMRtrials_Fn(stim, trialstoRemove_cell);
        cd(here);
        
        %If trials removed, save file: "raw_removed"
        fname2 = strcat(respDir,'MEMR_', stim.subj, '_', stim.ear, '_', ...
            datetag,'_raw_removed.mat');
        
        %Relabel stim for saving purposes
        stimOLD = stim;
        stim = stimREMOVED;
        
        %Resaves stimREMOVED ("_raw_removed.mat") into DATA folder
        save(fname2,'stim');
        
        %Set remove marker for AR
        remove = 1;
 
    case {'No'}
        %Continue to AR
        stim.removeMarker = 0;
        %Resave with removeMarker
        save(fname,'stim');
        
        %Set remove marker for AR
        remove = 0;
end

%%Third perform AR
%HG EDITED 4/6/20 - Perform AR on REMOVED dataset
answer = questdlg('Would you like to perform artifact rejection?'...
    ,'Artifact Rejection?','Yes','No','Dont know');
%Handle response
switch answer
    case {'Yes'}
        figure;
        AR = 1;
        %Call function - for stimREMOVED
        %stim = stimREMOVED;
        %remove declared above
        here = pwd;
        cd(CODEsub);
        [stim] = analyzeMEM_Fn(stim,AR,remove);
        cd(here);
        %Check satisfaction of AR
        answer3 = questdlg('Are you satisfied with artifact rejection? (If not, REVISIT flag in stim will be set to 1)'...
            ,'Artifact Rejection','Yes','No','Dont know');
        switch answer3
            case {'Yes'}
                stim.REVISIT = 0;
            case {'No'}
                %Add in revisit flag
                stim.REVISIT = 1;   
        end
        disp('Saving Artifact Rejected data ...')
        fname = strcat(respDir,'MEMR_', stim.subj, '_', stim.ear, '_', ...
            datetag, '_AR', '.mat');
        save(fname,'stim');
    case {'No'}
        %Completed, do nothing
end
warning('off');

%% Close and clean up
here = pwd;
cd(CODEsub);
close_play_circuit(f1RZ, RZ);
cd(here);
