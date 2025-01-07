import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/connect.dart';
import 'package:http/http.dart' as http;
import '../../../services/http_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:image_picker/image_picker.dart';
import '../../../core/data/data_provider.dart';
import '../../../models/poster.dart';
import '../../../utility/snack_bar_helper.dart';

class PosterProvider extends ChangeNotifier {
  HttpService service = HttpService();
  final DataProvider _dataProvider;
  final addPosterFormKey = GlobalKey<FormState>();
  TextEditingController posterNameCtrl = TextEditingController();
  Poster? posterForUpdate;

  File? selectedImage;
  XFile? imgXFile;

  PosterProvider(this._dataProvider);

  addPoster() async {
    try {
      if (selectedImage == null) {
        SnackBarHelper.showErrorSnackBar('Please Choose An Image!');
        return; // Stop execution if no image is selected
      }

      Map<String, dynamic> formDataMap = {
        'posterName': posterNameCtrl.text,
        'image': 'no_data', // Image path to be added server-side
      };

      final FormData form =
          await createFormData(imgXFile: imgXFile, formData: formDataMap);

      final response =
          await service.addItem(endpointUrl: 'posters/create', itemData: form);

      if (response.isOk) {
        // No more `success` check, directly parse and handle the response
        if (response.body != null && response.body['data'] != null) {
          clearFields();
          SnackBarHelper.showSuccessSnackBar(
              'Poster added successfully: ${response.body['msg']}');
          log('poster added');
          _dataProvider.getAllPosters();
        } else {
          // SnackBarHelper.showErrorSnackBar(
          //     'Failed to parse response: ${response.body}');
        }
      } else {
        // SnackBarHelper.showErrorSnackBar(
        //     'Error ${response.body?['message'] ?? response.statusText}');
      }
    } catch (e) {
      // SnackBarHelper.showErrorSnackBar('An error occurred: $e');
      rethrow;
    }
  }

  updatePoster() async {
    try {
      Map<String, dynamic> formDataMap = {
        'posterName': posterNameCtrl.text, // Updated poster name field
        'image': posterForUpdate?.imageUrl ?? '',
      };

      final FormData form =
          await createFormData(imgXFile: imgXFile, formData: formDataMap);

      final response = await service.updateItem(
          endpointUrl: 'posters',
          itemData: form,
          itemId: posterForUpdate?.sId ?? '');

      if (response.isOk) {
        // Removed success condition, directly check for response data
        if (response.body != null && response.body['data'] != null) {
          clearFields();
          SnackBarHelper.showSuccessSnackBar(
              'Poster updated successfully: ${response.body['msg']}');
          log('poster updated');
          _dataProvider.getAllPosters();
        } else {
          // SnackBarHelper.showErrorSnackBar(
          //     'Failed to parse response: ${response.body}');
        }
      } else {
        // SnackBarHelper.showErrorSnackBar(
        //     'Error ${response.body?['message'] ?? response.statusText}');
      }
    } catch (e) {
      // SnackBarHelper.showErrorSnackBar('An error occurred: $e');
      rethrow;
    }
  }

  submitPoster() {
    if (posterForUpdate != null) {
      updatePoster();
    } else {
      addPoster();
    }
  }

  deletePoster(Poster poster) async {
    try {
      if (poster.imageUrl == null || poster.imageUrl!.isEmpty) {
        SnackBarHelper.showErrorSnackBar(
            'Image URL is required to delete the poster.');
        return;
      }

      // Prepare the body with imageUrl to send in the request
      var body = {'imageUrl': poster.imageUrl};

      // Call deleteItem and send the imageUrl in the body of the request
      http.Response response = await service.deleteItem(
        endpointUrl: 'posters',
        itemId: poster.sId ?? '', // Poster ID
        itemData: body, // Send imageUrl in body
      );

      // Check the response status code and handle success/failure
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['msg'] == 'Poster deleted successfully.') {
          SnackBarHelper.showSuccessSnackBar('Poster Deleted Successfully');
          _dataProvider.getAllPosters(); // Fetch updated list of posters
        } else {
          SnackBarHelper.showErrorSnackBar(
              'Error: ${responseBody['error'] ?? responseBody}');
        }
      } else {
        SnackBarHelper.showErrorSnackBar(
            'Error: ${response.body}'); // Show the error message from the response body
      }
    } catch (e) {
      SnackBarHelper.showErrorSnackBar('An error occurred: $e');
      rethrow;
    }
  }

  //? to pick image for poster
  void pickImage() async {
    // Check if running on Windows or other platforms
    if (kIsWeb || Platform.isWindows) {
      // Using file_picker for Windows or Web
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null) {
        File? file = File(result.files.single.path!);
        selectedImage = file;
        imgXFile = XFile(file.path); // Converting the file to XFile
        notifyListeners();
      }
    } else {
      // Fallback to image_picker for mobile platforms
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedImage = File(image.path);
        imgXFile = image;
        notifyListeners();
      }
    }
  }

  //? to set data initially for updating poster form
  setDataForUpdatePoster(Poster? poster) {
    if (poster != null) {
      clearFields();
      posterForUpdate = poster;
      posterNameCtrl.text = poster.posterName ?? '';
    } else {
      clearFields();
    }
  }

  //? to create form data fir send image with data
  Future<FormData> createFormData(
      {required XFile? imgXFile,
      required Map<String, dynamic> formData}) async {
    if (imgXFile != null) {
      MultipartFile multipartFile;
      if (kIsWeb) {
        String fileName = imgXFile.name;
        Uint8List byteImg = await imgXFile.readAsBytes();
        multipartFile = MultipartFile(byteImg, filename: fileName);
      } else {
        String fileName = imgXFile.path.split('/').last;
        multipartFile = MultipartFile(imgXFile.path, filename: fileName);
      }
      formData['img'] = multipartFile;
    }
    final FormData form = FormData(formData);
    return form;
  }

  //? to clear images and text field after submit poster
  clearFields() {
    posterNameCtrl.clear();
    selectedImage = null;
    imgXFile = null;
    posterForUpdate = null;
  }
}
