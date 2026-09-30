import { el, empty, byId } from './dom.js';
import { state, setState } from './state.js';

let formFields = [];
const formContainer = byId('key-form');
const keyErrorContainer = el('span', { className: 'field-error', id: 'key-form-general-error' });

export function buildSchemaForm(fields, cipherId) {
  empty(formContainer);
  formFields = fields;
  
  const saved = state.savedParams[cipherId] || {};
  
  fields.forEach(field => {
    const fieldContainer = el('div', { className: 'field', id: `field-container-${field.name}` });
    
    // Label
    const label = el('label', { className: 'field-label', htmlFor: `input-${field.name}` }, field.label);
    fieldContainer.appendChild(label);
    
    // Input element
    let inputEl = null;
    let savedVal = saved[field.name];
    
    if (field.type === 'text') {
      inputEl = el('input', { 
        type: 'text', 
        id: `input-${field.name}`, 
        className: 'input mono', 
        value: savedVal || '' 
      });
      fieldContainer.appendChild(inputEl);
      
    } else if (field.type === 'integer') {
      if (field.options && field.options.length > 0) {
        inputEl = el('select', { id: `input-${field.name}`, className: 'select mono' });
        field.options.forEach(opt => {
          const optEl = el('option', { value: opt.value }, opt.label);
          if (savedVal && String(savedVal) === String(opt.value)) optEl.selected = true;
          inputEl.appendChild(optEl);
        });
        fieldContainer.appendChild(inputEl);
      } else {
        inputEl = el('input', { 
          type: 'number', 
          id: `input-${field.name}`, 
          className: 'input mono',
          value: savedVal || '' 
        });
        fieldContainer.appendChild(inputEl);
      }
      
    } else if (field.type === 'matrix') {
      // Untuk matrix, kita butuh elemen yang lebih kompleks
      // Hill Cipher punya n (ukuran matriks) dan matrix (isi).
      // API mengirim `n` (integer dengan opsi) dan `matrix` atau `key_text` (text).
      // Jadi jika field.type === 'matrix', ini adalah placeholder untuk manual grid
      const gridContainer = el('div', { className: 'matrix-grid', id: `grid-${field.name}` });
      fieldContainer.appendChild(gridContainer);
      
      // Kita akan dengarkan perubahan dari select 'n' secara hardcode jika ada.
      // Ini agak tricky, karena schema-driven.
      // Jika `savedVal` ada dan berupa array of array, kita bisa render.
      
      inputEl = {
        isMatrix: true,
        grid: gridContainer,
        name: field.name,
        getValue: () => {
          // Kumpulkan dari grid
          const inputs = gridContainer.querySelectorAll('input');
          if (inputs.length === 0) return null;
          const n = Math.sqrt(inputs.length);
          if (!Number.isInteger(n)) return null;
          const matrix = [];
          for (let i = 0; i < n; i++) {
            const row = [];
            for (let j = 0; j < n; j++) {
              row.push(inputs[i * n + j].value);
            }
            matrix.push(row);
          }
          return matrix;
        },
        render: (n) => {
          empty(gridContainer);
          gridContainer.style.gridTemplateColumns = `repeat(${n}, 48px)`;
          const matrixData = Array.isArray(saved[field.name]) ? saved[field.name] : [];
          for (let i = 0; i < n; i++) {
            for (let j = 0; j < n; j++) {
              let v = '';
              if (matrixData[i] && matrixData[i][j] !== undefined) v = matrixData[i][j];
              const cell = el('input', { class: 'input matrix-input mono', value: v });
              gridContainer.appendChild(cell);
            }
          }
        }
      };
      
    } else if (field.type === 'rotor_set') {
      // Enigma specific logic: 3 rotor selects
      inputEl = {
        isRotorSet: true,
        getValue: () => null // ditangani khusus jika perlu, atau kirim sebagai teks mentah jika api menerimanya
      };
      
      const rContainer = el('div', { style: { display: 'flex', gap: '8px' } });
      const rLeft = el('select', { class: 'select' }, [el('option', { value: 'I' }, 'I'), el('option', { value: 'II' }, 'II'), el('option', { value: 'III' }, 'III')]);
      const rMid = el('select', { class: 'select' }, [el('option', { value: 'II' }, 'II'), el('option', { value: 'I' }, 'I'), el('option', { value: 'III' }, 'III')]);
      const rRight = el('select', { class: 'select' }, [el('option', { value: 'III' }, 'III'), el('option', { value: 'I' }, 'I'), el('option', { value: 'II' }, 'II')]);
      
      rContainer.appendChild(rLeft);
      rContainer.appendChild(rMid);
      rContainer.appendChild(rRight);
      fieldContainer.appendChild(rContainer);
      
      inputEl.getValue = () => `${rLeft.value},${rMid.value},${rRight.value}`;
    } else if (field.type === 'plugboard') {
      inputEl = el('input', { type: 'text', id: `input-${field.name}`, className: 'input mono', value: savedVal || '', placeholder: 'AB CD EF' });
      
      const counterEl = el('span', { className: 'text-small text-help', style: { marginLeft: '8px' } }, '0 pasang');
      inputEl.addEventListener('input', () => {
        const pairs = inputEl.value.match(/[a-zA-Z]{2}/g) || [];
        counterEl.textContent = `${pairs.length} pasang`;
      });
      // trigger once
      const pairsInit = (savedVal || '').match(/[a-zA-Z]{2}/g) || [];
      counterEl.textContent = `${pairsInit.length} pasang`;
      
      fieldContainer.appendChild(inputEl);
      fieldContainer.appendChild(counterEl);
      
    } else {
      // fallback
      inputEl = el('input', { type: 'text', id: `input-${field.name}`, className: 'input mono', value: savedVal || '' });
      fieldContainer.appendChild(inputEl);
      console.warn(`Tipe field tidak dikenal: ${field.type}`);
    }
    
    // Help text
    if (field.help) {
      fieldContainer.appendChild(el('span', { className: 'field-help' }, field.help));
    }
    
    // Error text (hidden initially)
    const errorEl = el('span', { className: 'field-error', id: `error-${field.name}` });
    fieldContainer.appendChild(errorEl);
    
    formContainer.appendChild(fieldContainer);
    
    // Simpan ref ke inputEl di field untuk getParams()
    field.inputRef = inputEl;
  });
  
  // Custom logic for matrix size if 'n' exists
  const nSelect = byId('input-n');
  const matrixField = formFields.find(f => f.type === 'matrix');
  if (nSelect && matrixField) {
    const updateMatrix = () => {
      const n = parseInt(nSelect.value, 10);
      matrixField.inputRef.render(n);
    };
    nSelect.addEventListener('change', updateMatrix);
    updateMatrix();
  }
  
  formContainer.appendChild(keyErrorContainer);
}

