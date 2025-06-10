function mermaid2dmc_files_transmitted(log)
% MERMAID2DMC_FILES_TRANSMITTED(log)
%
% Check how many new files (to be) transmitted by mermaid2dmc.
%
% (1) Run mermaid2dmc in -p, "pretend" mode" in /iris/scripts/
%    $ ./mermaid2dmc
%
% (2) Parse the relevant lines from the modified log in /iris/data/
%    $ git diff mermaid2dmc.log | grep "from.*file(s)" >| log
%
% (3) Run this script with that log
%    >> MERMAID2DMC_FILES_TRANSMITTED('~/mermaid/iris/data/log')
%
% Author: Joel D. Simon
% Contact: jdsimon@alumni.princeton.edu | joeldsimon@gmail.com
% Last modified: 09-Jun-2025, 24.1.0.2568132 (R2024a) Update 1 on MACA64 (geo_mac)

s = readtext(log);
count = 0;
for i = 1:length(s)
    first = strsplit(s{i}, 'from ');
    second = strsplit(first{2}, ' file(s)');
    count = count + str2num(second{1});

end
count
