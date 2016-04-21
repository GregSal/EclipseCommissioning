function MeasuredData = read_measured_data(File_name, Center, GridSize, Smoothing)
% MeasuredData = read_measured_data(File_name)
% MeasuredData = read_measured_data(File_name, Center)
% MeasuredData = read_measured_data(File_name, Center, GridSize, Smoothing)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    This function reads the measured data from file_name and returns the
%    data in a single structured array
%
% Note: Centre % GridSize input order switched to allow for Centering
% without interpolation
%
%   Input Arguments
%     File_name  =  Name, includinf full path for file to be read
%
%     Center    =   Indicates if profiles should be centered. The
%                   options are 'Center' or Asymmetric' if absent no
%                   centering is done. It is required if interpolation or
%                   smoothing is desired. This option has no effect for
%                   measured PDDs
%
%     GridSize   =  An option to centre, normalize and interpolate
%                   the profile. If GridSize is used then the profile
%                   will be centered, normalized, linearly interpolated
%                   to the specified grid size
%
%     Smoothing =   The desired smoothing method for profiles (optional)
%                   can be one of 'sgolay', 'pchip' or 'none'  If
%                   interpolation is requested, smoothing is required.
%                   This option has no effect for measured PDDs.
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initilize the data
% Check the number of input arguments (Minimum 1 Maximum 1)
narginchk(1, 4)

% Check for interpolation (centering and smoothing options are just passed
% to the Centre_Profile function if interpolation is requested
if (nargin == 4)
    % verify that GridSize is valid
    if isnumeric(GridSize)
        DO_Interpolation = true;
    else
        error('read_measured_data:InvalidParameter', 'GridSize must be a numeric value');
    end
elseif (nargin == 2) %Valid # arguments is 1, 2 or 4
    % verify that Center is valid
    if ischar(Center)
        DO_Center = true;
        DO_Interpolation = false;
    else
        error('read_measured_data:InvalidParameter', 'Center must be a string');
    end
elseif (nargin == 1) %Valid # arguments is 1, 2 or 4
    DO_Interpolation = false;
    DO_Center = false;
else
    error('read_measured_data:InvalidParameters', 'Valid # arguments is 1, 2 or 4');
end

data=1;
Data_index = 1;

%% Open The file
fid = fopen(File_name);
%% Read each scan  from the File
while(not(isempty(data)))
    %%  Get Single scan data
    [scan_data, data]= read_scan(fid);
    
    % do not process an empty data set
    if isempty(data),
        continue
    end;
    
    %% curve test
    % check to see if curve type is a profile
    
    % which position column is changing (1 or 2 for profiles 3 for PDD)
    % find the increments in each column
    delta = data(:,1:3)-circshift(data(:,1:3),[1 0]);
    % calculate the average increment
    increments = abs(mean(delta(2:end,:)));
    % find out which columns besides other than the dose colum changes
    col = find(increments>2*eps);
    % Test to see that col is a valid scalar col = [1 2] implies a diagonal
    % profile, which is not used
    if or(isempty(col),size(col)~=1)
        continue
    end
    % Store the path and filename used
    [Path, DataName] = fileparts(File_name);
    MeasuredData(Data_index).Path = Path; %#ok<*AGROW>
    MeasuredData(Data_index).FileName = DataName;
    % test to see if the curve is a profile or a PDD
    % 1 is inplane 2 is crossplane
    if or(col == 1,col == 2)
        %% Process Profile Data
        % _________________________________________________________________
        % If the curve is a profile store it in the data set and create an
        % index to it.
        
        % Determine the depth of the profile in cm
        Depth = data(1,3)/10;
        
        %         % Set the scan parameters as default for the next scan
        %         default = scan_data;
        
        % convert the inplane and crossplane data to the same plane and
        % convert to cm
        RawDepth = data(:,col)/10;
        % sort data from lowest to highest (correct data that starts at
        % maximum distance)
        [Distance, I] = sort(RawDepth);
        
        % remove equal depth points
        Inc = find(diff(Distance));
        
        % Identify the dose column (diferent versions of measurements use a
        % diferent column) If column 6 is all zeros then use column 4
        DataIndicator = mean(data(:,6));
        if DataIndicator == 0
            DoseData = data(:,4);
        else
            DoseData = data(:,6);
        end
        
        % Smooth, Center and Normalize profiles
        if(DO_Interpolation)
            [distance, Dose] = Centre_Profile(Distance(Inc), DoseData(I(Inc)),Center,GridSize,Smoothing);
        elseif DO_Center
            [distance, Dose] = Centre_Profile(Distance(Inc), DoseData(I(Inc)),Center);
        else
            [distance, Dose] = Centre_Profile(Distance(Inc), DoseData(I(Inc)));
        end
        % Add the profile to the combined data set
        MeasuredData(Data_index).Type = 'Profile';
        MeasuredData(Data_index).Depth = Depth;
        MeasuredData(Data_index).FieldSize = scan_data.field_size;
        MeasuredData(Data_index).Energy = scan_data.energy;
        MeasuredData(Data_index).Direction = scan_data.CurveType;
        MeasuredData(Data_index).Parameters = scan_data;
        MeasuredData(Data_index).Distance=distance;
        MeasuredData(Data_index).Dose=Dose;
        Data_index = Data_index+1;
    elseif col == 3 % Data is for a PDD
        %% Process PDD Data
        % _________________________________________________________________
        % If the curve is a PDD interpolate it and store it for averaging
        
        % Find Offset distance in cm
        OffsetDistance = max(data(1,[1 2]))/10;
        
        % Convert Depth from mm to cm
        d = data(:,3)/10;
        
        % sort data from lowest to highest (correct data that starts at
        % deepest depth)
        [depthData, I] = sort(d);
        
        % remove equal depth points
        Inc = find(diff(depthData));
        
        % Identify the dose column (diferent versions of measurements use a
        % diferent column) If column 6 is all zeros then use column 4
        DataIndicator = mean(data(:,6));
        if DataIndicator == 0
            DoseData = data(:,4);
        else
            DoseData = data(:,6);
        end
        
        if(DO_Interpolation)
            % Do the Interpolation
            
            % set the maximum PDD depth (depth > maximum data will be NaN)
            maxpoint = 50;
            PDD_data = interp1(depthData(Inc),DoseData(I(Inc)),0:GridSize:maxpoint);
            
            % Select the good points
            good_points = ~isnan(PDD_data);
            PDD = PDD_data(good_points);
            
            depth_initial = 0:GridSize:maxpoint;
            depth = depth_initial(good_points)';
        else
            PDD = DoseData(I(Inc));
            depth = depthData(Inc);
        end
        
        % Renormalize the PDD
        norm = max(PDD(:));
        RenormPDD = (PDD/norm)*100;
        
        % Store the data
        MeasuredData(Data_index).Type = 'PDD';
        MeasuredData(Data_index).FieldSize = scan_data.field_size;
        MeasuredData(Data_index).Energy = scan_data.energy;
        MeasuredData(Data_index).Distance=OffsetDistance;
        MeasuredData(Data_index).Direction = scan_data.CurveType;
        MeasuredData(Data_index).Parameters = scan_data;
        MeasuredData(Data_index).Depth=depth;
        MeasuredData(Data_index).Dose=RenormPDD';
        Data_index = Data_index+1;
    end
end
end