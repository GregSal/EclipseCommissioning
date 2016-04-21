function [AdjustedDistance, RenormalizedDose] = Centre_Profile(Distance,Dose,Center,Spacing,Smoothing)
% [ShiftedDistance RenormalizedDose] = Centre_Profile(Distance,Dose)
% [ShiftedDistance RenormalizedDose] = Centre_Profile(Distance,Dose,Center)
% [ShiftedDistance RenormalizedDose] = Centre_Profile(Distance,Dose,Center,Spacing)
% [ShiftedDistance RenormalizedDose] = Centre_Profile(Distance,Dose,Center,Spacing, Smoothing)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Centre_Profile finds the centre of a Profile and returns the adjusted
%    Distance and renormalized dose with distance points spacing apart and
%    centred on 0.  It does this by using derivatives to find the field
%    edge shifting the distance and using spline interpolation to generate
%    a new profile.
%
% Note: Centre % GridSize input order switched to allow for Centering
% without interpolation
%
%   Output Arguments
%     AdjustedDistance =  The Profile distance (x) coordinates shifted and
%                         respaced (if spcing provided) to centre the
%                         profile around 0.
%     RenormalizedDose =  The profile doce re-normalized to the centre of
%                         the profile.
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO With current argument setup if only two input arguments then all
% that is done is to normalize the profile.  Need to think about all
% possible compinations to do.
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
    else
        SmoothingType = ''; % Anything else means no smoothing
    end
else
    SmoothingType = '';
end


%% Do rough normalization
MaxDose = max(Dose);
RoughNormDose = Dose/MaxDose*100;

%% Calculate the centre
if DoCenter
    % Find the derivative
    delta = diff(RoughNormDose);
    
    % Identify the regions for the two peaks which correspond to the field edges
    X1 = find(delta>5);
    X2 = find(delta<-5);
    
    % find the 50% dose point
    D50(1) = interp1(RoughNormDose(X1),Distance(X1),50,'linear');
    D50(2) = interp1(RoughNormDose(X2),Distance(X2),50,'linear');
    
    % The centre offset is calculated from an average of these two distances
    shift = (D50(1)+ D50(2))/2;
    
    % the distance position is moved to centre the data
    ShiftedDistance = Distance - shift;
else
    ShiftedDistance = Distance;
end
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