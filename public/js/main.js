import { state, setState, getActiveCipher, subscribe } from './state.js';
import { initTheme } from './theme.js';
import { fetchCiphers, apiEncrypt, apiDecrypt, cancelRequest } from './api.js';
import { buildSchemaForm, getParams, showValidationError, clearValidationErrors } from './schema_form.js';
import { initInputPanel } from './input_panel.js';
import { initResultPanel } from './result_panel.js';
import { renderKeyDetails } from './key_details.js';
import { byId, empty, el } from './dom.js';

document.addEventListener('DOMContentLoaded', async () => {
  initTheme();
  
  const inputPanel = initInputPanel();
  const resultPanel = initResultPanel();
  
  const cipherSelect = byId('cipher-select');
  const cipherSummary = byId('cipher-summary');
  const btnProcess = byId('btn-process');
  const btnClear = byId('btn-clear');
  
  const modeEncrypt = byId('mode-encrypt');
  const modeDecrypt = byId('mode-decrypt');
  
  // Load ciphers
  try {
    const res = await fetchCiphers();
    if (res.ok && res.ciphers) {
      setState({ ciphers: res.ciphers });
      
      // Update select
      empty(cipherSelect);
      const groups = {};
      res.ciphers.forEach(c => {
        if (!groups[c.group]) groups[c.group] = [];
        groups[c.group].push(c);
      });
      
      for (const [groupName, list] of Object.entries(groups)) {
        const optgroup = el('optgroup', { label: groupName });
        list.forEach(c => {
          optgroup.appendChild(el('option', { value: c.id }, c.title));
        });
        cipherSelect.appendChild(optgroup);
      }
      
      // Set initial
      if (res.ciphers.length > 0) {
        setState({ activeCipherId: res.ciphers[0].id });
        cipherSelect.value = res.ciphers[0].id;
        updateCipherUI();
      }
    }
  } catch (err) {
    showValidationError(null, 'Gagal memuat katalog cipher dari server.');
  }
  
  // Mode switch
  modeEncrypt.addEventListener('change', () => setState({ mode: 'encrypt' }));
  modeDecrypt.addEventListener('change', () => setState({ mode: 'decrypt' }));
  
  // Cipher switch
  cipherSelect.addEventListener('change', () => {
    setState({ activeCipherId: cipherSelect.value });
    updateCipherUI();
  });
  
  function updateDecryptFormatOptions(cipher) {
    if (!cipher) return;
    const fmtLetters = byId('fmt-letters');
    const fmtLettersLabel = document.querySelector('label[for="fmt-letters"]');
    const fmtHex = byId('fmt-hex');
    if (fmtLetters && fmtLettersLabel) {
      if (cipher.domain === 'bytes') {
        fmtLetters.disabled = true;
        fmtLettersLabel.style.display = 'none';
        if (fmtLetters.checked && fmtHex) {
          fmtHex.checked = true;
        }
      } else {
        fmtLetters.disabled = false;
        fmtLettersLabel.style.display = '';
      }
    }
  }

  function updateCipherUI() {
    const cipher = getActiveCipher();
    if (!cipher) return;
    
    cipherSummary.textContent = cipher.summary;
    byId('cipher-domain-badge').textContent = cipher.domain === 'letters' ? '26 Huruf' : '256 Byte';
    byId('cipher-group-badge').textContent = cipher.group;
    
    buildSchemaForm(cipher.fields, cipher.id);
    resultPanel.clear();
    updateDecryptFormatOptions(cipher);
  }
  
  // Key Details toggle binding
  byId('key-details-toggle').addEventListener('click', function() {
    const isExpanded = this.getAttribute('aria-expanded') === 'true';
    this.setAttribute('aria-expanded', String(!isExpanded));
  });
  
  // Process
  btnProcess.addEventListener('click', async () => {
    if (state.isProcessing) {
      cancelRequest();
      setState({ isProcessing: false });
      btnProcess.textContent = state.mode === 'encrypt' ? 'Enkripsi' : 'Dekripsi';
      return;
    }
    
    clearValidationErrors();
    resultPanel.clear();
    
    const params = getParams();
    const cipher = getActiveCipher();
    if (!cipher) return;
    
    setState({ isProcessing: true });
    btnProcess.textContent = 'Membatalkan...'; // akan ditimpa jika request cepat
    // tambahkan delay kecil untuk show cancel
    const cancelTextTimer = setTimeout(() => {
      if (state.isProcessing) btnProcess.textContent = 'Batal (Memproses...)';
    }, 1000);
    
    try {
      let res;
      if (state.mode === 'encrypt') {
        const textOrFile = state.inputType === 'text' ? state.textInput : state.fileInput;
        if (!textOrFile) throw new Error('Data input kosong.');
        res = await apiEncrypt(cipher.id, params, state.inputType, textOrFile);
      } else {
        if (state.inputType === 'file') {
          if (!state.fileInput) throw new Error('Berkas kosong.');
          res = await apiDecrypt(cipher.id, params, 'container', state.fileInput, null);
        } else {
          if (!state.textInput) throw new Error('Teks kosong.');
          // Gunakan format teks dari radio button format (letters, base64, hex)
          const fmtNode = document.querySelector('input[name="decrypt-format"]:checked');
          const fmt = fmtNode ? fmtNode.value : (cipher.domain === 'letters' ? 'letters' : 'base64');
          res = await apiDecrypt(cipher.id, params, 'text', fmt, state.textInput);
        }
      }
      
      if (res.ok) {
        resultPanel.renderResult(res, state.mode, cipher);
        if (res.key_info) {
          renderKeyDetails(res.key_info);
        }
      }
    } catch (err) {
      if (err.isAbort) {
        // dibatalkan pengguna
      } else if (err.apiError && err.code === 'invalid_key') {
        showValidationError(err.field, err.message);
      } else {
        resultPanel.showError(err);
      }
    } finally {
      clearTimeout(cancelTextTimer);
      setState({ isProcessing: false });
      btnProcess.textContent = state.mode === 'encrypt' ? 'Enkripsi' : 'Dekripsi';
    }
  });
  
  // Clear
  btnClear.addEventListener('click', () => {
    inputPanel.clear();
    resultPanel.clear();
    clearValidationErrors();
    renderKeyDetails(null);
  });
  
  // Shortcuts
  document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      btnProcess.click();
    }
  });
  
  // Reactive updates
  subscribe((s) => {
    btnProcess.textContent = s.mode === 'encrypt' ? 'Enkripsi' : 'Dekripsi';
    const decryptFormatArea = byId('decrypt-format-area');
    if (decryptFormatArea) {
      decryptFormatArea.style.display = (s.mode === 'decrypt' && s.inputType === 'text') ? 'block' : 'none';
    }
    const cipher = getActiveCipher();
    if (cipher) {
      updateDecryptFormatOptions(cipher);
    }
  });
});
