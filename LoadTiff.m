function im = LoadTiff(fileName)
    fprintf('LoadTiff: %s\n', fileName);
    tic
    info = imfinfo(fileName);
    nz = size(info, 1);
    nx = info.Width;
    ny = info.Height;
    im = zeros(ny, nx, nz);

    for i = 1:nz
        im(:, :, i) = imread(fileName, i);
    end

    im = single(im);
    fprintf('LoadTiff: takes %f seconds\n', toc);
end
