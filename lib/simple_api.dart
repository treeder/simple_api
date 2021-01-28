library simple_api;

import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as auth;

class APIError {
  int code;
  String message;
  APIError(this.message, this.code);

  String toString() {
    if (code != null && code > 0) {
      return "$code - $message";
    }
    return "$message";
  }
}

/// A Calculator.
class SimpleAPI {
  static Future<Map<String, String>> headers() async {
    // auth.User user = Globals.currentUser();
    var user = auth.FirebaseAuth.instance.currentUser;
    var h = {'Content-Type': 'application/json'};
    if (user == null) {
      // print("USER IS NULL! Should redirect here to login.");
      // NavigationService.instance().navigateTo('/');
      return h;
    }
    String idToken = await user.getIdToken();
    h[HttpHeaders.authorizationHeader] = "Bearer " + idToken;
    return h;
  }

  // ALMOST ALL METHODS SHOULD USE THIS
  // EXAMPLE: return await Api.call("POST", url, body: reqBody, fromJson: UserAndMember.fromJsonStatic) as UserAndMember;
  // if fromJson is not defined, this will return a Map<String, dynamic>
  // rootPath will skip a level in json
  static Future call(String method, String url,
      {dynamic body, Function fromJson, String rootPath, bool list}) async {
    var req = http.Request(method, Uri.parse(url));
    req.headers.addAll(await headers());
    if (body != null) {
      var x = jsonEncode(body);
      print("ENCODED");
      print(x);
      req.body = x;
    }
    http.Response response;
    try {
      var streamedResponse = await req.send();
      response = await http.Response.fromStream(streamedResponse);
    } catch (err) {
      // probably bad connection or something
      throw "Error connecting to API: $err";
    }
    if (response.statusCode == 404) {
      throw "404 not found";
    }
    var jsonmap;
    try {
      jsonmap = json.decode(response.body);
    } catch (err) {
      print("ERROR decoding json: $err");
      // if (response.statusCode != 200) {
      throw "${response.statusCode} ${response.body}";
      // }
      // throw err;
    }
    print('jsonmap: ' + response.body);
    if (response.statusCode != 200) {
      // resp.error = ErrorResponse.fromJson(jsonmap['error']);
      // return resp;
      throw jsonmap['error']['message'];
    }
    // If the server did return a 200 OK response, then parse the JSON.
    if (rootPath != null && rootPath != "") {
      jsonmap = jsonmap[rootPath];
    }
    if (fromJson != null) {
      if (list ?? false) {
        return List.from(jsonmap.map((model) => fromJson(model)));
      }
      print("about to fromJson");
      return fromJson(jsonmap);
    }

    return jsonmap;
  }

  static Future<T> post<T>(String url,
      {dynamic body, Function fromJson, String rootPath}) async {
    var ret = await call('POST', url,
        body: body, fromJson: fromJson, rootPath: rootPath);
    print("got response");
    print(ret.runtimeType);
    print(ret);
    return ret as T;
  }

  static Future delete(String url,
      {dynamic body, Function fromJson, String rootPath}) async {
    var ret = await call('DELETE', url,
        body: body, fromJson: fromJson, rootPath: rootPath);
    print("got delete response");
    print(ret.runtimeType);
    print(ret);
    return ret;
  }

  static Future<T> get<T>(String url,
      {dynamic body, Function fromJson, String rootPath}) async {
    return await call('GET', url,
        body: body, fromJson: fromJson, rootPath: rootPath) as T;
  }

  static Future<List<T>> getList<T>(String url,
      {dynamic body, Function fromJson, String rootPath}) async {
    var ret = await call('GET', url,
        body: body, fromJson: fromJson, rootPath: rootPath, list: true);
    print("got response getList");
    print(ret.runtimeType);
    print(ret);
    return ret.cast<T>(); //as List<T>;
  }
}
