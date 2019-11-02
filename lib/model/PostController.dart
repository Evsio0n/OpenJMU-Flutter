import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:extended_text/extended_text.dart';

import 'package:OpenJMU/api/API.dart';
import 'package:OpenJMU/api/PostAPI.dart';
import 'package:OpenJMU/constants/Constants.dart';
import 'package:OpenJMU/events/Events.dart';
import 'package:OpenJMU/model/Bean.dart';
import 'package:OpenJMU/model/SpecialText.dart';
import 'package:OpenJMU/pages/post/SearchPostPage.dart';
import 'package:OpenJMU/pages/user/UserPage.dart';
import 'package:OpenJMU/utils/ThemeUtils.dart';
import 'package:OpenJMU/api/UserAPI.dart';
import 'package:OpenJMU/widgets/CommonWebPage.dart';
import 'package:OpenJMU/widgets/cards/PostCard.dart';

class PostController {
  final String postType;
  final bool isFollowed;
  final bool isMore;
  final Function lastValue;
  final Map<String, dynamic> additionAttrs;

  PostController({
    @required this.postType,
    @required this.isFollowed,
    @required this.isMore,
    @required this.lastValue,
    this.additionAttrs,
  });

  _PostListState _postListState;

  Future reload() => _postListState._refreshData();
}

class PostList extends StatefulWidget {
  final PostController _postController;
  final bool needRefreshIndicator;

  PostList(this._postController, {Key key, this.needRefreshIndicator = true})
      : super(key: key);

  @override
  State createState() => _PostListState();

  PostList newController(_controller) => PostList(_controller);
}

class _PostListState extends State<PostList> {
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();
  Color currentColorTheme = ThemeUtils.currentThemeColor;

  int _lastValue = 0;
  bool _isLoading = false;
  bool _canLoadMore = true;
  bool _firstLoadComplete = false;
  bool _showLoading = true;

  Widget _itemList;

  Widget _emptyChild;
  Widget _errorChild;
  bool error = false;

  Widget _body = Center(
    child: Constants.progressIndicator(),
  );

  List<int> _idList = [];
  List<Post> _postList = [];

