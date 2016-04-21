function [Plan_data, Dose_file] = read_plan_data(plan_file)
% function [Plan_data, Dose_file] = read_plan_data(plan_file)
% This function reads Plan info from a DICOM RT Plan file and looks for a
% coresponding Dose file the Dose file name must be in the form RD*.dcm
% plan_file must be the full path to the file


load Months Months; % List of month names

%% Test to see if plan_file is a valid DICOM file
try
    % Read the Plan DICOM Header
    Plan_Info = dicominfo(plan_file);
catch ME
    %If not valid, return empty variables
    Plan_data = [];
    Dose_file = [];
    return
end

%% Test to see if plan_file is a valid DICOM Plan file
try
    % Read The Plan Name
    Plan_data.Plan_name = Plan_Info.RTPlanLabel;
catch ME  %#ok<*NASGU>
    %If not valid, return empty variables
    Plan_data = [];
    Dose_file = [];
    return
end

%
%% If a dose file is requested Look for the corresponding Dose file
%
if (nargout ==2)    % Plan Data and Dose Data Desired
    % initialize Dose_file so that it will return empty if search fails
    Dose_file = [];
    % get the path of the current plan file
    [Plan_path, Plan_name, ext] = fileparts(plan_file);  %#ok<ASGLU>
    % look for dose files in the plan directory and subdirectories
    Dose_files = dir_scan(Plan_path, 'RD*.dcm');
    %
    %% Examine all dose files to find one that corresponds to the plan file
    %
    for i=1:size(Dose_files,1)
        %% Test to see if dose_file is a valid DICOM file
        %
        try
            Dose_Info = dicominfo(Dose_files{i});
        catch ME
            %If not valid, try the next Dose file name
            continue
        end
        %
        % test for RTDOSE modality
        is_dose_file = strcmp(Dose_Info.Modality,'RTDOSE');
        if (not(is_dose_file))
            continue;
        end
        % Get the Plan ID from the Dose DICOM file
        Test_Plan_file_ID = Dose_Info.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
        % Test to see if this dose file coresponds to the plan file
        if strcmp(Test_Plan_file_ID,Plan_Info.SOPInstanceUID)
            % If it matches select this file name and stop scanning dose files
            Dose_file = Dose_files{i};
            break
        end
    end
    
elseif (nargout ~=1)  % Check for invalid # uptput arguments
    return
end

%

%% Get patient and Plan ID etc.
%
%
try
    Plan_data.Patient_name = [Plan_Info.PatientName.FamilyName ', ' Plan_Info.PatientName.GivenName];
    %Plan_data.Patient_name = [Plan_Info.PatientName.FamilyName]; % if given name is missing
catch ME
    %If not valid, return empty variables
    Plan_data.Patient_name = '';
end
try
Plan_data.Patient_ID = Plan_Info.PatientID;
catch ME
    %If not valid, return empty variables
    Plan_data.Patient_ID = '';
end
try
Plan_data.Plan_date = [Months{str2num(Plan_Info.RTPlanDate(5:6))} ' ' Plan_Info.RTPlanDate(7:8) ' ' Plan_Info.RTPlanDate(1:4)]; %#ok<ST2NM>
catch ME
    %If not valid, return empty variables
    Plan_data.Plan_date = '';
end
try
Plan_data.Plan_Time = [Plan_Info.RTPlanTime(1:2) ':' Plan_Info.RTPlanTime(3:4) ':' Plan_Info.RTPlanTime(5:6)];
catch ME
    %If not valid, return empty variables
    Plan_data.Plan_Time = '';
end
try
Plan_data.Patient_Orientation = Plan_Info.PatientSetupSequence.Item_1.PatientPosition;
catch ME
    %If not valid, return empty variables
    Plan_data.Patient_Orientation = '';
end
try
Plan_data.Plan_Name = Plan_Info.RTPlanLabel;
catch ME
    %If not valid, return empty variables
    Plan_data.Plan_Name = '';
end
try
    Plan_data.Plan_description = Plan_Info.RTPlanName;
catch ME
    %If not valid, return empty variables
    Plan_data.Plan_description = '';
end
try
Plan_data.Fractions = Plan_Info.FractionGroupSequence.Item_1.NumberOfFractionsPlanned;
catch ME
    %If not valid, return empty variables
    Plan_data.Fractions = 1;
end
try
Plan_data.StudyUID = Plan_Info.StudyInstanceUID;
catch ME
    %If not valid, return empty variables
    Plan_data.StudyUID = '';
end
try
Plan_data.SeriesUID = Plan_Info.SeriesInstanceUID;
catch ME
    %If not valid, return empty variables
    Plan_data.SeriesUID = '';
end
try
Plan_data.StructureUID = Plan_Info.ReferencedStructureSetSequence.Item_1.ReferencedSOPInstanceUID;
catch ME
    %If not valid, return empty variables
    Plan_data.StructureUID = '';
end

