import { Socket } from 'phoenix';
import * as PageLifecycle from '../page-lifecycle';

PageLifecycle.ready(() => {
  const pathSegments = window.location.pathname.split('/');
  const renderId = pathSegments[pathSegments.length - 1];

  const socket = new Socket('/socket');
  socket.connect();

  const channel = socket.channel(`mix_renders:${renderId}`);
  channel
    .join()
    .receive('ok', () => {
      channel.push('latest', {}).receive('ok', () => {
        // TODO: Implement
      });
    })
    .receive('error', e => {
      throw e;
    });
});
