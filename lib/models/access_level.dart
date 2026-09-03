enum AccessLevel {
  viewCheck(1),
  manageItems(2),
  admin(3);

  final int value;
  const AccessLevel(this.value);

  static AccessLevel fromInt(int v) {
    switch (v) {
      case 3:
        return AccessLevel.admin;
      case 2:
        return AccessLevel.manageItems;
      default:
        return AccessLevel.viewCheck;
    }
  }

  bool get canManageItems => value >= 2;
  bool get isAdmin => value >= 3;

  String get label {
    switch (this) {
      case AccessLevel.viewCheck:
        return 'Ver e marcar';
      case AccessLevel.manageItems:
        return 'Adicionar/editar itens';
      case AccessLevel.admin:
        return 'Administrador';
    }
  }
}
