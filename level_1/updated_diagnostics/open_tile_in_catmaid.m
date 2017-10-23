function open_tile_in_catmaid(~,~,url)
    command = sprintf('ssh -X c11u25 "firefox %s & exit"',url);
    system(command);
end