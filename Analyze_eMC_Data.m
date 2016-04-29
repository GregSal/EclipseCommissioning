
%% Import Data
ImportedTables       = Import_eMC_Data();

% Extract data from structure
BeamConfig_table     = ImportedTables.BeamConfig_table;
Measured_21A_table   = ImportedTables.Measured_21A_table;
Measured_21D_table   = ImportedTables.Measured_21D_table;
GoldenBeam_table     = ImportedTables.GoldenBeam_table;
Calculated_21A_table = ImportedTables.Calculated_21A_table;

%TODO save imported data tables
%% Load Data
% load('\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning\electron_data.mat')
% % Match the data in the tables
% % Search for variables with 'table' in the name
% variables = who;
% table_index = cellfun(@(A) isempty(A),strfind(variables,'table'));
% table_variables = variables(table_index);

%TODO Add a sorting column
%% Select X & Y columns for PDDs and add Curve Labels
 
% 21D measured
Measured_21D_table.X = Measured_21D_table. Depth;
Measured_21D_table.Y = Measured_21D_table.Dose;
Curve_label_string = '21D Measured';
Curve_label = cell(size(Measured_21D_table,1),1);
for i = 1:size(Measured_21D_table,1)
    Curve_label{i} = Curve_label_string;
end
Measured_21D_table.Curve_label = Curve_label;

% 21A measured
Measured_21A_table.X = Measured_21A_table.Depth;
Measured_21A_table.Y = Measured_21A_table.Dose;
Curve_label_string = '21A Measured';
Curve_label = cell(size(Measured_21A_table,1),1);
for i = 1:size(Measured_21A_table,1)
    Curve_label{i} = Curve_label_string;
end
Measured_21A_table.Curve_label = Curve_label;

% BeamConfig 
% Data already has X and Y
AlgorithmText = BeamConfig_table.Algorithm;
DataSourceText = BeamConfig_table.DataLabel;
DataSourceText = strrep(DataSourceText, 'Calculat','Calculated');
BeamConfig_table.DataLabel = DataSourceText;
Curve_label = cell(size(BeamConfig_table,1),1);
for i = 1:size(DataSourceText,1)
    Curve_label{i} = ['BeamConfig '  AlgorithmText{i}(11:end)  ' ' DataSourceText{i}];
end
BeamConfig_table.Curve_label = Curve_label;
% Do not use the "Measured" data from BeamConfig
calcIndex = strcmp(BeamConfig_table.DataLabel,'Calculated');
BeamConfig_table = BeamConfig_table(calcIndex,:);

% Eclipse 21A Measured Model 
Calculated_21A_table.X = Calculated_21A_table.depth;
Calculated_21A_table.Y = Calculated_21A_table.dose;
Curve_label_string = 'Eclipse 21A Measured Model';
Curve_label = cell(size(Calculated_21A_table,1),1);
for i = 1:size(Calculated_21A_table,1)
    Curve_label{i} = Curve_label_string;
end
Calculated_21A_table.Curve_label = Curve_label;

% Golden Beam 
GoldenBeam_table.X = GoldenBeam_table.depth;
GoldenBeam_table.Y = GoldenBeam_table.dose;
Curve_label_string = 'Eclipse Golden Beam Model';
Curve_label = cell(size(GoldenBeam_table,1),1);
for i = 1:size(GoldenBeam_table,1)
    Curve_label{i} = Curve_label_string;
end
GoldenBeam_table.Curve_label = Curve_label;



%% Create Plot tables
Matchingtables.BeamConfig_table = BeamConfig_table;
Matchingtables.Measured_21A_table = Measured_21A_table;
Matchingtables.Measured_21D_table = Measured_21D_table;
Matchingtables.GoldenBeam_table = GoldenBeam_table;
Matchingtables.Calculated_21A_table = Calculated_21A_table;

%TODO add Sort parameter
parameters = {'FieldSize','SSD'};
select{1} = {'Type','PDD'};
% select{2} = {'Energy','12 MeV'};
MatchParameters = {'FieldSize','Energy'};
eMC_PDD_Plot_table = Match_Data(Matchingtables,MatchParameters,select);
%% Save testing data
save('\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning\electron_data.mat','eMC_PDD_Plot_table');
Excel_filename = '\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning\electron_PDD_data.xls';
Excel_sheet = '12 MeV PDDs';
% eMC_PDD_Plot_table.Properties.VariableNames
% selected = strcmp(eMC_PDD_Plot_table{:,'Energy'},'12 MeV');

