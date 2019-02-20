import * as PageLifecycle from '../page-lifecycle';
import { getFileBlob } from '../file-cache';

const pageIds = {
  previewAudio: 'preview_audio'
};

PageLifecycle.ready(() => {
  const audio = document.getElementById(pageIds.previewAudio);
  getFileBlob(audio.dataset.clientUuid).then(blob => {
    audio.src = URL.createObjectURL(blob);
  });
});
