import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GradientDebug extends StatefulWidget {
  const GradientDebug({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GradientDebugState();
  }
}

class _GradientDebugState extends State<GradientDebug> with SingleTickerProviderStateMixin {
  double time = 0;
  late Ticker ticker;

  @override
  void initState() {
    super.initState();
    ticker = createTicker((elapsed) {
      setState(() {
        time = elapsed.inMilliseconds.toDouble() / 1000;
      });
    });
    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: CustomPaint(
        size: const Size(1000, 700),
        painter: _VertexPainter(time: time),
      ),
    );
  }
}

class _GradientPainter extends CustomPainter {
  final double time;
  _GradientPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    double gradientAngle = time / 3;
    Alignment gradientStart = Alignment(sin(time), cos(time));
    Alignment gradientEnd = gradientStart + Alignment(sin(gradientAngle), cos(gradientAngle));

    var gradient = LinearGradient(
      colors: [
        Colors.red.shade200,
        Colors.yellow,
        Colors.purple.shade300,
        Colors.grey.shade300,
        Colors.blue.shade100,
        Colors.red.shade200
      ],
      begin: gradientStart,
      end: gradientEnd,
      tileMode: TileMode.repeated,
    );
    var rect = Rect.fromLTRB(0, 0, size.width, size.height);
    var paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_GradientPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

class _VertexPainter extends CustomPainter {
  double time;

  double get cellSize {
    return 1;
  }

  _VertexPainter({required this.time});

  Float32List _createTriangles(Size size) {
    int numCols = size.width ~/ cellSize;
    int numRows = size.height ~/ cellSize;
    double xStep = cellSize;
    double yStep = cellSize;
    Float32List triangles = Float32List(numCols * numRows * 12);
    int x = 0;
    int i = 0;
    while (x < numCols) {
      double leftX = x * xStep;
      double rightX = leftX + xStep;
      int y = 0;
      while (y < numRows) {
        double topY = y * yStep;
        double bottomY = topY + yStep;
        triangles[i] = leftX;
        i++;
        triangles[i] = topY;
        i++;
        triangles[i] = rightX;
        i++;
        triangles[i] = topY;
        i++;
        triangles[i] = leftX;
        i++;
        triangles[i] = bottomY;
        i++;
        triangles[i] = rightX;
        i++;
        triangles[i] = topY;
        i++;
        triangles[i] = rightX;
        i++;
        triangles[i] = bottomY;
        i++;
        triangles[i] = leftX;
        i++;
        triangles[i] = bottomY;
        i++;
        y++;
      }
      x++;
    }
    return triangles;
  }

  Float32List _createTextureCoords(Size size) {
    int numCols = size.width ~/ cellSize;
    int numRows = size.height ~/ cellSize;
    double xStep = cellSize;
    double yStep = cellSize;
    Float32List triangles = Float32List(numCols * numRows * 12);
    int x = 0;
    int i = 0;
    while (x < numCols) {
      double leftX = x * xStep;
      double rightX = leftX + xStep;
      int y = 0;
      while (y < numRows) {
        double topY = y * yStep;
        double bottomY = topY + yStep;

        // double leftXM = leftX + 30 * sin(time) * sin(topY / 30);
        // double rightXM = rightX + 7 * cos(rightX / 170) * sin(bottomY / 7);
        // double topYM = topY + 15 * sin(leftX / 37);
        // double bottomYM = bottomY + 15 * sin(leftX / 37);
        double leftXM = leftX + 30 * sin(time) * sin(topY / 30);
        double rightXM = rightX + 7 * cos(rightX / 170) * sin(bottomY / 7);
        double topYM = topY + 70 * sin(leftX / 77) * cos(topY / 133);
        double bottomYM = bottomY + 70 * sin(leftX / 77) * cos(topY / 133);
        // double leftXM = leftX;
        // double rightXM = rightX;
        // double topYM = topY;
        // double bottomYM = bottomY;
        // leftXM /= 5;
        // rightXM /= 5;
        // bottomYM /= 5;
        // topYM /= 5;

        triangles[i] = leftXM;
        i++;
        triangles[i] = topYM;
        i++;
        triangles[i] = rightXM;
        i++;
        triangles[i] = topYM;
        i++;
        triangles[i] = leftXM;
        i++;
        triangles[i] = bottomYM;
        i++;
        triangles[i] = rightXM;
        i++;
        triangles[i] = topYM;
        i++;
        triangles[i] = rightXM;
        i++;
        triangles[i] = bottomYM;
        i++;
        triangles[i] = leftXM;
        i++;
        triangles[i] = bottomYM;
        i++;
        y++;
      }
      x++;
    }
    return triangles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    ui.Vertices vertices;
    //vertices = ui.Vertices(ui.VertexMode.triangles,
    //    [Offset.zero, Offset(100, 0), Offset(0, 100), Offset(100, 0), Offset(100, 100), Offset(0, 100)]);
    vertices =
        ui.Vertices.raw(VertexMode.triangles, _createTriangles(size), textureCoordinates: _createTextureCoords(size));
    double gradientAngle = time / 3;
    //double gradientAngle = pi / 4;
    Alignment gradientEnd = Alignment(sin(gradientAngle), cos(gradientAngle));
    //gradientEnd = Alignment(gradientEnd.x / size.width, gradientEnd.y / size.height);
    //gradientEnd *= 1100;

    var gradient = LinearGradient(
      colors: [
        Colors.red.shade200,
        Colors.yellow,
        Colors.purple.shade300,
        Colors.grey.shade300,
        Colors.blue.shade100,
        Colors.red.shade200
      ],
      begin: const Alignment(0, 0),
      end: gradientEnd,
      tileMode: TileMode.repeated,
    );
    var rect = Rect.fromLTRB(0, 0, max(size.width, size.height), max(size.width, size.height));
    var paint = Paint()
      ..style = ui.PaintingStyle.fill
      ..shader = gradient.createShader(rect);
    canvas.drawVertices(vertices, BlendMode.srcATop, paint);
  }

  @override
  bool shouldRepaint(_VertexPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
