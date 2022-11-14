function DataTable = Import_eMC_Data(varargin)
% DataTable = Import_eMC_Data(import_parameters, measured_path, description)
% DataTable = Import_eMC_Data(import_parameters, measured_path, calculated_path, description, SSD, Algorithm)
% DataTable = Import_eMC_Data(import_parameters, calculated_path, description, SSD, Algorithm, depths, directions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Import_eMC_Data creates a structured array of data tables containing
%    calculated and measured data with corresponding parameters.  The data
%    is imported from the driectory paths given and processed according to
%    the import_parameters. It saves the tables it creates as a .mat file
%    specified by save_path and then combines them as a structure.
%
%  Input Arguments
%     measured_path     =  The path to the folder conatining the .csv
%                          measured data files.
%     calculated_path   =  The path to the folder conatining the DICOM
%                          calculated plan and dose files.
%     description       =  A String describing the set of data.
%     SSD               =  A String SSD value to attach to the calculated
%                          data table.
%     Algorithm         =  A String indicating the calculation algorithm to
%                          attach to the calculated data table.
%     depths            =  A list of depths to extract for the calculated
%                          profiles.
%     directions        =  A length 1 or 2 cell array of the desired
%                          profile orientations each can be either
%                          'Crossline' or 'Inline'.
%                          Currently only the first orientation is used.
%                          profile orientations each can be either
%                          'Crossline' or 'Inline'.
%                          Currently only the first orientation is used.
%
%     import_parameters =  The parameters used for processing the imported
%                          data. The parameter set is in the form of nested
%                          structures:
%         The base parameter variable contains two fields:
%           measured:        Contains the parameters for the measured data.
%
%           calculated:      Contains the parameters for the Eclipse
%                            calculated data.
%              Both fields contain two subfields:
%                 PDD:          Contains the parameters for the PDD curves.
%                 profile:      Contains the parameters for the profile
%                               curves.
%                    Both fields contain multiple subfields:
%                      Both:
%                        GridSize  = The desired spacing between depth or
%                                    distance values obtained by
%                                    interpolating the data that is
%                                    imported.
%                        Smoothing = The desired smoothing method for the
%                                    imported data.  Can be one of
%                                    'linear', 'sgolay', 'pchip' or 'none'.
%
%                      PDD Only:
%                       shift_location = The desired positional correction.
%                                        Values can be 'Dmax' 'R50' or
%                                        'None'. If 'Dmax' or 'R50' the PDD
%                                        depth will be shifted to force
%                                        'Dmax' or 'R50' location to the
%                                        specified position.
%
%                      profile Only:
%                        Center    = Indicates if profile should be
%                                    centered. The options are 'Center' or
%                                    Asymmetric'.
%
%   Output Arguments
%     Data_Table = A table containing all measured PDD and Profile data
%                  found in the given directory and it's Subdirectories.
%                  The table contains the following fields:
%         Field Info:
%          FilePath   = The directory in which the measured data file is
%                       located.
%          FieldSize  = A string containing the field size in the form:
%                              {X} x {Y}
%                           or {diameter} cm circle
%          EquivSquare= The equivalent square field size based on the field
%                       size. 
%          Direction  = The string 'Crossline' (X), 'Inline' (Y), or 'Beam'
%                       (for a PDD) indicating the direction of the dose
%                       data curve.
%          Type       = PDD or Profile depending on the type of data curve
%          Energy     = A string containing the energy in the form:
%                               {energy} MeV
%          SSD        = The SSD of the field.
%                       For measured data it is taken from the
%                       measurement file's header and converted to cm.
%                       For calculated data it is manually entered for
%                       the calculated data because SSD is not stored in
%                       the DICOM files for electron beams.
%          GantryAngle= The gantry angle of the field.
%          Applicator = The applicator used by the field.
%                       For measured data it is manually entered based on
%                       the Field size.
%                       For calculated data it is obtained from the DICOM
%                       plan file.
%          Source     = The source of the data.  Cne be one of:
%                           'Measured' or 'Calculated'
%          Description= A text description of the data.
%
%         PDDs:
%          DepthShift   = The amount (in cm) the PDD depth was
%                         shifted.
%          SurfaceDose  = The percent dose at the surface after
%                         normalizing and depth shifts.
%          Buildup_95  = The location of the 95% dose in the
%                         build-up region after normalizing and depth
%                         shifts.
%          R100         = The location of dmax after normalizing and depth
%                         shifts.  
%          R95          = The location of the 95% dose beyond dmax after
%                         normalizing and depth shifts.
%          R90          = The location of the 90% dose beyond dmax after
%                         normalizing and depth shifts.
%          R80          = The location of the 80% dose beyond dmax after
%                         normalizing and depth shifts.
%          R50          = The location of the 50% dose after normalizing
%                         and depth shifts.  
%
%         Profiles:
%          DistanceShift= The amount (in cm) the profile distance was
%                         shifted to centre it.
%          FieldWidth   = The profile width in cm from 50% to 50% dose points.
%          Penumbra     = The average penumbra with in cm between the 20%
%                         and 80% dose points.
%          Flatness     = The variation in % of the dose in the region that
%                         is 80% of the field size.
%          Symmetry     = The maximum dose difference in percent between
%                         matching points on opposite sides of the profile
%                         over the region that is 80% of the field size.
%
%         Data:
%          Distance     =  The Profile distance (x) coordinates or the
%                          distance of the PDD from the central axis.
%          Depth        =  The Depth values for the PDD curve, or the depth
%                          of the profile.
%          Dose         =  The relative dose values for the PDD or profile
%                          curve.
%
%         Measured Only:
%          FileName     = The name of the file in which the measured data
%                         file is located.
%          Linac        = A string indicating the treatment unit the
%                         measurements were done on, based on the
%                         measurement file's header.
%
%         Calculated Only:
%          DoseFile     = File name for the DICOM dose file
%          PlanFile     = File name for the DICOM plan file
%          PlanName     = The plan name for the dicom dose matrix
%          FieldName    = The name of the first field in the plan that
%                         generated the dose matrix
%          Applicator   = The applicator used by the field.
%          InsertName   = The ID for the applicator inserd used.
%          InsertShape  = An n x 2 matrix of points defining the insert
%                         shape.
%          Offset       = The X and Z shifts relative to the iosocentre at
%                         which the PDD was taken
%
%          MUs          = The MUs used for the dose calculation.
%          dmax_Dose    = (PDDs) The Dose at dmax before normalizing
%          CAX_Dose     = (Profiles) The calculated dose at the central
%                          axis after any centering, interpoaltion and
%                          smoothing.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialize the function

% Check the number of input arguments (Minimum 2 Maximum 5)
narginchk(3, 7)
import_parameters = varargin{1};

% Check for importing calculated data
if (nargin == 3)
    %Importing only measured 
    import_measured = true;
    import_calculated = false;
    measured_path = varargin{2};
    description = varargin{3};
elseif (nargin == 6)
    %Importing matched measured and calculated
    import_measured = true;
    import_calculated = true;
    measured_path = varargin{2};
    calculated_path = varargin{3};
    description = varargin{4};
    SSD_string = varargin{5};
    Algorithm = varargin{6};
elseif (nargin == 7)
    %Importing only calculated
    import_calculated = true;
    import_measured = false;
    calculated_path = varargin{2};
    description = varargin{3};
    SSD_string = varargin{4};
    Algorithm = varargin{5};
    depths = varargin{6};
    directions = varargin{7};
    % If not importing measured check that depths and directions are valid
    % verify that depths is valid
    if isnumeric(depths)
        if max(size(depths)) > 0
            if min(depths) < 0
                error('Import_eMC_Data:InvalidParameter', 'depths must be non-negative');
            end
        else
            error('Import_eMC_Data:InvalidParameter', 'at least one depth is required');
        end
    else
        error('Import_eMC_Data:InvalidParameter', 'depths must positive real numbers');
    end
    % verify that directions is valid
    if iscellstr(directions)
        if max(size(directions))<3
            %verify that each cell is either 'Crossline' or 'Inline'
            valid_d = sum([strcmpi('Crossline',directions);strcmpi('Inline',directions)]);
            if all(valid_d)
                % directions is valid
            else
                error('Import_eMC_Data:InvalidParameter', 'directions must be a length 1 or 2 cell array containing either Crossline or Inline');
            end
        else
            error('Import_eMC_Data:InvalidParameter', 'directions must be a length 1 or 2 cell array containing either Crossline or Inline');
        end
    else
        error('Import_eMC_Data:InvalidParameter', 'directions must be a length 1 or 2 cell array containing either Crossline or Inline');
    end
end

%% Import Measured data
if import_measured
    Measured_table = Import_Measured_Electron_Data(measured_path, import_parameters.measured);
    
    % Get a list of the depths and orientations that the profiles were measured at
    Profile_Index = find(strcmp(Measured_table.Type,'Profile'));
    depths = unique(cell2mat(Measured_table.Depth(Profile_Index)));
    directions = unique(Measured_table.Direction(Profile_Index));
    % Add Applicator size (assuming = field size)
    FieldSize = Measured_table.FieldSize;
    expr = '^\s*(\d+)\s*[x]\s*(\d+)\s*[m]*\s*$';
    Applicator_func = @(x) str2double(regexprep(x,expr,'$1'));
    Applicator_list = cellfun(Applicator_func,FieldSize,'UniformOutput',false);
    Measured_table.Applicator = cell2mat(Applicator_list);

    % Add Source
    Source_list = cell(size(Measured_table,1),1);
    for i = 1:size(Source_list,1)
        Source_list{i} = 'Measured';
    end
    Measured_table.Source = Source_list;
    
    % Add Description
    Description_list = cell(size(Measured_table,1),1);
    for i = 1:size(Description_list,1)
        Description_list{i} = description;
    end
    Measured_table.Description = Description_list;

    % Select short name for Linac
    Linac = Measured_table.Linac;
    expr = '^.*(\d{2}[ABD])[^ABD]*$';
    Linac_func = @(x) regexprep(x,expr,'$1');
    Linac_list = cellfun(Linac_func,Linac,'UniformOutput',false);
    Measured_table.Linac = Linac_list;
    
    % Add "Calculated" variables to the Measured table
    EmptyCellStrings = cellstr(blanks(size(Measured_table,1))');
    EmptyCells = cell(size(Measured_table,1),1);
    Measured_table.Algorithm = EmptyCellStrings;
    Measured_table.PlanName = EmptyCellStrings;
    Measured_table.FieldName = EmptyCellStrings;
    Measured_table.InsertName = EmptyCells;
    Measured_table.InsertShape = EmptyCells;
    Measured_table.Offset = EmptyCells;
    Measured_table.PlanFile = EmptyCellStrings;
    Measured_table.DoseFile = EmptyCellStrings;
    Measured_table.CAX_Dose = EmptyCells;
    Measured_table.dmax_Dose = EmptyCells;
    Measured_table.MUs = EmptyCells;
end
%% Import calculated data from Eclipse
if import_calculated
    % Read in Calculated Data
    Calculated_table = Import_Calculated_Electron_Data(calculated_path, depths, SSD_string, directions, import_parameters.calculated);

    % Add SSD
    SSD_list = cell(size(Calculated_table,1),1);
    for i = 1:size(Calculated_table,1)
        SSD_list{i} = SSD_string;
    end
    Calculated_table.SSD = SSD_list;

    % Add Algorithm
    Algorithm_list = cell(size(Calculated_table,1),1);
    for i = 1:size(Calculated_table,1)
        Algorithm_list{i} = Algorithm;
    end
    Calculated_table.Algorithm = Algorithm_list;

    % Add Source
    Source_list = cell(size(Calculated_table,1),1);
    for i = 1:size(Source_list,1)
        Source_list{i} = 'Calculated';
    end
    Calculated_table.Source = Source_list;

    % Add Description
    Description_list = cell(size(Calculated_table,1),1);
    for i = 1:size(Description_list,1)
        Description_list{i} = description;
    end
    Calculated_table.Description = Description_list;

    % Add "Measured" variables to the Calculated table
    EmptyCellStrings = cellstr(blanks(size(Calculated_table,1))');
    Calculated_table.Linac = EmptyCellStrings;
    Calculated_table.FileName = EmptyCellStrings; 
end
%% Combine the Tables
if import_measured
    if import_calculated
        DataTable = [Measured_table; Calculated_table];
    else
        DataTable = Measured_table;
    end
else
    DataTable = Calculated_table;
end
end
