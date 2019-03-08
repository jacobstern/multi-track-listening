import uniqid from 'uniqid';

import { getElements } from '../dom-helpers';
import { cacheFile, removeCachedFile } from '../file-cache';
import { onReady } from '../page-lifecycle';

const pageIds = {
  trackUploadForm: 'track_upload_form',
  nameInput: 'track_upload_name',
  fileInput: 'track_upload_file',
  uuidInput: 'track_upload_client_uuid',
  submit: 'track_upload_submit',
  pseudoFileName: 'pseudo_file_name',
  fileInputRoot: 'file_input_root'
};

function guessTrackName(fileName) {
  const trackNumberRegex = /^\d\d?\.?\W+/;
  const artistDashRegex = /^.*\W+-\W+/;
  return fileName
    .substring(0, fileName.lastIndexOf('.'))
    .replace(trackNumberRegex, '')
    .replace(artistDashRegex, '');
}

function fixFileInput() {
  const fileInput = document.getElementById(pageIds.fileInput);
  const file = fileInput.files[0];
  if (file) {
    const trackName = guessTrackName(file.name);
    const [nameInput, pseudoFileName, fileInputRoot] = getElements([
      pageIds.nameInput,
      pageIds.pseudoFileName,
      pageIds.fileInputRoot
    ]);
    nameInput.value = trackName;
    pseudoFileName.classList.remove('is-hidden');
    pseudoFileName.innerText = file.name;
    fileInputRoot.classList.add('has-name');
  }
}

function handleFormSubmit(event) {
  const [submitButton, fileInput] = getElements([
    pageIds.submit,
    pageIds.fileInput
  ]);
  submitButton.disabled = true;
  submitButton.classList.add('is-loading');
  const file = fileInput.files[0];
  if (file) {
    const clientUuidInput = document.getElementById(pageIds.uuidInput);
    const previousValue = clientUuidInput.value;

    const uuid = uniqid();

    clientUuidInput.value = uuid;
    event.preventDefault();
    cacheFile(uuid, file)
      .then(() => {
        if (previousValue) {
          // Previously cached file no longer relevant
          return removeCachedFile(previousValue);
        }
      })
      .then(() => {
        event.target.submit();
      })
      .catch(() => {
        event.target.submit();
      });
  }
}

onReady(() => {
  fixFileInput(); // Need to apply correct UI if file input is already populated

  const [fileInput, form] = getElements([
    pageIds.fileInput,
    pageIds.trackUploadForm
  ]);
  fileInput.addEventListener('change', fixFileInput);
  form.addEventListener('submit', handleFormSubmit);
});
