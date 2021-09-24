
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

FWHMs = 2:6;
contrasts = 1:3;
motion_params = 1:2;

for s = 1:nSubjects
    
    subject_id = dirSubj(s).name;
    
    %% Save activation maps in cube volumes
    
    % Load brain activity maps and tumor mask from NifTI files
    for fwhm = FWHMs
        
        for m = motion_params
            
            switch m
                case 1
                    mot_str = 'std-mot';
                case 2
                    mot_str = 'ext-mot';
            end
            
            for contrast = contrasts
                
                fprintf('subj: %s, fwhm: %i, mot: %s, cont: %i\n', subject_id, fwhm, mot_str, contrast)
                
%                 fNameContrast = ['motor_5mm_std-mot_zstat', num2str(contrast), '_T1.nii.gz'];
                fNameContrast = ['motor_', num2str(fwhm), 'mm_', mot_str, '_zstat', num2str(contrast), '_T1.nii.gz'];
                fileContrast = fullfile(dataPath, subject_id, 'fmri_out', fNameContrast);
                info = niftiinfo(fileContrast);
                vol = niftiread(info);
                
                % Put volume in 256 cube, pad with zeros
                tmp = zeros(256,256,256);
                tmp(:,1+20:203+20,:) = vol;
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
                fNameOut = [fNameContrast(1:end-7) '_z', num2str(voxel_threshold),'_c', num2str(clustersize_threshold),'.nii'];
                fileOut = fullfile(dataPath, subject_id, 'fmri_out', fNameOut);
                niftiwrite(single(vol), fileOut, info);
                system(['pigz -f ', fileOut]);
                
            end
            
        end
        
    end
    
end
