function ProfileData = Extract_Profile(DICOM_data_path, isocentre, Offset, Directions, Depths)
% ProfileData = Extract_Profile(DICOM_data_path, Direction, Depths)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Extract_Profile Extracts a structured array of profiles at a given
%    plane and series of depths from a DICOM dose file If GridSize is
%    given, it also centres, normalizes and interpolates the data with a
%    spacing of GridSize in cm.
%
%   Input Arguments
%     DICOM_data_path    =  Directory where that DOCOM Data is located
%
%
%     isocentre          =  A 3 element array [x, y, z] indicating the
%                           DICOM coordinates of the beam isocentre.
%
%     Offset             =  A 2 element array [x, z] indicating the
%                           shift from the central axis for the depth dose
%                           curve.
%
%     Direction          =  The orientation of the profile.  Can be
%                           'Crossline' or 'Inline'.
%
%     Depths             =  An array of the depths of the profiles to be
%                           extracted from the dose matrix
%
%   Output Arguments
%     ProfileData     =   A structured array sonsisting of the following fiields:
%                          plane        = The plane of the dose matrix
%                                         (relative to the iosocentre) to
%                                         use for the profiles
%                          direction    = The orientation of the profile.
%                                         Can be 'CrossPlane' or 'InPlane'.
%                          depth        = The Depth of the profile to
%                                         extract from the dose matrix
%                          distance     = The distance (x) coordinates of
%                                         the profile
%                          dose         = The relative dose for the profile
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialize the function

% Check the number of input arguments (Minimum 5 Maximum 5)
narginchk(5, 5)
%TODO Expand to extract a list of planes
Direction = Directions{1};
% check direction
if strcmpi(Direction,'Crossline')
    CrossPlane = true;
elseif strcmpi(Direction,'Inline')
    CrossPlane = false;
else
    error('Extract_Profile:IncorrectDirection', ['The value: ' ...
        Direction ' is an invalid direction.  Valid options are ' ...
        char(180) 'CrossPlane'  char(180) 'and ' ...
        char(180) 'InPlane' char(180)]);
end
%% Extract Calculated DICOM dose date

% Extract the cross-plane data
if CrossPlane
    Position = Offset(2);
    DoseData = ExtractDosePlane(DICOM_data_path, isocentre, Position, 'xy');
else
    Position = Offset(1);
    DoseData = ExtractDosePlane(DICOM_data_path, isocentre, Position, 'zy');
end
%    Plane orientation can be one of 'xy', 'zy' or 'yz'.  x is Left to
%    right, y is ant to post and z is sup to inf

%% Prepare the profile data structure
Number_of_depths = length(Depths);

% Define the structure
ProfileData = struct('plane', {}, 'direction', {}, 'depth', {}, ...
    'distance', {}, 'dose', {});

% Set the correct dimensions
ProfileData(Number_of_depths).Path = {};

% Flip the variable so that it is the same as DICOM_isodose_files
ProfileData = ProfileData';

x = DoseData.x;
y = DoseData.y;
DoseSlice = DoseData.dose;
%% Extract a single profile for each depth
ProfileIndex = 1;
for j=1:Number_of_depths;
    % skip out of range depths
    if Depths(j) < min(y) || Depths(j) > max(y)
        continue % Skip this depth
    end
    % Select the Index from the y plane
    Indx = abs(y-Depths(j)) <1;
    
    % do linear interpolation on the Dose plane to extract the profile
    Dose = interp2(x,y(Indx),DoseSlice(Indx,:), x,Depths(j),'linear');
    
    % Put the data in the structured array
    ProfileData(ProfileIndex).plane = Position;
    ProfileData(ProfileIndex).direction = Direction;
    ProfileData(ProfileIndex).depth = Depths(j);
    ProfileData(ProfileIndex).distance = x;
    ProfileData(ProfileIndex).dose = Dose;
    ProfileIndex = ProfileIndex+1;
end
%Remove empty rows
ProfileData = ProfileData(1:ProfileIndex-1);
