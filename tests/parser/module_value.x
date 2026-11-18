// Fixture: modules are values (spec 4.3). Positive case, golden pending — it is
// blessed with --update once --parse-dump exists.
std = import("mathx.x");
std.range(2);
use_mod(import("mathx.x"));
f = fn(m){ m.step(1); };
f(std);
