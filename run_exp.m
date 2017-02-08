function dat = run_exp(file_name, fullscreen)

try
    setup_exp;


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