clc;clear;
addpath(genpath('utils'));
PSF_Genpath = 'psf\16x';
LF_path = 'LF';
LF_subpath = '';
FL_name = 'gaussian';
resultSave_path = ['Rec','\',LF_subpath];
PSF_path = fullfile(PSF_Genpath,FL_name);
%% loading PSFs
disp('Loading PSFs...');
for i = 1:21
    psfs(:,:,:,i) = LoadTiff(fullfile(PSF_path,sprintf('%d.tif',i)));
end
psfs = psfs./max(psfs(:));
disp('PSFs loaded');
%% loading images
Filename = fullfile([LF_path,'\',LF_subpath, '\'],[FL_name,'.tif']);
disp('Loading raw data...');
projs = single(LoadTiff(Filename));
disp('Raw data loaded');
%%
reconOpts.DAO = 1; % DAO on
[Xguess,shiftMap,dispMap,~] = reconPipeline(psfs,projs,resultSave_path,reconOpts);
stackForSave = gather(Xguess);
write3d(stackForSave*100,fullfile(resultSave_path,[FL_name,'.tif']),16);
