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
        if (is ValueType val) {
            return val;
        } else {
            throw UndeserializableValueException();
        }
    }
    if (is Interface<Anything> type,
        type.declaration in { `interface Sequential`, `interface Sequence` }) {
        if (!is JsonArray val) {
            throw UndeserializableValueException();
        }
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
        if (!type.typeArguments.empty) {
            throw UndeserializableTypeException();
        }
        if (!is JsonObject val) {
            throw UndeserializableValueException();
        }
        if (is CallableConstructor<Anything,Nothing> constructor = type.getConstructor<Nothing>("ofJSON") else type.defaultConstructor) {
            assert (is ValueType deserialized = constructor.namedApply {
                    for (paramName->paramType in zipEntries(constructor.declaration.parameterDeclarations*.name, constructor.parameterTypes))
                        paramName -> deserialize(val[paramName], paramType)
                });
            return deserialized;
        } else {
            throw UndeserializableTypeException();
        }
    }
    if (is UnionType<Anything> type) {
        if (type.caseTypes.narrow<Class<>>().filter(not(jsonPrimitiveTypes.contains)).longerThan(1)) {
            throw UndeserializableTypeException();
        }
        for (caseType in type.caseTypes) {
            try {
                assert (is ValueType deserialized = `function deserialize`.invoke {
                        typeArguments = [caseType];
                        arguments = [val, caseType];
                    });
                return deserialized;
            } catch (UndeserializableTypeException e) {
                throw e;
            } catch (UndeserializableValueException e) {
                continue;
            }
        } else {
            throw UndeserializableValueException();
        }
    }
    throw UndeserializableTypeException();
}
