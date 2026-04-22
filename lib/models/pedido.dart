/// Estados posibles de un pedido en el flujo de trabajo.
/// El valor `key` es el que se persiste en Firestore (en español,
/// consistente con el resto del proyecto).
enum EstadoPedido {
  enCola('en_cola', 'En cola'),
  imprimiendo('imprimiendo', 'Imprimiendo'),
  terminado('terminado', 'Terminado');

  final String key;
  final String label;

  const EstadoPedido(this.key, this.label);

  static EstadoPedido fromKey(String? key) {
    return EstadoPedido.values.firstWhere(
      (e) => e.key == key,
      orElse: () => EstadoPedido.enCola,
    );
  }
}

class Pedido {
  final String? id;              // ID del documento en Firestore (null antes de guardar)
  final String folio;            // ORD-001, ORD-002, ...
  final String nombreCliente;
  final String telefonoCliente;
  final String material;         // PLA, ABS, PETG, TPU
  final String color;            // Blanco, Negro, Rojo, Azul, Verde, Amarillo
  final String? descripcion;     // Opcional
  final int cantidad;
  final double pesoGramos;       // Viene desde la cotización
  final int horasEstimadas;      // Viene desde la cotización
  final int minutosEstimados;    // Viene desde la cotización
  final double precioUnitario;   // Resultado del algoritmo de costeo (por pieza)
  final double total;            // precioUnitario * cantidad con ajustes aplicados
  final bool esEstudiante;
  final bool esUrgente;
  final DateTime fechaRegistro;
  final DateTime? fechaEntrega;  // Obligatoria si esUrgente == true
  final EstadoPedido estado;

  Pedido({
    this.id,
    required this.folio,
    required this.nombreCliente,
    required this.telefonoCliente,
    required this.material,
    required this.color,
    this.descripcion,
    required this.cantidad,
    required this.pesoGramos,
    required this.horasEstimadas,
    required this.minutosEstimados,
    required this.precioUnitario,
    required this.total,
    required this.esEstudiante,
    required this.esUrgente,
    required this.fechaRegistro,
    this.fechaEntrega,
    this.estado = EstadoPedido.enCola,
  });

  factory Pedido.fromMap(Map<String, dynamic> map, {String? id}) {
    return Pedido(
      id: id,
      folio: map['folio'] ?? '',
      nombreCliente: map['nombre_cliente'] ?? '',
      telefonoCliente: map['telefono_cliente'] ?? '',
      material: map['material'] ?? '',
      color: map['color'] ?? '',
      descripcion: map['descripcion'],
      cantidad: (map['cantidad'] ?? 1) as int,
      pesoGramos: (map['peso_gramos'] ?? 0).toDouble(),
      horasEstimadas: (map['horas_estimadas'] ?? 0) as int,
      minutosEstimados: (map['minutos_estimados'] ?? 0) as int,
      precioUnitario: (map['precio_unitario'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      esEstudiante: map['es_estudiante'] ?? false,
      esUrgente: map['es_urgente'] ?? false,
      fechaRegistro: _parseDate(map['fecha_registro']) ?? DateTime.now(),
      fechaEntrega: _parseDate(map['fecha_entrega']),
      estado: EstadoPedido.fromKey(map['estado']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'folio': folio,
      'nombre_cliente': nombreCliente,
      'telefono_cliente': telefonoCliente,
      'material': material,
      'color': color,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'peso_gramos': pesoGramos,
      'horas_estimadas': horasEstimadas,
      'minutos_estimados': minutosEstimados,
      'precio_unitario': precioUnitario,
      'total': total,
      'es_estudiante': esEstudiante,
      'es_urgente': esUrgente,
      'fecha_registro': fechaRegistro,
      'fecha_entrega': fechaEntrega,
      'estado': estado.key,
    };
  }

  Pedido copyWith({
    String? id,
    String? folio,
    String? nombreCliente,
    String? telefonoCliente,
    String? material,
    String? color,
    String? descripcion,
    int? cantidad,
    double? pesoGramos,
    int? horasEstimadas,
    int? minutosEstimados,
    double? precioUnitario,
    double? total,
    bool? esEstudiante,
    bool? esUrgente,
    DateTime? fechaRegistro,
    DateTime? fechaEntrega,
    EstadoPedido? estado,
  }) {
    return Pedido(
      id: id ?? this.id,
      folio: folio ?? this.folio,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      material: material ?? this.material,
      color: color ?? this.color,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      pesoGramos: pesoGramos ?? this.pesoGramos,
      horasEstimadas: horasEstimadas ?? this.horasEstimadas,
      minutosEstimados: minutosEstimados ?? this.minutosEstimados,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      total: total ?? this.total,
      esEstudiante: esEstudiante ?? this.esEstudiante,
      esUrgente: esUrgente ?? this.esUrgente,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      estado: estado ?? this.estado,
    );
  }

  /// Convierte Timestamp de Firestore o DateTime a DateTime, maneja null.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    // Firestore Timestamp tiene .toDate() — se invoca dinámicamente para no
    // importar cloud_firestore en el modelo y mantenerlo puro.
    try {
      return (value as dynamic).toDate();
    } catch (_) {
      return null;
    }
  }
}