enum Env {
  test,
  production,
}

const bool _isProductionApp = bool.fromEnvironment("dart.vm.product");
Env _env = _isProductionApp ? Env.production : Env.test;
class EnvUtil {

  static bool isProduction() {
    return _env == Env.production;
  }

  static setProductionEnv() {
    _env = Env.production;
  }

  static setTestEnv() {
    _env = Env.test;
  }
}
