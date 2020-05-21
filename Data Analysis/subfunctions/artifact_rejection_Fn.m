function [stim] = artifact_rejection_Fn(stim)

%close all

%Create trial variable - HG EDITED 3/12/20
%stim.nTrials = stim.Averages;
stim.nTrials = size(stim.resp,2);

stim.rms = zeros(size(stim.resp(:,:,:,1)));
%Calculate rms
for T = 1:stim.nTrials %32
    for L = 1:stim.nLevels %8
       for R = 1:stim.nreps %7
          stim.rms(L,T,R)=rms(stim.resp(L,T,R,:));
       end
    end
end

%Creates stim.reject matrix
stim.reject = zeros(size(stim.rms(:,:,1)));

answer = questdlg('Would you like to see all the figures or just the last figure?'...
   ,'Figures','All','Last','Dont know');

%Handle response
switch answer
   case {'All'}
      %All figures
      seefigure = 1;
   case {'Last'}
      %Only last figure
      seefigure = 0;
end
warning('off');

%Looping: rms versus trial numbers
MAXloops = 9; %
OLDrejects = -1; 
NEWrejects = 0;
loop = 0;
%Add in counter of artifacts removed for each level
stim.counter = ones(stim.nLevels,1)*stim.nTrials;

while NEWrejects > OLDrejects
  loop=loop+1;
  OLDrejects=sum(sum(stim.reject));
  %Calls function
  [stim] = analyze_artifact_rejection(stim,loop,seefigure);
  NEWrejects=sum(sum(stim.reject));
  if loop> MAXloops
     warndlg('TOO MANY LOOPS')
  end
end


end

