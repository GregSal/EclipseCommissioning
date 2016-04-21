%% Extract dose plane data
% This function recursively scans a directory tree and produces a set of
% dose data in the specified plane from all of the DICOM dose files found
%%
function DoseData = ExtractDosePlane(DICOM_data_path, Position, Plane)
% function DoseData = ExtractDosePlane(DICOM_data_path, DICOM_data_path)
% DICOM_data_path  is the top directory to be searched for DICOM dose and
% plan files
%
% Position is the position in cm along the plane to be extracted
% Plane is Orientation of the dose plane to be extracted.  It can be one of
% 'xy', 'xz' or 'zy'.
% x is Left to right, y is ant to post and z is sup to inf
%% get a list of DICOM isodose data
%
DICOM_isodose_files=get_plan_list(DICOM_data_path);

%% Loop through all isodose files

% preallocate Dose Structure
number_of_files = size(DICOM_isodose_files,1);

%test for no files found
if number_of_files == 0
    DoseData = [];
    return
end

% Define the structure
DoseData = struct('Path', {},'DoseFileName', {}, 'PlanName', {}, ...
    'FieldName', {}, 'FieldSize', {}, 'Energy', {}, 'SSD', {}, ...
    'x', {}, 'y', {}, 'z', {}, 'dose', {});

% Set the correct dimensions
DoseData(number_of_files).Path = {};

% Flip the variable so that it is the same as DICOM_isodose_files
DoseData = DoseData';

for i=1:number_of_files;
    current_DICOM = DICOM_isodose_files(i);
    
    %% Extract DICOM from RT dose file
    % Dose is in units of cGy
    % Coordinates of dose data are centred around isocentre in cm
    % x is Left to right, y is ant to post and z is sup to inf
    % Note x is second dimension, y is first dimension
    [Dose, Coordinates] = ReadDose(current_DICOM);
    
    % rotate coordinates for easier use
    x = Coordinates.x';
    y = Coordinates.y';
    z = Coordinates.z';
    
    %% Select the correct orientation for the dose extraction
    % Rotate the dose matrix so that the desired extraction plane is the
    % 3rd dimension and select the coordinate indexes to use all planes
    % within 1 cm of the desired plane
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
    
    %% Interpolate to find Dose slice
    
    %% Put dose data into structure
    
    % Store the File info
    [Path, DoseFileName] = fileparts( current_DICOM.name);
    DoseData(i).Path = Path;
    DoseData(i).DoseFileName = DoseFileName;
    DoseData(i).PlanName = current_DICOM.plan_name;
    DoseData(i).FieldName = current_DICOM.FieldName;
    DoseData(i).FieldSize = current_DICOM.FieldSize;
    DoseData(i).Energy = current_DICOM.energy;
    DoseData(i).SSD = current_DICOM.SSD;
    DoseData(i).Plane = Plane;
    try
        DoseData(i).applicator = current_DICOM.applicator;
        DoseData(i).insertsize = current_DICOM.insertsize;
    catch  %#ok<CTCH>
        % if no applicator do not create this applicator field
        % create a field size parameter
    end
    
    % Store the dose data
    DoseData(i).x = D1;
    DoseData(i).y = D2;
    DoseData(i).z = D3;
    DoseData(i).dose = squeeze(DoseSlice);
end

