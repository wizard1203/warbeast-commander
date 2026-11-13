/** Local, pinned asset installation only. No network, shell, or pack code execution. */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
import {fileURLToPath} from 'node:url';

const game = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const manifestPath = path.join(game, 'assets/art/heroic/manifest.json');
export const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
export const runtimeRoot = path.join(game, 'assets/third_party/heroic_local');
export const LIMITS = Object.freeze({archive: 2 * 1024 * 1024, entry: 512 * 1024, total: 1024 * 1024, entries: 32});
const sha256 = data => crypto.createHash('sha256').update(data).digest('hex');
const demand = (condition, message) => {if (!condition) throw new Error(message);};

export function crc32(data) {
  let crc = 0xffffffff;
  for (const value of data) {
    crc ^= value;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

/** Parse the bounded ZIP envelope before trusting even its pinned archive hash. */
export function inspectArchive(binary, contract = manifest) {
  demand(Buffer.isBuffer(binary) && binary.length >= 22 && binary.length <= LIMITS.archive, 'Archive size exceeds the bounded ZIP budget');
  let end = -1;
  for (let offset = binary.length - 22; offset >= Math.max(0, binary.length - 65557); offset--) {
    if (binary.readUInt32LE(offset) === 0x06054b50 && offset + 22 + binary.readUInt16LE(offset + 20) === binary.length) {end = offset; break;}
  }
  demand(end >= 0, 'ZIP end record absent or trailing data present');
  demand(binary.readUInt16LE(end + 4) === 0 && binary.readUInt16LE(end + 6) === 0, 'Multi-disk ZIP is not accepted');
  const count = binary.readUInt16LE(end + 10), centralSize = binary.readUInt32LE(end + 12), centralStart = binary.readUInt32LE(end + 16);
  demand(count > 0 && count <= LIMITS.entries && count === binary.readUInt16LE(end + 8), 'ZIP entry count exceeds budget or differs between disks');
  demand(centralStart + centralSize === end && centralStart < end, 'ZIP64, overlapping, or invalid central directory');
  const root = contract.archive.root;
  const allowed = new Set(Object.values(contract.sheets).map(sheet => root + sheet.file));
  const files = new Map(), seen = new Set(), spans = [];
  let cursor = centralStart, total = 0;
  for (let index = 0; index < count; index++) {
    demand(cursor + 46 <= end && binary.readUInt32LE(cursor) === 0x02014b50, 'Truncated ZIP central entry');
    const flags = binary.readUInt16LE(cursor + 8), method = binary.readUInt16LE(cursor + 10), crc = binary.readUInt32LE(cursor + 16);
    const packed = binary.readUInt32LE(cursor + 20), size = binary.readUInt32LE(cursor + 24);
    const nameLength = binary.readUInt16LE(cursor + 28), extraLength = binary.readUInt16LE(cursor + 30), commentLength = binary.readUInt16LE(cursor + 32);
    const local = binary.readUInt32LE(cursor + 42), mode = binary.readUInt32LE(cursor + 38) >>> 16;
    demand(cursor + 46 + nameLength + extraLength + commentLength <= end, 'Truncated ZIP filename or metadata');
    const nameBytes = binary.subarray(cursor + 46, cursor + 46 + nameLength), name = nameBytes.toString('utf8');
    demand(name.length > 0 && /^[\x20-\x7e]+$/.test(name) && !name.includes('\\') && !name.startsWith('/') && !name.includes(':') && !name.split('/').includes('..') && !name.split('/').includes('.'), 'Unsafe ZIP path');
    demand(!seen.has(name), 'Duplicate ZIP entry');
    seen.add(name);
    demand((mode & 0xf000) !== 0xa000, 'ZIP symbolic link rejected');
    demand((flags & ~(0x800 | 8)) === 0 && [0, 8].includes(method), 'Encrypted or unsupported ZIP encoding');
    demand(size <= LIMITS.entry && packed <= LIMITS.archive && total + size <= LIMITS.total, 'ZIP uncompressed size exceeds budget');
    total += size;
    const directory = name.endsWith('/');
    demand(directory ? name === root && size === 0 : allowed.has(name) && name.endsWith('.png'), 'ZIP contains a non-whitelisted file (only seven named PNG sheets are accepted)');
    demand(local + 30 <= centralStart && binary.readUInt32LE(local) === 0x04034b50, 'Invalid ZIP local header');
    const localNameLength = binary.readUInt16LE(local + 26), localExtraLength = binary.readUInt16LE(local + 28);
    const payloadStart = local + 30 + localNameLength + localExtraLength, payloadEnd = payloadStart + packed;
    demand(payloadEnd <= centralStart && local + 30 + localNameLength <= centralStart, 'ZIP payload crosses the central directory');
    demand(binary.subarray(local + 30, local + 30 + localNameLength).equals(nameBytes), 'ZIP local and central names differ');
    demand(binary.readUInt16LE(local + 6) === flags && binary.readUInt16LE(local + 8) === method, 'ZIP local and central encodings differ');
    if (!(flags & 8)) demand(binary.readUInt32LE(local + 14) === crc && binary.readUInt32LE(local + 18) === packed && binary.readUInt32LE(local + 22) === size, 'ZIP local size or checksum differs');
    for (const span of spans) demand(payloadEnd <= span[0] || local >= span[1], 'Overlapping ZIP members');
    spans.push([local, payloadEnd]);
    const compressed = binary.subarray(payloadStart, payloadEnd);
    const data = method === 0 ? Buffer.from(compressed) : zlib.inflateRawSync(compressed, {maxOutputLength: LIMITS.entry});
    demand(data.length === size && crc32(data) === crc, 'ZIP payload checksum or byte length differs');
    if (!directory) files.set(name.slice(root.length), data);
    cursor += 46 + nameLength + extraLength + commentLength;
  }
  demand(cursor === end && files.size === allowed.size, 'ZIP does not contain the complete seven-sheet Starter pack');
  return files;
}

export function validatePng(binary, sheet) {
  demand(binary.length === sheet.bytes && sha256(binary) === sheet.sha256, 'PNG bytes or SHA-256 differ: ' + sheet.file);
  demand(binary.length >= 33 && binary.subarray(0, 8).equals(Buffer.from('89504e470d0a1a0a', 'hex')) && binary.readUInt32BE(8) === 13 && binary.toString('ascii', 12, 16) === 'IHDR', 'PNG header invalid: ' + sheet.file);
  demand(binary.readUInt32BE(16) === sheet.width && binary.readUInt32BE(20) === sheet.height, 'PNG dimensions differ: ' + sheet.file);
}

export function validateArchive(binary, contract = manifest) {
  const files = inspectArchive(binary, contract);
  demand(binary.length === contract.archive.bytes && sha256(binary) === contract.archive.sha256, 'Archive bytes or SHA-256 differ from the pinned legitimate download');
  for (const sheet of Object.values(contract.sheets)) validatePng(files.get(sheet.file), sheet);
  return files;
}

function assertNoSymlinkComponents(target) {
  let current = path.parse(target).root;
  for (const part of target.slice(current.length).split(path.sep).filter(Boolean)) {
    current = path.join(current, part);
    if (fs.existsSync(current) || (() => {try {return fs.lstatSync(current).isSymbolicLink();} catch {return false;}})()) demand(!fs.lstatSync(current).isSymbolicLink(), 'Installation path contains a symbolic link: ' + current);
  }
}

export function checkInstallation(target = runtimeRoot, contract = manifest) {
  const failures = [];
  try {assertNoSymlinkComponents(path.resolve(target));} catch (error) {failures.push(error.message);}
  if (!failures.length) for (const sheet of Object.values(contract.sheets)) {
    try {
      const source = path.join(target, sheet.file), stat = fs.lstatSync(source);
      demand(stat.isFile() && !stat.isSymbolicLink(), 'Installed PNG is not a regular file: ' + sheet.file);
      demand(stat.size === sheet.bytes && stat.size <= LIMITS.entry, 'Installed PNG size differs: ' + sheet.file);
      validatePng(fs.readFileSync(source), sheet);
    } catch (error) {failures.push(error.message);}
  }
  return {ready: failures.length === 0, pack_id: contract.pack_id, files: Object.keys(contract.sheets).length, failures, install_command: 'node tools/install_heroic_starter.mjs "/path/to/HAS Starter Pack.zip"'};
}

export function installLocalArchive(archivePath, target = runtimeRoot) {
  const absoluteArchive = path.resolve(archivePath), absoluteTarget = path.resolve(target);
  const stat = fs.lstatSync(absoluteArchive);
  demand(stat.isFile() && !stat.isSymbolicLink() && stat.size <= LIMITS.archive, 'Input must be a bounded local ZIP regular file');
  const files = validateArchive(fs.readFileSync(absoluteArchive));
  assertNoSymlinkComponents(absoluteTarget);
  if (fs.existsSync(absoluteTarget)) {
    const status = checkInstallation(absoluteTarget);
    demand(status.ready, 'Existing invalid installation preserved. Move that directory aside, then rerun installation. ' + status.failures.join('; '));
    return {...status, action: 'already-installed'};
  }
  const parent = path.dirname(absoluteTarget);
  fs.mkdirSync(parent, {recursive: true});
  const temporary = fs.mkdtempSync(path.join(parent, '.heroic-starter-tmp-'));
  try {
    for (const [name, data] of files) fs.writeFileSync(path.join(temporary, name), data, {flag: 'wx', mode: 0o644});
    fs.writeFileSync(path.join(temporary, 'installation-receipt.json'), JSON.stringify({schema_version: 1, pack_id: manifest.pack_id, archive_sha256: manifest.archive.sha256, manifest_sha256: sha256(fs.readFileSync(manifestPath)), source_url: manifest.source_url, attribution: manifest.attribution, public_raw_redistribution: false}, null, 2) + '\n', {flag: 'wx'});
    demand(checkInstallation(temporary).ready, 'Temporary installation failed its own verification');
    demand(!fs.existsSync(absoluteTarget), 'Installation target appeared during verification; nothing overwritten');
    fs.renameSync(temporary, absoluteTarget);
    return {...checkInstallation(absoluteTarget), action: 'installed'};
  } finally {
    // Only this invocation's mkdtemp directory can be removed, never a target.
    if (fs.existsSync(temporary)) fs.rmSync(temporary, {recursive: true});
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = process.argv.slice(2);
    demand(args.length === 1, 'Usage: node tools/install_heroic_starter.mjs <local ZIP path> | --check');
    const result = args[0] === '--check' ? checkInstallation() : installLocalArchive(args[0]);
    console.log(JSON.stringify(result, null, 2));
    if (!result.ready) process.exitCode = 2;
  } catch (error) {
    console.error('Heroic 素材安装失败 / installation failed: ' + error.message);
    console.error('请从作者页面合法下载 Starter ZIP，再运行 node tools/install_heroic_starter.mjs "/path/to/HAS Starter Pack.zip"。不会下载、执行包内代码或回退到 3D。');
    process.exitCode = 2;
  }
}
