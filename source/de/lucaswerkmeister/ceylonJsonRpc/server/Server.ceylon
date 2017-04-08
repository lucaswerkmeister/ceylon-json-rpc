import ceylon.language.meta.declaration {
    FunctionDeclaration,
    Module,
    OpenClassOrInterfaceType,
    OpenIntersection,
    OpenType,
    OpenTypeVariable,
    OpenUnion,
    Package,
    nothingType,
    FunctionOrValueDeclaration
}
import ceylon.language.meta.model {
    Type,
    IncompatibleTypeException,
    InvocationException
}
import ceylon.json {
    JsonArray,
    JsonObject,
    JsonValue=Value,
    parse
}
import de.lucaswerkmeister.ceylonJsonRpc.serialization {
    ...
}

class UnclosableTypeException() extends Exception("Open type cannot be closed") {}
class NoSuchParameterException() extends Exception("No such parameter") {}

"A JSON-RPC server for methods of the specified [[container]].
 Send the requests to [[process]] and serialize the returned response."
shared class Server(container) {

    "The container in which the server will look for called methods.
     If the container is a package,
     the server will search for methods in all its packages."
    shared Module|Package container;
    
    FunctionDeclaration? findFunction(String name) {
        switch (container)
        case (is Module) {
            for (pkg in container.members) {
                // TODO container.members.filter(Package.shared) once ceylon/ceylon#7015 and ceylon/ceylon#7016 are fixed
                if (exists fun = pkg.getFunction(name)) {
                    return fun;
                }
            } else {
                return null;
            }
        }
        case (is Package) {
            return container.getFunction(name);
        }
    }
    
    Type<> closeType(OpenType type) {
        switch (type)
        case (is OpenClassOrInterfaceType) {
            return type.declaration.apply<>(*type.typeArgumentList.map(closeType));
        }
        case (is OpenUnion) {
            return type.caseTypes.map(closeType).fold(`Nothing` of Type<Anything>)((t, u) => t.union(u));
        }
        case (is OpenIntersection|OpenTypeVariable) {
            throw UnclosableTypeException();
        }
        case (nothingType) {
            return `Nothing`;
        }
    }
    
    FunctionOrValueDeclaration parameterDeclaration(FunctionDeclaration fun, String name) {
        if (exists parameter = fun.getParameterDeclaration(name)) {
            return parameter;
        } else {
            throw NoSuchParameterException();
        }
    }
    
    class InvocationError(shared JsonObject? errorObject) {}
    
    "Call [[invocation]] – which should be the actual JSON-RPC method invocation –
     while handling errors appropriately.
     Returns the return value of [[invocation]] or an [[InvocationError]] object."
    Anything invokeWithErrorHandling(Anything invocation(), String|Integer|Float|Null id, Boolean notification) {
        try {
            return invocation();
        } catch (UndeserializableTypeException e) {
            return InvocationError(errorResponse(invalidMethod, id, notification));
        } catch (UndeserializableValueException e) {
            return InvocationError(errorResponse(invalidParams, id, notification));
        } catch (IncompatibleTypeException e) {
            // this should never happen, should result in an UndeserializableValueException
            // TODO log
            return InvocationError(errorResponse(internalError, id, notification));
        } catch (InvocationException e) {
            // missing or extraneous arguments
            return InvocationError(errorResponse(invalidParams, id, notification));
        } catch (NoSuchParameterException e) {
            // this should never happen, something went wrong zipping params and args
            // TODO log
            return InvocationError(errorResponse(internalError, id, notification));
        } catch (UnclosableTypeException e) {
            return InvocationError(errorResponse(invalidMethod, id, notification));
        } catch (ApplicationErrorException e) {
            return InvocationError(errorResponse(e.error, id, notification));
        } catch (Exception e) {
            return InvocationError(errorResponse(UnknownError(e), id, notification));
        }
    }

    "Process a JSON-RPC request,
     which may be a single Request object
     or a Batch array of requests.
     Returns the appropriate response;
     [[null]] means that no response should be sent at all (notifications)."
    shared JsonObject|JsonArray? process(String request) {
        JsonValue requestValue;
        try {
            requestValue = parse(request);
        } catch (Exception e) {
            return errorResponse {
                parseError;
                id = null; // can’t determine ID
                notification = false;
            };
        }
        switch (requestValue)
        case (is JsonObject) {
            value id = requestValue["id"];
            if (!is String|Integer|Float|Null id) {
                return errorResponse {
                    invalidRequest;
                    id = null; // invalid ID
                    notification = false;
                };
            }
            if ((requestValue["jsonrpc"] else "none") != "2.0") {
                return errorResponse(invalidRequest, id, false);
            }
            value methodName = requestValue["method"];
            if (!is String methodName) {
                return errorResponse(invalidRequest, id, false);
            }
            // From here on, requestValue is a valid Request object;
            // if the Request is a notification, we should never return a Response, even for errors.
            Boolean notification = !requestValue.defines("id");
            value method = findFunction(methodName);
            if (!exists method) {
                return errorResponse(methodNotFound, id, notification);
            }
            Anything result;
            switch (args = requestValue["params"])
            case (is JsonArray) {
                // by-position
                value invocationResult = invokeWithErrorHandling {
                    () => method.invoke {
                            typeArguments = [];
                            arguments = [
                                for (param->arg in zipEntries(method.parameterDeclarations, args))
                                    deserialize(arg, closeType(param.openType))
                            ];
                        };
                    id;
                    notification;
                };
                if (is InvocationError invocationResult) {
                    return invocationResult.errorObject;
                } else {
                    result = invocationResult;
                }
            }
            case (is JsonObject) {
                // by-name
                value invocationResult = invokeWithErrorHandling {
                    () => method.apply<>().namedApply {
                            for (name in args.keys)
                                let (parameter = parameterDeclaration(method, name))
                                    name -> deserialize(args[name], closeType(parameter.openType))
                        };
                    id;
                    notification;
                };
                if (is InvocationError invocationResult) {
                    return invocationResult.errorObject;
                } else {
                    result = invocationResult;
                }
            }
            case (null) {
                if (requestValue.defines("params")) {
                    // explicit null params are not allowed
                    return errorResponse(invalidRequest, id, notification);
                } else {
                    value invocationResult = invokeWithErrorHandling {
                        () => method.invoke {
                                typeArguments = [];
                                arguments = [];
                            };
                        id;
                        notification;
                    };
                    if (is InvocationError invocationResult) {
                        return invocationResult.errorObject;
                    } else {
                        result = invocationResult;
                    }
                }
            }
            else {
                return errorResponse(invalidParams, id, notification);
            }
            if (!notification) {
                try {
                    value serializedResult = serialize(result, closeType(method.openType));
                    return JsonObject {
                        "jsonrpc"->"2.0",
                        "result"->serializedResult,
                        "id"->id
                    };
                } catch (UnserializableTypeException|UnserializableValueException e) {
                    // TODO the method was already called, it’s a bit late to return an error… what if it had side effects?
                    return errorResponse(invalidMethod, id, notification);
                }
            } else {
                // notifications have no response
                return null;
            }
        }
        case (is JsonArray) {
            if (requestValue.empty) {
                return errorResponse {
                    invalidRequest;
                    id = null; // can’t determine ID
                    notification = false;
                };
            }
            if (nonempty response = requestValue.map((v) => process(v?.string else "null")).coalesced.sequence()) {
                return JsonArray(response);
            } else {
                /**
                 * If there are no Response objects contained within the Response array
                 * as it is to be sent to the client,
                 * the server MUST NOT return an empty Array
                 * and should return nothing at all.
                 */
                return null;
            }
        }
        else {
            return errorResponse {
                invalidRequest;
                id = null; // can’t determine ID
                notification = false;
            };
        }
    }
}
