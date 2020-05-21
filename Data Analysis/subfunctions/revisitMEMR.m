function [stim] = revisitMEMR(stim,fname,path)
%% Revisit MEMR after data collection

%Stim must be RAW DATA!!
%fname will be raw data name
%path will be data subfolder (in DATA)

%Possibilities
%Loop see raw,remove,AR --> flag of REVISITED with numbers???

%REVISIT script call 
%copy code from end of run_MEMR chin
%Notify which trials were removed
%Reput past removed trials if necessary

%starting in AR file
stimSTARTAR = stim;

%% First show which trials have been removed, if any
%Need to load in raw_removed file to "see" removed trials
%But raw_removed file might not exist (so look at AR file instead)


%Notify user if and which trials have been removed during data colllection
%Old data does not have remove marker!
if isfield(stimSTARTAR,'removeMarker')
    if (stimSTARTAR.removeMarker == 1)
        %raw_removed file should exist
        fname_nomat = fname(1:end-4);
        fname_raw_removed = strcat(fname_nomat,'_raw_removed.mat');
        [stimRAWREMOVED] = load(fname_raw_removed);
        remove = 1;
        removedTrials = stimRAWREMOVED.RemovedTrials;
        removedTrials_str = mat2str(removedTrials);
        strMSG1 = strcat('You removed trials the following trials during data collection: ',removedTrials_str);
        f1 = msgbox(strMSG1,'TRIALS REMOVED!');
    elseif (stimSTARTAR.removeMarker == 0) %no trials removed during data collection
        remove = 0;
        strMSG2 = strcat('You did not remove any trials during data collection!');
        f2 = msgbox(strMSG2,'NO TRIALS REMOVED!');
    end
