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

                if frame < image_frame_from_time
                    img.Draw(tgt.first_image(trial_count));
                else
                    img.Draw(tgt.second_image(trial_count));
                end

                % overshoot 'last frame' by a little for breathing room
                if frame >= (last_frame + 30)
                    enter_intrial = true;
                    state = 'feedback';
                end
            case 'feedback' % show feedback & wait
                if enter_feedback
                    enter_feedback = false;
                    aud.Stop(1);
                    fix_cross.Set('color', [255, 30, 63]);
                    if correct
                       aud.Play(2, 0);
                       fix_cross.Set('color', [97, 255, 77]);
                    end
                end
                
                img.Draw(tgt.second_image(trial_count));

                if exit_feedback
                    aud.Stop(2);
                    fix_cross.Set('color', [255 255 255]);
                    state = 'posttrial';
                    enter_feedback = true;
                end
            case 'posttrial'
                if enter_posttrial
                    enter_posttrial = false;
                    wait_secs = GetSecs + 1 + rand(1);
                end
                
                if GetSecs >= wait_secs
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

% bail out gracefully
catch err 
    ShowCursor;
    Priority(0);
    sca;
    try win.Close;
    catch 
        disp('Window not open.');
    end
    try
        kbrd.Close;
    catch
        disp('No keyboard open');
    end
    try
        aud.Close;
    catch
        disp('No audio device open.');
    end
    try
        if ~exist(data_dir, 'dir')
            mkdir(data_dir);
        end
        save(data_name, 'dat');
    catch
        disp('Data might not exist');
    end
    rethrow(err);
end
end