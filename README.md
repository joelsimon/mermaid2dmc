Package and transmit MERMAID miniSEED and GeoCSV for archival at the IRIS DMC.\
Written by Joel D. Simon for EarthScope-Oceans.\
Contact: jdsimon@alumni.princeton.edu | joeldsimon@gmail.com\


NB,\
`$ <command>` means execute in terminal\
`>> <command>` means execute in MATLAB

[0] Activate `conda` env from automaid (see
https://github.com/earthscopeoceans/automaid)
```
    $ conda activate pymaid
```

[1] Generate new MERMAID archive for transmission to IRIS DMC
(default archive location: $MERMAID/iris/data/)
```
    $ python mermaid4dmc.py
```

[2] Run various tests and verifications\
(check logs, git diffs etc. in $MERMAID/iris/data)
```
    $ python tests/verify_time_correction.py
    $ tests/verify_geocsv_algo_rows
    $ tests/verify_geocsv_diff
    $ tests/mseed2sac_diff
    >> cd tests; compare_first_vs_current;
    >> verify_mseed2sac
```

[3] Transmit miniSEED in new archive via IRIS' `miniseed2dmc` protocol\
(only works on JDS' frisius; other users must contact IRIS admin for "host:port")
```
   $ mermaid2dmc <new_archive>
   ```

By default `mermaid2dmc` runs in "pretend mode"; turn it off when ready...
After completion, check $MERMAID/iris/data/ermaid2dmc.log for errors

[5] Tar new GeoCSV for posting on the MDA (email to Un Joe at IRIS)\
    e.g., https://ds.iris.edu/data/reports/MH/P0008/archive/
```
    $ tar_geocsv
```

[6] # Check data availability (give IRIS a few days to archive)\
https://service.iris.edu/fdsnws/availability/1/query?format=text&net=MH&sta=*&loc=*&cha=*&starttime=2000-01-01T00:00:00&endtime=2059-12-23T59:59:99&orderby=nslc_time_quality_samplerate&includerestricted=true&nodata=404
