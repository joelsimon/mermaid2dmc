function write_deleted_mseed(archive)
% WRITE_DELETED_MSEED(archive)
%
% Writes metadata to file for mseeds deleted in last archive.
%
% Input:
% archive       Archive date, e.g., '2025-06-09T22:15:37.918Z'
%
% Output:
% <txtfile>     SNCL and start/end times in:
%                   $MERMAID/iris/data/<archive_deleted_mseed_meta.txt
%
% Ex: WRITE_DELETED_MSEED('2025-06-09T22:15:37.918Z')
%
% Author: Joel D. Simon
% Contact: jdsimon@alumni.princeton.edu | joeldsimon@gmail.com
% Last modified: 11-Jun-2025, 24.1.0.2568132 (R2024a) Update 1 on MACA64 (geo_mac)

% Initiate I/O paths and open output file.
merdir = fullfile(getenv('MERMAID'), 'iris', 'data');
txtfile = fullfile(merdir, sprintf('%s_deleted_mseed_meta.txt', archive));
writeaccess('unlock', txtfile, false);
dfmt = 'uuuu-MM-dd HH:mm:ss.SS';
fmt = '%s    %s    %s    %s    %s\n';
fid = fopen(txtfile, 'w');

% Fetch all "deleted_mseed.txt" in all archives, most of which are empty.
f = globglob(merdir, '**/*', sprintf('*%s*', archive), 'deleted_mseed.txt');
for i = 1:length(f)
    % Read deleted_mseed.txt and move along if empty.
    txt = readtext(f{i});
    if isempty(txt)
        continue

    end
    archive_path = fx(strsplit(f{i}, 'archive'), 1);
    for j = 1:length(txt)
        % This mseed deleted with this archive, but it was not necessarily created in
        % the last one -- may have been archived with the first send. So have to
        % search all archives (should only exist in one; fullsac below errors if
        % it exists in multiple).
        deleted_mseed = txt{j};
        deleted_sac = strrep(deleted_mseed, 'mseed', 'sac');

        % Read the SAC header and print metadata (just easier for me to read SAC than mSEED)
        sac_path = fullsac(deleted_sac, archive_path);
        h = sachdr(sac_path);
        sd = seistime(h);
        sb = string(sd.B, dfmt);
        se = string(sd.E, dfmt);
        fprintf(fid, fmt, h.KSTNM, h.KHOLE, h.KCMPNM, sb, se);

    end
end
writeaccess('lock', txtfile)
fclose(fid);
fprintf('Wrote: %s\n', txtfile)
