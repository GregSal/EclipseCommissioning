function [scan_info, data]= read_scan(fid)
% This function reads header info and data for a single scan from a 
% Welhoffer text file

%% Initialize File Structure Parameters
% File dlimeter is semicolon
delimiter = ';';
HeaderRows = 15;
% Set header format consisting of two strings seperated by a semicolon
HeaderFormat = '%s%s%*s%*s%*s%*s%*[^\n\r]';
% Set Variable names format consisting of 6 strings seperated by semicolons
VariableSpec = '%s%s%s%s%s%s%*[^\n\r]';
% Set the Data format cosisting of 6 numeric values seperated by semicolons
DataformatSpec = '%f%f%f%f%f%f%*[^\n\r]';


%% Read Header.
% This imports the header data into a cell array
HeaderArray = textscan(fid, HeaderFormat, HeaderRows, 'Delimiter', delimiter);
ParameterDescription = HeaderArray{1};
ParameterValues = HeaderArray{2};

% Check for end of file
if isempty(HeaderArray{1})
    scan_info = [];
    data = [];
    return
end
%% Get Energy
SearchParameter = 'Energy';
ParameterIndex = strncmp(ParameterDescription, SearchParameter,length(SearchParameter));
Value =  ParameterValues{ParameterIndex};

% test for no beam description
%TODO Test for multiple Values
if isempty(Value)
        scan_info.energy = 'Unidentified';
else
    scan_info.energy = Value;
end

%TODO add this for electron scans
% %% Get Applicator
% fseek(fid, file_pointer, 'bof');
% if (strcmp(scan_data.beam_type,'Electron'))
%     text_line = get_parameter_line(fid,'Applicator');
%     % test for no beam description
%     if isempty(text_line)
%             scan_data.applicator = default.applicator;
%     else
%         a = textscan(text_line,'%*s %d');
%         scan_data.applicator = ['A' int2str(a{1})];
%     end
% end

%% Get SSD
SearchParameter = 'SSD';
ParameterIndex = strncmp(ParameterDescription, SearchParameter,length(SearchParameter));
Value =  ParameterValues{ParameterIndex};

% test for no beam description
%TODO Test for multiple Values
if isempty(Value)
        scan_info.SSD = 'Unidentified';
else
    scan_info.SSD = Value;
end
%% Get Field Size
SearchParameter = 'Field size';
ParameterIndex = strncmp(ParameterDescription, SearchParameter,length(SearchParameter));
Value =  ParameterValues{ParameterIndex};

% test for no beam description
%TODO Test for multiple Values
if isempty(Value)
        scan_info.field_size = 'Unidentified';
else
    scan_info.field_size = Value;
end

%% Get Curve Type
SearchParameter = 'Scan type';
ParameterIndex = strncmp(ParameterDescription, SearchParameter,length(SearchParameter));
Value =  ParameterValues{ParameterIndex};

% test for no beam description
%TODO Test for multiple Values
if isempty(Value)
        scan_info.CurveType = 'Unidentified';
else
    scan_info.CurveType = Value;
end

%% Get Treatment Unit
SearchParameter = 'Radiation device';
ParameterIndex = strncmp(ParameterDescription, SearchParameter,length(SearchParameter));
Value =  ParameterValues{ParameterIndex};

% test for no beam description
%TODO Test for multiple Values
if isempty(Value)
        scan_info.TreatmentUnit = 'Unidentified';
else
    scan_info.TreatmentUnit = Value;
end

%% Read Variable Names
Variables = textscan(fid, VariableSpec, 1, 'Delimiter', delimiter); %#ok<NASGU>

% read a blank line of text from the file to line up to read data
fgetl(fid);

%% Read Data
% this will read until it encounters an error, which will occur when it
% encounters the date line: 07/08/2014 1:24:46 PM the 07/08 will not fit
% with the format and it will stop.
% The last entry to the data is from the next data header if there are more
% data sets in the file and needs to be removed
RawData = textscan(fid, DataformatSpec, 'Delimiter', delimiter);

% Check to see if extra point exists in the first column and remove remove
% if nessesary
FirstColumn =RawData{1};
SecondColumn =RawData{2};
if length(FirstColumn) > length(SecondColumn)
    FirstColumn = FirstColumn(1:end-1);
    RawData{1} = FirstColumn;
end

% Convert data to matrix
data = cell2mat(RawData);

% Put Data in structured array
% data = struct;
% data = setfield(data,strtrim(char(Variables{1})),FirstColumn);
% data = setfield(data,strtrim(char(Variables{2})),RawData{2});
% data.(strtrim(char(Variables{2}))) =RawData{2};

%% Align to start of next data set
% textscan begins to read the next header before stopping
% This resets the file pointer to the beginning of the header
file_pointer = ftell(fid);
fseek(fid, file_pointer-1, 'bof');
% text_line=fgetl(fileID);

end