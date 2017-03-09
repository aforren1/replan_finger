%% pre-experiment boilerplate

% input dialog
prompt = {'Subject id:', 'Day:', 'Block:', 'Trial table path:', 'Trial table name:', 'fullscreen:', 'transducers:'};
dlg_title = 'Experimentation Supination';
num_lines = 1;
load('defaults/defaultans.mat');
defaultans = inputdlg(prompt, dlg_title, num_lines, defaultans);
save('defaults/defaultans.mat', 'defaultans');

% cast inputs to appropriate types
input_dlg = cell2struct(defaultans, {'id', 'day', 'block', 'path', 'file', 'fullscreen', 'transducers'});
input_dlg.fullscreen = str2num(input_dlg.fullscreen);
input_dlg.transducers = str2num(input_dlg.transducers);
input_dlg.fullfile = [input_dlg.path, input_dlg.file];

Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);
addpath(genpath('Psychoobox'));
addpath(genpath('ptbutils'));
tgt = readtable(input_dlg.fullfile);

% lop off extension
[~, tgt_name] = fileparts(input_dlg.file);

data_dir = ['data/', input_dlg.id, '/'];
% final file name (explicitly append .mat?)
data_name = [data_dir, input_dlg.id, '_', tgt_name, '_', ...
             'day', input_dlg.day, '_', ...
             'block', input_dlg.block, '_', ...
              datestr(now, 'hhMMSS')]; % this end chunk prevents overwriting existing data

%% Set up screen
HideCursor;
Screen('Preference', 'Verbosity', 1);
if input_dlg.fullscreen
    win_size = [];
else
    win_size = [50 50 800 700];
end

win = PobWindow('screen', max(Screen('screens')), ...
                'color', [0 0 0], ...
                'rect', win_size);

%% Set up audio
aud = PobAudio;
snd0 = GenClick(1046, 1/2, 4); % frequency of tone, frequency of repetition, number of beeps
last_beep = (length(snd0) - 0.02 * 44100)/44100;
% last frame of a trial
last_frame = floor(last_beep/win.flip_interval);
snd1 = audioread('audio/smw_coin.wav');
aud.Add('slave', 1);
aud.Add('slave', 2);
aud.Add('buffer', 1, 'audio', [snd0; snd0]);
aud.Add('buffer', 2, 'audio', [snd1, snd1]');
aud.Map(1, 1);
aud.Map(2, 2);
% audio warmup
aud.Play(1, 0);
WaitSecs(.5);
aud.Stop(1);

%% Set up images
imgs = PobImage;
img_dir = 'images/';
img_names = dir('images/*.png');

hand_offset = 0.3; % x displacement of hands rel to center
rel_x_scale = 0.25;
for ii = 1:length(img_names)
    tmpimg = imread([img_dir, img_names(ii).name]);
    %tmpimg = imcomplement(tmpimg);
    rel_x_pos = 0.5 - hand_offset;
    rot_angle = 90;
    if ii > 5
        rel_x_pos = 0.5 + hand_offset;
        rot_angle = 270;
    end

    imgs.Add(ii, 'original_matrix', {tmpimg}, ...
             'rel_x_pos', rel_x_pos, ...
             'rel_y_pos', 0.5, ...
             'rel_x_scale', rel_x_scale, ...
             'rel_y_scale', nan,...
             'rotation_angle', rot_angle);
end

blank_imgs = PobImage;
img_dir = 'images/blank/';
img_names = dir('images/blank/*.png');
for ii = 1:length(img_names)
    tmpimg = imread([img_dir, img_names(ii).name]);
    %tmpimg = imcomplement(tmpimg);
    rel_x_pos = 0.5 - hand_offset;
    rot_angle = 90;
    if ii == 2
        rel_x_pos = 0.5 + hand_offset;
        rot_angle = 270;
    end

    blank_imgs.Add(ii, 'original_matrix', {tmpimg}, ...
             'rel_x_pos', rel_x_pos, ...
             'rel_y_pos', 0.5, ...
             'rel_x_scale', rel_x_scale, ...
             'rel_y_scale', nan, ...
             'rotation_angle', rot_angle);
end

%% Set up text
helptext = ['This experiment is\nTimed Response.\n', ...
            ];

info_txt = PobText('value', helptext, 'size', 50, ...
                   'color', [255 255 255], ...
                   'rel_x_pos', 0.5, ...
                   'rel_y_pos', 0.5,...
                   'style', 'bold');

too_fast = PobText('value', 'Too early', 'size', 50, ...
                   'color', [255 30 63], ...
                   'rel_x_pos', 0.5, ...
                   'rel_y_pos', 0.5, ...
                   'style', 'bold');
too_slow = PobText('value', 'Too late', 'size', 50, ...
                   'color', [255 30 63], ...
                   'rel_x_pos', 0.5, ...
                   'rel_y_pos', 0.5, ...
                   'style', 'bold');

% hardcoded indices at present, in the future parse unique(tgt.finger)?
if input_dlg.transducers
    kbrd = BlamForceboard(1:10);
else
    kbrd = BlamKeyboard(1:10);
end

fix_cross =  PobText('value', '+', 'size', 160, ...
                   'color', [255 255 255], ...
                   'rel_x_pos', 0.5, ...
                   'rel_y_pos', 0.5);

% visual feedback
press_feedback = PobText('value', '+', 'size', 180, ...
                   'color', [200 200 200], ...
                   'rel_x_pos', 0.5, ...
                   'rel_y_pos', 0.5, ...
                   'style', 'bold');

%% Register relative to window
imgs.Register(win.pointer);
imgs.Prime();

blank_imgs.Register(win.pointer);
blank_imgs.Prime();
% imgs.Draw(index); % to draw
info_txt.Register(win.pointer);
too_slow.Register(win.pointer);
too_fast.Register(win.pointer);
fix_cross.Register(win.pointer);
press_feedback.Register(win.pointer);

tgt.second_image_frame = last_frame - floor(tgt.preparation_time/win.flip_interval);
tgt.id(1:height(tgt), 1) = {input_dlg.id};
tgt.day(1:height(tgt), 1) = {input_dlg.day};
tgt.block(1:height(tgt), 1) = {input_dlg.block};
tgt.trial(:, 1) = 1:height(tgt);
