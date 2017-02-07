import ceylon.language.meta.model {
    Type
}
import ceylon.json {
    JsonArray,
    JsonObject,
    Value
}

"Serialize a [[value|val]] of the given [[type]] into a JSON [[Value]]."
shared Value serialize<ValueType>(ValueType val, Type<ValueType> type) {
    if (type in { `String`, `Integer`, `Float`, `Boolean`, `Null` }) {
        assert (is Value val);
        return val;
    }
    assert (false);
}
