import * as PageLifecycle from '../page-lifecycle';
import * as MixPreview from '../mix-preview';
import * as FileCache from '../file-cache';

const pageIds = {
  previewButton: 'preview_button',
  previewStatus: 'preview_status'
};

function loadAudioBufferFetch(url) {
  return fetch(url).then(response => response.arrayBuffer());
}

function loadAudioBuffer(url, clientUuid) {
  if (clientUuid) {
    return FileCache.getFileBlob(clientUuid)
      .then(blob => new Response(blob).arrayBuffer())
      .catch(() => loadAudioBufferFetch(url));
  }
  return loadAudioBufferFetch(url);
}

function makeHandlePreviewStop(previewBuffers, stopPreview) {
  const handler = {
    handleEvent: event => {
      const previewButton = event.target;
      previewButton.removeEventListener('click', handler);
      previewButton.addEventListener(
        'click',
        makeHandlePreviewPlay(previewBuffers)
      );
      stopPreview();
      previewButton.value = 'Preview';
    }
  };
  return handler;
}

function makeHandlePreviewPlay(previewBuffers) {
  const handler = {
    handleEvent: event => {
      const previewButton = event.target;

      const continuation = buffers => {
        const stopPreview = MixPreview.startPreview(buffers);
        previewButton.disabled = false;
        previewButton.value = 'Stop Preview';
        previewButton.removeEventListener('click', handler);
        previewButton.addEventListener(
          'click',
          makeHandlePreviewStop(buffers, stopPreview)
        );
      };

      if (previewBuffers) {
        continuation(previewBuffers);
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
          MixPreview.preparePreviewBuffers(...buffers).then(continuation)
        );
      }
    }
  };
  return handler;
}

PageLifecycle.ready(() => {
  const previewButton = document.getElementById(pageIds.previewButton);
  if (MixPreview.isSupported) {
    previewButton.addEventListener('click', makeHandlePreviewPlay());
  } else {
    const previewStatus = document.getElementById(pageIds.previewStatus);
    previewStatus.innerText = 'This browser does not support mix preview.';
    previewButton.disabled = true;
  }
});
