import ceylon.language.meta.model {
    Class,
    Interface,
    Type,
    UnionType
}
import ceylon.json {
    JsonArray,
    JsonObject,
    JsonValue=Value
}

"Deserialize a [[JSON value|val]] into a value of the given [[type]]."
shared ValueType deserialize<ValueType>(JsonValue val, Type<ValueType> type) {
    if (type in { `String`, `Integer`, `Float`, `Boolean`, `Null` }) {
        assert (is ValueType val);
        return val;
    }
    throw AssertionError("Type cannot be deserialized from JSON: ``type``");
}
