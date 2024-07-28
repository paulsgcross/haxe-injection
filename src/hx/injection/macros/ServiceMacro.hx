package hx.injection.macros;

#if macro
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Type.Ref;
import haxe.macro.Expr;
import haxe.macro.Type.ClassType;

class ServiceMacro {
	public static var requestedTypes:StringMap<String> = new StringMap();

	public static function build() {
		var fields = Context.getBuildFields();
		var classType = Context.getLocalClass().get();
		var interfaces = classType.interfaces;

		var funcName = "getConstructorArgs";

		if (classType.isInterface) {
			return fields;
		}

		for (field in fields)
			if (field.name == funcName)
				return fields;

		var constructorArgs = [];
		for (field in fields) {
			if (field.name == "new") {
				var pos = field.pos;
				var metas = field.meta;

				var names = new StringMap();
				if (metas != null) {
					for (meta in metas) {
						switch (meta.name) {
							case ':binding':
								var expr1 = meta.params[0].expr;
								var expr2 = meta.params[1].expr;
								switch ([expr1, expr2]) {
									case [EConst(CIdent(s1)), _]:
										switch (field.kind) {
											case FFun(f):
												var check = false;
												for (arg in f.args) {
													if (arg.name == s1) {
														check = true;
														break;
													}
												}
												if (!check) Context.error('No such argument ${s1} for ${Context.getLocalModule()}', pos);
											default:
										}
										var type = getClassType(expr2);
										try {
											Context.getType(type);
										} catch (e:Dynamic) {
											Context.error('No such type \"${type}\"" exists to bind in ${Context.getLocalModule()}', pos);
										}
										names.set(s1, type);
									default:
								}
							case ':autoCtor':
								switch (field.kind) {
									case FFun(f):
										var block = [];
										for (arg in f.args) {
											var newField = {
												name: '_${arg.name}',
												access: [APrivate],
												kind: FVar(arg.type, null),
												pos: Context.currentPos(),
											}
											fields.push(newField);
											block.push(macro {$i{'_${arg.name}'} = $i{'${arg.name}'}});
										}

										field.kind = FFun({args: f.args, ret: f.ret, expr: macro {$e{f.expr} $b{block}}});

									default:
								}
						}
					}
				}

				if (classType.name != 'ServiceProvider') {
					switch (field.kind) {
						case FFun(f):
							var argNum = 1;
							for (arg in f.args) {
								var type = Context.resolveType(arg.type, pos);
								switch (type) {
									case TInst(t, params):
										var argName = names.get(arg.name);

										if (argName == null) {
											for (int in interfaces) {
												var hash_1 = int.t.toString();
												var hash_2 = t.toString();
												
												// if (hash_1 == hash_2) {
												// 	Context.error('Service: Argument ${argNum} (${t.toString()}) is recursive in ${classType.name}.',
												// 		pos);
												// }
											}
										}

										var parameterArgs = paramsToString(params);

										var serviceName = argName != null ? '|' + argName : '';
										var argDefinition = '${t.toString()}${parameterArgs}${serviceName}';
										requestedTypes.set(argDefinition, argDefinition);
										constructorArgs.push(argDefinition);
									case TType(t, params):
										var type = t.toString();
										if (type == 'Iterable') {
											var out = '(';
											var param = params[0];
											switch (param) {
												case TInst(t, params):
													out += t.toString() + paramsToString(params);
												default:
											}
											out += ')';
											var argDefinition = '${t.toString()}$out';
											requestedTypes.set(argDefinition, argDefinition);
											constructorArgs.push(argDefinition);
										} else {
											Context.error('Injecting "$type" not supported by the DI container', pos);
										}
									default:
										Context.error("Service Builder: Constructor parameter types must be either a class or an interface.", pos);
								}
								argNum++;
							}
						default:
					}
				}

				var access = [Access.APrivate];
				if (superClassIsService(classType)) {
					// Only if we have defined a ctor, otherwise don't
					if (superHasCtor(classType))
						access.push(Access.AOverride);
				}

				var newField = {
					name: funcName,
					access: access,
					kind: FFun({args: [], ret: macro :Array<String>, expr: macro return $v{constructorArgs}}),
					pos: Context.currentPos(),
				}
				fields.push(newField);
			}
		}
		return fields;
	}

	private static function paramsToString(params:Array<haxe.macro.Type>):String {
		var parameterArgs = '';
		for (param in params) {
			switch (param) {
				case TAbstract(t, params):
					parameterArgs += '_' + t.toString().split('.').join('_');
				case TInst(t, params):
					parameterArgs += '_' + t.toString().split('.').join('_');
				default:
			}
		}
		return parameterArgs;
	}

	private static function getClassType(expr:ExprDef):String {
		var out = '';
		switch (expr) {
			case EField(e, field):
				out += getClassType(e.expr) + '.' + field;
			case EConst(CIdent(s)):
				out += s;
			default:
		}
		return out;
	}

	private static function interfaceIsService(interfaces:Array<{t:Ref<ClassType>, params:Array<haxe.macro.Type>}>):Bool {
		var result = false;
		if (interfaces != null) {
			for (int in interfaces) {
				var interfaceType = int.t.get();
				if (interfaceType.name == 'Service') {
					return true;
				}
				result = result || interfaceIsService(interfaceType.interfaces);
			}
		}
		return result;
	}

	private static function superClassIsService(type:ClassType):Bool {
		var superClass = type.superClass;
		if (superClass != null) {
			var superType = superClass.t.get();
			if (interfaceIsService(superType.interfaces)) {
				return true;
			}
			return superClassIsService(superType);
		} else
			return false;
	}

	private static function superHasCtor(type:ClassType):Bool {
		var superClass = type.superClass;
		if (superClass != null) {
			var superType = superClass.t.get();
			if (superType.constructor != null)
				return true;
			else
				return superHasCtor(superType);
		} else
			return false;
	}
}
#end
