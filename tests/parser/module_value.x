// Fixture: every file is a unit and a unit is a block (spec 3); modules are
// values (spec 4.8). Positive case, golden pending — it is blessed with
// --update once --parse-dump exists.
{
    std = import("mathx.x");
    std.range(2);
    use_mod(import("mathx.x"));
    f = fn(m){ m.step(1); };
    f(std);
}
