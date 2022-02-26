function cf = compare_first_vs_current
% CF = COMPARE_FIRST_VS_CURRENT
%
% Compares SAC files in the first archive 2021-05-28T16:42:41Z with the current
% "all" running list to ensure that only the SAC headers SCALE and KUSER0
% (automaid version) differ.
%
% Author: Joel D. Simon
% Contact: jdsimon@alumni.princeton.edu | joeldsimon@gmail.com
% Last modified: 30-Aug-2021, Version 9.3.0.948333 (R2017b) Update 9 on MACI64

merdir = fullfile(getenv('MERMAID'), 'iris', 'data');

% This is the old (first) archive directory which included SAC files with the
% incorrect SCALE factor.
s_old = fullsac([], merdir, [], '2021-05-28');

% The "all" directory is a running list of ALL SAC files in ALL archives.  It
% houses the most up-to-date version of the files, so if there are differences
% between the current and a previous archive, it will overwrite the relevant
% extant SAC files. Note that an archive is NEVER OVERWRITTEN so that we know
% what we sent to IRIS and when; the diffs in the all directory just alert you
% when you've made changes that WOULD HAVE resulted in a different SAC being
% sent to IRIS.
s_new = fullsac([], merdir, [], 'all');

% The expectation: only the SCALE will have updated (from 170177 to -149400).
[~, idx_old, idx_new] = intersect(strippath(s_old), strippath(s_new));

if length(s_old) ~= length(idx_new)
    error('Every SAC in the old archive should still exist in the current full ("all") list')

end

for i = 1:length(idx_old)
    [iseq, cf{i}, h1, h2] = sacequality(s_old{idx_old(i)}, ...
                                        s_new{idx_new(i)});

    fprintf('%s\n', cf{i});

end

% There should be only a single unique comparison string, listing only the
% SCALE and automaid version number (KUSER0) differences.
fprintf('\nLength 2021-05-28 archive:  %i\n', length(s_old))
fprintf(  'Number of SAC comparisons:  %i\n', length(cf));
fprintf(  'Unique comparisons strings: %s\n', char(unique(cf)));
