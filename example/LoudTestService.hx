package example;

class LoudTestService implements TestService {

    private var _config : TestConfig;

    public function new(config : TestConfig) {
        _config = config;
    }

    public function sayWord() : Void {
        trace(_config.word.toUpperCase());
    }
}