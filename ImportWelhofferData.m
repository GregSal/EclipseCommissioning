function  MeasuredData = ImportWelhofferData(data_path, Center, GridSize, Smoothing)
% MeasuredData = ImportWelhofferData(data_path)
% MeasuredData = ImportWelhofferData(data_path, GridSize, Center, Smoothing)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    ImportWelhofferData imports all Welhoffer data curves saved in a given
%    directory.  It seperates them according to whether they are Profiles
%    or PDD curves. The data is smoothed centred and normalized.
%
% Note: Centre % GridSize input order switched to allow for Centering
% without interpolation
%
%   Input Arguments
%     data_path  =  Directory where the ASCII (*.csv Welhoffer Data files
%                   are located
%
%     Center     =   Indicates if profiles should be centered. The
%                    options are 'Center' or 'Asymmetric' if absent no
%                    centering is done. It is required if interpolation or
%                    smoothing is desired. This option has no effect for
%                    measured PDDs
%
%     GridSize   =   An option to centre, normalize and interpolate
%                    the profile. If GridSize is used then the profile
%                    will be centered, normalized, linearly interpolated
%                    to the specified grid size
%
%     Smoothing  =   The desired smoothing method for profiles (optional)
%                    can be one of 'sgolay', 'pchip' or 'none'  If
%                    interpolation is requested, smoothing is required.
%                    This option has no effect for measured PDDs.
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

%% initialize the function

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


%% Get list of '.csv' files in the directory and subdirectories

% define  '.csv' files as the search string
% scan_string = '*.txt';
scan_string = '*.csv';

% Scan the directory and subdirectories for this search string
Measurement_files = dir_scan(data_path, scan_string);
%
%% Loop through all isodose files

% preallocate Structure
MeasuredData = [];
number_of_files = size(Measurement_files,1);

for i=1:number_of_files;
    
    % Read in the data
    if (DO_Interpolation)
        ImportedData = read_measured_data(Measurement_files{i},Center, GridSize,Smoothing);
    elseif DO_Center
        ImportedData = read_measured_data(Measurement_files{i},Center);
    else
        ImportedData = read_measured_data(Measurement_files{i});
    end
    if ~isempty(MeasuredData)
        MeasuredData = cat(2,MeasuredData,ImportedData);
    else
        MeasuredData = ImportedData;
    end
end
end
