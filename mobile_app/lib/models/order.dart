class OrderModel {
  const OrderModel({
    required this.id,
    required this.code,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String code;
  final double total;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: int.tryParse('${json['order_id'] ?? json['id'] ?? 0}') ?? 0,
        code: '${json['order_code'] ?? json['code'] ?? 'ORDER'}',
        total: double.tryParse('${json['total'] ?? 0}') ?? 0,
        paymentMethod:
            '${json['payment_method'] ?? json['paymentMethod'] ?? 'cod'}',
        status: '${json['status'] ?? 'pending'}',
        createdAt:
            DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      );
}
