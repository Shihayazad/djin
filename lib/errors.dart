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

class NotResolveableError extends Error {
  String _message;
  String get message => _message;

  /** The [message] describes the erroneous argument. */
  NotResolveableError([this._message]);
  
  NotResolveableError.fromList(List<NotResolveableError> errors) {
    StringBuffer buffer = new StringBuffer();
    errors.forEach( (error) => buffer.add("${error.message}\n"));
    _message = buffer.toString();
  }

  String toString() {
    if (message != null) {
      return "Resolving not possible: $message";
    }
    return "Resolving not possible";
  }
}
