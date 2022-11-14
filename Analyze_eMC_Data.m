%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Analyze_eMC_Data imports groups of measured and calculated data,
%    creates graphs and comparison charts and exports data to excel
%    spreadsheets.
%    Each section is intended to import and analyze a seperate group of
%    data.  The script is continuously expanded as more data is analyzed
%    and can often contain unused sections of code at the end from previous
%    work.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% initialize parameters and paths
% Set the base data path
data_path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\';

% Set the base path for saving data and analysis
save_path = '\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning\';

%%% Set the basic import parameters
%  This sets the basic import_parameters structure. It can be copied and
%  modified for individual groups.

% Set the measured PDD parameters
import_parameters.measured.PDD.GridSize = 0.03;
import_parameters.measured.PDD.Smoothing = 'sgolay';
import_parameters.measured.PDD.Shift_location = 'R50';

% Set the measured profile parameters
% Current measured profiles are already smoothed and centred in OmniPro
import_parameters.measured.profile.GridSize = 0.03;
import_parameters.measured.profile.Center = 'Asymmetric';
import_parameters.measured.profile.Smoothing = 'none';

% Set the calculated PDD parameters
import_parameters.calculated.PDD.GridSize = 0.03;
import_parameters.calculated.PDD.Smoothing = 'sgolay';
import_parameters.calculated.PDD.Shift_location = 'R50';

% Set the calculated profile parameters
import_parameters.calculated.profile.GridSize = 0.1;
import_parameters.calculated.profile.Center = 'Center';
import_parameters.calculated.profile.Smoothing = 'linear';


%% Import High Accuracy Open Square Fields
description = 'High Accuracy Open Square Fields';

% Import 21D Measured data
data_path_21D = [data_path '21D Measured Data\PDD-Profiles\SSD=100cm'];
Measured_21D_table = Import_eMC_Data(import_parameters, data_path_21D, description);
% Keep only 21D Data
FindLinac = @(x) isempty(strfind(x, '21D'));
index = cellfun(FindLinac,Measured_21D_table.Linac);
Measured_21D_table(index,:) = [];
% Get a list of the depths and orientations that the profiles were measured at
Profile_Index = find(strcmp(Measured_21D_table.Type,'Profile'));
depths_21D = unique(cell2mat(Measured_21D_table.Depth(Profile_Index)));
directions_21D = unique(Measured_21D_table.Direction(Profile_Index));

% Import 21A Measured data
data_path_21A = [data_path '21A Measured data\electron profiles and PDDs for isodose lines'];
Measured_21A_table = Import_eMC_Data(import_parameters, data_path_21A, description);
% Get a list of the depths and orientations that the profiles were measured at
Profile_Index = find(strcmp(Measured_21A_table.Type,'Profile'));
depths_21A = unique(cell2mat(Measured_21A_table.Depth(Profile_Index)));
directions_21A = unique(Measured_21A_table.Direction(Profile_Index));
% Make a combined list of the depths and orientations
depths = union(depths_21A,depths_21D);
directions = union(directions_21A,directions_21D);

% Import Eclipse Calculated Data
SSD = '100 cm';
Algorithm = 'Golden Beam';
% data_path_calc = [data_path 'Eclipse Calculated Data\High Accuracy'];
data_path_calc = [data_path 'Eclipse Calculated Data\High Accuracy'];
Calculated_table = Import_eMC_Data(import_parameters, data_path_calc, description, SSD, Algorithm, depths, directions);
% Keep only square field sizes
FieldSize = Calculated_table.FieldSize;
f = @issquare;
index = cellfun(f,FieldSize);
Calculated_table(~index,:) = [];

% Merge and Save the tables
DataTable = [Measured_21D_table; Measured_21A_table; Calculated_table];
analysis_save_path = [save_path description '\'];
mkdir(analysis_save_path);
imported_mat_file = [analysis_save_path 'imported_data.mat'];
save(imported_mat_file,'DataTable');

%% Load Data
save_path = '\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning';
description = 'High Accuracy Open Square Fields';
% Analysis_folder = 'Square Fields Analysis';
analysis_save_path = [save_path '\' description];
imported_mat_file = [analysis_save_path '\' 'imported_data.mat'];
load(imported_mat_file)


%% Identify Groups for  Plotting and spreadsheets

% First split by PDD and Profile
[TypeIndex,Types] = findgroups(DataTable(:,'Type'));
PDDs = DataTable(TypeIndex==find(strcmp(Types{:,'Type'},'PDD')),:);
Profiles = DataTable(TypeIndex==find(strcmp(Types{:,'Type'},'Profile')),:);
% Analyze_profiles(Profiles, analysis_save_path)
Analyze_PDDs(PDDs, analysis_save_path)
