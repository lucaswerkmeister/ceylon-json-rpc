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
    if (is UnionType<Anything> type) {
        "Union type to deserialize must involve at most one class"
        assert (type.caseTypes.narrow<Class<>>().shorterThan(2));
        for (caseType in type.caseTypes) {
            try {
                assert (is ValueType deserialized = `function deserialize`.invoke {
                        typeArguments = [caseType];
                        arguments = [val, caseType];
                    });
                return deserialized;
            } catch (Throwable t) {
                continue;
            }
        } else {
            throw AssertionError("Unable to serialize value with any case type");
        }
    }
    throw AssertionError("Type cannot be deserialized from JSON: ``type``");
}
