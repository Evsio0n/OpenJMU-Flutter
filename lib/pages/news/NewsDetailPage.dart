import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:OpenJMU/api/NewsAPI.dart';
import 'package:OpenJMU/constants/Constants.dart';
import 'package:OpenJMU/model/Bean.dart';

class NewsDetailPage extends StatefulWidget {
  final News news;

  const NewsDetailPage({Key key, this.news}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  String pageContent;
  bool _contentLoaded = false;

  @override
  void initState() {
    super.initState();
    getNewsContent();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getNewsContent() async {
    Map<String, dynamic> data =
        (await NewsAPI.getNewsContent(newsId: widget.news.id)).data;
    pageContent = """<!DOCTYPE html>
                <html>
                    <head>
                        <meta charset="UTF-8" />
                        <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,shrink-to-fit=no" />'
                        <title>${widget.news.title}</title>
                    </head>
                    <body>${data['content']}</body>
                </html>
            """;
    pageContent = Uri.dataFromString(
      pageContent,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    ).toString();
    _contentLoaded = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.news.title,
          style: Theme.of(context).textTheme.title.copyWith(
                fontSize: Constants.suSetSp(21.0),
              ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: (pageContent != null && _contentLoaded)
          ? WebviewScaffold(
              url: pageContent,
              allowFileURLs: true,
              enableAppScheme: true,
              withJavascript: true,
              withLocalStorage: true,
              resizeToAvoidBottomInset: true,
            )
          : Center(child: Constants.progressIndicator()),
    );
  }
}
