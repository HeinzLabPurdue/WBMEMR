function [memrDATA1] = preprocess1_MEMR(DATAdir,ANALYSISdir,Chin,Cond)
%% MEMR preprocess1 script - Step 1A
    %This script allows you to preprocess ONE dataset
        %Nothing depends on data struct
    
%Process:
%1. Must send in DATAdir and ANALYSIS dir; Chin and Cond are optional
%2. Data "grabbed" from DATAdir and "saved" into ANALYSISdir
%3. After cd'ing into correct spot, ensures that AR file has been saved
%4. Checks if revisit flag is 1, calling revisitMEMR
%5. Calls analyzeMEM_Fn one last time and saves stim and tiff file
    %into "Analyzed Data" in ANALYSISdir

    %If neither Chin or Cond sent in, saves into "Analyzed Data"
    %If both are sent in, saves into specific Chin/Cond folder in "Analyzed
    %Data"
    %If only Chin is sent in, will loop through all Conditions in DATAdir
    %NOT ALLOWED: to only send in Cond and not Chin

%Saves:
%After calling analyzeMEM_Fn last time, saves mat file and tiff file of result

%Before running code, MUST DO:
%Edit "Directory-related" to be specific to computer of use


%% Directory-related - FIRST!
%DATAdir = data to analyze
%ANALYSISdir = "Data Analysis" (analysis code, "Analyzed Data")
SUBFUNCTIONname = 'subfunctions';
ANALYSISsub = strcat(ANALYSISdir,filesep,SUBFUNCTIONname);
ANALYZEDdatadir =  strcat(ANALYSISdir,filesep,'Analyzed Data');

%% Set up under assumption that only one data set exists for this chin/condition
% if AR doesn't exist, it will be created
clear memrDataDirName

%ASSUMPTION: Cond will not be an input WITHOUT Chin input (on its own)
    %Data structure needs Chin to "find" Cond subfolder

%Establish saveINTO and dataIN
%cd into data folder
if ((isempty(Chin)) && (isempty(Cond))) %neither Chin or Cond sent in
    %Save into ANALYZEDdatadir
    saveINTO = ANALYZEDdatadir;
    %Grab data from...
    dataIN = DATAdir;
    %If Chin and Cond are not sent in, will save into "Analyzed Data"
    %Analyze "everything" in DATAdir
    opt = 1;
    
elseif ((~isempty(Chin)) && (~isempty(Cond))) %both Chin and Cond sent in
    %Save into Chin/Cond subfolder
    here = pwd;
    cd(ANALYZEDdatadir);
    %Check if Chin folder exists first
    Dlist=dir(Chin);
    if isempty(Dlist) %create directory if it doesn't exist
        fprintf('   ***Creating "%s" Directory (/pre and /post)\n',Chin)
        mkdir(Chin)
        %cd(Chins2Run{ChinIND})
        mkdir('pre')
        mkdir('post')
    else
        %cd(Chins2Run{ChinIND})
        %chin subfolder exists
    end
    Dlist=dir(Cond);
    %Check if Condition folder exists second
    if isempty(Dlist) %create directory if it doesn't exist
        fprintf('   ***Creating "%s" Directory\n',Cond)
        mkdir(Cond)
        %cd(Cond)
    else
        %cd(Cond)
    end
    %Place to save analyzed data
    saveINTO = strcat(ANALYZEDdatadir,filesep,Chin,filesep,Cond);
    %Grab data from...
    dataIN = strcat(DATAdir,filesep,Chin,filesep,Cond);
    %Specific to one chin, one condition
    opt = 2;
    
