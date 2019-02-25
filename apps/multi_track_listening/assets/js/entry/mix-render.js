import { Socket } from 'phoenix';
import * as PageLifecycle from '../page-lifecycle';

const pageIds = {
  renderStatus: 'render_status',
  resultAudio: 'result_audio'
};

function updateRender(render) {
  const renderStatus = document.getElementById(pageIds.renderStatus);
  renderStatus.innerText = render.status_text;

  if (render.result_url) {
    const resultAudio = document.getElementById(pageIds.resultAudio);
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
