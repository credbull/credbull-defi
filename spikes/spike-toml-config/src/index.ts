import { parse as jstParse } from './js-toml'
import { parse as jtParse } from './j-toml'
import { parse as stParse }  from './smol-toml'
import { parse as tepParse }  from './toml-eslint-parser'
import { parse as tnParse } from './toml-nodejs'
import fs from 'fs';
import { verify } from "./verifier"; 

function loadSample() {
    return fs.readFileSync('resource/sample.toml', 'utf8');
}

const sample = loadSample()

verify('js-toml', jstParse(sample))
verify('j-toml', jtParse(sample))

// FIXM (JL,2024-05-10): 'ERR_REQUIRE_ESM' module load errors. Need an explanation!
// verify('smol-toml', stParse(sample))

verify('toml-eslint-parser', tepParse(sample))

// FIXM (JL,2024-05-10): 'ERR_REQUIRE_ESM' module load errors. Need an explanation!
// verify('toml-nodejs', tnParse(sample))
