for i = 1:15
    mk_tfiles('tfiles/', ['block', num2str(i)], ...
            'ind_finger', [3 5 6 8], ...
            'approx_trials', 100, ...
            'transition_prob', 0.3, ...
            'seed', i);
end