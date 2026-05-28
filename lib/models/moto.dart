class Moto {
  final int? id;
  final String marca;
  final String modelo;
  final int cilindrada;
  final String? imagenUrl;
  final String? createdAt;
  final String? updatedAt;

  Moto({
    this.id,
    required this.marca,
    required this.modelo,
    required this.cilindrada,
    this.imagenUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Moto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return Moto(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? ''),
      marca: json['marca'] as String? ?? '',
      modelo: json['modelo'] as String? ?? '',
      cilindrada: json['cilindrada'] as int? ?? 0,
      imagenUrl: (json['imagen_url'] ?? json['imagenUrl']) as String?,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'marca': marca,
      'modelo': modelo,
      'cilindrada': cilindrada,
      'imagen_url': imagenUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() => 'Moto($marca $modelo - $cilindrada cc)';
}
