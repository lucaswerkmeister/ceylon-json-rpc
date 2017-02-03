"This module implements [JSON-RPC] for Ceylon
 (specifically, [JSON-RPC 2.0]).
 
 For a toplevel function to be eligible for JSON-RPC,
 it must have no type parameters and
 all of its required parameters must have types
 that can be deserialized from JSON,
 and it must have a return type
 that can be serialized to JSON.
 
 The following types can be deserialized from JSON:
 
 - JSON primitive types:
   [[String]], [[Integer]], [[Float]], [[Boolean]], [[Null]];
 - [[Sequential]] or [[Sequence]] of a type
   that can be deserialized from JSON
   (but not subtypes like [[Tuple]] or [[Range]]);
 - toplevel non-abstract classes without type parameters
   where every parameter of the `ofJSON` constructor
   or, if that does not exist, of the default constructor or initializer
   has a type that can be deserialized from JSON; and
 - unions of types that can be deserialized from JSON
   involving at most one class.
 
 These rules ensure that the choice of class to be instantiated
 is always unambiguous.
 Should the need arise,
 a future version of this module may relax these restrictions
 provided that the choice of class is disambiguated in some other fashion.
 
 The following types can be serialized to JSON:
 
 - JSON primitive types, as above;
 - [[Sequential]] and [[Sequence]], as above;
 - toplevel classes, interfaces or objects without type parameters
   where every shared value has a type that can be serialized to JSON; and
 - unions of types that can be serialized to JSON.
 
 The rules for serialization are less strict than those for deserialization,
 since there is no need to instantiate a particular class here.
 You can use an `ofJSON` constructor to bridge the gap:
 
 ~~~
 shared interface Foo { shared formal String s; }
 shared class FooImpl(shared actual String s) satisfies Foo {}
 
 shared class Bar {
     
     shared Foo foo;
     
     shared new (Foo foo) {
         this.foo = foo;
     }
     
     shared new ofJSON(FooImpl foo) extends Bar(foo) {}
 }
 ~~~
 
 Here, the type of `Bar.foo` is the more general interface type `Foo`,
 while the `ofJSON` constructor specifies that JSON deserialization
 should always use the `FooImpl` class.
 
 Note that this is not a general-case serialization/deserialization module,
 and does not employ [[package ceylon.language.serialization]].
 Circular references in values to be serialized are not supported.
 (No attempt is made to detect circular references –
 they result in a stack overflow.)
 
 [JSON-RPC]: http://www.jsonrpc.org/
 [JSON-RPC 2.0]: http://www.jsonrpc.org/specification"
module de.lucaswerkmeister.ceylonJsonRpc "1.0.0-SNAPSHOT" {
    shared import ceylon.json "1.3.1";
}