%% Get Beam data
Plan_data.Number_of_Beams = Plan_Info.FractionGroupSequence.Item_1.NumberOfBeams;
BeamIndex = zeros(Plan_data.Number_of_Beams,1);
for i = 1:Plan_data.Number_of_Beams
    
    %% Get Basic BeamParameters
    Beam_data = Plan_Info.BeamSequence.(['Item_' int2str(i)]);
    % Identify Beam for cross referenceing MUs
    BeamIndex(i) = Beam_data.BeamNumber;
    
    Plan_data.Beams(i).Field_Name = Beam_data.BeamName;
    Plan_data.Beams(i).Treatment_machine = Beam_data.TreatmentMachineName;
    
    Plan_data.Beams(i).Beam_Energy = Beam_data.ControlPointSequence.Item_1.NominalBeamEnergy;
    
    Plan_data.Beams(i).Gantry_Angle = Beam_data.ControlPointSequence.Item_1.GantryAngle;
    Plan_data.Beams(i).Collimator_angle = Beam_data.ControlPointSequence.Item_1.BeamLimitingDeviceAngle;
    Plan_data.Beams(i).Couch_angle = 360 - Beam_data.ControlPointSequence.Item_1.PatientSupportAngle;
    
    Plan_data.Beams(i).x_jaw = Beam_data.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions./10;
    Plan_data.Beams(i).y_jaw = Beam_data.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions./10;
    Plan_data.Beams(i).Radiation_Type = Beam_data.RadiationType;
    
    Plan_data.Beams(i).Bolus = Beam_data.NumberOfBoli;
    Plan_data.Beams(i).Isocentre = Beam_data.ControlPointSequence.Item_1.IsocenterPosition';
    try
        Plan_data.Beams(i).SSD = Beam_data.ControlPointSequence.Item_1.SourceToSurfaceDistance;
        catch ME
         %If not valid, return empty variables
         Plan_data.Beams(i).SSD = '';
    end
    %% Get Electron Plan Data
    if (strcmp(Plan_data.Beams(i).Radiation_Type,'ELECTRON'))  % If the Radiation Type is Electrons
        % Get the applicator
        Plan_data.Beams(i).Applicator = Plan_Info.BeamSequence.(['Item_' int2str(i)]).ApplicatorSequence.Item_1.ApplicatorID;
        % Get the electron insert shape (a single block)
        if (isfield(Beam_data, 'BlockSequence')) % test for presence of Electron insert
            Shape =  Beam_data.BlockSequence.Item_1.BlockData./10;
            points = size(Shape);
            Plan_data.Beams(i).InsertShape=reshape(Shape,points(1)/2,2);
        end
    else
        %% Get MLC Data
        % Check for MLCs

if( Beam_data.NumberOfControlPoints == 2)
    % Not intended for IMRT or field-in-field plans
    if (isfield(Beam_data.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence, 'Item_3'))
    % check for presence of MLCs
    Plan_data.Beams(i).MLC = Beam_data.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_3.LeafJawPositions;
    Plan_data.Beams(i).mlc_index = [-19.5:1:-10.5 -9.75:.5:9.75 10.5:1:19.5 19.5:-1:10.5 9.75:-.5:-9.75 -10.5:-1:-19.5]';
    end
end
 
 
 %% Get Wedge data
 % Check for wedges
        wedges = Beam_data.NumberOfWedges;
        if wedges >0
            Plan_data.Beams(i).wedge =  Beam_data.WedgeSequence.Item_1.WedgeID;
        end
        
        %% Get Cerobend Block data
        % Check for blocks
        Blocks = Beam_data.NumberOfBlocks;
        if Blocks >0
            for B = 1:Blocks
                Block_info =  Beam_data.BlockSequence.(['Item_' int2str(B)]);
                Plan_data.Beams(i).block(B).Name =  Block_info.BlockName;
                Plan_data.Beams(i).block(B).Type =  Block_info.BlockType;
                Plan_data.Beams(i).block(B).Tray =  Block_info.BlockTrayID;
                Shape =  Block_info.BlockData./10;
                points = size(Shape);
                Plan_data.Beams(i).block(B).Shape=reshape(Shape,points(1)/2,2);
            end
        end
    end
end
%% Get MU Data
% Loop to extract MUs
MU_Index = zeros(Plan_data.Number_of_Beams,1);
MU = zeros(Plan_data.Number_of_Beams,1);
%Dose = zeros(Plan_data.Number_of_Beams);
for i = 1:Plan_data.Number_of_Beams
    MU_data = Plan_Info.FractionGroupSequence.Item_1.ReferencedBeamSequence.(['Item_' int2str(i)]);
    MU_Index(i) = MU_data.ReferencedBeamNumber;
    %Plan_data.Beams(i).Target_Dose_Fraction = Plan_Info.FractionGroupSequence.Item_1.ReferencedBeamSequence.(['Item_' int2str(i)]).BeamDose;
    % Get MUs
    try
        MU(i) = MU_data.BeamMeterset;
    catch ME
        %If not valid, return empty variables
        MU(i) = 0;
    end
    % I don't know how to use these, but adding them here for the record
    %     Dose.value(i) = MU_data.BeamDose;
    %     Dose.reference(i) = MU_data.BeamDoseSpecificationPoint;
end
%% Match MU data to Plan Data
for i=1:length(MU_Index)
    k = MU_Index(i)==BeamIndex;
    Plan_data.Beams(k).MUs = MU(i);
end
end
