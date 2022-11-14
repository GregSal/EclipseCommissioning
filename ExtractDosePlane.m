%% Extract dose plane data
% This extracts the dose data in the specified plane from the DICOM dose
% file specified
%%
function DoseData = ExtractDosePlane(DICOM_dose_file, Isocentre, Position, Plane)
% DoseData = ExtractDosePlane(DICOM_dose_file, Isocentre, Position, Plane)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    ExtractDosePlane Extracts the dose data in the specified plane from
%    the DICOM dose file specified.
%
%   Input Arguments
%     DICOM_dose_file    =  Path and filename for the DOCOM Dose Data
%
%     isocentre          =  A 3 element array [x, y, z] indicating the DICOM
%                           coordinates of the beam isocentre.
%
%     Position           =  The position in cm along the plane to be
%                           extracted 
%     Plane             =   The orientation of the dose plane to be
%                           extracted. It can be one of 'xy', 'xz' or 'zy'.
%                           x is Left to right, y is ant to post and z is
%                           sup to inf.
%
%   Output Arguments
%     DoseData         =   A structured array consisting of the following fields:
%                          x     = The x coordinates for the dose plane.
%                          y     = The y coordinates for the dose plane.
%                          z     = The z coordinates for the dose plane.
%                          dose  = The relative dose for the dose plane.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Extract DICOM from RT dose file
% Dose is in units of cGy
% Coordinates of dose data are centred around isocentre in cm
% x is Left to right, y is ant to post and z is sup to inf
% Note x is second dimension, y is first dimension
[Dose, Coordinates] = ReadDose(DICOM_dose_file, Isocentre);

% rotate coordinates for easier use
x = Coordinates.x';
y = Coordinates.y';
z = Coordinates.z';

%% Select the correct orientation for the dose extraction
% Rotate the dose matrix so that the desired extraction plane is the
% 3rd dimension and select the coordinate indexes to use all planes
% within 1 cm of the desired plane
% Interpolate to find Dose slice
% TODO Tested only xy plane test others  the x & y coordinates may not
% be correct
if (strcmp(Plane,'xy'))
    % Select the z plane, no rotation nessesary
    % Select the Index from the z plane
    Indx = abs(z-Position) <1;
    % Set the coordinates for the dose plane
    D1 = x;D2=y;D3=Position;
    % do linear interpolation on the z plane to extract the dose plane
    DoseSlice = interp3(x,y,z(Indx),Dose(:,:,Indx), ...
        x,y,Position,'linear');
elseif (strcmp(Plane,'zy'))
    % Swap the x and z planes
    % Note: first dimension is Y even though interp and plot refer to
    % X first and then Y
    Dose = permute(Dose,[1 3 2]);
    % Select the Index from the x plane
    Indx = abs(x-Position) <1;
    % Set the coordinates for the dose plane
    D1 = z;D2=y;D3=Position;
    % do linear interpolation on the z plane to extract the dose plane
    DoseSlice = interp3(z,y,x(Indx),Dose(:,:,Indx), ...
        z,y,Position,'linear');
elseif (strcmp(Plane,'xz'))
    % Select the y plane, rotate two steps
    Dose = shiftdim(Dose,2);
    % Select the Index from the y plane
    Indx = abs(y-Position) <1;
    % Set the coordinates for the dose plane
    D1 = z;D2=x;D3=Position;
    % do linear interpolation on the y plane to extract the dose plane
    DoseSlice = interp3(z,x,y(Indx),Dose(:,:,Indx), ...
        z,x,Position,'linear');
else
    % no appropriate plane selected
    DoseData = [];
    return
end

% Store the dose data
DoseData.x = D1;
DoseData.y = D2;
DoseData.z = D3;
DoseData.dose = squeeze(DoseSlice);
end

