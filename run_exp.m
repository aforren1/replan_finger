function dat = run_exp(file_name, fullscreen)

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

    % state machine
    while true
        if trial_count > length(tgt.trial)
            % end of experiment
            break;
        end
        % bail out by holding esc
        tmp = KbCheck();
        if tmp
            break;
        end

        % get the most recent presses/releases
        [~, presses] = kbrd.Check;
        % state machine
        switch state
            case 'pretrial' % single-frame setup for trial
                
                state = 'intrial';
            case 'intrial' % dynamic bit
                if enter_intrial
                    frame = 1;
                    
                end

                if exit_intrial
             
                end
            case 'feedback' % show feedback & wait
                if enter_feedback

                end

                if exit_feedback
                    frame = 0;
                    trial_count = trial_count + 1;
                end
        end
        
        window_time = win.Flip(window_time + 0.8 * win.flip_interval);
        frame = frame + 1;
        % compare using this time for showing things
        approx_next_frame_time = window_time + win.flip_interval;
    end

    % cleanup

% bail out gracefully
catch err 
    ShowCursor;
    Priority(0);
    sca;
    try
        kbrd.Close;
    catch
        disp('No keyboard open');
    end
    try
        PsychPortAudio('Close');
    catch
        disp('No audio device open.');
    end
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    save(data_name, 'dat');
    rethrow(err);
end
end