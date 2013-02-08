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

abstract class InstanceHolder {
  bool hasInstance;
  Future instance;
}

class SingletonHolder implements InstanceHolder {
  Future _instance;
  
  bool get hasInstance => _instance != null;
  
  Future get instance => _instance;
  void set instance(Future value) {
    if(_instance != null) {
      throw new ArgumentError("instance already set");
    }
    _instance = value;
  } 
}

class TransientHolder implements InstanceHolder {
  bool get hasInstance => false;
  
  Future get instance => null;
  void set instance(Future value) {
  }
}