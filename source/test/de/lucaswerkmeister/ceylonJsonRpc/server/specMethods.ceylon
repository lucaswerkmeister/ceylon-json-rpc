shared Integer subtract(Integer minuend, Integer subtrahend) => minuend - subtrahend;
shared void update(Integer i1, Integer i2, Integer i3, Integer i4, Integer i5) {}
shared Integer sum(Integer i1, Integer i2, Integer i3) => Integer.sum { i1, i2, i3 };
shared void notify_hello(Integer param) {}
shared <String|Integer>[] get_data() => ["hello", 5];
shared void notify_sum(Integer i1, Integer i2, Integer i3) {}
// TODO make update, sum, notify_sum variadic once Server supports variadic methods
