// public/js/dom.js

/**
 * Membuat elemen DOM secara aman dengan textContent.
 * @param {string} tag Nama tag elemen.
 * @param {Object} attrs Atribut elemen.
 * @param {Array|string|Element} children Anak elemen.
 * @returns {Element}
 */
export function el(tag, attrs = {}, children = []) {
  const element = document.createElement(tag);
  
  for (const [key, value] of Object.entries(attrs)) {
    if (key.startsWith('on') && typeof value === 'function') {
      element.addEventListener(key.slice(2).toLowerCase(), value);
    } else if (key === 'className') {
      element.className = value;
    } else if (key === 'dataset') {
      for (const [dKey, dVal] of Object.entries(value)) {
        element.dataset[dKey] = dVal;
      }
    } else if (key === 'style' && typeof value === 'object') {
      Object.assign(element.style, value);
    } else {
      // boolean attributes like 'disabled', 'checked'
      if (value === true) {
        element.setAttribute(key, '');
      } else if (value !== false && value !== null && value !== undefined) {
        element.setAttribute(key, value);
      }
    }
  }

  const childArray = Array.isArray(children) ? children : [children];
  for (const child of childArray) {
    if (child == null) continue;
    if (child instanceof Node) {
      element.appendChild(child);
    } else {
      element.appendChild(document.createTextNode(String(child)));
    }
  }

  return element;
}

/**
 * Menghapus semua anak dari sebuah elemen.
 * @param {Element} element 
 */
export function empty(element) {
  while (element.firstChild) {
    element.removeChild(element.firstChild);
  }
}

/**
 * Mencari elemen berdasarkan ID.
 * @param {string} id 
 * @returns {Element}
 */
export function byId(id) {
  return document.getElementById(id);
}
