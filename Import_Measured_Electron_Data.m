 function Measured_Data_Table = Import_Measured_Electron_Data(data_path,import_parameters)
% Measured_Data_Table = Import_Measured_Electron_Data(data_path,import_parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    Import_eMC_Data creates a structured array of data tables from a
%    variety of sources. It does not recieve any variables because this
%    function needs to be customezed for every data collection. It saves
%    the tables it creates as a .mat file and then combins them as a
%    structure. 
%
%    The function is continuaously expanded as more data is analyzed and
%    can often contain unused sections of code at the end from previous
%    work.
%
%   Input Arguments
%     data_path          =  Directory where the ASCII (*.csv)
%                           Welhoffer Data files are located
%     import_parameters  =  parameters used for processing the imported
%                           data. It contains two fields:
%         PDD:          Contains the parameters for the PDD curves.
%
%         profile:      Contains the parameters for the profile curves. 
%
%         Both fields contain multiple subfields:
%
%            Both:
%              GridSize    =     The desired spacing between depth or
%                                distance values obtained by interpolating
%                                the data that is imported.
%              Smoothing   =     The desired smoothing method for the
%                                imported data.  Can be one of 'linear',
%                                'sgolay', 'pchip' or 'none'.
%
%            PDD Only:
%              Shift_location = The desired positional correction.  Values
%                               can be 'Dmax' 'R50' or 'None'. If 'Dmax' or
%                               'R50' the PDD depth will be shifted to
%                               force 'Dmax' or 'R50' location to the
%                               specified position. 
%
%            profile Only:
%              Center       =   Indicates if profile should be centered.
%                               The options are 'Center' or Asymmetric'.
%
%   Output Arguments
%     Measured_Data_Table   =  A table containing all measured PDD and
%                              Profile data found in the given directory
%                              and it's Subdirectories. The table contains
%                              the following fields: 
%   Table Variables:
%          FilePath     = The directory in which the measured data file is
%                         located.  
%          FileName     = The name of the file in which the measured data
%                         file is located.  
%          Linac        = A string indicating the treatment unit the
%                         measurements were done on, based on the
%                         measurement file's header.
%          Energy       = A string containing the energy extracted from the
%                         measurement file's header in the form: 
%                               {energy} MeV
%          SSD          = A string indicating the SSD in cm.
%          FieldSize    = A string containing the field size taken from the
%                         measurement file's header and converted to cm
%                         in the form: {X} x {Y}
%          EquivSquare  = The equivlent square field size based on the
%                         field size. 
%          Direction    = The string 'Beam', 'Crossline' or 'Inline' which
%                         indicates the direction of the dose data curve.
%          Type         = The string 'PDD' or 'Profile'
%          DepthShift   = (PDDs) The amount (in cm) the PDD depth was
%                          shifted.
%          SurfaceDose  = (PDDs) The percent dose at the surface after
%                          normalizing and depth shifts.
%          Build_up_95  = (PDDs) The location of the 95% dose in the
%                          build-up region after normalizing and depth
%                          shifts.
%          R100         = (PDDs) The location of dmax after normalizing and
%                          depth shifts. 
%          R95          = (PDDs) The location of the 95% dose beyond dmax
%                          after normalizing and depth shifts.
%          R90          = (PDDs) The location of the 90% dose beyond dmax
%                          after normalizing and depth shifts.
%          R80          = (PDDs) The location of the 80% dose beyond dmax
%                          after normalizing and depth shifts.
%          R50          = (PDDs) The location of the 50% dose after
%                          normalizing and depth shifts. 
%          CAX_Dose     = (Profiles) The calculated dose at the central
%                          axis after any centering, interpoaltion and
%                          smoothing.
%          DistanceShift= (Profiles) The amount (in cm) the profile
%                          distance was shifted to centre it.
%          FieldWidth   = (Profiles) The profile width in cm from 50% to
%                          50% dose points.
%          Penumbra     = (Profiles) The average penumbra with in cm
%                          between the 20% and 80% dose points.
%          Flatness     = (Profiles) The variation in % of the dose in the
%                          region that is 80% of the field size.
%          Symmetry     = (Profiles) The maximum dose difference in percent
%                          between matching points on opposite sides of the
%                          profile over the region that is 80% of the field
%                          size.
%          Depth        =  The Depth values for the PDD curve, or the depth
%                          of the profile.
%          Distance     =  The Profile distance (x) coordinates or the
%                          distance of the PDD from the central axis.
%          Dose         =  The relative dose values for the PDD or profile
%                          curve.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Measured_Data = ImportWelhofferData(data_path);
% convert to table variable
Measured_Data_Table = struct2table(Measured_Data);

%% normalize and shift the PDDs
% get the normalization and shift parameters
GridSize = import_parameters.PDD.GridSize;
Smoothing = import_parameters.PDD.Smoothing;
Shift_location = import_parameters.PDD.Shift_location;
% select the PDDS 
PDD_Index = find(strcmp(Measured_Data_Table.Type,'PDD'));
for i = 1:length(PDD_Index)
    Depth = cell2mat(Measured_Data_Table{PDD_Index(i),'Depth'});
    Dose = cell2mat(Measured_Data_Table{PDD_Index(i),'Dose'});
    %match dimensions
    if size(Depth) ~= size(Dose)
        Dose = shiftdim(Dose,1);
    end
    Energy = sscanf(cell2mat(Measured_Data_Table{PDD_Index(i),'Energy'}),'%u');
    FieldSize = sscanf(cell2mat(Measured_Data_Table{PDD_Index(i),'FieldSize'}),'%u');
    SSD_string = char(Measured_Data_Table{PDD_Index(i),'SSD'});
    SSD = str2double(SSD_string(1:3));
    Position = get_databook_depth(SSD,Energy,FieldSize,Shift_location);
    [ShiftedDepth, NormDose, PDD_analysis] = Normalize_PDD(Depth,Dose,GridSize,Smoothing,Shift_location,Position);
    Measured_Data_Table{PDD_Index(i),'Depth'} = {ShiftedDepth};
    Measured_Data_Table{PDD_Index(i),'Dose'} = {NormDose};
    Measured_Data_Table{PDD_Index(i),'R100'} = {PDD_analysis.R100 - PDD_analysis.depth_shift};
    Measured_Data_Table{PDD_Index(i),'SurfaceDose'} = {PDD_analysis.SurfaceDose};
    Measured_Data_Table{PDD_Index(i),'Buildup_95'} = {PDD_analysis.Build_up_95};
    Measured_Data_Table{PDD_Index(i),'R95'} = {PDD_analysis.R95};
    Measured_Data_Table{PDD_Index(i),'R90'} = {PDD_analysis.R90};
    Measured_Data_Table{PDD_Index(i),'R80'} = {PDD_analysis.R80};
    Measured_Data_Table{PDD_Index(i),'R50'} = {PDD_analysis.R50 - PDD_analysis.depth_shift};
    Measured_Data_Table{PDD_Index(i),'DepthShift'} = {PDD_analysis.depth_shift};
end

%% get the profile parameters
% select the Profiles 
Profile_Index = find(strcmp(Measured_Data_Table.Type,'Profile'));
% normalize and shift each profile based on the import parameters
GridSize = import_parameters.profile.GridSize;
Center = import_parameters.profile.Center;
Smoothing = import_parameters.profile.Smoothing;
for i = 1:length(Profile_Index)
    Distance = cell2mat(Measured_Data_Table{Profile_Index(i),'Distance'});
    Dose = cell2mat(Measured_Data_Table{Profile_Index(i),'Dose'});
    [ShiftedDistance, RenormalizedDose, Profile_analysis] = Process_Profile(Distance,Dose,Center,GridSize,Smoothing);
    Measured_Data_Table{Profile_Index(i),'Distance'} = {ShiftedDistance};
    Measured_Data_Table{Profile_Index(i),'Dose'} = {RenormalizedDose};
    Measured_Data_Table{Profile_Index(i),'DistanceShift'} = {Profile_analysis.shift};
    Measured_Data_Table{Profile_Index(i),'FieldWidth'} = {Profile_analysis.field_width};
    Measured_Data_Table{Profile_Index(i),'Penumbra'} = {Profile_analysis.penumbra};
    Measured_Data_Table{Profile_Index(i),'Flatness'} = {Profile_analysis.flatness};
    Measured_Data_Table{Profile_Index(i),'Symmetry'} = {Profile_analysis.symmetry};
end

