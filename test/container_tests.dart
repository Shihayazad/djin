import 'package:unittest/unittest.dart';
import '../lib/djin.dart';
import 'dart:async';
import 'dart:mirrors';

/// The classes used in all those tests are defined at the bottom of this file
void main() {
  test("argumentErrorTest", shouldThrowArgumentErrorIfGivenTypeIsNotKnownInOwnIsolate);
  test("doNotAutoResolveSimpleOrDyanmicTypes", shouldThrowNotResolveableErrorIfDependenciesToAutoResolveAreSimpleOrDynamicTypes);
  test("resolveWithParametersGiven", shouldResolveIfSimpleOrDyanmicDependenciesAreGiven);
  //test("paramsInWrongOrder", shouldThrowFutureUnhandledExceptionIfParametersArePassedInTheWrongOrder);
  test("resolveConcreteDependency", shouldResolveConcreteDependency);
  
  test("useResolveableConstructor", shouldUseResolveableConstructor);

  
  test("resolveByClosure", shouldResolveUsingClosure);
}

void shouldThrowArgumentErrorIfGivenTypeIsNotKnownInOwnIsolate() {
  print("argumentErrorTest");
  Container container = new Container();
  ClassWithSimpleDependency<Dependency> completer = new ClassWithSimpleDependency<Dependency>(new Dependency());
  print(completer.runtimeType);
  expect( () => container.resolveByName("UnknownTypeName"), throwsA(new isInstanceOf<ArgumentError>()));
}

void shouldThrowNotResolveableErrorIfDependenciesToAutoResolveAreSimpleOrDynamicTypes() {
  print("doNotAutoResolveSimpleOrDyanmicTypes");
  Container container = new Container();
  expect( () => container.resolveByName("ClassWithStringDependency"), throwsA(new isInstanceOf<NotResolveableError>()));
  expect( () => container.resolveByName("ClassWithNumDependency"), throwsA(new isInstanceOf<NotResolveableError>()));
  expect( () => container.resolveByName("ClassWithBoolDependency"), throwsA(new isInstanceOf<NotResolveableError>()));
  expect( () => container.resolveByName("ClassWithDynamicDependency"), throwsA(new isInstanceOf<NotResolveableError>()));
}

void shouldThrowFutureUnhandledExceptionIfParametersArePassedInTheWrongOrder() {
  print("paramsInWrongOrder");
  Container container = new Container();
  Map<String, ClassMirror> classes = currentMirrorSystem().isolate.rootLibrary.classes;
  ClassMirror classMirror = classes["ClassWithSeveralDependencies"];

  classMirror.constructors.forEach((String key, MethodMirror c) {
    print("Params: ${c.parameters}");
  });
  
  Future<InstanceMirror> newInstance = classMirror.newInstance("", [0, "SomeValue"])
      .catchError(expectAsync1((error) => print("error $error")));
      //.whenComplete(() => print("Tada"));
  
  
  //expect( () => container.resolveByName("ClassWithSeveralDependencies", [0, "SomeValue"]), throwsA(new isInstanceOf<FutureUnhandledException>()));
}

void shouldResolveIfSimpleOrDyanmicDependenciesAreGiven() {
  print("resolveWithParametersGiven");
  Container container = new Container();
  container.resolveByName("ClassWithStringDependency", ["SomeValue"]).then(expectAsync1((result) {
    expect(result, new isInstanceOf<ClassWithStringDependency>());
    expect(result.toString(), equals("SomeValue"));
  }));
  
  container.resolveByName("ClassWithNumDependency", [0]).then(expectAsync1((result) {
    expect(result, new isInstanceOf<ClassWithNumDependency>());
    expect(result.toString(), equals("0"));
  }));
  
  container.resolveByName("ClassWithBoolDependency", [true]).then(expectAsync1((result) {
    expect(result, new isInstanceOf<ClassWithBoolDependency>());
    expect(result.toString(), equals("true"));
  }));
  
  container.resolveByName("ClassWithDynamicDependency", [new Object()]).then(expectAsync1((result) {
    expect(result, new isInstanceOf<ClassWithDynamicDependency>());
    expect(result.toString(), equals("Instance of 'Object'"));
  }));
  
  container.resolveByName("ClassWithSeveralDependencies", ["SomeValue", 0]).then(expectAsync1((result) {
    expect(result, new isInstanceOf<ClassWithSeveralDependencies>());
    expect(result.toString(), equals("SomeValue 0"));
  }));
  
  // TODO: I probably don't need all those classes, the generic one is enough to test all those cases
  container.resolveByName("ClassWithSimpleDependency", [new Dependency()]).then(expectAsync1((result) {
    expect(result, new isInstanceOf<ClassWithSimpleDependency>());
    expect(result.toString(), equals("Instance of 'Dependency'"));
  }));
}

void shouldResolveConcreteDependency() {
  print("resolveConcreteDependency");
  Container container = new Container();
  container.resolveByName("ClassWithDependency").then(expectAsync1((result) {
    expect(result, new isInstanceOf<ClassWithDependency>());
    expect(result.dependency, new isInstanceOf<Dependency>());
    print("got result $result");
  }));
} 

void shouldUseResolveableConstructor() {
  Container container = new Container();
  container.resolveByName("ClassWithSeveralConstructors").then(expectAsync1((result) {
    expect(result, new isInstanceOf<ClassWithSeveralConstructors>());
    expect(result.dependency, new isInstanceOf<Dependency>());
  }));
}  

void shouldResolveUsingClosure() {
  Container container = new Container();
  var asyncCallback = expectAsync1((Dependency instance) => expect(instance, new isInstanceOf<Dependency>()));
  container.resolveByClosure((Dependency instance) => asyncCallback(instance));
  
  Dependency dependency = new Dependency();
  var asyncCallbackWithDependency = expectAsync1((ClassWithDependency instance) {
      expect(instance, new isInstanceOf<ClassWithDependency>());
      expect(instance.dependency, equals(dependency));
      
    });
  
  container.resolveByClosure((ClassWithDependency instance) => asyncCallbackWithDependency(instance), [dependency]);
}

class ClassWithSimpleDependency<T> {
  final T simpleValue;
  
  ClassWithSimpleDependency(T this.simpleValue);
  
  String toString() => simpleValue.toString();
}

class ClassWithStringDependency extends ClassWithSimpleDependency<String> {
  ClassWithStringDependency(String dependency) : super(dependency);
}

class ClassWithNumDependency extends ClassWithSimpleDependency<num> {
  ClassWithNumDependency(num dependency) : super(dependency);
}

class ClassWithBoolDependency extends ClassWithSimpleDependency<bool> {
  ClassWithBoolDependency(bool dependency) : super(dependency);
}

class ClassWithDynamicDependency extends ClassWithSimpleDependency {
  ClassWithDynamicDependency(dependency) : super(dependency);
}

class ClassWithSeveralDependencies extends ClassWithSimpleDependency<String> {
  num otherValue;
  ClassWithSeveralDependencies(String dependency, num this.otherValue) : super(dependency);
  
  String toString() => "${super.toString()} ${otherValue.toString()}";
}

class Dependency {
  
}

class ClassWithDependency {
  final Dependency dependency;
  
  ClassWithDependency(Dependency this.dependency);
}

class ClassWithSeveralConstructors extends ClassWithDependency{
  ClassWithSeveralConstructors.unresolveable(String unresolveableParam) : super(null);
  ClassWithSeveralConstructors(Dependency dependency) : super(dependency);
}