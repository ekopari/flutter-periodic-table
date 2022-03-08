import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ParagraphDebug extends StatelessWidget {
  ParagraphDebug({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(200, 200),
      painter: _ParagraphPainter(),
    );
  }
}

class _ParagraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    ParagraphStyle paragraphStyle = ParagraphStyle(
      fontSize: 30,
      fontFamily: "Parisienne",
    );
    ParagraphBuilder paragraphBuilder = ParagraphBuilder(paragraphStyle);
    paragraphBuilder.pushStyle(ui.TextStyle(color: Colors.white));
    paragraphBuilder.addText("d");
    var paragraph = paragraphBuilder.build();
    paragraph.layout(ParagraphConstraints(width: 100));
    double letterWidth = paragraph.longestLine;
    canvas.drawParagraph(paragraph, Offset.zero);
    ParagraphStyle superscriptStyle = ParagraphStyle(
      fontSize: 20,
      fontFamily: "Parisienne",
    );
    ParagraphBuilder superscriptBuilder = ParagraphBuilder(superscriptStyle);
    superscriptBuilder.pushStyle(ui.TextStyle(
      color: Colors.white,
    ));
    superscriptBuilder.addText("10");
    var superscript = superscriptBuilder.build();
    superscript.layout(ParagraphConstraints(width: 100));
    canvas.drawParagraph(superscript, Offset(letterWidth * 1.3, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
