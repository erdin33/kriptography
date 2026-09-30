import { byId, empty, el } from './dom.js';
import { state } from './state.js';
import { decodeBase64ToUint8Array, createBlobUrl, revokeBlobUrl, sanitizeFilename } from './download.js';
import { createPreviewElement } from './preview.js';

let activeDownloadUrl = null;
let currentPlaintextBlobUrl = null;

export function initResultPanel() {
  const btnCopy = byId('btn-copy-result');
  const btnDownload = byId('btn-download');
  
  const tabLetters = byId('tab-letters');
  const tabBase64 = byId('tab-base64');
  const tabHex = byId('tab-hex');
  const panelLetters = byId('panel-letters');
  const panelBase64 = byId('panel-base64');
  const panelHex = byId('panel-hex');
  
  const dataLetters = byId('result-data-letters');
  const dataBase64 = byId('result-data-base64');
  const dataHex = byId('result-data-hex');
  
  const meta = byId('result-meta');
  const errorBanner = byId('error-banner');
  const errorMessage = byId('error-message');
  const integrityBanner = byId('integrity-banner');
  
  const plaintextPanel = byId('plaintext-panel');
  const plaintextB64Content = byId('plaintext-b64-content');
  const plaintextToggle = byId('plaintext-toggle');
  
  // Tabs logic
  function activateTab(tabId) {
    tabLetters.setAttribute('aria-selected', tabId === 'letters');
    tabBase64.setAttribute('aria-selected', tabId === 'base64');
    tabHex.setAttribute('aria-selected', tabId === 'hex');
    
    panelLetters.classList.toggle('active', tabId === 'letters');
    panelBase64.classList.toggle('active', tabId === 'base64');
    panelHex.classList.toggle('active', tabId === 'hex');
    
    panelLetters.style.display = tabId === 'letters' ? 'block' : 'none';
    panelBase64.style.display = tabId === 'base64' ? 'block' : 'none';
    panelHex.style.display = tabId === 'hex' ? 'block' : 'none';
  }
  
  tabLetters.addEventListener('click', () => activateTab('letters'));
  tabBase64.addEventListener('click', () => activateTab('base64'));
  tabHex.addEventListener('click', () => activateTab('hex'));
  
  // Copy logic
  btnCopy.addEventListener('click', async () => {
    let content = '';
    if (panelLetters.classList.contains('active')) content = dataLetters.textContent;
    else if (panelBase64.classList.contains('active')) content = dataBase64.textContent;
    else if (panelHex.classList.contains('active')) content = dataHex.textContent;
    
    if (!content) return;
    
    try {
      await navigator.clipboard.writeText(content);
      const originalTitle = btnCopy.title;
      btnCopy.title = "Tersalin!";
      setTimeout(() => btnCopy.title = originalTitle, 2000);
    } catch (e) {
      // fallback
      const tx = el('textarea', { value: content });
      document.body.appendChild(tx);
      tx.select();
      document.execCommand('copy');
      document.body.removeChild(tx);
    }
  });
  
  // Plaintext toggle
  plaintextToggle.addEventListener('click', () => {
    const isExpanded = plaintextToggle.getAttribute('aria-expanded') === 'true';
    plaintextToggle.setAttribute('aria-expanded', String(!isExpanded));
  });
  
  return {
    clear: () => {
      empty(dataLetters);
      empty(dataBase64);
      empty(dataHex);
      empty(meta);
      errorBanner.style.display = 'none';
      integrityBanner.style.display = 'none';
      btnDownload.style.display = 'none';
      plaintextPanel.style.display = 'none';
      
      if (activeDownloadUrl) {
        revokeBlobUrl(activeDownloadUrl);
        activeDownloadUrl = null;
      }
      if (currentPlaintextBlobUrl) {
        revokeBlobUrl(currentPlaintextBlobUrl);
        currentPlaintextBlobUrl = null;
      }
    },
    
    showError: (err) => {
      errorBanner.style.display = 'flex';
      errorMessage.textContent = err.message || 'Terjadi kesalahan.';
    },
    
    renderResult: (res, mode, activeCipher) => {
      // Normalize output between encrypt and decrypt
      const output = mode === 'encrypt' ? res.output : {
        letters: res.text,
        base64: res.plain_base64,
        hex: res.plain_base64 ? res.plain_base64 : '', // Need to derive hex if missing? Or just skip
        letters_truncated: res.plain_truncated,
        base64_truncated: res.plain_truncated,
        hex_truncated: res.plain_truncated,
        symbols_count: res.plain_total_bytes,
        container_b64: res.container_b64,
        plain_full_b64: res.plain_full_b64,
        mime_guess: res.mime_guess,
        original_filename: res.filename,
        integrity_valid: res.integrity ? res.integrity.valid : true
      };
      
      const inp = res.input;
      
      // Update data
      dataBase64.textContent = output.base64 || '';
      dataHex.textContent = mode === 'decrypt' ? '' : (output.hex || '');
      
      if (output.letters) {
        dataLetters.textContent = output.letters;
        tabLetters.style.display = 'block';
        activateTab('letters');
      } else {
        tabLetters.style.display = 'none';
        activateTab('base64');
      }
      
      // Meta
      let truncated = output.base64_truncated || output.hex_truncated || (output.letters && output.letters_truncated);
      meta.innerHTML = `<span>${output.symbols_count || output.symbol_count || 0} simbol</span> &bull; <span>Encoding: ${activeCipher ? activeCipher.group : 'unknown'}</span>${truncated ? ' &bull; <span style="color:var(--warning)">[Terpotong untuk tampilan]</span>' : ''}`;
      
      // Container Download (Encrypt)
      if (mode === 'encrypt' && res.container_b64) {
        btnDownload.style.display = 'inline-flex';
        const bytes = decodeBase64ToUint8Array(res.container_b64);
        
        if (activeDownloadUrl) revokeBlobUrl(activeDownloadUrl);
        activeDownloadUrl = createBlobUrl(bytes, 'application/octet-stream');
        
        btnDownload.href = activeDownloadUrl;
        btnDownload.download = res.suggested_filename || 'cipher_output.dat';
        btnDownload.textContent = 'Unduh cipherteks (.dat)';
      } else if (mode === 'decrypt' && res.plain_full_b64) {
        // Plaintext File Download
        btnDownload.style.display = 'inline-flex';
        const bytes = decodeBase64ToUint8Array(res.plain_full_b64);
        
        if (activeDownloadUrl) revokeBlobUrl(activeDownloadUrl);
        activeDownloadUrl = createBlobUrl(bytes, res.mime_guess || 'application/octet-stream');
        
        btnDownload.href = activeDownloadUrl;
        btnDownload.download = sanitizeFilename(res.filename || 'decrypted_file');
        btnDownload.textContent = 'Unduh dengan nama asli';
        
        // Render preview if media
        if (output.mime_guess) {
          const previewEl = createPreviewElement(output.mime_guess, activeDownloadUrl);
          if (previewEl) {
            empty(dataBase64); // replace content with preview
            dataBase64.appendChild(previewEl);
            dataBase64.appendChild(el('div', {style: {marginTop: '8px', color: 'var(--ink-muted)'}}, `Pratinjau ${output.mime_guess}`));
          }
        }
      }
      
      // Plaintext B64 panel
      if (inp && inp.plain_base64) {
        plaintextPanel.style.display = 'block';
        plaintextB64Content.textContent = inp.plain_base64;
      } else {
        plaintextPanel.style.display = 'none';
      }
      
      // Integrity check
      if (mode === 'decrypt' && output.integrity_valid === false) {
        integrityBanner.style.display = 'flex';
      } else {
        integrityBanner.style.display = 'none';
      }
      
      // Focus result for accessibility
      byId('result-panel').setAttribute('tabindex', '-1');
      byId('result-panel').focus();
    }
  };
}
