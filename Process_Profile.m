function [AdjustedDistance, RenormalizedDose, Profile_analysis] = Process_Profile(Distance, Dose, Center, Spacing, Smoothing)
% [ShiftedDistance RenormalizedDose, Profile_analysis] = Centre_Profile(Distance,Dose)
% [ShiftedDistance RenormalizedDose, Profile_analysis] = Centre_Profile(Distance,Dose, Center)
% [ShiftedDistance RenormalizedDose, Profile_analysis] = Centre_Profile(Distance,Dose, Center, Spacing)
% [ShiftedDistance RenormalizedDose, Profile_analysis] = Centre_Profile(Distance,Dose, Center, Spacing, Smoothing)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Centre_Profile finds the centre of a Profile and returns the adjusted
%    Distance and renormalized dose with distance points spacing apart and
%    centred on 0.  It does this by using derivatives to find the field
%    edge shifting the distance and using spline interpolation to generate
%    a new profile.
%
%   Input Arguments
%     Distance         =   The distance (x) coordinates of the profile
%
%     Dose             =   The relative dose for the profile
%
%     Center           =   Indicates if profile should be centered. The
%                          options are 'Center' or Asymmetric' if absent no
%                          centering is done. It is required if
%                          interpolation or smoothing is desired.
%
%     Spacing          =   The desired distance spacing for the output
%                          profile.  if absent no interpolation is done
%
%     Smoothing        =   The desired smoothing method for profiles
%                          can be one of 'sgolay', 'pchip' or 'none'  If
%                          interpolation is requested, smoothing is
%                          required. Interpolation is required for
%                          smoothing.
%
%   Output Arguments
%     AdjustedDistance =  The Profile distance (x) coordinates shifted and
%                         respaced (if spcing provided) to centre the
%                         profile around 0.
%     RenormalizedDose =  The profile doce re-normalized to the centre of
%                         the profile.
%     Profile_analysis =  A structured array consisting of the following
%                         fields: 
%                              CAX_Dose      =  The calculated dose at the
%                                               central axis after
%                                               centering, interpoaltion
%                                               and smoothing.   
%                                               from 50% to 50% dose points
%                              field_width   =  The profile width in cm
%                                               from 50% to 50% dose points
%                              penumbra      =  The average penumbra with
%                                               in cm between the 20% and
%                                               80% dose points
%                              flatness      =  The variation in % of the
%                                               dose in the region that is
%                                               80% of the field size.  
%                              symmetry      =  The maximum dose
%                                               difference in percent
%                                               between matching points on
%                                               opposite sides of the
%                                               profile over the region
%                                               that is 80% of the field
%                                               size.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialize the function

% Check the number of input arguments (Minimum 2 Maximum 3)
narginchk(2, 5)

% Check for centering
if (nargin > 2)
    if strcmpi(Center,'Center')
        DoCenter = true;
    elseif strcmpi(Center,'Asymmetric')
        DoCenter = false;
    else
        error('Centre_Profile:InvalidParameter', ['The value: ' ...
            Center ' is an invalid option for centering.  ' ...
            'Valid options are ' ...
            char(180) 'Center'  char(180) 'and ' ...
            char(180) 'Asymmetric' char(180)]);
    end
else
    DoCenter = false;
end

% Check for interpolation
if (nargin > 3)
    DoInterpolation = true;
else
    DoInterpolation = false;
end

% Check for Smoothing
if (nargin == 5)
    if strcmpi(Smoothing,'sgolay')
        SmoothingType = 'sgolay'; % Use smoothing from curve fitting toolbox
    elseif strcmpi(Smoothing,'pchip')
        SmoothingType = 'pchip'; % Use Standrd Matlab smoothing
    elseif strcmpi(Smoothing,'linear')
        SmoothingType = 'linear'; % Use Standrd Matlab smoothing
    else
        SmoothingType = ''; % Anything else means no smoothing
    end
else
    SmoothingType = '';
end


%% Do rough normalization
MaxDose = max(Dose);
RoughNormDose = Dose/MaxDose*100;

%% Determine the 50% points
% Find the derivative
delta = diff(RoughNormDose);

