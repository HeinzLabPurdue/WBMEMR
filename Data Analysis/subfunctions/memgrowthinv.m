function y = memgrowthinv(x, params)
% Inverse of the growth function
%

a = params(1);
b = params(2);
c = params(3);
t = params(4);


y = t - (1/a)*log(b./(x-c) - 1);

%Automatic setting - error control
y(x > b) = 94; %if thresh>b?

%HG removed on 2/18/20
%y(y > 88) = 94; %Removed for 