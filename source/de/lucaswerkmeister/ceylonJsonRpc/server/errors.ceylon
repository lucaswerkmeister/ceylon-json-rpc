import ceylon.json {
    JsonArray,
    JsonObject,
    JsonValue=Value
}

"An Error object."
shared abstract class ErrorObject(code, message, data = null)
        of parseError | invalidRequest | methodNotFound | invalidParams | internalError | ServerError | ApplicationError {
    "A number that indicates the error type that occurred."
    shared Integer code;
    "A [[String]] providing a short description of the error.
      The message SHOULD be limited to a concise single sentence."
    shared String message;
    "A [[Value|JsonValue]] that contains additional information about the error.
     This may be omitted ([[null]]).
     The value of this member is defined by the Server (e.g. detailed error information, nested errors etc.)."
    shared JsonValue data;
}

"Invalid JSON was received by the server.
 An error occurred on the server while parsing the JSON text."
shared object parseError extends ErrorObject(-32700, "Parse error") {}
"The JSON sent is not a valid Request object."
shared object invalidRequest extends ErrorObject(-32600, "Invalid Request") {}
"The method does not exist / is not available."
shared object methodNotFound extends ErrorObject(-32601, "Method not found") {}
"Invalid method parameter(s)."
shared object invalidParams extends ErrorObject(-32602, "Invalid params") {}
"Internal JSON-RPC error."
shared object internalError extends ErrorObject(-32603, "Internal error") {}

"Reserved for implementation-defined server-errors."
shared sealed class ServerError(Integer code, JsonValue data = null) extends ErrorObject(code, "Server error", data) {
    assert (-32099 <= code <= -32000);
}

"The method’s parameter types, return type or return value
 cannot be deserialized from or serialized to JSON."
shared object invalidMethod extends ServerError(-32099) {}

JsonObject exceptionData(Throwable t) {
    StringBuilder sb = StringBuilder();
    printStackTrace(t, sb.append);
    return JsonObject {
        "message"->t.message,
        "stackTrace"->sb.string,
        "cause" -> (if (exists c = t.cause) then exceptionData(c) else null),
        "suppressed" -> JsonArray(t.suppressed.map(exceptionData))
    };
}

"The method threw an exception that was not an [[ApplicationErrorException]]."
shared sealed class UnknownError(Exception e) extends ServerError(-32098, exceptionData(e)) {}

shared class ApplicationError(Integer code, String message, JsonValue data = null) extends ErrorObject(code, message, data) {
    "The error codes from and including -32768 to -32000 are reserved for pre-defined errors."
    assert (!(-32768 <= code <= -32000));
}

"Methods invoked by a [[Server]] can throw this exception to return a custom [[error]] object.
 All other exceptions thrown will result in an [[UnknownError]]."
shared class ApplicationErrorException(error) extends Exception(error.message) {
    shared ApplicationError error;
}

JsonObject? errorResponse(
    "The error object."
    ErrorObject errorObject,
    "The ID of the Request object for this error Response.
     If the ID of the Request object could not be determined, specify [[null]]."
    String|Integer|Float|Null id,
    "Whether the request was a notification or not.
     Notifications get no response, even if there is an error."
    Boolean notification) {
    if (notification) {
        return null;
    } else {
        return JsonObject {
            "jsonrpc"->"2.0",
            "error"->JsonObject {
                "code"->errorObject.code,
                "message"->errorObject.message,
                if (errorObject.data exists) "data"->errorObject.data
            },
            "id"->id
        };
    }
}
