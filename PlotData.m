function PlotData(group, group_data, X, Y,Compare_on)
% PlotData(group, all_data, X, Y, Compare_on)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Create a Plot of the group_data
%
%   Input Arguments
%     group         =  A structure describing the data.  
%                      Required fields are:
%         FieldSize  = A string containing the field size in the form:
%                              {X} x {Y}
%                           or {diameter} cm circle (not handled yet)
%         Title     =  A header title to go at the top of the spreadsheet.
%
%     group_data    =  A Table containing variables:
%       {Compare_on}=  The Variable defining which data is subtracted from
%                      For the subtracted data the value is 'Difference'.
%       {X.Name}    =  The variable contining the X data (not subtracted)
%       {Y.Name}    =  The variable contining the data to be subtracted.
%       'DataLabel' =  A string defining each data setVariable 
%                      and X and Y variables with names given by 
%                      X.Name and Y.Name  
%     X & Y         =  Structure containing:
%        Name  =       The name of the X & Y variables in group_data
%        Label   =     A string label for that variable. 
%     Compare_on    =  The name of the variable identifying difference data.
%                      difference data is indicated by 'Difference';
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% set plot parameters
colors = {'red','green','blue','cyan','magenta','yellow','black','white'};
% markers = {'+','o','*','.','x','s','d','^','v','>','<','p','h'};
% linestyles = {'-','--',':','-.'};

%% Look for difference data
difference_index = strcmp(group_data{:,Compare_on},'Difference');
difference_data = find(difference_index);
other_data = find(~difference_index);
if isempty(difference_data)
    NumPlots = 1;
    PlotDifference = false;
else
    NumPlots = 2;
    PlotDifference = true;
end

%% Select X and Y Range
%FIXME THis only works for Profiles
max_range = @(x) max(abs(x));
X_range = cellfun(max_range,group_data{other_data,X.Name});
Y_range = cellfun(max_range,group_data{other_data,Y.Name});

mid_range = @(x) (max(x) - min(x))/max(x);
X_mid = cellfun(mid_range,group_data{other_data,X.Name});
% determine the field size
expr = '^\s*(\d+)\s*[x]\s*(\d+)\s*$';
FieldSize = [str2double(regexprep(group.FieldSize,expr,'$1')), ...
             str2double(regexprep(group.FieldSize,expr,'$2'))];
% ApplicatorSize = group.Applicator;

%find a nice round number for the distance plot
RangeStep = ceil(max(FieldSize)/10/0.5)*0.5;

Y_max = ceil(max(Y_range(:)))+5;

% determine if X range sould start at 0 (PDD) or at -Xmax (Profile
X_max = ceil(min(X_range(:))/RangeStep)*RangeStep;
if mean(abs(X_mid)) < 1.2
    X_min = 0;
else
    X_min = -X_max;
end

%% Generate the figure
FigureTitle = group.Title;
f = figure('NumberTitle','off','Name',FigureTitle);

%% plot the full curves 
subplot(NumPlots,1,1);
for j=1:size(other_data,1)
    LegendName = char(group_data{other_data(j),'DataLabel'});
    X_data = cell2mat(group_data{other_data(j),X.Name});
    Y_Data = cell2mat(group_data{other_data(j),Y.Name});
    graph = plot(X_data,Y_Data,'DisplayName',LegendName);
    set(graph,'Color',colors{j},'LineWidth',2)
    hold on
end
    % Set axis limits
    ylim(gca,[0 Y_max]);
    set (gca,'YTick',0:10:Y_max);
    xlim(gca,[X_min X_max]);
    set (gca,'XTick',X_min:RangeStep:X_max);
    grid(gca,'minor')

    % Mark the zero line
    c = plot([0 0],ylim);
    set(c,'Color','black','LineWidth',2)

    % configure the graph
    xlabel(X.Label)
    ylabel(Y.Label)
    Title = FigureTitle;
    title(Title,'FontName','Arial','FontSize',16,'fontweight','b')
    legend('show')
    h = legend('show');
    %Remove the zero line from the legend
    h.String = h.String(1:end-1);
    

%% Plot the difference curves
if PlotDifference
    % Set Y Range
%     Y_dif_range = cellfun(max_range,all_data{difference_data,Y.Name});
%     Y_dif_limit = ceil(max(Y_dif_range(:)));
     Y_dif_limit = 3;
     Y_RangeStep = 0.5;
    for j=1:size(difference_data,1)
        subplot(NumPlots,1,2);
        LegendName = char(group_data{difference_data(j),'DataLabel'});
        X_data = cell2mat(group_data{difference_data(j),X.Name});
        Y_Data = cell2mat(group_data{difference_data(j),Y.Name});
        graph = plot(X_data,Y_Data,'DisplayName',LegendName);
        set(graph,'Color',colors{j},'LineWidth',2)
        hold on
    end
    % Set axis limits
%    ylim(gca,[-Y_dif_limit Y_dif_limit]);
%     set (gca,'YTick',-Y_dif_limit:Y_RangeStep:Y_dif_limit);
    xlim(gca,[X_min X_max]);
    set (gca,'XTick',X_min:RangeStep:X_max);
    grid(gca,'minor')
    
    % Mark the zero line
    c = plot([0 0],ylim);
    set(c,'Color','black','LineWidth',2)
    c = plot(xlim,[0 0]);
    set(c,'Color','black','LineWidth',2)

    % configure the graph
    set(graph,'Color',colors{j},'LineWidth',2)
    xlabel(X.Label)
    ylabel(Y.Label)
    Title = 'Difference';
    title(Title,'FontName','Arial','FontSize',12,'fontweight','b')
    legend('show')
    h = legend('show');
    %Remove the viritcal and horizontal zero lines from the legend
    h.String = h.String(1:end-2);

    % TODO add a textbox that shows text in an annotation column of group_data    
    % % Create textbox
    % annotation(f,'textbox', [0.16 0.33 0.4 0],...
    %         'String',{['50% distance error = ' ...
    %         num2str(DistanceError(1)*10,1) ' mm, ' ...
    %         num2str(DistanceError(2)*10,1) ' mm']}, ...
    %         'FontWeight','bold',...
    %         'FontSize',14,...
    %         'FitBoxToText','off',...
    %         'LineStyle','none');


% box(gca,'on');
% set(f, 'Units','inches')
% set(f, 'Position',[5 3 8 5])

end    


 
 %% Add distance error annotation
    

