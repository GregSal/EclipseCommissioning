function ProfileData = Extract_Profile(DICOM_data_path,Position, Direction, Depths,GridSize,Center,Smoothing)
% ProfileData = Extract_Profile(DICOM_data_path, Direction, Depths)
% ProfileData = Extract_Profile(DICOM_data_path, Direction,Depths,GridSize,Center,Smoothing)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Extract_Profile Extracts a structured array of profiles at a given
%    plane and series of depths from a DICOM dose file If GridSize is
%    given, it also centres, normalizes and interpolates the data with a
%    spacing of GridSize in cm. 
%
%   Input Arguments
%     DICOM_data_path  =  Directory where that DOCOM Data is located
%
%     Position         =  The distance in cm of the desired plane from dose
%                         matrix (relative to the iosocentre) to use for
%                         the profiles.   
%     Direction        =  The orientation of the profile.  Can be
%                         'Crossline' or 'Inline'.   
%     Depths           =  An array of the depths of the profiles to be
%                         extracted from the dose matrix
%     GridSize         =  An option to centre, normalize and interpolate
%                         the profile. If GridSize is used then the profile
%                         will be centered, normalized, linearly
%                         interpolated to the specified grid size
%     Center          =   Indicates if profiles should be centered. The
%                         options are 'Center' or Asymmetric' if absent no
%                         centering is done. It is required if
%                         interpolation or smoothing is desired. 
%     Smoothing       =   The desired smoothing method for profiles can be
%                         one of 'sgolay', 'pchip' or 'none'  If
%                         interpolation is requested, smoothing is
%                         required. 
%
%
%   Output Arguments
%     ProfileData     =   A structured array sonsisting of the following fiields:
%                          Path         = The directory path that the file
%                                         was in  
%                          DoseFileName = File name for the DICOM dose file
%                          PlanName     = The plan name for the dicom dose
%                                         matrix
%                          FieldName    = The name of the first field in
%                                         the plan that generated the dose  
%                                         matrix
%                          FieldSize    = A string containing the field
%                                         size of the first field in the
%                                         plan that generated the dose
%                                         matrix 
%                          Energy       = A string containing the energy of
%                                         the first field in the plan that
%                                         generated the dose matrix 
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

%TODO Expand to extract a list of planes
%% initialize the function

% Check the number of input arguments (Minimum 4 Maximum 7)
narginchk(4, 7)

% Check for Interpolation
if (nargin == 7)
    DO_Interpolation = true;
elseif (nargin == 4) % Only 4 or 7 arguments are valid
    DO_Interpolation = false;
else
    error('Extract_Profile:InvalidParameters', 'Valid # arguments is 4 or 7');
end

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
    DoseData = ExtractDosePlane(DICOM_data_path, Position, 'xy');
else
    DoseData = ExtractDosePlane(DICOM_data_path, Position, 'zy');
end
%    Plane orientation can be one of 'xy', 'zy' or 'yz'.  x is Left to
%    right, y is ant to post and z is sup to inf  

%% Loop through all isodose files

% preallocate Dose Structure
number_of_files = size(DoseData,1);
Number_of_depths = length(Depths);

Number_of_Profiles = number_of_files*Number_of_depths;

% Initialize the profile indes
ProfileIndex = 1;

% Define the structure
ProfileData = struct('Path', {},'DoseFileName', {}, 'PlanName', {}, ...
                     'FieldName', {}, 'FieldSize', {}, 'Energy', {}, ...
                     'plane', {}, 'direction', {}, 'depth', {}, ...
                     'distance', {}, 'dose', {});

% Set the correct dimensions
ProfileData(Number_of_Profiles).Path = {};

% Flip the variable so that it is the same as DICOM_isodose_files
ProfileData = ProfileData';

for i=1:number_of_files;
    % Extract a single profile
    
    x = DoseData(i).x;
    y = DoseData(i).y;
    DoseSlice = DoseData(i).dose;
    
    for j=1:Number_of_depths;
        % skip out of range depths
        if Depths(j) < min(y) || Depths(j) > max(y)
            continue % Skip this depth
        end
        % Select the Index from the y plane
        Indx = abs(y-Depths(j)) <1;
        
        % do linear interpolation on the Dose plane to extract the profile
        Dose = interp2(x,y(Indx),DoseSlice(Indx,:), x,Depths(j),'linear');
        
        % Centre the data
        if DO_Interpolation
            [Distance, ProfileDose] = Centre_Profile(x,Dose,Center,GridSize,Smoothing);
        else
            Distance = x;
            ProfileDose = Dose;
        end
        % Put the data in the structured array
        ProfileData(ProfileIndex).Path = DoseData(i).Path;
        ProfileData(ProfileIndex).DoseFileName = DoseData(i).DoseFileName;
        ProfileData(ProfileIndex).PlanName = DoseData(i).PlanName;
        ProfileData(ProfileIndex).FieldName = DoseData(i).FieldName;
        ProfileData(ProfileIndex).FieldSize = DoseData(i).FieldSize;
        ProfileData(ProfileIndex).Energy = [num2str(DoseData(i).Energy) ' MeV'];
        ProfileData(ProfileIndex).SSD = DoseData(i).SSD;
        ProfileData(ProfileIndex).plane = Position;
        ProfileData(ProfileIndex).direction = Direction;
        ProfileData(ProfileIndex).Type = 'Profile';
        ProfileData(ProfileIndex).depth = Depths(j);
        ProfileData(ProfileIndex).distance = Distance;
        ProfileData(ProfileIndex).dose = ProfileDose;
        try
            ProfileData(ProfileIndex).applicator = DoseData(i).applicator;
            ProfileData(ProfileIndex).insertsize = DoseData(i).insertsize;
        catch  %#ok<CTCH>
            % if no applicator do not create this applicator field
            % create a field size parameter
        end
        ProfileIndex = ProfileIndex+1;
    end
end
%Remove empty rows
ProfileData = ProfileData(1:ProfileIndex-1);
