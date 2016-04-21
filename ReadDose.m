%% ReadDose
% This function reads in dose data from a given file

%%
function [Dose_data, coordinates] = ReadDose(DoseFile)
%function [doseinfo,Dose_data] = ReadDose(FileName)
% This function reads in dose data from a given file

%% load the dose info

% Extract DICOM metadata from RT dose file
doseinfo = dicominfo(DoseFile.name);
  
%% Extract DICOM dose data from the dose file
% Extract DICOM image data from RT dose file
dose = dicomread(DoseFile.name);

% Initialize dose sum
dose = squeeze(dose); % remove the 4D singleton dimension

% Convert image data to actual dose values in cGy
Dose_data = double(dose)*doseinfo.DoseGridScaling*100;

% TODO make normalization an option
% renormalize dose to dose for one fraction
%Dose_data = Dose_data/DoseFile.Fractions;

% renormalize dose to MU of 100
%Dose_data = Dose_data/DoseFile.MU*100;

% Select only those voxels withing the field (i.e. dose > 50 cGy)
%     FieldPixels = Dose_data>50;

% TODO
% Rotate Coordinate system so that depth is vertical
% Use Interpolate to generate new plotting data

%% Get coordinate information from plan and dose info
% Get coordinates of isocentre in DICOM frame of reference
isocentre = DoseFile.isocentre;
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