% Extract Depth column - all curves will have the same spacing, find the
% longest one
Depth_sets = eMC_PDD_Plot_table{:,'X'};
Depth_length = cellfun(@(x) size(x,1), Depth_sets);
DepthIndex = find(Depth_length == max(Depth_length));
Depth = num2cell(cell2mat(eMC_PDD_Plot_table{DepthIndex(1),'X'}));
xlswrite(Excel_filename,cellstr('Test'),Excel_sheet,'A1')
xlswrite(Excel_filename,cellstr('Field Size'),Excel_sheet,'A1')
xlswrite(Excel_filename,cellstr('Depth(cm)'),Excel_sheet,'A2')
xlswrite(Excel_filename,Depth,Excel_sheet,'A3')

key_list = eMC_PDD_Plot_table{:,'key'};
unique_keys = sort(unique(key_list));
Index = 1;
Dose_cell = cell(1);
for i = 1:size(unique_keys,1)
    KeyIndex = find(strcmp(eMC_PDD_Plot_table{:,'key'},unique_keys{i}));
    for j = 1:size(KeyIndex,1)
        Header{1,Index} = cell2mat(eMC_PDD_Plot_table{KeyIndex(j),'FieldSize'});
        Header{2,Index} = cell2mat(eMC_PDD_Plot_table{KeyIndex(j),'Curve_label'});
        Dose = num2cell(cell2mat(eMC_PDD_Plot_table{KeyIndex(j),'Y'}));
        %Pad the dose cell array
        if size(Dose,1) > size(Dose_cell,1)
            Dose_cell{size(Dose,1),1} = '';
        elseif size(Dose,1) < size(Dose_cell,1)
            Dose{size(Dose_cell,1),1} = '';
        end
        Dose_cell = [Dose_cell, Dose];
        Index = Index +1;
    end
end
% remove the extra column from Dose_cell
 Dose_cell = Dose_cell(:,2:end);
 Excel_table = [Header; Dose_cell];
xlswrite(Excel_filename,Excel_table,Excel_sheet,'B1')
 
%% Plot the data
eMC_PDD_Plot_table = sortrows(eMC_PDD_Plot_table,{'key'});
Plot_Groups = findgroups(eMC_PDD_Plot_table.key);
maxDepth = 8;
depthIncrement = 1;
colors = {'red','green','blue','cyan','magenta','yellow','black','white'};
markers = {'+','o','*','.','x','s','d','^','v','>','<','p','h'};
linestyles = {'-','--',':','-.'};
for i = 1:max(Plot_Groups)
    %% Select the data
    index = find(Plot_Groups == i);
    FigureTitle = eMC_PDD_Plot_table{index(1),'key'}{1};
    f = figure('NumberTitle','off','Name',FigureTitle);
    % plot the full curves 
    subplot(2,1,1);
    for j=1:size(index,1)
        LegendName = eMC_PDD_Plot_table{index(j),'Curve_label'}{1};
        X = cell2mat(eMC_PDD_Plot_table{index(j),'X'});
        Y = cell2mat(eMC_PDD_Plot_table{index(j),'Y'});
        graph = plot(X,Y,'DisplayName',LegendName);
        hold on
        set(graph,'Color',colors{j},'LineWidth',2)
    end
    % configure the graph
    xlabel('Depth (cm)')
    ylabel('Relative Dose (%)')
    Title = FigureTitle;
    title(Title,'FontName','Arial','FontSize',20,'fontweight','b')
    legend('show')
    
    ylim(gca,[0 101]);
    set (gca,'YTick',0:10:101);
    xlim(gca,[0 7.5]);
    set (gca,'XTick',0:.5:7.5);
    grid(gca,'minor')

    % plot the curves from 1-4.5 cm (80%)
       subplot(2,1,2);
    for j=1:size(index,1)
        LegendName = eMC_PDD_Plot_table{index(j),'Curve_label'}{1};
        X = cell2mat(eMC_PDD_Plot_table{index(j),'X'});
        Y = cell2mat(eMC_PDD_Plot_table{index(j),'Y'});
        graph = plot(X,Y,'DisplayName',LegendName);
        hold on
        set(graph,'Color',colors{j},'LineWidth',2)
    end
    % configure the graph
    xlabel('Depth (cm)')
    ylabel('Relative Dose (%)')
    Title = FigureTitle;
    title(Title,'FontName','Arial','FontSize',20,'fontweight','b')
    legend('show')
    
    ylim(gca,[80 101]);
    set (gca,'YTick',80:2:101);
    xlim(gca,[1 4.5]);
    set (gca,'XTick',1:0.5:4.5);
    grid(gca,'minor') 

    box(gca,'on');
    set(f, 'Units','inches')
    set(f, 'Position',[5 3 8 5])
    
