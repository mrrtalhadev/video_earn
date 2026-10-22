/// Shared status for subscription orders, withdraw requests and promote orders.
enum OrderStatus {
  pending,
  approved,
  rejected;

  static OrderStatus parse(Object? value) =>
      OrderStatus.values.firstWhere((s) => s.name == value, orElse: () => OrderStatus.pending);
}
