/*
 * Copyright 2013 Philipp Walser
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
part of djin;

class Container {
  Map<String, Component> _components = new Map<String, Component>();
  
  Future resolveByName(String typeName, [List parameters]) {
    Completer completer = new Completer();
    Future<InstanceMirror> resolve = _resolveByName(typeName, parameters);
    resolve.then((InstanceMirror mirror) => completer.complete(mirror.reflectee));
    /*resolve.handleException( (exception) { 
      print("exception $exception");
      completer.completeException(exception);
      return true;
      });*/
    return completer.future;
  }
  
  void resolveByClosure(Function resolveCallback, [List parameters]) {
    InstanceMirror mirror = reflect(resolveCallback);
    FunctionTypeMirror funcmir = mirror.type;
    if(funcmir.parameters.length != 1) {
      throw new ArgumentError("closure must have only one param so that the type to be resolved can be determined");
    }    
    funcmir.parameters.forEach( (ParameterMirror param) { 
        resolveByName(param.type.simpleName, parameters).then( (result) => resolveCallback(result));
        });
    //mirror.type
  }
  
  void register(Component component) {
    _components.putIfAbsent(component.typeName, () => component);
  }
  
  bool containsComponentFor(String typeName) {
    return _components.containsKey(typeName);
  }
  
  Future<InstanceMirror> _resolveByName(String typeName, [List parameters]) {
    ClassMirror classMirror = _retrieveClassMirror(typeName);
    Completer<InstanceMirror> completer = new Completer<InstanceMirror>();
    MethodMirror constructor = _selectResolveableConstructor(classMirror, parameters);
    _resolveParameters(constructor, parameters).then((params) {
      print("Instantiate Type ${constructor.simpleName} with params $params");
      Future<InstanceMirror> newInstance = classMirror.newInstance(constructor.constructorName, params);
      newInstance.then((InstanceMirror newIM) {
        //if (!completer.future.isComplete) {
          completer.complete(newIM);
       // }
      }).catchError( (error) => print("exception error $error") );
      /*newInstance.handleException( (exception) {
        print("exception $exception"); 
        completer.completeException(exception);});*/
    });
    return completer.future;
  }

  Future<List> _resolveParameters(MethodMirror methodMirror, List parameters) {
    if (parameters == null) {
      parameters = new List();
    }
    for (int i = 0; i < parameters.length; ++i) {
      if (!_isSimpleType(parameters[i].runtimeType.toString())) {
        parameters[i] = reflect(parameters[i]);
      }
    }    
    
    Completer<List> completer = new Completer<List>();
    List<ParameterMirror> methodParams = methodMirror.parameters;
    var resolvedParams = new List<Future>();
    if (methodParams.length > parameters.length) {
      for (int i = parameters.length; i < methodParams.length; ++i) {
          String parameterTypeName = methodParams[i].type.simpleName;
          /*if (_isSimpleType(parameterTypeName)) {
            throw new NotResolveableError("Can not auto-resolve simple type in constructor ${methodMirror.simpleName} for parameter at position $i");
          } else if (_isDynamicType(parameterTypeName)) {
            throw new NotResolveableError("Can not auto-resolve Dynamic type in constructor ${methodMirror.simpleName} for parameter at position $i");
          }*/
          resolvedParams.add(_resolveByName(parameterTypeName));
      }
    }
    Future<List> waitForDependencies = Future.wait(resolvedParams);
    waitForDependencies.then((List additionalParameters) {
      parameters.addAll(additionalParameters);
      completer.complete(parameters);
    });
    /*waitForDependencies.handleException( (exception) {
      print("exception $exception");
      completer.completeException(exception);});*/
    
    return completer.future;
  }
  
  MethodMirror _selectResolveableConstructor(ClassMirror classMirror, [List parameters]) {
    MethodMirror resolveableConstructor;
    List<NotResolveableError> errors = new List<NotResolveableError>();
    //print("Find resolveable constructor for $classMirror");
    classMirror.constructors.values.forEach( (MethodMirror methodMirror) {
      if (methodMirror.parameters.isEmpty) {
        resolveableConstructor = methodMirror;
      } else if (resolveableConstructor == null) {
        List<ParameterMirror> constructorParams = methodMirror.parameters;
        for (int i = 0; i < constructorParams.length; ++i) {
          String requestedParamType = constructorParams[i].type.simpleName;
          if (parameters != null && parameters.length > i) {
            /*String paramType = parameters[i].runtimeType.toString();
            if(requestedParamType != paramType 
                && requestedParamType != "Dynamic"
                && (requestedParamType != "num" || (paramType != "double" && paramType != "int"))) {
              errors.add(new NotResolveableError("Type mismatch in constructor ${methodMirror.simpleName} for parameter at position $i. Expected $requestedParamType but got $paramType"));
            }*/
          } else {          
            if (_isSimpleType(requestedParamType)) {
              errors.add(new NotResolveableError("Can not auto-resolve simple type $requestedParamType in constructor ${methodMirror.simpleName} for parameter at position $i"));
            } else if (_isDynamicType(requestedParamType)) {
              errors.add(new NotResolveableError("Can not auto-resolve Dynamic type in constructor ${methodMirror.simpleName} for parameter at position $i"));
            } else {
              try {
                ClassMirror classMirror = _retrieveClassMirror(requestedParamType);
                _selectResolveableConstructor(classMirror);
              } on NotResolveableError catch(error) {
                errors.add(error);
              }  
            }
          }
          if (errors.isEmpty) {
            resolveableConstructor = methodMirror;
          }
        }
      }
    });
    if (resolveableConstructor == null) {
      throw new NotResolveableError.fromList(errors);
    }
    return resolveableConstructor;
  }
  
  ClassMirror _retrieveClassMirror(String typeName) {
    ClassMirror mirror = currentMirrorSystem().isolate.rootLibrary.classes[typeName];
    if(mirror == null) {
      currentMirrorSystem().libraries.values.forEach((lib) {
        if (lib.classes.containsKey(typeName))
        {
          mirror = lib.classes[typeName];
        }
      });
    }
    if(mirror == null) {
      throw new ArgumentError("typeName '$typeName' not found in any library known to this isolate");
    }
    return mirror;
  }
  
  bool _isSimpleType(String typeName) => (typeName == "num" 
                                            || typeName == "int"
                                            || typeName == "double"
                                            || typeName == "String" 
                                            || typeName == "bool");
  
  bool _isDynamicType(String typeName) => (typeName == "Dynamic");
}
