library;

final _emailDeseni=RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? emailValidator(String? value){
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'E-posta gerekli.';
  if (!_emailDeseni.hasMatch(v)) return 'Geçerli bir e-posta girmelisin.';
  return null;
}

//backendde min 8 max 72 karakter olmasını ve hem harf hem rakam içermesini girmiştik. ayrıca sadece rakam ve sadece harften oluşan şifreler reddedilir
String? passwordValidator(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Şifre gerekli.';
  if (v.length < 8) return 'Şifre en az 8 karakter olmalı.';
  if (v.length > 72) return 'Şifre en fazla 72 karakter olabilir.';
  final sadeceRakam = RegExp(r'^\d+$').hasMatch(v);
  final sadeceHarf = RegExp(r'^[a-zA-ZçğıöşüÇĞİÖŞÜ]+$').hasMatch(v);
  if (sadeceRakam || sadeceHarf) {
    return 'Şifre hem harf hem rakam içermeli.';
  }
  return null;
}

String? loginPasswordValidator(String? value){
  if(value == null || value.isEmpty) return 'Şifre gerekli.';
  return null;
}

String? fullNameValidator(String? value){
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null;
  if (v.length > 120) return 'İsim en fazla 120 karakter olabilir.';
  return null;
}

/// Kilo ve boy sinirlari backend'deki Field(gt/lt) ile BIREBIR AYNI
/// (backend: schemas/user.py UserProfileBase). Amac istegi bosuna
/// gondermemek: ayni kural sunucuda da var, burasi yalnizca kullaniciya
/// 422 yerine anlasilir bir cumle gostermek icin.
String? kiloValidator(String? value) {
  final v = (value ?? '').trim().replaceAll(',', '.');
  if (v.isEmpty) return 'Kilo gerekli.';
  final sayi = double.tryParse(v);
  if (sayi == null) return 'Sayı girmelisin.';
  if (sayi <= 20 || sayi >= 400) return 'Kilo 20-400 kg arasında olmalı.';
  return null;
}

String? boyValidator(String? value) {
  final v = (value ?? '').trim().replaceAll(',', '.');
  if (v.isEmpty) return 'Boy gerekli.';
  final sayi = double.tryParse(v);
  if (sayi == null) return 'Sayı girmelisin.';
  if (sayi <= 50 || sayi >= 260) return 'Boy 50-260 cm arasında olmalı.';
  return null;
}

/// '78,5' -> 78.5. Turkce klavyede ondalik ayraci VIRGULDUR; double.parse
/// virgulu kabul etmez ve kullanici neden kaydedilmedigini anlamaz.
double? ondalikCoz(String? value) =>
    double.tryParse((value ?? '').trim().replaceAll(',', '.'));

enum PasswordStrength {weak, medium, strong }

PasswordStrength calculatePasswordStength(String value){
  if (value.length < 8) return PasswordStrength.weak;
  final hasLetter = RegExp(r'[a-zA-ZçğıöşüÇĞİÖŞÜ]').hasMatch(value);
  final hasDigit = RegExp(r'\d').hasMatch(value);
  if (!hasLetter || !hasDigit) return PasswordStrength.weak;

  final hasUpper = RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(value);
  final hasLower = RegExp(r'[a-zçğıöşü]').hasMatch(value);
  final hasSpecial = RegExp(r'[^a-zA-Z0-9çğıöşüÇĞİÖŞÜ]').hasMatch(value);
  final guclu = value.length >= 12 || (hasUpper && hasLower && hasSpecial);

  return guclu ? PasswordStrength.strong : PasswordStrength.medium;
}