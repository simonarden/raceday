// Encrypts the bundled app with AES-256-GCM, key = PBKDF2-SHA256(RACEDAY_PASSCODE, salt, ITER).
// Output: vault.bin = salt(16) | iv(12) | ciphertext+tag. The passcode is read from the environment only.
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { webcrypto as C, randomBytes } from "node:crypto";
const [, , inFile, outFile, saltFile, iterStr] = process.argv;
const code = process.env.RACEDAY_PASSCODE || "";
if (!/^\d{4}$/.test(code)) { console.error("RACEDAY_PASSCODE missing or not 4 digits"); process.exit(4); }
const ITER = Number(iterStr);
let salt;
if (existsSync(saltFile)) salt = Buffer.from(readFileSync(saltFile, "utf8").trim(), "hex");
else { salt = randomBytes(16); writeFileSync(saltFile, salt.toString("hex") + "\n"); }
const base = await C.subtle.importKey("raw", new TextEncoder().encode(code), "PBKDF2", false, ["deriveKey"]);
const key = await C.subtle.deriveKey({ name: "PBKDF2", hash: "SHA-256", salt, iterations: ITER }, base, { name: "AES-GCM", length: 256 }, false, ["encrypt"]);
const iv = randomBytes(12);
const ct = new Uint8Array(await C.subtle.encrypt({ name: "AES-GCM", iv }, key, readFileSync(inFile)));
writeFileSync(outFile, Buffer.concat([salt, iv, Buffer.from(ct)]));
console.log(`encrypted -> ${outFile} (${Math.round((28 + ct.length) / 1024)} KB, PBKDF2-SHA256 x${ITER})`);
