import ceylon.language.meta.model {
    Type
}
import ceylon.json {
    JsonArray,
    JsonObject,
    StringEmitter,
    Value,
    parse,
    visit
}
import ceylon.test {
    assertEquals,
    assumeTrue,
    parameters,
    test
}
import de.lucaswerkmeister.ceylonJsonRpc.serialization {
    serialize
}

shared [Anything, Type<Anything>][] primitives = [
    // basic
    ["", `String`],
    [0, `Integer`],
    [0.0, `Float`],
    [true, `Boolean`],
    [null, `Null`],
    // corner cases
    ["\{#0000}", `String`],
    ["\{ELEPHANT}", `String`],
    [runtime.maxIntegerValue, `Integer`],
    [runtime.minIntegerValue, `Integer`],
    [runtime.maxFloatValue, `Float`],
    [runtime.minFloatValue, `Float`]
    // Infinity and NaN are not valid JSON
];

test
parameters (`value primitives`)
shared void serializePrimitive(Anything val, Type<Anything> type) {
    assertEquals {
        expected = val;
        actual = serialize(val, type);
    };
}

test
parameters (`value primitives`)
shared void serializePrimitiveViaString(Anything val, Type<Anything> type) {
    assumeTrue(!Float.parse(1.0e21.string) is Exception); // ceylon/ceylon#6908
    assertEquals {
        expected = val;
        value actual {
            value serialized = serialize(val, type);
            value emitter = StringEmitter();
            visit(serialized, emitter);
            value parsed = parse(emitter.string);
            return parsed;
        }
    };
}

shared [Anything[], Type<Anything[]>, Value][] primitiveArrays = [
    [["", "Hello, World!"], `String[]`, JsonArray { "", "Hello, World!" }],
    [["\{#0000}", "\{ELEPHANT}"], `[String+]`, JsonArray { "\{#0000}", "\{ELEPHANT}" }],
    [[42, 13, 37], `Integer[]`, JsonArray { 42, 13, 37 }],
    [[4.2, 13.37], `Float[]`, JsonArray { 4.2, 13.37 }],
    [[true, false], `Boolean[]`, JsonArray { true, false }],
    [[null, null], `[Null+]`, JsonArray { null, null }],
    [[], `String[]`, JsonArray {}]    
];

test
parameters (`value primitiveArrays`)
shared void serializePrimitiveArray(Anything[] val, Type<Anything[]> type, Value expected) {
    assertEquals {
        expected = expected;
        actual = serialize(val, type);
    };
}

shared [Anything[][], Type<Anything[][]>, Value][] primitiveArrayArrays = [
    [[["", "Hello, World!"]], `String[][]`, JsonArray { JsonArray { "", "Hello, World!" } }],
    [[["\{#0000}"], ["\{ELEPHANT}"]], `[[String+]+]`, JsonArray { JsonArray { "\{#0000}" }, JsonArray { "\{ELEPHANT}" } }],
    [[], `String[][]`, JsonArray {}],
    [[[]], `String[][]`, JsonArray { JsonArray {} }]
];

test
parameters (`value primitiveArrayArrays`)
shared void serializePrimitiveArrayArray(Anything[][] val, Type<Anything[][]> type, Value expected) {
    assertEquals {
        expected = expected;
        actual = serialize(val, type);
    };
}
