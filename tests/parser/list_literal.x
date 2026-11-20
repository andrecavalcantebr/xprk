// Positive fixture: a list literal is an atom (spec 3, list_literal). Elements
// evaluate left to right; homogeneity rides the Integer -> Real promotion, and
// [] stays [?] until a concrete [T] is assigned (spec 4.2). Golden is pending:
// it is blessed with --update once --parse-dump exists.
{
    e = [];
    e = [1, 2.0, 3];
    m = [[1, 2], [3, 4]];
    e[0] + m[0][1];
}
