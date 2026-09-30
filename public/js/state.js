// simple state management

const listeners = [];

export const state = {
  ciphers: [], // array objek cipher dari API
  limits: { max_upload_bytes: 25 * 1024 * 1024, display_limit_bytes: 65536 },
  
  mode: 'encrypt', // 'encrypt' | 'decrypt'
  activeCipherId: null, // string
  inputType: 'text', // 'text' | 'file'
  
  // Penyimpanan sementara params per cipher agar tidak hilang saat berganti cipher
  // format: { [cipher_id]: { [field_name]: value } }
  savedParams: {}, 
  
  isProcessing: false,
  
  // Data input
  textInput: '',
  fileInput: null, // objek File
  pasteFormat: 'letters', // 'letters', 'base64', 'hex' (untuk mode dekripsi tempelan teks)
  
  // Data hasil
  result: null, // objek respons sukses
  resultContainer: null, // Uint8Array atau Blob URL (jika ada)
  
  // Error state
  error: null // { type: 'api' | 'validation', field?: 'key', message: '...' }
};

export function setState(updates) {
  Object.assign(state, updates);
  notify();
}

export function subscribe(fn) {
  listeners.push(fn);
}

function notify() {
  for (const fn of listeners) {
    fn(state);
  }
}

export function getActiveCipher() {
  if (!state.activeCipherId) return null;
  return state.ciphers.find(c => c.id === state.activeCipherId);
}
