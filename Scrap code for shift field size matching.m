%     GridSize        =   Optional, the size of the interpolated grid in cm
%                         If GridSize is used then the profile will be
%                         centered, normalized, linearly interpolated to
%                         the specified grid size
%     Smoothing       =   Optional, The desired smoothing method for
%                         profiles can be one of 'linear', 'sgolay' or
%                         'pchip'.
%     Shift_location  =   The desired positional correction. values can be
%                         'Dmax' 'R50' or 'None'. If 'None' or absent, no
%                         shift will be done.  If present the position
%                         value is required.  The position value will be
%                         taken as either 'Dmax' or 'R50' and the PDD will
%                         be shifeted to force that positioning.
%     Position        =   Optional, a 2D cell array of matching field sizes
%                         and expected PDD distance values of either
%                         'Dmax' or 'R50' in cm.  It is used to line up the
%                         extracted curve to the selected point.  If shift
%                         is 'Dmax', the PDD  will be shifted so that the
%                         Point of Maximum dose is located at position.  If
%                         shift is 'R50', the PDD will be shifted so that
%                         the 50% point lies at that position.
%                         Interpolation must be done if the curve is to be
%                         shifted.
% TODO change Extract_PDD to search for Energy and Field Size
Smoothing = 'linear';
Shift_location = 'R50';
Position = {'6 x 6'    5.0; '10 x 10'  5.0; '15 x 15' 5.0; ...
            '20 x 20'  5.0; '25 x 25'  5.0};

if DO_Normalize
        if DO_Smoothing
            if DO_Shift
                % TODO change Extract_PDD to search for Energy and Field Size
                % find the field size
                % Note field size in Dmax must match the FieldSize in the
                % extracted profile exactly
                FieldSizeString = DoseData(i).FieldSize;
                %Select the correct position
                PositionIndex = strcmp(Position(:,1), FieldSizeString);
                [Depth, PDD, Shift] = Normalize_PDD(y,Dose,GridSize,Smoothing,Shift_location,Position{PositionIndex,2});
                disp(['Field Size = ' FieldSizeString ' Shift = ' num2str(Shift)]);
            else
                [Depth, PDD, ~] = Normalize_PDD(y,Dose,GridSize,Smoothing);
            end
        else
            [Depth, PDD, ~] = Normalize_PDD(y,Dose,GridSize);
        end
    else
