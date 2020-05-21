function [stim] = analyzeMEM_Fn(stim,AR,remove)

%ARTIFACT REJECTION
if AR == 1
   %Call artifact rejection function
   [stim] = artifact_rejection_Fn(stim);
   %Compare GREATtrials to stim.rms-->NEW STIM.RMS
   for L = 1:stim.nLevels
      for T = 1:stim.nTrials
         if stim.reject(L,T)
            stim.resp(L,T,:,:) = NaN;
         end
      end
   end  
   %Ask about closing all figures
   quest = 'Would you like to close all figures now?';
   answer = questdlg(quest,'Close all figures?','Yes','No','Don''t know');
   if (answer == 'Yes')
       close all;
   else
       %dont close
       %Problem??
   end
end

%original analyzeMEM below
endsamps = ceil(stim.clickwin*stim.Fs*1e-3);

freq = 10.^linspace(log10(200), log10(8000), 1024);
MEMband = [500, 2000];
ind = (freq >= MEMband(1)) & (freq <= MEMband(2));
stim.freq = freq;
stim.ind = ind;

%count1=0;
%count2=0;

for k = 1:stim.nLevels
    %RESHAPE ERROR
    temp = reshape(squeeze(stim.resp(k, :, 2:end, 1:endsamps)),...
      (stim.nreps-1)*stim.nTrials, endsamps);
   %temp = reshape(squeeze(stim.resp(k, :, 2:end, 1:endsamps)),...
      %(stim.nreps-1)*stim.Averages, endsamps);
   resp(k, :) = trimmean(temp, 20, 1); %#ok<*SAGROW>
   resp_freq(k, :) = pmtm(resp(k, :), 4, freq, stim.Fs);
   %HG ADDED (below) to account for NaN resp levels
   if isnan(nanmean(resp(k,:))) %probably won't get here?
       fprintf(' **** ERROR IN RESP! ONE LEVEL was saved as all NaNs! Go to analyzeMEM_Fn, line 40 ****');
   end
   %mustbeFinite(resp(k,:))
   %Fixes: Error using pmtm, Expected x to be finite.
   %if ~isnan(nanmean(resp(k,:)))
       %IGNORE NaN LINES
       %count1 = count1+1;
       %resp_freq(count1, :) = pmtm(resp(k, :), 4, freq, stim.Fs);
       %keep1(k) = 1;
   %else
       %keep1(k) = 0;
       %fprintf('\nError in resp_freq. Refer to line 42\n')
       %break;
   %end
   blevs = k;
   temp2 = squeeze(stim.resp(k, :, 1, 1:endsamps));
   if(numel(blevs) > 1) 
      temp2 = reshape(temp2, size(temp2, 2)*numel(k), endsamps);
   end
   bline(k, :) = trimmean(temp2, 20, 1);
   bline_freq(k, :) = pmtm(bline(k, :), 4, freq, stim.Fs);
   %if ~isnan(nanmean(resp(k,:)))
       %IGNORE NaN LINES
       %count2 = count2+1;
       %bline_freq(count2, :) = pmtm(bline(k, :), 4, freq, stim.Fs);
       %keep2(k) = 1;
   %else
       %keep2(k) = 0;
       %fprintf('Error in bline_freq. Refer to line 42.\n')
       %break;
   %end
   %bline_freq(k, :) = pmtm(bline(k, :), 4, freq, stim.Fs);
end

%Calculate MEM
MEM = pow2db(resp_freq ./ bline_freq);
stim.MEM = MEM;

%Set elicitor values
if(min(stim.noiseatt) == 6)
    elicitor = 94 - (stim.noiseatt - 6);
else
    elicitor = 94 - stim.noiseatt;
end

%HG EDITED 3/31/20 to account for removing NaN levels
%www=0;
%for ww = 1:length(keep1)
    %if keep1(ww) == 1
        %www = www+1;
        %elicitor_tokeep(www) = elicitor(ww);
    %end
%end

%Declare stim.elicitor
stim.elicitor = elicitor;
%stim.elicitor = elicitor_tokeep;

%Sets colors 
% cols = [103,0,31;
% 178,24,43;
% 214,96,77;
% 244,165,130;
% 253,219,199;
% 247, 247, 247;
% 209,229,240;
% 146,197,222;
% 67,147,195;
% 33,102,172;
% 5,48,97];
% cols = cols(end:-1:1, :)/255;

%Set variable - number of colors
n=11;

%Code below from getDivergentColors.m
% Colorblind friendly continuous hue/sat changes
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

ncols = size(cols, 1);
reds = interp1(1:ncols, cols(:, 1),...
    linspace(1, ncols, n), 'spline');
greens = interp1(1:ncols, cols(:, 2),...
    linspace(1, ncols, n), 'spline');
blues = interp1(1:ncols, cols(:, 3),...
    linspace(1, ncols, n), 'spline');
cols_n = [reds(:), greens(:), blues(:)];


%% cols = jet(size(MEM, 1));
figure;
%count3=0;
%HG ADDED 3/27/20
%for qq=1:length(elicitor)
    %if keep1(qq) == 1
        %count3=count3+1;
        %elicitortoInclude(count3) = elicitor(qq);
    %end
%end
%elicitor = elicitortoInclude;

%axes('NextPlot','replacechildren', 'ColorOrder',cols);
%cols = getDivergentColors(11);
axes('NextPlot','replacechildren','ColorOrder',cols);
subplot(1,2,1); 
semilogx(freq / 1e3, MEM, 'linew', 2);
xlim([0.2, 8]);
ticks = [0.25, 0.5, 1, 2, 4, 8];
set(gca, 'XTick', ticks, 'XTickLabel', num2str(ticks'), 'FontSize', 12);
%legend(num2str(elicitor'));
%lgd = legend(num2str(elicitor'),'Location','southwest','Fontsize',6);
lgd = legend(num2str(elicitor'),'Location','northeast','Fontsize',8); 
%set(lgd,'FontSize',6); %added
xlabel('Frequency (kHz)', 'FontSize', 12);
% ylabel('Ear canal pressure (dB re: Baseline)', 'FontSize', 16);
ylabel('\Delta Ear Canal Pressure (dB)', 'FontSize', 12,'Interp','tex');

%figure;
subplot(1,2,2);
plotnum(1) = plot(elicitor, mean(abs(MEM(:, ind)), 2) , 'ok-', 'linew', 2);  % Feb 9 - MH removed *5
hold on;
xlabel('Elicitor Level (dB SPL)', 'FontSize', 12);
ylabel('\Delta Ear Canal Pressure (dB)', 'FontSize', 12,'Interp','tex');
% ylabel('Change in Ear Canal Pressure (dB)', 'FontSize', 10);
set(gca,'FontSize', 12);
xlim([30 100])
%Add in title to alert on number of trials
%account for throwaway here??
if (remove == 1)
    str = strcat('Number of trials remaining=',num2str(stim.nTrials));
else
    str = strcat('No trials removed.',num2str(stim.nTrials),'total trials.');
end
title(str,'Fontsize',10);
set(gcf, 'units', 'normalized', 'position', [.1 .1 .6 .6]);
hold off;

end

