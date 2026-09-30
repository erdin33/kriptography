import { el } from './dom.js';

export function createPreviewElement(mimeType, blobUrl) {
  if (mimeType.startsWith('image/')) {
    return el('img', { src: blobUrl, style: { maxWidth: '100%', maxHeight: '300px', display: 'block', marginTop: '8px' } });
  }
  if (mimeType.startsWith('audio/')) {
    return el('audio', { src: blobUrl, controls: true, style: { marginTop: '8px' } });
  }
  if (mimeType.startsWith('video/')) {
    return el('video', { src: blobUrl, controls: true, style: { maxWidth: '100%', maxHeight: '300px', display: 'block', marginTop: '8px' } });
  }
  return null;
}
