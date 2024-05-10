import { decode } from 'toml-nodejs';

export function parse(sample: string) {
    return decode(sample);
}
