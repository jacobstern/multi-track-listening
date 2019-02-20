const AudioContext = window.AudioContext || window.webkitAudioContext;

export function isSupported() {
  return AudioContext != null;
}

export function previewMix(trackOneBuffer, trackTwoBuffer) {
  return null;
}

export function stopPreview(handle) {}
