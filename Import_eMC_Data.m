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
% Current measured data is already smoothed  and centred in OmniPro
Center = 'Asymmetric';
% Center = 'Center';
Smoothing = 'none';
% Measured_MLC_Data = ImportWelhofferData(data_path);
% Measured_MLC_Data = ImportWelhofferData(data_path, Center);
Measured_21D_Data = ImportWelhofferData(data_path, Center, GridSize, Smoothing);

% convert to table variable
Measured_21D_table = struct2table(Measured_21D_Data);

%%%%%%% Set Parameters
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

%%%%%%% normalize and shift the PDDs
% set the normalization and shift parameters
Smoothing = 'linear';
Shift_location = 'R50';
%TODO select position by energy
Position = 5.0;
disp('21D Measured Data');
% select the PDDS 
PDD_Index = find(strcmp(Measured_21D_table.Type,'PDD'));
for i = 1:length(PDD_Index)
    Depth = cell2mat(Measured_21D_table{PDD_Index(i),'Depth'});
    Dose = cell2mat(Measured_21D_table{PDD_Index(i),'Dose'});
    [ShiftedDepth, NormDose, Shift] = Normalize_PDD(Depth,Dose,GridSize,Smoothing,Shift_location,Position);
    Measured_21D_table{PDD_Index(i),'Depth'} = {ShiftedDepth};
    Measured_21D_table{PDD_Index(i),'Dose'} = {NormDose};
    FieldSizeString = cellstr(Measured_21D_table{PDD_Index(i),'FieldSize'});
    disp(['Field Size = ' FieldSizeString ' Shift = ' num2str(Shift)]);
end

%%%%%%%%%% Identify the profiles
% select the Profiles 
Profile_Index = find(strcmp(Measured_21D_table.Type,'Profile'));
depths_21D = unique(cell2mat(Measured_21D_table.Depth(Profile_Index)));
directions_21D = unique(Measured_21D_table.Direction(Profile_Index));

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

% Select only 12 MeV  *******************!!!!!!!!!!!!!!!!*************
EnergyIndex = strcmp(Measured_21A_table.Energy,'12 MeV');
Measured_21A_table = Measured_21A_table(EnergyIndex,:);

%%%%%%% normalize and shift the PDDs
% set the normalization and shift parameters
Smoothing = 'linear';
Shift_location = 'R50';
%TODO select position by energy
Position = 5.0;
disp('21A Measured Data');
% select the PDDS 
PDD_Index = find(strcmp(Measured_21A_table.Type,'PDD'));
for i = 1:length(PDD_Index)
    Depth = cell2mat(Measured_21A_table{PDD_Index(i),'Depth'});
    Dose = cell2mat(Measured_21A_table{PDD_Index(i),'Dose'});
    [ShiftedDepth, NormDose, Shift] = Normalize_PDD(Depth,Dose,GridSize,Smoothing,Shift_location,Position);
    Measured_21A_table{PDD_Index(i),'Depth'} = {ShiftedDepth};
    Measured_21A_table{PDD_Index(i),'Dose'} = {NormDose};
    FieldSizeString = cellstr(Measured_21A_table{PDD_Index(i),'FieldSize'});
    disp(['Field Size = ' FieldSizeString ' Shift = ' num2str(Shift)]);
end

%%%%%%%%%% Identify the profiles
% select the Profiles 
Profile_Index = find(strcmp(Measured_21A_table.Type,'Profile'));
depths_21A = unique(cell2mat(Measured_21A_table.Depth(Profile_Index)));
directions_21A = unique(Measured_21A_table.Direction(Profile_Index));

%% Import Beam Configuration Data
Path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\Beam Configuration Data';
GridSize = 0.1;
BeamConfigData = ImportBeamConfigData(Path, GridSize);
BeamConfig_table = struct2table(BeamConfigData);

% Get rid uf underscore in Algorithm
AlgorithmText = BeamConfig_table.Algorithm;
BeamConfig_table{:,'Algorithm'} = strrep(AlgorithmText, '_', ' ');

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

%%%%%%% normalize and shift the PDDs
% set the normalization and shift parameters
Smoothing = 'linear';
Shift_location = 'R50';
%TODO select position by energy
Position = 5.0;
disp('Beam Config Data');
% select the PDDS 
PDD_Index = find(strcmp(BeamConfig_table.Type,'PDD'));
for i = 1:length(PDD_Index)
    Depth = cell2mat(BeamConfig_table{PDD_Index(i),'X'});
    Dose = cell2mat(BeamConfig_table{PDD_Index(i),'Y'});
    [ShiftedDepth, NormDose, Shift] = Normalize_PDD(Depth,Dose,GridSize,Smoothing,Shift_location,Position);
    BeamConfig_table{PDD_Index(i),'X'} = {ShiftedDepth};
    BeamConfig_table{PDD_Index(i),'Y'} = {NormDose};
    FieldSizeString = cellstr(BeamConfig_table{PDD_Index(i),'FieldSize'});
    disp(['Field Size = ' FieldSizeString ' Shift = ' num2str(Shift)]);
end

%% Import Eclipse Calculated Plans from the 21A Measured Model 
DICOM_data_path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\Eclipse Calculated Data\';
directory = '21A Measured Model\12MeV';
data_path = [DICOM_data_path directory];

