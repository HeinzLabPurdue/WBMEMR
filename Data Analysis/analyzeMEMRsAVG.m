%% MEMR Averages Comparison - Step 3
    %This script compares pre/post datasets for each chin and all chins
    %Option to analyze "raw" or "clean" data
    
%Process:
%1. Loop through Chin and Condition...
%2. Plot comparison of three conditions on top of each other for EACH CHIN
%3. Plot comparison of three conditions for ALL CHINS

%Saves:
%1. Plot of three conditions for EACH CHIN (tiff file)
%2. Plot of three conditions for ALL CHINS (tiff file)

%Before running code, MUST DO:
%Edit "Directory-related" to be specific to computer of use
%**Edit Chins2Run and Conds2Run to loop through
%****Perform preprocessing on MEMR data (preprocessALL_MEMR and
%preprocess1_MEMR) and autothresh_MEMR for analysis of CLEAN dataset

%% Directory-related - FIRST!
%NOTE: EDIT directories to be specific to your computer
%Current folder is "Data Collection"
close all
clear;

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
warning off;

%% Determine "raw" or "clean"
%Look at clean or original data
%Do you want to analyze raw or clean data?
answer = questdlg('Would you like to analyze the RAW or CLEAN data?','User Choice','RAW','CLEAN','None');
switch answer
    case 'RAW'
        load_clean = 0;  
    case 'CLEAN'
        load_clean = 1;
    case 'None'
        errordlg('Code error.','ERROR!');
end

%% Begin analysis
MEMR_DATA=cell(length(Chins2Run),length(Conds2Run));
plotcolors = {'b','g','r','c','y','k'};
linestyles = {'-','--','-.',':'};

%HARD-CODED: because some mismatched, hard code this in
elicitor_dBSPL=[34   40   46   52    58    64    70    76    82    88    94];
MEMR_ECpressChange_dB=cell(size(Conds2Run));
for CondIND=1:length(Conds2Run)
	MEMR_ECpressChange_dB{CondIND}=NaN+zeros(length(Chins2Run),length(elicitor_dBSPL));
