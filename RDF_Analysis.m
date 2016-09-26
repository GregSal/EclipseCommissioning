function RDF_table = RDF_Analysis(DICOM_data_path)
% RDF_table = RDF_Analysis(DICOM_data_path)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    RDF_Analysis Extracts Depth Dose curves field sizes and MUs from the
%    DICOM dose files in the given path and its subdirectories. It then
%    calculates RDF values and generates a spreadsheet of data. 
%
%   Input Arguments
%     DICOM_data_path  =  Directory where that DOCOM Data is located
%
%   Output Arguments 
%     RDF_table        =   A Table with the following variables:
%                          Path         = The directory path that the file
%                                         was in
%                          DoseFileName = File name for the DICOM dose file
%                          PlanName     = The plan name for the dicom dose
%                                         matrix
%                          Algorithm    = The calculation algorithm used
%                          FieldName    = The name of the field in
%                                         associated with the dose matrix
%                          Energy       = A string containing the energy of
%                                         the first field in the plan that
%                                         generated the dose matrix
%                          Applicator   = The Applicator for that field.
%                          Field_x      = The Field X dimensions based on
%                                         the insert size. 
%                          Field_y      = The Field Y dimensions based on
%                                         the insert size. 
%                          Field_diam   = The Field diameter if the insert
%                                         is a circle (based on number of
%                                         points in the insert definition). 
%                          FieldSize    = A String describing the field
%                                         size and shape. 
%                          SSD          = The field SSD.
%                          EqSq        =  The equivalent square calculated 
%                                         from the field dimensions.
%                          MUs         =  The MUs used in the dose
%                                         calculation. 
%                          R100        =  The location of dmax.
%                          dmax_Dose   =  The Dose at dmax before
%                                         normalizing 
%                          output      =  The ratio of max dose to MUs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check the number of input arguments (Minimum 1 Maximum 1)
narginchk(1, 1)

%% Get the list of DICOM dose files and corresponding data
%TODO Find a way to extract the calculation algorithm
Algorithm_string = 'GoldenBeam';

Beam_data=get_plan_list(DICOM_data_path);


%% Prepare RDF data structure

% Define the structure
RDF_Data = struct('Path', {},'DoseFileName', {}, 'PlanName', {}, ...
    'Algorithm', {}, 'FieldName', {}, 'Energy', {}, 'Applicator', {}, ...
    'Field_x', {}, 'Field_y', {}, 'Field_diam', {}, 'FieldSize', {}, ...
    'SSD', {}, 'EqSq', {}, 'MUs', {}, 'R100', {}, 'dmax_Dose', {}, ...
    'output', {});

% Set the correct dimensions
number_of_files = size(Beam_data,1);
RDF_Data(number_of_files).Path = {};

% Flip the variable so that it is the same as Dose_files
RDF_Data = RDF_Data';

RDF_Index = 1;
%% Loop through all isodose files
for i=1:number_of_files;
    % Extract the PDD curve
    Beam = Beam_data(i);
    Offset = mean(Beam.insertsize);
    DICOM_dose_file = Beam.dose_file;
    isocentre = Beam.isocentre;
    PDD_Data = Extract_PDD(DICOM_dose_file, isocentre, Offset);
    Dose = PDD_Data.dose;
    Depth = PDD_Data.depth;
    [AdjustedDepth, FinalDose, PDD_analysis] = Normalize_PDD(Depth,Dose);
    
    % Determine field shape
    e_Insert = Beam.insertsize;
    if size(e_Insert,1) == 4
        insert_dimensions = max(abs(diff(e_Insert)));
        x = insert_dimensions(1);
        y = insert_dimensions(2);
        EqSq = (2*x*y)/(x+y);
        diameter = '';
        % field size string
        max_dim = max([x,y]);
        min_dim = min([x,y]);
        FieldSize = [num2str(max_dim) ' x ', num2str(min_dim)];
    else
        diameter = sum(max(e_Insert));
        EqSq = sqrt(pi*(diameter/2)^2);
        x = '';
        y = '';
        % files size string
        FieldSize = [num2str(diameter) ' cm circle'];
    end

% Get other PDD data MUs
    MUs = Beam.MU;
    dmax = PDD_analysis.R100;
    max_dose = PDD_analysis.dmax_Dose;
    output = max_dose/MUs;
    [Path, DoseFileName] = fileparts(DICOM_dose_file);

    % Put the data in the structured array
    RDF_Data(RDF_Index).Path = Path;
    RDF_Data(RDF_Index).DoseFileName = DoseFileName;
    RDF_Data(RDF_Index).PlanName = Beam.plan_name;
    RDF_Data(RDF_Index).Algorithm = Algorithm_string;
    RDF_Data(RDF_Index).FieldName = Beam.FieldName;
    RDF_Data(RDF_Index).Energy = [num2str(Beam.energy) ' MeV'];
    try
        RDF_Data(RDF_Index).Applicator = Beam.applicator;
    catch
        RDF_Data(RDF_Index).Applicator = '';
    end
    
    try
        if Beam.SSD == ''
            RDF_Data(RDF_Index).SSD = '100 cm';
        else
            RDF_Data(RDF_Index).SSD = [num2str(Beam.SSD) ' cm'];
        end
    catch 
        RDF_Data(RDF_Index).SSD = '100 cm';
    end
    RDF_Data(RDF_Index).Field_x = x;
    RDF_Data(RDF_Index).Field_y = y;
    RDF_Data(RDF_Index).Field_diam = diameter;
    RDF_Data(RDF_Index).FieldSize = FieldSize;
    RDF_Data(RDF_Index).EqSq = EqSq;
    
    RDF_Data(RDF_Index).MUs = MUs;
    RDF_Data(RDF_Index).R100 = dmax;
    RDF_Data(RDF_Index).dmax_Dose = max_dose;
    RDF_Data(RDF_Index).output = output;

    RDF_Data(RDF_Index).depth = AdjustedDepth;
    RDF_Data(RDF_Index).dose = FinalDose;

    RDF_Index = RDF_Index+1;
end
% convert to table variable
RDF_table = struct2table(RDF_Data);

%% Calculate RDF
%Get reference output
Ref_field_Size = strcmp(RDF_table{:,'FieldSize'},'10 x 10');
Ref_Applicator = RDF_table.Applicator == 10;
Ref_rows = Ref_field_Size & Ref_Applicator;
vars = {'Energy', 'Applicator', 'FieldSize', 'EqSq','MUs','R100','dmax_Dose','output'};
Ref_table = RDF_table(Ref_rows, vars);
[EnergyGroups, Energies] = findgroups(Ref_table.Energy);
Ref_output = splitapply(@mean,Ref_table.output,EnergyGroups);

for i = 1:size(RDF_table,1)
    energy = RDF_table{i,'Energy'};
    EnergyIndex = strcmp(Energies,energy);
    RDF(i) = RDF_table{i,'output'}/Ref_output(EnergyIndex);
end
RDF_table.RDF = RDF';

%% Save the table
data_path = '\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning\Output Factors';
matlab_file = 'electron_RDF_data.mat';
save([data_path '\' matlab_file],'RDF_table');

% Write to spreadsheet
excel_file = 'electron_RDF_data.xls';
vars = {'Path','DoseFileName','PlanName','Algorithm','FieldName','Energy', ...
        'Applicator', 'Field_x','Field_y','Field_diam','FieldSize','SSD', ...
        'EqSq','MUs','R100','dmax_Dose','output','RDF'};
writetable(RDF_table(:,vars),[data_path '\' excel_file],'Sheet','Eclipse')