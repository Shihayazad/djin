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


class TestContainer extends Mock implements Container {
  TestContainer(List instances) {
    Behavior behavior = when(callsTo('doResolve', instances[0].runtimeType.toString()));
    instances.forEach((instance) => behavior.thenReturn(new Future.immediate(instance)));
  }
  
  TestContainer.withDependencies(dependendObject, dependency) {
    Behavior behavior = when(callsTo('doResolve', dependendObject.runtimeType.toString(), [dependency]));
    behavior.thenReturn(new Future.immediate(dependendObject));
  }
}

void resolveUsingContainer() {
  Container container = new TestContainer([new TestClass()]);
  Component sut = new Component<TestClass>();
  expect(sut.hasInstance, isFalse);
  sut.resolveUsing(container).then(expectAsync1((result) {
    expect(result, new isInstanceOf<TestClass>());
    expect(sut.hasInstance, isTrue);
  }));
}

class TestClassImpl extends TestClass {
  
}

void resolveImplementation() {
  Container container = new TestContainer([new TestClassImpl()]);
  Component sut = new Component<TestClass>()..implementedBy(new ComponentImplementation<TestClassImpl>());
  expect(sut.hasInstance, isFalse);
  sut.resolveUsing(container).then(expectAsync1((result) {
    expect(result, new isInstanceOf<TestClassImpl>());
    expect(sut.hasInstance, isTrue);
  }));
}

class Dependency {  
}

class ClassWithDependency {
  final Dependency dependency;
  ClassWithDependency(Dependency this.dependency);
}

void resolveWithCustomDependencies() {
  Dependency dependency = new Dependency();
  Container container = new TestContainer.withDependencies(new ClassWithDependency(dependency), dependency);
  Component sut = new Component<ClassWithDependency>()..dependsOn([dependency]);
  expect(sut.hasInstance, isFalse);
  sut.resolveUsing(container).then(expectAsync1((result) {
    expect(result, new isInstanceOf<ClassWithDependency>());
    expect(result.dependency, same(dependency));
    expect(sut.hasInstance, isTrue);
  }));
}

void resolveSingleton() {
  Container container = new TestContainer([new TestClass()]);
  Component sut = new Component<TestClass>();
  var singletonInstance = null;
  sut.resolveUsing(container).then(expectAsync1((result) {
    singletonInstance = result;
    expect(result, new isInstanceOf<TestClass>());
  }));
  
  sut.resolveUsing(container).then(expectAsync1((result) {
    expect(result, same(singletonInstance));
  })); 
}

void resolveTransient() {
  Container container = new TestContainer([new TestClass(), new TestClass()]);
  Component sut = new Component<TestClass>(LifeStyle.Transient);
  var transientInstance = null;
  sut.resolveUsing(container).then(expectAsync1((result) {
    transientInstance = result;
    expect(result, new isInstanceOf<TestClass>());
  }));
  sut.resolveUsing(container).then(expectAsync1((result) {
    expect(result, isNot(same(transientInstance)));
  }));
}