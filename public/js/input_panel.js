import { byId } from './dom.js';
import { state, setState } from './state.js';
import { apiInspect } from './api.js';
import { showValidationError } from './schema_form.js';

export function initInputPanel() {
  const inText = byId('in-text');
  const inFile = byId('in-file');
  const textArea = byId('input-text-area');
  const fileArea = byId('input-file-area');
  
  const textInput = byId('input-text');
  const textCount = byId('input-text-count');
  const loadSampleLink = byId('load-sample-link');
  
  const dropzone = byId('dropzone');
  const fileInput = byId('file-input');
  const btnSelectFile = byId('btn-select-file');
  const btnClearFile = byId('btn-clear-file');
  const fileCard = byId('file-card');
  const fileName = byId('file-name');
  const fileSize = byId('file-size');
  const fileType = byId('file-type');
  
  function updateView() {
    if (state.inputType === 'text') {
      textArea.style.display = 'flex';
      fileArea.style.display = 'none';
      textInput.focus();
    } else {
      textArea.style.display = 'none';
      fileArea.style.display = 'block';
    }
  }
  
  inText.addEventListener('change', () => {
    setState({ inputType: 'text' });
    updateView();
  });
  
  inFile.addEventListener('change', () => {
    setState({ inputType: 'file' });
    updateView();
  });
  
  textInput.addEventListener('input', () => {
    setState({ textInput: textInput.value });
    textCount.textContent = textInput.value.length;
  });
  
  loadSampleLink.addEventListener('click', (e) => {
    e.preventDefault();
    const sample = "Di bawah sinar bulan purnama, air laut berkilauan, berayun-ayun ombak mengalir ke pantai senda gurauan";
    textInput.value = sample;
    setState({ textInput: sample });
    textCount.textContent = sample.length;
  });
  
  // File handling
  function handleFile(file) {
    if (!file) return;
    
    if (file.size > state.limits.max_upload_bytes) {
      alert(`Ukuran berkas melebihi batas maksimal (${Math.floor(state.limits.max_upload_bytes / 1024 / 1024)}MB)`);
      return;
    }
    
    setState({ fileInput: file });
    
    // UI updates
    dropzone.style.display = 'none';
    fileCard.style.display = 'flex';
    fileName.textContent = file.name;
    fileSize.textContent = `${(file.size / 1024).toFixed(1)} KB`;
    fileType.textContent = file.type || 'application/octet-stream';
    
    // Inspect if mode is decrypt
    if (state.mode === 'decrypt') {
      inspectFile(file);
    }
  }
  
  async function inspectFile(file) {
    try {
      const info = await apiInspect(file);
      if (info.ok) {
        fileName.textContent = info.original_filename || file.name;
        
        if (state.activeCipherId !== info.cipher) {
          showValidationError(null, `Perhatian: Berkas ini dienkripsi dengan ${info.cipher}, tetapi cipher aktif adalah ${state.activeCipherId}. Silakan ganti cipher.`);
        }
      }
    } catch (err) {
      if (err.apiError && err.code === 'invalid_container') {
        showValidationError(null, 'Berkas bukan format .dat Cipher Workbench yang valid.');
      }
    }
  }
  
  btnSelectFile.addEventListener('click', () => {
    fileInput.click();
  });
  
  fileInput.addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
      handleFile(e.target.files[0]);
    }
  });
  
  btnClearFile.addEventListener('click', () => {
    setState({ fileInput: null });
    fileInput.value = '';
    dropzone.style.display = 'flex';
    fileCard.style.display = 'none';
  });
  
  // Drag and drop
  dropzone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropzone.classList.add('is-dragover');
  });
  
  dropzone.addEventListener('dragleave', (e) => {
    e.preventDefault();
    dropzone.classList.remove('is-dragover');
  });
  
  dropzone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropzone.classList.remove('is-dragover');
    if (e.dataTransfer.files.length > 0) {
      handleFile(e.dataTransfer.files[0]);
    }
  });
  
  // Expose clean function
  return {
    clear: () => {
      textInput.value = '';
      textCount.textContent = '0';
      setState({ textInput: '' });
      btnClearFile.click();
    }
  };
}