end
       
return        
%%%%%    
%%Done to Here 
%%%%%        
        
        
%% 
        
        
        %% Calculate Dose Differences
    DifferenceIndex = 1:min([size(CalculatedDose,1) size(MeasuredDose,1)]);
    DoseDifference = MeasuredDose(DifferenceIndex) - CalculatedDose(DifferenceIndex);


  

    %% Plot a zoomed in curve
    subplot(3,1,2);
    LegendName = 'AAA Calculated Data';
    a = plot(CalculatedDepth,CalculatedDose,'r','DisplayName',LegendName);
    hold on
    
    % Plot the TrueBeam measured data
    LegendName = 'TrueBeam Measured Data with Depth Correction';
    b = plot(MeasuredDepth,MeasuredDose,'b','DisplayName',LegendName);
    
    % Plot the Golden Beam data
    LegendName = 'Golden Beam Data';
    c = plot(GoldenBeamDepth,GoldenBeamDose,'g','DisplayName',LegendName);
    
    set(gca,'FontName','Arial','FontSize',16);
    set(a,'Color','red','LineWidth',2)
    set(b,'Color','blue','LineWidth',2)
    set(c,'Color','green','LineWidth',2)
    % set(d,'Color','magenta','LineWidth',2)
    
    xlabel('Depth (cm)')
    ylabel('Relative Dose (%)')
    % Title = FigureTitle;
    % Title = [header{1}; header{3}; 'Field Size ' FieldSize];
    % title(Title,'FontName','Arial','FontSize',20,'fontweight','b')
    legend('show')
    
    xlim(gca,[0 5]);
    ylim(gca,[90 101]);
    set (gca,'YTick',0:1:101);
    set (gca,'XTick',0:0.5:5);
    set (gca,'XMinorGrid','on','XGrid','on','YGrid','on','YMinorGrid','on');
    
    %% Plot Difference
    subplot(3,1,3);
    set(gca,'FontName','Arial','FontSize',18);
    a = plot(MeasuredDepth(DifferenceIndex),DoseDifference);
    set(a,'Color','blue','LineWidth',2)
    xlabel('Distance (cm)')
    ylabel('Difference (%)')
    title('Differences','FontName','Arial','FontSize',16,'fontweight','b');
    % Mark the zero line
    hold on
    c = plot([0 30],[0 0]);
    set(c,'Color','black','LineWidth',2)
    xlim(gca,[0 30]);
    ylim(gca,[-3 3]);
    set (gca,'YTick',-3:0.5:3);
    set (gca,'XTick',0:5:30);
    grid(gca,'minor')
    %       ylim(gca,[min(DoseDifference) max(DoseDifference)]);
    
    % box(gca,'on');
    % set(f, 'Units','inches')
    % set(f, 'Position',[5 3 8 5])
    


%% Plot Profile Data
MatchedIndex = MatchProfileData (CalculatedAAAProfiles, MeasuredData_10MV_TR1, GoldenBeamProfiles);

