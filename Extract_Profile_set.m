function Dose_Data = Extract_Profile_set(DICOM_data_path,Direction, Depths, import_parameters)
% Profile_Data =  Profile_Data = Extract_Profile_set(DICOM_data_path,Position, Direction, Depths, import_parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Extract_PDD Extracts a structured array of Depth Dose curves from a
%    DICOM dose file. If GridSize is given, it also centres, normalizes and
%    interpolates the data with a spacing of GridSize in cm.
%
%   Input Arguments
%     DICOM_data_path  =  Directory where that DOCOM Data is located
%
%     Position         =  The X or Z distance in cm of the desired plane
%                         from dose matrix (relative to the iosocentre)
%                         to use for the profiles.
%
%     Direction        =  The orientation of the profile.  Can be
%                         'Crossline' or 'Inline'.
%
%     Depths           =  An array of the depths of the profiles to be
%                         extracted from the dose matrix
%
%     import_parameters  =  Parameters used for processing the imported
%                           PDDs. If absent, raw dose data is returned.  It
%                           contains multiple fields:
%
%            GridSize    =  The desired spacing between distance values
%                           obtained by interpolating the data that is
%                           imported.
%
%            Smoothing   =  The desired smoothing method for the profiles.
%                           Can be one of 'linear', 'sgolay', 'pchip' or
%                           'none'.
%
%            Center      =  Indicates if profiles should be centered. The
%                           options are 'Center' or Asymmetric'.
%
%
%   Output Arguments
%     PDD_Data  =   A structured array consisting of the following fields:
%          Path         = The directory path that the file was in.
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
%          applicator   = The applicator used by the field.
%          FieldSize    = A string containing the field size in the form:
%                              {max dimension} x {min dimension}
%                           or {diameter} cm circle
%          insertname   = The ID for the applicator inserd used.
%          insertshape  = An n x 2 matrix of points defining the insert
%                         shape.
%          direction    = The string 'Beam' (The direction of the dose data
%                         indicates a PDD curve)
%          Type         = The string 'PDD'
%          dmax_Dose    = The Dose at dmax before normalizing
%          MUs          = The MUs used for the dose calculation.
%          R100         =  The location of dmax before the depth shift.
%          R50          =  The location of the 50% dose before the depth
%                          shift.
%          depth_shift  =  The amount (in cm) the PDD depth was shifted.
%          SurfaceDose  =  The percent dose at the surface after
%                          normalizing and depth shifts.
%          Build_up_95  =  The location of the 95% dose in the build-up
%                          region after normalizing and depth shifts.
%          R95          =  The location of the 95% dose beyond dmax after
%                          normalizing and depth shifts.
%          R90          =  The location of the 90% dose beyond dmax after
%                          normalizing and depth shifts.
%          R80          =  The location of the 80% dose beyond dmax after
%                          normalizing and depth shifts.
%          depth        =  The Depth values for the PDD curve.
%          dose         =  The relative dose values for the PDD curve.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialize the function

% Check the number of input arguments (Minimum 4 Maximum 4)
narginchk(4, 4)

%% Get the list of DICOM dose files and corresponding data
Beam_data=get_plan_list(DICOM_data_path);
%% Prepare Profile data structure
% Define the structure
Dose_Data = struct('Path', {},'DoseFile', {},'PlanFile', {}, ...
    'PlanName', {}, 'FieldName', {}, 'Energy', {}, ...
    'SSD', {}, 'GantryAngle', {}, 'Applicator', {}, ...
    'FieldSize', {}, 'EquivSquare', {}, ...
    'InsertName', {}, 'InsertShape', {}, ...
    'Offset', {}, 'Direction', {}, 'Type', {}, ...
    'CAX_Dose', {}, 'MUs', {}, 'DistanceShift', {}, ...
    'FieldWidth', {}, 'Penumbra', {}, ...
    'Flatness', {}, 'Symmetry', {}, ...
    'Depth', {}, 'Distance', {}, 'Dose', {});

% Set the correct dimensions
number_of_files = size(Beam_data,1);
Dose_Data(number_of_files).Path = {};

% Flip the variable so that it is the same as Dose_files
Dose_Data = Dose_Data';

% get the normalization and shift parameters
Profile_GridSize = import_parameters.GridSize;
Profile_Smoothing = import_parameters.Smoothing;
Profile_Center = import_parameters.Center;

%% Loop through all isodose files
for i=1:number_of_files;
    % Extract the Profile curves
    Beam = Beam_data(i);
    DICOM_dose_file = Beam.dose_file;
    isocentre = Beam.isocentre;
    try
        Dose_Data(i).Applicator = Beam.applicator;
        Dose_Data(i).InsertShape = Beam.insertsize;
        Dose_Data(i).InsertName = Beam.insertname;
        [EqSq, FieldSize] = calculate_field_size(Beam.insertsize);
        Offset = mean(Beam.insertsize);  %This assumes gantry=0, collimator=0 & couch=0
    catch  %#ok<CTCH>
        % if no applicator do not create this applicator field
        %% TODO for Photons create field size parameters
    end
    [pathstr,dose_file_name,~] = fileparts(Beam.dose_file);
    [~,plan_file_name,~] = fileparts(Beam.plan_file);
    Dose_Data(i).Path = pathstr;
    Dose_Data(i).DoseFile = dose_file_name;
    Dose_Data(i).PlanFile = plan_file_name;
    Dose_Data(i).PlanName = Beam.plan_name;
    Dose_Data(i).FieldName = Beam.FieldName;
    Dose_Data(i).FieldSize = FieldSize;
    %PDD_Data(i).FieldSize = Beam.FieldSize; %Produces Applicator jaw
    %                                         settings in the form {X} x {Y}
    Dose_Data(i).EquivSquare = EqSq;
    Dose_Data(i).Energy = [num2str(Beam.energy) ' MeV'];
    Dose_Data(i).SSD = Beam.SSD;
    Dose_Data(i).Gantry_Angle = Beam.Gantry_Angle;
    Dose_Data(i).Type = 'Profile';
    Dose_Data(i).MUs = Beam.MU;
        
        Dose_Data(i).Direction = Profiles(j).direction;
        Dose_Data(i).Depth = Profiles(j).depth;

        [AdjustedDistance, RenormalizedDose, Profile_analysis] = Process_Profile(Distance,Dose,Profile_Center,Profile_GridSize,Profile_Smoothing);
        % Put the data in the structured array
        Dose_Data(i).CAX_Dose = Profile_analysis.CAX_Dose;
        Dose_Data(i).Distance = AdjustedDistance;
        Dose_Data(i).Dose = RenormalizedDose;
        Dose_Data(i).FieldWidth = Profile_analysis.field_width;
        Dose_Data(i).Penumbra = Profile_analysis.penumbra;
        Dose_Data(i).Flatness = Profile_analysis.flatness;
        Dose_Data(i).Symmetry = Profile_analysis.symmetry;
        Dose_Data(i).DistanceShift = Profile_analysis.shift;
    end
end

