import 'dart:convert';
import 'package:get/get_connect.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../utility/constants.dart';

class HttpService {
  final String baseUrl = MAIN_URL;

  //? to send get request
  Future<Response> getItems({required String endpointUrl}) async {
    try {
      return await GetConnect().get('$baseUrl/$endpointUrl');
    } catch (e) {
      return Response(
          body: json.encode({'error': e.toString()}), statusCode: 500);
    }
  }

  //? to send post request
  Future<Response> addItem(
      {required String endpointUrl, required dynamic itemData}) async {
    try {
      final response =
          await GetConnect().post('$baseUrl/$endpointUrl', itemData);
      return response;
    } catch (e) {
      return Response(
          body: json.encode({'message': e.toString()}), statusCode: 500);
    }
  }

  //? to send put or update request
  Future<Response> updateItem(
      {required String endpointUrl,
      required String itemId,
      required dynamic itemData}) async {
    try {
      return await GetConnect().put('$baseUrl/$endpointUrl/$itemId', itemData);
    } catch (e) {
      return Response(
          body: json.encode({'message': e.toString()}), statusCode: 500);
    }
  }

  //? to send delete request

  Future<http.Response> deleteItem({
    required String endpointUrl,
    required String itemId,
    Map<String, String?>? itemData, // Optional parameter
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$endpointUrl/$itemId');

      // Send the DELETE request with a body using the HTTP package
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: itemData != null
            ? json.encode(itemData)
            : null, // Send itemData as body
      );

      return response;
    } catch (e) {
      return http.Response(json.encode({'message': e.toString()}), 500);
    }
  }
}
