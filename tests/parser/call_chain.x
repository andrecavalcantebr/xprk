// Positive fixture: call chains nest left, so a curried two-input operation
// (spec 5.3) parses as two arity-1 applications. Golden is pending: it is
// blessed with --update once --parse-dump exists.
{
    pow = fn(base){ fn(exponent){ exp(exponent * log(base)); }; };
    pow(2)(3);
}
