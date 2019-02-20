import localforage from 'localforage';

const store = localforage.createInstance({
  name: 'file-cache',
  driver: localforage.INDEXEDDB
});

export function putFile(key, file) {
  const blob = file.slice(0, file.size, file.type);
  return store.setItem(key, blob);
}

export function getFileBlob(key) {
  return store.getItem(key);
}
