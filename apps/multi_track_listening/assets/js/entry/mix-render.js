import { Socket } from 'phoenix';
import * as PageLifecycle from '../page-lifecycle';
import { getElements } from '../dom-helpers';

const pageIds = {
  renderStatus: 'render_status',
  resultAudio: 'result_audio',
  renderProgress: 'render_progress',
  finishedControls: 'finished_controls'
};

function updateRender(render) {
  const [renderStatus, renderProgress, finishedControls] = getElements([
    pageIds.renderStatus,
    pageIds.renderProgress,
    pageIds.finishedControls
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
    finishedControls.classList.remove('is-hidden');
  }

  if (render.result_url) {
    const resultAudio = document.getElementById(pageIds.resultAudio);
    resultAudio.classList.remove('is-hidden');
    resultAudio.src = render.result_url;
  }
}

PageLifecycle.ready(() => {
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
});
