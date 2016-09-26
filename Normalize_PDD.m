function [AdjustedDepth, FinalDose, PDD_analysis] = Normalize_PDD(Depth,Dose,Spacing,Smoothing,Shift_location,Position)
% [AdjustedDepth, RenormalizedDose, Shift] = Normalize_PDD(Depth,Dose,Spacing,Smoothing,Shift_location,Position)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Normalize_PDD returns the depth dose curve with depth points Spacing
%    intervals apart, renormalized to d_max, smoothed using Smoothing
%    method and shifted depth-wise to align Shift_location with Position.
%    It also includes analysis data on the PDD Curve. 
%
%   Input Arguments
%     Depth            =   The distance (x) coordinates of the profile
%
%     Dose             =   The relative dose for the profile
%
%     Spacing          =   Optional, The desired distance spacing for the
%                          output profile.  if absent no interpolation is
%                          done. 
%     Smoothing        =   The desired smoothing method for profiles
%                          can be one of 'linear', 'sgolay', 'pchip' or
%                          'none'  If spacing is given, smoothing is
%                          required. Interpolation is required for
%                          smoothing.
%     Shift_location   =   Optional, The desired positional correction.
%                          values can be 'Dmax' 'R50' or 'None'. If 'None'
%                          or absent, no shift will be done.  If present
%                          the position value is required.  The position
%                          value will be taken as either 'Dmax' or 'R50'
%                          and the PDD will be shifeted to force that
%                          positioning. 
%     Position         =   The expected PDD distance setting of either
%                          'Dmax' or 'R50'.  If shift is 'Dmax', the PDD
%                          will be shifted so that the Point of Maximum
%                          dose is located at position.  If shift is 'R50',
%                          the PDD will be shifted so that the 50% point
%                          lies at that position. Interpolation must be
%                          done if the curve is to be shifted.
%
%   Output Arguments
%     AdjustedDepth    =  The PDD distance (x) coordinates shifted (if
%                         shift location and Position provided) and
%                         respaced (if spacing provided).
%     FinalDose        =  The PDD dose, shiftes smoothed and re-normalized
%                         to Dmax. 
%     PDD_analysis     =  A structured array consisting of the following
%                         fields: 
%                              R100          =  The location of dmax before
%                                               the depth shift.
%                              R50           =  The location of the 50%
%                                               dose before the depth
%                                               shift. 
%                              depth_shift   =  The amount (in cm) the PDD
%                                               depth was shifted. 
%                              dmax_Dose     =  The Dose at dmax before
%                                               normalizing
%                              Surface_Dose  =  The percent dose at the
%                                               surface after normalizing
%                                               and depth shifts. 
%                              Build_up_95   =  The location of the 95%
%                                               dose in the build-up
%                                               region after normalizing
%                                               and depth shifts. 
%                              R95           =  The location of the 95%
%                                               dose beyond dmax after
%                                               normalizing and depth
%                                               shifts.  
%                              R90           =  The location of the 90%
%                                               dose beyond dmax after
%                                               normalizing and depth
%                                               shifts.  
%                              R80           =  The location of the 80%
%                                               dose beyond dmax after
%                                               normalizing and depth shifts. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check in input arguments

% Check the number of input arguments (Minimum 2 Maximum 6)
narginchk(2, 6)

% Check for interpolation
if (nargin == 2)
    DoInterpolation = false;
    DoShift = false;
else
    if (nargin == 3)
        SmoothingType = 'linear'; % Use linear interpolation as default
        DoInterpolation = true;
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
        end
    end
end

