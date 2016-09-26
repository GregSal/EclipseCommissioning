%% ReadDose
% This function reads in dose data from a given file

%%
function [Dose_data, coordinates] = ReadDose(DoseFile, isocentre)
% [Dose_data, coordinates] = ReadDose(DoseFile, isocentre)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    ReadDose Extracts the dose data from the specified DICOM file,
%    converts it to floating poing values in cGy and returns this dose data
%    along with coordinates in cm, with the isocentre at the origin.
%
%   Input Arguments
%     DICOM_dose_file    =  Path and filename for the DOCOM Dose Data
%
%     isocentre          =  A 3 element array [x, y, z] indicating the DICOM
%                           coordinates of the beam isocentre.
%
%   Output Arguments
%     Dose_data        =   A 3D array of dose values in cGy.
%
%     coordinates      =   A structured array consisting of the following
%                          fields: 
%                          x     = The x coordinates in cm.
%                          y     = The x coordinates in cm.
%                          z     = The x coordinates in cm.
%                          The origin is located at the field isocentre.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% load the dose info

% Extract DICOM metadata from RT dose file
doseinfo = dicominfo(DoseFile);
  
%% Extract DICOM dose data from the dose file
% Extract DICOM image data from RT dose file
dose = dicomread(DoseFile);

% Initialize dose sum
dose = squeeze(dose); % remove the 4D singleton dimension

% Convert image data to actual dose values in cGy
Dose_data = double(dose)*doseinfo.DoseGridScaling*100;

%% Get coordinate information from the dose info
% Extract dose slice pixel spacing data
pixspacing = doseinfo.PixelSpacing;
% get the DICOM origin coordinates
origin = doseinfo.ImagePositionPatient;
%Get the list of slices in the DICOM coordinates
slices = doseinfo.GridFrameOffsetVector;

%% Create x,y,z -coordinates of dose data centred around isocentre
% x is Left to right, y is ant to post and z is sup to inf
% Note x is second dimension, y is first dimension
% Units are in cm
dx = size(dose,2); % Get number of dose volume pixels in x-direction
dy = size(dose,1); % Get number of dose volume pixels in y-direction

coordinates.x = ((1:dx)*pixspacing(1)+origin(1)-isocentre(1))/10;
coordinates.y = ((1:dy)*pixspacing(2)+origin(2)-isocentre(2))/10;
coordinates.z = (slices'+origin(3)-isocentre(3))/10;
% FIXME  Z direction may be reversed

