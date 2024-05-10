import { strict as assert } from 'assert';

// Verifies that the `toml` object matches the data in the `sample.toml` file.
export function verify(label: string, toml: any) {
    assert(toml?.title, "Title missing")
    assert("TOML Example" === toml.title, "Title incorrect")

    assert(toml?.owner, "Owner missing")
    assert(toml.owner?.name, "Owner Name missing")
    assert("Tom Preston-Werner" === toml.owner.name, "Owner Name incorrect")
    assert(toml.owner?.dob, "Owner DOB missing")
    const dob = new Date("1979-05-27T07:32:00-08:00")
    // HACK: Compare dates on the UTC millisecond value. 
    // TODO JL,2024-05-10): How to do proper date value comparison? 
    assert(dob.valueOf() === Number(toml.owner.dob.valueOf()), "Owner DOB incorrect")
    console.log("Verified: " + label)
}
