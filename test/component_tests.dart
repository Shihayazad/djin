import 'package:unittest/unittest.dart';
import "package:unittest/mock.dart";
import 'dart:async';
import '../lib/djin.dart';

void main() {
  test("shouldDefaultToSingletonLifeStyle", useSingletonLifeStyleAsDefault);
  test("shouldHaveTransientLifeStyle", useTransientLifeStyle);
  test("shouldBeAbleToSpecifyInstance", specifyInstance);
  test("shouldThrowArgumentErrorIfInstanceAlreadySet", throwArgumentErrorIfInstanceAlreadySet);
  test("shouldThrowErrorWhenSettingInstanceForTransientLifeStyle", throwErrorWhenSettingInstanceForTransientLifeStyle);
  test("shouldHaveTransientLifeStyle", useTransientLifeStyle);
  test("shouldResolveUsingContainer", resolveUsingContainer);
  test("shouldResolveWithCustomDependencies", resolveWithCustomDependencies);
  test("shouldResolveRegisteredImplementation", resolveImplementation);
  test("shouldResolveSingleton", resolveSingleton);
  test("shouldResolveTransient", resolveTransient);
}

class TestClass {
}

void useSingletonLifeStyleAsDefault() {
  Component<TestClass> sut = new Component<TestClass>();
  expect(sut.lifeStyle, same(LifeStyle.Singleton));
}

void useTransientLifeStyle() {
  Component<TestClass> sut = new Component<TestClass>(LifeStyle.Transient);
  expect(sut.lifeStyle, same(LifeStyle.Transient));
}

void specifyInstance() {
  Component<TestClass> sut = new Component<TestClass>();
  sut.instance(new TestClass());
  expect(sut.hasInstance, isTrue);
}

void throwArgumentErrorIfInstanceAlreadySet() {
  Component<TestClass> sut = new Component<TestClass>();
  sut.instance(new TestClass());
  expect(() => sut.instance(new TestClass()), throwsA(new isInstanceOf<ArgumentError>()));
}

void throwErrorWhenSettingInstanceForTransientLifeStyle() {
  Component<TestClass> sut = new Component<TestClass>(LifeStyle.Transient);
  expect(() => sut.instance(new TestClass()), throwsA(new isInstanceOf<Error>()));
}

void resolveUsingContainer() {
  var resolveDelegate = (classMirror, params) {
    expect(classMirror.simpleName, same("TestClass"));
    return new Future.immediate(null);
  };
  Component sut = new Component<TestClass>();
  expect(sut.hasInstance, isFalse);
  sut.resolveUsing(resolveDelegate);
  expect(sut.hasInstance, isTrue);
}

class TestClassImpl extends TestClass {
  
}

void resolveImplementation() {
  var resolveDelegate = (classMirror, params) {
    expect(classMirror.simpleName, same("TestClassImpl"));
    return new Future.immediate(null);
  };
  Component sut = new Component<TestClass>()..implementedBy(new ComponentImplementation<TestClassImpl>());
  expect(sut.hasInstance, isFalse);
  sut.resolveUsing(resolveDelegate);
  expect(sut.hasInstance, isTrue);
}

class Dependency {  
}

class ClassWithDependency {
  final Dependency dependency;
  ClassWithDependency(Dependency this.dependency);
}

void resolveWithCustomDependencies() {
  Dependency dependency = new Dependency();
  
  var resolveDelegate = (classMirror, params) {
    expect(classMirror.simpleName, same("ClassWithDependency"));
    expect(params[0], same(dependency));
    return new Future.immediate(null);
  };

  Component sut = new Component<ClassWithDependency>()..dependsOn([dependency]);
  expect(sut.hasInstance, isFalse);
  sut.resolveUsing(resolveDelegate);
  expect(sut.hasInstance, isTrue);
}

void resolveSingleton() {
  Component sut = new Component<TestClass>();
  var singletonInstance;
  
  var resolveDelegate = (classMirror, params) {
    expect(classMirror.simpleName, same("TestClass"));
    return new Future.immediate(new TestClass());
  };
  
  sut.resolveUsing(resolveDelegate).then(expectAsync1((result) {
    singletonInstance = result;
  })); 
  
  sut.resolveUsing(resolveDelegate).then(expectAsync1((result) {
    expect(result, same(singletonInstance));
  })); 
}

void resolveTransient() {
  Component sut = new Component<TestClass>(LifeStyle.Transient);
  var transientInstance = null;
  
  var resolveDelegate = (classMirror, params) {
    expect(classMirror.simpleName, same("TestClass"));
    return new Future.immediate(new TestClass());
  };
  
  sut.resolveUsing(resolveDelegate).then(expectAsync1((result) {
    transientInstance = result;
  }));
  sut.resolveUsing(resolveDelegate).then(expectAsync1((result) {
    expect(result, isNot(same(transientInstance)));
  }));
}