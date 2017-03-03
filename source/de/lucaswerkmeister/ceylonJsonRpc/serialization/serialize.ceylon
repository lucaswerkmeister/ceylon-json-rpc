import ceylon.language.meta.model {
    Interface,
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
    if (is Interface<Anything> type,
        type.declaration in { `interface Sequential`, `interface Sequence` }) {
        assert (is Anything[] val);
        assert (exists elementType = type.typeArgumentList[0]);
        Value serializeElement(Anything element) {
            assert (is Value serializedElement = `function serialize`.invoke {
                    typeArguments = [elementType];
                    arguments = [element, elementType];
                });
            return serializedElement;
        }
        return JsonArray(val.map(serializeElement));
    }
    assert (false);
}
