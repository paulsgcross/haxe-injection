package hx.injection.macros;

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

import haxe.macro.TypeTools;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

#if macro
class ServiceMacro {
    public static function build() {
        var fields = Context.getBuildFields();
        var classType = Context.getLocalClass().get();
        var interfaces = classType.interfaces;

        if(classType.isInterface) {
            return fields;
        }

        var constructorArgs = [];
        for(field in fields) {
            if(field.name == "new") {
                var pos = field.pos;
                switch(field.kind) {
                    case FFun(f):
                        for(arg in f.args) {
                            var type = Context.resolveType(arg.type, pos);
                            switch(type) {
                                case TInst(t, params):
                                    for(int in interfaces) {
                                        if(int.t.toString() == t.toString()) {
                                            throw "Service Builder: Recursive parameter definition.";
                                        }
                                    }
                                    constructorArgs.push(t.toString());
                                default:
                                    throw "Service Builder: Constructor parameter types must be either class or interface.";
                            }
                        }
                    default:
                }
                var newField = {
                    name: "getConstructorArgs",
                    access: [Access.APrivate],
                    kind: FFun({args: [], ret: macro:Array<String>, expr: macro return $v{constructorArgs}}),
                    pos: Context.currentPos(),
                }
                fields.push(newField);
                break;
            }
        }
        return fields;
    }
}
#end