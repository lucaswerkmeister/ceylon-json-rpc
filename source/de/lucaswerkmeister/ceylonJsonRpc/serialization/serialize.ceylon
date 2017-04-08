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

"Serialize a [[value|val]] of the given [[type]] into a JSON [[Value|JsonValue]]."
shared JsonValue serialize<ValueType>(ValueType val, Type<ValueType> type) {
    if (type in jsonPrimitiveTypes) {
        assert (is JsonValue val);
        if (is Float val, !val.finite) {
            throw UnserializableValueException();
        }
        return val;
    }
    if (is Interface<Anything> type,
        type.declaration in { `interface Sequential`, `interface Sequence` }) {
        assert (is Anything[] val);
        assert (exists elementType = type.typeArgumentList[0]);
        JsonValue serializeElement(Anything element) {
            assert (is JsonValue serializedElement = `function serialize`.invoke {
                    typeArguments = [elementType];
                    arguments = [element, elementType];
                });
            return serializedElement;
        }
        return JsonArray(val.map(serializeElement));
    }
    if (is Class<Anything,Nothing>|Interface<Anything> type) {
        if (!type.typeArguments.empty) {
            throw UnserializableTypeException();
        }
        return JsonObject {
            for (attribute in type.getAttributes<>())
                if (!`Object`.getAttribute<>(attribute.declaration.name) exists)
                    attribute.declaration.name -> serialize(attribute.bind(val).get(), attribute.type)
        };
    }
    if (is UnionType<Anything> type) {
        for (caseType in type.caseTypes) {
            try {
                assert (is JsonValue serialized = `function serialize`.invoke {
                        typeArguments = [caseType];
                        arguments = [val, caseType];
                    });
                return serialized;
            } catch (Throwable t) {
                continue;
            }
        } else {
            throw AssertionError("Unable to serialize value with any case type");
        }
    }
    throw UnserializableTypeException();
}
