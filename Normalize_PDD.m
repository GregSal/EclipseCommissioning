function [TargetDepth, NormDose] = Normalize_PDD(Depth,Dose,Spacing,Dmax)
% [ShiftedDistance RenormalizedDose] = Normalize_PDD(Depth,Dose,spacing)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Normalize_PDD returns the depth dose curve with depth points spacing
%    apart and renormalized to d_max. It smoothes the data using linear
%    interpolation.
%
%   Output Arguments
%     AdjustedDistance =  The Profile distance (x) coordinates shifted and
%                         respaced (if spcing provided) to centre the
%                         profile around 0.
%     RenormalizedDose =  The profile doce re-normalized to the centre of
%                         the profile.
%
%   Input Arguments
%     Depth            =   The distance (x) coordinates of the profile
%
%     Dose             =   The relative dose for the profile
%
%     spacing          =   The desired distance spacing for the output
%                          profile.  if absent no interpolation is done
%     Dmax             =   The desired Maximum dose point. If present the
%                          PDD will be shifted so that the Point of Maximum
%                          dose is located at Dmax.  Interpolation must be
%                          done if the curve is to be shifted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%TODO  This function has not been tested
%% initialize the function

% Check the number of input arguments (Minimum 2 Maximum 3)
narginchk(2, 4)

% Check for interpolation
if (nargin > 3)
    DoInterpolation = true;
    if (nargin == 4)
        DoShift = true;
    else
        DoShift = false;
    end
else
    DoInterpolation = false;
end

%% Do initial normalization
MaxDose = max(Dose);
Dose = Dose/MaxDose*100;

%% Do the interpolation if required and renormalize the dose to d_max

if (DoInterpolation)
    if (DoShift)
        %% Shift the Dmax point
        % find the location of the maximum dose
        DmaxIndex = find(Dose == max(Dose));
        % if more that one point at maximum dose select the one closest to
        % the surface
        DmaxPoint = Depth(DmaxIndex(1));
        
        % shift the Depths to line up Dmax
        CurveShift = Dmax - DmaxPoint;
        Depth = Depth + CurveShift;
        disp(['Depth Shift = ' num2str(CurveShift,2)]);
    end
    %% Interpolate the dose data
    
    % find the largest distance to use so a 0 point is included in the data
    DistanceExtent = floor(max(Depth)/Spacing)*Spacing;
    
    % generate new distance data
    TargetDepth = (0:Spacing:DistanceExtent)';
    
    % Interpolate the dose using the new distance data
    FinalDose = interp1(Depth,Dose,TargetDepth,'linear');
    
else
    FinalDose = Dose;
    TargetDepth = Depth;
end

%% renormalize the interpolated data
MaxDose = max(FinalDose);
NormDose = FinalDose/MaxDose*100;

end