function Analyze_PDDs(PDDs, analysis_save_path)
% Analyze_PDDs(PDDs, analysis_save_path)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Analyze_PDDs Plots PDD figures and saves data to excel files.
%
%  Input Arguments
%     analysis_save_path =  the path for saving the profile spreadsheets
%     PDDs    =    A table containing measured and calculated Profile data
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
%                          smoothing.%                          measured data files.
%     calculated_path   =  The path to the folder conatining the DICOM
%                          calculated plan and dose files.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialize the function

% Check the number of input arguments (Minimum 2 Maximum 2)
narginchk(2, 2)

%% Select PDDs
%Convert Energy to a numerical variable and sort Data
expr = '^\s*(\d+)\s*MeV\s*$';
Energy_func = @(x) str2double(regexprep(x,expr,'$1'));
PDDs.EnergySort = cell2mat(cellfun(Energy_func,PDDs.Energy,'UniformOutput',false));

sort_categories = {'EnergySort','EquivSquare','Source',};
PDDs = sortrows(PDDs,sort_categories);
 
% Set categories and find PDD groups
group_categories = {'Type';'Energy';'Applicator';'FieldSize'};
[GroupIndex,Groups] = findgroups(PDDs(:,group_categories));

% Select only PDDs that have both Calculated and Measured
Compare_on = {'Source'};
for i = 1:height(Groups)
    Groups{i,'NumSources'} = size(unique(PDDs{GroupIndex==i,Compare_on}),1);
end
PDDSelection = find(Groups.NumSources > 1);
SelectedPDDGroups = Groups(PDDSelection,:);
SelectedPDDGroups.Index = PDDSelection;

%% Define PDD group labels for plotting and saving
PDDGroupVariables = {'Depth', 'Dose', 'Source', 'Linac', 'Algorithm'};

group_labels = struct;
% Define an excel directory (This is used for saving data to excel files)
group_labels(1).Name = 'Directory';
group_labels(1).Elements = {'Type'};
group_labels(1).Functions = {@(x) strcat('\', analysis_save_path, x{:,1})};
    
% Define a Spreadsheet name (This is used for saving data to excel files)
group_labels(2).Name = 'ExcelName';
group_labels(2).Elements = {'Energy'};
group_labels(2).Functions = {@(x) strcat(x{:,1}, '.xls')};

% Define a Worksheet name (This is used for saving data to excel files)
group_labels(3).Name = 'SheetName';
group_labels(3).Elements = {'FieldSize'};
group_labels(3).Functions = {@(x) strcat(x{:,1}, {' cm'})};

% Define a Plot Title (This is used for Plot titles)
group_labels(4).Name = 'Title';
group_labels(4).Elements = {'Energy';'Applicator';'FieldSize'};
group_labels(4).Functions = {...
    @(x) strcat(x{:,1}, {',  '}) ...
    @(x) strcat(cellfun(@num2str,num2cell(x{:,1}),'UniformOutput',false), {' cm Applicator,  '}) ...
    @(x) strcat(x{:,1}, {' Insert, '})};


X.Name = 'Depth';
X.Label = 'Depth (cm)';
Y.Name = 'Dose';
Y.Label = 'Dose (%)';

%% Define data labels for plotting and saving
data_labels = struct;
% Define a Curve Label Title (This applies to individual data curves and is used to label plots and excel columns)
data_labels(1).Name = 'Linac';
data_labels(1).Elements = {'Linac'};
data_labels(1).Functions = {@(x) strcat(x{:,1}, {''})};
    
data_labels(2).Name = 'Algorithm';
data_labels(2).Elements = {'Algorithm'};
data_labels(2).Functions = {@(x) strrep(x{:,1}, 'Golden Beam', 'GB')};

data_labels(3).Name = 'DataLabel';
data_labels(3).Elements = {'Source';'Linac';'Algorithm'};
data_labels(3).Functions = {...
    @(x) strcat(x{:,1}, {' '}) ...
    @(x) strcat(x{:,1}, '') ...
    @(x) strcat(x{:,1}, '')};
%% Process groups
% Add labels
for n = 1:size(group_labels,2)
    SelectedPDDGroups(:,group_labels(n).Name) = MakeColumn(SelectedPDDGroups, group_labels(n));
end

for i = 1:height(SelectedPDDGroups)
    group = table2struct(SelectedPDDGroups(i,:));
    
    group_data = PDDs(GroupIndex==group.Index,PDDGroupVariables);
    % Add data titles
    for n = 1:size(data_labels,2)
        group_data(:,data_labels(n).Name) = MakeColumn(group_data, data_labels(n));
    end
    %FIXME Multiple identical data sets being obtained they should be
    %averaged in CalculateDifferences
    all_data = CalculateDifference(Compare_on, group_data, X, Y);
    %TODO Create an annotation column that can be added to plots    
    % % Calculate the distance between 50% points
    % DistanceError = ProfileDistanceError(MeasuredDistance_TR1,MeasuredDose_TR1, ...
    %         GoldenBeamDistance,GoldenBeamDose);
    %         'String',{['50% distance error = ' ...
    %         num2str(DistanceError(1)*10,1) ' mm, ' ...
    %         num2str(DistanceError(2)*10,1) ' mm']}, ...
%     WriteSheet(group, all_data, X, Y)
    PlotData(group, all_data, X, Y, Compare_on)
end
%% Save PDD agregate data
PDD_data_analysis = PDDs;
PDD_data_analysis.EnergySort = [];
% Remove Profile related data columns
PDD_data_analysis.DistanceShift = [];
PDD_data_analysis.FieldWidth = [];
PDD_data_analysis.Flatness = [];
PDD_data_analysis.Symmetry = [];
% Remove data curves
PDD_data_analysis.Distance = [];
PDD_data_analysis.Depth = [];
PDD_data_analysis.Dose = [];
% Remove poorly shaped data
PDD_data_analysis.InsertShape = [];
PDD_data_analysis.Offset = [];

%Save the profile analysis data to a spreadsheet
filename = [analysis_save_path '\' 'PDD Analysis.xls'];
% writetable(PDD_data_analysis,filename)