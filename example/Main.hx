package example;

import hx.injection.*;

class Main {
    static public function main() : Void {
      // Example 1:
      var collection = new ServiceCollection();
      collection.add(TestService, NormalTestService);
      collection.addConfig(new TestConfig());

      var provider = collection.createProvider();
      sayWord(provider.getService(TestService));
      
      // Example 2:
      var collection = new ServiceCollection();
      collection.add(TestService, LoudTestService);
      collection.addConfig(new TestConfig());

      var provider = collection.createProvider();
      sayWord(provider.getService(TestService));
      
    }

    private static function sayWord(service : TestService) : Void {
      service.sayWord();
    }
  }