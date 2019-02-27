export function getElements(ids) {
  return ids.map(Document.prototype.getElementById.bind(document));
}
