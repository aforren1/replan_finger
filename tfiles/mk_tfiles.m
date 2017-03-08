function tbl = mk_tfiles(out_path, name, varargin)
% MK_TFILES generate trial table for replanning experiment.
%     tbl = mk_tfiles(path, name) make a sample trial table.
%   
% Required args:
%     path - Location where trial table should be written (as csv).
%     name - Name of the file (omit extension).
% 
% Optional args:
%     ind_finger - indices to use (1 to 10)
%     approx_trials - Approximate number of trials (rounds up) (default 100)
%     min_prep_time - Minimal preparation time (default 0.05 seconds)
%     max_prep_time - Max preparation time (default 0.5 seconds)
%     transition_prob - proportion of replan trials (default .3)
%     seed - seed for random number generator (default 1)
%
% Example:
%     tbl = mk_tfiles('tfiles/', 'testme', ...
%                     'ind_finger', [3 5 6 8], ...
%                     'approx_trials', 100, ...
%                     'transition_prob', 0.2, ...
%                     'seed', 5);

    p = inputParser;
    addRequired(p, 'out_path', @isstr);
    addRequired(p, 'name', @isstr);
    addParameter(p, 'approx_trials', 100, @isnumeric);
    addParameter(p, 'ind_finger', [3, 5, 6, 8], @(x) ~any(x > 10 | x < 1));
    addParameter(p, 'min_prep_time', 0.15, @(x) isnumeric(x) & x > 0);
    addParameter(p, 'max_prep_time', 0.55, @(x) isnumeric(x) & x > 0);
    addParameter(p, 'transition_prob', 0.3, @(x) x >= 0 & x <= 1);
    addParameter(p, 'seed', 1, @(x) rem(x, 1) == 0);
    parse(p, out_path, name, varargin{:});
    % access parameters via p.Results.<field>
    res = p.Results;
    
    rng(res.seed);
    same = transpose([res.ind_finger; res.ind_finger]);
    if res.transition_prob > 0 % any switches at all
        same_rep = repmat(same, ceil(((1 - res.transition_prob)*res.approx_trials)/length(res.ind_finger)), 1);

        diff1 = nchoosek(res.ind_finger, 2);
        diff2 = fliplr(diff1);
        both_diff = [diff1; diff2];

        diff_rep = repmat(both_diff, ceil((res.transition_prob*res.approx_trials)/length(both_diff)), 1);

        pairs = [same_rep; diff_rep];
    else
        pairs = repmat(same, ceil(res.approx_trials/length(res.ind_finger)), 1);
    end
    shuffled_inds = randperm(length(pairs));
    pairs = pairs(shuffled_inds, :);
    prep_times = res.min_prep_time + rand(length(pairs), 1) * ...
                        (res.max_prep_time - res.min_prep_time);
    tbl = table(prep_times, pairs(:, 1), pairs(:, 2),...
                'VariableNames', {'preparation_time', 'first_image', 'second_image'});
    writetable(tbl, [out_path, name, '.csv']);

end