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
%     repeats - Number of times to repeat each ind_finger (default 5)
%     min_prep_time - Minimal preparation time (default 0.05 seconds)
%     max_prep_time - Max preparation time (default 0.9 seconds)
%     transition_prob - proportion of replan trials (default .3)
%     seed - seed for random number generator (default 1)
%
% Example:
%     tbl = mk_tfiles('tfiles/', 'testme', ...
%                     'ind_finger', [3 5 6 8], ...
%                     'repeats', 10, ...
%                     'transition_prob', 0.2, ...
%                     'seed', 5);

    p = inputParser;
    addRequired(p, 'out_path', @isstr);
    addRequired(p, 'name', @isstr);
    addParameter(p, 'repeats', 5, @isnumeric);
    addParameter(p, 'ind_finger', [3, 5, 6, 8], @(x) ~any(x > 10 | x < 1));
    addParameter(p, 'min_prep_time', 0.05, @(x) isnumeric(x) & x > 0);
    addParameter(p, 'max_prep_time', 0.9, @(x) isnumeric(x) & x > 0);
    addParameter(p, 'transition_prob', 0.3, @(x) x >= 0 & x <= 1);
    addParameter(p, 'seed', 1, @(x) rem(x, 1) == 0);
    parse(p, out_path, name, varargin{:});
    % access parameters via p.Results.<field>
    res = p.Results;
    
    rng(res.seed);
    pairs = repmat(res.ind_finger, 2, res.repeats);
    n_elements = length(pairs);
    frac_elements = ceil(n_elements * res.transition_prob);

    % if there are swaps, try to generate new pairings
    if frac_elements ~= 0
        indices = randperm(n_elements, frac_elements);    
        maxit = 1e6;
        for ii = 1:maxit
            % shuffle indices and try to get it so that 
            % 
            mod_indices = indices(randperm(length(indices)));
            pairs(2, indices) = pairs(2, mod_indices);
            if ~any(pairs(1, indices) - pairs(2, indices) == 0)
                break
            end
        end
        if ii == maxit
            error('Max iterations exceeded.');
        end
    end

    prep_times = res.min_prep_time + rand(n_elements, 1) * ...
                        (res.max_prep_time - res.min_prep_time);
    pairs = pairs';
    tbl = table(prep_times, pairs(:, 1), pairs(:, 2),...
                'VariableNames', {'preparation_time', 'first_image', 'second_image'});
    writetable(tbl, [out_path, name, '.csv']);

end