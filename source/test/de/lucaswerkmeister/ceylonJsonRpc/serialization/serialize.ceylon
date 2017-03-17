import ceylon.language.meta.model {
    Type
}
import ceylon.json {
    JsonArray,
    JsonObject,
    StringEmitter,
    JsonValue=Value,
    parse,
    visit
}
import ceylon.random {
    DefaultRandom,
    Random
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

Random random = DefaultRandom(0); // deterministic seed for deterministic tests

"A single test case: Ceylon value, type, and serialized JSON value."
shared alias Test => [Anything, Type<Anything>, JsonValue];

"Create a test where the serialized JSON value is identical to the Ceylon value."
Test createIdentityTest(JsonValue val, Type<JsonValue> type)
        => [val, type, val];

"Turn the given sequence of [[values]] into a [[Sequential]] of the given [[element type|elementType]] (with the correct reified type argument)."
Anything[] makeSequence(Anything[] values, Type<Anything> elementType) {
    if (nonempty values) {
        assert (is Array<out Anything> array = `new Array.ofSize`.invoke([elementType], values.size, values.first));
        for (index->element in values.indexed.rest) {
            `function Array.set`.memberInvoke(array, [], index, element);
        }
        return array.sequence();
    } else {
        return [];
    }
}

"Compose zero or more tests into a test for a [[Sequential]] of those tests."
Test composeSequentialTest(Test* elementTests) {
    value elementType = elementTests*.rest*.first.reduce(uncurry<Type<Anything>,Type<Anything>,Type<Anything>,[Type<Anything>]>(Type.union<Anything>)) else `Anything[]`;
    return [makeSequence(elementTests*.first, elementType), `interface Sequential`.interfaceApply<Anything>(elementType), JsonArray { for (elementTest in elementTests) elementTest[2] }];
}

"Compose one or more tests into a test for a [[Sequence]] of those tests."
Test composeSequenceTest(Test+ elementTests) {
    value elementType = elementTests*.rest*.first.reduce(uncurry<Type<Anything>,Type<Anything>,Type<Anything>,[Type<Anything>]>(Type.union<Anything>));
    return [makeSequence(elementTests*.first, elementType), `interface Sequence`.interfaceApply<Anything>(elementType), JsonArray { for (elementTest in elementTests) elementTest[2] }];
}

"Compose one or more tests into a test for a union of those tests, with a randomly chosen test as the actual value."
Test composeUnionTest(Test+ caseTests)
        => let (actualTest = random.nextElement(caseTests))
            [actualTest[0], caseTests*.rest*.first.reduce(uncurry<Type<Anything>,Type<Anything>,Type<Anything>,[Type<Anything>]>(Type.union<Anything>)), actualTest[2]];

shared interface Named {
    shared formal String name;
}
shared interface Resident {
    aliased ("address")
    shared formal String? residence;
}
shared class Person(name, residence) satisfies Named & Resident {
    shared actual String name;
    shared actual String? residence;
    string => if (exists residence) then "``name``, of ``residence``" else name;
}
shared class Company(name, head, residence) satisfies Named & Resident {
    shared actual String name;
    shared Person head;
    shared actual String residence;
    string => "``name``, of ``residence``; head of company: ``head``";
}

Test createPersonTest(String name, String residence)
        => [Person(name, residence), `Person`, JsonObject { "name"->name, "residence"->residence }];
Test composeCompanyTest(String name, Test head, String residence) {
    assert (is Person headPerson = head[0]);
    return [Company(name, headPerson, residence), `Company`, JsonObject { "name"->name, "head" -> head[2], "residence"->residence }];
}

"Compose a test into a test with the same value but a supertype of the original test’s type,
 which only contains a subset of the original test’s attributes."
Test composeSupertypeTest(Test test, Type<Anything> supertype, String* attributes) {
    assert (supertype.supertypeOf(test[1]));
    assert (is JsonObject json = test[2],
        attributes.every(json.defines));
    return [test[0], supertype, JsonObject(zipEntries(attributes, attributes.map(json.get)))];
}

Test composeNamedTest(Test test)
        => composeSupertypeTest(test, `Named`, "name");
Test composeResidentTest(Test test)
        => composeSupertypeTest(test, `Resident`, "residence");

shared object tests {
    
    shared Test primitiveString = createIdentityTest("", `String`);
    shared Test primitiveInteger = createIdentityTest(0, `Integer`);
    shared Test primitiveFloat = createIdentityTest(0.0, `Float`);
    shared Test primitiveBoolean = createIdentityTest(true, `Boolean`);
    shared Test primitiveNull = createIdentityTest(null, `Null`);
    shared Test[] primitiveTests = [primitiveString, primitiveInteger, primitiveFloat, primitiveBoolean, primitiveNull];
    
    shared Test cornerCaseNullString = createIdentityTest("\{#0000}", `String`);
    shared Test cornerCaseNonBMPString = createIdentityTest("\{ELEPHANT}", `String`);
    shared Test cornerCaseMaxInteger = createIdentityTest(runtime.maxIntegerValue, `Integer`);
    shared Test cornerCaseMinInteger = createIdentityTest(runtime.minIntegerValue, `Integer`);
    shared Test cornerCaseMaxFloat = createIdentityTest(runtime.maxFloatValue, `Float`);
    shared Test cornerCaseMinFloat = createIdentityTest(runtime.minFloatValue, `Float`);
    shared Test[] cornerCaseTests = [cornerCaseNullString, cornerCaseNonBMPString, cornerCaseMaxInteger, cornerCaseMinInteger, cornerCaseMaxFloat, cornerCaseMinFloat];
    
    shared Test arrayOfPrimitiveString = composeSequenceTest(primitiveString, cornerCaseNullString, cornerCaseNonBMPString);
    shared Test arrayOfPrimitiveBoolean = composeSequentialTest(primitiveBoolean);
    shared Test emptyArray = composeSequentialTest();
    shared Test[] primitiveArrayTests = [arrayOfPrimitiveString, arrayOfPrimitiveBoolean, emptyArray];
    
    shared Test arrayOfArrayOfPrimitive = composeSequenceTest(arrayOfPrimitiveString);
    
    shared Test unionOfTwoPrimitives = composeUnionTest(primitiveString, primitiveInteger);
    shared Test unionOfAllPrimitives = composeUnionTest(primitiveString, primitiveInteger, primitiveFloat, primitiveBoolean, primitiveNull);
    shared Test[] primitiveUnionTests = [unionOfTwoPrimitives, unionOfAllPrimitives];
    
    shared Test classPersonBilbo = createPersonTest("Bilbo Baggins", "Bag End, Underhill, The Shire");
    shared Test classPersonHarry = createPersonTest("Harry James Potter", "Cupboard under the Stairs, Number 4, Privet Drive, Little Whinging, Surrey");
    shared Test[] classPersonTests = [classPersonBilbo, classPersonHarry];
    
    shared Test classCompanyRedBooks = composeCompanyTest("Red Book Publishing House", classPersonBilbo, "Imladris (Rivendell)");
    shared Test classCompanyDA = composeCompanyTest("Dumbledore’s Army", classPersonHarry, "The Room of Requirements, Hogwarts, Great Britain");
    shared Test[] classCompanyTests = [classCompanyRedBooks, classCompanyDA];
    
    shared Test interfaceNamedBilbo = composeNamedTest(classPersonBilbo);
    shared Test interfaceResidentDA = composeResidentTest(classCompanyDA);
    shared Test[] interfaceTests = [interfaceNamedBilbo, interfaceResidentDA];
    
    shared Test[] allTests = concatenate(
        primitiveTests,
        cornerCaseTests,
        primitiveArrayTests,
        [arrayOfArrayOfPrimitive],
        primitiveUnionTests,
        classPersonTests,
        classCompanyTests,
        interfaceTests
    );
}

// work around ceylon/ceylon-sdk#635 – parameters (`value tests.allTests`) isn’t supported
shared Test[] allTests => tests.allTests;
shared Test[] primitiveTests => tests.primitiveTests;

test
parameters (`value allTests`)
shared void testSerialize(Anything val, Type<Anything> type, JsonValue expected) {
    assertEquals {
        expected = expected;
        actual = serialize(val, type);
    };
}

test
parameters (`value primitiveTests`)
shared void testSerializeViaString(Anything val, Type<Anything> type, Anything expected) {
    assumeTrue(!Float.parse(1.0e21.string) is Exception); // ceylon/ceylon#6908
    assertEquals {
        expected = expected;
        value actual {
            value serialized = serialize(val, type);
            value emitter = StringEmitter();
            visit(serialized, emitter);
            value parsed = parse(emitter.string);
            return parsed;
        }
    };
}