elseif ~(isempty(Chin)) %Only Chin sent in
    %Save into Chin subfolder
    here = pwd;
    cd(ANALYZEDdatadir);
    Dlist=dir(Chin);
    if isempty(Dlist) %create directory if it doesn't exist
        fprintf('   ***Creating "%s" Directory (/pre and /post)\n',Chins2Run{ChinIND})
        mkdir(Chins2Run{ChinIND})
        cd(Chins2Run{ChinIND})
        mkdir('pre')
        mkdir('post'
    else
        cd(Chins2Run{ChinIND})
    end
    %Place to save analyzed data
    saveINTO = strcat(ANALYZEDdatadir,filesep,Chin);
    %Grab data from...
    dataIN = strcat(DATAdir,filesep,Chin);
    %Analyze "everything" in Chin subfolder
    opt = 3;
end

%% Enter correct directory
if (opt == 1) %neither Chin or Cond sent into function
    condSubFolders = dataIN;
    cd(dataIN);
elseif (opt == 2) %both Chin and Cond sent into function
    condSubFolders = dataIN;
    cd(dataIN);
elseif (opt == 3) %Only Chin sent into function
    %Need to "check" to see if Cond subfolders exist
    cd(dataIN);
    %Common conditions are pre and post
    preList = dir('pre*');
    postList = dir('post*');
    count = 0;
    if ~isempty(preList) %Cond Subfolders exist for PRE!
        dirPRE = dir;
        for w = 1:length(dirPRE)
           if ~contains(dirPRE(w).name,'.')
               condSubFolders(count) = strcat(dataIN,filesep,'pre',filsep,dirPRE(w).name);
               count = count + 1;
           end
        end
    end
    if ~isempty(postList) %Cond subfolders exist for POST!
        dirPOST = dir;
        for p = 1:length(dirPOST)
            if ~contains(dirPOST(p).name,'.')
                condSubFolders(count) = strcat(dataIN,filesep,'post',filesep,dirPOST(p).name);
                count = count + 1;
            end
        end
    end
    %condSubFolders provides the path of each Cond subfolder (if they
    %exist)
end

%Keeps track if looping is necessary
numReps = length(condSubFolders);

%Now cd'd into folder of inputs provided

%% Locate files
for loopIND = 1:length(condSubFolders)
    if (numReps > 1)
       here2 = pwd;
       cd(condSubFolders(loopIND)); 
    end
    %else, should be in correct spot already (no need to cd)
    %in subfolder WITH DATA...
    
    %AR should be same as "AR_removed"
    %AR has stim.removeMarker == 1 if trials have been removed
    Dlist_AR = dir('MEMR*AR.mat');
    Dlist_MEMR=dir('MEMR*.mat'); 
    remove = 0;

    %NEED THIS BELOW?
    %Locate and separate clean mat files - HG ADDED 2/24/20
%     if ~isempty(Dlist_AR) %removed trial AR mat file exists
%         for pp = 1:length(Dlist_AR)
%            if contains(Dlist_AR(pp).name,'clean') %CLEAN DATA
%                Dlist_AR_clean = Dlist_AR(pp);
%            else %AR DATA
%                Dlist_AR_not_clean = Dlist_AR(pp);
%            end
%         end
%     end

    %What there should be
    %Definitily one "raw" MEMR file
    %Potentially one "raw_removed" MEMR file
    %Should be one AR file

    %If AR file is not in folder, PERFORM AR FIRST
    %AR should contain dataset to be analyzed -- either raw or raw_removed
    if isempty(Dlist_AR)
       %% run AR (from bottom)
       %If no AR exists in Dlist...
       %if ARmarker == 0 %No AR file in folder
          for h = 1:length(Dlist_MEMR)
             if contains(Dlist_MEMR(h).name,'MEMR') && ~contains(Dlist_MEMR(h).name,'AR')
                %Assume no AR in folder, perform AR
                AR = 1;
                %Load in stim in analyzeMEM_Fn not here??
                stim = load(Dlist_MEMR(h).name); %load in stim
                stim = stim.stim; %hardcoded
                here = pwd;
                cd(ANALYSISsub)
                [stimSAVE] = analyzeMEM_Fn(stim,AR,remove);
                cd(here);
                filename = strcat(Dlist_MEMR(h).name(1:end-4),'_AR.mat');
                stim = stimSAVE;
                save(filename,'stim')  % Saves .mat file with as many variables as you list

                %Create new struct memr to send back
                %memr.freq(h,:) = stimSAVE.freq;
                %memr.MEM(h,:,:) = stimSAVE.MEM;
                %memr.elicitor(h,:) = stimSAVE.elicitor;
                %memr.ind(h,:) = stimSAVE.ind;
             end
          end
       %end
    end

    %FROM HERE - you know you only have ONE AR file
    % GET RID Of k
    %Look for AR files again -- now AR file should exist
    close all;
    Dlist_AR = dir('MEMR*AR.mat');
    Dlist = Dlist_AR;
    %First try to find AR file in Dlist
    ARmarker = 0;
    for k = 1:length(Dlist)
       if contains(Dlist(k).name,'MEMR') && contains(Dlist(k).name,'AR')
          %Analysis of just AR file
          ARmarker = 1;
          AR = 0;

          %Pull up analysis and save
          saveName = Dlist(k).name;
          load(saveName);
          if exist('stimSAVE','var')
             stim = stimSAVE;
          end

          %Check REVISIT
          if exist('stim.REVISIT','var')
              if (stim.REVISIT == 1)              
                %Notify need to revisit data
                str2 = sprintf('ERROR! Need to revisit artifact rejection for %s, %s before continuing!',Chin,Cond);
                errordlg(str2,'REVISIT DATA!');
                %Call revisit function!!!!!
                %Send in AR file name
                %Send in path (in DATA folder)
                fname = saveName; %check this
                path = pwd; %check this
                here = pwd;
                cd(ANALYSISsub)
                [stim] = revisitMEMR(stim,fname,path);
                cd(here);

                %End result:
                %stim.REVISIT = 0 --> data is "good"
                %stim.REVISIT still 1 --> add in "_need_to_recollect"
                if (stim.REVISIT == 1)
                    %Still an issue - Need to recollect data
                    str3 = sprintf('You indicated that data needs to be recollected for %s, %s! The program will terminate now.',Chin,Cond);
                    errordlg(str3,'NEED TO RECOLLECT DATA!'); 
                    %Terminate program 
                    %User must remove Chin/Cond combination from
                    %(Chins2Run/Conds2Run)
                    return;
                elseif (stim.REVISIT == 0) %AFTER REVISITING
                    %User has indicated that data is now ready to be analyzed
                    %continue on
                end

                %return;
              elseif (stim.REVISIT == 0)
                  %DATA is good to go
                  %"no need to revisit" indicated during data collection
              end
          end

          %Check remove
          if exist('stim.removeMarker','var')
              remove = 1;
          end

          %Call analyzeMEM function
          here = pwd;
          cd(ANALYSISsub);
          stimNEW = analyzeMEM_Fn(stim,AR,remove);
          cd(here);

          %Save into struct
          memr.freq = stimNEW.freq; %ONLY ONE ROW OF DATA!
          memr.MEM = stimNEW.MEM;
          memr.elicitor = stimNEW.elicitor;
          memr.ind = stimNEW.ind;

       end
    end

    %Save into struct
    memrDATA1 = memr;

    %Save into correct spot
    cd(saveINTO);
    save(filename,'memrDATA1')  % Saves .mat file with as many variables as you list
    print('-dtiff',filename)
    cd(here2);
end
end

