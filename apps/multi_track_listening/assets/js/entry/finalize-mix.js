import * as PageLifecycle from '../page-lifecycle';
import * as MixPreview from '../mix-preview';
import * as FileCache from '../file-cache';

const pageIds = {
  finalizeMixForm: 'finalize_mix_form',
  previewButton: 'preview_button',
  previewStatus: 'preview_status',
  trackOneStartInput: 'mix_parameters_track_one_start',
  trackTwoStartInput: 'mix_parameters_track_two_start',
  mixDurationInput: 'mix_parameters_mix_duration'
};

function loadAudioBufferFetch(url) {
  return fetch(url).then(response => response.arrayBuffer());
}

function suppressEnterKeyHandler(event) {
  if (event.keyCode == 13 || event.keyCode == 32) {
    event.preventDefault();
  }
}

function getAllFormInputs() {
  return document.querySelectorAll(`#${pageIds.finalizeMixForm} input`);
}

function suppressEnterKeySubmit() {
  getAllFormInputs().forEach(input => {
    input.addEventListener('keypress', suppressEnterKeyHandler);
  });
}

function enableEnterKeySubmit() {
  getAllFormInputs().forEach(input => {
    input.removeEventListener('keypress', suppressEnterKeyHandler);
  });
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
      if (event.type === 'click') {
        event.preventDefault();
      }

      const previewButton = document.getElementById(pageIds.previewButton);
      const finalizeMixForm = document.getElementById(pageIds.finalizeMixForm);

      // In makePreviewPlayHandler(), this event is applied to both listeners at once
      previewButton.removeEventListener('click', handler);
      finalizeMixForm.removeEventListener('input', handler);

      previewButton.addEventListener(
        'click',
        makePreviewPlayHandler(previewBuffers)
      );
      stopPreview();
      previewButton.innerText = 'Preview';

      enableEnterKeySubmit();
    }
  };
  return handler;
}

function makePreviewPlayHandler(previewBuffers) {
  const handler = {
    handleEvent: event => {
      event.preventDefault();

      const previewButton = document.getElementById(pageIds.previewButton);
      const previewWithBuffers = buffers => {
        const [
          finalizeMixForm,
          trackOneStartInput,
          trackTwoStartInput,
          mixDurationInput
        ] = [
          pageIds.finalizeMixForm,
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
        previewButton.innerText = 'Stop';
        previewButton.removeEventListener('click', handler);

        const stopPreviewHandler = makePreviewStopHandler(buffers, stopPreview);
        previewButton.addEventListener('click', stopPreviewHandler);
        finalizeMixForm.addEventListener('input', stopPreviewHandler);

        // This is somewhat evil, but it does prevent the awkward behavior of
        // Enter stopping the preview. The behavior will be enabled again when
        // the form is edited or preview is stopped by clicking the button.
        suppressEnterKeySubmit();
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
