
## Requirements:
 - Windows OS (for NI DAQ communication, keyboard version should work anywhere)
 - MATLAB 2013b+ (largely for tables)
 - Recent version of Psychtoolbox 3 (+ gstreamer, Asio4All, ... for Windows)

## Optional:
 - git (for installation)

## Installation:
 - git clone --recursive git://github.com/aforren1/replan_finger.git
 - Alternatively,
     1. Download zip from https://github.com/aforren1/replan_finger and extract somewhere reasonable
     2. Download zips from https://github.com/aforren1/psychoobox and https://github.com/aforren1/ptbutils,
        and extract those to the folders of the same name in replan_finger.
        
## Explanation of data files

Starred elements (**) are included in the reduced dataset.
`NaN` indicates missing data (e.g. no press, no force data in computer keyboard situation)
PTB = Psychtoolbox

The "full" data file (stored as `.mat`) contains the following elements:
 - preparation_time - the projected preparation time (generated from U(0.05, 0.5) distribution)
 - first_image - the first image shown (**)
 - second_image - the second image shown (**)
 - second_image_frame - the intended frame for the second image (relative to the start of the trial)
 - id - subject id (**)
 - day - day (can be numeric or string) (**)
 - block - block (can be numeric or string) (**)
 - trial - trial # (**)
 - second_image_sanity - the recorded time of the screen flip that the image actually appeared on,
                         relative to the start of the trial
 - second_image_prep - the preparation time, based on second_image_sanity and the time of the last beep
 - first_press - index of the first press, 1 to 10 (**)
 - correct - logical true/false (**)
 - time_first_press - the time of the first recorded press (based off "velocity" threshold)
 - real_prep_time - time_first_press - second_image_sanity (**)
 - max_force - value of maximum force exerted (overall I think, not just on first press). Currently returns
               voltage, as we need to redo the calibration.
 - time_max_force - Time that the maximum force was exerted (currently used for timing feedback).
 - post_data - contains either force traces (N x 12 I think, column 1 being projected PTB timestamp, column 2
               being the timestamp from the NI DAQ, and the remainders being force/voltage values for all fingers)
               or discrete presses (N x 2, where the first column is the selection and the second is a PTB timestamp).
 - trial_start - Absolute time of the trial start (PTB timestamp)
 - last_beep - Center of the final beep (in seconds).
 - last_beep_frame - Frame that the final beep is projected to occur upon.
 - diff_last_beep - last_beep - time_first_press 
 - block_start - Abslute time of the block start (in seconds).

You can access individual elements of this struct via things like:

```matlab
% print info for trial 
data(3)
ans = 

  struct with fields:

       preparation_time: 0.3625
            first_image: 3
           second_image: 8
     second_image_frame: 109
                     id: "sub007"
                    day: "1"
                  block: "1"
                  trial: 3
    second_image_sanity: 1.7989
      second_image_prep: 0.3678
            first_press: 8
                correct: 1
       time_first_press: 2.1263
         real_prep_time: 0.3275
              max_force: NaN
         time_max_force: NaN
              post_data: [8 2.2991e+03]
            trial_start: 2.2970e+03
              last_beep: 2.1667
        last_beep_frame: 130
         diff_last_beep: -0.0403
            block_start: 2.2863e+03

% look at distribution of preparation times
all_trs = cell2mat({data.real_prep_time});
```

Alternatively, you can do operations on the reduced data set. This is stored (and loaded) as 
'long' format data.

```matlab
tbl = readtable('data/sub007/sub007_test_day1_block1_162045.csv');
% same operations as above
tbl(3, :)
ans = 

    first_image    second_image       id       day    block    trial    first_press    correct    real_prep_time
    ___________    ____________    ________    ___    _____    _____    ___________    _______    ______________

    3              8               'sub007'    1      1        3        8              1          0.32747       

all_trs = tbl.real_prep_time;
```