% Read in Calculated PDD Data
 Calculated21A_Measured_PDDs = Extract_PDD(data_path);

% Read in Calculated Profile Data
GridSize = 0.1;
Center = 'Center';
Smoothing = 'linear';
% Select the depths
depths = union(depths_21A, depths_21D);
directions = union(directions_21A, directions_21D);
Calculated21A_Measured_Profiles = Extract_Profile(data_path,0,directions{1},depths,GridSize,Center,Smoothing);

% convert to table variable
Calculated21A_Measured = [Calculated21A_Measured_PDDs; Calculated21A_Measured_Profiles];
Calculated_21A_table = struct2table(Calculated21A_Measured);

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

%%%%%%% normalize and shift the PDDs
% set the normalization and shift parameters
Shift_location = 'R50';
%TODO select position by energy
Position = 5.0;
disp('calculated 21A Model Data');
% select the PDDS 
PDD_Index = find(strcmp(Calculated_21A_table.Type,'PDD'));
for i = 1:length(PDD_Index)
    Depth = cell2mat(Calculated_21A_table{PDD_Index(i),'depth'});
    Dose = cell2mat(Calculated_21A_table{PDD_Index(i),'dose'});
    [ShiftedDepth, NormDose, Shift] = Normalize_PDD(Depth,Dose,GridSize,Smoothing,Shift_location,Position);
    Calculated_21A_table{PDD_Index(i),'depth'} = {ShiftedDepth};
    Calculated_21A_table{PDD_Index(i),'dose'} = {NormDose};
    FieldSizeString = cellstr(Calculated_21A_table{PDD_Index(i),'FieldSize'});
    disp(['Field Size = ' FieldSizeString ' Shift = ' num2str(Shift)]);
end

%% Import Eclipse Calculated Plans from the Golden Beam Model 
DICOM_data_path = '\\dkphysicspv1\e$\Gregs_Work\Gregs_Data\Eclipse Commissioning Data\eMC V13.6 Commissioning Data\Eclipse Calculated Data\';
directory = 'Golden Beam Model\12MeV';
data_path = [DICOM_data_path directory];

% Read in Calculated PDD Data
GoldenBeam_Calculated_PDDs = Extract_PDD(data_path);

% Read in Calculated Profile Data
GridSize = 0.1;
Center = 'Center';
Smoothing = 'linear';
% Select the depths
depths = union(depths_21A, depths_21D);
directions = union(directions_21A, directions_21D);
GoldenBeam_Calculated_Profiles = Extract_Profile(data_path,0,directions{1},depths,GridSize,Center,Smoothing);

% convert to table variable
GoldenBeam_Calculated = [GoldenBeam_Calculated_PDDs; GoldenBeam_Calculated_Profiles];
GoldenBeam_Calculated_table = struct2table(GoldenBeam_Calculated);

% Correct Field Size
ApplicatorSize = GoldenBeam_Calculated_table.applicator;
FieldSize = cell(size(ApplicatorSize));
for i = 1:size(ApplicatorSize,1)
    FieldSize{i} = [num2str(ApplicatorSize(i)) ' x ', num2str(ApplicatorSize(i))];
end
GoldenBeam_Calculated_table.FieldSize = FieldSize;

% Add 100 SSD
SSD = cellstr(strcat(num2str(ones(size(ApplicatorSize))*100),' cm'));
GoldenBeam_Calculated_table.SSD = SSD;
% Add Algorithm
Algorithm_string = '21A Measured';
Algorithm = cell(size(GoldenBeam_Calculated_table,1),1);
for i = 1:size(GoldenBeam_Calculated_table,1)
    Algorithm{i} = Algorithm_string;
end
GoldenBeam_Calculated_table.Algorithm = Algorithm;

%%%%%%% normalize and shift the PDDs
% set the normalization and shift parameters
GridSize = 0.1;
Smoothing = 'linear';
Shift_location = 'R50';
%TODO select position by energy
Position = 5.0;
disp('calculated Golden Beam Data');
% select the PDDS 
PDD_Index = find(strcmp(GoldenBeam_Calculated_table.Type,'PDD'));
for i = 1:length(PDD_Index)
    Depth = cell2mat(GoldenBeam_Calculated_table{PDD_Index(i),'depth'});
    Dose = cell2mat(GoldenBeam_Calculated_table{PDD_Index(i),'dose'});
    [ShiftedDepth, NormDose, Shift] = Normalize_PDD(Depth,Dose,GridSize,Smoothing,Shift_location,Position);
    GoldenBeam_Calculated_table{PDD_Index(i),'depth'} = {ShiftedDepth};
    GoldenBeam_Calculated_table{PDD_Index(i),'dose'} = {NormDose};
    FieldSizeString = cellstr(GoldenBeam_Calculated_table{PDD_Index(i),'FieldSize'});
    disp(['Field Size = ' FieldSizeString ' Shift = ' num2str(Shift)]);
end

%% Save the tables
save('\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning\electron_data.mat','*table');
tables.BeamConfig_table = BeamConfig_table;
tables.Measured_21A_table = Measured_21A_table;
tables.Measured_21D_table = Measured_21D_table;
tables.GoldenBeam_table = GoldenBeam_Calculated_table;
tables.Calculated_21A_table = Calculated_21A_table;
