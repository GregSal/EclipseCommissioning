function DataBook_value = get_databook_value(energy,field_size,parameter)
DataBook_file = '\\dkphysicspv1\e$\Gregs_Work\Eclipse\eMC 13.6.23 Commissioning\DataBook_PDD_parameters.mat';
% DataBook_R50_value = get_databook_R50(energy,field_size)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    get_databook_R50 loads the table of Data Book R50 values and
%    interpolates along field size to obtain an R50 value.
%
%   Input Arguments
%     energy     =  Electon energy (one of 6,9,12,16,20)
%     Field_size = Equivalent square field size to use for interpolating
%                  R50 value
%     Parameter  = Equivalent square field size to use for interpolating
%                  R50 value
%
%   Output Arguments 
%     DataBook_R50_value = An interpolated R50 value to use for shifting
%                          PDD curves. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check the number of input arguments (Minimum 2 Maximum 2)
narginchk(2, 2)

%% Load Data
load(DataBook_file);
%Find the R50 values for a given Energy
energy_select = DataBook_R50.Energy==energy;
R50_values = DataBook_R50{energy_select,'R50_data'};
DataBook_value = interp1(DataBook_Field_Size,R50_values,field_size);

