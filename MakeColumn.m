function NewColumn = MakeColumn(OldTable, ColumnDefinition)
% NewColumn = MakeColumn(OldTable, ColumnDefinition)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Create a new string column from current columns based on functions
%    provided. 
%    structure tables according to the parameters in the Parameters cell
%    array. Eacjh string in parameters must be a variable in every table in
%    the tables structure.
%    The output is indexes that match up the common parameters from each
%    data set.
%
%   Input Arguments
%     OldTable         =  A Table containing the required columns
%
%     ColumnDefinition =  A structure containing:
%        Elements  = A Cell array of strings containing the names of the
%                    table columns to be used.         
%        Functions = A Cell array of function handles describing the
%                   function to be applied to the matching column in
%                   Elements. 
%      e.g.:
%       ColumnDefinition.Elements = {'Energy';'Applicator';'FieldSize'};
%       ColumnDefinition.Functions = {...
%     @(x) strcat(x{:,1}, {',  '}); ...
%     @(x) strcat(cellfun(@num2str,num2cell(x{:,1}),'UniformOutput',false), {' cm Applicator,  '}); ...
%     @(x) strcat(x{:,1}, {' Insert'})};
%
%   Output Arguments
%     NewColumn   =   A Cell array of strings with the same length as the
%                     OldTable.  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define a Curve Label Title (This applies to individual data curves and is used to label plots and excel columns)

%% Check in input arguments

% Check the number of input arguments (Minimum 2 Maximum 2)
narginchk(2, 2)

NumElements = max(size(ColumnDefinition.Elements));
Strings = cell(size(OldTable,1),NumElements);
NewColumn = cellstr(blanks(size(OldTable,1))');
for k = 1:NumElements
    Strings(:,k) = ColumnDefinition.Functions{k}(OldTable(:,ColumnDefinition.Elements(k)));
    NewColumn = strcat(NewColumn, Strings(:,k));
end
NewColumn = strtrim(NewColumn);