%% Obtain dmax Dose, R100 and max dose values
% find d_max by interpolating to half mm spacing around max dose
MaxDose = max(Dose);
RenormalizedDose = Dose/MaxDose*100;
DoseIndex = RenormalizedDose > 97;
DoseRegion = Dose(DoseIndex);
DoseRange = Depth(DoseIndex);
MinDepth = min(DoseRange);
MaxDepth = max(DoseRange);
InterpDepth = MinDepth:0.05:MaxDepth;
InterpDose = interp1(DoseRange,DoseRegion,InterpDepth,'pchip');
dmax_Dose = max(InterpDose);
PDD_analysis.dmax_Dose = dmax_Dose;
PDD_analysis.R100 = InterpDepth(InterpDose==dmax_Dose);
%Redo-normalization with interpolated Dmax
RenormalizedDose = Dose/dmax_Dose*100;

%% Find R50
%select data past buildup region
BuildDownIndex = Depth > PDD_analysis.R100;
DoseIndexLow = RenormalizedDose > 30;
DoseIndexHigh = RenormalizedDose < 70;
DoseIndex = BuildDownIndex & DoseIndexLow & DoseIndexHigh;
DoseRegion = RenormalizedDose(DoseIndex);
DoseRange = Depth(DoseIndex);
PDD_analysis.R50 = interp1(DoseRegion,DoseRange,50,'linear');

%% Apply any Depth shifts
if (DoShift)
    if (ShiftDmax)
        % shift the Depths to line up Dmax
        PDD_analysis.depth_shift =  Position - PDD_analysis.R100;
    else
        % Shift to R50
        PDD_analysis.depth_shift =  Position - PDD_analysis.R50;
    end
else
    PDD_analysis.depth_shift = 0;
end
ShiftedDepth = Depth + PDD_analysis.depth_shift;

%% Do the interpolation if required and renormalize the dose to d_max
if (DoInterpolation)
    % find the largest distance to use so a 0 point is included in the data
    DepthExtent = floor(max(ShiftedDepth)/Spacing)*Spacing;
    
    % generate new distance data
    AdjustedDepth = (0:Spacing:DepthExtent)';
    
    % Interpolate the dose using the new distance data
    FinalDose = interp1(ShiftedDepth,RenormalizedDose,AdjustedDepth,SmoothingType);
else
    FinalDose = RenormalizedDose;
    AdjustedDepth = ShiftedDepth;
end
%% Find Build_up_95
BuildUpIndex = AdjustedDepth < PDD_analysis.R100;
DoseIndexLow = FinalDose > 85;
DoseIndexHigh = FinalDose < 100;
DoseIndex = BuildUpIndex & DoseIndexLow & DoseIndexHigh;
DoseRegion = FinalDose(DoseIndex);
DoseRange = AdjustedDepth(DoseIndex);
PDD_analysis.Build_up_95 = interp1(DoseRegion,DoseRange,95,'linear');
%% Find R95
BuildDownIndex = AdjustedDepth > PDD_analysis.R100;
DoseIndexLow = FinalDose > 85;
DoseIndexHigh = FinalDose < 100;
DoseIndex = BuildDownIndex & DoseIndexLow & DoseIndexHigh;
DoseRegion = FinalDose(DoseIndex);
DoseRange = AdjustedDepth(DoseIndex);
PDD_analysis.R95 = interp1(DoseRegion,DoseRange,95,'linear');
%% Find  R90
BuildDownIndex = AdjustedDepth > PDD_analysis.R100;
DoseIndexLow = FinalDose > 80;
DoseIndexHigh = FinalDose < 100;
DoseIndex = BuildDownIndex & DoseIndexLow & DoseIndexHigh;
DoseRegion = FinalDose(DoseIndex);
DoseRange = AdjustedDepth(DoseIndex);
PDD_analysis.R90 = interp1(DoseRegion,DoseRange,90,'linear');
%% Find  R80
BuildDownIndex = AdjustedDepth > PDD_analysis.R100;
DoseIndexLow = FinalDose > 60;
DoseIndexHigh = FinalDose < 90;
DoseIndex = BuildDownIndex & DoseIndexLow & DoseIndexHigh;
DoseRegion = FinalDose(DoseIndex);
DoseRange = AdjustedDepth(DoseIndex);
PDD_analysis.R80 = interp1(DoseRegion,DoseRange,80,'linear');

end