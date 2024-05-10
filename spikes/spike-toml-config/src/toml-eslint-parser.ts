import { parseTOML, getStaticTOMLValue } from "toml-eslint-parser";

export function parse(sample: string) {
    return getStaticTOMLValue(parseTOML(sample));
}
