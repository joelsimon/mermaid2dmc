function fetch_traces(uname, passwd)
% FETCH_TRACES(uname, passwd)
%
% Fetch open and restricted MERMAID data sets from IRIS.
%
% Input:
% uname     IRIS username for embargoed data
%               (def: 'jdsimon@alumni.princeton.edu')
% passwd    IRIS password for embargoed data
%               (def: getenv('IRIS_AUTH_PASSWD'))
%
% Output:
% Writes trace lists to $MERMAID/iris/fetch/
%
% Author: Joel D. Simon
% Contact: jdsimon@alumni.princeton.edu | joeldsimon@gmail.com
% Last modified: 31-Jan-2023, Version 9.3.0.948333 (R2017b) Update 9 on MACI64

defval('uname', 'jdsimon@alumni.princeton.edu')
defval('passwd', getenv('IRIS_AUTH_PASSWD'))

network = 'MH';
station = '*';
location = '*';
channel = '*';
startDate = '1970-01-01 00:00:00';
endDate = datestr(datetime('now'));
unamepwd = {uname, passwd};

restriction = {'open', 'partial'};
for k = 1:length(restriction)
    st = irisFetch.Stations('Response', 'MH', '*', location, channel);

    for i = 1:length(st)
        station = st(i).StationCode;

        switch restriction{k}
          case 'open'
            tr.(station) = irisFetch.Traces(network, station, location, ...
                                            channel, startDate, endDate);

          case 'partial'
            tr.(station) = irisFetch.Traces(network, station, location, ...
                                            channel, startDate, endDate, ...
                                            unamepwd);

          otherwise
            error('Choose only ''open'' or ''partial'' for restriction status')

        end

        for j = 1:length(tr.(station))
            tr.(station)(j).sacpz.units = 'Pa';
            tr.(station)(j).sacpz.constant =  double(st(i).Channels.Response.Stage.StageGain.Value);
            tr.(station)(j).sacpz.poles = st(i).Channels.Response.Stage.PolesZeros.Pole';
            tr.(station)(j).sacpz.zeros = st(i).Channels.Response.Stage.PolesZeros.Zero';

        end
    end

    irisdir = fullfile(getenv('MERMAID'), 'iris');
    fetchdir = fullfile(irisdir, 'fetch');
    if exist(fetchdir, 'dir') ~= 7
        success = mkdir(fetchdir);
        if success
            fprintf('Made new directory: %s\n', fetchdir)

        else
            error('Unable to make new directory: %s', fetchdir)

        end
    end

    fname = fullfile(fetchdir, sprintf('fetch_traces_%s.txt', restriction{k}));
    fid = fopen(fname, 'w+');
    fprintf(fid, 'station #traces            oldest_trace            newest_trace\n');
    names = fieldnames(tr);
    for i = 1:length(names)
        mermaid = names{i};
        MER = tr.(mermaid);
        num_traces = length(MER);
        oldest = datestr(MER(1).startTime);
        newest = datestr(MER(end).startTime);
        fprintf(fid, '  %5s    %4i    %s    %s\n', mermaid, num_traces, oldest, newest);

    end
    fclose(fid);
    fprintf('Wrote %s\n', fname)

end
