function [stim] = removeMEMRtrials_Fn(stim, trialstoRemove_cell)
%Function to remove trials from MEMR dataset

%Convert cell to double
trialstoRemove_doub = str2double(trialstoRemove_cell);
trialstoRemove2 = str2double(regexp(num2str(trialstoRemove_doub),'\d','match'));

%% Procedure: Remove trials from non-AR File, perform AR, resave as
%_AR_removed

%Directory stuff - need this
%Set USERdir automatically
%if (ismac == 1) %MAC computer
    %USERdir = '/Volumes/Heinz-Lab/Users/Hannah';
    %USERdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab/Users/Hannah');
%else %WINDOWS computer
    %USERdir='Y:\Users\Hannah';
    %USERdir = strcat('Y:',filesep,'Users',filesep,'Hannah');
%end
%EXPname='ARO_2018_MEMR_TTS';

%Adding paths
%ROOTdir=strcat(USERdir,filesep,EXPname);
%DATAdir=strcat(ROOTdir,filesep,'Data');
%ANALYSISdir=strcat(ROOTdir,filesep,'Analysis');
%addpath(strcat(ANALYSISdir,filesep,'MEMR'));

%Already in data folder!
%Enter data folder
%here1 = pwd;
%cd(DATAdir);
%here2 = pwd;

%if dataCollection == 0
%Load in non-AR mat file
%User choose file
%filter = '*.mat';
%ASK ANIMAL FIRST, pull up folder of just animal MEMR data
%f=msgbox('Please choose the RAW data in which ou would like to remove trials. Must be RAW data!');
%[file,path] = uigetfile(filter,'CHOOSE RAW FILE');
%filename = file;
%ERROR MESSAGE IF filename CONTAINS AR!!!
%cd(path);
%load(file); %Loaded in as stim
%cd(here2);
throwaway = stim.ThrowAway;
numTrials = stim.Averages+throwaway; %plus throwaway = 33
trialstoKeep = [];

%account for throwaway problem
if any(trialstoRemove2 == 1) 
    throwaway_spot = find(trialstoRemove2 == throwaway);
    trialstoRemove = trialstoRemove2(throwaway_spot+1:end); %remove throwaway
else
    trialstoRemove = trialstoRemove2;
end

%now create "keep" trials
for keepIND = throwaway:numTrials
    if ~any(trialstoRemove == keepIND)
        trialstoKeep = [trialstoKeep keepIND];
    end
end
trialstoKeep2 = trialstoKeep;

%still need to remove throwaway
if any(trialstoKeep==1)
   %remove first trial
   %technically remove throwaway trial 1 -- 32
   trialstoKeep = trialstoKeep(1:end-1);
end

%remove trials, resave into struct
stimNEW = stim;
stimNEW.trialstoRemove = trialstoRemove2;
stimNEW.trialstoKeep = trialstoKeep2;

%resp variable
resp = stim.resp;
respNEW = resp(:,trialstoKeep,:,:);

%Save respNEW into stim.resp
stim.resp = respNEW;

%ADDS in marker into stim to indicate trials have been removed
stim.removeMarker = 1;

%Perform Artifact Rejection on REMOVED data
%Call analyzeMEM_Fn
%AR = 1;
%stim = analyzeMEM_Fn(stim,AR);

%Resave file
%filename3 = filename(1:end-4);
%filename1 = strcat(filename3,'_AR_removed.mat');
%cd(path);
%Resaves stim into DATA folder
%save(filename1,'stim') 
%Go back to overall data folder
%cd(here2);

%Let user know
%TO DO: Add in Chin and Cond variables above
%fprintf('You have successfully removed trials %d for Chin: %s;  Cond: %s\n',trialstoRemove2,Chins2Run,Conds2Run);
fprintf('You have successfully removed trial %d\n',trialstoRemove2);

end

