import uniqid from 'uniqid';

import * as PageLifecycle from '../page-lifecycle';
import * as FileCache from '../file-cache';

const pageIds = {
  nameInput: 'track_upload_name',
  fileInput: 'track_upload_file',
  uuidInput: 'track_upload_client_uuid',
  submit: 'track_upload_submit'
};

function guessTrackName(fileName) {
  const trackNumberRegex = /^\d\d?\.?\W+/;
  return fileName
    .substring(0, fileName.lastIndexOf('.'))
    .replace(trackNumberRegex, '');
}

function handleFileInputChange(event) {
  const file = event.target.files[0];
  if (file) {
    const trackName = guessTrackName(file.name);
    const nameInput = document.getElementById(pageIds.nameInput);
    nameInput.value = trackName;
  }
}

function handleFormSubmit(event) {
  const submitButton = document.getElementById(pageIds.submit);
  submitButton.disabled = true;

  const fileInput = document.getElementById(pageIds.fileInput);
  const file = fileInput.files[0];
  if (file) {
    const clientUuidInput = document.getElementById(pageIds.uuidInput);
    const previousValue = clientUuidInput.value;

    const uuid = uniqid();

    clientUuidInput.value = uuid;
    event.preventDefault();
    FileCache.putFile(uuid, file)
      .then(() => {
        if (previousValue) {
          // Previously cached file no longer relevant
          return FileCache.removeFile(previousValue);
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

PageLifecycle.ready(() => {
  const fileInput = document.getElementById(pageIds.fileInput);
  fileInput.addEventListener('change', handleFileInputChange);

  const form = document.getElementById('track_upload_form');
  form.addEventListener('submit', handleFormSubmit);
});
