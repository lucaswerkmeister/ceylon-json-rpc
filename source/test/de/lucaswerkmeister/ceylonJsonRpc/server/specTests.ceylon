import ceylon.language.meta.model { Type }
import ceylon.json { ... }
import ceylon.test { ... }
import de.lucaswerkmeister.ceylonJsonRpc.server { Server }

test
parameters (`value specExamples`)
shared void testSpecExample(String request, String? expectedResponse) {
    assumeTrue(canApplyEmptyList());
    value server = Server(`module`);
    value actualResponse = server.process(request);
    if (exists expectedResponse) {
        assertEquals {
            expected = parse(expectedResponse);
            actual = actualResponse;
        };
    } else {
        assertNull(actualResponse);
    }
}

"See [ceylon/ceylon#7017](https://github.com/ceylon/ceylon/issues/7017)."
Boolean canApplyEmptyList() {
    try {
        `class Null`.apply<>(*([] of [Type<>=]));
        return true;
    } catch (Throwable t) {
        return false;
    }
}
