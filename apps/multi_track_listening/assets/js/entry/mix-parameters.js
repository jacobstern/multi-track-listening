import { onReady } from '../page-lifecycle';
import * as MixPreview from '../mix-preview';
import { getCachedFileBlob } from '../file-cache';
import { getElements } from '../dom-helpers';

const pageIds = {
  mixParametersForm: 'mix_parameters_form',
  previewButton: 'preview_button',
  stopPreviewButton: 'stop_preview_button',
  trackOneStartInput: 'mix_parameters_track_one_start',
  trackTwoStartInput: 'mix_parameters_track_two_start',
  mixDurationInput: 'mix_parameters_mix_duration',
  previewError: 'preview_error'
};

function showPreviewError(message) {
  const previewError = document.getElementById(pageIds.previewError);
  previewError.classList.remove('is-hidden');
  previewError.innerText = message;
}

function loadAudioBufferFetch(url) {
  return fetch(url).then(response => response.arrayBuffer());
}

function getArrayBufferFromBlob(blob) {
  return new Promise((resolve, reject) => {
    const fileReader = new FileReader();
    fileReader.onload = event => {
      resolve(event.target.result);
    };
    fileReader.onerror = event => {
      reject(event.target.error);
    };
    fileReader.readAsArrayBuffer(blob);
  });
}

function loadAudioBuffer(url, clientUuid) {
  if (clientUuid) {
    return getCachedFileBlob(clientUuid).then(blob => {
      if (blob) {
        return getArrayBufferFromBlob(blob);
      }
      return loadAudioBufferFetch(url);
    });
  }
  return loadAudioBufferFetch(url);
}

onReady(() => {
  let stopPreviewCallback, previewBuffers;

  const handlePreviewStop = event => {
    event.preventDefault();

    const stopButton = document.getElementById(pageIds.stopPreviewButton);
    stopButton.disabled = true;

    if (stopPreviewCallback) {
      stopPreviewCallback();
    }
  };

  const handlePreviewPlay = event => {
    event.preventDefault();

    if (stopPreviewCallback) {
      stopPreviewCallback();
    }

    const stopButton = document.getElementById(pageIds.stopPreviewButton);
    stopButton.disabled = true;

    const previewButton = document.getElementById(pageIds.previewButton);
    const previewWithBuffers = buffers => {
      const [
        trackOneStartInput,
        trackTwoStartInput,
        mixDurationInput,
        stopPreviewButton
      ] = getElements([
        pageIds.trackOneStartInput,
        pageIds.trackTwoStartInput,
        pageIds.mixDurationInput,
        pageIds.stopPreviewButton
      ]);
      const previewParameters = {
        trackOneStart: trackOneStartInput.value,
        trackTwoStart: trackTwoStartInput.value,
        mixDuration: mixDurationInput.value
      };
      const stopPreview = MixPreview.startPreview(buffers, previewParameters);
      previewButton.classList.remove('is-loading');
      previewButton.disabled = false;

      stopPreviewButton.disabled = false;

      previewBuffers = buffers;
      stopPreviewCallback = stopPreview;
    };

    if (previewBuffers) {
      previewWithBuffers(previewBuffers);
    } else {
      previewButton.disabled = true;
      previewButton.classList.add('is-loading');
      return Promise.all([
        loadAudioBuffer(
          previewButton.dataset.trackOneUrl,
          previewButton.dataset.trackOneClientUuid
        ),
        loadAudioBuffer(
          previewButton.dataset.trackTwoUrl,
          previewButton.dataset.trackTwoClientUuid
        )
      ]).then(buffers =>
        MixPreview.preparePreviewBuffers(...buffers).then(previewWithBuffers)
      );
    }
  };

  const [previewButton, stopPreviewButton, mixParametersForm] = getElements([
    pageIds.previewButton,
    pageIds.stopPreviewButton,
    pageIds.mixParametersForm
  ]);

  if (MixPreview.isSupported) {
    previewButton.addEventListener('click', handlePreviewPlay);
  } else {
    showPreviewError('Preview is not supported in this browser.');
    previewButton.disabled = true;
    previewButton.classList.remove('is-primary');
  }

  stopPreviewButton.addEventListener('click', handlePreviewStop);
  mixParametersForm.addEventListener('change', handlePreviewStop);
});
