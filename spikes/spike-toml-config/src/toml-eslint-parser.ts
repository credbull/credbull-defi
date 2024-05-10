import type { AST } from "toml-eslint-parser";
import { parseTOML, getStaticTOMLValue } from "toml-eslint-parser";
import fs from 'fs';
import { verify } from "./verifier"; 

const sample = fs.readFileSync('resource/sample.toml', 'utf8');
const ast: AST.TOMLProgram = parseTOML(sample);
const toml = getStaticTOMLValue(ast);
verify('toml-eslint-parser', toml)
