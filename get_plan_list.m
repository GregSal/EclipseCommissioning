function Dose_files=get_plan_list(DICOM_path)
% function Dose_files=get_dose_list(DICOM_path)
% This function generates a list of Plan and coresponding dose files within
% the given directory and it's subdirectories.  It extracts only a small
% portion of the plan data and assumes only one field per plan
%
% TODO This is a custom version of Get_dose_list to identify the key fields for each plan make more general
%
% it uses the functions:
% dir_scan and read_plan_data

%% Get list of dose files

% define the DICOM Plan search string
scan_string = 'RP*.dcm';
outputType = 'flat';
% Scan the directory and subdirectories for this search string
Plan_files = dir_scan(DICOM_path, scan_string,outputType);

if isempty(Plan_files)
    message = ('Warning: no files found');
    warning(message);
    % Return an empty list
    Dose_files = {};
    return
end


%% Predefine the Dose_files structure
%
% Define the structure
Dose_files = struct(...
    'Patient',{},'PatientID',{},'Plan_Time',{},'dose_file',{},'plan_file',{},'plan_name',{},...
    'plan_description',{},'energy',[],'applicator',{},'isocentre',[],'MU',[]);

% Set the minimum number of expected dose files
Dose_files(size(Plan_files,1)).Patient ={};

% Flip the variable so that it is the same as Plan_files
Dose_files = Dose_files';

% initialize Dose_files index
index=1;
%
%% Examine all plan files found
%
for i=1:size(Plan_files,1)  % Examine all plan files
    %
    %% Get plan data and Dose File
    %
    [plan_data, Dose_file_list, Beam_Reference] = read_plan_data(Plan_files{i});
    %
    %% Check that dose files were found
    if (isempty(plan_data) || isempty(Dose_file_list))
        message = 'No Dose data files found';
        warning('Get_plan_list:InvalidDoseFile',message);
        % Return an empty list
        Dose_files = {};
        return
    end
    %% Save the relevant Plan info for each dose file
    %
    for j=1:size(Dose_file_list,2)
        %% Save the General Plan info
        %
        Dose_files(index).Patient = plan_data.Patient_name;
        Dose_files(index).PatientID = plan_data.Patient_ID;
        Dose_files(index).Plan_Time = plan_data.Plan_Time;
        Dose_files(index).dose_file = Dose_file_list{j};
        Dose_files(index).plan_file = Plan_files{i};
        Dose_files(index).plan_name = plan_data.Plan_name;
        Dose_files(index).plan_description = plan_data.Plan_description;
        % Find the matching Beam Data for the dose file
        Field_Number =[plan_data.Beams.Field_Number]';
        MatchField = find(Field_Number == Beam_Reference(j));
        Dose_files(index).FieldName = plan_data.Beams(MatchField).Field_Name;
        Dose_files(index).energy = plan_data.Beams(MatchField).Beam_Energy;
        Dose_files(index).isocentre = plan_data.Beams(MatchField).Isocentre;
        Dose_files(index).MU = plan_data.Beams(MatchField).MUs;
        Dose_files(index).Fractions = plan_data.Fractions;
        Dose_files(index).Gantry_Angle = plan_data.Beams(MatchField).Gantry_Angle;
        Dose_files(index).Collimator_angle = plan_data.Beams(MatchField).Collimator_angle;
        Dose_files(index).Couch_angle = plan_data.Beams(MatchField).Couch_angle;
        Dose_files(index).SSD = plan_data.Beams(MatchField).SSD;
        % Add electron applicator and insert data if available
        try
            Dose_files(index).applicator = str2num(plan_data.Beams(MatchField).Applicator(2:end)); %#ok<ST2NM>
            Dose_files(index).insertsize = plan_data.Beams(MatchField).InsertShape;
            Dose_files(index).insertname = plan_data.Beams(MatchField).InsertName;
        catch  %#ok<CTCH>
            % if no applicator do not create this applicator field
        end
        % create a field size parameter
        try
            x_jaws = plan_data.Beams(MatchField).x_jaw;
            y_jaws = plan_data.Beams(MatchField).y_jaw;
            if (x_jaws(2) == -x_jaws(1))
                X_jaw_string = num2str(x_jaws(2)-x_jaws(1),'%4.1f');
            else
                X_jaw_string = ['(' num2str(-x_jaws(1),'%4.1f') ',' ...
                    num2str(x_jaws(2),'%4.1f') ')'];
            end
            if (y_jaws(2) == -y_jaws(1))
                Y_jaw_string = num2str(y_jaws(2)-y_jaws(1),'%4.1f');
            else
                Y_jaw_string = ['(' num2str(-y_jaws(1),'%4.1f') ',' ...
                    num2str(y_jaws(2),'%4.1f') ')'];
            end
            Dose_files(index).FieldSize = [X_jaw_string ' x ' Y_jaw_string];
            
        catch  %#ok<CTCH>
            % if this fails don't create a field size parameter
        end
        
        index=index+1;
    end
end
%
%% Get rid of blank file references
%
Dose_files(index:end) = [];
end

