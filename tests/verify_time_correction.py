# conda env: pymaid
#
# Only checks DET files -- REQ files can be redundant (multiple mseed)
# represented by a single algo line in GeoCSV.
#
# Developer: Joel D. Simon (JDS)
# Contact: jdsimon@alumni.princeton.edu
# Last modified: 04-Jun-2025
# Last tested: Python Python 3.10.15, Darwin Kernel Version 23.6.0

import os
import csv
import glob
from itertools import islice

from obspy.io.mseed import util as obspy_util

## Function prototypes
## ___________________________________________________________________________ ##

def get_DET_mseed_filenames(mseed_dir):
    mseed_filenames = []
    for dirpath, _, filenames in os.walk(mseed_dir):
        for filename in filenames:
            if 'DET' in filename and filename.endswith('.mseed'):
                mseed_filenames.append(os.path.join(dirpath, filename))

    return mseed_filenames

def get_DET_automaid_metadata_corrections(automaid_metadata_filename, fieldnames_row_num=2):
    # Returns a { filename : correction } dict
    automaid_metadata_corrections = {}

    with open(automaid_metadata_filename, 'r') as meta_file:
        # Skip all headers but the final, which spells out the fieldnames
        # (counting from 0)
        meta_file = islice(meta_file, fieldnames_row_num, None)

        # Read every row and parse the relevant columns in dict
        reader = csv.DictReader(meta_file)
        for row in reader:
            filename = row["#filename"] + '.mseed'
            if 'DET' in filename:
                correction = float(row["USER3"])
                automaid_metadata_corrections[filename] = correction

    return automaid_metadata_corrections

def get_DET_geocsv_corrections(geocsv_filename, fieldnames_row_num=11):
    # Returns a simple list of "Time Corrections" for associated with every
    # "Algorithm" row in the GeoCSV
    geocsv_corrections = []

    with open(geocsv_filename, 'r') as meta_file:
        # Skip all headers but the final, which spells out the fieldnames
        # (counting from 0)
        meta_file = islice(meta_file, fieldnames_row_num, None)

        # Read DET every "Algorithm" row and parse the relevant columns in dict
        reader = csv.DictReader(meta_file)
        for row in reader:
            if "Algorithm" in row["MethodIdentifier"] and "D" in row["DataQuality"]:
                correction = float(row["TimeCorrection"])
                geocsv_corrections.append(correction)

    return geocsv_corrections

def time_correction_isequal(mseed_filename, geoscv_correction, automaid_metadata_correction):
    '''Verifies that the time corrections printed in the GeoCSV and automaid
    metadata files match that contained in the mseed header, within 1/10,000 s

    '''

    # NB, I cannot just use `flags['timing_correction']` for the second test
    # That value seems to be a bug? (or maybe it's a percentage?)

    # Verify every record in the mseed is time_corrected
    flags = obspy_util.get_flags(mseed_filename)
    number_of_records = flags['record_count']
    number_of_corrected_records = flags['activity_flags_counts']['time_correction_applied']

    # 1st test: every record has a time correction applied
    if number_of_records != number_of_corrected_records:
        return False

    # Verify that the time correction applied is within 1/10,000 of one second of
    # what is printed in the Geo CSV file
    record_offset = 0
    for record_number in range(number_of_records):
        record_info = obspy_util.get_record_information(mseed_filename,
                                                        offset=record_offset)

        # Time correction units are are 1/10000 s (1e-4 s)
        mseed_time_corr_secs = record_info['time_correction'] * 1.e-4

        ## 2nd test: each record's time correction matches the metadata file (w/in precision)
        # 1. The mseed time correction is in units of 1/10,000 s (1e-4 s)
        # 2. It is encoded as an integer; i.e., it cannot encode fractional units
        # 3. Therefore, the smallest time difference it can encode is 1/10,000 s (1e-4 s)
        # 4. QED* (w/in precision, see note at bottom)
        if abs(geocsv_correction - mseed_time_corr_secs) >= 0.0002 \
           or abs(automaid_metadata_correction - mseed_time_corr_secs) >= 0.0002:
            return False

        # Advance file pointer to next record
        record_offset += record_info.get('record_length')

    return True

