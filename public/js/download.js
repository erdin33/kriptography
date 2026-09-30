import { el, empty, byId } from './dom.js';
import { state, setState } from './state.js';

export function sanitizeFilename(filename) {
  // Hanya nama dasar, tanpa / \ atau karakter kontrol
  const base = filename.split(/[\\/]/).pop();
  return base.replace(/[\x00-\x1F]/g, '');
}

export function createBlobUrl(uint8Array, mimeType) {
  const blob = new Blob([uint8Array], { type: mimeType || 'application/octet-stream' });
  return URL.createObjectURL(blob);
}

export function revokeBlobUrl(url) {
  if (url && url.startsWith('blob:')) {
    URL.revokeObjectURL(url);
  }
}

export function decodeBase64ToUint8Array(base64) {
  const binaryString = atob(base64);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}
