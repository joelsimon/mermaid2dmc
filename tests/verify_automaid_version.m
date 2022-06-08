function [sac, ver] = verify_automaid_version(iris_path)
% [sac, ver] = VERIFY_AUTOMAID_VERSION(iris_path)
%
% Author: Joel D. Simon
% Contact: jdsimon@alumni.princeton.edu | joeldsimon@gmail.com
% Last modified: 07-Jun-2022, Version 9.3.0.948333 (R2017b) Update 9 on MACI64
clc

% Default.
defval('iris_path', fullfile(getenv('MERMAID'), 'iris'))

% Glob may require future update with new station names.
sac = globglob(fullfile(iris_path, 'data'), '**/*', 'archive', '**/*', '*.sac');
num_sac = length(sac);
fprintf('number .sac files tested: %i\n', num_sac)

% Extract 'KUSER0' from each SAC file.
for i = 1:num_sac
    [~, h] = readsac(sac{i});
    ver{i} = h.KUSER0;

end

fprintf('automaid versions in use:\n')
uniq_ver = unique(ver);
for i = 1:length(uniq_ver)
    fprintf('%s\n', uniq_ver{i});

end
