class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class ForbiddenException implements Exception {
  const ForbiddenException();
}

class HttpException implements Exception {
  const HttpException(this.message);

  final String message;

  @override
  String toString() => message;
}
