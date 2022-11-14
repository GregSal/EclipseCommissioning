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
