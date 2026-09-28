import 'dart:io';

import 'package:flutter/material.dart';

Widget localImageThumb(String path, {double size = 48}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      File(path),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Icon(
        Icons.image_not_supported_outlined,
        size: size * 0.6,
      ),
    ),
  );
}
