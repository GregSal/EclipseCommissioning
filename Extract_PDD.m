function PDD_Data = Extract_PDD(DICOM_data_path,GridSize,Offset,Dmax)
% PDD_Data = Extract_PDD(DICOM_data_path)
% PDD_Data = Extract_PDD(DICOM_data_path,GridSize)
% PDD_Data = Extract_PDD(DICOM_data_path,GridSize,Offset)
% PDD_Data = Extract_PDD(DICOM_data_path,GridSize,Offset,Dmax)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Extract_PDD Extracts a structured array of Depth Dose curves from a
%    DICOM dose file. If GridSize is given, it also centres, normalizes and
%    interpolates the data with a spacing of GridSize in cm. 
%
%   Input Arguments
%     DICOM_data_path  =  Directory where that DOCOM Data is located
%
%     GridSize        =   Optional, the size of the interpolated grid in cm
%                         If GridSize is used then the profile will be
%                         centered, normalized, linearly interpolated to
%                         the specified grid size 
%     Offset          =   Optional, a 2 element array [x, z] indicating the
%                         shift from the central axis for the depth dose
%                         curve.
%     Dmax            =   Optional, a 2D cell array of matching field sizes
%                         and Dmax values used to shift the PDD curve to
%                         line up the Dmax values from the extracted curve
%                         to the selected value in cm. The first column is
%                         the Field size and the second is the Dmax. This
%                         is done because the surface from Eclipse location
%                         is not accurate. The curve must be normalized if
%                         it is to be shifted.
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
narginchk(1, 4)

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

% Check for Shifting
if (nargin == 4)
    DO_Shift = true;
else
    DO_Shift = false;
end

%% Extract Calculated DICOM dose date

% Extract the cross-plane data passing through the isocentre
DoseData = ExtractDosePlane(DICOM_data_path, Z_Offset, 'xy');

%    Plane orientation can be one of 'xy', 'xz' or 'yz'.  x is Left to
%    right, y is ant to post and z is sup to inf  

%% Loop through all isodose files

% preallocate Dose Structure
number_of_files = size(DoseData,1);

% Initialize the profile indes
PDD_Index = 1;

% Define the structure
PDD_Data = struct('Path', {},'DoseFileName', {}, 'PlanName', {}, ...
                     'FieldName', {}, 'FieldSize', {}, 'Energy', {}, ...
                     'SSD', {}, 'plane', {}, 'distance', {}, ...
                     'direction', {}, 'depth', {}, 'dose', {});

% Set the correct dimensions
PDD_Data(number_of_files).Path = {};

% Flip the variable so that it is the same as DICOM_isodose_files
PDD_Data = PDD_Data';

for i=1:number_of_files;
    % Extract the PDD curve
    
    x = DoseData(i).x;
    y = DoseData(i).y;
    DoseSlice = DoseData(i).dose;
    
        % Select the Index from the y plane
        Indx = abs(x-X_Offset) <1;
        
        % do linear interpolation on the Dose plane to extract the curve
        Dose = interp2(x(Indx),y,DoseSlice(:,(Indx)), X_Offset,y,'linear');
        
        % Normalize the PDD
        if DO_Normalize
            if DO_Shift
                % find the field size
                % Note field size in Dmax must match the FieldSize in the
                % extracted profile exactly
                    FieldSizeString = DoseData(i).FieldSize;
                    disp(['Field Size = ' FieldSizeString]);
                %Select the correct Dmax
                DmaxIndex = strcmp(Dmax(:,1), FieldSizeString);
                [Depth, PDD] = Normalize_PDD(y,Dose,GridSize,Dmax{DmaxIndex,2});
            else
                [Depth, PDD] = Normalize_PDD(y,Dose,GridSize);
            end
        else
            Depth = y;
            PDD = Dose;
        end
% Put the data in the structured array
        PDD_Data(PDD_Index).Path = DoseData(i).Path;
        PDD_Data(PDD_Index).DoseFileName = DoseData(i).DoseFileName;
        PDD_Data(PDD_Index).PlanName = DoseData(i).PlanName;
        PDD_Data(PDD_Index).FieldName = DoseData(i).FieldName;
        PDD_Data(PDD_Index).FieldSize = DoseData(i).FieldSize;
        PDD_Data(PDD_Index).Energy = [num2str(DoseData(i).Energy) ' MeV'];
        PDD_Data(PDD_Index).SSD = DoseData(i).SSD;
        PDD_Data(PDD_Index).plane = Z_Offset;
        PDD_Data(PDD_Index).distance = X_Offset;
        PDD_Data(PDD_Index).direction = 'Beam';
        PDD_Data(PDD_Index).Type = 'PDD';
        PDD_Data(PDD_Index).depth = Depth;
        PDD_Data(PDD_Index).dose = PDD;
        try
            PDD_Data(PDD_Index).applicator = DoseData(i).applicator;
            PDD_Data(PDD_Index).insertsize = DoseData(i).insertsize;
        catch  %#ok<CTCH>
            % if no applicator do not create this applicator field
            % create a field size parameter
        end
           PDD_Index = PDD_Index+1;
 end
