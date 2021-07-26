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

# Create new nifti header with isotropic voxels
fslcreatehd 256 256 203 1 1 1 1 1 0 0 0 16  T1_1mm_ref.nii.gz

# for subject in ?????; do
for subject in ?????; do

	# Interpolate T1 volume to get isotropic
	echo $subject T1
	flirt -in ${subject}/anat/T1.nii.gz -applyxfm -init /usr/local/fsl/etc/flirtsch/ident.mat -out ${subject}/anat/T1_isotropic.nii.gz -paddingsize 0.0 -interp sinc -datatype float -ref T1_1mm_ref.nii.gz &
	check_jobs

	# Interpolate brainmask volume to get isotropic voxels
	echo $subject brainmask
	flirt -in ${subject}/anat/brainmask.nii.gz -applyxfm -init /usr/local/fsl/etc/flirtsch/ident.mat -out ${subject}/anat/brainmask_isotropic.nii.gz -paddingsize 0.0 -interp nearestneighbour -datatype float -ref T1_1mm_ref.nii.gz &
	check_jobs

	# Interpolate tumor mask volume to get isotropic voxels
	echo $subject tumor_mask
	flirt -in ${subject}/anat/tumor_mask_clean.nii.gz -applyxfm -init /usr/local/fsl/etc/flirtsch/ident.mat -out ${subject}/anat/tumor_mask_isotropic.nii.gz -paddingsize 0.0 -interp trilinear -datatype float -ref T1_1mm_ref.nii.gz &
	check_jobs

done

wait_finish

for subject in ?????; do

	for motion in 1 2 ; do

		case $motion in
			1)
				motion_str=standardmotion
				;;
			2)
				motion_str=extendedmotion
				;;
		esac

		for fwhm in 2 3 4 5 6 ; do

			str=motor_${fwhm}mm_$motion_str

			# finger
			echo $subject $str finger
			flirt -interp sinc -in ${subject}/out/${str}.feat/stats/zstat1.nii.gz -ref ${subject}/anat/T1_isotropic.nii.gz -applyxfm -init ${subject}/out/${str}.feat/reg/example_func2highres.mat -out ${subject}/out/${str}_zstat1_T1.nii.gz &
			check_jobs

			# foot
			echo $subject $str foot
			flirt -interp sinc -in ${subject}/out/${str}.feat/stats/zstat2.nii.gz -ref ${subject}/anat/T1_isotropic.nii.gz -applyxfm -init ${subject}/out/${str}.feat/reg/example_func2highres.mat -out ${subject}/out/${str}_zstat2_T1.nii.gz &
			check_jobs

			# mouth
			echo $subject $str mouth
			flirt -interp sinc -in ${subject}/out/${str}.feat/stats/zstat3.nii.gz -ref ${subject}/anat/T1_isotropic.nii.gz -applyxfm -init ${subject}/out/${str}.feat/reg/example_func2highres.mat -out ${subject}/out/${str}_zstat3_T1.nii.gz &
			check_jobs

		done

	done

done

wait_finish
