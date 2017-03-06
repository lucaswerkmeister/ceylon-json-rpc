"This library implements a [JSON-RPC 2.0] Server for Ceylon.
 It receives a Request as JSON [[ceylon.json::Value]],
 calls the appropriate function in a user-supplied module,
 then encodes the result back into a JSON Response.
 
 For a toplevel function to be eligible for JSON-RPC,
 it must have no type parameters and
 all of its required parameters must have types
 that can be deserialized from JSON,
 and it must have a return type
 that can be serialized to JSON.
 The JSON primitive types
 [[String]], [[Integer]], [[Float]], [[Boolean]], [[Null]]
 are all supported,
 as are classes composed of them.
 For details, see [[module de.lucaswerkmeister.ceylonJsonRpc.serialization]].
 
 [JSON-RPC 2.0]: http://www.jsonrpc.org/specification"
module de.lucaswerkmeister.ceylonJsonRpc.server "1.0.0-SNAPSHOT" {
    shared import ceylon.json "1.3.2";
    import de.lucaswerkmeister.ceylonJsonRpc.serialization "1.0.0-SNAPSHOT";
}
