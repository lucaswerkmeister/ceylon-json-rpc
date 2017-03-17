import ceylon.language.meta.model {
    Class,
    ClassOrInterface,
    Interface,
    Type,
    UnionType,
    Value
}
import ceylon.json {
    JsonArray,
    JsonObject,
    JsonValue=Value
}

"Serialize a [[value|val]] of the given [[type]] into a JSON [[Value|JsonValue]]."
shared JsonValue serialize<ValueType>(ValueType val, Type<ValueType> type) {
    if (type in { `String`, `Integer`, `Float`, `Boolean`, `Null` }) {
        assert (is JsonValue val);
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
    if (is Class<Anything,Nothing>|Interface<Anything>|Value<Anything,Nothing> type) {
        ClassOrInterface<Anything> actualType;
        switch (type)
        case (is ClassOrInterface<Anything>) {
            assert (type.typeArguments.empty);
            actualType = type;
        }
        case (is Value<Anything,Nothing>) {
            assert (exists objectClass = type.declaration.objectClass);
            actualType = objectClass.apply();
        }
        return JsonObject {
            for (attribute in actualType.getAttributes<Nothing,Anything,Nothing>())
                if (!`Object`.getAttribute<Nothing,Anything,Nothing>(attribute.declaration.name) exists)
                    attribute.declaration.name -> serialize<Anything>(attribute.bind(val).get(), attribute.type)
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
    throw AssertionError("Type cannot be serialized to JSON: ``type``");
}
