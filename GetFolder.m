function ret = getFolder( folder )
% if folder does not exist, create it
if ~exist(folder)
    mkdir(folder);
    fprintf('Create folder: %s\n', folder);
end
ret = folder;

