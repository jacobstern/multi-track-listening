function prefixAudioContext() {
  window.AudioContext = window.AudioContext || window.webkitAudioContext;
}

/*
 * Hand-written Promise version of AudioContext.decodeAudioData()
 */
function decodeAudioData(context, arrayBuffer) {
  return new Promise((resolve, reject) =>
    context.decodeAudioData(arrayBuffer, resolve, reject)
  );
}

export function isSupported() {
  prefixAudioContext();
  return window.AudioContext != null;
}

export function preparePreviewBuffers(trackOneBuffer, trackTwoBuffer) {
  prefixAudioContext();
  const context = new AudioContext();
  return Promise.all([
    decodeAudioData(context, trackOneBuffer),
    decodeAudioData(context, trackTwoBuffer)
  ]).then(previewBuffers => {
    context.close();
    return previewBuffers;
  });
}

export function startPreview(previewBuffers, previewParameters) {
  const [trackOneAudioBuffer, trackTwoAudioBuffer] = previewBuffers;

  prefixAudioContext();
  const context = new AudioContext();

  const trackOneSource = context.createBufferSource();
  const trackTwoSource = context.createBufferSource();

  trackOneSource.buffer = trackOneAudioBuffer;
  trackTwoSource.buffer = trackTwoAudioBuffer;

  const [trackOnePanner, trackTwoPanner] = [trackOneSource, trackTwoSource].map(
    source => {
      const downMix = context.createGain();
      downMix.channelCount = 1;
      downMix.channelCountMode = 'explicit';

      source.connect(downMix);

      const panner = context.createPanner();
      panner.panningModel = 'HRTF';
      panner.refDistance = 1;
      panner.distanceModel = 'linear';
      panner.coneInnerAngle = 360;
      panner.rolloffFactor = 1;
      panner.setOrientation(1, 0, 0);

      downMix.connect(panner);

      return panner;
    }
  );

  trackOnePanner.setPosition(-1, 0, 0);
  trackTwoPanner.setPosition(1, 0, 0);

  trackOneSource.start();
  trackTwoSource.start();

  trackOnePanner.connect(context.destination);
  trackTwoPanner.connect(context.destination);

  context.listener.setOrientation(0, 0, -1, 0, 1, 0);

  const preview = {
    startTime: Date.now(),
    trackOneSource,
    trackTwoSource,
    trackOnePanner,
    trackTwoPanner,
    requestAnimationFrameToken,
    context,
    parameters: previewParameters
  };

  const requestAnimationFrameToken = requestAnimationFrame(
    previewAnimationFrame.bind(null, preview)
  );

  return stopPreview.bind(null, preview);
}

function stopPreview(preview) {
  const {
    trackOneSource,
    trackTwoSource,
    requestAnimationFrameToken,
    context
  } = preview;

  trackOneSource.stop();
  trackTwoSource.stop();

  trackOneSource.disconnect();
  trackTwoSource.disconnect();

  cancelAnimationFrame(requestAnimationFrameToken);

  context.close();
}

function previewAnimationFrame(preview) {
  const { trackOnePanner, trackTwoPanner, startTime } = preview;
  const elapsedSeconds = (Date.now() - startTime) / 1000;
  const angle = ((elapsedSeconds * Math.PI * 2.0) / 10.0) % (Math.PI * 2.0);
  const opposite = angle + Math.PI;

  trackOnePanner.setPosition(Math.cos(opposite), 0, Math.sin(opposite));
  trackTwoPanner.setPosition(Math.cos(angle), 0, Math.sin(angle));

  preview.requestAnimationFrameToken = requestAnimationFrame(
    previewAnimationFrame.bind(null, preview)
  );
}
