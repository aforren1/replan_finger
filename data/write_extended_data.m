
% list all potential data files
files = dir('*/*.mat');
files = struct2table(files);

% figues out junk files, and remove
demos = contains(files.name(:), 'demo');
tests = contains(files.name(:), 'test');

remove = bsxfun(@or, demos, tests);

files = files(~remove, :);

% iterate over table & build long-form data
for ii = 1:height(files)
    % all data called tgt
    name = strcat(files.folder(ii), '/', files.name(ii));
    load(name{1});
    tgt = struct2table(tgt);
    tgt(:, {'post_data', 'second_image_frame', ...
            'time_max_force', 'trial_start', 'last_beep', ...
            'last_beep_frame', 'block_start', 'second_image_sanity'}) = [];
    if ii == 1
        bigtgt = tgt;
    else
        bigtgt = [bigtgt; tgt];
    end
end

writetable(bigtgt, 'extended_data.csv');