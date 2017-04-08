"Exception thrown by [[serialize]] to indicate that the type cannot be serialized to JSON."
shared sealed class UnserializableTypeException() extends Exception("Type cannot be serialized", null) {}
"Exception thrown by [[deserialize]] to indicate that the type cannot be deserialized from JSON."
shared sealed class UndeserializableTypeException() extends Exception("Type cannot be deserialized", null) {}

"Exception thrown by [[serialize]] to indicate that the Ceylon value cannot be serialized to JSON."
shared sealed class UnserializableValueException() extends Exception("Value cannot be serialized", null) {}
"Exception thrown by [[deserialize]] to indicate that the JSON value cannot be deserialized to Ceylon."
shared sealed class UndeserializableValueException() extends Exception("Value cannot be deserialized", null) {}
