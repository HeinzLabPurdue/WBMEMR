%% Automatic MEMR Thresholding - Step 2
    %This script performs auto-thresholding on MEMR data
    
%Process:
%1. Loop through Chin and Condition...
%2. Perform auto-thresholding to generate clean dataset

%Saves:
%1. Plot of curve-fitting (with threshold) (tiff file)
%2. Updated memrDATA1 with "clean" variables (mat file)
%3. left/right subplots of clean data (with threshold) on right subplot

%Before running code, MUST DO:
%Edit "Directory-related" to be specific to computer of use
%**Edit Chins2Run and Conds2Run to loop through
%****Perform preprocessing on MEMR data (preprocessALL_MEMR and
%preprocess1_MEMR)

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

%USER INPUT: Set save to 1 if you would like to save summary figure
save_marker = 1;

%% Collect all Data - SECOND!
Chins2Run={'Q348','Q364'};
Conds2Run = {strcat('pre',filesep,'1weekPreTTS'),strcat('post',filesep,'1dayPostTTS'), strcat('post',filesep,'2weeksPostTTS')};
warning off;

%% Declarations and cd'ing
%Declare for plotting
cols = [103,0,31;
178,24,43;
214,96,77;
244,165,130;
253,219,199;
%247, 247, 247;
180, 180, 180;
209,229,240;
146,197,222;
67,147,195;
33,102,172;
5,48,97];
cols = cols(end:-1:1, :)/255;

%cd into "Analyzed Data"
cd(ANALYZEDdatadir);

%Initialize auto thresh array to fill up
auto_thresh_to_save = zeros(length(Chins2Run),length(Conds2Run));

