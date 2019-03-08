import { onReady } from '../page-lifecycle';

function handleCopyLinkClick(event) {
  event.preventDefault();
  const linkText = event.target.dataset.mixCardCopyLink;
  return navigator.clipboard.writeText(linkText);
}

onReady(() => {
  const downloadLinks = document.querySelectorAll('[data-mix-card-copy-link]');
  downloadLinks.forEach(anchor => {
    anchor.addEventListener('click', handleCopyLinkClick);
  });
});
