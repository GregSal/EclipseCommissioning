function PlotTable = Match_Data (tables,parameters,select)
% MatchedIndex = Match_Data (tables,parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Match_Data generates an index which matches each of the tables in the
%    structure tables according to the parameters in the Parameters cell
%    array. Eacjh string in parameters must be a variable in every table in
%    the tables structure.
%    The output is indexes that match up the common parameters from each
%    data set.
%
%   Input Arguments
%     tables       =  A structure containing all tables to be matched. Each
%                     table should have an X and Y column which contain the
%                     data to be plotted.
%
%     parameters   =  A cell array of strings with the names of the
%                     variables to match
%
%   Output Arguments
%     MatchedIndex =   A NxM array of matching indecies for the tables
%                      where N is the number of dirferent matches found and
%                      M is the number of tables
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check inputs
%TODO verify that all fields in tables are of type table & parameters is a
%cell aray of strings, verify that each tables contains the variables
%listed in parameters, verify that all parameter variable are cell array
%strings

%% Load testing data
% load('\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning\matchtest.mat')

%% Get number of tables
TablesList = fieldnames(tables);
NumTables = size(TablesList,1);

NumParams = size(parameters(:),1);
NumSelect = size(select(:),1);
% for each table create a key variable by merging all of the parameters
key_list = cell(0);
select_index = cell(NumTables,1);
for i = 1:NumTables
    tables.(TablesList{i}).key = tables.(TablesList{i}).(parameters{1});
    for j=2:NumParams
        key_sub_string = tables.(TablesList{i}).(parameters{j});
        tables.(TablesList{i}).key = strcat(tables.(TablesList{i}).key, '--', key_sub_string);
    end
    keys = tables.(TablesList{i}).key;
    select_index{i} = ones(size(keys));
    % Select Data
    for k = 1:NumSelect
        select_var{k} = select{k}{1}; %#ok<AGROW>
        selected = strcmp(tables.(TablesList{i}){:,select{k}{1}},select{k}{2});
        select_index{i} = select_index{i}&selected;
    end
    key_list = [key_list; keys(select_index{i})];%#ok<AGROW>
end
unique_keys = unique(key_list);


%% Make index

NumPlots = size(unique_keys,1);
PlotTable = table();
PlotTableVariables = [{'key'} parameters select_var {'X','Y','Curve_label'}];
% key_index = cell(NumPlots,NumTables);
for i = 1:NumTables
    for j=1:NumPlots
        key_index = strcmp(tables.(TablesList{i}).key,unique_keys{j});
        Plot_index = key_index & select_index{i};
        PlotTable = [PlotTable; tables.(TablesList{i})(Plot_index, PlotTableVariables)];%#ok<AGROW>
    end
end
end
