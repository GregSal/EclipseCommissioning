function [DistanceError, Centre] = ProfileDistanceError(Distance1,Dose1,Distance2,Dose2)
% DistanceError = ProfileDistanceError(Distance1,Dose1,Distance2,Dose2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    ProfileDistanceError finds the distance between the 50% dose points of
%    2 centered and normalized profiles. It does this by using derivatives
%    to find the 50% field edge for each profile and subtracting
%    the difference.
%
%
%   Output Arguments
%     DistanceError    =  Contains the two 50% differences for the profiles
%
%     Centre           =  Contains calculated centre for the two profiles
%                         based on its two 50% point locations 
%
%   Input Arguments
%     Distance1        =   The distance (x) coordinates of the first profile
%
%     Dose1            =   The relative dose for the first profile.  
%                          It must be smoothed and normalized   
%
%     Distance2        =   The distance (x) coordinates of the second profile
%
%     Dose2            =   The relative dose for the secon profile.  
%                          It must be smoothed and normalized   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialize the function

% Check the number of input arguments (Minimum 2 Maximum 3)
narginchk(4, 4)

%% Calculate the 50% points for the first curve

% Find the derivative
delta1 = diff(Dose1);

% Identify the regions for the two peaks which correspond to the field edges
X1_first = delta1>2;
X1_second = delta1<-2;

% find the 50% dose point
D50_first1 = interp1(Dose1(X1_first),Distance1(X1_first),50,'linear');
D50_second1 = interp1(Dose1(X1_second),Distance1(X1_second),50,'linear');

%% Calculate the 50% points for the second curve

% Find the derivative
delta2 = diff(Dose2);

% Identify the regions for the two peaks which correspond to the field edges
X2_first = delta2>2;
X2_second = delta2<-2;

% find the 50% dose point
D50_first2 = interp1(Dose2(X2_first),Distance2(X2_first),50,'linear');
D50_second2 = interp1(Dose2(X2_second),Distance2(X2_second),50,'linear');

%% Calculate the diference between the 50% points
DistanceError(1) = D50_first1-D50_first2;
DistanceError(2) = D50_second1-D50_second2;

%% Calculate the centre of each profile
Centre(1) = (D50_second1-D50_first1)/2+D50_first1;
Centre(2) = (D50_second2-D50_first2)/2+D50_first2;
end