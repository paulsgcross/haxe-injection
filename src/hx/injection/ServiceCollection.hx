package hx.injection;

import haxe.Exception;

/*
MIT License

Copyright (c) 2020 Paul SG Cross

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

class ServiceCollection {
    
    private var _configs : Map<String, Any>;
    private var _requestedServices : Map<String, Class<Service>>;
    private var _services : Map<String, Service>;
    
    public function new() {
        _requestedServices = new Map();
        _configs = new Map();
        _services = new Map();
    }
    
    public function addConfig<T>(config : T) : Void {
        _configs.set(Type.getClassName(Type.getClass(config)), config);
    }
    
    public function addService<T : Service, V : T>(type : Class<T>, service : Class<V>) : ServiceCollection {
        _requestedServices.set(Type.getClassName(type), cast service);
        
        return this;
    }
    
    public function createProvider() : ServiceProvider {
        createDependencyTree();
        return new ServiceProvider(_services);
    }

    private function createDependencyTree() : Void {
        for(service in _requestedServices.keyValueIterator()) {
            handleService(service.key, service.value);
        }
    }

    private function handleService(interfaceName : String, service : Class<Service>) : Service {
        var instance = getHandled(interfaceName);
        if(instance != null) {
            return instance;
        }

        var args = getServiceArgs(service);
        var dependencies = [];
        for(arg in args) {
            var dependency = getService(arg);
            if(dependency != null) {
                dependencies.push(handleService(arg, dependency));
                continue;
            }

            var config = _configs.get(arg);
            if(config != null) {
                dependencies.push(config);
                continue;
            }

            throw new Exception('Dependency ' + arg + ' for ' + service + ' is missing. Did you add it to the collection?');
        }

        instance = Type.createInstance(service, dependencies);
        _services.set(interfaceName, instance);

        return instance;
    }

    private function getService(arg : String) : Class<Service> {
        return _requestedServices.get(arg);
    }

    private function configExists(arg : String) : Bool {
        return _configs.get(arg) != null;
    }

    private function getServiceArgs(service : Class<Service>) : Array<String> {
        var instance = Type.createEmptyInstance(service);
        return instance.getConstructorArgs();
    }

    private function getHandled(interfaceName : String) : Service {
        return _services.get(interfaceName);
    }
}