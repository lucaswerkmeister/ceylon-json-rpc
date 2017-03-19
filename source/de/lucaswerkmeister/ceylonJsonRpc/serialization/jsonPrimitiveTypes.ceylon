import ceylon.language.meta.model {
    Type
}

"The JSON primitive types:
 [[String]], [[Integer]], [[Float]], [[Boolean]], [[Null]].

 Even though these types are technically class types,
 unions of several of them may be [[deserialized|deserialize]];
 the restriction that a union may involve at most one class
 does not consider them classes."
shared Set<Type<>> jsonPrimitiveTypes = set { `String`, `Integer`, `Float`, `Boolean`, `Null` };
