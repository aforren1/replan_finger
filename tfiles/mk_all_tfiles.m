% generate all finger pairs
subject_id = '001';
row = 4; % number from 1-6
all_comb = [1 3 8 10; 1 4 7 10; 1 5 6 10; 2 4 7 9; 2 5 6 9; 3 5 6 8];

%this_comb = all_comb(randperm(size(all_comb, 1), 1),:);
this_comb = all_comb(row, :);
dir_stub = ['tfiles/', subject_id, '/'];
if ~exist(dir_stub, 'dir')
    mkdir(dir_stub);
end  
% make a warmup block
mk_tfiles(dir_stub, ['demo'], 'ind_finger', this_comb, ...
          'transition_prob', 0, 'seed', 1, ...
          'approx_trials', 50);

for i = 1:15
    mk_tfiles(dir_stub, ['block', num2str(i)], ...
            'ind_finger', this_comb, ...
            'approx_trials', 100, ...
            'transition_prob', 0.3, ...
            'seed', i);
end