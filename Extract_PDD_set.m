function PDD_Data = Extract_PDD_set(DICOM_data_path,GridSize,Smoothing)
% PDD_Data = Extract_PDD(DICOM_data_path)
% PDD_Data = Extract_PDD(DICOM_data_path,GridSize)
% PDD_Data = Extract_PDD(DICOM_data_path,GridSize,Smoothing)
% PDD_Data = Extract_PDD(DICOM_data_path,GridSize,Offset,Smoothing,Shift,Position)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Extract_PDD Extracts a structured array of Depth Dose curves from a
%    DICOM dose file. If GridSize is given, it also centres, normalizes and
%    interpolates the data with a spacing of GridSize in cm.
%
%   Input Arguments
%     DICOM_data_path  =  Directory where that DOCOM Data is located
%
%     Offset          =   Optional, a 2 element array [x, z] indicating the
%                         shift from the central axis for the depth dose
%                         curve.
%     GridSize   =   An option to centre, normalize and interpolate
%                    the profile. If GridSize is used then the profile
%                    will be centered, normalized, linearly interpolated
%                    to the specified grid size
%
%     Smoothing  =   The desired smoothing method for profiles (optional)
%                    can be one of 'sgolay', 'pchip' or 'none'  If
%                    interpolation is requested, smoothing is required.
%                    This option has no effect for measured PDDs.

%     Smoothing       =   The desired smoothing method for profiles
%                         can be one of 'linear', 'sgolay', 'pchip' or
%                         'none'  If spacing is given, smoothing is
%                         required. Interpolation is required for
%                         smoothing.
%
%   Output Arguments
%     PDD_Data        =   A structured array consisting of the following fields:
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
%                                         (relative to the iosocentre in
%                                         the 'z' direction) to use for the
%                                         PDD curve
%                          distance     = The distance ('x') offset of
%                                         the PDD
%                          direction    = The vale 'Beam' indicating a PDD
%                                         curve
%                          depth        = The Depth of the profile to
%                                         extract from the dose matrix
%                          dose         = The relative dose for the profile
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%TODO Get off-centre PDDs
%% initialize the function

% Check the number of input arguments (Minimum 3 Maximum 4)
narginchk(1, 6)

% Check for Normalize
if (nargin > 1)
    DO_Normalize = true;
else
    DO_Normalize = false;
end

% Check for Offset
if (nargin > 2)
    X_Offset = Offset(1);
    Z_Offset = Offset(2);
else
    X_Offset = 0;
    Z_Offset = 0;
end

% Check for Smoothing
if (nargin > 3)
    DO_Smoothing = true;
else
    DO_Smoothing = false;
end

% Check for Shifting
if (nargin == 6)
    DO_Shift = true;
    %The last 3 argument are passed directly to Normalize_PDD
else
    DO_Shift = false;
end

%% Get the list of DICOM dose files and corresponding data
DICOM_data_path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\Eclipse Calculated Data\Golden Beam Model\High Accuracy Calculations for RDF\12MeV';
Beam_data=get_plan_list(DICOM_data_path);


%% Prepare PDD data structure

% Define the structure
PDD_Data = struct('Path', {},'DoseFileName', {}, 'PlanName', {}, ...
    'FieldName', {}, 'FieldSize', {}, 'Energy', {}, ...
    'SSD', {}, 'plane', {}, 'distance', {}, ...
    'direction', {}, 'depth', {}, 'dose', {});

% Set the correct dimensions
number_of_files = size(Beam_data,1);
PDD_Data(number_of_files).Path = {};

% Flip the variable so that it is the same as Dose_files
PDD_Data = PDD_Data';

PDD_Index = 1;
%% Loop through all isodose files
for i=1:number_of_files;
    % Extract the PDD curve
    Beam = Beam_data(i);
    Offset = mean(Beam.insertsize);
    DICOM_dose_file = Beam.dose_file;
    isocentre = Beam.isocentre;
    PDD_Data = Extract_PDD(DICOM_dose_file, isocentre, Offset);
%%%%%%%% call Normalize_PDD Here
    
    x = DoseData(i).x;
    y = DoseData(i).y;
    DoseSlice = DoseData(i).dose;
    
    % Select the Index from the y plane
    Indx = abs(x-X_Offset) <1;
    
    % do linear interpolation on the Dose plane to extract the curve
    Dose = interp2(x(Indx),y,DoseSlice(:,(Indx)), X_Offset,y,'linear');

    % Put the data in the structured array
    PDD_Data(PDD_Index).Path = DoseData(i).Path;
    PDD_Data(PDD_Index).DoseFileName = DoseData(i).DoseFileName;
    PDD_Data(PDD_Index).PlanName = DoseData(i).PlanName;
    PDD_Data(PDD_Index).FieldName = DoseData(i).FieldName;
    PDD_Data(PDD_Index).FieldSize = DoseData(i).FieldSize;
    PDD_Data(PDD_Index).Energy = [num2str(DoseData(i).Energy) ' MeV'];
    PDD_Data(PDD_Index).SSD = DoseData(i).SSD;
    PDD_Data(PDD_Index).plane = Z_Offset;
    PDD_Data(PDD_Index).direction = 'Beam';
    PDD_Data(PDD_Index).Type = 'PDD';
    PDD_Data(PDD_Index).distance = X_Offset;
    PDD_Data(PDD_Index).depth = y;
    PDD_Data(PDD_Index).dose = Dose;
    try
        PDD_Data(PDD_Index).applicator = DoseData(i).applicator;
        PDD_Data(PDD_Index).insertsize = DoseData(i).insertsize;
    catch  %#ok<CTCH>
        % if no applicator do not create this applicator field
        % create a field size parameter
    end
    PDD_Index = PDD_Index+1;
end
