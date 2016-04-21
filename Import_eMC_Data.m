function tables = Import_eMC_Data()
% tables = Import_eMC_Data()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Import_eMC_Data creates a structured array of data tables from a
%    variety of sources. It does not recieve any variables because this
%    function needs to be customezed for every data collection. It saves
%    the tables it creates as a .mat file and then combins them as a
%    structure. 
%
%    The function is continuaously expanded as more data is analyzed and
%    can often contain unused sections of code at the end from previous
%    work.
%
%   No Input Arguments
%
%   Output Arguments
%     tables       =  A structure containing all data tables created
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TODO Save Data to Excel File

%% Import 21D Measured data
data_path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\21D Measured Data\PDD-Profiles\SSD=100cm';
GridSize = 0.1;
% Current measured data is already smoothed  and centredin OmniPro
Center = 'Asymmetric';
% Center = 'Center';
Smoothing = 'none';
% Measured_MLC_Data = ImportWelhofferData(data_path);
% Measured_MLC_Data = ImportWelhofferData(data_path, Center);
Measured_21D_Data = ImportWelhofferData(data_path, Center, GridSize, Smoothing);

% convert to table variable
Measured_21D_table = struct2table(Measured_21D_Data);
% Identify Linac
Parameters = Measured_21D_table.Parameters;
linac = arrayfun(@(A) sscanf(A.TreatmentUnit,'%s Accelerator'),Parameters,'UniformOutput', false);
Measured_21D_table.linac = linac;
% Keep only 21D Data
index = strcmp(Measured_21D_table.linac,'Trilogy');
Measured_21D_table(~index,:) = [];
% Convert FieldSize mm to cm
FieldSizeText = Measured_21D_table.FieldSize;
% Extract the field size numbers
FieldSizeCell = cellfun(@(A) sscanf(A,'%d x %d mm')/10,FieldSizeText,'UniformOutput', false);
FieldSize = cellfun(@(A) [num2str(A(1)) ' x ', num2str(A(2))],FieldSizeCell,'UniformOutput', false);
Measured_21D_table.FieldSize = FieldSize;
% Add applicators size (assuming = field size)
ApplicatorSize = cellfun(@(A) uint16(A(1)),FieldSizeCell,'UniformOutput', false);
Measured_21D_table.ApplicatorSize = ApplicatorSize;
% Add SSD
Parameters = Measured_21D_table.Parameters;
SSD = arrayfun(@(A) num2str(sscanf(A.SSD,'%d mm')/10),Parameters,'UniformOutput', false);
SSD_string = cellstr(strcat(SSD,' cm'));
Measured_21D_table.SSD = SSD_string;

%% Import 21A Measured data
data_path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\21A Measured data\electron profiles and PDDs for isodose lines';
GridSize = 0.1;
% Current measured data is already smoothed  and centredin OmniPro
Center = 'Asymmetric';
% Center = 'Center';
Smoothing = 'none';
% Measured_MLC_Data = ImportWelhofferData(data_path);
% Measured_MLC_Data = ImportWelhofferData(data_path, Center);
Measured_21A_Data = ImportWelhofferData(data_path, Center, GridSize, Smoothing);

% convert to table variable
Measured_21A_table = struct2table(Measured_21A_Data);
% Identify Linac
Parameters = Measured_21A_table.Parameters;
linac = arrayfun(@(A) sscanf(A.TreatmentUnit,'%s Accelerator'),Parameters,'UniformOutput', false);
Measured_21A_table.linac = linac;
% Convert FieldSize mm to cm
FieldSizeText = Measured_21A_table.FieldSize;
% Extract the field size numbers
FieldSizeCell = cellfun(@(A) sscanf(A,'%d x %d mm')/10,FieldSizeText,'UniformOutput', false);
FieldSize = cellfun(@(A) [num2str(A(1)) ' x ', num2str(A(2))],FieldSizeCell,'UniformOutput', false);
Measured_21A_table.FieldSize = FieldSize;
% Add applicators size (assuming = field size)
ApplicatorSize = cellfun(@(A) uint16(A(1)),FieldSizeCell,'UniformOutput', false);
Measured_21A_table.ApplicatorSize = ApplicatorSize;
% Add SSD
Parameters = Measured_21A_table.Parameters;
SSD = arrayfun(@(A) num2str(sscanf(A.SSD,'%d mm')/10),Parameters,'UniformOutput', false);
SSD_string = cellstr(strcat(SSD,' cm'));
Measured_21A_table.SSD = SSD_string;

%% Import Beam Configuration Data
Path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\Beam Configuration Data';
GridSize = 0.1;
BeamConfigData = ImportBeamConfigData(Path, GridSize);
BeamConfig_table = struct2table(BeamConfigData);