end
for ChinIND=1:length(Chins2Run)
    %cd into correct spot - into "Analyzed Data"
    cd(ANALYZEDdatadir);
    cd(Chins2Run{ChinIND});
    here4 = pwd;
	for CondIND=1:length(Conds2Run)
		fprintf('Collecting MEMR Data for Chin: %s;  Cond: %s\n',Chins2Run{ChinIND},Conds2Run{CondIND})
        cd(Conds2Run{CondIND});
        here5 = pwd;
		Dlist=dir('*.mat');
        %Separate clean and non-clean data - HG ADDED 2/24/20
        for pp = 1:length(Dlist)         
            if contains(Dlist(pp).name,'clean') %CLEAN DATA
                Dlist_clean = Dlist(pp);
            else %AR DATA
                Dlist_not_clean = Dlist(pp);
            end    
        end
        
		%if length(Dlist)>1
        if length(Dlist_not_clean)>1
			error('WHY is there more than 1 *.mat file for this condition?')
		%elseif length(Dlist)<1
        elseif length(Dlist_not_clean)<1
			error('WHY are there NO *.mat files for this condition?')		
        end
        
        %Which data to load
        if load_clean == 1 %Load clean data
            %HG ADDED 3/31/20
            if ~exist('Dlist_clean','var')
                %TO DO: Give info on which chin, cond needs CLEAN data
                errordlg('You chose CLEAN but no CLEAN data exists. Run auto_memr_thresh.m first!','CLEAN DATA DOESNT EXIST');
                %return;
                break;
            else %clean data exists
                load(Dlist_clean.name);
            end
        else %Load non-clean data
           load(Dlist_not_clean.name);
        end
       
		MEMR_DATA{ChinIND,CondIND}=memrDATA1;
		
		%% Gather data
		clear ECpressChange_dB_TEMP %mean across 8 elicitors, dim 2
        %HG ADDED 2/24/20 -- to account for plotting clean data
        if load_clean == 1
            ECpressChange_dB_TEMP = memrDATA1.y_clean;
        else
           ECpressChange_dB_TEMP = mean(abs(memrDATA1.MEM(:, memrDATA1.ind)), 2);
        end

        %plot(elicitor, mean(abs(MEM(:, ind)), 2)
        %plotnum(1) = plot(x,y_clean, 'ok-', 'linew', 2);

      if (length(ECpressChange_dB_TEMP) ~= 11)
         remaining = 11 - length(ECpressChange_dB_TEMP);
         remaining = NaN*ones(remaining,1);
         if load_clean == 1
            ECpressChange_dB_TEMP = vertcat(remaining, ECpressChange_dB_TEMP'); 
         else
           ECpressChange_dB_TEMP = vertcat(remaining, ECpressChange_dB_TEMP);  
         end
      end
      
      %ADDED TO CHECK!!!
      %ASSUMPTION on order: 1week pre --> 1day post --> 2weeks post
      if (CondIND == 1)
         pre(ChinIND) = max(ECpressChange_dB_TEMP);
      elseif (CondIND == 2)
         day1(ChinIND) = max(ECpressChange_dB_TEMP);
      else
         twoweeks(ChinIND) = max(ECpressChange_dB_TEMP);
      end
	   
	 %% Place data in correct place based on elicitor SPLs used
      %Average ONE value for each of ELEVEN elicitor levels
      MEMR_ECpressChange_dB{CondIND}(ChinIND,:) = ECpressChange_dB_TEMP;
         
	end   % Cond loop
    
    %back to chin folder
    cd(here4);
   
	% Plot individual Chin Data
	figure(str2num(Chins2Run{ChinIND}(2:end))); clf
	clear legendstr plotnum
	
	%Creates figure
   %Plot elicitor level versus ear canal pressure
	for CondIND=1:length(Conds2Run)
		lineapp = strcat(plotcolors{CondIND},linestyles{CondIND});
		%plotnum(CondIND)=plot(elicitor_dBSPL, MEMR_ECpressChange_dB{CondIND}(ChinIND,:), lineapp, 'linew', 2);	
        plotnum(CondIND)=plot(elicitor_dBSPL, MEMR_ECpressChange_dB{CondIND}(ChinIND,:), lineapp, 'linew', 2);
		hold on;
		legendstr{CondIND} = Conds2Run{CondIND};
	end
	hold off;
	clear title;
    if load_clean == 1
        title(strcat('MEMRs--',Chins2Run{ChinIND},'--CLEAN'));
    else
        title(strcat('MEMRs--',Chins2Run{ChinIND},'--RAW'));
    end
	xlabel('Elicitor Level (dB SPL)', 'FontSize', 16);
	ylabel('\Delta Ear Canal Pressure (dB)', 'FontSize', 16,'Interp','tex');
	set(gca, 'FontSize', 16);
	ylim([0 2]);
	xlim([30 100])
	grid on
	set(gca,'linew',2);
	h=legend(plotnum(:),legendstr{:},'Location','northwest');
	set(h,'Interpreter','none');
	
	filename_old=strcat(Chins2Run{ChinIND},'_MEMRs');
    if load_clean == 1
        filename = strcat(filename_old,'_clean');
    else
        filename = strcat(filename_old,'_raw');  
    end
    print('-dtiff',filename) 
	
end  % Chin loop

%% Ask user if they want to see summary fig
answer = questdlg('Would you like to see a summary figure for all Chins2Run?','User Choice','Yes','No','None');
switch answer
    case 'Yes'
        summaryfig = 1;  
    case 'No'
        summaryfig = 0;
    case 'None'
        errordlg('Code error.','ERROR!');
end

% AVG data
if (summaryfig == 1)
    cd(ANALYZEDdatadir);
    for CondIND=1:length(Conds2Run)
        CondDATA = MEMR_ECpressChange_dB{CondIND};
       for elicitorIND = 1:length(MEMR_ECpressChange_dB{CondIND})
          AVG_memrDATA_xx(elicitorIND) = nanmean(CondDATA(:,elicitorIND));
          STD_memrDATA_xx(elicitorIND) = nanstd(CondDATA(:,elicitorIND));
       end
       AVG_memrDATA_ECpc_dBSPL(CondIND,:) = AVG_memrDATA_xx; %NOT IN CELL FORMAT RIGHT NOW
       STD_memrDATA_ECpc_dBSPL(CondIND,:) = STD_memrDATA_xx;
       %AVG_memrDATA_ECpc_dBSPL{CondIND}=nanmean(MEMR_ECpressChange_dB{CondIND},1);
        %STD_memrDATA_ECpc_dBSPL{CondIND}=nanstd(MEMR_ECpressChange_dB{CondIND},1);
    end

    % Plot AVG Chin Data
    figure(1000); clf
    % plotcolors = {'k'};
    % linestyles = {'-','--','-.',':'};
    clear legendstr plotnum

    %Creates figure
    for CondIND=1:length(Conds2Run)
        lineapp = strcat(plotcolors{CondIND},linestyles{CondIND});
        %plotnum(CondIND)=errorbar(elicitor_dBSPL, AVG_memrDATA_ECpc_dBSPL{CondIND}, STD_memrDATA_ECpc_dBSPL{CondIND}/sqrt(length(Chins2Run)), lineapp, 'linew', 2);
        plotnum(CondIND)=errorbar(elicitor_dBSPL, AVG_memrDATA_ECpc_dBSPL(CondIND,:), STD_memrDATA_ECpc_dBSPL(CondIND,:)/sqrt(length(Chins2Run)), lineapp, 'linew', 2);
       hold on;
        legendstr{CondIND} = Conds2Run{CondIND};
    end
    legendstr={'pre TTS','1-day post TTS','2-weeks post TTS'};
    hold off;
    clear title;
    title(sprintf('MEMRs-- AVERAGE DATA (n=%d; mean+-STE)',length(Chins2Run)));

    if load_clean == 1
        title(sprintf('MEMRs-- AVG DATA (n=%d; mean+-STE)--CLEAN',length(Chins2Run)));
    else
        title(sprintf('MEMRs-- AVG DATA (n=%d; mean+-STE)--RAW',length(Chins2Run)));
    end
    xlabel('Elicitor Level (dB SPL)', 'FontSize', 16);
    ylabel('\Delta Ear Canal Pressure (dB)', 'FontSize', 16,'Interp','tex');
    set(gca, 'FontSize', 16);
    ylim([0 2]);
    xlim([30 100])
    grid on
    set(gca,'linew',2);
    h=legend(plotnum(:),legendstr{:},'Location','northwest');
    set(h,'Interpreter','none');

    cd(strcat(ANALYSISdir,filesep,'MEMR'))
    if load_clean == 1
        save analyzeMEMRsAVG_clean MEMR_DATA elicitor_dBSPL MEMR_ECpressChange_dB AVG_memrDATA_ECpc_dBSPL STD_memrDATA_ECpc_dBSPL  
        print('-dtiff','AVG_MEMRs_clean')
    else
        save analyzeMEMRsAVG_raw MEMR_DATA elicitor_dBSPL MEMR_ECpressChange_dB AVG_memrDATA_ECpc_dBSPL STD_memrDATA_ECpc_dBSPL
        print('-dtiff','AVG_MEMRs_raw') 
    end
end
close all;

