function tr = fetch_traces
% TR = FETCH_TRACES
%
% Author: Joel D. Simon
% Contact: jdsimon@alumni.princeton.edu | joeldsimon@gmail.com
% Last modified: 19-Nov-2021, Version 9.3.0.948333 (R2017b) Update 9 on MACI64

network = 'MH';
station = '*';
location = '*';
channel = '*';
startDate = '1970-01-01 00:00:00';
endDate = datestr(datetime('now'));

st = irisFetch.Stations('Response', 'MH', '*', location, channel);
for i = 1:length(st)
    station = st(i).StationCode
    tr.(station) = irisFetch.Traces(network, station, location, channel, ...
                                    startDate, endDate);

    for j = 1:length(tr.(station))
        tr.(station)(j).sacpz.units = 'Pa';
        tr.(station)(j).sacpz.constant =  double(st(i).Channels.Response.Stage.StageGain.Value);
        tr.(station)(j).sacpz.poles = st(i).Channels.Response.Stage.PolesZeros.Pole';
        tr.(station)(j).sacpz.zeros = st(i).Channels.Response.Stage.PolesZeros.Zero';

    end
end

fid = fopen('~/Desktop/IRIS_traces.txt', 'w+');
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
