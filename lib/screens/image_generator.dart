import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../services/api_service.dart';
import '../widgets/main_drawer.dart';
import '../widgets/text_widget.dart';
import 'my_gallery.dart';

class ImageGenerator extends StatefulWidget {
  static const String routeName = '/Image_generator';
  const ImageGenerator({Key? key}) : super(key: key);

  @override
  State<ImageGenerator> createState() => _ImageGeneratorState();
}

class _ImageGeneratorState extends State<ImageGenerator> {

  var sizes = ["Small","Medium","Large"];
  var values = ["256x256","512x512","1024x1024"];
  String? dropValue;
  String image = '';
  bool isLoading = false;
  bool isLoaded = false;
  
  ScreenshotController screenshotController = ScreenshotController();
  var textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }


  downloadImage() async {
    var result = await Permission.storage.request();

    if(result.isGranted) {
      const folderName = "AI Image Gallery";
      final path = Directory("storage/emulated/0/$folderName");
      final fileName = "AI_IMG_${DateTime.now().millisecondsSinceEpoch}.png";

      if(await path.exists()) {
        await screenshotController.captureAndSave(path.path,delay:
        const Duration(milliseconds: 100),fileName: fileName,pixelRatio: 1.0);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TextWidget(
              label: "Downloaded successfully!",
            ),
            backgroundColor: Colors.greenAccent,
          ),
        );
        print("Downloaded to ${path.path}");

      } else {
        await path.create();

        await screenshotController.captureAndSave(path.path,delay:
        const Duration(milliseconds: 100),fileName: fileName,pixelRatio: 1.0);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TextWidget(
              label: "Downloaded successfully!",
            ),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
      print("Downloaded to ${path.path}");

    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Permission Denied')));
    }
  }

  shareImage() async {
    await screenshotController.capture(delay:
    const Duration(milliseconds: 100),pixelRatio: 1.0).then((Uint8List? img) async {
      if(img != null) {
        final directory = (await getApplicationDocumentsDirectory()).path;
        const fileName = "share.png";
        final imgPath = await File("$directory/$fileName").create();
        await imgPath.writeAsBytes(img);

        Share.shareFiles([imgPath.path],text: "Generated by AI -- NextDigit");

      } else {
        print('Failed to take screenshot');
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: const Color(0xFFCCCCFF),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade500,
                  offset: const Offset(4, 4),
                  blurRadius: 15,
                  spreadRadius: 1
              ),
              const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 15,
                  spreadRadius: 1
              ),
            ],
        ),
        alignment: Alignment.center,
        height: 30,
        //color: const Color(0xFFCCCCFF),
        child: const Text("Developed By NextDigit",
          style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
      ),
      backgroundColor: const Color(0xFFCCCCFF),
      appBar: AppBar(
        //backgroundColor: const Color(0xFFCCCCFF),
        title: const Text("Image Generator"),
        //centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0FF),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> const MyGallery()));
                },
                child: const Text("My Arts",
                  style: TextStyle(fontSize: 16,color: Colors.black87),)
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 2,),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: "eg 'A dog with car'",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4,),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                          icon: const Icon(Icons.expand_more,color: Colors.black87,),
                          value: dropValue,
                          hint: const Text("Select size"),
                          items: List.generate(
                              sizes.length,
                              (index) => DropdownMenuItem(
                                value: values[index],
                                child: Text(sizes[index]),)),
                          onChanged: (values){
                            setState(() {
                              dropValue = values.toString();
                            });
                          },
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 15,),
                SizedBox(
                  width: 300,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      //shape: const StadiumBorder()
                    ),
                      onPressed: dropValue == null ?
                      null : () async {
                      if(textController.text.isNotEmpty && dropValue!.isNotEmpty) {
                        setState(() {
                          isLoading = true;
                          isLoaded = false;
                        });

                        try {
                          image = await Api.generateImage(textController.text, dropValue!);
                          setState(() {
                            isLoading = false;
                            isLoaded = true;
                            // dropValue = null;
                            // textController.clear();
                          });
                        } catch(e) {
                          return;
                        }

                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text("Please pass the query and size"),
                            backgroundColor: Colors.deepOrangeAccent,),);
                      }

                      },
                      child: const Text("Generate",
                        style: TextStyle(fontSize: 18),)
                  ),
                ),
                //const SizedBox(height: 10,),
              ],
            ),
            isLoading ? Expanded(
              flex: 6,
              child: Center(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Container(
                          width: 280,
                          decoration: BoxDecoration(
                              color: const Color(0xFFCCCCFF),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.indigo.shade500,
                                    offset: const Offset(4, 4),
                                    blurRadius: 15,
                                    spreadRadius: 1
                                ),
                                const BoxShadow(
                                    color: Colors.indigo,
                                    offset: Offset(-4, -4),
                                    blurRadius: 15,
                                    spreadRadius: 1
                                ),
                              ]
                          ),
                          child: Image.asset('assets/images/giphy.gif')),
                    ),
                    const SizedBox(height: 20,),
                    const Center(
                      child: Text('Waiting for image to be generated...',
                        style: TextStyle(fontSize: 18,fontWeight: FontWeight.w400),),
                    ),
                  ],
                ),
              ),
            ) : Container(),

            isLoaded ? Expanded(
              flex: 6,
              child: Center(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                          //clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                              color: const Color(0xFFCCCCFF),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.indigo.shade500,
                                    offset: const Offset(4, 4),
                                    blurRadius: 15,
                                    spreadRadius: 1
                                ),
                                const BoxShadow(
                                    color: Colors.indigo,
                                    offset: Offset(-4, -4),
                                    blurRadius: 15,
                                    spreadRadius: 1
                                ),
                              ]
                          ),
                          child: Screenshot(
                            controller: screenshotController,
                            child: Image.network(image,fit: BoxFit.contain,),
                          ),
                      ),
                    ),
                    const SizedBox(height: 20,),
                    Row(
                      children: [
                        Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                              ),
                              onPressed: () {
                                downloadImage();
                              },
                              label: const Text('Download',
                                style: TextStyle(fontSize: 18),),
                            )
                        ),
                        const SizedBox(width: 10,),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.share),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
                          ),
                          onPressed: () async {
                            await shareImage();
                          },
                          label: const Text('Share',
                            style: TextStyle(fontSize: 18),),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ) : Container(),
          ],
        ),
      ),
    );
  }
}
