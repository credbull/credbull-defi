import { decode } from 'toml-nodejs';
import fs from 'fs';
import { verify } from "./verifier"; 

const sample = fs.readFileSync('resource/sample.toml', 'utf8'); 
const toml = decode(sample);
verify('toml-nodejs', toml)
