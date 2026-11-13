/** Pinned local ZIPs only. Never download, execute archive code or publish pixels. */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
import {fileURLToPath} from 'node:url';
import {crc32} from './install_heroic_starter.mjs';

const game = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const manifestPath = path.join(game, 'assets/art/heroic/collection-manifest.json');
export const runtimeRoot = path.join(game, 'assets/third_party/heroic_collection');
export const LIMITS = Object.freeze({archive: 16 * 1024 * 1024, entry: 4 * 1024 * 1024, total: 32 * 1024 * 1024, entries: 4096});
export const sha256 = data => crypto.createHash('sha256').update(data).digest('hex');
const demand = (yes, message) => {if (!yes) throw new Error(message);};
export const readManifest = () => JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

function safePath(name) {
  return typeof name === 'string' && /^[\x20-\x7e]+$/.test(name) && !name.includes('\\') && !name.includes(':') && !name.startsWith('/') && !name.split('/').some((part, i, parts) => part === '.' || part === '..' || (!part && i !== parts.length - 1));
}

/** Validate every member envelope even though only pinned runtime PNGs are used. */
export function inspectArchive(binary, contract) {
  demand(Buffer.isBuffer(binary) && binary.length >= 22 && binary.length <= LIMITS.archive, 'Archive size exceeds budget');
  let end = -1;
  for (let offset = binary.length - 22; offset >= Math.max(0, binary.length - 65557); offset--) {
    if (binary.readUInt32LE(offset) === 0x06054b50 && offset + 22 + binary.readUInt16LE(offset + 20) === binary.length) {end = offset; break;}
  }
  demand(end >= 0, 'ZIP end record missing or trailing data present');
  demand(binary.readUInt16LE(end + 4) === 0 && binary.readUInt16LE(end + 6) === 0, 'Multi-disk ZIP rejected');
  const count = binary.readUInt16LE(end + 10), centralSize = binary.readUInt32LE(end + 12), start = binary.readUInt32LE(end + 16);
  demand(count > 0 && count <= LIMITS.entries && count === binary.readUInt16LE(end + 8), 'ZIP entry count exceeds budget or differs');
  demand(start + centralSize === end && start < end, 'ZIP64 or invalid central directory');
  const requested = contract.files, files = new Map(), seen = new Set(), selectedCase = new Set(), spans = [];
  demand(requested && Object.keys(requested).length > 0, 'Pack has no pinned runtime files');
  for (const name of Object.keys(requested)) {
    demand(safePath(name) && name.endsWith('.png'), 'Unsafe manifest path');
    demand(!selectedCase.has(name.toLowerCase()), 'Case-colliding runtime paths');
    selectedCase.add(name.toLowerCase());
  }
  let cursor = start, total = 0;
  for (let index = 0; index < count; index++) {
    demand(cursor + 46 <= end && binary.readUInt32LE(cursor) === 0x02014b50, 'Truncated central entry');
    const flags = binary.readUInt16LE(cursor + 8), method = binary.readUInt16LE(cursor + 10), crc = binary.readUInt32LE(cursor + 16);
    const packed = binary.readUInt32LE(cursor + 20), size = binary.readUInt32LE(cursor + 24);
    const nl = binary.readUInt16LE(cursor + 28), el = binary.readUInt16LE(cursor + 30), cl = binary.readUInt16LE(cursor + 32);
    const local = binary.readUInt32LE(cursor + 42), mode = binary.readUInt32LE(cursor + 38) >>> 16;
    demand(cursor + 46 + nl + el + cl <= end, 'Truncated filename metadata');
    const nameBytes = binary.subarray(cursor + 46, cursor + 46 + nl), name = nameBytes.toString('utf8');
    demand(safePath(name) && nameBytes.equals(Buffer.from(name, 'utf8')), 'Unsafe ZIP path');
    demand(!seen.has(name), 'Duplicate ZIP path'); seen.add(name);
    demand((mode & 0xf000) !== 0xa000 && [0, 0x4000, 0x8000].includes(mode & 0xf000), 'ZIP link or special file rejected');
    demand((flags & ~(0x800 | 8)) === 0 && [0, 8].includes(method), 'Encrypted or unsupported ZIP encoding');
    demand(size <= LIMITS.entry && packed <= LIMITS.archive && total + size <= LIMITS.total, 'ZIP expanded budget exceeded'); total += size;
    demand(local + 30 <= start && binary.readUInt32LE(local) === 0x04034b50, 'Invalid local header');
    const localNl = binary.readUInt16LE(local + 26), localEl = binary.readUInt16LE(local + 28);
    const payloadStart = local + 30 + localNl + localEl, payloadEnd = payloadStart + packed;
    demand(payloadEnd <= start && local + 30 + localNl <= start, 'ZIP payload crosses central directory');
    demand(binary.subarray(local + 30, local + 30 + localNl).equals(nameBytes), 'Local and central names differ');
    demand(binary.readUInt16LE(local + 6) === flags && binary.readUInt16LE(local + 8) === method, 'Local encoding differs');
    if (!(flags & 8)) demand(binary.readUInt32LE(local + 14) === crc && binary.readUInt32LE(local + 18) === packed && binary.readUInt32LE(local + 22) === size, 'Local size or checksum differs');
    let spanEnd = payloadEnd;
    if (flags & 8) {
      let descriptor = payloadEnd;
      if (descriptor + 4 <= start && binary.readUInt32LE(descriptor) === 0x08074b50) descriptor += 4;
      demand(descriptor + 12 <= start && binary.readUInt32LE(descriptor) === crc && binary.readUInt32LE(descriptor + 4) === packed && binary.readUInt32LE(descriptor + 8) === size, 'Invalid ZIP data descriptor');
      spanEnd = descriptor + 12;
    }
    for (const [a, b] of spans) demand(spanEnd <= a || local >= b, 'Overlapping ZIP members');
    spans.push([local, spanEnd]);
    // Every member's size and CRC is checked; unselected source formats are discarded.
    const data = method === 0 ? Buffer.from(binary.subarray(payloadStart, payloadEnd)) : zlib.inflateRawSync(binary.subarray(payloadStart, payloadEnd), {maxOutputLength: LIMITS.entry});
    demand(data.length === size && crc32(data) === crc, 'ZIP payload size or CRC differs');
    if (name.endsWith('/')) demand(size === 0, 'Directory has a payload');
    if (Object.hasOwn(requested, name)) files.set(name, data);
    cursor += 46 + nl + el + cl;
  }
  demand(cursor === end && files.size === Object.keys(requested).length, 'ZIP missing pinned runtime files');
  return files;
}