else %no trials removed (old data doesn't have removeMarker = no trials removed)
    remove = 0;
    strMSG2 = strcat('You did not remove any trials during data collection!');
    f2 = msgbox(strMSG2,'NO TRIALS REMOVED!'); 
end

%% Second run AR on RAW data
%Load in RAW DATA!!
fnameRAW = strcat(fname(1:end-7),'.mat'); %AR and .mat removed
currentspot=pwd;
cd(path);
[stimRAW] = load(fnameRAW);
stimRAW = stimRAW.stim; %hardcoded
cd(currentspot);

%Run AR to visualize ON RAW DATA
figure;
AR = 1;
%STIM LOADED INTO FUNCTION IS RAW DATA
[stimAR] = analyzeMEM_Fn(stimRAW,AR,remove);
stimtoEDIT = stimAR;
%stimAR == stimSTARTAR if no trials have been removed
%stimAR != stimSTARTAR if trials have been removed (all trials still exist)

%stim's that exist
%stimSTARTAR = post-AR stim (with trials removed if any)
    %with "REVISIT" flag and removeMarker (i.e. removed trials) flag
%stimRAW = RAW data stim
%stimAR = post-AR stim (with NO trials removed)
%stimtoEDIT = stimAR
%stimRAWREMOVED = stim with trials REMOVED


%This should pop-up the AR-corrected figure of RAW DATA 
    %Does not account for removed trials here!

%% Check user satisfaction - indicate next steps
%%Look back-(1)okay, (2)remove more trials, (3)AR tweaked, (4)data needs to be recollected

%Create radio button selection
%[x1 y1 width height]
%x1 and y1 are the coordinate of the window
figRB = uifigure('Position',[680 678 398 271]);
bgRB = uibuttongroup(figRB,'Position',[5 80 390 160],'Title','Choose next step from 4 options below:'); 
handles.rb1 = uiradiobutton(bgRB,'Position',[10 80 360 15]);
handles.rb2 = uiradiobutton(bgRB,'Position',[10 60 360 15]);
handles.rb3 = uiradiobutton(bgRB,'Position',[10 40 360 15]); 
handles.rb4 = uiradiobutton(bgRB,'Position',[10 20 360 15]); 
handles.rb5 = uiradiobutton(bgRB,'Position',[10 100 360 15]); 
handles.rb1.Text = 'Data is reasonable.';
handles.rb2.Text = 'Remove more trials.'; 
handles.rb3.Text = 'Tweak AR parameters.';
handles.rb4.Text = 'Data needs to be recollected.';
handles.rb5.Text = "*Preselected*: Choose different radio button to continue.";
%Set handles.rb1 to not-checked (because automatically checks first RB)
set(handles.rb1,'Value',0);
set(handles.rb2,'Value',0);
set(handles.rb3,'Value',0);
set(handles.rb4,'Value',0);
set(handles.rb5,'Value',1); %preselected option

%Initialize
continueLOOPING = 1;
optrb1 = 0;
optrb2 = 0;
optrb3 = 0;
optrb4 = 0;

while (continueLOOPING == 1) %uses break to break out of while loop
    disp('Continue looping');
    %(get(handles.rb5,'Value') == 1) %preselected button is pressed
    if (get(handles.rb5,'Value') == 0) %Different radio button selected
       if ((get(handles.rb1,'Value') == 1)  || (get(handles.rb2,'Value') == 1) || (get(handles.rb3,'Value') == 1) || (get(handles.rb4,'Value')))
           %An option has been chosen!
           if (get(handles.rb1,'Value') == 1)
               %Option 1 selected
               optrb1 = 1;
               %continueLOOPING = 0;
               break; %out of while loop
           elseif (get(handles.rb2,'Value') == 1)
               %Option 2 selected
               optrb2 = 1;
               %continueLOOPING = 0;
               break;  
           elseif (get(handles.rb3,'Value') == 1)
               %Option 3 selected
               optrb3 = 1;
               %continueLOOPING = 0;
               break;   
           elseif (get(handles.rb4,'Value') == 1)
               %Option 4 selected
               optrb4 = 1;
               %continueLOOPING = 0;
               break;
           end
       end
    end
    pause(1);
end

%Close radio button box
close(figRB);

%Result in one (optrb1, optrb2, optrb3, optrb4) equal to 1, rest 0

%% Once option selected, complete option
%(1)case "actually okay": pop-up box indicating"
%set stim.REVISIT = 0, NO TRIALS REMOVED SAVED IN AR FILE
if (optrb1 == 1) %option 1 selected, only one option can be selected
   strMSG3 = strcat('REVISIT flag will be removed from stim.');
   msgbox(strMSG3,'Data is reasonable.');

   %Resave over AR file (with REVISIT=1) 
   %fname is AR File name
   %Replacing stimSTARTAR (trials could be removed) with stimAR (no trials removed)
   
   %ADD in revisit flag set to zero WITH NO TRIALS REMOVED
   stimtoEDIT.REVISIT = 0;
   stim = stimtoEDIT;
   %Resave stim (over current AR file of same name)
   curspot=pwd;
   cd(path);
   disp('Saving stim WITHOUT REVISIT flag ...')
   save(fname,'stim');
   cd(curspot);
   
   stimtoSENDBACK = stim;

%(2)case "remove more trials"
%Rerun removeTrials_Fn - user able to change which trials are removed
%Check user satisfaction
%If satisfied, set stim.REVISIT=0
%If not satisfied, give one more chance to remove trials
%If still not satified, becomes "need to be recollected" (case 4)
%POP UP:  Note: You will not be able un-remove trials you removed during data collection
elseif (optrb2 == 1)  
    repeatREMOVE = 1;
    stimPREREMOVED = stimRAW;
    while (repeatREMOVE == 1)
         prompt = {'Enter trials you wish to remove from the dataset as comma-separated list with NO SPACES (i.e. 1,2,3).'};
         dlgtitle = 'Choose trials to remove';
         dims = [1 60];
         trialstoRemove_cell = inputdlg(prompt,dlgtitle,dims);

         %Call removeMEMRtrials_Fn to remove trials
         stimREMOVED = removeMEMRtrials_Fn(stimPREREMOVED, trialstoRemove_cell);
         
         %Run AR to visualize removed trials
         figure;
         remove = 1;
         AR = 1;
         %[stimAR] = analyzeMEM_Fn(stim,AR,remove);
         [stimAR_2] = analyzeMEM_Fn(stimREMOVED,AR,remove);
         stimtoEDIT_2 = stimAR_2; %RIGHT?

          %Check satisfaction of AR
          answer4 = questdlg('Are you satisfied with artifact rejection? If not, would you want to remove trials again OR does data need to be recollected?'...
                ,'Artifact Rejection','Yes','No, remove trials again.','No, data needs to be recollected','Dont know');
            switch answer4
                case {'Yes'}
                    repeatREMOVE = 0; %Leave while loop
                    %Remove REVISIT flag
                    stimtoEDIT_2.REVISIT = 0;
                    removedTrials = stimtoEDIT_2.RemovedTrials;
                    removedTrials_str = mat2str(removedTrials);
                    strMSG3 = strcat('Trials removed:',removedTrials_str,'. REVISIT flag will be removed from stim.');
                    msgbox(strMSG3,'Data is reasonable.');
                    %Resave stim
                    stim=stimtoEDIT_2;
                    curspot = pwd;
                    cd(path);
                    disp('Saving stim WITHOUT REVISIT flag ...')
                    save(fname,'stim'); 
                    cd(curspot)
                    
                    stimtoSENDBACK = stim;
                    
                case {'No, remove trials again.'}
                    %REMOVE TRIALS AGAIN
                    %does not remember which trials you just tried removing
                    repeatREMOVE = 1; 
                    
                case {'No, data needs to be recollected'}
                    repeatREMOVE = 0; %Leave while loop
                    strMSG4 = strcat('Filename will now include "_NEED_TO_RECOLLECT".'); %remove "raw" or "raw_removed" from name
                    %If the name flag, don't run any other code
                    %Resave over raw file --> need_to_recollect
                    msgbox(strMSG4,'Recollect data!'); 
                    %Edit filename
                    fnameNEW = strcat(fname,'_NEED_TO_RECOLLECT');
                    %Resave stim
                    stimtoEDIT_2.REVISIT = 1;
                    stim = stimtoEDIT; %save stimAR (no trials removed)
                    cd(path);
                    disp('Saving with "_NEED_TO_RECOLLECT" filename ...')
                    save(fnameNEW,'stim');
                    
                    stimtoSENDBACK = stim;
                    
            end
            disp('Saving Artifact Rejected data ...')
            save(fname,'stim');
            
            stimtoSENDBACK = stim;
    end

%(3)case "tweak AR"
%In the future: Call new analyzeMEM_Fn with more inputs
%Refer to artifact_rejection_Fn
elseif (optrb3 == 1) 
%Curerently: rerun AR, check satisfaction, if not, need to be recollected
    %Rerun AR on stimRAW
    %Run AR to visualize ON RAW DATA
    figure;
    AR = 1;
    remove = 0;
    %STIM LOADED INTO FUNCTION IS RAW DATA
    [stimAR_3] = analyzeMEM_Fn(stimRAW,AR,remove);
    stimtoEDIT = stimAR_3;
    
    answer4 = questdlg('Are you satisfied with artifact rejection? (If not, data needs to be recollected!)'...
            ,'Artifact Rejection','Yes','No','Dont know');
    switch answer4
        case {'Yes'}
            strMSG5 = strcat('REVISIT flag will be removed from stim.');
            msgbox(strMSG5,'Data is reasonable.');   
            %ADD in revisit flag set to zero WITH NO TRIALS REMOVED
            stimtoEDIT.REVISIT = 0;
            stim = stimtoEDIT;
            %Resave stim (over current AR file of same name)
            curspot=pwd;
            cd(path);
            disp('Saving stim WITHOUT REVISIT flag ...')
            save(fname,'stim');
            cd(curspot);
            
            stimtoSENDBACK = stim;
            
        case {'No'}
            %Data needs to be recollected
            strMSG4 = strcat('Filename will now include "_need_to_recollect".');
            msgbox(strMSG4,'Recollect data!'); 
            %Edit filename (stimtoEDIT is AR data)
            fnameNEW = strcat(fname,'_NEED_TO_RECOLLECT');
            stim = stimAR_3; %stimAR_3 == stimAR (as of now)
            %TO DO: Check to make sure analysis down-the-line gives error with flag
            
            %Resave stim --> NEW FILE (new filename)
            curspot = pwd;
            cd(path);
            disp('Saving with "_NEED_TO_RECOLLECT" filename ...')
            save(fnameNEW,'stim');  
            cd(curspot);
            
            stimtoSENDBACK = stim;
    end
 
%(4)case "data needs to be recollected"
%Save in filename that data is NOT GOOD, "need_to_recollect"
elseif (optrb4 == 1)
   strMSG4 = strcat('Filename will now include "_need_to_recollect".');
   msgbox(strMSG4,'Recollect data!'); 
   
   %Edit filename (stimtoEDIT is AR data)
   fnameNEW = strcat(fname,'_NEED_TO_RECOLLECT');
   stim = stimtoEDIT; %stimtoEDIT is stimAR (with no trials removed)
   %TO DO: SHOULD I add in REVISIT flag into this new file??
   %TO DO: Check to make sure analysis down-the-line gives error with flag
   %use move function - rename all files with "NEED_TO_RECOLLECT"
   
   %Resave stim --> NEW FILE (new filename)
   curspot = pwd;
   cd(path);
   disp('Saving with "_NEED_TO_RECOLLECT" filename ...')
   save(fnameNEW,'stim');  
   cd(curspot);
   
   stimtoSENDBACK = stim;
end
%% Send back stim - make sure you are sending back a "similar" thing
%Set at end of each if statement
stim = stimtoSENDBACK;
end

