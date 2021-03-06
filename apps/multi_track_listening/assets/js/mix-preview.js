const FADEOUT_DURATION = 0.8;

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

function startSource(source, start, currentTime, mixDuration) {
  if (!source.buffer) {
    throw new Error('Attempt to start source with no buffer');
  }

  const duration = source.buffer.duration;
  if (start >= duration) {
    return;
  }

  source.loop = false;
  source.loopEnd = duration;
  source.loopStart = start;
  source.start(currentTime, start);
  source.stop(currentTime + mixDuration);
}

export function startPreview(previewBuffers, previewParameters) {
  const [trackOneAudioBuffer, trackTwoAudioBuffer] = previewBuffers;

  prefixAudioContext();
  const context = new AudioContext();
  const currentTime = context.currentTime;

  const trackOneSource = context.createBufferSource();
  const trackTwoSource = context.createBufferSource();

  trackOneSource.buffer = trackOneAudioBuffer;
  trackTwoSource.buffer = trackTwoAudioBuffer;

  const {
    trackOneStart,
    trackTwoStart,
    mixDuration,
    trackOneGain,
    trackTwoGain
  } = previewParameters;
  startSource(trackOneSource, trackOneStart, currentTime, mixDuration);
  startSource(trackTwoSource, trackTwoStart, currentTime, mixDuration);

  const trackOneDownMix = context.createGain();
  trackOneDownMix.channelCount = 1;
  trackOneDownMix.channelCountMode = 'explicit';
  trackOneDownMix.gain.value = trackOneGain;
  trackOneSource.connect(trackOneDownMix);

  const trackTwoDownMix = context.createGain();
  trackTwoDownMix.channelCount = 1;
  trackTwoDownMix.channelCountMode = 'explicit';
  trackTwoDownMix.gain.value = trackTwoGain;
  trackTwoSource.connect(trackTwoDownMix);

  const [trackOnePanner, trackTwoPanner] = [
    trackOneDownMix,
    trackTwoDownMix
  ].map(downMix => {
    const panner = context.createPanner();
    panner.panningModel = 'HRTF';
    panner.refDistance = 1;
    panner.distanceModel = 'linear';
    panner.coneInnerAngle = 360;
    panner.rolloffFactor = 1;
    panner.setOrientation(1, 0, 0);

    downMix.connect(panner);

    return panner;
  });

  trackOnePanner.setPosition(-1, 0, 0);
  trackTwoPanner.setPosition(1, 0, 0);

  const masterGain = context.createGain();
  const endTimestamp = currentTime + mixDuration;
  masterGain.gain.setValueAtTime(1.0, endTimestamp - FADEOUT_DURATION);
  masterGain.gain.exponentialRampToValueAtTime(0.01, endTimestamp);
  masterGain.gain.setValueAtTime(0, endTimestamp);
  trackOnePanner.connect(masterGain);
  trackTwoPanner.connect(masterGain);

  masterGain.connect(context.destination);

  context.listener.setOrientation(0, 0, -1, 0, 1, 0);

  const preview = {
    startTime: Date.now(),
    trackOneSource,
    trackTwoSource,
    trackOnePanner,
    trackTwoPanner,
    context,
    parameters: previewParameters
  };

  preview.requestAnimationFrameToken = requestAnimationFrame(
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
  const {
    trackOnePanner,
    trackTwoPanner,
    startTime,
    parameters: { driftingSpeed }
  } = preview;
  const elapsedSeconds = (Date.now() - startTime) / 1000;
  const angle =
    ((elapsedSeconds * Math.PI * 2.0 * driftingSpeed) / 60.0) % (Math.PI * 2.0);
  const opposite = angle + Math.PI;

  trackOnePanner.setPosition(Math.cos(opposite), 0, Math.sin(opposite));
  trackTwoPanner.setPosition(Math.cos(angle), 0, Math.sin(angle));

  preview.requestAnimationFrameToken = requestAnimationFrame(
    previewAnimationFrame.bind(null, preview)
  );
}
