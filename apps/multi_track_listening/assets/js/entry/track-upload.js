import { ready } from '../page-lifecycle';

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
    const nameInput = document.getElementById('track_upload_name');
    nameInput.value = trackName;
  }
}

ready(() => {
  const fileInput = document.getElementById('track_upload_file');
  fileInput.addEventListener('change', handleFileInputChange);
});
