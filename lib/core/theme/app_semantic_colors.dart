import 'package:flutter/material.dart';

/// Cores semânticas que não existem no [ColorScheme] do Material
/// (ex.: "sucesso" verde). Ficam no tema via [ThemeExtension] — as telas
/// leem por `context.semantic`, nunca com hex solto.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  static const AppSemanticColors light = AppSemanticColors(
    success: Color(0xff2e9e5b),
    onSuccess: Color(0xffffffff),
    successContainer: Color(0xffd8f2e2),
    onSuccessContainer: Color(0xff0b3b22),
    info: Color(0xff3f6fe5),
    infoContainer: Color(0xffdee6ff),
    onInfoContainer: Color(0xff0a1f52),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: Color(0xff7fd7a3),
    onSuccess: Color(0xff06371e),
    successContainer: Color(0xff1f4d33),
    onSuccessContainer: Color(0xffd8f2e2),
    info: Color(0xffb4c6ff),
    infoContainer: Color(0xff2b3f74),
    onInfoContainer: Color(0xffdee6ff),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
