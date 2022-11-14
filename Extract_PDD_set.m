function PDD_Data = Extract_PDD_set(DICOM_data_path, import_parameters)
% PDD_Data = Extract_PDD_set(DICOM_data_path, import_parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Extract_PDD Extracts a structured array of Depth Dose curves from a
%    DICOM dose file. If GridSize is given, it also centres, normalizes and
%    interpolates the data with a spacing of GridSize in cm.
%
%   Input Arguments
%     DICOM_data_path  =  Directory where that DOCOM Data is located
%
%     import_parameters  =  Parameters used for processing the imported
%                           PDDs. It contains multiple fields:
%
%              GridSize    =     The desired spacing between depth or
%                                distance values obtained by interpolating
%                                the data that is imported.
%              Smoothing   =     The desired smoothing method for the
%                                imported data.  Can be one of 'linear',
%                                'sgolay', 'pchip' or 'none'.
%
%              Shift_location = The desired positional correction.  Values
%                               can be 'Dmax' 'R50' or 'None'. If 'Dmax' or
%                               'R50' the PDD depth will be shifted to
%                               force 'Dmax' or 'R50' location to the
%                               specified position. 
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
%          EquivSquare  = The equivlent square field size as defined by the
%                         insert shape.  
%          insertname   = The ID for the applicator inserd used.
%          insertshape  = An n x 2 matrix of points defining the insert
%                         shape. 
%          Offset       = The X and Z shifts relative to the iosocentre at
%                         which the PDD was taken
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

% Check the number of input arguments (Minimum 3 Maximum 4)
narginchk(2, 2)

%% Get the list of DICOM dose files and corresponding data
Beam_data=get_plan_list(DICOM_data_path);

%% Prepare PDD data structure
% Define the structure
PDD_Data = struct('Path', {},'DoseFile', {},'PlanFile', {}, ...
                  'PlanName', {}, 'FieldName', {}, 'Energy', {}, ...
                  'SSD', {}, 'GantryAngle', {}, 'applicator', {}, ...
                  'FieldSize', {}, 'EquivSquare', {}, ...
                  'insertname', {}, 'insertshape', {}, ...
                  'Offset', {}, 'direction', {}, 'Type', {}, ...
                  'dmax_Dose', {}, 'MUs', {}, ...
                  'R100', {}, 'R50', {}, 'depth_shift', {}, ...
                  'SurfaceDose', {}, 'Build_up_95', {}, ...
                  'R95', {}, 'R90', {}, 'R80', {}, ...
                  'depth', {}, 'dose', {});

% Set the correct dimensions
number_of_files = size(Beam_data,1);
PDD_Data(number_of_files).Path = {};

% Flip the variable so that it is the same as Dose_files
PDD_Data = PDD_Data';

% get the normalization and shift parameters
GridSize = import_parameters.PDD.GridSize;
Smoothing = import_parameters.PDD.Smoothing;
Shift_location = import_parameters.PDD.Shift_location;

%% Loop through all isodose files
for i=1:number_of_files;
    % Extract the PDD curve
    Beam = Beam_data(i);
    DICOM_dose_file = Beam.dose_file;
    isocentre = Beam.isocentre;
    try
        PDD_Data(i).applicator = Beam.applicator;
        PDD_Data(i).insertshape = Beam.insertsize;
        PDD_Data(i).insertname = Beam.insertname;
        Offset = mean(Beam.insertsize);
    catch  %#ok<CTCH>
        % if no applicator do not create this applicator field
        %% TODO for Photons create field size parameters
    end
    PDD_Data = Extract_PDD(DICOM_dose_file, isocentre, Offset);
    Energy = Beam.energy;
    [EqSq, FieldSize] = calculate_field_size(Beam.insertsize);
    Position = get_databook_depth(Energy,EqSq,Shift_location);
    [ShiftedDepth, NormDose, PDD_analysis] = Normalize_PDD(PDD_Data.depth,PDD_Data.dose,GridSize,Smoothing,Shift_location,Position);
    % Put the data in the structured array
    [pathstr,dose_file_name,~] = fileparts(Beam.dose_file);
    [~,plan_file_name,~] = fileparts(Beam.plan_file);
    PDD_Data(i).Path = pathstr;
    PDD_Data(i).DoseFile = dose_file_name;
    PDD_Data(i).PlanFile = plan_file_name;
    PDD_Data(i).PlanName = Beam.plan_name;
    PDD_Data(i).FieldName = Beam.FieldName;
    PDD_Data(i).FieldSize = FieldSize;
    %PDD_Data(i).FieldSize = Beam.FieldSize; %Produces Applicator jaw
    %                                         settings in the form {X} x {Y}
    PDD_Data(i).EquivSquare = EqSq;
    PDD_Data(i).Energy = [num2str(Beam.energy) ' MeV'];
    PDD_Data(i).SSD = Beam.SSD;
    PDD_Data(i).Gantry_Angle = Beam.Gantry_Angle;
    PDD_Data(i).Offset = Offset;
    PDD_Data(i).direction = 'Beam';
    PDD_Data(i).Type = 'PDD';
    PDD_Data(i).MUs = Beam.MU;
    PDD_Data(i).dmax_Dose = PDD_analysis.dmax_Dose;
    PDD_Data(i).Depth = ShiftedDepth;
    PDD_Data(i).Dose = NormDose;
    PDD_Data(i).R100 = PDD_analysis.R100;
    PDD_Data(i).SurfaceDose = PDD_analysis.SurfaceDose;
    PDD_Data(i).Build_up_95 = PDD_analysis.Build_up_95;
    PDD_Data(i).R95 = PDD_analysis.R95;
    PDD_Data(i).R90 = PDD_analysis.R90;
    PDD_Data(i).R80 = PDD_analysis.R80;
    PDD_Data(i).R50 = PDD_analysis.R50;
    PDD_Data(i).depth_shift = PDD_analysis.depth_shift;
end
    
