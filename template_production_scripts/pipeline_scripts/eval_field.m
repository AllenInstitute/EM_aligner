function v = eval_field(s, fname, default_value, asis)
    if nargin < 4, asis = false; end
    if isfield(s, fname) && ~isempty(s.(fname))
        v = s.(fname);
        if ~asis && ischar(v)
            v = eval(v);
        end
    else
        v = default_value;
    end
end
