# haxe-injection
A straight to the point Microsoft-style singleton dependency injection library for Haxe.

### What does it do?
Allows you to arbitrarily define service objects, specific to your application, that handle low-level code which can then be injected into high-level code via interfaces. This allows one to take advantage of the dependency inversion and single responsibility principles.

### How does it work?
First you define the interface that represents your given service. To identify it as a service, it must extend the hx.injection.Service interface:
```haxe
    import hx.injection.Service;

    interface TestService extends Service {
        public function sayWord() : Void;
    }
``` 

Then create a concrete implementation of that interface:
```haxe
    import hx.injection.Service;

    class LoudTestService implements TestService {
        public function new() {}
        public function sayWord() : Void {
            trace("HELLO");
        }
    }
``` 

During start up:-
- Create a service collection. Here, you can define what services your application will depend upon:
```haxe
    var collection = new ServiceCollection();
    collection.add(TestService, NormalTestService);
``` 

- Supply optional configuration files:
```haxe
collection.addConfig(new TestConfig());
```

- After defining your application dependencies, you can create the service provider and inject the service into your application:
```haxe
var provider = collection.createProvider();
var testService = provider.getService(TestService);
var app = new MyApp(testService);
```

- Additionally, you can define dependencies between services and configurations simply by defining them as an argument in the constructor for the concrete service and providing them in the service collection:
```haxe
    import hx.injection.Service;

    class LoudTestService implements TestService {

        private var _config : TestConfig;
        private var _phoneService : PhoneService;

        public function new(config : TestConfig, phoneService : PhoneService) {
            _config = config;
            _phoneService = phoneService;
        }

        public function sayWord() : Void {
            var word = _config.word;
            _phoneService.alert(word);
            trace(_config.word);
        }
    }
```