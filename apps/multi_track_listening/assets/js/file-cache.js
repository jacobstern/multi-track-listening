import localforage from 'localforage';

const store = localforage.createInstance({
  name: 'file-cache',
  driver: localforage.INDEXEDDB
});

export function cacheFile(key, file) {
  const blob = file.slice(0, file.size, file.type);
  return store.setItem(key, blob);
}

export function getCachedFileBlob(key) {
  return store.getItem(key);
}

export function removeCachedFile(key) {
  return store.removeItem(key);
}
