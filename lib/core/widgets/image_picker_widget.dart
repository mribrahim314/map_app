import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class ImagePickerWidget extends StatefulWidget {
  ImagePickerWidget({
    Key? key,
    required this.onImagePicked,
    required this.onImageRemoved,
    required this.imageFile,
    this.imageURL,
  }) : super(key: key);
  File? imageFile;
  String? imageURL;
  void Function() onImagePicked; // Callback
  void Function() onImageRemoved;
  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: widget.imageURL!=null?() {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.zero,
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pop(context), // Tap to dismiss
                  child: Hero(
                    tag:
                        widget.imageURL!, // Optional: for smooth transition if you use Hero elsewhere
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              child: Image.network(
                                widget.imageURL!,
                                fit: BoxFit.contain,
                                loadingBuilder:
                                    (context, child, progress) {
                                      if (progress == null)
                                        return child;
                                      return const Center(
                                        child:
                                            CircularProgressIndicator(),
                                      );
                                    },
                              ),
                            ),
                            Positioned(
                              top: 40,
                              left: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } 
         : widget.imageFile == null ? widget.onImagePicked : null,
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            dashPattern: const [10, 4],
            color: Colors.grey,
            strokeWidth: 1.5,
            radius: const Radius.circular(12),
          ),

          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.imageURL != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.imageURL!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: widget.onImageRemoved,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  )
                : widget.imageFile == null
                ? const Center(
                    child: Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          widget.imageFile!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: widget.onImageRemoved,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
