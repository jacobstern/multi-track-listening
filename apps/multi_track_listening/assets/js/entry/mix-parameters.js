import * as PageLifecycle from '../page-lifecycle';
import * as MixPreview from '../mix-preview';
import { getCachedFileBlob } from '../file-cache';

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

function makePreviewStopHandler(stopPreview) {
  const handler = {
    handleEvent: event => {
      event.preventDefault();

      const stopButton = document.getElementById(pageIds.stopPreviewButton);
      stopButton.removeEventListener('click', handler);
      stopButton.disabled = true;

      stopPreview();
    }
  };
  return handler;
}

function makePreviewPlayHandler(
  previewBuffers,
  stopPreviewCallback,
  stopPreviewHandler
) {
  const handler = {
    handleEvent: event => {
      event.preventDefault();

      if (stopPreviewCallback) {
        stopPreviewCallback();
      }

      if (stopPreviewHandler) {
        const stopButton = document.getElementById(pageIds.stopPreviewButton);
        stopButton.removeEventListener('click', stopPreviewHandler);
        stopButton.disabled = true;
      }

      const previewButton = document.getElementById(pageIds.previewButton);
      const previewWithBuffers = buffers => {
        const [
          trackOneStartInput,
          trackTwoStartInput,
          mixDurationInput,
          stopPreviewButton
        ] = [
          pageIds.trackOneStartInput,
          pageIds.trackTwoStartInput,
          pageIds.mixDurationInput,
          pageIds.stopPreviewButton
        ].map(Document.prototype.getElementById.bind(document));
        const previewParameters = {
          trackOneStart: trackOneStartInput.value,
          trackTwoStart: trackTwoStartInput.value,
          mixDuration: mixDurationInput.value
        };
        const stopPreview = MixPreview.startPreview(buffers, previewParameters);
        previewButton.classList.remove('is-loading');
        previewButton.disabled = false;

        const newStopHandler = makePreviewStopHandler(stopPreview);
        stopPreviewButton.addEventListener('click', newStopHandler);
        stopPreviewButton.disabled = false;

        const newPlayHandler = makePreviewPlayHandler(
          buffers,
          stopPreview,
          newStopHandler
        );
        previewButton.removeEventListener('click', handler);
        previewButton.addEventListener('click', newPlayHandler);
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
    }
  };
  return handler;
}

PageLifecycle.ready(() => {
  const previewButton = document.getElementById(pageIds.previewButton);
  if (MixPreview.isSupported) {
    previewButton.addEventListener('click', makePreviewPlayHandler());
  } else {
    showPreviewError('Preview is not supported in this browser.');
    previewButton.disabled = true;
    previewButton.classList.remove('is-primary');
  }
});
