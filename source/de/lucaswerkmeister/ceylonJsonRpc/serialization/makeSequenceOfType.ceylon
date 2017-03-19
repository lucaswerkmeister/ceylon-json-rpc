import ceylon.language.meta.model {
    Type
}

"Turn the given sequence of [[values]] into a [[Sequential]] of the given [[element type|elementType]] (with the correct reified type argument)."
shared Anything[] makeSequenceOfType(Anything[] values, Type<> elementType) {
    if (nonempty values) {
        assert (is Array<out Anything> array = `new Array.ofSize`.invoke {
                typeArguments = [elementType];
                arguments = [values.size, values.first];
            });
        for (index->element in values.indexed.rest) {
            `function Array.set`.memberInvoke {
                container = array;
                typeArguments = [];
                arguments = [index, element];
            };
        }
        return array.sequence();
    } else {
        return [];
    }
}
