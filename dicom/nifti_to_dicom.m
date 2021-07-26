
% Work order

% 1. Analyze fMRI data (analyze_all_subjects.sh)
% 2. Re-scale anatomical T1w volume to 1 mm isotropic, transform activity maps to this new T1 volume (transform_motor.sh)
% 3. Run this script, to fit nifti volumes into 256 cubes, and then convert T1w brain volume to DICOM format (one DICOM file per slice)
% 4. Create RT struct files for tumor mask and activity maps (create_RTSTRUCTS.sh)


% Parameters
voxel_threshold = 3.1;
clustersize_threshold = 10;
clustersize_threshold_T1 = clustersize_threshold * 4 * 4 * 4; % T1 volume is 1 x 1 x 1 mm, fMRI volume is 4 x 4 x 4 mm

% Find subject folders
dataPath = '/flush/davab27/CENIIT/data';
dirSubj = dir(dataPath);
names = string({dirSubj(:).name}');
ISubjects = cellfun(@(x)length(x)==5, regexp(names, '[0-9]'));  % Check if the file/folder name consists of 5 numbers
dirSubj = dirSubj(ISubjects);

nSubjects = length(dirSubj);

% Load DICOM header
fileDICOM = 'template.dcm';
infoDICOM = dicominfo(fileDICOM);

for s = 1:1
    
    subject_id = dirSubj(s).name;
    
    %% Save activation maps in cube volumes
    
    % Load brain activity maps and tumor mask from NifTI files
    for contrast = 1:3
        
        fNameConstrast = ['motor_5mm_standardmotion_zstat', num2str(contrast), '_T1.nii.gz'];
        fileContrast = fullfile(dataPath, subject_id, 'out', fNameConstrast);
        info = niftiinfo(fileContrast);
        vol = niftiread(info);
        
        % Put volume in 256 cube, pad with zeros
        tmp = zeros(256,256,256);
        tmp(:,1+20:202+20,:) = vol;
        vol = tmp;
        info.ImageSize = [256 256 256];
        info.raw.dim = [3 256 256 256 1 1 1 1];
        
        info.Transform.T = eye(4);
        info.Transform.T(1,1) = -1;
        
        % Z-value threshold
        vol = double(vol > voxel_threshold);
        
        % Cluster size threshold, remove small clusters
        cc = bwconncomp(vol);
        for c = 1:cc.NumObjects
            if length(cc.PixelIdxList{c}) < clustersize_threshold_T1
                vol(cc.PixelIdxList{c}) = 0;
            end
        end
        
        % Save as new nifti file
        fNameOut = [fNameConstrast(1:end-7) '_z', num2str(voxel_threshold),'_c', num2str(clustersize_threshold),'.nii'];
        fileOut = fullfile(dataPath, subject_id, 'out', fNameOut);
        niftiwrite(single(vol), fileOut, info);
        system(['pigz -f ', fileOut]);
        
    end
    
    %% Save tumor mask in cube volume
    
    fileBrainmask = fullfile(dataPath, subject_id, 'anat', 'tumor_mask_isotropic.nii.gz');
    info = niftiinfo(fileBrainmask);
    vol = niftiread(info);

    % Put volume in 256 cube, pad with zeros
    tmp = zeros(256,256,256);
    tmp(:,1+20:202+20,:) = vol;
    vol = tmp;
    info.ImageSize = [256 256 256];
    info.raw.dim = [3 256 256 256 1 1 1 1];

    info.Transform.T = eye(4);
    info.Transform.T(1,1) = -1;
    
    fileOut =[fileBrainmask(1:end-7), '_256cube.nii'];
    niftiwrite(single(vol), fileOut, info);
    system(['pigz -f ', fileOut]);
    
    %% Save T1 in cube volume
    
    fileT1 = fullfile(dataPath, subject_id, 'anat', 'T1_isotropic.nii.gz');
    info = niftiinfo(fileT1);
    vol = niftiread(info);

    % Put volume in 256 cube, pad with zeros
    tmp = zeros(256,256,256);
    tmp(:,1+20:202+20,:) = vol;
    vol = tmp;
    info.ImageSize = [256 256 256];
    info.raw.dim = [3 256 256 256 1 1 1 1];

    info.Transform.T = eye(4);
    info.Transform.T(1,1) = -1;
    
    fileOut =[fileT1(1:end-7), '_256cube.nii'];
    niftiwrite(single(vol), fileOut, info);
    system(['pigz -f ', fileOut]);

    %% Conver T1 to DICOM
    
    % Create output folder for DICOM files
    dirOutDicom = fullfile(dataPath, subject_id, 'dicom');
    if ~exist(dirOutDicom, 'dir')
        mkdir(dirOutDicom)
    end
    
    % Load T1w brain volume from NifTI file
    fileT1 = fullfile(dataPath, subject_id, 'anat', 'T1_isotropic.nii.gz');
    vol = niftiread(fileT1);
    
    % Put volume in 256 cube, pad with zeros
    tmp = zeros(256,256,256);
    tmp(:,1+20:202+20,:) = vol;
    vol = tmp;
    
    % Split single 3D volume into one DICOM file per slice
    nSlices = size(vol,3);
    for i = 1:nSlices
        
        progresss(i, nSlices, 'Saving DICOM... ')
        
        % Take single slice. Flip for correct patient orientation
        %         slice = uint16(squeeze(vol(:,i,:))');
        
        slice = uint16(rot90(vol(:,:,i)));
        
        %imagesc(slice); colormap gray
        %pause(0.1)
        
        % Create DICOM header
        md = infoDICOM;
        md.ImagePositionPatient(1) = 0;
        md.ImagePositionPatient(2) = 0;
        md.ImagePositionPatient(3) = 0;
        md.Rows = size(slice,1);
        md.Columns = size(slice,2);
        
        % Not necessary?
        %     md.SpecificCharacterSet = 'ISO_IR 100';
        %     md.LargestImagePixelValue = max(slice(:));
        
        % These fields will be visible when loading data in GammaPlan
        md.PatientName = [subject_id '_Test_D3']; % Update when creating new files
        md.PatientID = [subject_id '_Test_D3']; % Update when creating new files
        %     md.SeriesNumber = 1002;  % To have several MR images for the same patient, not necessary ?
        md.SeriesDescription = 'T1w';
        md.MRAcquisitionType = '2D';
        
        md.InstanceNumber = i;  % Slice number
        
        % From standard: "specifies the x, y, and z coordinates of the upper left hand corner of the image"
        md.ImagePositionPatient(3) = md.ImagePositionPatient(3)+i;
        
        % Replacing field from the 3D DICOM to the 2D version
        %md.SliceLocation = md.SliceLocationVector(i);
        md.SliceLocation = i;
        md = rmfield(md, 'SliceLocationVector');
        
        md.PatientPosition = 'HFS';  % Head-first position
        
        md.ImageOrientationPatient(5) = 1;  % This is necessary for GammaPlan
        
        % Save slice as DICOM file
        fOut = fullfile(dirOutDicom, ['slice', num2str(i, '%.3i'), '.dcm']);
        x = dicomwrite(slice, fOut, md, 'ObjectType', 'MR Image Storage');
        
    end
    
end
