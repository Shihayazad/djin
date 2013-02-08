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
library djin;

import 'dart:mirrors';
import 'dart:async';

part 'errors.dart';
part 'container.dart';
part 'lifestyles.dart';
part 'component.dart';
part 'component_implementation.dart';
part 'instance_holder.dart';

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

