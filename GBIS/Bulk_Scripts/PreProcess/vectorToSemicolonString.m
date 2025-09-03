function str = vectorToSemicolonString(vec)
    % Converts a numeric vector to a MATLAB-style string with semicolon-separated elements
    % Example: [1 2 3] → '[1;2;3;]'

        str = '[';  % Start of the string
        for i = 1:length(vec)
            str = [str, num2str(vec(i)), ';'];
        end
        str = [str, ']'];  % End of the string
end