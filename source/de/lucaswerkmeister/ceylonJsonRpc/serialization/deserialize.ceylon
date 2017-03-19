import ceylon.language.meta.model {
    CallableConstructor,
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
    if (type in jsonPrimitiveTypes) {
        assert (is ValueType val);
        return val;
    }
    if (is Interface<Anything> type,
        type.declaration in { `interface Sequential`, `interface Sequence` }) {
        assert (is JsonArray val);
        assert (exists elementType = type.typeArgumentList[0]);
        Anything deserializeElement(JsonValue element) {
            return `function deserialize`.invoke {
                typeArguments = [elementType];
                arguments = [element, elementType];
            };
        }
        Anything[] deserialized = val.collect(deserializeElement);
        assert (is ValueType deserializedOfType = makeSequenceOfType(deserialized, elementType));
        return deserializedOfType;
    }
    if (is Class<Anything,Nothing> type) {
        assert (type.typeArguments.empty);
        assert (is JsonObject val);
        assert (is CallableConstructor<Anything,Nothing> constructor = type.getConstructor<Nothing>("ofJSON") else type.defaultConstructor);
        assert (is ValueType deserialized = constructor.namedApply {
                for (paramName->paramType in zipEntries(constructor.declaration.parameterDeclarations*.name, constructor.parameterTypes))
                    paramName -> deserialize(val[paramName], paramType)
            });
        return deserialized;
    }
    if (is UnionType<Anything> type) {
        "Union type to deserialize must involve at most one class"
        assert (type.caseTypes.narrow<Class<>>().filter(not(jsonPrimitiveTypes.contains)).shorterThan(2));
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
