function Calculated_Data_Table = Import_Calculated_Electron_Data(DICOM_data_path, Depths, SSD_string, Directions, import_parameters)
% Calculated_Data_Table = Import_Calculated_Electron_Data(data_path, depths, SSD_string, directions, import_parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Import_Calculated_Electron_Data creates a data table of PDDs and
%    Profiles from the DICOM dose files located in data_path and it's
%    subdirectories.
%
%   Input Arguments
%     DICOM_data_path       =  Directory where the DICOM Dose data files
%                              are located
%     depths                =  A list of the desired profile depths
%     directions            =  A list of the desired profile orientations
%                              Currently only the first orientation in the
%                              list is used.
%     Algorithm             =  A string contining the name of the
%                              calculation algorithm used
%     SSD                   =  The SSD of the calculations
%
%     import_parameters  =  parameters used for processing the imported
%                           data. It contains two fields:
%         PDD:          Contains the parameters for the PDD curves.
%
%         profile:      Contains the parameters for the profile curves.
%
%         Both fields contain multiple subfields:
%
%            Both:
%              GridSize    =     The desired spacing between depth or
%                                distance values obtained by interpolating
%                                the data that is imported.
%              Smoothing   =     The desired smoothing method for the
%                                imported data.  Can be one of 'linear',
%                                'sgolay', 'pchip' or 'none'.
%
%            PDD Only:
%              Shift_location = The desired positional correction.  Values
%                               can be 'Dmax' 'R50' or 'None'. If 'Dmax' or
%                               'R50' the PDD depth will be shifted to
%                               force 'Dmax' or 'R50' location to the
%                               specified position.
%
%            profile Only:
%              Center       =   Indicates if profile should be centered.
%                               The options are 'Center' or Asymmetric'.
%
%   Output Arguments
%     Calculated_Data_Table =  A table containing all calculated PDD and
%                              Profile data found in the given directory
%                              and it's Subdirectories along with relevant
%                              parameters:
%   Table Variables:
%          FilePath     = The directory path that the dose file is in.
%          DoseFile     = File name for the DICOM dose file
%          PlanFile     = File name for the DICOM plan file
%          PlanName     = The plan name for the dicom dose matrix
%          FieldName    = The name of the first field in the plan that
%                         generated the dose matrix
%          Energy       = A string containing the energy in the form:
%                               {energy} MeV
%          SSD          = The SSD of the field. Left blank because SSD
%                         cannot be extracted for electron beams
%          GantryAngle  = The gantry angle of the field.
%          Applicator   = The applicator used by the field.
%          FieldSize    = A string containing the field size in the form:
%                              {max dimension} x {min dimension}
%                           or {diameter} cm circle
%          EquivSquare  = The equivlent square field size as defined by the
%                         insert shape.
%          InsertName   = The ID for the applicator inserd used.
%          InsertShape  = An n x 2 matrix of points defining the insert
%                         shape.
%          Offset       = The X and Z shifts relative to the iosocentre at
%                         which the PDD was taken
%          Direction    = The string 'Beam', 'Crossline' or 'Inline' which
%                         indicates the direction of the dose data curve.
%          Type         = The string 'PDD' or 'Profile'
%          MUs          = The MUs used for the dose calculation.
%          dmax_Dose    = (PDDs) The Dose at dmax before normalizing
%          DepthShift   = (PDDs) The amount (in cm) the PDD depth was
%                          shifted.
%          SurfaceDose  = (PDDs) The percent dose at the surface after
%                          normalizing and depth shifts.
%          Build_up_95  = (PDDs) The location of the 95% dose in the
%                          build-up region after normalizing and depth
%                          shifts.
%          R100         = (PDDs) The location of dmax after normalizing and
%                          depth shifts. 
%          R95          = (PDDs) The location of the 95% dose beyond dmax
%                          after normalizing and depth shifts.
%          R90          = (PDDs) The location of the 90% dose beyond dmax
%                          after normalizing and depth shifts.
%          R80          = (PDDs) The location of the 80% dose beyond dmax
%                          after normalizing and depth shifts.
%          R50          = (PDDs) The location of the 50% dose after
%                          normalizing and depth shifts. 
%          CAX_Dose     = (Profiles) The calculated dose at the central
%                          axis after any centering, interpoaltion and
%                          smoothing.
%          DistanceShift= (Profiles) The amount (in cm) the profile
%                          distance was shifted to centre it.
%          FieldWidth   = (Profiles) The profile width in cm from 50% to
%                          50% dose points.
%          Penumbra     = (Profiles) The average penumbra with in cm
%                          between the 20% and 80% dose points.
%          Flatness     = (Profiles) The variation in % of the dose in the
%                          region that is 80% of the field size.
%          Symmetry     = (Profiles) The maximum dose difference in percent
%                          between matching points on opposite sides of the
%                          profile over the region that is 80% of the field
%                          size.
%          Depth        =  The Depth values for the PDD curve, or the depth
%                          of the profile.
%          Distance     =  The Profile distance (x) coordinates or the
%                          distance of the PDD from the central axis.
%          Dose         =  The relative dose values for the PDD or profile
%                          curve.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Get the list of DICOM dose files and corresponding data
Beam_data=get_plan_list(DICOM_data_path);

%% Prepare PDD data structure
% Define the structure
Dose_Data = struct('FilePath', {},'DoseFile', {},'PlanFile', {}, ...
    'PlanName', {}, 'FieldName', {}, 'Energy', {}, ...
    'SSD', {}, 'GantryAngle', {}, 'Applicator', {}, ...
    'FieldSize', {}, 'EquivSquare', [], ...
    'InsertName', {}, 'InsertShape', {}, ...
    'Offset', {}, 'Direction', {}, 'Type', {}, ...
    'MUs', {}, 'dmax_Dose', {}, 'CAX_Dose', {}, ...
    'DistanceShift', {}, 'DepthShift', {}, ...
    'R100', {}, 'R50', {}, ...
    'SurfaceDose', {}, 'Buildup_95', {}, ...
    'R95', {}, 'R90', {}, 'R80', {}, ...
    'FieldWidth', {}, 'Penumbra', {}, ...
    'Flatness', {}, 'Symmetry', {}, ...
    'Depth', {}, 'Distance', {}, 'Dose', {});
% Set the correct dimensions
number_of_files = size(Beam_data,1);
number_of_curves = number_of_files * size(Depths,1);
Dose_Data(number_of_curves).FilePath = {};
% Flip the variable so that it is the same as Dose_files
Dose_Data = Dose_Data';

% get the normalization and shift parameters
PDD_GridSize = import_parameters.PDD.GridSize;
PDD_Smoothing = import_parameters.PDD.Smoothing;
PDD_Shift_location = import_parameters.PDD.Shift_location;

Profile_GridSize = import_parameters.profile.GridSize;
Profile_Smoothing = import_parameters.profile.Smoothing;
Profile_Center = import_parameters.profile.Center;

%% Loop through all isodose files extracting PDDs and Profiles
Curve_Index = 1;
for i=1:number_of_files;
    % Get the basic field information
    Beam = Beam_data(i);
    DICOM_dose_file = Beam.dose_file;
    [pathstr,dose_file_name,~] = fileparts(Beam.dose_file);
    [~,plan_file_name,~] = fileparts(Beam.plan_file);
    isocentre = Beam.isocentre;
    Energy = Beam.energy;
    SSD = str2double(SSD_string(1:3));

    try
        [EqSq, FieldSize] = calculate_field_size(Beam.insertsize);
        Offset = mean(Beam.insertsize);  %This assumes gantry=0, collimator=0 & couch=0
        Offset_Distance = sqrt(Offset(1)^2 + Offset(2)^2);
    catch  %#ok<CTCH>
        % if no applicator do not create this applicator field
        %% TODO for Photons create field size parameters
    end
    Dose_Data(Curve_Index).FilePath = pathstr;
    Dose_Data(Curve_Index).DoseFile = dose_file_name;
    Dose_Data(Curve_Index).PlanFile = plan_file_name;
    Dose_Data(Curve_Index).PlanName = Beam.plan_name;
    Dose_Data(Curve_Index).FieldName = Beam.FieldName;
    Dose_Data(Curve_Index).FieldSize = FieldSize;
    %Dose_Data(Curve_Index).FieldSize = Beam.FieldSize; %Produces Applicator jaw
    %                                         settings in the form {X} x {Y}
    Dose_Data(Curve_Index).EquivSquare = EqSq;
    Dose_Data(Curve_Index).Offset = num2cell(Offset);
    Dose_Data(Curve_Index).Energy = [num2str(Beam.energy) ' MeV'];
    Dose_Data(Curve_Index).SSD = Beam.SSD;
    Dose_Data(Curve_Index).GantryAngle = Beam.Gantry_Angle;
    Dose_Data(Curve_Index).MUs = {Beam.MU};
    try
        Dose_Data(Curve_Index).Applicator = Beam.applicator;
        Dose_Data(Curve_Index).InsertShape = Beam.insertsize;
        Dose_Data(Curve_Index).InsertName = Beam.insertname;
    catch  %#ok<CTCH>
        % if no applicator do not create this applicator field
        %% TODO for Photons create field size parameters
    end
    Position = get_databook_depth(SSD,Energy,EqSq,PDD_Shift_location);
    %Extract the PDD curve
    PDD_Data = Extract_PDD(DICOM_dose_file, isocentre, Offset);
    [DepthData, DoseData, PDD_Analysis] = Normalize_PDD(PDD_Data.depth,PDD_Data.dose,PDD_GridSize,PDD_Smoothing,PDD_Shift_location,Position);
    % Put the PDD data in the structured array
    Dose_Data(Curve_Index).Type = 'PDD';
    Dose_Data(Curve_Index).Direction = 'Beam';
    Dose_Data(Curve_Index).dmax_Dose = PDD_Analysis.dmax_Dose;
    Dose_Data(Curve_Index).SurfaceDose = PDD_Analysis.SurfaceDose;
    Dose_Data(Curve_Index).Buildup_95 = PDD_Analysis.Build_up_95;
    Dose_Data(Curve_Index).R100 = PDD_Analysis.R100 - PDD_Analysis.depth_shift;
    Dose_Data(Curve_Index).R95 = PDD_Analysis.R95;
    Dose_Data(Curve_Index).R90 = PDD_Analysis.R90;
    Dose_Data(Curve_Index).R80 = PDD_Analysis.R80;
    Dose_Data(Curve_Index).R50 = PDD_Analysis.R50 - PDD_Analysis.depth_shift;
    Dose_Data(Curve_Index).DepthShift = PDD_Analysis.depth_shift;
    Dose_Data(Curve_Index).Distance = Offset_Distance;
    Dose_Data(Curve_Index).Depth = DepthData;
    Dose_Data(Curve_Index).Dose = DoseData;
    % Extract the Profile Curves
    ProfileData = Extract_Profile(DICOM_dose_file, isocentre, Offset, Directions, Depths);
    Number_of_depths = size(ProfileData,1);
    for j=1:Number_of_depths;
        Curve_Index = Curve_Index + 1;
        %Add the beam data to this curve
        Dose_Data(Curve_Index).FilePath = pathstr;
        Dose_Data(Curve_Index).DoseFile = dose_file_name;
        Dose_Data(Curve_Index).PlanFile = plan_file_name;
        Dose_Data(Curve_Index).PlanName = Beam.plan_name;
        Dose_Data(Curve_Index).FieldName = Beam.FieldName;
        Dose_Data(Curve_Index).FieldSize = FieldSize;
        Dose_Data(Curve_Index).EquivSquare = EqSq;
        Dose_Data(Curve_Index).Offset = {Offset};
        Dose_Data(Curve_Index).Energy = [num2str(Beam.energy) ' MeV'];
        Dose_Data(Curve_Index).SSD = Beam.SSD;
        Dose_Data(Curve_Index).GantryAngle = Beam.Gantry_Angle;
        Dose_Data(Curve_Index).MUs = num2cell(Beam.MU);
        try
            Dose_Data(Curve_Index).Applicator = Beam.applicator;
            Dose_Data(Curve_Index).InsertShape = Beam.insertsize;
            Dose_Data(Curve_Index).InsertName = Beam.insertname;
        catch  %#ok<CTCH>
            % if no applicator do not create this applicator field
            %% TODO for Photons create field size parameters
        end
        % Smooth, Normalize, Interpolate and Analyze the profile
        Distance = ProfileData(j).distance;
        Dose = ProfileData(j).dose;
        [ProfileDistance, ProfileDose, ProfileAnalysis] = Process_Profile(Distance,Dose,Profile_Center,Profile_GridSize,Profile_Smoothing);
        % Add the data for this profile curve to the structured array
        Dose_Data(Curve_Index).Type = 'Profile';
        Dose_Data(Curve_Index).Direction = ProfileData(j).direction;
        Dose_Data(Curve_Index).DistanceShift = ProfileAnalysis.shift;
        Dose_Data(Curve_Index).CAX_Dose = ProfileAnalysis.CAX_Dose;
        Dose_Data(Curve_Index).FieldWidth = ProfileAnalysis.field_width;
        Dose_Data(Curve_Index).Penumbra = ProfileAnalysis.penumbra;
        Dose_Data(Curve_Index).Flatness = ProfileAnalysis.flatness;
        Dose_Data(Curve_Index).Symmetry = ProfileAnalysis.symmetry;
        Dose_Data(Curve_Index).Depth = ProfileData(j).depth;
        Dose_Data(Curve_Index).Distance = ProfileDistance;
        Dose_Data(Curve_Index).Dose = ProfileDose;
    end
end
% remove extra rows
if size(Dose_Data,1) > Curve_Index
    Dose_Data(Curve_Index+1:end) = [];
end
Calculated_Data_Table = struct2table(Dose_Data);
end
