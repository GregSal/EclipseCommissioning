function  BeamConfigData = ImportBeamConfigData(data_path, GridSize)
% BeamConfigData = ImportBeamConfigData(data_path)
% BeamConfigData = ImportBeamConfigData(data_path, GridSize)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    ImportBeamConfigData imports all data curves exported from Eclipse
%    Beam Configuration saved in a given directory. The data is
%    normalized. 
%
% Note: Centre % GridSize input order switched to allow for Centering
% without interpolation
%
%   Input Arguments
%     data_path  =   Directory where the ASCII (*.csv Welhoffer Data files
%                    are located
%
%     GridSize   =   An option to centre, normalize and interpolate
%                    the profile. If GridSize is used then the profile
%                    will be centered, normalized, linearly interpolated
%                    to the specified grid size
%
%   Output Arguments
%     MeasuredData     =   A structured array sonsisting of the following fields:
%                          Type       = PDD or Profile depending on the
%                                       type of data curve
%                          FieldSize  = The field Size info extracted from
%                                       the measurement file's header
%                          Energy     = The Beam Energy extracted from
%                                       the measurement file's header
%                          Parameters = A structure variable containing a
%                                       set of scan parameters extracted
%                                       from the measurement file's header
%                          Direction  = The direction of a profile scan.
%                                       Values are 'Crossline' (X),
%                                       'Inline' (Y) or 'Beam' (for a PDD)
%                          Depth      = The Depth of a profile curve or the
%                                       depth (x) coordinates for the PDD
%                                       data
%                          Distance   = The distance (x) coordinates of a
%                                       profile scan.
%                          Dose       = The relative dose for the profile
%                                       or PDD
%
%% initialize the function

% Check the number of input arguments (Minimum 1 Maximum 1)
narginchk(1, 2)

% Check for interpolation (centering and smoothing options are just passed
% to the Centre_Profile function if interpolation is requested
if (nargin == 2)
    % verify that GridSize is valid
    if isnumeric(GridSize)
        DO_Interpolation = true;
    else
        error('ImportBeamConfigData:InvalidParameter', 'GridSize must be a numeric value');
    end
elseif (nargin == 1) %Valid # arguments is 1, 2 or 4
    DO_Interpolation = false;
else
    error('ImportBeamConfigData:InvalidParameters', 'Valid # arguments is 1, 2 or 4');
end


%% Get list of '.csv' files in the directory and subdirectories

% define '.txt' files as the search string
scan_string = '*.txt';

% Scan the directory and subdirectories for this search string
Data_Curve_files = dir_scan(data_path, scan_string);
%
%% Loop through all isodose files

% preallocate Structure (each file contains 2 curves)
number_of_files = size(Data_Curve_files,1);
BeamConfigData(number_of_files*2,1) = struct;

BC_Index = 1;
for i=1:number_of_files;
    % Read in the data
    [curve_info, DataPoints] = read_curve(Data_Curve_files{i});
    %TODO include test for PDD vs Profile
    % Do the Interpolation if required
    if(DO_Interpolation)
        % set the interpolation range based on the maximum X range
%         MinX = max(min(DataPoints.X1),min(DataPoints.X2));
%         if MinX <0
%             MinX = 0;
%         end
        MaxX = min(max(DataPoints.X1),max(DataPoints.X2));
        Y1_final = interp1(DataPoints.X1,DataPoints.Y1,0:GridSize:MaxX,'linear','extrap');
        X1_final = 0:GridSize:MaxX;
        Y2_final = interp1(DataPoints.X2,DataPoints.Y2,0:GridSize:MaxX,'linear','extrap');
        X2_final = 0:GridSize:MaxX;
    else
        Y1_final = DataPoints.Y1;
        X1_final = DataPoints.X1;
        Y2_final = DataPoints.Y2;
        X2_final = DataPoints.X2;
    end
    % Renormalize the PDDs
    norm = max(Y1_final(:));
    RenormY1 = (Y1_final/norm)*100;
    
    norm = max(Y2_final(:));
    RenormY2 = (Y2_final/norm)*100;
    % Store the first curve
    BeamConfigData(BC_Index).FileName = curve_info.FileName;
    if strcmp(curve_info.RadiationType,'electrons');
        BeamConfigData(BC_Index).Energy = [curve_info.energy ' MeV'];
        BeamConfigData(BC_Index).Type = 'PDD';
    end
    BeamConfigData(BC_Index).Applicator = curve_info.Applicator;
    BeamConfigData(BC_Index).Algorithm = curve_info.Algorithm;
    BeamConfigData(BC_Index).Machine = curve_info.Machine;
    BeamConfigData(BC_Index).RadiationType = curve_info.RadiationType;
    BeamConfigData(BC_Index).DataType = curve_info.DataType;
    BeamConfigData(BC_Index).X_units = curve_info.X_Label;
    BeamConfigData(BC_Index).Y_units = curve_info.Data_Label;
    BeamConfigData(BC_Index).DataLabel = curve_info.Variables{2};
    BeamConfigData(BC_Index).parameters = curve_info;
    BeamConfigData(BC_Index).X=X1_final';
    BeamConfigData(BC_Index).Y=RenormY1';

    BC_Index = BC_Index +1;
    
    % Store the second curve
    BeamConfigData(BC_Index).FileName = curve_info.FileName;
    if strcmp(curve_info.RadiationType,'electrons');
        BeamConfigData(BC_Index).Energy = [curve_info.energy ' MeV'];
        BeamConfigData(BC_Index).Type = 'PDD';
    end
    BeamConfigData(BC_Index).Applicator = curve_info.Applicator;
    BeamConfigData(BC_Index).Algorithm = curve_info.Algorithm;
    BeamConfigData(BC_Index).Machine = curve_info.Machine;
    BeamConfigData(BC_Index).RadiationType = curve_info.RadiationType;
    BeamConfigData(BC_Index).DataType = curve_info.DataType;
    BeamConfigData(BC_Index).X_units = curve_info.X_Label;
    BeamConfigData(BC_Index).Y_units = curve_info.Data_Label;
    BeamConfigData(BC_Index).DataLabel = curve_info.Variables{3};
    BeamConfigData(BC_Index).parameters = curve_info;
    BeamConfigData(BC_Index).X=X2_final';
    BeamConfigData(BC_Index).Y=RenormY2';

    BC_Index = BC_Index +1;
end
end