export function validatePng(binary, spec, name = '') {
  demand(Buffer.isBuffer(binary) && binary.length === spec.bytes && sha256(binary) === spec.sha256, 'PNG bytes or hash differ: ' + name);
  demand(binary.length >= 33 && binary.subarray(0, 8).equals(Buffer.from('89504e470d0a1a0a', 'hex')) && binary.readUInt32BE(8) === 13 && binary.toString('ascii', 12, 16) === 'IHDR', 'Invalid PNG header: ' + name);
  demand(binary.readUInt32BE(16) === spec.width && binary.readUInt32BE(20) === spec.height, 'PNG dimensions differ: ' + name);
}

export function validateArchive(binary, contract) {
  const files = inspectArchive(binary, contract);
  demand(binary.length === contract.archive.bytes && sha256(binary) === contract.archive.sha256, 'ZIP differs from pinned user-supplied version');
  for (const [name, spec] of Object.entries(contract.files)) validatePng(files.get(name), spec, name);
  return files;
}

function noLinks(target) {
  let current = path.parse(target).root;
  for (const part of target.slice(current.length).split(path.sep).filter(Boolean)) {
    current = path.join(current, part);
    try {demand(!fs.lstatSync(current).isSymbolicLink(), 'Installation path contains a symbolic link: ' + current);} catch (error) {if (error.code !== 'ENOENT') throw error;}
  }
}

