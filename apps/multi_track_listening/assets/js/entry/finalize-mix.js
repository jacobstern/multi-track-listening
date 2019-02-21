import * as PageLifecycle from '../page-lifecycle';
import * as MixPreview from '../mix-preview';
import * as FileCache from '../file-cache';

const pageIds = {
  previewButton: 'preview_button',
  previewStatus: 'preview_status',
  trackOneStartInput: 'mix_parameters_track_one_start',
  trackTwoStartInput: 'mix_parameters_track_two_start',
  mixDurationInput: 'mix_parameters_mix_duration'
};

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
    return FileCache.getFileBlob(clientUuid).then(blob => {
      if (blob) {
        return getArrayBufferFromBlob(blob);
      }
      return loadAudioBufferFetch(url);
    });
  }
  return loadAudioBufferFetch(url);
}

function makePreviewStopHandler(previewBuffers, stopPreview) {
  const handler = {
    handleEvent: event => {
      const previewButton = event.target;
      previewButton.removeEventListener('click', handler);
      previewButton.addEventListener(
        'click',
        makePreviewPlayHandler(previewBuffers)
      );
      stopPreview();
      previewButton.value = 'Preview';
    }
  };
  return handler;
}

function makePreviewPlayHandler(previewBuffers) {
  const handler = {
    handleEvent: event => {
      const previewButton = event.target;

      const previewWithBuffers = buffers => {
        const [trackOneStartInput, trackTwoStartInput, mixDurationInput] = [
          pageIds.trackOneStartInput,
          pageIds.trackTwoStartInput,
          pageIds.mixDurationInput
        ].map(Document.prototype.getElementById.bind(document));
        const previewParameters = {
          trackOneStart: trackOneStartInput.value,
          trackTwoStart: trackTwoStartInput.value,
          mixDuration: mixDurationInput.value
        };
        const stopPreview = MixPreview.startPreview(buffers, previewParameters);
        previewButton.disabled = false;
        previewButton.value = 'Stop Preview';
        previewButton.removeEventListener('click', handler);
        previewButton.addEventListener(
          'click',
          makePreviewStopHandler(buffers, stopPreview)
        );
      };

      if (previewBuffers) {
        previewWithBuffers(previewBuffers);
      } else {
        previewButton.disabled = true;
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
    const previewStatus = document.getElementById(pageIds.previewStatus);
    previewStatus.innerText = 'This browser does not support mix preview.';
    previewButton.disabled = true;
  }
});
