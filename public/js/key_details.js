import { el, empty, byId } from './dom.js';

export function renderKeyDetails(keyInfo) {
  const panel = byId('key-details-panel');
  const content = byId('key-details-content');
  const infoContent = byId('key-info-content'); // Info ringkas di kolom kiri
  const infoPanel = byId('key-info-panel');
  
  if (!keyInfo || Object.keys(keyInfo).length === 0) {
    panel.style.display = 'none';
    infoPanel.style.display = 'none';
    return;
  }
  
  // Render untuk panel kiri
  empty(infoContent);
  infoPanel.style.display = 'flex';
  
  // Render untuk panel kanan
  empty(content);
  panel.style.display = 'flex';
  
  // Pretty JSON for now, or custom table if specific
  const pre = el('pre', { style: { margin: 0, fontFamily: 'var(--font-mono)' } }, JSON.stringify(keyInfo, null, 2));
  content.appendChild(pre);
  
  // Simple view for left panel
  const list = el('ul', { style: { paddingLeft: '16px', margin: 0 } });
  for (const [k, v] of Object.entries(keyInfo)) {
    if (v === null || v === undefined) continue;
    let text = String(v);
    if (Array.isArray(v)) text = `[Array length ${v.length}]`;
    if (text.length > 30) text = text.slice(0, 30) + '...';
    list.appendChild(el('li', {}, `${k}: ${text}`));
  }
  infoContent.appendChild(list);
  
  // Collapsible toggle
  const toggle = byId('key-details-toggle');
  // Re-bind to prevent duplicates if called multiple times - actually already bound in main
}
