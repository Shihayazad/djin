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

abstract class ComponentDefinition<T> {
  static final RegExp _regexp = new RegExp(r'\b(?!(?:Component))\w+');
  
  String _typeName;
  
  String get typeName => _typeName;
  
  ComponentDefinition() {
    _typeName = _retrieveTypeName();
  }
  
  String _retrieveTypeName() {
    Iterator<Match> iterator = _regexp.allMatches(this.runtimeType.toString()).iterator;
    iterator.moveNext();
    return iterator.current.group(0);
  }  
}

class Component<T> extends ComponentDefinition<T> {  
  LifeStyle _lifeStyle;
  ComponentImplementation _implementation;
  InstanceHolder _instanceHolder;
  
  LifeStyle get lifeStyle => _lifeStyle;
  
  Component([LifeStyle style]) {
    if(!?style) {
      _lifeStyle = LifeStyle.Singleton;
    } else {
      _lifeStyle = style;
    }
    _instanceHolder = _lifeStyle.createInstanceHolder();
    
    //List<String> typeArguments = _retrieveTypeArguments();
    //typeArguments.forEach( (arg) => print(arg));
  }
  
  void implementedBy(ComponentImplementation impl) {
    _implementation = impl;
  }
  
  bool get hasInstance {
    return _instanceHolder.hasInstance;
  }
  
  void instance(T instance) {
    if(_lifeStyle == LifeStyle.Transient) {
      throw new Error("You can not specify an instance for a component with transient lifestyle");
    }
    _instanceHolder.instance = new Future.immediate(instance);
  }

  Future resolveUsing(Container container, [List parameters]) {
    Future resolvedInstance;
    if(!_instanceHolder.hasInstance) {
      String typeToResolve = typeName;
      if(_implementation != null)  {
        typeToResolve = _implementation.typeName;
      }
      resolvedInstance = container.resolveByName(typeToResolve, parameters);
      _instanceHolder.instance = resolvedInstance;
      //print("return cached instance");
      //resolvedInstance = new Future.immediate(_instanceHolder.instance);
    } else {
      resolvedInstance = _instanceHolder.instance;
     /* print("create new instance");
      
      resolvedInstance = 
      resolvedInstance.then((instance) {
        print("set instance");_instanceHolder.instance = instance;});*/
    }
    return resolvedInstance;
  }  
  
  /**
   * ClassMirror.typeArguments is not implemented yet, so we need to implement a fallback
  List<String> _retrieveTypeArguments() {
    InstanceMirror im = reflect(this);
    ClassMirror cm = im.type;
    return cm.typeArguments.keys;
  }*/
  List<String> _retrieveTypeArguments() {
    List<String> typeArguments = new List<String>();
    for(Match match in _regexp.allMatches(this.runtimeType.toString())) {
      String typeArgument = match.group(0);
      typeArguments.add(typeArgument);
    }
    return typeArguments;
  }  
 
}

