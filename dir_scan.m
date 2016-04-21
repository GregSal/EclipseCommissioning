%% Directory Scan
% This function recursively scans a directory tree and produces a list of
% all files in that directory
%%
function file_list = dir_scan(varargin)
% function file_list = dir_scan(start_path, scan_string)
% function file_list = dir_scan(start_path, scan_string)
% function file_list = dir_scan(scan_string)
% function file_list = dir_scan()
% function file_list = dir_scan(..., output_type)
% This function scans a directory and its subdirectories for files which
% match scan_string (which may contain wild cards).
% file_list contains the full path to the files located.
% If no start path is given the user will be prompted for the start path.
% ouput type can be one of 'flat', 'array' or 'tree'
%

%%  Test input and output variables

% Define the minimum and maximum number of arguments allowed
minargsin = 0;
maxargsin = 3;

% Check the number of input arguments
narginchk(minargsin, maxargsin)


%% Check for file output type
% Checks to see if the last argument is the output type
% Types can be 'flat', 'array' or 'tree'

% Set the default output type
OutputType = 'flat'; % flat output is the default

% change the output type if the last argument starts with one of array,
% tree or flat or if these letters are the second in the argument (allows
% for extra spaces, commas etc)
if (nargin>0) % verify that there is at least one argument
    if ischar(varargin{end}),
        type = strtrim([varargin{end} '    ']); % Protect against short string.
        if strcmpi(type,'array') 
            OutputType = 'array'; % Cell array with 1 element for each directory
            narg = nargin-1;
         elseif strcmpi(type,'tree')
            OutputType = 'tree'; % tree output with file lists for subdirectories under their root directory
            narg = nargin-1;
        elseif strcmpi(type,'flat')
            OutputType = 'flat'; % flat output with all files in one list
            narg = nargin-1;
        else
            narg = nargin;  % the last argument is not output type
        end
    end
else
    narg = 0;
end

%% Set the directory according to the number of arguments

% narg is the number of arguments after any output type argument has been removed from the end

% If no arguments, prompt for the directory and look for all files
if narg == 0
    % Set the base path for directories to be selected
    Data_path = pwd; % use current directory
    start_path = uigetdir(Data_path,'Select the directory to scan');
    
    scan_string = '*.*';
end

% If one argument assume that it is the scan string and prompt for the directory
if narg == 1
    % Set the base path for directories to be selected
    Data_path = pwd; % use current directory
    start_path = uigetdir(Data_path,'Select the directory to scan');
    
    scan_string = varargin{1};
end

% if two arguments assign them to the path and scan string
if narg == 2
    start_path = varargin{1};
    scan_string = varargin{2};
end
%% Test the input Parameters

% Test that a valid path and scan string were supplied
if ~ischar(start_path)
    message = ('Warning: start_path is not a valid directory');
    warning(message);
    % Return an empty list
    file_list = {};
    return
end

if ~ischar(scan_string)
    message = ('Warning: scan_string is not a valid directory');
    warning(message);
    % Return an empty list
    file_list = {};
    return
end

%% Find all files in the start_path directory
% this scans all files and directories in the start path regardless of
% whether they match the scan string.  This is needed to identify
% subdirectories.

dirlist = dir(start_path);

%% Test that the directory is valid and contains files of the any type
if isempty(dirlist)
    % This test finds invalid paths because dir returns an empty string for invalid paths
    message = strcat('Warning: ',start_path,' is either empty or not a valid directory');
    warning(message);
    % Return an empty list
    file_list = {};
    return
end

%% Scan the directory

% combine the path with the scan_string
file_search = fullfile(start_path,scan_string);

files = dir(file_search);

%% Eliminate directories from the files list

% identify all non-directory files
file_index = not([files.isdir]);
files = files(file_index);

%% Create the list of full filenames from the current directory

% If files are found, create full path names for each filename found
if ~isempty(files)
    file_names = {files.name};
    Path_list = cellstr(repmat(start_path,size(file_names')));
    Current_file_list = cellfun(@fullfile,Path_list,file_names','UniformOutput',false);
else
    Current_file_list = {};
end

%% Place the files from the current directory into the complete file list

if (~isempty(Current_file_list))
    % Add the list of files found in the subdirectory to the list of
    % files found in the current directory
    if strncmpi(OutputType,'flat',1)
        % This produces a flat list with one element per file
        file_list = Current_file_list;
    elseif strncmpi(OutputType,'array',1)
        % This produces a cell array with one element per directory
        file_list(1) = {Current_file_list};
    elseif strncmpi(OutputType,'tree',1)
        % This produces a nested cell array with one level per directory
        file_list = Current_file_list;
    else
        % This should never be reached
        error('dir_scan:Flow control no file structure type was identified');
    end
else
    file_list = {};
end
        
        %% find all subdirectories of the current directory

% find all sub directories except the '.' and the '..' directories
names = {dirlist.name};
dir_index = [dirlist.isdir] & not(strcmp(names,'..')) & not(strcmp(names,'.'));

% create a list of directory names
dir_names = {dirlist(dir_index).name};

%% Scan all subdirectories by recursively calling dir_scan
if ~isempty(dir_names)
    %   For each directory in the list
    for i=1:length(dir_names)
        % Create a new path to that subdirectory
        sub_dir = fullfile(start_path,dir_names{i});
       
        % Look for the files in that subdirectory by recusively calling dir_scan
        sub_file_list = dir_scan(sub_dir, scan_string,OutputType);
        
        % if files are found in the subdirectory  add them to the full list
        % in the correct format
        if (~isempty(sub_file_list))
        % Add the list of files found in the subdirectory to the list of
        % files found in the current directory
        if strncmpi(OutputType,'flat',1) 
            % This produces a flat list with one element per file
            file_list = [file_list(:); sub_file_list];
        elseif strncmpi(OutputType,'array',1) 
            % This produces a cell array with one element per directory
              file_list =  horzcat(file_list, sub_file_list);   %#ok<AGROW>
          elseif strncmpi(OutputType,'tree',1) 
            % This produces a nested cell array with one level per directory
              ListLength = length(file_list);
              file_list(ListLength+1) = {sub_file_list};  
        else
            % This should never be reached
            error('dir_scan:Flow control no file structure type was identified');
        end

        end
    end
end
end

