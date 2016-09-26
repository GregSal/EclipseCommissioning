function PDD_Data = Extract_PDD(DICOM_dose_file, isocentre, Offset)
% PDD_Data = Extract_PDD(DICOM_dose_file)
% PDD_Data = Extract_PDD(DICOM_dose_file,Offset)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Extract_PDD Extracts a structure containing the Depth Dose curve from a
%    DICOM dose file. If GridSize is given, it also centres, normalizes and
%    interpolates the data with a spacing of GridSize in cm.
%
%   Input Arguments
%     DICOM_dose_file  =  Path and filename for the DOCOM Dose Data
%
%     isocentre        =   A 3 element array [x, y, z] indicating the DICOM
%                          coordinates of the beam isocentre.
%
%     Offset           =   Optional, a 2 element array [x, z] indicating the
%                          shift from the central axis for the depth dose
%                          curve.
%
%   Output Arguments
%     PDD_Data         =   A structured array consisting of the following fields:
%                          plane        = The plane of the dose matrix
%                                         (relative to the iosocentre in
%                                         the 'z' direction) to use for the
%                                         PDD curve
%                          distance     = The distance ('x') offset of
%                                         the PDD
%                          depth        = The Depth of the profile to
%                                         extract from the dose matrix
%                          dose         = The relative dose for the profile
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check the number of input arguments (Minimum 1 Maximum 2)
narginchk(2, 3)

% Check for Offset
if (nargin > 2)
    X_Offset = Offset(1);
    Z_Offset = Offset(2);
else
    X_Offset = 0;
    Z_Offset = 0;
end

%% Extract Calculated DICOM dose data

% Extract the cross-plane data passing through the isocentre
DoseData = ExtractDosePlane(DICOM_dose_file, isocentre, Z_Offset, 'xy');

%    Plane orientation can be one of 'xy', 'xz' or 'yz'.  x is Left to
%    right, y is ant to post and z is sup to inf

    % Extract the PDD curve
    
    x = DoseData.x;
    y = DoseData.y;
    DoseSlice = DoseData.dose;
    
    % Select the Index from the y plane
    Indx = abs(x-X_Offset) <1;
    
    % do linear interpolation on the Dose plane to extract the curve
    Dose = interp2(x(Indx),y,DoseSlice(:,(Indx)), X_Offset,y,'linear');

    % Put the data in the structured array
    PDD_Data.plane = Z_Offset;
    PDD_Data.distance = X_Offset;
    PDD_Data.depth = y;
    PDD_Data.dose = Dose;
end
