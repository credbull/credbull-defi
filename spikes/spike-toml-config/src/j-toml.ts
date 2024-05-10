import TOML from '@ltd/j-toml';

export function parse(sample: string) {
    return TOML.parse(sample);
}
