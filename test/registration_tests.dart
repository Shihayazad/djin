import 'package:unittest/unittest.dart';
import '../lib/djin.dart';

/// These are integration tests
void main() {
  test("shouldRegisterInContainer", registerInContainer);
}

class TestClass {
  
}


void registerInContainer() {
  Container container = new Container();
  Component sut = new Component<TestClass>();
  container.register(sut);
  expect(container.containsComponentFor("TestClass"), isTrue);
}

