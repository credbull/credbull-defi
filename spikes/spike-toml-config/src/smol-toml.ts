import { parse as smol_parse } from 'smol-toml'

export function parse(sample: string) {
    return smol_parse(sample);
}
