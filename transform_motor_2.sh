#!/bin/bash

# Work order

# 1. Analyze fMRI data (analyze_all_subjects.sh)
# 2. Re-scale anatomical T1w volume to 1 mm isotropic, transform activity maps to this new T1 volume (this script)
# 3. Fit nifti volumes into 256 cubes, and then convert T1w brain volume to DICOM format (one DICOM file per slice) (nifti_to_dicom.m)
# 4. Create RT struct files for tumor mask and brain activity maps (create_RTSTRUCTS.sh)

maxJobs=6
check_jobs () {
	while [[ $(jobs -r | wc -l) -ge $maxJobs ]]; do
		sleep 1
	done
}
wait_finish () {
	while [[ $(jobs -r | wc -l) -gt 0 ]]; do
	  sleep 1
	done
}

# for subject in ?????; do
for subject in [0-9][0-9][0-9][0-9][0-9] ; do

	# Interpolate T1 volume to get isotropic
	echo $subject T1
	flirt -in ${subject}/anat/T1.nii.gz -ref ${subject}/anat/T1.nii.gz -applyisoxfm 1.0 -out ${subject}/anat/T1_isotropic.nii.gz -interp sinc -datatype float &
	check_jobs

	# # Interpolate brainmask volume to get isotropic voxels
	# echo $subject brainmask
	# flirt -in ${subject}/anat/brainmask.nii.gz -ref ${subject}/anat/brainmask.nii.gz -applyisoxfm 1.0 -out ${subject}/anat/brainmask_isotropic.nii.gz -interp nearestneighbour -datatype float &
	# check_jobs

	# Interpolate tumor mask volume to get isotropic voxels
	echo $subject tumor_mask
	flirt -in ${subject}/anat/tumor_mask_clean.nii.gz -ref ${subject}/anat/tumor_mask_clean.nii.gz -applyisoxfm 1.0 -out ${subject}/anat/tumor_mask_isotropic.nii.gz -interp trilinear -datatype float &
	check_jobs

done

wait_finish

for subject in [0-9][0-9][0-9][0-9][0-9] ; do

	for motion in 1 2 ; do

		case $motion in
			1)
				motion_str=std-mot
				;;
			2)
				motion_str=ext-mot
				;;
		esac

		for fwhm in 2 3 4 5 6 ; do

			str=motor_${fwhm}mm_$motion_str

			# finger
			echo $subject $str finger
			flirt -interp sinc -in ${subject}/fmri_out/${str}.feat/stats/zstat1.nii.gz -ref ${subject}/anat/T1_isotropic.nii.gz -applyxfm -init ${subject}/fmri_out/${str}.feat/reg/example_func2highres.mat -out ${subject}/fmri_out/${str}_zstat1_T1.nii.gz &
			check_jobs

			# foot
			echo $subject $str foot
			flirt -interp sinc -in ${subject}/fmri_out/${str}.feat/stats/zstat2.nii.gz -ref ${subject}/anat/T1_isotropic.nii.gz -applyxfm -init ${subject}/fmri_out/${str}.feat/reg/example_func2highres.mat -out ${subject}/fmri_out/${str}_zstat2_T1.nii.gz &
			check_jobs

			# mouth
			echo $subject $str mouth
			flirt -interp sinc -in ${subject}/fmri_out/${str}.feat/stats/zstat3.nii.gz -ref ${subject}/anat/T1_isotropic.nii.gz -applyxfm -init ${subject}/fmri_out/${str}.feat/reg/example_func2highres.mat -out ${subject}/fmri_out/${str}_zstat3_T1.nii.gz &
			check_jobs

		done

	done

done

wait_finish