% Convert Applicator to field size
Algorithms = unique(BeamConfig_table.Algorithm);
AlgorithmText = BeamConfig_table.Algorithm;
DataSource = unique(BeamConfig_table.DataLabel);
DataSourceText = BeamConfig_table.DataLabel;
ApplicatorText = BeamConfig_table.Applicator;
BeamConfig_table.FieldSize = cell(size(AlgorithmText));
BeamConfig_table.ApplicatorSize = cell(size(AlgorithmText));
FS = {'6 x 6','10 x 10','15 x 15','20 x 20','25 x 25'};
Ap_S = {6,10,15,20,25};
for i = 1:size(Algorithms,1)
    for j = 1:size(DataSource,1)
        Algorithm_rows = find(cell2mat(cellfun(@(A) strcmp(A,Algorithms{i}),AlgorithmText,'UniformOutput', false)));
        DataSource_rows = find(cell2mat(cellfun(@(A) strcmp(A,DataSource{j}),DataSourceText,'UniformOutput', false)));
        rows = intersect(Algorithm_rows,DataSource_rows);
        ApplicatorIDs = cell2mat(cellfun(@(A) sscanf(A,'Applicator - %u'),ApplicatorText(rows),'UniformOutput', false));
        [~,I] = sort(ApplicatorIDs);
        for k = 1:5
            BeamConfig_table.FieldSize{rows(I(k))} = FS{k};
            BeamConfig_table.ApplicatorSize{rows(I(k))} = Ap_S{k};
        end
    end
end
% Add 100 SSD
SSD = cellstr(strcat(num2str(ones(size(AlgorithmText))*100),' cm'));
BeamConfig_table.SSD = SSD;

%% Import Eclipse Calculated Plans from the 21A Measured Model 
DICOM_data_path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\Eclipse Calculated Data\';
directory = '21A Measured Model\12MeV';
data_path = [DICOM_data_path directory];
GridSize = 0.1;

% Read in Measured PDD Data
% Dmax = {'3.0 x 3.0'  2.3; '4.0 x 4.0'  2.4; '6.0 x 6.0' 2.4; ...
%         '8.0 x 8.0'  2.3; '10.0 x 10.0'  2.3; '20.0 x 20.0'  2.0; ...
%         '30.0 x 30.0'  1.8};
% Offset = [0 0]; 

Calculated21A_Measured_PDDs = Extract_PDD(data_path,GridSize);
% CalculatedAAA_PDDs = Extract_PDD(DICOM_data_path,GridSize,Offset,Dmax);

% convert to table variable
Calculated_21A_table = struct2table(Calculated21A_Measured_PDDs);

% Correct Field Size
ApplicatorSize = Calculated_21A_table.applicator;
FieldSize = cell(size(ApplicatorSize));
for i = 1:size(ApplicatorSize,1)
    FieldSize{i} = [num2str(ApplicatorSize(i)) ' x ', num2str(ApplicatorSize(i))];
end
Calculated_21A_table.FieldSize = FieldSize;

% Add 100 SSD
SSD = cellstr(strcat(num2str(ones(size(ApplicatorSize))*100),' cm'));
Calculated_21A_table.SSD = SSD;
% Add Algorithm
Algorithm_string = '21A Measured';
Algorithm = cell(size(Calculated_21A_table,1),1);
for i = 1:size(Calculated_21A_table,1)
    Algorithm{i} = Algorithm_string;
end
Calculated_21A_table.Algorithm = Algorithm;

%% Import Eclipse Calculated Plans from the Golden Beam Model 
DICOM_data_path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\Eclipse Calculated Data\';
directory = 'Golden Beam Model\12MeV';
data_path = [DICOM_data_path directory];
GridSize = 0.1;

% Read in Measured PDD Data
% Dmax = {'3.0 x 3.0'  2.3; '4.0 x 4.0'  2.4; '6.0 x 6.0' 2.4; ...
%         '8.0 x 8.0'  2.3; '10.0 x 10.0'  2.3; '20.0 x 20.0'  2.0; ...
%         '30.0 x 30.0'  1.8};
% Offset = [0 0]; 

GoldenBeam_Measured_PDDs = Extract_PDD(data_path,GridSize);
% CalculatedAAA_PDDs = Extract_PDD(DICOM_data_path,GridSize,Offset,Dmax);

% convert to table variable
GoldenBeam_table = struct2table(GoldenBeam_Measured_PDDs);

