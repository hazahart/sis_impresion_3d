enum RolUsuario {
  operador('operador', 'Operador');

  final String key;
  final String label;

  const RolUsuario(this.key, this.label);

  static RolUsuario fromKey(String? key) => RolUsuario.values.firstWhere(
    (e) => e.key == key,
    orElse: () => RolUsuario.operador,
  );
}

enum EstadoCuenta {
  activo('activo', 'Activo'),
  pendienteAprobacion('pendiente_aprobacion', 'Pendiente de aprobación');

  final String key;
  final String label;

  const EstadoCuenta(this.key, this.label);

  static EstadoCuenta fromKey(String? key) => EstadoCuenta.values.firstWhere(
    (e) => e.key == key,
    orElse: () => EstadoCuenta.pendienteAprobacion,
  );
}

class Usuario {
  final String? id;
  final String correo;
  final RolUsuario rol;
  final EstadoCuenta estado;
  final String? nombreCompleto;
  final String? fotoUrl;
  final String? numeroControl;
  final String? carrera;
  final int? semestre;
  final DateTime fechaRegistro;
  final String? info;

  const Usuario({
    this.id,
    required this.correo,
    required this.rol,
    required this.estado,
    this.nombreCompleto,
    this.fotoUrl,
    this.numeroControl,
    this.carrera,
    this.semestre,
    required this.fechaRegistro,
    this.info,
  });

  static bool esInstitucional(String correo) {
    final dominio = correo.trim().toLowerCase().split('@').last;
    return dominio == 'itcelaya.edu.mx' || dominio == 'celaya.tecnm.mx';
  }

  factory Usuario.fromMap(Map<String, dynamic> map, {String? id}) {
    return Usuario(
      id: id,
      correo: map['correo'] ?? '',
      rol: RolUsuario.fromKey(map['rol']),
      estado: EstadoCuenta.fromKey(map['estado']),
      nombreCompleto: map['nombre_completo'],
      fotoUrl: map['foto_url'],
      numeroControl: map['numero_control'],
      carrera: map['carrera'],
      semestre: map['semestre'] != null
          ? (map['semestre'] as num).toInt()
          : null,
      fechaRegistro: _parseDate(map['fecha_registro']) ?? DateTime.now(),
      info: map['info'],
    );
  }

  Map<String, dynamic> toMap() => {
    'correo': correo,
    'rol': rol.key,
    'estado': estado.key,
    'nombre_completo': nombreCompleto,
    'foto_url': fotoUrl,
    'numero_control': numeroControl,
    'carrera': carrera,
    'semestre': semestre,
    'fecha_registro': fechaRegistro,
    'info': info,
  };

  Usuario copyWith({
    String? id,
    String? correo,
    RolUsuario? rol,
    EstadoCuenta? estado,
    String? nombreCompleto,
    String? fotoUrl,
    String? numeroControl,
    String? carrera,
    int? semestre,
    DateTime? fechaRegistro,
    String? info,
  }) => Usuario(
    id: id ?? this.id,
    correo: correo ?? this.correo,
    rol: rol ?? this.rol,
    estado: estado ?? this.estado,
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    fotoUrl: fotoUrl ?? this.fotoUrl,
    numeroControl: numeroControl ?? this.numeroControl,
    carrera: carrera ?? this.carrera,
    semestre: semestre ?? this.semestre,
    fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    info: info ?? this.info,
  );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return (value as dynamic).toDate();
    } catch (_) {
      return null;
    }
  }
}
