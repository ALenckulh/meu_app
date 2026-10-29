/// Validações de formulário reaproveitadas no login e no cadastro.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _letra = RegExp(r'\p{L}', unicode: true);
  static final RegExp _numero = RegExp(r'\d');

  static String? email(String? valor) {
    final String v = (valor ?? '').trim();
    if (v.isEmpty) {
      return 'Informe o e-mail';
    }
    if (!_email.hasMatch(v)) {
      return 'E-mail inválido';
    }
    return null;
  }

  /// Regra de senha do cadastro: mínimo de 8 caracteres, com letras e números.
  static String? senhaNova(String? valor) {
    final String v = valor ?? '';
    if (v.isEmpty) {
      return 'Informe a senha';
    }
    if (v.length < 8) {
      return 'A senha precisa ter ao menos 8 caracteres';
    }
    if (!_letra.hasMatch(v) || !_numero.hasMatch(v)) {
      return 'Use letras e números na senha';
    }
    return null;
  }
}
