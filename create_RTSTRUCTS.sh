#!/bin/bash

# Work order

# 1. Analyze fMRI data (analyze_all_subjects.sh)
# 2. Re-scale anatomical T1w volume to 1 mm isotropic, transform activity maps to this new T1 volume (transform_motor.sh)
# 3. Fit nifti volumes into 256 cubes, and then convert T1w brain volume to DICOM format (one DICOM file per slice) (nifti_to_dicom.m)
# 4. Run this script to Create RT struct files for tumor mask and brain activity maps


for subject in [0-9][0-9][0-9][0-9][0-9] ; do
# for subject in 17904 ; do


	dirRT=$subject/dicom/${subject}_dicom_RTSTRUCT/
	if [[ ! -d $dirRT ]] ; then
		mkdir $dirRT
	fi

	dirT1DICOM=$subject/dicom/${subject}_dicom/
	fileMask=$subject/anat/tumor_mask_isotropic_256cube.nii.gz
	dirfMRI=$subject/fmri_out/

	python3.7 convert_to_RTSTRUCT.py $fileMask $dirT1DICOM $dirRT ${subject}_Tumor Red

	python3.7 convert_to_RTSTRUCT.py $dirfMRI/motor_5mm_std-mot_zstat1_T1_z3.1_c10.nii.gz $dirT1DICOM $dirRT ${subject}_Finger Green

	python3.7 convert_to_RTSTRUCT.py $dirfMRI/motor_5mm_std-mot_zstat2_T1_z3.1_c10.nii.gz $dirT1DICOM $dirRT ${subject}_Foot Blue

	python3.7 convert_to_RTSTRUCT.py $dirfMRI/motor_5mm_std-mot_zstat3_T1_z3.1_c10.nii.gz $dirT1DICOM $dirRT ${subject}_Lips Yellow

done
