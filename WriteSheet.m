function WriteSheet(group, group_data, X, Y)
% WriteSheet(group, group_data, X, Y)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Create Write X and Y data from group_data to an Excel spreadsheet
%
%   Input Arguments
%     group         =  A structure describing the data.  
%                      Required fields are:
%         Directory =  The directory to save the excel file in.  It will be
%                      created if it does not already exist. 
%         ExcelName =  The name of the excel file including the '.xls'
%         SheetName =  The name for the worksheet.  If it arteady exists it
%                      will be overwritten. 
%         Title     =  A header title to go at the top of the spreadsheet.
%
%     group_data    =  A Table containing a 'Label' Variable and X and Y
%                      variables with names given by X.Name and Y.Name  
%     X & Y         =  Structure containing:
%        Name  =       The name of the X & Y variables in group_data
%        Label   =    A string label for that variable. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Pad the data
Length =cellfun(@(x) size(x,1), group_data{:,X.Name})';
pad =   num2cell(max(Length)- Length);
extension = cellfun(@(x) NaN(x,1), pad, 'UniformOutput',false);

%Format the excel data
Header{1,1} = group.Title;
for i = 1:height(group_data)
     data(:,2*i-1) = [cell2mat(group_data{i,X.Name});extension{i}];
     Header{2,2*i-1} = char(group_data{i,'DataLabel'});
     Header{3,2*i-1} = X.Label;
     data(:,2*i) = [cell2mat(group_data{i,Y.Name});extension{i}];
     Header{3,2*i} = Y.Label;
end
excel_data = [Header;num2cell(data)];
mkdir(group.Directory);
filename = [group.Directory '\' group.ExcelName];
xlswrite(filename,excel_data,group.SheetName);