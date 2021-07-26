#!/bin/bash

# Work order

# 1. Analyze fMRI data (analyze_all_subjects.sh)
# 2. Re-scale anatomical T1w volume to 1 mm isotropic, transform activity maps to this new T1 volume (transform_motor.sh)
# 3. Fit nifti volumes into 256 cubes, and then convert T1w brain volume to DICOM format (one DICOM file per slice) (nifti_to_dicom.m)
# 4. Run this script to Create RT struct files for tumor mask and brain activity maps 

# conda activate nnUNetDicom

data_directory=/home/andek67/Research_projects/CENIIT/Edinburgh

Analysis=motor_5mm_standardmotion

for Subject in 17904 18582 18975 19015 19275 19849; do
#for Subject in 17904 ; do
#for Subject in 18582 ; do
#for Subject in 19015 19275 ; do        
	
	python3.7 convert_to_RTSTRUCT.py ${data_directory}/${Subject}/tumor_mask_isotropic_256cube.nii.gz ${Subject}_dicom/ ${Subject}_dicom_RTSTRUCT/ ${Subject}_Tumor Red

	python3.7 convert_to_RTSTRUCT.py ${data_directory}/${Subject}/${Analysis}_zstat1_T1_256cube.nii.gz ${Subject}_dicom/ ${Subject}_dicom_RTSTRUCT/ ${Subject}_Finger Green

	python3.7 convert_to_RTSTRUCT.py ${data_directory}/${Subject}/${Analysis}_zstat2_T1_256cube.nii.gz ${Subject}_dicom/ ${Subject}_dicom_RTSTRUCT/ ${Subject}_Foot Blue

	python3.7 convert_to_RTSTRUCT.py ${data_directory}/${Subject}/${Analysis}_zstat3_T1_256cube.nii.gz ${Subject}_dicom/ ${Subject}_dicom_RTSTRUCT/ ${Subject}_Lips Yellow

done






#gzip ${data_directory}/${Subject}_tumor_mask_isotropic_256cube.nii

#gzip ${data_directory}/${Subject}_finger_256cube.nii

#gzip ${data_directory}/${Subject}_foot_256cube.nii

#gzip ${data_directory}/${Subject}_lips_256cube.nii
