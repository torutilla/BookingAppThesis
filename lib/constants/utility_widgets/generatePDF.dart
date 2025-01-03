import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:pdf/widgets.dart';

class GeneratePDF {
  final pdf = Document();
  Future<Uint8List> generate(Document pdf) {
    print('Hotdog');
    return pdf.save();
  }

  void bark() {
    print('AW');
  }
}

class addPDFPage extends GeneratePDF {
  @override
  Future<Uint8List> generate(Document pdf) {
    pdf.addPage(Page(build: (context) {
      return Center(
        child: Text('Hotdog'),
      );
    }));
    return super.generate(pdf);
  }
}
