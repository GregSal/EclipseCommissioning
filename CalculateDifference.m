function dif_data = CalculateDifference(Compare_on, group_data, X, Y)
% dif_data = CalculateDifference(Compare_on, group_data, X, Y)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Create Write X and Y data from group_data to an Excel spreadsheet
%
%   Input Arguments
%     Compare_on    =  The name of the variable defining which data is
%                      subtracted from which. 
%     group         =  A structure describing the data.  
%                      Required fields are:
%         Directory =  The directory to save the excel file in.  It will be
%                      created if it does not already exist. 
%         ExcelName =  The name of the excel file including the '.xls'
%         SheetName =  The name for the worksheet.  If it arteady exists it
%                      will be overwritten. 
%         Title     =  A header title to go at the top of the spreadsheet.
%
%     group_data    =  A Table containing variables:
%       {Compare_on}=  The Variable defining which data is subtracted from
%       {X.Name}    =  The variable contining the X data (not subtracted)
%       {Y.Name}    =  The variable contining the data to be subtracted.
%       'DataLabel' =  A string defining each data setVariable 
%                      and X and Y variables with names given by 
%                      X.Name and Y.Name  
%     X & Y         =  Structure containing:
%        Name  =       The name of the X & Y variables in group_data
%        Label   =    A string label for that variable. 
%
%   Output Arguments
%     dif_data    =  A table containing group_data and the subtracted data.
%                    The table contains the variables:
%       {Compare_on}=  The Variable defining which data is subtracted from.
%                      For the subtracted data the value is 'Difference'.
%       {X.Name}    =  The shortest of the {X.Name} arrays from group_data
%       {Y.Name}    =  The difference betweenvariable contining the data to be subtracted.
%       'DataLabel' =  A string defining each data set.   
%                      For the subtracted data the value is:
%                       {DataLabel #1} - {DataLabel #2}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Calculate Dose Differences
    DifGrp.Name = char(Compare_on);
    DifGrp.Types = unique(group_data{:,DifGrp.Name});
    for n=1:size(DifGrp.Types,1)
        Index{n} = find(strcmp(DifGrp.Types{n},group_data{:,DifGrp.Name}));
    end
    
    % Define the dif_data table using the selected variables from group_data
    dif_data = group_data(:,{DifGrp.Name, 'DataLabel', X.Name, Y.Name});
    
    % For each data pair calculate the difference
    Index2 = Index{2};
    for j = 1:size(Index2,1)
        Label2 = group_data{Index2(j),'DataLabel'};
        data2 = cell2mat(group_data{Index2(j),Y.Name});
        X2 = cell2mat(group_data{Index2(j),X.Name});
        Index1 = Index{1};
        for k = 1:size(Index1,1)
            Label1 = group_data{Index1(k),'DataLabel'};
            data1 = cell2mat(group_data{Index1(k),Y.Name});
            X1 = cell2mat(group_data{Index1(k),X.Name});
            
            % Select interpolation range
            step = mean(diff(X1));
            X_limit = min(max(abs(X1)),max(abs(X2)));
            X_max = floor(floor(X_limit/step)*step);
            % determine if X range sould start at 0 (PDD) or at -Xmax (Profile
            X_mid = (max(X1) - min(X1))/max(X1);
            if X_mid < 0.2
                X_min = 0;
            else
                X_min = -X_max;
            end
            X_data = X_min:step:X_max;
            data1_int = interp1(X1,data1,X_data);
            data2_int = interp1(X2,data2,X_data);

            % Assign to dif structure and merge with table
            dif.(X.Name) =X_data';
            dif.(Y.Name) = (data1_int - data2_int)';
            dif.DataLabel = strcat(Label1, {' - '}, Label2);
            dif.(DifGrp.Name) = 'Difference';    
            dif_data = [dif_data; struct2table(dif,'AsArray',true)];
        end
    end