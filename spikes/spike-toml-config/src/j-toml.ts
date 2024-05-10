import TOML from '@ltd/j-toml';
import fs from 'fs';
import { verify } from "./verifier"; 

const sample = fs.readFileSync('resource/sample.toml', 'utf8');
const toml = TOML.parse(sample);
verify('j-toml', toml)
