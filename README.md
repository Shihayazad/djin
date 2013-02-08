djin
====

Inversion of Control-Container for Dart using the Mirrors-API

This package is in a very early state, and as the Mirrors-API, not fully implemented yet.

The goal is to provide an IoC-Container which requires as little configuration as possible, 
but gives you the option to do so if needed. 
It is inspired by the IoC-library 'Castle Windsor' for the .NET-Framework. 

Example:

class Dependency {  
}

class ClassWithDependency {
  final Dependency dependency;  
  ClassWithDependency(Dependency this.dependency);
}

void main() {
  Container container = new Container();
  container.resolveByName("ClassWithDependency").then((result) => print("got result $result"));
}

djin will resolve this component automatically by using the Mirror-Api of Dart. 

If you don't like using Strings for identifying your classes, you can also use the following method to resolve your dependencies:

container.resolveByClosure((ClassWithDependency instance) => print("got result $result"));

Of course, you can provide additional parameters to be used when resolving:

Dependency dependency = new Dependency();
container.resolveByClosure((ClassWithDependency instance) => print("got result $result"), [dependency]);
container.resolveByName("ClassWithDependency", [dependency]).then((result) => print("got result $result"));


Next things to come:
- Registration of Components for custom configuration, something like that:
  Component component = new Component<TestClass>(Lifestyle.Transient)..implementedBy(new ComponentImplementation<TestClassImpl>());
  component.resolveUsing(container).then((result) => print("got result $result"));
  Have a look at comonent_tests.dart for more details
  
- Lifestyle/Scope, for example Singleton/Transient/PerWebRequest