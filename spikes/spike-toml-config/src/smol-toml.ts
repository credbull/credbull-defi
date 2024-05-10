import { parse } from 'smol-toml'
import fs from 'fs';
import { verify } from "./verifier"; 

const sample = fs.readFileSync('resource/sample.toml', 'utf8');
const toml = parse(sample)
verify('smol-toml', toml)
