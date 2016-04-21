
function [curve_info, data] = read_curve(FileName)
% [scan_info, data]= read_curve(FileName,Path)
%________________________________________________________________________
% Created by Greg Salomons
%    read_curve Reads a curve a text file containing a PDDs from
%    beam configuration data and returns it as a data structure. Importing
%    profiles will be added when working with Photon models
%
%   Output Arguments
%     scan_info     =  A Structure variable containing data imported
%                         from the text file.  It contains the following
%                         fields: 
%                         FileName         The name of the text file
%                         Algorithm        The Algorithm used for the
%                                          calculations  
%                         Applicator       The Applicator ID (electrons
%                                          only) extracted from the file's
%                                          header 
%                         Machine          The treatment machine in beam
%                                          configuration that the
%                                          calculations were done for 
%                         Energy           The Beam Energy extracted from  
%                                          the file's header
%                         RadiationType    Either electrons or photons
%                         DataType         A description of the curve (PDD
%                                          or Profile)
%                         X_Label          A description of the X units
%                         Data_Label       A description of the Y units
%                         X1               The (x) coordinates for the
%                                          calculated PDD data   
%                         Y1               The relative dose for the
%                                          calculated PDD data
%                         X2               The (x) coordinates for the
%                                          measured PDD data   
%                         Y2               The relative dose for the
%                                          measured PDD data

% For future when analyzing photon models:
%                         Type             PDD or Profile depending on the 
%                                          type of data curve
%                         Distance         The distance (x) coordinates of
%                                          a profile scan. 
%   Input Arguments
%     Path          =  The full directory path where the file is found 
%     FileName      =  The name of the data textfile to be imported
%                          The file must have 14 header lines where label
%                          and value are separated by a colon, a comman
%                          delimited curve label line indicating the
%                          calculated and measured curves and three columns
%                          of floating point data comma seperated e.g.:  
%                            0.000,         ,    0.860
%                            0.030,         ,    0.861
%                            0.060,         ,    0.862
%                            0.080,         ,    0.863
%                            0.090,         ,    0.864
%                            0.110,         ,    0.866
%                            0.125,    0.855,         
%                            0.150,         ,    0.869
%                            0.160,         ,    0.870
%________________________________________________________________________

%% open the file
% TODO include error checking
% FullFile = [Path '\' FileName];
FID = fopen(FileName);

%% Initialize File Structure Parameters
% Header delimeter is colon
delimiter = ':';
HeaderRows = 14;
% Set header format consisting of two strings seperated by a semicolon
HeaderFormat = '%s%s%*[^\n\r]';

%% Initialize the Data Variable
curve_info.FileName = FileName;

%% Read Header.
% This imports the header data into a cell array
HeaderArray = textscan(FID, HeaderFormat, HeaderRows, 'Delimiter', delimiter);
ParameterDescription = HeaderArray{1};
ParameterValues = HeaderArray{2};

% Check for end of file
if isempty(HeaderArray{1})
    curve_info = [];
    data = [];
    return
end

%% Extract paramters
%Energy
Value = GetParameter(ParameterDescription,ParameterValues,'energy');
curve_info.energy = Value;

%Applicator
Value = GetParameter(ParameterDescription,ParameterValues,'add on:');
curve_info.Applicator = Value;

%Algorithm
Value = GetParameter(ParameterDescription,ParameterValues,'algorithm:');
curve_info.Algorithm = Value;

%Machine
Value = GetParameter(ParameterDescription,ParameterValues,'machine:');
curve_info.Machine = Value;

%Electrons or Photons
Value = GetParameter(ParameterDescription,ParameterValues,'beam:');
curve_info.RadiationType = Value;

%Curve Type
Value = GetParameter(ParameterDescription,ParameterValues,'data:');
curve_info.DataType = Value;

%X Label
Value = GetParameter(ParameterDescription,ParameterValues,'row legend');
curve_info.X_Label = Value;

%Data Label
Value = GetParameter(ParameterDescription,ParameterValues,'data legend');
curve_info.Data_Label = Value;

%% Initialize File Structure Parameters
% Data delimeter is comma
delimiter = ',';
% Set Variable names format consisting of 3 strings seperated by commas
VariableSpec = '%s%s%s*[^\n\r]';
% Set the Data format cosisting of 6 numeric values seperated by semicolons
DataformatSpec = '%f%f%f%*[^\n\r]';

%% Read Variable Names
curve_info.Variables = textscan(FID, VariableSpec, 1, 'Delimiter', delimiter); 

%% Read Data
% this will read until it encounters an error, which will occur when it
% encounters the date line: 07/08/2014 1:24:46 PM the 07/08 will not fit
% with the format and it will stop.
% The last entry to the data is from the next data header if there are more
% data sets in the file and needs to be removed
RawData = textscan(FID, DataformatSpec, 'Delimiter', delimiter);

% Match the X data with the Y data in the second and third columns
FirstColumn =RawData{1};
SecondColumn =RawData{2};
ThirdColumn =RawData{3};
index1 = ~isnan(SecondColumn);
index2 = ~isnan(ThirdColumn);
data.X1 = FirstColumn(index1);
data.Y1 = SecondColumn(index1);
data.X2 = FirstColumn(index2);
data.Y2 = ThirdColumn(index2);

%% Close the file
fclose(FID);

end
function ParameterValue = GetParameter(Labels,Values,Parameter)
    %Value = GetParameter(ParameterDescription,ParameterValues,label)
    % Get Index
    % add colon to end of lable to ensure unique search
    Labels = cellfun(@(A) [A ':'],Labels,'UniformOutput', false);
    ParameterSearch = strfind(Labels, Parameter);
    index_ref = min(cell2mat(ParameterSearch));
    ParameterIndex = zeros(size(ParameterSearch));
    for i = 1:size(ParameterSearch,1)
        if ~isempty(ParameterSearch{i})
            ParameterIndex(i) = ParameterSearch{i} == index_ref;
        else
            ParameterIndex(i) = 0;
        end
    end
    ParameterIndex =  logical(ParameterIndex);
    ParameterValue =  Values{ParameterIndex};

    % test for no beam description
    if isempty(ParameterValue)
        ParameterValue = 'Unidentified';
    end
end