%% Select Data to Plot
for i = 1:size(MatchedIndex,1);
    %% Select the data
    FigureTitle = [CalculatedAAAProfiles(MatchedIndex(i,1)).PlanName ...
        '   Depth = ' ...
        num2str(CalculatedAAAProfiles(MatchedIndex(i,1)).depth) ...
        ' cm'];
    CalculatedDistance = CalculatedAAAProfiles(MatchedIndex(i,1)).distance;
    CalculatedDose = CalculatedAAAProfiles(MatchedIndex(i,1)).dose;
    MeasuredDistance_TR1 = MeasuredData_10MV_TR1(MatchedIndex(i,2)).Distance;
    MeasuredDose_TR1 = MeasuredData_10MV_TR1(MatchedIndex(i,2)).Dose;
    GoldenBeamDistance = GoldenBeamProfiles(MatchedIndex(i,3)).Distance;
    GoldenBeamDose = GoldenBeamProfiles(MatchedIndex(i,3)).Dose;
    
    %% Select Range
    Limits = [-min(CalculatedDistance) max(CalculatedDistance) ...
        -min(GoldenBeamDistance) max(GoldenBeamDistance) ...
        -min(MeasuredDistance_TR1) max(MeasuredDistance_TR1)];
    
    % determine the field size
    FieldSizeString = MeasuredData_10MV_TR1(MatchedIndex(i,2)).FieldSize;
    FieldSize = sscanf(FieldSizeString, '%f %*[^x] %*s')/10;
    
    %find a nice round number for the distance plot
    RangeStep = ceil(FieldSize/10/0.5)*0.5;
    DistanceLimit = ceil(min(Limits(:))/RangeStep)*RangeStep;
    
    MaxDose = max([max(CalculatedDose) max(MeasuredDose_TR1) max(GoldenBeamDose)]);
    Doselimit = ceil(MaxDose)+5;
    
    %% Calculate Dose Differences
    % find the matching distance indicies
    % need to round off numbers to deal with floating point inaccuracies
    [DifferenceDistance,PointMatch_GB,PointMatch_TR1] = intersect(round(GoldenBeamDistance.*1000), ...
        round(MeasuredDistance_TR1.*1000));
    DifferenceDistance = DifferenceDistance./1000;
    
    DoseDifference = MeasuredDose_TR1(PointMatch_TR1) - GoldenBeamDose(PointMatch_GB);
    
    
    % Calculate the distance between 50% points
    DistanceError = ProfileDistanceError(MeasuredDistance_TR1,MeasuredDose_TR1, ...
        GoldenBeamDistance,GoldenBeamDose);
    %% Plot the data
    f = figure('NumberTitle','off','Name',FigureTitle);
    
    %% plot the full curves
    subplot(2,1,1);
    % Plot the calculated data
    LegendName = 'AAA Calculated Data';
    a = plot(CalculatedDistance,CalculatedDose,'r','DisplayName',LegendName);
    hold on
    
    % Plot the TrueBeam measured data
    LegendName = 'TrueBeam Measured Data';
    b = plot(MeasuredDistance_TR1,MeasuredDose_TR1,'b','DisplayName',LegendName);
    
    % Plot the Golden Beam data
    LegendName = 'Golden Beam Data';
    c = plot(GoldenBeamDistance,GoldenBeamDose,'g','DisplayName',LegendName);
    
    set(gca,'FontName','Arial','FontSize',16);
    set(a,'Color','red','LineWidth',2)
    set(b,'Color','blue','LineWidth',2)
    set(c,'Color','green','LineWidth',2)
%     set(d,'Color','magenta','LineWidth',2)
    
    xlabel('Distance from CAX (cm)')
    ylabel('Relative Dose (%)')
    Title = FigureTitle;
    % Title = [header{1}; header{3}; 'Field Size ' FieldSize];
    title(Title,'FontName','Arial','FontSize',20,'fontweight','b')
    legend('show')
    
    xlim(gca,[-DistanceLimit DistanceLimit]);
    ylim(gca,[0 Doselimit]);
    set (gca,'YTick',0:10:Doselimit);
    set (gca,'XTick',-DistanceLimit:2*RangeStep:DistanceLimit);
    grid(gca,'minor')
    
    
    %% Plot Difference
    subplot(2,1,2);
    set(gca,'FontName','Arial','FontSize',18);
    FieldSizeString = plot(DifferenceDistance,DoseDifference);
    set(FieldSizeString,'Color','blue','LineWidth',2)
    xlabel('Distance from CAX (cm)')
    ylabel('Difference (%)')
    title('TR1 - 21A Differences','FontName','Arial','FontSize',16,'fontweight','b');
    % Mark the zero line
    hold on
    c = plot([-DistanceLimit DistanceLimit],[0 0]);
    set(c,'Color','black','LineWidth',2)
    xlim(gca,[-DistanceLimit DistanceLimit]);
    set (gca,'XTick',-DistanceLimit:2*RangeStep:DistanceLimit);
    ylim(gca,[-3 3]);
    set (gca,'YTick',-3:0.5:3);
    grid(gca,'minor')
    
    % Create textbox
    annotation(f,'textbox', [0.16 0.33 0.4 0],...
        'String',{['50% distance error = ' ...
        num2str(DistanceError(1)*10,1) ' mm, ' ...
        num2str(DistanceError(2)*10,1) ' mm']}, ...
        'FontWeight','bold',...
        'FontSize',14,...
        'FitBoxToText','off',...
        'LineStyle','none');
    
    % box(gca,'on');
    % set(f, 'Units','inches')
    % set(f, 'Position',[5 3 8 5])
end