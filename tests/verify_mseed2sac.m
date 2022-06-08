function verify_mseed2sac(iris_path)
% VERIFY_MSEED2SAC(iris_path)
%
% Compares SAC files written directly by automaid with SAC files originally
% written as mseed and converted to SAC with "mseed2sac.m -m mseed2sac_metadata*.csv"
%
% Input:
% irispath        Path to IRIS directory (def: $MERMAID/iris)
%
% Author: Joel D. Simon
% Contact: jdsimon@alumni.princeton.edu | joeldsimon@gmail.com
% Last modified: 25-Feb-2022, Version 9.3.0.948333 (R2017b) Update 9 on MACI64

%% NB, this script only checks the equality of SAC header variables filled by
%% mseed2sac.m.  It does not compare, e.g. `KUSER?`, because those fields are
%% not filled by mseed2sac (though the are filled in the SAC files output
%% directly by automaid).

clc

% Default.
defval('iris_path', fullfile(getenv('MERMAID'), 'iris'))

% Glob may require future update with new station names.
data_path = fullfile(iris_path, 'data');
float_dirs = skipdotdir(dir(fullfile(data_path, 'P00*')));

global_max_B = 0;
global_max_B_sac = '';
global_max_E = 0;
global_max_E_sac = '';

for i = 1:length(float_dirs)
    float_path = fullfile(float_dirs(i).folder, float_dirs(i).name);
    fprintf('Testing: %s\n', float_path)

    mseed_path = fullfile(float_path, 'all', 'mseed');
    meta_path = fullfile(float_path, 'all', 'meta');
    sac_path = fullfile(float_path, 'all', 'sac');

    % Perform and log all the diffs in, e.g., ~/mermaid/iris/data/P0008/logs/.
    log_path = fullfile(float_path, 'logs');
    [~, foo] = mkdir(fullfile(float_path, 'logs'));

    % Go to log folder and clean any previously converted SAC files.
    cd(log_path)
    delete('*SAC')

    % Convert from miniSEED to SAC using `mseed2sac`.
    mseed_files = fullfile(mseed_path, '*\.mseed');
    meta_file = fullfile(meta_path, 'mseed2sac_metadata_DET.csv');
    [status, result] = system(sprintf('mseed2sac -m %s %s', meta_file, mseed_files));
    if status ~= 0
        error(sprintf('`mseed2sac` failed with the following  message:\n%s', result))

    end

    % Match up file lists based on starttime.
    s1_sac = fullsac([], sac_path);
    s2_sac = fullsac([], log_path);

    s1_time = mersac2date(s1_sac);
    s2_time = mseed2sac2date(s2_sac);

    [s1_time, s1_idx] = sort(s1_time);
    [s2_time, s2_idx] = sort(s2_time);

    s1_sac = s1_sac(s1_idx);
    s2_sac = s2_sac(s2_idx);

    % First verification.
    if ~isequal(s1_time, s2_time)
        error('List of starttimes (from filenames) do not match')

    end

    % 17 columns of metadata file for mseed2sac.m
    % (https://github.com/iris-edu/mseed2sac/blob/master/doc/mseed2sac.md)
    %
    % (01) Network (KNETWK)
    % (02) Station (KSTNM)
    % (03) Location (KHOLE)
    % (04) Channel (KCMPNM)
    % (05) Latitude (STLA)
    % (06) Longitude (STLO)
    % (07) Elevation (STEL), in meters [not currently used by SAC]
    % (08) Depth (STDP), in meters [not currently used by SAC]
    % (09) Component Azimuth (CMPAZ), degrees clockwise from north
    % (10) Component Incident Angle (CMPINC), degrees from vertical
    % (11) Instrument Name (KINST), up to 8 characters
    % (12) Scale Factor (SCALE)
    % (13) Scale Frequency, unused
    % (14) Scale Units, unused
    % (15) Sampling rate, unused
    % (16) Start time, used for matching
    % (17) End time, used for matching

    % Fields to compare (NB; sacequality.m also checks binary data)
    fields = {'KNETWK' ; % Entries [1:12] in mseed2sac_metadata.csv
              'KSTNM'  ;
              'KHOLE'  ;
              'KCMPNM' ;
              'STLA'   ;
              'STLO'   ;
              'STEL'   ;
              'STDP'   ;
              'CMPAZ'  ;
              'CMPINC' ;
              'KINST'  ;
              'SCALE'  ;
              'NPTS'   ; % the final 6 are required in a complete SAC file
              'NVHDR'  ;
              'B'      ;
              'E'      ;
              'IFTYPE' ;
              'LEVEN'  ;
              'DELTA'};
    % USER? and KUSER? not filled by mseed2sac and thus not checked


    % Compare data, and SAC header field-by-field.
    cf_line = cell(length(s1_sac), 1);
    max_B = 0;
    max_B_sac = '';
    max_E = 0;
    max_E_sac = '';
    for i = 1:length(s1_sac)
        % Compare SAC header fields individually.
        sacnames = [strippath(s1_sac{i}) ', ' strippath(s2_sac{i}) ' -- '];
        [~, cf, h1, h2] = sacequality(s1_sac{i}, s2_sac{i}, fields, false);
        cf_line{i} = [sacnames cf];

        % Compare start/end times I compute from those fields.
        t1 = seistime(h1);
        t2 = seistime(h2);

        B_diff = abs(seconds(t1.B-t2.B));
        E_diff = abs(seconds(t1.E-t2.E));

        % Minor differences explained by slightly difference sampling frequencies
        % (h1.DELTA - h2.DELTA)*(h1.NPTS-1) == seconds(t1.E - t2.E)
        if B_diff > max_B
            max_B = B_diff;
            max_B_sac = s1_sac{i};

        end

        if E_diff > max_E
            max_E = E_diff;
            max_E_sac = s1_sac{i};

        end
    end

    % Write the results.
    filename = fullfile(log_path, 'mseed2sac_diffs.txt');
    fid = fopen(filename, 'w+');
    fprintf(fid, '%s\n', cf_line{:});
    fclose(fid);

    % Clean converted SAC files.
    delete('*SAC')

    % Conclude with per float printouts
    fprintf('Largest starttime discrepancy: %.6f s (%s)\n', max_B, strippath(max_B_sac))
    fprintf('Largest endtime discrepancy:   %.6f s (%s)\n', max_E, strippath(max_E_sac))
    fprintf('Wrote %s\n\n', filename)

    if max_B > global_max_B
        global_max_B = max_B;
        global_max_B_sac = max_B_sac;

    end
    if max_E > global_max_E
        global_max_E = max_E;
        global_max_E_sac = max_E_sac;

    end
end

% Conclude with printout of max diffs considering all floats.
fprintf('Considering all floats --\n')
fprintf('Largest starttime discrepancy: %.6f s (%s)\n', global_max_B, strippath(global_max_B_sac))
fprintf('Largest endtime discrepancy:   %.6f s (%s)\n', global_max_E, strippath(global_max_E_sac))

cd(iris_path)
