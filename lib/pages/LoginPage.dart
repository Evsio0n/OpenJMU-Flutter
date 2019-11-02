import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'package:OpenJMU/api/API.dart';
import 'package:OpenJMU/constants/Configs.dart';
import 'package:OpenJMU/constants/Constants.dart';
import 'package:OpenJMU/pages/MainPage.dart';
import 'package:OpenJMU/utils/DataUtils.dart';
import 'package:OpenJMU/utils/ThemeUtils.dart';
import 'package:OpenJMU/utils/ToastUtils.dart';
import 'package:OpenJMU/widgets/CommonWebPage.dart';
import 'package:OpenJMU/widgets/RoundedCheckBox.dart';
import 'package:OpenJMU/widgets/announcement/AnnouncementWidget.dart';

class LoginPage extends StatefulWidget {
  final int initIndex;

  LoginPage({this.initIndex, Key key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _formScrollController = ScrollController();
  final TextEditingController _usernameController = TextEditingController(
    text: DataUtils.recoverWorkId(),
  );
  final TextEditingController _passwordController = TextEditingController();
  final List<Color> colorGradient = const <Color>[
    Color(0xffff8976),
    Color(0xffff3c33)
  ];

  String _username = DataUtils.recoverWorkId() ?? "", _password = "";

  bool _agreement = false;
  bool _login = false;
  bool _loginDisabled = true;
  bool _isObscure = true;
  bool _usernameCanClear = false;
  bool _keyboardAppeared = false;

  bool _isDark = false;
  Color _defaultIconColor = Colors.grey;

  @override
  void initState() {
    _usernameController
      ..addListener(() {
        if (this.mounted) {
          _username = _usernameController.text;
          if (_usernameController.text.length > 0 && !_usernameCanClear) {
            setState(() {
              _usernameCanClear = true;
            });
          } else if (_usernameController.text.length == 0 &&
              _usernameCanClear) {
            setState(() {
              _usernameCanClear = false;
            });
          }
        }
      });
    _passwordController
      ..addListener(() {
        if (this.mounted) {
          _password = _passwordController.text;
        }
      });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    ThemeUtils.setDark(_isDark);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _usernameController?.dispose();
    _passwordController?.dispose();
    super.dispose();
  }

  int last = 0;
  Future<bool> doubleBackExit() {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - last > 800) {
      showShortToast("再按一次退出应用");
      last = DateTime.now().millisecondsSinceEpoch;
      return Future.value(false);
    } else {
      cancelToast();
      return Future.value(true);
    }
  }

  Widget topBackground(context) {
    return Positioned(
      right: 0.0,
      top: 0.0,
      child: Image.asset(
        "images/login_top.png",
        width: MediaQuery.of(context).size.width - Constants.suSetSp(60.0),
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget bottomBackground(context) {
    return Positioned(
      left: 0.0,
      right: 0.0,
      bottom: 15.0,
      child: Center(
        child: Image.asset(
          "images/login_bottom.png",
          color: Colors.grey.withAlpha(50),
          width: MediaQuery.of(context).size.width - 150.0,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }

  Widget logo(context) {
    return Positioned(
      right: Constants.suSetSp(40.0),
      top: Constants.suSetSp(50.0),
      child: Hero(
        tag: "Logo",
        child: Image.asset(
          'images/ic_jmu_logo_trans.png',
          color: Theme.of(context).primaryColor.withAlpha(0x33),
          width: Constants.suSetSp(120.0),
          height: Constants.suSetSp(120.0),
        ),
      ),
    );
  }

  Widget logoTitle() {
//        final Shader linearGradient = LinearGradient(
//            colors: colorGradient,
//        ).createShader(Rect.fromLTWH(0.0, 0.0, 150, 60));
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      textBaseline: TextBaseline.ideographic,
      children: <Widget>[
        Stack(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(
                top: Constants.suSetSp(10.0),
                left: Constants.suSetSp(6.0),
                right: Constants.suSetSp(6.0),
              ),
              child: Text(
                "OPENJMU",
                style: TextStyle(
                  color: Theme.of(context).iconTheme.color,
                  fontSize: Constants.suSetSp(50.0),
                  fontFamily: "chocolate",
//                                    foreground: Paint()..shader = linearGradient,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget usernameTextField() {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.person,
          color: Theme.of(context).iconTheme.color,
          size: Constants.suSetSp(24.0),
        ),
        suffixIcon: _usernameCanClear
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Theme.of(context).iconTheme.color,
                  size: Constants.suSetSp(24.0),
                ),
                onPressed: _usernameController.clear,
              )
            : null,
        border: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: ThemeUtils.defaultColor,
          ),
        ),
        contentPadding: EdgeInsets.all(Constants.suSetSp(12.0)),
        labelText: '工号/学号',
        labelStyle: TextStyle(
          color: Theme.of(context).textTheme.title.color,
          fontSize: Constants.suSetSp(18.0),
        ),
      ),
      style: TextStyle(
        color: Theme.of(context).textTheme.title.color,
      ),
      strutStyle: StrutStyle(
        fontSize: Constants.suSetSp(18.0),
        height: Constants.suSetSp(1.7),
        forceStrutHeight: true,
      ),
      cursorColor: ThemeUtils.defaultColor,
      onSaved: (String value) => _username = value,
      validator: (String value) {
        if (value.isEmpty) return '请输入账户';
        return null;
      },
      keyboardType: TextInputType.number,
      enabled: !_login,
    );
  }

  Widget passwordTextField() {
    return TextFormField(
      controller: _passwordController,
      onSaved: (String value) => _password = value,
      obscureText: _isObscure,
      validator: (String value) {
        if (value.isEmpty) return '请输入密码';
        return null;
      },
      decoration: InputDecoration(
        border: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: ThemeUtils.defaultColor,
          ),
        ),
        contentPadding: EdgeInsets.all(Constants.suSetSp(12.0)),
        prefixIcon: Icon(
          Icons.lock,
          color: Theme.of(context).iconTheme.color,
          size: Constants.suSetSp(24.0),
        ),
        labelText: '密码',
        labelStyle: TextStyle(
          color: Theme.of(context).textTheme.title.color,
          fontSize: Constants.suSetSp(18.0),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility : Icons.visibility_off,
            color: _defaultIconColor,
            size: Constants.suSetSp(24.0),
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
              _defaultIconColor =
                  _isObscure ? Colors.grey : ThemeUtils.defaultColor;
            });
          },
        ),
      ),
      style: TextStyle(
        color: Theme.of(context).textTheme.title.color,
      ),
      strutStyle: StrutStyle(
        fontSize: Constants.suSetSp(18.0),
        height: Constants.suSetSp(1.7),
        forceStrutHeight: true,
      ),
      cursorColor: ThemeUtils.defaultColor,
      enabled: !_login,
    );
  }

  Padding noAccountButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.center,
        child: FlatButton(
          padding: EdgeInsets.all(0.0),
          child: Text(
            '没有账号',
            style: TextStyle(
              color: Colors.grey,
              fontSize: Constants.suSetSp(16.0),
            ),
          ),
          onPressed: () {},
        ),
      ),
    );
  }

  Padding findWorkId(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.center,
        child: FlatButton(
          padding: EdgeInsets.all(0.0),
          child: Text(
            '查询工号',
            style: TextStyle(
              color: Colors.grey,
              fontSize: Constants.suSetSp(16.0),
            ),
          ),
          onPressed: () {
            CommonWebPage.jump(
              context,
              "http://myid.jmu.edu.cn/ids/EmployeeNoQuery.aspx",
              "集大通行证 - 工号查询",
            );
          },
        ),
      ),
    );
  }

  Padding forgetPasswordButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.center,
        child: FlatButton(
          padding: EdgeInsets.all(0.0),
          child: Text(
            '忘记密码',
            style: TextStyle(
              color: Colors.grey,
              fontSize: Constants.suSetSp(16.0),
            ),
          ),
          onPressed: resetPassword,
        ),
      ),
    );
  }

  Widget userAgreementCheckbox(context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        RoundedCheckbox(
          value: _agreement,
          inactiveColor: Theme.of(context).iconTheme.color,
          onChanged: !_login
              ? (value) {
                  setState(() {
                    _agreement = value;
                  });
                  validateForm();
                }
              : null,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: "《用户协议》",
                style: TextStyle(
                  color: ThemeUtils.defaultColor,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    return CommonWebPage.jump(
                      context,
                      "${API.homePage}/license.html",
                      "OpenJMU 用户协议",
                    );
                  },
              ),
            ],
            style: TextStyle(fontSize: Constants.suSetSp(15.0)),
          ),
        ),
      ],
    );
  }

  Widget loginButton(context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_login || _loginDisabled) {
          return null;
        } else {
          loginButtonPressed(context);
        }
      },
      child: Container(
        width: Constants.suSetSp(120.0),
        height: Constants.suSetSp(50.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Constants.suSetSp(6.0)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              blurRadius: Constants.suSetSp(10.0),
              color: colorGradient[1].withAlpha(50),
              offset: Offset(0.0, Constants.suSetSp(10.0)),
            ),
          ],
          gradient: LinearGradient(colors: colorGradient),
        ),
        child: Center(
          child: !_login
              ? Icon(
                  Icons.arrow_forward,
                  size: Constants.suSetSp(24.0),
                  color: Colors.white,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: Constants.suSetSp(24.0),
                      height: Constants.suSetSp(24.0),
                      child: Constants.progressIndicator(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget loginForm(context) {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: Align(
          alignment:
              _keyboardAppeared ? Alignment.bottomCenter : Alignment.center,
          child: ListView(
            shrinkWrap: true,
            controller: _formScrollController,
            padding: EdgeInsets.symmetric(horizontal: Constants.suSetSp(50.0)),
            physics:
                NeverScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            children: <Widget>[
              logoTitle(),
              Constants.emptyDivider(height: Constants.suSetSp(40.0)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Constants.suSetSp(10.0),
                  vertical: Constants.suSetSp(10.0),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Constants.suSetSp(6.0)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      blurRadius: 20.0,
                      color: Theme.of(context).dividerColor,
                    ),
                  ],
                  color: Theme.of(context).cardColor,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (Configs.announcementsEnabled)
                      AnnouncementWidget(
                        context,
                        radius: 6.0,
                      ),
                    usernameTextField(),
                    Constants.emptyDivider(height: Constants.suSetSp(10.0)),
                    passwordTextField(),
                    Constants.emptyDivider(height: Constants.suSetSp(10.0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
//                                                noAccountButton(context),
                        findWorkId(context),
                        forgetPasswordButton(context),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: Constants.suSetSp(20.0)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    userAgreementCheckbox(context),
                    loginButton(context),
                  ],
                ),
              ),
              Constants.emptyDivider(height: Constants.suSetSp(30.0)),
            ],
          ),
        ),
        onChanged: validateForm,
      ),
    );
  }

  void loginButtonPressed(context) {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      setState(() {
        _login = true;
      });
      DataUtils.login(context, _username, _password).then((result) {
        if (result) {
          Constants.navigatorKey.currentState.pushAndRemoveUntil(
            platformPageRoute(
              context: context,
              builder: (_) => MainPage(initIndex: widget.initIndex),
            ),
            (_) => false,
          );
        } else {
          _login = false;
          if (mounted) setState(() {});
        }
      }).catchError((e) {
        _login = false;
        if (mounted) setState(() {});
      });
    }
  }

  void resetPassword() async {
    return showPlatformDialog<Null>(
      context: context,
      builder: (BuildContext dialogContext) {
        return PlatformAlertDialog(
          title: Text('忘记密码'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('找回密码详见'),
                Text('网络中心主页 -> 集大通行证'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('返回'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            FlatButton(
              child: Text('查看'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                return CommonWebPage.jump(
                  context,
                  "https://net.jmu.edu.cn/info/1309/2476.htm",
                  "集大通行证登录说明",
                  withCookie: false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void validateForm() {
    if (_username != "" && _password != "" && _agreement && _loginDisabled) {
      setState(() {
        _loginDisabled = false;
      });
    } else if (_username == "" || _password == "" || !_agreement) {
      setState(() {
        _loginDisabled = true;
      });
    }
  }

  void setAlignment(context) {
    final double inputMethodHeight = MediaQuery.of(context).viewInsets.bottom;
    if (inputMethodHeight > 1.0 && !_keyboardAppeared) {
      setState(() {
        _keyboardAppeared = true;
      });
    } else if (inputMethodHeight <= 1.0 && _keyboardAppeared) {
      setState(() {
        _keyboardAppeared = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    setAlignment(context);
    return WillPopScope(
      onWillPop: doubleBackExit,
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Stack(
          children: <Widget>[
            topBackground(context),
            bottomBackground(context),
            logo(context),
            loginForm(context),
          ],
        ),
        resizeToAvoidBottomInset: true,
      ),
    );
  }
}
