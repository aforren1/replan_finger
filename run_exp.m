function dat = run_exp()

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
    state = 'pretrial';
    enter_intrial = true;
    save_img_time = true;
    enter_feedback = true;
    enter_posttrial = true;

    window_time = win.Flip();
    block_start = window_time;
    kbrd.Start();
    Priority(win.priority);

    % state machine
    while true
        % check for end of experiment
        if trial_count > length(tgt.preparation_time), break; end

        % bail out by holding esc
        tmp = KbCheck();
        if tmp, break; end

        % get the most recent presses/releases
        [~, presses] = kbrd.Check;

        % draw constants
        blank_imgs.Draw(1:2);
        % state machine
        switch state
            case 'intrial' % dynamic bit
                if enter_intrial
                    frame = 1;
                    trial_start = aud.Play(1, window_time + win.flip_interval);
                    image_frame_from_time = floor(tgt.preparation_time(trial_count)/win.flip_interval);
                    image_frame_from_time = last_frame - image_frame_from_time;
                    enter_intrial = false;
                end

                if frame < tgt.second_image_frame(trial_count)
                    img.Draw(tgt.first_image(trial_count));
                else
                    if save_img_time
                        save_img_time = false;
                        tgt.second_image_sanity(trial_count) = window_time + win.flip_interval - trial_start;
                    end
                    img.Draw(tgt.second_image(trial_count));
                end

                % overshoot 'last frame' by a little for breathing room
                if frame >= (last_frame + 30)
                    enter_intrial = true;
                    save_img_time = true;
                    state = 'feedback';
                end
            case 'feedback' % show feedback & wait
                if enter_feedback
                    enter_feedback = false;
                    aud.Stop(1);

                    % find what was pressed and when
                    [first_press, time_first_press, post_data, max_force, time_max_force] = kbrd.CheckMid();
                    tgt.first_press(trial_count) = first_press;
                    tgt.correct = first_press == tgt.second_image(trial_count);
                    tgt.time_first_press(trial_count) = time_first_press - trial_start;
                    tgt.real_prep_time(trial_count) = tgt.time_first_press(trial_count) - ...
                                                      tgt.second_image_sanity(trial_count);
                    tgt.max_force(trial_count) = max_force;
                    tgt.time_max_force(trial_count) = time_max_force;
                    post_data(:, 1) = post_data(:, 1) - trial_start;
                    tgt.post_data(trial_count) = post_data;
                    tgt.diff_last_beep(trial_count) = tgt.time_first_press(trial_count) - last_beep;
                    
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
                       aud.Play(2, 0);
                       fix_cross.Set('color', [97, 255, 77]);
                    end

                    % figure out how long to wait for feedback
                    end_feedback_frame = frame + 30;
                end
                
                img.Draw(tgt.second_image(trial_count));

                if frame >= end_feedback_frame
                    aud.Stop(2);
                    fix_cross.Set('color', [255 255 255]);
                    state = 'posttrial';
                    enter_feedback = true;
                end
            case 'posttrial'
                if enter_posttrial
                    enter_posttrial = false;
                    wait_frames = (0.5 + rand(1))/win.flip_interval;
                end
                
                if frame >= wait_frames
                    enter_posttrial = true;
                    trial_count = trial_count + 1;
                    state = 'pretrial';
                end
        end % end state machine

        fix_cross.Draw();
        window_time = win.Flip(window_time + 0.8 * win.flip_interval);
        frame = frame + 1;
        % compare using this time for showing things
        frame_delta = window_time - approx_next_frame_time;
        approx_next_frame_time = window_time + win.flip_interval;
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
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    save([data_name, '.mat'], 'tgt');
    less_tgt = tgt;
    less_tgt(:, {'post_data'}) = [];
    writetable(less_tgt, [data_name, '.csv']);

% bail out gracefully
catch err 
    bailout;
    rethrow(err);
end
end