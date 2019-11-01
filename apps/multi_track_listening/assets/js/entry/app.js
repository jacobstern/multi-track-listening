import 'phoenix_html';
import { onReady } from '../page-lifecycle';

import '../../scss/app.scss';

onReady(() => {
  let alerts = document.querySelectorAll('[data-is-notification]');
  if (alerts) {
    alerts.forEach(notification => {
      let deleteButton = notification.querySelector('[data-is-delete]');
      if (deleteButton) {
        deleteButton.addEventListener('click', () => {
          notification.parentNode.removeChild(notification);
        });
      }
    });
  }
});
