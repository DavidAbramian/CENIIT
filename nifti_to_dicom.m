

Subject = '17904';

% Load DICOM header
fileDICOM = 'template.dcm';
infoDICOM = dicominfo(fileDICOM);

% Load volumes from NifTI files
for file = 1:4
    
    if file == 1
        description = 'finger';
    elseif file == 2
        description = 'foot';
    elseif file == 3
        description = 'lips';
    elseif file == 4
        description = 'tumor_mask_isotropic';
    end
    
    fileNifti = [Subject '_' description '.nii.gz'];
    info = niftiinfo(fileNifti);
    vol = niftiread(info);
    tmp = zeros(256,256,256);
    tmp(:,:,1+20:203+20) = vol;
    vol = tmp;
    tmp = zeros(256,256,256);
    nSlices = size(vol,3);
    for i = 1:nSlices
        slice = squeeze(vol(:,i,:));
        tmp(:,:,i) = slice;
    end
    vol = tmp;
    info.ImageSize = [256 256 256];
    info.raw.dim = [3 256 256 256 1 1 1 1];
    niftiwrite(single(vol),[Subject '_' description '_256cube.nii'],info)
end

% Load T1 volume from NifTI file
fileNifti = [Subject '_T1_isotropic.nii.gz'];
vol = niftiread(fileNifti);
tmp = zeros(256,256,256);
tmp(:,:,1+20:203+20) = vol;
vol = tmp;

% Split single 3D DICOM into slices

nSlices = size(vol,3);
for i = 1:nSlices
    
    % Take single slice. Flip for correct patient orientation
    slice = uint16(squeeze(vol(:,i,:))');
    %slice = uint16(vol(:,:,i));
    
    %imagesc(slice); colormap gray
    %pause(0.1)
    
    % Create DICOM header
    md = infoDICOM;
    md.ImagePositionPatient(1) = 0;
    md.ImagePositionPatient(2) = 0;
    md.ImagePositionPatient(3) = 0;
    md.Height = 256;
    
    % These must have not been necessary in the end
    %     md.SpecificCharacterSet = 'ISO_IR 100';
    %     md.LargestImagePixelValue = max(slice(:));
    
    % These fields will be visible when loading data in GammaPlan
    md.PatientName = 'David Davidsson';
    md.PatientID = '18975 3';
    %     md.SeriesNumber = 1002;  % This field is used to have several MR sequences under the same patient, but I couldn't get it to work properly
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
    fOut = fullfile('dicom', ['test', num2str(i, '%.3i'), '.dcm']);
    x = dicomwrite(slice, fOut, md, 'ObjectType', 'MR Image Storage');
    
end

