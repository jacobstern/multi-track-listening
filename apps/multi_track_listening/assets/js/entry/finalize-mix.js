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
  if (Boolean(clientUuid)) {
    return FileCache.getFileBlob(clientUuid)
      .then(blob => new Response(blob).arrayBuffer())
      .catch(() => loadAudioBufferFetch(url));
  }
  return loadAudioBufferFetch(url);
}

function makeHandlePreviewStop(previewHandle) {
  const handler = {
    handleEvent: event => {
      const previewButton = event.target;
      previewButton.removeEventListener('click', handler);
      previewButton.addEventListener('click', handlePreviewPlay);
      MixPreview.stopPreview(previewHandle);
      previewButton.value = 'Preview';
    }
  };
  return handler;
}

function handlePreviewPlay(event) {
  event.preventDefault();
  const previewButton = event.target;
  Promise.all([
    loadAudioBuffer(
      previewButton.dataset.trackOneUrl,
      previewButton.dataset.trackOneClientUuid
    ),
    loadAudioBuffer(
      previewButton.dataset.trackTwoUrl,
      previewButton.dataset.trackTwoClientUuid
    )
  ]).then(([trackOneBuffer, trackTwoBuffer]) => {
    previewButton.value = 'Stop Preview';
    const previewHandle = MixPreview.previewMix(trackOneBuffer, trackTwoBuffer);
    previewButton.removeEventListener('click', handlePreviewPlay);
    previewButton.addEventListener(
      'click',
      makeHandlePreviewStop(previewHandle)
    );
  });
}

PageLifecycle.ready(() => {
  const previewButton = document.getElementById(pageIds.previewButton);
  if (MixPreview.isSupported) {
    previewButton.addEventListener('click', handlePreviewPlay);
  } else {
    const previewStatus = document.getElementById(pageIds.previewStatus);
    previewStatus.innerText = 'This browser does not support mix preview.';
    previewButton.disabled = true;
  }
});
