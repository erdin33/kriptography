import test from 'node:test';
import assert from 'node:assert/strict';
import { sanitizeFilename, decodeBase64ToUint8Array } from '../download.js';

test('sanitizeFilename removes path traversal and control characters', () => {
  assert.equal(sanitizeFilename('path/to/file.txt'), 'file.txt');
  assert.equal(sanitizeFilename('..\\windows\\file.txt'), 'file.txt');
  assert.equal(sanitizeFilename('normal.pdf'), 'normal.pdf');
  assert.equal(sanitizeFilename('file\x00\x1F.txt'), 'file.txt');
});

test('decodeBase64ToUint8Array decodes correctly', () => {
  const b64 = 'SGVsbG8='; // "Hello"
  const bytes = decodeBase64ToUint8Array(b64);
  assert.equal(bytes.length, 5);
  assert.equal(bytes[0], 72); // H
  assert.equal(bytes[1], 101); // e
  assert.equal(bytes[2], 108); // l
  assert.equal(bytes[3], 108); // l
  assert.equal(bytes[4], 111); // o
});
