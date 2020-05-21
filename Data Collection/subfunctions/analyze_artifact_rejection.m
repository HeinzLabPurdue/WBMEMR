function [stim] = analyze_artifact_rejection(stim,loop,seefigure)

if seefigure == 1
   %Figure for each loop
   figure(loop);
else
   close all;
   figure(loop)
end

%First calculate averages
for L = 1:stim.nLevels %8
   for T = 1:stim.nTrials %32
      stim.AVERAGES(L,T) = nanmean(stim.rms(L,T,:));
      stim.MEAN(L)=nanmean(stim.AVERAGES(L,:));
      stim.STD(L)=nanstd(stim.AVERAGES(L,:));
   end
   subplot(stim.nLevels,1,L)
   %subplot(stim.nLevels/2,2,L)
   for i = 1:stim.nreps
      plot(stim.rms(L,:,i),'x')
      hold on
   end
   plot(stim.AVERAGES(L,:),'b-')
   plot([1 stim.nTrials],ones(1,2)*stim.MEAN(L),'k-')
   plot([1 stim.nTrials],ones(1,2)*(stim.MEAN(L)+2*stim.STD(L)),'k--')
   hold off
   title(['Level: ' num2str(L) ', Trials: ' , num2str(stim.counter(L)) '/' num2str(stim.nTrials)]);
   xlim([0,stim.nTrials+1]);
   ylabel('rms');
   xlabel('Trial number');
end

%Stdev level
stim.NumSTDcriteria=2;

%Decide if trial needs rejected
for L = 1:stim.nLevels %8
   for T = 1:stim.nTrials %32
      if loop==1 %super strict
         if ~isempty(find(squeeze(stim.rms(L,T,:))>(stim.MEAN(L)+stim.NumSTDcriteria*stim.STD(L))))
            stim.reject(L,T)=1; %0 = GOOD TRIAL, 1 = REJECTED TRIAL
            stim.rms(L,T,:) = NaN;
         end
      else %less strict
         if (stim.AVERAGES(L,T) > (stim.MEAN(L)+stim.NumSTDcriteria*stim.STD(L))) %LESS STRICT
            stim.reject(L,T)=1; %0 = GOOD TRIAL, 1 = REJECTED TRIAL
            stim.rms(L,T,:) = NaN;
         end
      end
   end
   stim.counter(L) = numel(stim.reject(L,:)) - sum(stim.reject(L,:)~=0);
end

end


