function p = correct_path(p)
p = strrep(p, '\', filesep);
p = strrep(p, '/', filesep);
if ~strcmp(p(end), filesep)
    p = [p, filesep];
end
