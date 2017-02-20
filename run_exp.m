function [dat, frame_time] = run_exp()

try
    setup_exp;
    info_txt.Draw();
    win.Flip();
    WaitSecs(1);

    for ii = fliplr(1:5)
        helptext = ['Experiment starting in\n', ...
                    num2str(ii), ' seconds'];
        info_txt.Set('value', helptext);
        info_txt.Draw();
        win.Flip;
        WaitSecs(1);
    end

    % set various flags
    trial_count = 1;
    state = 'intrial';
    enter_intrial = true;
    save_img_time = true;
    enter_feedback = true;
    enter_posttrial = true;
    both_right = 0;
    draw_slow = false;
    draw_fast = false;
    frame = 0;
    fdc = 1;

    window_time = win.Flip();
    block_start = window_time;
    kbrd.Start();
    Priority(win.priority);

    % state machine
    while true
        % check for end of experiment
        if trial_count > length(tgt.preparation_time), break; end

        % bail out by clicking mouse
        [~, ~, tmp] = GetMouse;
        if any(tmp), break; end

        % get the most recent presses/releases
        [~, presses, ~, releases] = kbrd.Check;
        if ~isnan(presses)
            press_feedback.Set('color', [100 100 100]);
        end
        if ~isnan(releases)
            press_feedback.Set('color', [200 200 200]);
        end
        press_feedback.Draw();

        % draw constants
        blank_imgs.Draw(1:2);
        % state machine
        switch state
            case 'intrial' % dynamic bit
                if enter_intrial
                    frame = 1;
                    kbrd.CheckMid; % dump any in-between presses
                    trial_start = aud.Play(1, window_time + win.flip_interval);
                    enter_intrial = false;
                end

                if frame < 30
                    % block drawing until first beep
                elseif frame < tgt.second_image_frame(trial_count)
                    imgs.Draw(tgt.first_image(trial_count));
                elseif frame == tgt.second_image_frame(trial_count)
                    save_img_time = true;
                    imgs.Draw(tgt.second_image(trial_count));
                else
                    imgs.Draw(tgt.second_image(trial_count));
                end

                % overshoot 'last frame' by a little for breathing room
                if frame >= (last_frame + 20)
                    enter_intrial = true;
                    save_img_time = false;
                    state = 'feedback';
                end
            case 'feedback' % show feedback & wait
                if enter_feedback
                    enter_feedback = false;
                    aud.Stop(1);

                    % find what was pressed and when
                    [first_press, time_first_press, post_data, max_force, time_max_force] = kbrd.CheckMid();
                    tgt.first_press(trial_count) = first_press;
                    tgt.correct(trial_count) = first_press == tgt.second_image(trial_count);
                    tgt.time_first_press(trial_count) = time_first_press - trial_start;
                    tgt.real_prep_time(trial_count) = tgt.time_first_press(trial_count) - ...
                                                      tgt.second_image_sanity(trial_count);
                    tgt.max_force(trial_count) = max_force;
                    tgt.time_max_force(trial_count) = time_max_force;
                 %   post_data(:, 1) = post_data(:, 1) - trial_start;
                    tgt.post_data(trial_count) = {post_data};
                    tgt.trial_start(trial_count) = trial_start;
                    tgt.last_beep(trial_count) = last_beep;
                    tgt.last_beep_frame(trial_count) = last_frame;
                    tgt.diff_last_beep(trial_count) = tgt.time_first_press(trial_count) - last_beep;
                    tgt.block_start(trial_count) = block_start;
                    % debug chunk
                    disp(['First press: ', num2str(first_press)]);
                    disp(['Image index: ', num2str(tgt.second_image(trial_count))])
                    disp(['Correct: ', num2str(tgt.correct(trial_count))]);
                    disp(['Prep time: ', num2str(tgt.real_prep_time(trial_count))])
                    disp(['Distance from last beep: ', ...
                          num2str(tgt.diff_last_beep(trial_count))]);
                    
                    % correctness feedback
                    fix_cross.Set('color', [255, 30, 63]);
                    if tgt.correct(trial_count)
                        both_right = 1;
                        fix_cross.Set('color', [97, 255, 77]);
                    end
                    % timing feedback
                    if tgt.diff_last_beep(trial_count) > 0.1
                        draw_slow = true;
                    elseif tgt.diff_last_beep(trial_count) < -0.1
                        draw_fast = true;
                    else % good timing
                        both_right = both_right + 1;
                    end

                    if both_right == 2
                        aud.Play(2, 0);
                    end
                    both_right = 0;
                    % figure out how long to wait for feedback
                    end_feedback_frame = frame + 30;
                end
                
                imgs.Draw(tgt.second_image(trial_count));

                if frame >= end_feedback_frame
                    draw_slow = false;
                    draw_fast = false;
                    aud.Stop(2);
                    fix_cross.Set('color', [255 255 255]);
                    state = 'posttrial';
                    enter_feedback = true;
                end
            case 'posttrial'
                if enter_posttrial
                    enter_posttrial = false;
                    wait_frames = frame + (0.3 + rand(1))/win.flip_interval;
                end
                
                % wait until at least one press
                if frame >= wait_frames && ...
                   ((any(isnan(first_press)) && ~any(isnan(presses))) ...
                     || (~any(isnan(first_press))))
                    enter_posttrial = true;
                    trial_count = trial_count + 1;
                    state = 'intrial';
                end
        end % end state machine

        fix_cross.Draw();
        if draw_slow
            too_slow.Draw();
        elseif draw_fast
            too_fast.Draw();
        end
        window_time = win.Flip(window_time + 0.6 * win.flip_interval);

        if save_img_time && strcmp(state, 'intrial')
            save_img_time = false;
            tgt.second_image_sanity(trial_count) = window_time - trial_start;
            tgt.second_image_prep(trial_count) = last_beep - tgt.second_image_sanity(trial_count);
        end

        frame = frame + 1;
        % compare using this time for showing things
        frame_time(fdc) = window_time - block_start;
        fdc = fdc + 1;
        % for whatever reason, daq doesn't work properly w/o short pause
        pause(1e-5);
    end

    % cleanup
    Priority(0);
    win.Close();
    imgs.Close();
    blank_imgs.Close();
    sca;
    aud.Close();
    kbrd.Stop();
    kbrd.Close();

    % correct preparation time for identical image
    tgt(tgt.first_image == tgt.second_image,:).real_prep_time = tgt(tgt.first_image == tgt.second_image,:).time_first_press;
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    save([data_name, '.mat'], 'tgt');
    less_tgt = tgt;
    dat = tgt;
    less_tgt(:, {'post_data', 'max_force', 'time_max_force', 'post_data', 'trial_start', 'last_beep',...
                 'last_beep_frame', 'diff_last_beep', 'block_start', 'second_image_sanity', ...
                 'second_image_frame', 'preparation_time', 'second_image_prep', ...
                 'time_first_press'}) = [];
    writetable(less_tgt, [data_name, '.csv']);

% bail out gracefully
catch err 
    bailout;
    rethrow(err);
end
end