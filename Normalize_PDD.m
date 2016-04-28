function [AdjustedDepth, RenormalizedDose, Shift] = Normalize_PDD(Depth,Dose,Spacing,Smoothing,Shift_location,Position)
% [AdjustedDepth, RenormalizedDose, Shift] = Normalize_PDD(Depth,Dose,Spacing,Smoothing,Shift_location,Position)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Normalize_PDD returns the depth dose curve with depth points spacing
%    apart and renormalized to d_max. It smoothes the data using linear
%    interpolation.
%
%   Output Arguments
%     AdjustedDepth    =  The PDD distance (x) coordinates shifted (if
%                         shift location and Position provided) and
%                         respaced (if spacing provided).
%     RenormalizedDose =  The PDD dose re-normalized to Dmax.
%     Shift            =  The amount (in cm) the PDD depth was shifted.
%
%   Input Arguments
%     Depth            =   The distance (x) coordinates of the profile
%
%     Dose             =   The relative dose for the profile
%
%     Spacing          =   The desired distance spacing for the output
%                          profile.  if absent no interpolation is done
%     Smoothing        =   The desired smoothing method for profiles
%                          can be one of 'linear', 'sgolay', 'pchip' or
%                          'none'  If spacing is given, smoothing is
%                          required. Interpolation is required for
%                          smoothing.
%     Shift_location   =   The desired positional correction. values can be
%                          'Dmax' 'R50' or 'None'. If 'None' or absent, no
%                          shift will be done.  If present the position
%                          value is required.  The position value will be
%                          taken as either 'Dmax' or 'R50' and the PDD will
%                          be shifeted to force that positioning.
%     Position         =   The expected PDD distance setting of either
%                          'Dmax' or 'R50'.  If shift is 'Dmax', the PDD
%                          will be shifted so that the Point of Maximum
%                          dose is located at position.  If shift is 'R50',
%                          the PDD will be shifted so that the 50% point
%                          lies at that position. Interpolation must be
%                          done if the curve is to be shifted.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialize the function

% Check the number of input arguments (Minimum 2 Maximum 6)
narginchk(2, 6)

% Check for interpolation
if (nargin == 2)
    DoInterpolation = false;
    DoShift = false;
else
    if (nargin >3)
        DoInterpolation = true;
        % Check for Smoothing
        if strcmpi(Shift_location,'sgolay')
            SmoothingType = 'sgolay'; % Use smoothing from curve fitting toolbox
        elseif strcmpi(Smoothing,'pchip')
            SmoothingType = 'pchip'; % Use Standrd Matlab smoothing
        else
            SmoothingType = 'linear'; % Use linear interpolation as default
        end
        if (nargin == 5)
            return % bad number of arguments
        else
            if (nargin == 6)
                DoShift = true;
                % Check for shift type
                if strcmpi(Shift_location,'Dmax')
                    ShiftDmax = true; % Shift to Dmax
                elseif strcmpi(Shift_location,'R50')
                    ShiftDmax = false; % Shift to R50
                else
                    return % invalid shift location
                end
            else
                DoShift = false;
                Shift = 0;
            end
        end
    else
        if (nargin == 3)
            SmoothingType = 'linear'; % Use linear interpolation as default
        end
    end
end

%% Do initial normalization
MaxDose = max(Dose);
RenormalizedDose = Dose/MaxDose*100;

%% Do the interpolation if required and renormalize the dose to d_max

if (DoInterpolation)
    if (DoShift)
        if (ShiftDmax)
            %% Shift the Dmax point
            %TODO use curve fitting to select Dmax point
            % find the location of the maximum dose
            DmaxIndex = find(RenormalizedDose == max(RenormalizedDose));
            % if more that one point at maximum dose select the one closest to
            % the surface
            DmaxPoint = Depth(DmaxIndex(1));
            
            % shift the Depths to line up Dmax
            CurveShift = Dmax - DmaxPoint;
            Depth = Depth + CurveShift;
            disp(['Depth Shift = ' num2str(CurveShift,2)]);
        else
            %% Shift to R50
            % find the location of the maximum dose
            DmaxIndex = find(RenormalizedDose == max(RenormalizedDose));
            %select data past buildup region
            PastBuildupDose = RenormalizedDose(DmaxIndex:end);
            PastBuildupDepth = Depth(DmaxIndex:end);
            %find a region around the 50% point
            R50HiIndex = find(PastBuildupDose < 70);
            R50LowIndex = find(PastBuildupDose < 30);
            FitDepth = PastBuildupDepth(R50HiIndex(1):R50LowIndex(1));
            FitDose = PastBuildupDose(R50HiIndex(1):R50LowIndex(1));
            % find the 50% dose point
            R50 = interp1(FitDose,FitDepth,50,'linear');
            % calculate the shift required to make R50=Position
            Shift = Position-R50;
            % the depth position is moved to force R50 at position
            Depth = Depth + Shift;
        end
    else
        Shift = 0;
    end
    %% Interpolate the dose data
    
    % find the largest distance to use so a 0 point is included in the data
    DepthExtent = floor(max(Depth)/Spacing)*Spacing;
    
    % generate new distance data
    AdjustedDepth = (0:Spacing:DepthExtent)';
    
    % Interpolate the dose using the new distance data
    FinalDose = interp1(Depth,Dose,AdjustedDepth,SmoothingType);
    %% renormalize the interpolated data
    % find the location of the maximum dose
    DmaxIndex = find(FinalDose == max(FinalDose));
    max_range = DmaxIndex + 10;
    min_range = DmaxIndex - 10;
    if min_range <0
        min_range = 0;
    end
    Dmax_range = min_range:max_range;
    Dmax_depth = AdjustedDepth(Dmax_range);
    Dmax_dose = FinalDose(Dmax_range);
    smooth_dose = interp1(Dmax_depth,Dmax_dose,Dmax_depth,'pchip');
%     smooth_dose = smooth(FinalDose(Dmax_range),'rloess');
    MaxDose = max(smooth_dose);    
    RenormalizedDose = FinalDose/MaxDose*100;
else
    AdjustedDepth = Depth;
end
end