  @override
  void initState() {
    widget._postController._postListState = this;
    Instances.eventBus
      ..on<ScrollToTopEvent>().listen((event) {
        if (this.mounted &&
            ((event.tabIndex == 0 &&
                    widget._postController.postType == "square") ||
                (event.type == "首页"))) {
          _scrollController.jumpTo(0.0);
          Future.delayed(Duration(milliseconds: 50), () {
            refreshIndicatorKey.currentState.show();
          });
          Future.delayed(Duration(milliseconds: 500), () {
            _refreshData(needLoader: true);
          });
        }
      })
      ..on<PostChangeEvent>().listen((event) {
        if (event.remove) {
          if (mounted) {
            setState(() {
              _postList.removeWhere((post) => event.post.id == post.id);
            });
          }
        } else {
          if (mounted) {
            setState(() {
              var index = _postList.indexOf(event.post);
              _postList.replaceRange(index, index + 1, [event.post.copy()]);
            });
          }
        }
      })
      ..on<ChangeThemeEvent>().listen((event) {
        if (mounted) {
          setState(() {
            currentColorTheme = event.color;
          });
        }
      })
      ..on<PostDeletedEvent>().listen((event) {
        debugPrint(
            "PostDeleted: ${event.postId} / ${event.page} / ${event.index}");
        if (mounted && (event.page == "user") && event.index != null) {
          setState(() {
            _idList.removeAt(event.index);
            _postList.removeAt(event.index);
          });
        }
      });

    _emptyChild = GestureDetector(
      onTap: () {},
      child: Container(
        child: Center(
          child: Text('这里空空如也~', style: TextStyle(color: currentColorTheme)),
        ),
      ),
    );

    _errorChild = GestureDetector(
      onTap: () {
        setState(() {
          _isLoading = false;
          _showLoading = true;
          _refreshData();
        });
      },
      child: Container(
        child: Center(
          child: Text('加载失败，轻触重试', style: TextStyle(color: currentColorTheme)),
        ),
      ),
    );

    _refreshData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLoading) {
      if (_firstLoadComplete) {
        _itemList = ListView.separated(
          controller: widget._postController.postType == "user"
              ? null
              : _scrollController,
          padding: EdgeInsets.zero,
          separatorBuilder: (context, index) => Container(
            color: Theme.of(context).canvasColor,
            height: Constants.suSetSp(8.0),
          ),
          itemCount: _postList.length + 1,
          itemBuilder: (context, index) {
            if (index == _postList.length) {
              if (this._canLoadMore) {
                _loadData();
                return Container(
                  height: Constants.suSetSp(40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: Constants.suSetSp(15.0),
                        height: Constants.suSetSp(15.0),
                        child: Platform.isAndroid
                            ? CircularProgressIndicator(strokeWidth: 2.0)
                            : CupertinoActivityIndicator(),
                      ),
                      Text(
                        "　正在加载",
                        style: TextStyle(
                          fontSize: Constants.suSetSp(14.0),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  height: Constants.suSetSp(50.0),
                  color: Theme.of(context).canvasColor,
                  child: Center(
                    child: Text(
                      Constants.endLineTag,
                      style: TextStyle(
                        fontSize: Constants.suSetSp(14.0),
                      ),
                    ),
                  ),
                );
              }
            } else if (index < _postList.length) {
              return PostCard(
                _postList[index],
                fromPage: widget._postController.postType,
                index: index,
                isDetail: false,
              );
            } else {
              return Container();
            }
          },
        );

        _body = _postList.isEmpty
            ? (error ? _errorChild : _emptyChild)
            : _itemList;

        if (widget.needRefreshIndicator) {
          _body = RefreshIndicator(
            key: refreshIndicatorKey,
            color: currentColorTheme,
            onRefresh: _refreshData,
            child: _body,
          );
        }
      }
      return _body;
    } else {
      return Container(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  Future<Null> _loadData() async {
    _firstLoadComplete = true;
    if (!_isLoading && _canLoadMore) {
      _isLoading = true;

      Map result = (await PostAPI.getPostList(
        widget._postController.postType,
        widget._postController.isFollowed,
        true,
        _lastValue,
        additionAttrs: widget._postController.additionAttrs,
      ))
          .data;

      List<Post> postList = [];
      List _topics = result['topics'];
      int _total = int.parse(result['total'].toString());
      int _count = int.parse(result['count'].toString());

      for (var postData in _topics) {
        if (!UserAPI.blacklist.contains(jsonEncode({
          "uid": postData['topic']['user']['uid'].toString(),
          "username": postData['topic']['user']['nickname'],
        }))) {
          postList.add(PostAPI.createPost(postData['topic']));
          _idList.add(
            postData['id'] is String
                ? int.parse(postData['id'])
                : postData['id'],
          );
        }
      }
      _postList.addAll(postList);

      if (mounted) {
        setState(() {
          _showLoading = false;
          _firstLoadComplete = true;
          _isLoading = false;
          _canLoadMore = _idList.length < _total && _count != 0;
          _lastValue = _idList.isEmpty
              ? 0
              : widget._postController.lastValue(_idList.last);
        });
      }
    }
  }

  Future<Null> _refreshData({bool needLoader = false}) async {
    if (!_isLoading) {
      _isLoading = true;
      _lastValue = 0;

      Map result = (await PostAPI.getPostList(
        widget._postController.postType,
        widget._postController.isFollowed,
        false,
        _lastValue,
        additionAttrs: widget._postController.additionAttrs,
      ))
          .data;

      List<Post> postList = [];
      List<int> idList = [];
      List _topics = result['topics'] ?? result['data'];
      int _total = int.parse(result['total'].toString());
      int _count = int.parse(result['count'].toString());

      for (var postData in _topics) {
        if (postData['topic'] != null && postData != "") {
          if (!UserAPI.blacklist.contains(jsonEncode({
            "uid": postData['topic']['user']['uid'].toString(),
            "username": postData['topic']['user']['nickname'],
          }))) {
            postList.add(PostAPI.createPost(postData['topic']));
            idList.add(
              postData['id'] is String
                  ? int.parse(postData['id'])
                  : postData['id'],
            );
          }
        }
      }
      _postList = postList;

      if (needLoader) {
        if (idList.toString() != _idList.toString()) {
          _idList = idList;
        }
      } else {
        _idList = idList;
      }

      if (mounted) {
        setState(() {
          _showLoading = false;
          _firstLoadComplete = true;
          _isLoading = false;
          _canLoadMore = _idList.length < _total && _count != 0;
          _lastValue = _idList.isEmpty
              ? 0
              : widget._postController.lastValue(_idList.last);
        });
      }
    }
  }
}

class ForwardListInPostController {
  _ForwardListInPostState _forwardInPostListState;

  void reload() {
    _forwardInPostListState?._refreshData();
  }
}

class ForwardListInPost extends StatefulWidget {
  final Post post;
  final ForwardListInPostController forwardInPostController;

  ForwardListInPost(this.post, this.forwardInPostController, {Key key})
      : super(key: key);

  @override
  State createState() => _ForwardListInPostState();
}

class _ForwardListInPostState extends State<ForwardListInPost> {
  List<Post> _posts = [];

  bool isLoading = true;
  bool canLoadMore = false;
  bool firstLoadComplete = false;

  int lastValue;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshData() {
    setState(() {
      isLoading = true;
      _posts = [];
    });
    _refreshList();
  }

  Future<Null> _loadList() async {
    isLoading = true;
    try {
      Map<String, dynamic> response = (await PostAPI.getForwardListInPost(
              widget.post.id,
              isMore: true,
              lastValue: lastValue))
          ?.data;
      List<dynamic> list = response['topics'];
      int total = response['total'] as int;
      if (_posts.length + response['count'] as int < total) {
        canLoadMore = true;
      } else {
        canLoadMore = false;
      }
      List<Post> posts = [];
      list.forEach((post) {
        if (!UserAPI.blacklist.contains(jsonEncode({
          "uid": post['topic']['user']['uid'].toString(),
          "username": post['topic']['user']['nickname'],
        }))) {
          posts.add(PostAPI.createPost(post['topic']));
        }
      });
      if (this.mounted) {
        setState(() {
          _posts.addAll(posts);
        });
        isLoading = false;
        lastValue = _posts.isEmpty ? 0 : _posts.last.id;
      }
    } on DioError catch (e) {
      if (e.response != null) {
        debugPrint("${e.response.data}");
      } else {
        debugPrint("${e.request}");
        debugPrint("${e.message}");
      }
      return;
    }
  }

  Future<Null> _refreshList() async {
    setState(() {
      isLoading = true;
    });
    try {
      Map<String, dynamic> response =
          (await PostAPI.getForwardListInPost(widget.post.id))?.data;
      List<dynamic> list = response['topics'];
      int total = response['total'] as int;
      if (response['count'] as int < total) canLoadMore = true;
      List<Post> posts = [];
      list.forEach((post) {
        if (!UserAPI.blacklist.contains(jsonEncode({
          "uid": post['topic']['user']['uid'].toString(),
          "username": post['topic']['user']['nickname'],
        }))) {
          posts.add(PostAPI.createPost(post['topic']));
        }
      });
      if (this.mounted) {
        setState(() {
          Instances.eventBus
              .fire(new ForwardInPostUpdatedEvent(widget.post.id, total));
          _posts = posts;
          isLoading = false;
          firstLoadComplete = true;
        });
        lastValue = _posts.isEmpty ? 0 : _posts.last.id;
      }
    } on DioError catch (e) {
      if (e.response != null) {
        debugPrint("${e.response.data}");
      } else {
        debugPrint("${e.request}");
        debugPrint("${e.message}");
      }
      return;
    }
  }

  GestureDetector getPostAvatar(context, post) {
    return GestureDetector(
      child: Container(
        width: Constants.suSetSp(40.0),
        height: Constants.suSetSp(40.0),
        margin: EdgeInsets.symmetric(
            horizontal: Constants.suSetSp(16.0),
            vertical: Constants.suSetSp(10.0)),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFECECEC),
          image: DecorationImage(
              image: UserAPI.getAvatarProvider(uid: post.uid),
              fit: BoxFit.cover),
        ),
      ),
      onTap: () {
        return UserPage.jump(context, post.uid);
      },
    );
  }

  Text getPostNickname(context, post) => Text(
        post.nickname,
        style: TextStyle(
          color: Theme.of(context).textTheme.title.color,
          fontSize: Constants.suSetSp(18.0),
        ),
      );

  Text getPostTime(context, post) {
    String _postTime = post.postTime;
    DateTime now = DateTime.now();
    if (int.parse(_postTime.substring(0, 4)) == now.year) {
      _postTime = _postTime.substring(5, 16);
    }
    if (int.parse(_postTime.substring(0, 2)) == now.month &&
        int.parse(_postTime.substring(3, 5)) == now.day) {
      _postTime = "${_postTime.substring(5, 11)}";
    }
    return Text(
      _postTime,
      style: Theme.of(context)
          .textTheme
          .caption
          .copyWith(fontSize: Constants.suSetSp(14.0)),
    );
  }

  Widget getExtendedText(context, content) => ExtendedText(
        content != null ? "$content " : null,
        style: TextStyle(fontSize: Constants.suSetSp(17.0)),
        onSpecialTextTap: (dynamic data) {
          String text = data['content'];
          if (text.startsWith("#")) {
            SearchPage.search(context, text.substring(1, text.length - 1));
          } else if (text.startsWith("@")) {
            UserPage.jump(context, data['uid']);
          } else if (text.startsWith(API.wbHost)) {
            CommonWebPage.jump(context, text, "网页链接");
          }
        },
        specialTextSpanBuilder: StackSpecialTextSpanBuilder(),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      width: MediaQuery.of(context).size.width,
      padding: isLoading
          ? EdgeInsets.symmetric(vertical: Constants.suSetSp(42))
          : EdgeInsets.zero,
      child: isLoading
          ? Center(
              child: SizedBox(
              child: Constants.progressIndicator(),
            ))
          : Container(
              color: Theme.of(context).cardColor,
              padding: EdgeInsets.zero,
              child: firstLoadComplete
                  ? ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      separatorBuilder: (context, index) => Container(
                        color: Theme.of(context).dividerColor,
                        height: Constants.suSetSp(1.0),
                      ),
                      itemCount: _posts.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _posts.length) {
                          if (canLoadMore && !isLoading) {
                            _loadList();
                            return Container(
                              height: Constants.suSetSp(40.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(
                                    width: Constants.suSetSp(15.0),
                                    height: Constants.suSetSp(15.0),
                                    child: Constants.progressIndicator(
                                        strokeWidth: 2.0),
                                  ),
                                  Text("　正在加载",
                                      style: TextStyle(
                                          fontSize: Constants.suSetSp(14.0))),
                                ],
                              ),
                            );
                          } else {
                            return Container();
                          }
                        } else if (index < _posts.length) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              getPostAvatar(context, _posts[index]),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(height: Constants.suSetSp(10.0)),
                                    getPostNickname(context, _posts[index]),
                                    Container(height: Constants.suSetSp(4.0)),
                                    getExtendedText(
                                        context, _posts[index].content),
                                    Container(height: Constants.suSetSp(6.0)),
                                    getPostTime(context, _posts[index]),
                                    Container(height: Constants.suSetSp(10.0)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Container();
                        }
                      },
                    )
                  : Container(
                      height: Constants.suSetSp(120.0),
                      child: Center(
                        child: Text("暂无内容",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: Constants.suSetSp(18.0))),
                      ),
                    ),
            ),
    );
  }
}
