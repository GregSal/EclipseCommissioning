function DataBook_depth = get_databook_depth(SSD,energy,field_size,parameter)
DataBook_file = '\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning\DataBook_PDD_parameters.mat';
% DataBook_R50_value = get_databook_R50(energy,field_size)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    get_databook_R50 loads the table of DataBook Dmax and R50 values and
%    interpolates along field size to obtain the desired databook depth.
%
%   Input Arguments
%     SSD        = SSD in cm (100 or 110)
%     energy     = Electon energy (one of 6,9,12,16,20)
%     Field_size = Equivalent square field size at 100 cm to use for
%                  interpolating depth values
%     Parameter  = The depth parameter to be extracted.  Can be either
%                  'Dmax' or 'R50' 
%
%   Output Arguments 
%     DataBook_depth = The interpolated Dmax or R50 value to use for
%                      shifting PDD curves. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check the number of input arguments (Minimum 2 Maximum 2)
narginchk(4, 4)

%% Load Data
load(DataBook_file);
SSD_select = DataBook_depths.SSD==SSD;
energy_select = DataBook_depths.Energy==energy;
data_select = SSD_select & energy_select;
depth_values = DataBook_depths{data_select,parameter};
DataBook_depth = interp1(DataBook_Field_Size,depth_values,field_size);


