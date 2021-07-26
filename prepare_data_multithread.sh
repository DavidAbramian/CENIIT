#!/bin/bash

maxJobs=6 # Max number of parallel jobs

# Extract subject data
echo "untaring files"
for file in orig_files/*.tar; do

  tar -xf $file

done

echo ""

# Function that carries out all the processing for a single subject
process_subj () {

  local subj=$1

  echo $subj

  # Create forlders for data
  mkdir $subj/{anat,fmri}

  # Extract and rename T1
  local fileT1=$(ls $subj/*COR_3D*.zip)
  unzip -q $fileT1 -d $subj/anat
  gzip -c $subj/anat/*COR_3D*/anon_*.nii > $subj/anat/T1.nii.gz
  rm -r $subj/anat/*COR_3D*

  # Fix T1 orientation
  fslswapdim $subj/anat/T1.nii.gz x -z y $subj/anat/T1.nii.gz

  # Extract and rename T2
  local fileT2=$(ls $subj/*Axial_T2*.zip)
  unzip -q $fileT2 -d $subj/anat
  gzip -c $subj/anat/*Axial_T2*/anon_*.nii > $subj/anat/T2.nii.gz
  rm -r $subj/anat/*Axial_T2*

  # Extract and rename tumor segmentation
  local fileTumor=$(ls $subj/tissue_classes.zip)
  unzip -q $fileTumor -d $subj/anat
  gzip -c $subj/anat/c3anon_*.nii > $subj/anat/tumor_mask.nii.gz
  rm $subj/anat/*anon*.nii

  # Create brainmask
  # bet $subj/anat/T1.nii.gz $subj/anat/T1_brain.nii.gz -m -R -f 0.5
  # mv $subj/anat/T1_brain_mask.nii.gz $subj/anat/brainmask.nii.gz
  bet $subj/anat/T1.nii.gz $subj/anat/T1_brain.nii.gz -R -f 0.5

  # Extract and process motor fMRI
  local fileMotor=$(ls $subj/*finger*.zip 2> /dev/null)

  if [[ -n $fileMotor ]]; then
    unzip -q $fileMotor -d $subj/fmri
    fslmerge -tr $subj/fmri/motor.nii.gz $subj/fmri/*finger*/*.nii 2.5
    fslroi $subj/fmri/motor.nii.gz $subj/fmri/motor.nii.gz 4 180
    rm -r $subj/fmri/*finger*
  fi

  # Extract and process verb generation fMRI
  local fileVerb=$(ls $subj/*silent*.zip 2> /dev/null)

  if [[ -n $fileVerb ]]; then
    unzip -q $fileVerb -d $subj/fmri
    fslmerge -tr $subj/fmri/verb.nii.gz $subj/fmri/*silent*/*.nii 2.5
    fslroi $subj/fmri/verb.nii.gz $subj/fmri/verb.nii.gz 4 169
    rm -r $subj/fmri/*silent*
  fi

  # Extract and process word repetition fMRI
  local fileWord=$(ls $subj/*word*.zip 2> /dev/null)

  if [[ -n $fileWord ]]; then
    unzip -q $fileWord -d $subj/fmri
    fslmerge -tr $subj/fmri/word.nii.gz $subj/fmri/*word*/*.nii 2.5
    fslroi $subj/fmri/word.nii.gz $subj/fmri/word.nii.gz 4 72
    rm -r $subj/fmri/*word*
  fi

  # Delete zip files
  rm $subj/*.zip

}

for subj in [0-9][0-9][0-9][0-9][0-9] ; do

  # Process subject
  process_subj $subj &

  # Start a new job as soon as another one finishes
  while [[ $(jobs -r | wc -l) -ge $maxJobs ]]; do
    sleep 1
  done

done

# Wait for remaining jobs to finish
while [[ $(jobs -r | wc -l) -gt 0 ]]; do
  sleep 1
done