## Verification script
## ___________________________________________________________________________ ##

# Globs may need updating with new station names
iris_data_dir = os.path.join(os.environ['MERMAID'], 'iris', 'data')
float_dirs = sorted([os.path.join(iris_data_dir, d)
                     for d in os.listdir(iris_data_dir)
                     if (os.path.isdir(os.path.join(iris_data_dir, d)))
                     and not (d.startswith('.'))])

tot_tested = 0
fail_list = []
for float_dir in float_dirs:
    print("\nTesting: {}".format(float_dir))

    # Use the "all" directory, not any specific "archive" to check all time
    # corrections using newest metadata
    mseed_dir = os.path.join(float_dir, 'all', 'mseed')
    mseed_filenames = get_DET_mseed_filenames(mseed_dir)

    metadata_dir = os.path.join(float_dir, 'all', 'meta')
    geocsv_filename = os.path.join(metadata_dir, 'geo_DET_REQ.csv')
    geocsv_corrections = get_DET_geocsv_corrections(geocsv_filename)

    automaid_metadata_filename = os.path.join(metadata_dir, 'automaid_metadata_DET_REQ.csv')
    automaid_metadata_corrections = get_DET_automaid_metadata_corrections(automaid_metadata_filename)

    if len(geocsv_corrections) != len(mseed_filenames):
        raise ValueError("Failed: Number of GeoCSV 'Algorithm' rows does not equal number of mseed files")

    if len(automaid_metadata_corrections) != len(mseed_filenames):
        raise ValueError("Failed: Number of automaid metadata rows does not equal number of mseed files")

    test_count = 0
    pass_count = 0
    fail_count = 0

    for i, mseed_filename in enumerate(sorted(mseed_filenames)):
        mseed_basename = os.path.basename(mseed_filename)

        geocsv_correction = geocsv_corrections[i]
        automaid_metadata_correction = automaid_metadata_corrections[mseed_basename]

        if time_correction_isequal(mseed_filename, geocsv_correction, automaid_metadata_correction):
            pass_count += 1

        else:
            fail_count += 1
            fail_list.append(mseed_filename)

        test_count += 1

    print("Result: {}\n        {}".format(geocsv_filename, automaid_metadata_filename))
    print("Tested: " + str(test_count))
    print("Passed: " + str(pass_count))
    print("Failed: " + str(fail_count))
    tot_tested += test_count
    
print(f"\nTested {tot_tested} DET files")
if not fail_list:
    print("All tests passed\n")

else:
    for fail in fail_list:
        print("!!! Failure: " + fail)



# Why we allow 0.0002 and not 0.0001 for comparison --
#
# Example: '20210424T002358.06_60861874.MER.DET.WLT5'
#
# The raw float passed around and used in algorithm, in s:
#   In : e.obspy_trace_stats.sac['user3']
#   Out: -0.08689990453064578
#
# That float in 0.0001 s:
#   In : e.obspy_trace_stats.sac['user3']*10000
#   Out: -868.9990453064578
#
# That float in 0.0001 s, cast to int (what is written to mseed header):
#   In : np.int(e.obspy_trace_stats.sac['user3']*10000)
#   Out: -868
#   ==> TRUNCATED
#
# That float in s, cast to float32 (what is written in meta files/SAC header):
#   In : '{:>13.6f}'.format(np.float32(e.obspy_trace_stats.sac['user3']))
#   Out: '    -0.086900'
#   ==> ROUNDED
#
# The difference between truncated and rounded in forms is 0.0001.
# The nominal sampling frequency to date has been 0.05 seconds.
# Therefore, this difference is 500x smaller than a single sampling interval.
# This amount of slop is acceptable, and is practically encoded in the miniSEED format.