%Looping
for ChinIND=1:length(Chins2Run)
    pwd1 = pwd;
    Chin = Chins2Run{ChinIND};
    cd(Chin);
    for CondIND=1:length(Conds2Run)
        SKIP=0;
		fprintf('Cleaning MEMR Data for Chin: %s;  Cond: %s\n',Chins2Run{ChinIND},Conds2Run{CondIND})
        pwd2 = pwd;
        Cond = Conds2Run{CondIND};
        cd(Cond);
        %Now in correct folder
        %Locate AR mat file AND check if CLEAN DATA already exists
        matFiles = dir('*.mat');
        for matCheck = 1:length(matFiles)
            if (contains(matFiles(matCheck).name,'clean'))
                SKIP = 1;
                fprintf('   ***CLEAN DATA ALREADY EXISTS: SKIPPING cleaning Data for Chin: %s;  Cond: %s\n',Chins2Run{ChinIND},Conds2Run{CondIND});
                cleanNAME = matFiles(matCheck).name;
                break;
            elseif (SKIP == 0) %only go into here if no clean data exists (other mat file)
                load(matFiles(matCheck).name)
                
                %Check REVISIT - necessary??
                if exist('stim.REVISIT','var')
                    if (stim.REVISIT == 1)
                        %Notify need to revisit data
                        str2 = sprintf('ERROR! Need to revisit preprocess1_MEMR.m for %s, %s before continuing!',Chin,Cond);
                        errordlg(str2,'REVISIT DATA!');
                        return;
                    end
                end
            end
        end
        %AR mat file has been loaded
        %Start auto thresh code here
        %Baseline correction first
        %Determine mean of two lowest levels
        if (SKIP == 0)
            elicitor = memrDATA1.elicitor;
            MEM = memrDATA1.MEM;
            ind = memrDATA1.ind;
            freq = memrDATA1.freq;
            if isfield(memrDATA1,'remove') %only if files have been removed
                remove1 = memrDATA1.remove;
            end
            mean_twolowlevels = mean(mean(abs(MEM(1:2,ind)),2));

            %Empty out memrNEW
            memrNEW = [];

            %Subtract the mean response from all levels
            for levelIND = 1:length(elicitor)
                memrNEW(levelIND) = mean(abs(MEM(levelIND,ind))) - mean_twolowlevels; 
            end

            %Calls memfit function
            x = elicitor;
            y = memrNEW;
            here = pwd;
            cd(ANALYSISsub);           
            [val, fitted] = memfit(x, y);
            cd(here);

            %Plotting purposes
            %Original figure - uncomment if necessary
            % figure;
            % plot(elicitor,mean(abs(MEM(:,ind)),2));
            % hold on;

            %New de-meaned figure
            figure;
            plot(x,y,'ok-', 'linew', 1);
            hold on;

            %Formatting figure
            xlabel('Elicitor Level (dB SPL)', 'FontSize', 16);
            ylabel('\Delta Ear Canal Pressure (dB)', 'FontSize', 16,'Interp','tex');
            set(gca,'FontSize', 16);
            xlim([30 100])

            %Plot sigmoid curve
            here = pwd;
            cd(ANALYSISsub);
            y_clean = memgrowth(x,fitted);
            cd(here);
            plot(x,y_clean,'r','Linewidth',1);
            hold on;

            %Set thresh_cutoff
            thresh_cutoff = 0.05;
            %thresh_cutoff = 0.1;

            %Calculate threshold -- memgrowthinv function
            %thresh_cutoff = 0.1; %Doesn't work well with chin data
            here = pwd;
            cd(ANALYSISsub);           
            thresh = memgrowthinv(thresh_cutoff,fitted);
            cd(here);
            title(['Threshold = ',num2str(round(thresh,1)),'dBSPL']); 

            %Plot threshold
            ylim1 = get(gca,'ylim');
            xlim1 = get(gca,'xlim');
            %line([thresh, thresh],[0,ylim1(2)],'Color','red','LineStyle','-.');
            line([xlim1(1), xlim1(2)],[thresh_cutoff, thresh_cutoff],'Color','red','LineStyle',':');
            line([thresh, thresh],[ylim1(1),ylim1(2)],'Color','red','LineStyle','-.');

            %ylim([0,ylim1(2)]);
            ylim([ylim1(1),ylim1(2)]);

            %Plot legend
            legend('Original','Clean','Threshold','Location','northwest');
            %legend('Original','Clean','Threshold','Location','northwest');

            %Save threshold figure
            %filename1 = sprintf('MEMR_AR_%s_%s_clean',Chins2Run{ChinIND},Conds2Run{CondIND}(findstr(Conds2Run{CondIND},'\')+1:end));
            filesep_loc = findstr(Conds2Run{CondIND},filesep);
            filename1=sprintf('MEMR_AR_%s_%s_clean',Chins2Run{ChinIND},Conds2Run{CondIND}(filesep_loc+1:end));
            %Save new MEMR figure -- two subplots - for later
            filename2=sprintf('MEMR_AR_%s_%s_clean_all',Chins2Run{ChinIND},Conds2Run{CondIND}(filesep_loc+1:end));
            print('-dtiff',filename1);

            %Subplotting both
            figure;
            axes('NextPlot','replacechildren','ColorOrder',cols);
            subplot(1,2,1); 
            semilogx(freq / 1e3, MEM, 'linew', 2);
            xlim([0.2, 8]);
            ticks = [0.25, 0.5, 1, 2, 4, 8];
            set(gca, 'XTick', ticks, 'XTickLabel', num2str(ticks'), 'FontSize', 16);
            lgd = legend(num2str(elicitor'),'Location','northeast','Fontsize',8); 
            %set(lgd,'FontSize',8); %added
            xlabel('Frequency (kHz)', 'FontSize', 16);
            ylabel('\Delta Ear Canal Pressure (dB)', 'FontSize', 16,'Interp','tex');

            subplot(1,2,2);
            plotnum(1) = plot(x,y_clean, 'ok-', 'linew', 2);  % Feb 9 - MH removed *5
            hold on;
            xlabel('Elicitor Level (dB SPL)', 'FontSize', 16);
            ylabel('\Delta Ear Canal Pressure (dB)', 'FontSize', 16,'Interp','tex');
            set(gca,'FontSize', 16);
            xlim([30 100])

            %plot threshold on subplot 2
            line([thresh, thresh],get(gca, 'ylim'),'Color','red','LineStyle','-.');

            %Title in subplot 2
            title(['Threshold =',' ',num2str(round(thresh,1)),'dBSPL'],'FontSize',10);

            %Saving figure
            print('-dtiff',filename2);
            
            %Save new mat file with fitted curve
            memrDATA1.y_clean = y_clean;
            memrDATA1.y = y;
            memrDATA1.thresh = thresh;
            memrDATA1.thresh_cutoff = thresh_cutoff;
            memrDATA1.fitted = fitted;

            %Saving mat file with new variables in memrDATA1
            save(filename1,'memrDATA1');

            %Close figure for next condition
            close all;

            %Back to chin folder
            cd(pwd2);
            
            %Save to array with just auto thresh
            auto_thresh_to_save(ChinIND,CondIND) = thresh;
            
        else %SKIP = 1
            %Load in clean data that already exists
            load(cleanNAME);
            %Save to array with just auto thresh
            thresh = memrDATA1.thresh;
            auto_thresh_to_save(ChinIND,CondIND) = thresh;
            
            %Back to chin folder
            cd(pwd2);
        end
    end
    cd(pwd1);
end

%Save auto thresh array
cd(ANALYSISsub);
if (save_marker == 1)
    filename3 = 'autoThresh_all.mat';
    chinsSAVED = Chins2Run;
    condsSAVED = Conds2Run;
    save(filename3,'auto_thresh_to_save','chinsSAVED','condsSAVED'); 
end


%% Compare visual to auto here
%Hardcoded for ARO CHINS!
%MUST HAVE PRE AND POST DATA FOR THIS TO WORK
%visual_thresh_to_save = zeros(size(auto_thresh_to_save,1),2);

%Uncomment to complete
%{

%In typical chin order
%[Q348, Q350, Q351, Q363, Q364, Q365, Q368]
visual_thresh_to_compare = [64 82; 52 58; 76 82; 82 NaN; 82 70; 76 70; 58 88];

%To compare -- just pre and 2 weeks post
auto_thresh_to_compare = auto_thresh_to_save(:,[1 3]);

%assigning
visual_pre = visual_thresh_to_compare(:,end-1);
visual_post = visual_thresh_to_compare(:,end);
auto_pre = auto_thresh_to_compare(:,end-1);
auto_post = auto_thresh_to_compare(:,end);

%Perform comparisons
%Post minus pre
%If positive, post threshold > pre threshold (follows trend)
%If negative, post threshold < pre threshold (outlier?)
visual_post_minus_pre = visual_post - visual_pre;
auto_post_minus_pre = auto_post - auto_pre;

%Averaging
visual_pre_mean = nanmean(visual_pre);
visual_post_mean = nanmean(visual_post);
auto_pre_mean = nanmean(auto_pre);
auto_post_mean = nanmean(auto_post);

%Plotting in MATLAB
%Pre | Post
plotting_array = [visual_pre_mean visual_post_mean; auto_pre_mean auto_post_mean];
bar(plotting_array);
ylabel('MEMR Threshold in dB SPL','FontSize',12);
title(['Visual vs. Auto Thresholding, n=',num2str(length(Chins2Run))]);
xticklabel = [{'Visual'},{'Auto'}];
set(gca,'xticklabel',xticklabel);

%Save summary figure
filename4 = sprintf('auto_vs_visual_summary_fig');
print('-dtiff',filename4);

%}


