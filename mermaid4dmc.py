# conda env: pymaid
#
# Generate archives of [.sac, GeoCSV, and] .mseed for `mermaid2dmc` transmission.
#
# (1) Delete and overwrite all data in, .e.g.
#     .../P0008/all/[ mseed/ , sac/ , meta/ ]
# (2) Generate new timestamped archive as, e.g.
#     .../P0008/archive/<iso8601>/[ mseed/ , sac/ , meta/ ]
#
# Author: Joel D. Simon (JDS)
# Contact: jdsimon@alumni.princeton.edu | joeldsimon@gmail.com
# Last modified by JDS: 30-Aug-2021
# Last tested: Python 2.7.15, Darwin-18.7.0-x86_64-i386-64bit

import os
import csv
import glob
import shutil

# Define directories (globs may need to be changed new stations)
mer_dir = os.environ['MERMAID']
proc_dirs = sorted(glob.glob(os.path.join(mer_dir, 'processed', '452*')))
iris_data_dir = os.path.join(mer_dir, 'iris', 'data')

for proc_dir in proc_dirs:

    # Convert, e.g., ".../452.020-P-08/" to ".../P0008/"
    # (lifted from `dives.attach_kstnm_kinst`)
    station_name = proc_dir.split('/')[-1]
    kinst, kstnm_char, kstnm_num = station_name.split('-')
    num_zeros = 5 - len(kstnm_char + kstnm_num)
    kstnm = kstnm_char + '0'*num_zeros + kstnm_num

    # I want to do two things:
    # (1) Delete and overwrite all data in, .e.g.
    #     .../P0008/all/[ mseed/ , sac/ , meta/ ]
    # (2) Generate new timestamped archive as, e.g.
    #     .../P0008/archive/<iso8601>/[ mseed/ , sac/ , meta/ ]

    # Make a new directory with the KSTNM (long-form station name)
    kstnm_dir = os.path.join(iris_data_dir, kstnm)
    if not os.path.exists(kstnm_dir):
        os.makedirs(kstnm_dir)

    ## _______________________________________________________________________ ##
    ## (1) .../<float_name>/all/
    ## _______________________________________________________________________ ##

    # Delete everything and then remake, e.g., ".../P0008/all/"
    all_dir = os.path.join(kstnm_dir, 'all')
    if os.path.exists(all_dir):
        shutil.rmtree(all_dir)
        #os.system("git -C {} rm -rf .".format(all_dir))
    if not os.path.exists(all_dir):
        os.mkdir(all_dir)

    # (Re)make the subdirectories
    all_mseed_dir = os.path.join(all_dir, 'mseed')
    all_sac_dir = os.path.join(all_dir, 'sac')
    all_meta_dir = os.path.join(all_dir, 'meta')
    for subdir in [all_mseed_dir, all_sac_dir, all_meta_dir]:
        os.mkdir(subdir)

    # Copy all SAC files
    current_sac_list = sorted(glob.glob(os.path.join(proc_dir, "**/*DET*sac")))
    current_sac_list = [x for x in current_sac_list if 'prelim' not in x]
    for sac in current_sac_list:
        shutil.copy(sac, all_sac_dir)

    # Copy all miniSEED files
    current_mseed_list = sorted(glob.glob(os.path.join(proc_dir, "**/*DET*mseed")))
    current_mseed_list = [x for x in current_mseed_list if 'prelim' not in x]
    for mseed_file in current_mseed_list:
        shutil.copy(mseed_file, all_mseed_dir)

    # Copy requisite metadata files
    meta_list = [os.path.join(proc_dir, 'geo_DET.csv')]
    meta_list.append(os.path.join(proc_dir, 'mseed2sac_metadata_DET.csv'))
    meta_list.append(os.path.join(proc_dir, 'automaid_metadata_DET.csv'))
    for meta_file in meta_list:
        shutil.copy(meta_file, all_meta_dir)

    ## _______________________________________________________________________ ##
    ## (2) .../<float_name>/archive/<iso8601>/
    ## _______________________________________________________________________ #

    archive_dir = os.path.join(kstnm_dir, 'archive')
    if not os.path.exists(archive_dir):
        os.mkdir(archive_dir)

    archived_mseed_list = glob.glob(os.path.join(archive_dir, "**/mseed/*DET*mseed"))
    archived_sac_list = glob.glob(os.path.join(archive_dir, "**/sac/*DET*sac"))

    # Extract GeoCSV creation date from file to generate this archive's date
    with open(meta_list[0], 'r') as geocsv_file:
        lines = geocsv_file.readlines()
        for line in lines:
            if "created" in line:
                created_str = line
                break
    last_created_date = created_str.split("#created: ")[-1].strip('\n')
    archive_str = "{}:{}".format(kstnm, last_created_date)
    current_archive_dir = os.path.join(archive_dir, archive_str)
    if not os.path.exists(current_archive_dir):
        os.mkdir(current_archive_dir)

    current_archive_mseed_dir = os.path.join(current_archive_dir, 'mseed')
    current_archive_sac_dir = os.path.join(current_archive_dir, 'sac')
    current_archive_meta_dir = os.path.join(current_archive_dir, 'meta')
    for subdir in [current_archive_mseed_dir, current_archive_sac_dir, current_archive_meta_dir]:
        if not os.path.exists(subdir):
            os.mkdir(subdir)

    # Determine which files have not previously been archived, and
    # which files were previously archived and have since been deleted
    current_mseed_basename_list = map(os.path.basename, current_mseed_list)
    archived_mseed_basename_list = set(map(os.path.basename, archived_mseed_list))

    new_mseed_basename_list = [x for x in current_mseed_basename_list if x not in archived_mseed_basename_list]
    del_mseed_basename_list = [x for x in archived_mseed_basename_list if x not in current_mseed_basename_list]


    current_sac_basename_list = map(os.path.basename, current_sac_list)
    archived_sac_basename_list = set(map(os.path.basename, archived_sac_list))

    new_sac_basename_list = [x for x in current_sac_basename_list if x not in archived_sac_basename_list]
    del_sac_basename_list = [x for x in archived_sac_basename_list if x not in current_sac_basename_list]

    ## Copy all new files to current archive
    ## Copy from `all_dir` (single path) rather than `proc_dir` because we used
    ## basenames to compare and the basenames in the `proc_dir` have different paths

    # Copy all miniSEED files
    for new_mseed_basename in new_mseed_basename_list:
        shutil.copy(os.path.join(all_mseed_dir, new_mseed_basename), current_archive_mseed_dir)

    # Copy all SAC files
    for new_sac_basename in new_sac_basename_list:
        shutil.copy(os.path.join(all_sac_dir, new_sac_basename), current_archive_sac_dir)

    # Copy requisite metadata files
    # These get copied in totality (complete from deployment) with every mseed2dmc
    for meta_file in meta_list:
        # Append archive string
        # E.g., ".../geo_DET.csv" --> ".../P0008_2021-05-25T17:52:38Z_geo_DET.csv"
        basename = os.path.basename(meta_file)
        archive_str_basename = archive_str + '-' +  basename
        shutil.copy(meta_file, os.path.join(current_archive_meta_dir, archive_str_basename))

    # Finally, note any files that were deleted since the last archive
    # Put this at the top level of the archive because I want to know
    del_mseed_txt = os.path.join(current_archive_dir, 'deleted_mseed.txt')
    with open(del_mseed_txt, 'w') as del_mseed_f:
        for line in del_mseed_basename_list:
            del_mseed_f.write(line + '\n')

    del_sac_txt = os.path.join(current_archive_dir, 'deleted_sac.txt')
    with open(del_sac_txt, 'w') as del_sac_f:
        for line in del_sac_basename_list:
            del_sac_f.write(line + '\n')

    print "Archived: " + proc_dir
