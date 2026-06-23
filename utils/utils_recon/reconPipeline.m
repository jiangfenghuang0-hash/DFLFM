% Reconstruction pipeline for 2pSAM
%
% ELi, 20230208, rearrange inputs, delete unused functions and add comments
function [Xguess,shiftMap,dispMap,reconOpts] = reconPipeline( psfs,projs,saveFolder,reconOpts)
% INPUT
%     psfs      - 3D psfs used for reconstruction, (usually) 4D matrix
%     projs     - 2D projections to be reconstructed, (usually) 3D matrix
%     saveFolder - save reconstruction results&&options in this folder
%     reconOpts - options for 3D reconstruction, struct (default)
%                 .maxIter: max iterations (10)
%                 .solver: reconstruction algorithm (fRL)
%                 .upWeight: weight for volume update in each iteration (.5)
%                 .upSeq: updating sequence for projections from different angles
%                 .CAIndex: index of centre projection in projs (1)
%                 .initMethod: volume initialization method ('all1')
%                 .gpuSelect: GPU used (1)
%                 .startFrame: frame to start reconstruction (1)
%                 .step: skip frames to reconstruction (13)
%                 .endFrame: frame to end reconstruction (inf)
%                 .savepath: folder to save results. If not given, generate a folder in saveFolder and save results there
%                 .tifSaveOn: iterations save flag (.tif), 0/1 (0)
%                 .matSaveOn: iterations save flag (.mat), 0/1 (0)
%                 .dispOn: display reconstruction process flag, 0/1 (1)
%                 .project_cutz: slices cut for projection (bilateral) (20)
%                 .project_cutx: pixels cut in x-dim for projection (bilateral) (0)
%                 .project_cuty: pixels cut in y-dim for projection (bilateral) (0)
%                 .project_opt: self defined project options (e.g. {'MEANy',125,130,506,112,522,151})
%                 .DAO: DAO flag, 0/1
%                 .DAOOpts: options for DAO
%                     .maxIter_init: max iteration without DAO
%                     .shiftEstFunc: function used for shift estimation
%                     .patchN: number of patches for multi-site shift estimation
%                     .patchOvFactor: overlap factor for multi-site shift estimation
%                     .minPatchSize: minimum patch size for multi-site shift estimation
%                     .sidelobe: sidelobe in pixel for shift estimation
%                     .sidelobez: use only the high-resolution regime for shift estimation
%                 .demotion: demotion flag, 0/1
%                 .demotionOpts: options for motion correction
%                     .maxIter_init: iterations without shift estimation in each iteration of demotion
%                     .maxIter: iterations without+out shift estimation in each iteration of demotion
%                     .shiftEstFunc: function used for shift estimation
%                     .patchN: number of patches for multi-site shift estimation
%                     .patchOvFactor: overlap factor for multi-site shift estimation
%                     .minPatchSize: minimum patch size for multi-site shift estimation
%                     .sidelobe: sidelobe in pixel for shift estimation
%                     .sidelobez: use only the high-resolution regime for shift estimation
%                     .thrMSE: the motion map converges if its increments are small enough
%                     .maxIterDemotion: max iterations to quit demotion if the motion map does not converge
%                     .maxShift: max shift in pixel for each iteration of demotion
%                     .angDistx_normed: PSF angle distribution, x, to remove the defocus item when initializing motion map
%                     .angDisty_normed: PSF angle distribution, y, to remove the defocus item when initializing motion map

%% default recon options
if ~exist('reconOpts','var');reconOpts = struct;end
% .maxIter: max iterations (10)
if ~isfield(reconOpts,'maxIter');reconOpts.maxIter = 3;end
% .solver: reconstruction algorithm (fRL): fRL/RL
if ~isfield(reconOpts,'solver');reconOpts.solver = 'fRL';end
% .upWeight: weight for volume update in each iteration (.5): 0-1
if ~isfield(reconOpts,'upWeight');reconOpts.upWeight = 0.5;end
if ~isfield(reconOpts,'initMethod');reconOpts.initMethod = 'all1';end
% .gpuSelect: GPU used (1)
if ~isfield(reconOpts,'gpuSelect');reconOpts.gpuSelect = 1;end
% .startFrame: frame to start reconstruction (1)
if ~isfield(reconOpts,'startFrame');reconOpts.startFrame = 1;end
% .endFrame: frame to end reconstruction (inf)
if ~isfield(reconOpts,'endFrame');reconOpts.endFrame = size(projs,3);end
reconOpts.endFrame = min(reconOpts.endFrame,size(projs,3));
% .tifSaveOn: iterations save flag (.tif), 0/1 (0)
if ~isfield(reconOpts,'tifSaveOn');reconOpts.tifSaveOn = 0;end
% .matSaveOn: iterations save flag (.mat), 0/1 (0)
if ~isfield(reconOpts,'matSaveOn');reconOpts.matSaveOn = 0;end
% .dispOn: display reconstruction process flag, 0/1 (1)
if ~isfield(reconOpts,'dispOn');reconOpts.dispOn = 1;end
% .DAO: DAO flag, 0/1
if ~isfield(reconOpts,'DAO');reconOpts.DAO = 1;end
reconOpts.savepath = saveFolder;
% .savepath: folder to save results. If not given, generate a folder in saveFolder and save results there

if ~isfield(reconOpts,'savepath');reconOpts.savepath = savepath_def;end
if ~exist(reconOpts.savepath,'dir');mkdir(reconOpts.savepath);end
%%% save recon options in savepath
%% size and other preparations
psfs = single(psfs); projs = single(projs); % singular resolution is enough in most cases
[~, ~, ~, angleNum]=size(psfs); [~,~,frameNum]=size(projs);
gpuDevice(reconOpts.gpuSelect);

%% Xguess initialization
[Xguess_init, reconOpts] = initXguess( psfs,projs,reconOpts.initMethod,reconOpts);

%% frame-by-frame reconstruction

    %% select solver and start reconstruction

    switch reconOpts.solver
        case 'fRL'
            [Xguess,shiftMap,dispMap] = recon_fRL_GPU(psfs,projs,reconOpts,Xguess_init);
        case 'RL'
            [Xguess,shiftMap,dispMap] = recon_RL_GPU( psfs,projs,reconOpts,Xguess_init);
    end

