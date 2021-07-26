#!/bin/bash

# Extract subject data
echo "untaring files"
for file in orig_files/*.tar; do

  tar -xf $file

done

for subj in ?????; do

  echo -e "\n $subj"

  # Create forlders for data
  mkdir $subj/{anat,fmri}

  echo "extracting files"

  # Extract and rename T1
  fileT1=$(ls $subj/*COR_3D*.zip)
  unzip -q $fileT1 -d $subj/anat
  gzip -c $subj/anat/*COR_3D*/anon_*.nii > $subj/anat/T1.nii.gz
  rm -r $subj/anat/*COR_3D*

  # Extract and rename T2
  fileT2=$(ls $subj/*Axial_T2*.zip)
  unzip -q $fileT2 -d $subj/anat
  gzip -c $subj/anat/*Axial_T2*/anon_*.nii > $subj/anat/T2.nii.gz
  rm -r $subj/anat/*Axial_T2*

  # Extract and rename tumor segmentation
  fileTumor=$(ls $subj/tissue_classes.zip)
  unzip -q $fileTumor -d $subj/anat
  gzip -c $subj/anat/c3anon_*.nii > $subj/anat/tumor_mask.nii.gz
  rm $subj/anat/*anon*.nii

  # Create brainmask
  echo "creating brainmask"
  bet $subj/anat/T1.nii.gz $subj/anat/T1_brain.nii.gz -m -R -f 0.5
  mv $subj/anat/T1_brain_mask.nii.gz $subj/anat/brainmask.nii.gz

  # Extract and process motor fMRI
  fileMotor=$(ls $subj/*finger*.zip 2> /dev/null)

  if [[ -n $fileMotor ]]; then
    echo "processing motor fMRI"
    unzip -q $fileMotor -d $subj/fmri
    fslmerge -tr $subj/fmri/motor.nii.gz $subj/fmri/*finger*/*.nii 2.5
    fslroi $subj/fmri/motor.nii.gz $subj/fmri/motor.nii.gz 4 180
    rm -r $subj/fmri/*finger*
  else
    echo "no motor fMRI"
  fi

  # Extract and process verb generation fMRI
  fileVerb=$(ls $subj/*silent*.zip 2> /dev/null)

  if [[ -n $fileVerb ]]; then
    echo "processing verb generation fMRI"
    unzip -q $fileVerb -d $subj/fmri
    fslmerge -tr $subj/fmri/verb.nii.gz $subj/fmri/*silent*/*.nii 2.5
    fslroi $subj/fmri/verb.nii.gz $subj/fmri/verb.nii.gz 4 169
    rm -r $subj/fmri/*silent*
  else
    echo "no verb generation fMRI"
  fi

  # Extract and process word repetition fMRI
  fileWord=$(ls $subj/*word*.zip 2> /dev/null)

  if [[ -n $fileWord ]]; then
    echo "processing word repetition fMRI"
    unzip -q $fileWord -d $subj/fmri
    fslmerge -tr $subj/fmri/word.nii.gz $subj/fmri/*word*/*.nii 2.5
    fslroi $subj/fmri/word.nii.gz $subj/fmri/word.nii.gz 4 72
    # rm -r $subj/fmri/*word*
  else
    echo "no word repetition fMRI"
  fi

  # Delete zip files
  rm $subj/*.zip

done