export function checkInstallation(target = runtimeRoot, contract = readManifest()) {
  const failures = [], absolute = path.resolve(target);
  try {noLinks(absolute);} catch (error) {failures.push(error.message);}
  const absent = !fs.existsSync(absolute) && !failures.length;
  let count = 0, rgba = 0;
  if (!absent && !failures.length) for (const [id, pack] of Object.entries(contract.packs)) for (const [name, spec] of Object.entries(pack.files)) {
    try {
      demand(/^[a-z]+$/.test(id) && safePath(name), 'Unsafe manifest path');
      const file = path.join(absolute, id, name); noLinks(file);
      const stat = fs.lstatSync(file);
      demand(stat.isFile() && stat.size === spec.bytes && stat.size <= LIMITS.entry, 'Missing or invalid installed PNG: ' + id + '/' + name);
      validatePng(fs.readFileSync(file), spec, id + '/' + name);
      count++; rgba += spec.width * spec.height * 4;
    } catch (error) {failures.push(error.message);}
  }
  if (!absent && rgba > contract.texture_budget_bytes) failures.push('Selected runtime pixels exceed declared budget');
  return {ready: failures.length === 0, profile: absent ? 'starter' : 'collection', installed: !absent, files: count, selected_rgba8_bytes: rgba, failures, install_command: 'node tools/install_heroic_collection.mjs --from-dir "/path/to/asset-library"'};
}

export function installLocalCollection(sourceDirectory, target = runtimeRoot, contract = readManifest()) {
  const source = path.resolve(sourceDirectory), absolute = path.resolve(target), staged = new Map();
  for (const [id, pack] of Object.entries(contract.packs)) {
    demand(/^[a-z]+$/.test(id) && path.basename(pack.archive.file) === pack.archive.file, 'Unsafe pack contract');
    const sourcePath = path.join(source, pack.archive.file), stat = fs.lstatSync(sourcePath);
    demand(stat.isFile() && !stat.isSymbolicLink() && stat.size <= LIMITS.archive, 'Input must be a bounded local regular ZIP: ' + pack.archive.file);
    staged.set(id, validateArchive(fs.readFileSync(sourcePath), pack));
  }
  noLinks(absolute);
  if (fs.existsSync(absolute)) {
    const status = checkInstallation(absolute, contract);
    demand(status.ready, 'Existing invalid installation preserved; move it aside before reinstalling. ' + status.failures.join('; '));
    return {...status, action: 'already-installed'};
  }
  const parent = path.dirname(absolute); fs.mkdirSync(parent, {recursive: true});
  const temporary = fs.mkdtempSync(path.join(parent, '.heroic-collection-tmp-'));
  try {
    for (const [id, files] of staged) for (const [name, data] of files) {
      const output = path.join(temporary, id, name); fs.mkdirSync(path.dirname(output), {recursive: true}); fs.writeFileSync(output, data, {flag: 'wx'});
    }
    fs.writeFileSync(path.join(temporary, 'installation-receipt.json'), JSON.stringify({schema_version: 1, pack_id: contract.pack_id, archive_sha256: Object.fromEntries(Object.entries(contract.packs).map(([id, p]) => [id, p.archive.sha256])), manifest_sha256: sha256(Buffer.from(JSON.stringify(contract))), attribution: contract.attribution, public_raw_redistribution: false}, null, 2) + '\n', {flag: 'wx'});
    const checked = checkInstallation(temporary, contract); demand(checked.ready && checked.installed, 'Temporary collection failed validation');
    demand(!fs.existsSync(absolute), 'Installation target appeared; nothing overwritten');
    fs.renameSync(temporary, absolute);
    return {...checkInstallation(absolute, contract), action: 'installed'};
  } finally {
    // Only this invocation's mkdtemp path, never the installed or source directories.
    if (fs.existsSync(temporary)) fs.rmSync(temporary, {recursive: true});
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = process.argv.slice(2);
    demand(args.length === 1 && args[0] === '--check' || args.length === 2 && args[0] === '--from-dir', 'Usage: node tools/install_heroic_collection.mjs --from-dir <local ZIP directory> | --check');
    const result = args[0] === '--check' ? checkInstallation() : installLocalCollection(args[1]);
    console.log(JSON.stringify(result, null, 2)); if (!result.ready) process.exitCode = 2;
  } catch (error) {console.error('Heroic 完整包安装失败 / installation failed: ' + error.message); process.exitCode = 2;}
}