% Correct Field Size
ApplicatorSize = GoldenBeam_table.applicator;
FieldSize = cell(size(ApplicatorSize));
for i = 1:size(ApplicatorSize,1)
    FieldSize{i} = [num2str(ApplicatorSize(i)) ' x ', num2str(ApplicatorSize(i))];
end
GoldenBeam_table.FieldSize = FieldSize;

% Add 100 SSD
SSD = cellstr(strcat(num2str(ones(size(ApplicatorSize))*100),' cm'));
GoldenBeam_table.SSD = SSD;
% Add Algorithm
Algorithm_string = '21A Measured';
Algorithm = cell(size(GoldenBeam_table,1),1);
for i = 1:size(GoldenBeam_table,1)
    Algorithm{i} = Algorithm_string;
end
GoldenBeam_table.Algorithm = Algorithm;
%%
save('\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning\electron_data.mat','*table')
tables.BeamConfig_table = BeamConfig_table;
tables.Measured_21A_table = Measured_21A_table;
tables.Measured_21D_table = Measured_21D_table;
tables.GoldenBeam_table = GoldenBeam_table;
tables.Calculated_21A_table = Calculated_21A_table;
%%
%
return
%%%%%%%%%%%%%%%%%%%%%%%%%% Done to here %%%%%%%%%%%%%%%%%%%
%
%
%
%% import the profiles
directory = '21A Measured Model\12MeV';
data_path = [DICOM_data_path directory];
Position = 0;
Direction = 'CrossPlane';
Depths = [3 8 15];
Center = 'Asymmetric';
Smoothing = 'none';
Calculated_MLC_AC_Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);

Direction = 'InPlane';
Depths = [3 8 15];
Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);

Calculated_MLC_AC_Profiles = [Calculated_MLC_AC_Profiles; Profiles];
clear Profiles;

%% import the Open profiles
directory = '10X MLC open';
data_path = [DICOM_data_path directory];
Position = 0.25;
Center = 'Center';
Direction = 'CrossPlane';
Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);
Calculated_MLC_AC_Profiles = [Calculated_MLC_AC_Profiles; Profiles];
clear Profiles;

Position = 0;
Direction = 'InPlane';
Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);
Calculated_MLC_AC_Profiles = [Calculated_MLC_AC_Profiles; Profiles];
clear Profiles;

%% import the Y_Jaw profiles
directory = '10X MLC=Y_Jaw';
data_path = [DICOM_data_path directory];
Position = 0.25;
Center = 'Center';
Direction = 'CrossPlane';
Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);
Calculated_MLC_AC_Profiles = [Calculated_MLC_AC_Profiles; Profiles];
clear Profiles;

Position = 0;
Direction = 'InPlane';
Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);
Calculated_MLC_AC_Profiles = [Calculated_MLC_AC_Profiles; Profiles];
clear Profiles;



%% Import PDDs

% % Read in Measured PDD Data
% Dmax = {'3.0 x 3.0'  2.3; '4.0 x 4.0'  2.4; '6.0 x 6.0' 2.4; ...
%         '8.0 x 8.0'  2.3; '10.0 x 10.0'  2.3; '20.0 x 20.0'  2.0; ...
%         '30.0 x 30.0'  1.8};
% Offset = [0 0];
%
% % CalculatedAAA_PDDs = Extract_PDD(DICOM_data_path,GridSize);
% CalculatedAAA_PDDs = Extract_PDD(DICOM_data_path,GridSize,Offset,Dmax);

%% convert to table variable
Calculated_MLC_AC_Profiles_table = struct2table(Calculated_MLC_AC_Profiles);

% Identify Type of field from FileName
PlanNames = Calculated_MLC_AC_Profiles_table.PlanName;

% Extract the last portion of the file name (After MLC in the file name)
FieldType = cellfun(@(A) sscanf(A,'%*[^C] %*2c %s'),PlanNames,'UniformOutput', false);

% fix the 'Y_Jaw' type Because the '_' causes a subscript as a lable
FieldType = strrep(FieldType, 'Y_Jaw', 'Y jaw');

% add field type as aVariable to the table
Calculated_MLC_AC_Profiles_table.FieldType = FieldType;


% Convert the variable names to match the measured data
VariableNames =Calculated_MLC_AC_Profiles_table.Properties.VariableNames;
% Change 'depth' to 'Depth'
VariableNames = strrep(VariableNames, 'depth', 'Depth');
% Change 'direction' to 'Direction'
VariableNames = strrep(VariableNames, 'direction', 'Direction');
% Convert the variable names
Calculated_MLC_AC_Profiles_table.Properties.VariableNames = VariableNames;

