% separate script for bailing out
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
    tgt = table2struct(tgt);
    save([data_name, '.mat'], 'tgt');
catch
    disp('Data might not exist');
end