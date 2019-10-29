import localforage from 'localforage';

export class FileCacheError extends Error {
  constructor(message) {
    super(message);
  }
}

const META_KEY = '___meta';
const FILE_TTL = 604800000; // 1 week

const store = localforage.createInstance({
  name: 'file-cache',
  driver: localforage.INDEXEDDB
});

// Serialize operations on metadata object
let metaPromise = Promise.resolve();

function setFileMetadata(key, val) {
  metaPromise = metaPromise
    .then(() => store.getItem(META_KEY))
    .then(metaObj => {
      metaObj = metaObj || {};
      metaObj[key] = val;
      return store.setItem(META_KEY, metaObj).then(Promise.resolve());
    });
  return metaPromise;
}

function deleteFileMetadata(key) {
  metaPromise = metaPromise
    .then(() => store.getItem(META_KEY))
    .then(metaObj => {
      if (metaObj) {
        delete metaObj[key];
        delete metaObj['test-key'];
        return store.setItem(META_KEY, metaObj).then(Promise.resolve());
      }
    });
  return metaPromise;
}

// Currently inlined in expireOldFiles()
// eslint-disable-next-line no-unused-vars
function getFileMetadata(key) {
  metaPromise = metaPromise
    .then(() => store.getItem(META_KEY))
    .then(metaObj => {
      if (metaObj && metaObj.hasOwnProperty(key)) {
        return metaObj[key];
      }
      return undefined;
    });
  return metaPromise;
}

export function cacheFile(key, file) {
  if (key === META_KEY) {
    return Promise.reject(
      new FileCacheError('Refusing to use reserved key ' + META_KEY)
    );
  }
  const blob = file.slice(0, file.size, file.type);
  return Promise.all([
    store.setItem(key, blob),
    setFileMetadata(key, { createdAt: Date.now() })
  ]);
}

export function getCachedFileBlob(key) {
  return store.getItem(key);
}

export function removeCachedFile(key) {
  return Promise.all([store.removeItem(key), deleteFileMetadata(key)]);
}

export function expireOldFiles() {
  const now = Date.now();
  metaPromise = store.getItem(META_KEY);
  return metaPromise.then(metaObj => {
    metaObj = metaObj || {};
    let toRemove = [];
    return store
      .iterate((value, key) => {
        if (metaObj.hasOwnProperty(key)) {
          let { createdAt } = metaObj[key];
          if (typeof createdAt === 'number' && now - createdAt > FILE_TTL) {
            toRemove.push(key);
          }
        } else {
          toRemove.push(key); // Delete old files from before this JS change was made
        }
      })
      .then(() => Promise.all(toRemove.map(removeCachedFile)))
      .then(Promise.resolve());
  });
}
