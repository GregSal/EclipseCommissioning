function [EqSq, FieldSize] = calculate_field_size(e_Insert)
% [EqSq, FieldSize] = calculate_field_size(e_Insert)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    calculate_field_size calculates an equivalent field size for an
%    electron insert shape. It assumes that the insert is either a
%    rectangle or a circle.
%
%   Input Arguments
%     e_Insert   =  An n x 2 matrix of points defining the insert
%                           shape. 
%
%   Output Arguments 
%     EqSq       =   The equivalent square field size for the insert.
%
%     FieldSize  =   A text string describing the field size
%                      One of:
%                        {max dimension} x {min dimension}
%                        {diameter} cm circle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check the number of input arguments (Minimum 1 Maximum 1)
narginchk(1, 1)
% Determine field shape
    if size(e_Insert,1) == 4
        insert_dimensions = max(abs(diff(e_Insert)));
        x = insert_dimensions(1);
        y = insert_dimensions(2);
        EqSq = (2*x*y)/(x+y);
        diameter = '';
        % field size string
        max_dim = max([x,y]);
        min_dim = min([x,y]);
        FieldSize = [num2str(max_dim) ' x ', num2str(min_dim)];
    else
        diameter = sum(max(e_Insert));
        EqSq = sqrt(pi*(diameter/2)^2);
        x = '';
        y = '';
        % files size string
        FieldSize = [num2str(diameter) ' cm circle'];
    end
end