% Identify the regions for the two peaks which correspond to the field edges
peak_range = 0.66*(max(delta)-min(delta))/2;
X1 = find(delta>peak_range);
X2 = find(delta<-peak_range);
if and(size(X1,2) > 4, size(X2,2) > 4)
    % find the 50% dose point
    lower_fit = polyfit(RoughNormDose(X1)',Distance(X1),1);
    D50(1) = 50*lower_fit(1)+lower_fit(2);

    upper_fit = polyfit(RoughNormDose(X2)',Distance(X2),1);
    D50(2) = 50*upper_fit(1)+upper_fit(2);
else
    DoCenter = false;
end
%% Calculate the centre
if DoCenter
    % The centre offset is calculated from an average of these two distances
    shift = (D50(1)+ D50(2))/2;
    
    % the distance position is moved to centre the data
    ShiftedDistance = Distance - shift;
else
    ShiftedDistance = Distance;
    shift = 0;
end
Profile_analysis.shift = shift;
%% Do the interpolation if required and renormalize the dose to the centre point

if (DoInterpolation)
    %% Interpolate the dose data
    
    if DoCenter
        % if profile is symmetric centre the profile around 0
        % Find the smalest maximum profile distance
        MaxDistance = min(abs([max(ShiftedDistance) min(ShiftedDistance)]));
        % find the largest distance to use so a 0 point is included in the data
        DistanceExtent = floor(MaxDistance/Spacing)*Spacing;
        
        % generate new distance range
        AdjustedDistance = (-DistanceExtent:Spacing:DistanceExtent)';
    else
        % make an asymmetric range select valid lower and upper limits that are
        % multiples of the spacing
        LowerDistanceExtent = ceil(min(ShiftedDistance)/Spacing)*Spacing;
        UpperDistanceExtent = floor(max(ShiftedDistance)/Spacing)*Spacing;
        
        % generate new distance range
        AdjustedDistance = (LowerDistanceExtent:Spacing:UpperDistanceExtent)';
    end
    
    % Interpolate and smooth the dose using the new distance data
    if strcmpi(SmoothingType,'sgolay')
        % do a linear interpolation and then smooth
        InterpolatedDose = interp1(ShiftedDistance,Dose,AdjustedDistance,'linear');
        % this function comes from the curve fittiong toolbox
        smoothed = smooth(AdjustedDistance,InterpolatedDose,15,'sgolay',3);
        
    elseif strcmpi(SmoothingType,'pchip')
        % interpolate data using pchip
        % This is an alternate smoothing that doesn't require the curve fitting
        % toolbox
        smoothed = interp1(ShiftedDistance,Dose,AdjustedDistance,'pchip');
        
    elseif isempty(SmoothingType)
        % don't smooth, just use linear interpolation
        smoothed = interp1(ShiftedDistance,Dose,AdjustedDistance,'linear');
    else
        % don't smooth, just use linear interpolation
        %Currently redundant allows for easy addition of other options eg.
        %spline
        smoothed = interp1(ShiftedDistance,Dose,AdjustedDistance,'linear');
    end
else
    %% Don't do Interpolation
    AdjustedDistance = ShiftedDistance;
    smoothed = Dose;
end

%% renormalize the interpolated data
if DoCenter
    % if profile is centered around 0 then normalize to offset distance =0
    X0 = find(abs(AdjustedDistance)==min(abs(AdjustedDistance)));
    RenormalizedDose = smoothed/smoothed(X0(1))*100;
else
    % if profile is Asymmetric, normalize to max dose
    MaxDose = max(smoothed);
    RenormalizedDose = smoothed/MaxDose*100;
end

%% Calculate Field width
%% Find R50
%divide data into upper and lower portions
lower_range = AdjustedDistance < 0;
lower_dose = RenormalizedDose(lower_range);
lower_distance = AdjustedDistance(lower_range);
% find the upper and lower 50% dose point
R50_Lower_range = lower_dose > 45 & lower_dose < 55;
if size(lower_dose(R50_Lower_range),1) < 4
    R50_Lower_range = lower_dose > 40 & lower_dose < 60;
    if size(lower_dose(R50_Lower_range),1) < 3
        R50_Lower_range = lower_dose > 30 & lower_dose < 70;
    end
end
lower_fit = polyfit(lower_dose(R50_Lower_range),lower_distance(R50_Lower_range),1);
R50_L = 50*lower_fit(1)+lower_fit(2);

upper_range = AdjustedDistance > 0;
upper_dose = RenormalizedDose(upper_range);
upper_distance = AdjustedDistance(upper_range);
R50_upper_range = upper_dose > 45 & upper_dose < 55;
if size(upper_dose(R50_upper_range),1) < 4
    R50_upper_range = upper_dose > 40 & upper_dose < 60;
    if size(upper_dose(R50_upper_range),1) < 3
        R50_upper_range = upper_dose > 30 & upper_dose < 70;
    end
end
upper_fit = polyfit(upper_dose(R50_upper_range),upper_distance(R50_upper_range),1);
R50_U = 50*upper_fit(1)+upper_fit(2);

Profile_analysis.field_width = R50_U - R50_L;
%% Calculate penumbra
% find the upper and lower 20% and 80% dose points
R20_Lower_range = lower_dose > 18 & lower_dose < 22;
if size(lower_dose(R20_Lower_range),1) < 6
    R20_Lower_range = lower_dose > 15 & lower_dose < 25;
    if size(lower_dose(R20_Lower_range),1) < 4
        R20_Lower_range = lower_dose > 12 & lower_dose < 28;
    end
end
R80_Lower_range = lower_dose > 78 & lower_dose < 82;
if size(lower_dose(R80_Lower_range),1) < 6
    R80_Lower_range = lower_dose > 75 & lower_dose < 85;
    if size(lower_dose(R80_Lower_range),1) < 4
        R80_Lower_range = lower_dose > 72 & lower_dose < 88;
    end
end
R20_lower_fit = polyfit(lower_dose(R20_Lower_range),lower_distance(R20_Lower_range),2);
R20_L = 400*R20_lower_fit(1) + 20*R20_lower_fit(2) + R20_lower_fit(3);
R80_lower_fit = polyfit(lower_dose(R80_Lower_range),lower_distance(R80_Lower_range),2);
R80_L = 400*R80_lower_fit(1) + 20*R80_lower_fit(2) + R80_lower_fit(3);
lower_penumbra = R80_L - R20_L;

R20_Upper_range = upper_dose > 18 & upper_dose < 22;
if size(upper_dose(R20_Upper_range),1) < 6
    R20_Upper_range = upper_dose > 15 & upper_dose < 25;
    if size(upper_dose(R20_Upper_range),1) < 4
        R20_Upper_range = upper_dose > 12 & upper_dose < 28;
    end
end
R80_Upper_range = upper_dose > 78 & upper_dose < 82;
if size(upper_dose(R80_Upper_range),1) < 6
    R80_Upper_range = upper_dose > 75 & upper_dose < 85;
    if size(upper_dose(R80_Upper_range),1) < 4
        R80_Upper_range = upper_dose > 72 & upper_dose < 88;
    end
end
R20_upper_fit = polyfit(upper_dose(R20_Upper_range),upper_distance(R20_Upper_range),2);
R20_U = 400*R20_upper_fit(1) + 20*R20_upper_fit(2) + R20_upper_fit(3);
R80_upper_fit = polyfit(upper_dose(R80_Upper_range),upper_distance(R80_Upper_range),2);
R80_U = 400*R80_upper_fit(1) + 20*R80_upper_fit(2) + R80_upper_fit(3);
upper_penumbra = R20_U - R80_U;

Profile_analysis.penumbra = mean([lower_penumbra, upper_penumbra]);

%% Calculate flatness
% find dose with the region 80% of field width
distance_80 = round(Profile_analysis.field_width*.8/2,1);
range_80 = abs(AdjustedDistance) < distance_80;
dose_80 = RenormalizedDose(range_80);

Profile_analysis.flatness = max(dose_80) - min(dose_80);

%% Calculate Symmetry
% select uniform distance points 1 mm appart on each side of centre 
distance_lower = -distance_80:0.1:0;
distance_upper = distance_80:-0.1:0;
% find the dose un these two regions
dose_lower = interp1(AdjustedDistance,RenormalizedDose,distance_lower,'linear');
dose_upper = interp1(AdjustedDistance,RenormalizedDose,distance_upper,'linear');

Profile_analysis.symmetry = max(abs(dose_lower-dose_upper));

%% Find Central Axis dose
% find 5 points around the central axis
centre_point = min(abs(AdjustedDistance));
centre_index = find(AdjustedDistance == centre_point);
centre_range = [centre_index-2:1:centre_index+2];
centre_distance = AdjustedDistance(centre_range);
centre_dose = smoothed(centre_range);
Profile_analysis.CAX_Dose = interp1(centre_distance,centre_dose,0,'linear');


