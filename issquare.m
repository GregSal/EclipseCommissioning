function tf = issquare(field_size)
% tf = issquare(field_size)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Greg Salomons
%    issquare tests whether a field size string of the format N x M is a
%    square field size.
%
%  Input Arguments
%     field_size =  A field size string of the format N x N. (All other
%                   formats will return false)
%
%   Output Arguments
%     tf         =  A boolean, true if N = M
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialize the function

% Check the number of input arguments (Minimum 1 Maximum 1)
narginchk(1, 1)
if ischar(field_size)
    % Set the regular expression to extract the N and M numbers
    expr = '^\s*(\d+)\s*[x]\s*(\d+)\s*$';
    
    % extract the X and Y filed sizes
    N = str2num(regexprep(field_size,expr,'$1'));
    M = str2num(regexprep(field_size,expr,'$2'));
    
    if max(size(N)) == 0
        tf = false;
    else
        tf = N == M;
    end
else
    tf = false;
end

end
