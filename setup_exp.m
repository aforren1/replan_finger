% pre-experiment boilerplate

Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);
addpath(genpath('Psychoobox'));
addpath(genpath('ptbutils'));
tgt = ParseTgt(file_name, ',');
tgt = struct2table(tgt); % R2013b ++!

% break it up into segments
split_str = regexp(file_name, '/', 'split');

% return values of particular portions
% use name as stand-in for id
id = split_str{end - 1};
tgt_name = split_str{end};

% lop off extension
tgt_name = regexprep(tgt_name, '.tgt', '');

data_dir = ['data/', id, '/'];
% final file name (explicitly append .mat?)
data_name = [data_dir, id, '_', tgt_name, '_', datestr(now, 'hhMMSS'), '.mat'];

%% Set up screen
HideCursor;
Screen('Preference', 'Verbosity', 1);
if fullscreen
    win_size = [];
else
    win_size = [50 50 500 500];
end

win = PobWindow('screen', max(Screen('screens')), ...
                'color', [0 0 0], ...
                'rect', win_size);

%% Set up audio
aud = PobAudio;
snd0 = GenClick(1046, 1/2, 3);
last_beep = (length(snd0) - 0.02 * 44100)/44100;
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

for ii = 1:length(img_names)
    tmpimg = imcomplement(...
        imread([img_dir, img_names(ii).name])...
        );
    rel_x_pos = 0.5 - 0.15;
    if regexp(img_names(ii).name, ['\d']) > 5
        rel_x_pos = 0.5 + 0.15;
    end

    imgs.Add(ii, 'original_matrix', {tmpimg}, ...
             'rel_x_pos', rel_x_pos, ...
             'rel_y_pos', 0.5, ...
             'rel_x_scale', 0.2, ...
             'rel_y_scale', nan);
end

blank_imgs = PobImage;
img_dir = 'images/';
img_names = dir('images/blank/*.png');
for ii = 1:length(img_names)
    tmpimg = imcomplement(...
        imread([img_dir, img_names(ii).name])...
        );
    rel_x_pos = 0.5 - 0.15;
    if img_names(1).name(7) == 'r'
        rel_x_pos = 0.5 + 0.15;
    end

    blank_imgs.Add(ii, 'original_matrix', {tmpimg}, ...
             'rel_x_pos', rel_x_pos, ...
             'rel_y_pos', 0.5, ...
             'rel_x_scale', 0.2, ...
             'rel_y_scale', nan);
end

%% Set up text
helptext = ['This experiment is\nTimed Response.\n', ...
            ];

info_txt = PobText('value', helptext, 'size', 50, ...
                   'color', [255 255 255], ...
                   'rel_x_pos', 0.5, ...
                   'rel_y_pos', 0.5,...
                   'style', 'bold');

% hardcoded indices at present, in the future parse unique(tgt.finger)?
kbrd = BlamForceboard([1:10]);

go_cue =  PobText('value', '+', 'size', 160, ...
                   'color', [255 255 255], ...
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
go_cue.Register(win.pointer);

% bailer
KbName('UnifyKeyNames');
RestrictKeysForKbCheck(KbName({'ESCAPE'}));

%TODO: handle data storage

% transition conditions

enter_intrial = @() 