% fix the 'open' type
Calculated_MLC_AC_Profiles_table.FieldType = strrep(Calculated_MLC_AC_Profiles_table.FieldType, 'open', 'Open');
% fix the 'CrossPlane' direction
Calculated_MLC_AC_Profiles_table.Direction = strrep(Calculated_MLC_AC_Profiles_table.Direction, 'CrossPlane', 'Crossline');
% fix the 'InPlane' direction
Calculated_MLC_AC_Profiles_table.Direction = strrep(Calculated_MLC_AC_Profiles_table.Direction, 'InPlane', 'Inline');

%% Import Calculated 10X AAA MLC Plans

DICOM_data_path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\TrueBeam Commissioning\MLC Defined Fields\AAA Calculations\';
GridSize = 0.1;

% import the profiles

% import the Offset profiles
directory = '10X MLC Offset';
data_path = [DICOM_data_path directory];
Position = 4.5;
Direction = 'CrossPlane';
Depths = [3 8 15];
Center = 'Asymmetric';
Smoothing = 'none';
Calculated_MLC_AAA_Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);

Direction = 'InPlane';
Depths = [3 8 15];
Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);

Calculated_MLC_AAA_Profiles = [Calculated_MLC_AAA_Profiles; Profiles];
clear Profiles;

%% import the Open profiles
directory = '10X MLC open';
data_path = [DICOM_data_path directory];
Position = 0.25;
Center = 'Center';
Direction = 'CrossPlane';
Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);
Calculated_MLC_AAA_Profiles = [Calculated_MLC_AAA_Profiles; Profiles];
clear Profiles;

Position = 0;
Direction = 'InPlane';
Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);
Calculated_MLC_AAA_Profiles = [Calculated_MLC_AAA_Profiles; Profiles];
clear Profiles;

%% import the Y_Jaw profiles
directory = '10X MLC=Y_Jaw';
data_path = [DICOM_data_path directory];
Position = 0.25;
Center = 'Center';
Direction = 'CrossPlane';
Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);
Calculated_MLC_AAA_Profiles = [Calculated_MLC_AAA_Profiles; Profiles];
clear Profiles;

Position = 0;
Direction = 'InPlane';
Profiles = Extract_Profile(data_path,Position, Direction, Depths,GridSize,Center,Smoothing);
Calculated_MLC_AAA_Profiles = [Calculated_MLC_AAA_Profiles; Profiles];
clear Profiles;



%% Import PDDs

% % Read in Measured PDD Data
% Dmax = {'3.0 x 3.0'  2.3; '4.0 x 4.0'  2.4; '6.0 x 6.0' 2.4; ...
%         '8.0 x 8.0'  2.3; '10.0 x 10.0'  2.3; '20.0 x 20.0'  2.0; ...
%         '30.0 x 30.0'  1.8};
% Offset = [0 0];
%
% % CalculatedAAA_PDDs = Extract_PDD(DICOM_data_path,GridSize);
% CalculatedAAA_PDDs = Extract_PDD(DICOM_data_path,GridSize,Offset,Dmax);

%% convert to table variable
Calculated_MLC_AAA_Profiles_table = struct2table(Calculated_MLC_AAA_Profiles);

% Identify Type of field from FileName
PlanNames = Calculated_MLC_AAA_Profiles_table.PlanName;

% Extract the last portion of the file name (After MLC in the file name)
FieldType = cellfun(@(A) sscanf(A,'%*[^C] %*2c %s'),PlanNames,'UniformOutput', false);

% fix the 'Y_Jaw' type Because the '_' causes a subscript as a lable
FieldType = strrep(FieldType, 'Y_Jaw', 'Y jaw');

% add field type as aVariable to the table
Calculated_MLC_AAA_Profiles_table.FieldType = FieldType;


% Convert the variable names to match the measured data
VariableNames =Calculated_MLC_AAA_Profiles_table.Properties.VariableNames;
% Change 'depth' to 'Depth'
VariableNames = strrep(VariableNames, 'depth', 'Depth');
% Change 'direction' to 'Direction'
VariableNames = strrep(VariableNames, 'direction', 'Direction');
% Convert the variable names
Calculated_MLC_AAA_Profiles_table.Properties.VariableNames = VariableNames;

% fix the 'open' type
Calculated_MLC_AAA_Profiles_table.FieldType = strrep(Calculated_MLC_AAA_Profiles_table.FieldType, 'open', 'Open');

% fix the 'CrossPlane' direction
Calculated_MLC_AAA_Profiles_table.Direction = strrep(Calculated_MLC_AAA_Profiles_table.Direction, 'CrossPlane', 'Crossline');
% fix the 'InPlane' direction
Calculated_MLC_AAA_Profiles_table.Direction = strrep(Calculated_MLC_AAA_Profiles_table.Direction, 'InPlane', 'Inline');
