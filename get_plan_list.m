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
    'Patient',{},'PatientID',{},'Plan_Time',{},'name',{},'plan_name',{},...
    'plan_description',{},'energy',[],'applicator',{},'isocentre',[],'MU',[]);

% Set the correct dimensions
Dose_files(size(Plan_files,1)).name ={};

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
    [plan_data, Dose_file] = read_plan_data(Plan_files{i});
    %
    %% Look for one non Zero MU field
    % FIX ME  There is not test for an empty file return
    MU_list =[plan_data.Beams.MUs]';
    testField = find(MU_list ~= 0);
    if length(testField)>1
        message = 'More than 1 non-zero MU field. Using 1st field';
        warning('Get_plan_list:Invalidplan',message);
        testField = testField(1);
    end
    %% test the plan data
    %
    if (not(isempty(plan_data) & isempty(Dose_file)))  % Test that both Plan and Dose information retrieved
        %% Save the Plan info of interest from the first beam
        %
        Dose_files(index).Patient = plan_data.Patient_name;
        Dose_files(index).PatientID = plan_data.Patient_ID;
        Dose_files(index).Plan_Time = plan_data.Plan_Time;
        Dose_files(index).name = Dose_file;
        Dose_files(index).plan_file = Plan_files{i};
        Dose_files(index).plan_name = plan_data.Plan_name;
        Dose_files(index).plan_description = plan_data.Plan_description;
        Dose_files(index).FieldName = plan_data.Beams(testField).Field_Name;
        Dose_files(index).energy = plan_data.Beams(testField).Beam_Energy;
        Dose_files(index).isocentre = plan_data.Beams(testField).Isocentre;
        Dose_files(index).MU = plan_data.Beams(testField).MUs;
        Dose_files(index).Fractions = plan_data.Fractions;
        Dose_files(index).Gantry_Angle = plan_data.Beams(testField).Gantry_Angle;
        Dose_files(index).Collimator_angle = plan_data.Beams(testField).Collimator_angle;
        Dose_files(index).Couch_angle = plan_data.Beams(testField).Couch_angle;
        Dose_files(index).SSD = plan_data.Beams(testField).SSD;
        try
            Dose_files(index).applicator = str2num(plan_data.Beams(testField).Applicator(2:end)); %#ok<ST2NM>
            Dose_files(index).insertsize = max(plan_data.Beams(testField).InsertShape(:));
        catch  %#ok<CTCH>
            % if no applicator do not create this applicator field
            % create a field size parameter
        end
        try
            x_jaws = plan_data.Beams(testField).x_jaw;
            y_jaws = plan_data.Beams(testField).y_jaw;
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

