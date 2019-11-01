import { Socket } from 'phoenix';
import { getElements } from '../dom-helpers';
import { removeCachedFile } from '../file-cache';
import { onReady } from '../page-lifecycle';

const pageIds = {
  renderStatus: 'render_status',
  resultAudio: 'result_audio',
  renderProgress: 'render_progress',
  finishedFooter: 'finished_footer',
  downloadButton: 'download_button',
  publishButton: 'publish_button',
  publishForm: 'publish_form'
};

function handleFormSubmit(event) {
  const publishButton = document.getElementById(pageIds.publishButton);
  publishButton.disabled = true;
  publishButton.classList.add('is-loading');

  if (
    publishButton.dataset.trackOneClientUuid &&
    publishButton.dataset.trackTwoClientUuid
  ) {
    event.preventDefault();
    Promise.all([
      removeCachedFile(publishButton.dataset.trackOneClientUuid),
      removeCachedFile(publishButton.dataset.trackTwoClientUuid)
    ])
      .then(() => {
        event.target.submit();
      })
      .catch(() => {
        event.target.submit();
      });
  }
}

function updateRender(render) {
  const [
    renderStatus,
    renderProgress,
    finishedFooter,
    downloadButton
  ] = getElements([
    pageIds.renderStatus,
    pageIds.renderProgress,
    pageIds.finishedFooter,
    pageIds.downloadButton
  ]);

  if (render.status_text) {
    renderStatus.innerText = render.status_text;
  } else {
    renderStatus.innerText = '';
  }

  if (render.status === 'error') {
    renderStatus.classList.add('has-text-danger');
    renderProgress.innerText = '15%';
    renderProgress.value = 15;
    renderProgress.classList.add('is-danger');
  } else if (render.status === 'finished') {
    renderProgress.innerText = '100%';
    renderProgress.value = 100;
    renderProgress.classList.add('is-success');
    finishedFooter.classList.remove('is-hidden');
  }

  if (render.result_url) {
    const resultAudio = document.getElementById(pageIds.resultAudio);
    resultAudio.classList.remove('is-hidden');
    resultAudio.src = render.result_url;
    downloadButton.href = render.result_url;
  }
}

onReady(() => {
  const pathSegments = window.location.pathname.split('/');
  const renderId = pathSegments[pathSegments.length - 1];

  const socket = new Socket('/socket');
  socket.connect();

  const channel = socket.channel(`mix_renders:${renderId}`);
  channel
    .join()
    .receive('ok', render => {
      updateRender(render);
    })
    .receive('error', e => {
      throw e;
    });
  channel.on('update', updateRender);

  document
    .getElementById(pageIds.publishForm)
    .addEventListener('submit', handleFormSubmit);
});
