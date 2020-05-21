%% MEMR preprocessALL script - Step 1
    %This script allows you to loop through and call preprocess1
    
%Process:
%1. Loop through Chin and Condition...
%2. Call preprocess1_MEMR.m each time

%Saves:
%No saving, sole purpose is for looping through chins/conditions
%All saving done in preprocess1_MEMR.m

%Before running code, MUST DO:
%Edit "Directory-related" to be specific to computer of use
%**Edit Chins2Run and Conds2Run to loop through

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
ANALYZEDdatadir = strcat(ROOTdir,filesep,ANALYSISname,filesep,'Analyzed Data');

%% Collect all Data - SECOND!
Chins2Run={'Q348','Q364'};
Conds2Run = {strcat('pre',filesep,'1weekPreTTS'),strcat('post',filesep,'1dayPostTTS'), strcat('post',filesep,'2weeksPostTTS')};

%% Looping through Chins and Conditions
%Enter "Analyzed Data" subfolder
cd(ANALYZEDdatadir);
%Begin looping
for ChinIND=1:length(Chins2Run)
	for CondIND=1:length(Conds2Run)
		SKIP=0;
		fprintf('Pre-Processing MEMR Data for Chin: %s;  Cond: %s\n',Chins2Run{ChinIND},Conds2Run{CondIND})
		% Check if basic directories (chin#/pre & /post) exist for this chin already
		Dlist=dir(Chins2Run{ChinIND});
		if isempty(Dlist) %create directory if it doesn't exist
			fprintf('   ***Creating "%s" Directory (/pre and /post)\n',Chins2Run{ChinIND})
			mkdir(Chins2Run{ChinIND})
			cd(Chins2Run{ChinIND})
			mkdir('pre')
			mkdir('post')
		else
			%cd(Chins2Run{ChinIND})
        end
        %Now cd'd into chin folder
		Dlist=dir(Conds2Run{CondIND}); % check if specific Condition directory exists, if not make it
		if isempty(Dlist)
			fprintf('   ***Creating "%s" Directory\n',Conds2Run{CondIND})
			mkdir(Conds2Run{CondIND})
            cd(Conds2Run{CondIND});
        else
            cd(Conds2Run{CondIND});
        end
        %Now cd'd into condition subfolder
        
        %Only complete preprocessing if preprocessing has not been
        %completed yet...
		%filename=sprintf('MEMR_AR_%s_%s',Chins2Run{ChinIND},Conds2Run{CondIND}(findstr(Conds2Run{CondIND},'\')+1:end));
        filesep_loc = findstr(Conds2Run{CondIND},filesep);
        filename=sprintf('MEMR_AR_%s_%s',Chins2Run{ChinIND},Conds2Run{CondIND}(filesep_loc+1:end));
		Dlist=dir(sprintf('%s*',filename));
		if ~isempty(Dlist)  %If data exists, SKIP recomputing
			SKIP=1;
			fprintf('   ***DATA ALREADY EXISTS: SKIPPING pre-processing Data for Chin: %s;  Cond: %s\n',Chins2Run{ChinIND},Conds2Run{CondIND})
        end
        here = pwd;
		
        %After checking, complete preprocessing...
		if ~SKIP
            %preprocess1_MEMR in main folder (not subfunctions)
			memrDATA1 = preprocess1_MEMR(DATAdir,ANALYSISdir,Chins2Run{ChinIND},Conds2Run{CondIND});
        end	
	end   % Cond loop
	
	%Make sure all figures are closed
	close all;
end  % Chin loop


