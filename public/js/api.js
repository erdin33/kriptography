export let activeController = null;

async function doFetch(url, options = {}) {
  if (activeController) {
    activeController.abort();
  }
  
  activeController = new AbortController();
  options.signal = activeController.signal;
  
  try {
    const res = await fetch(url, options);
    const contentType = res.headers.get('content-type') || '';
    
    if (!res.ok) {
      if (res.status === 413) {
        throw new Error('Berkas terlalu besar (Payload Too Large).');
      }
      
      let errorData;
      if (contentType.includes('application/json')) {
        errorData = await res.json();
      } else {
        const text = await res.text();
        throw new Error(`Server error (${res.status}): ${text.slice(0, 100)}`);
      }
      
      throw { apiError: true, ...errorData };
    }
    
    if (contentType.includes('application/json')) {
      return await res.json();
    } else {
      throw new Error('Respons server bukan JSON.');
    }
  } catch (err) {
    if (err.name === 'AbortError') {
      throw { isAbort: true };
    }
    throw err;
  } finally {
    activeController = null;
  }
}

export function cancelRequest() {
  if (activeController) {
    activeController.abort();
  }
}

export async function fetchCiphers() {
  return doFetch('/api/ciphers');
}

export async function apiEncrypt(cipherId, params, inputType, textOrFile) {
  const fd = new FormData();
  fd.append('cipher', cipherId);
  fd.append('params', JSON.stringify(params));
  fd.append('input_type', inputType);
  
  if (inputType === 'text') {
    fd.append('text', textOrFile);
  } else {
    fd.append('file', textOrFile);
  }
  
  return doFetch('/api/encrypt', {
    method: 'POST',
    body: fd
  });
}

export async function apiDecrypt(cipherId, params, sourceType, formatOrFile, textData) {
  const fd = new FormData();
  fd.append('cipher', cipherId);
  fd.append('params', JSON.stringify(params));
  fd.append('source', sourceType);
  
  if (sourceType === 'container') {
    fd.append('file', formatOrFile); // formatOrFile = file
  } else {
    fd.append('text_format', formatOrFile); // formatOrFile = format
    fd.append('text', textData);
  }
  
  return doFetch('/api/decrypt', {
    method: 'POST',
    body: fd
  });
}

export async function apiInspect(file) {
  const fd = new FormData();
  fd.append('file', file);
  
  return doFetch('/api/inspect', {
    method: 'POST',
    body: fd
  });
}
