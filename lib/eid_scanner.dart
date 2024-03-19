import 'dart:io';

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:intl/intl.dart';

class EIDScanner {
  /// this method will process the images and extract information from the card
  static Future<EmirateIdModel?> scanEmirateId({
    required File image,
  }) async {
    List<String> eIdDates = [];
    String? faceImagePath;

    // GoogleMlKit vision languageModelManager
    TextDetector textDetector = GoogleMlKit.vision.textDetector();
    final RecognisedText recognisedText = await textDetector.processImage(
      InputImage.fromFilePath(image.path),
    );

    // Face detection
    final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
    final List<Face> faces = await faceDetector.processImage(
      InputImage.fromFilePath(image.path),
    );

    // to check if it is an Emirate Card
    if (!recognisedText.text.toString().toLowerCase().contains("Resident Identity Card".toLowerCase()) &&
        !recognisedText.text.toString().toLowerCase().contains("UNITED ARAB EMIRATES".toLowerCase())) {
      return null;
    }

    final listText = recognisedText.text.split('\n');

    // attributes
    String? name;
    String? number;
    String? nationality;
    String? sex;

    listText.forEach((element) {
      if (_isDate(text: element.trim())) {
        eIdDates.add(element.trim());
      } else if (_isName(text: element.trim()) != null) {
        name = _isName(text: element.trim());
      } else if (_isNationality(text: element.trim()) != null) {
        nationality = _isNationality(text: element.trim());
      } else if (_isSex(text: element.trim()) != null) {
        sex = _isSex(text: element.trim());
      } else if (_isNumberID(text: element.trim())) {
        number = element.trim();
      }
    });

    eIdDates = _sortDateList(dates: eIdDates);

    textDetector.close();
    faceDetector.close();

    return EmirateIdModel(
      name: name!,
      number: number!,
      nationality: nationality,
      sex: sex,
      dateOfBirth: eIdDates.length == 3 ? eIdDates[0] : null,
      issueDate: eIdDates.length == 3 ? eIdDates[1] : null,
      expiryDate: eIdDates.length == 3 ? eIdDates[2] : null,
      faceImagePath: faceImagePath,
    );
  }

  /// it will sort the dates
  static List<String> _sortDateList({required List<String> dates}) {
    List<DateTime> tempList = [];
    DateFormat format = DateFormat("dd/MM/yyyy");
    for (int i = 0; i < dates.length; i++) {
      tempList.add(format.parse(dates[i]));
    }
    tempList.sort((a, b) => a.compareTo(b));
    dates.clear();
    for (int i = 0; i < tempList.length; i++) {
      dates.add(format.format(tempList[i]));
    }
    return dates;
  }

  /// it will sort the dates
  static bool _isDate({required String text}) {
    RegExp pattern = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    return pattern.hasMatch(text);
  }

  /// it will get the value of sex
  static String? _isSex({required String text}) {
    return text.startsWith("Sex:") ? text.split(":").last.trim() : null;
  }

  /// it will get the value of name
  static String? _isName({required String text}) {
    return text.startsWith("Name:") ? text.split(":").last.trim() : null;
  }

  /// it will get the value of Nationality
  static String? _isNationality({required String text}) {
    return text.startsWith("Nationality:") ? text.split(":").last.trim() : null;
  }

  /// it will get the value of Number ID
  static bool _isNumberID({required String text}) {
    RegExp pattern = RegExp(r'^\d{3}-\d{4}-\d{7}-\d{1}$');
    return pattern.hasMatch(text);
  }
}

/// this class is used to store data from package and display data on user screen
class EmirateIdModel {
  late String name;
  late String number;
  late String? issueDate;
  late String? expiryDate;
  late String? dateOfBirth;
  late String? nationality;
  late String? sex;
  late String? faceImagePath;

  EmirateIdModel({
    required this.name,
    required this.number,
    this.issueDate,
    this.expiryDate,
    this.dateOfBirth,
    this.nationality,
    this.sex,
    this.faceImagePath,
  });

  @override
  String toString() {
    var string = '';
    string += name.isEmpty ? "" : 'Holder Name = $name\n';
    string += number.isEmpty ? "" : 'Number = $number\n';
    string += expiryDate == null ? "" : 'Expiry Date = $expiryDate\n';
    string += issueDate == null ? "" : 'Issue Date = $issueDate\n';
    string += expiryDate == null ? "" : 'Cnic Holder DoB = $expiryDate\n';
    string += nationality == null ? "" : 'Nationality = $nationality\n';
    string += sex == null ? "" : 'Sex = $sex\n';
    return string;
  }
}
