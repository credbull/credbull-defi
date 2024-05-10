import { load } from "js-toml";
import fs from 'fs';
import { verify } from "./verifier"; 

const sample = fs.readFileSync('resource/sample.toml', 'utf8');
const toml = load(sample);
verify('js-toml', toml)
