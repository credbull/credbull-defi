import { load } from "js-toml";

export function parse(sample: string) {
    return load(sample);
}