export function getParams() {
  const params = {};
  for (const field of formFields) {
    if (field.inputRef && field.inputRef.isMatrix) {
      const mat = field.inputRef.getValue();
      if (mat) params[field.name] = mat;
    } else if (field.inputRef && field.inputRef.isRotorSet) {
      params[field.name] = field.inputRef.getValue();
    } else if (field.inputRef) {
      params[field.name] = field.inputRef.value;
    }
  }
  
  // Save locally
  if (state.activeCipherId) {
    state.savedParams[state.activeCipherId] = params;
  }
  
  return params;
}

export function showValidationError(field, message) {
  // Clear all errors
  clearValidationErrors();
  
  if (field) {
    const fieldContainer = byId(`field-container-${field}`);
    const errorEl = byId(`error-${field}`);
    if (fieldContainer && errorEl) {
      fieldContainer.classList.add('has-error');
      errorEl.textContent = message;
      
      const inputEl = byId(`input-${field}`);
      if (inputEl) inputEl.focus();
    }
  } else {
    keyErrorContainer.textContent = message;
    keyErrorContainer.style.display = 'block';
  }
}

export function clearValidationErrors() {
  for (const field of formFields) {
    const fieldContainer = byId(`field-container-${field.name}`);
    if (fieldContainer) fieldContainer.classList.remove('has-error');
  }
  keyErrorContainer.style.display = 'none';
}
