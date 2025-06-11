import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _color = 'Red';

class Interfacetheme extends StatefulWidget {
  const Interfacetheme({Key? key}) : super(key: key);

  @override
  _InterfacethemeState createState() => _InterfacethemeState();
}

class _InterfacethemeState extends State<Interfacetheme> {
  Widget _interfacethemechoices(String name, String imagepath, String value) {
    return Column(
      children: [
        SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _color = value),
          child: Container(
            height: 100,
            // width: 100,
            // color: _value == 0 ? Colors.grey : Colors.transparent,
            margin: const EdgeInsets.all(15.0),
            padding: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: Colors.grey[200],
                border: Border.all(
                    color: _color == value ? Colors.grey : Colors.transparent,
                    width: 3)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Image(image: AssetImage(imagepath)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final _themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.interface_theme,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            size: 25,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              SizedBox(height: 4),
              _interfacethemechoices(
                  AppLocalizations.of(context)!.theme_red, 'assets/interfacethemered.jpeg', 'Red'),
              _interfacethemechoices(
                  AppLocalizations.of(context)!.theme_yellow, 'assets/interfacethemeyellow.jpeg', 'Yellow'),
              _interfacethemechoices(
                  AppLocalizations.of(context)!.theme_green, 'assets/interfacethemegreen.jpeg', 'Green'),
              _interfacethemechoices(
                  AppLocalizations.of(context)!.theme_blue, 'assets/interfacethemeblue.jpeg', 'Blue'),
              Material(
                  // elevation: 5.0,
                  borderRadius: BorderRadius.circular(5.0),
                  color: Theme.of(context).primaryColor,
                  child: MaterialButton(
                    minWidth: (MediaQuery.of(context).size.width - 280),
                    // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    onPressed: () async {
                      onThemeChanged(_color, _themeNotifier);
                      final prefs = await SharedPreferences.getInstance();

                      if (_color == 'Red') {
                        prefs.setString('theme', 'Redtheme');
                      } else if (_color == 'Yellow') {
                        prefs.setString('theme', 'yellowtheme');
                      } else if (_color == 'Green') {
                        prefs.setString('theme', 'greentheme');
                      } else if (_color == 'Blue') {
                        prefs.setString('theme', 'bluetheme');
                      } else {
                        prefs.setString('theme', 'Redtheme');
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context)!.theme_apply,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void onThemeChanged(String value, ThemeNotifier themeNotifier) async {
    // (value)
    //     ? themeNotifier.setTheme(darkTheme)
    //     : themeNotifier.setTheme(lightTheme);

    if (value == 'Red') {
      themeNotifier.setTheme(RedTheme);
    } else if (value == 'Yellow') {
      themeNotifier.setTheme(yellowTheme);
    } else if (value == 'Green') {
      themeNotifier.setTheme(greentheme);
    } else if (value == 'Blue') {
      themeNotifier.setTheme(blueTheme);
    } else {
      themeNotifier.setTheme(RedTheme);
    }

    // var prefs = await SharedPreferences.getInstance();
    // prefs.setBool('darkMode', value);
  }
}

final yellowTheme = ThemeData(
    // Define the default brightness and colors.
    // brightness: Brightness.dark,
    primaryColor: Colors.yellow[700],
    // primaryColor: Colors.yellow[700],
    // Define the default font family.
    fontFamily: 'Gilroy',

    // Define the default TextTheme. Use this to specify the default
    // text styling for headlines, titles, bodies of text, and more.
    textTheme:
        TextTheme(
      displayLarge: TextStyle(
          fontSize: 24.0,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.bold,
          color: Colors.black,
          letterSpacing: 1),
      displayMedium: TextStyle(
          // fontSize: 20.0,
          fontSize: 14,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          // color: Colors.black,
          color: Colors.white,
          letterSpacing: 1),
      displaySmall: TextStyle(
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.black,
          letterSpacing: 1),
      headlineMedium: TextStyle(
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.blue,
          letterSpacing: 1),
      headlineSmall: TextStyle(
          fontSize: 16.0,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.bold,
          color: Color(0xffE51837),
          letterSpacing: 1),
      titleLarge: TextStyle(
          fontSize: 7.0,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.blue,
          letterSpacing: 1),
      titleMedium: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          letterSpacing: 1),
      titleSmall: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          letterSpacing: 1),
      bodyLarge: TextStyle(
          // fontSize: 12.0,
          fontSize: 8,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.black,
          letterSpacing: 1),
      bodyMedium: TextStyle(
          // fontSize: 10.0,120
          fontSize: 7,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          // fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 1),
    ));

final RedTheme = ThemeData(
  // Define the default brightness and colors.
  // brightness: Brightness.dark,
  primaryColor: Color(0xffE51837),
  // primaryColor: Colors.yellow[700],
  // Define the default font family.
  fontFamily: 'Gilroy',

  // Define the default TextTheme. Use this to specify the default
  // text styling for headlines, titles, bodies of text, and more.
  textTheme: TextTheme(
    displayLarge: TextStyle(
        fontSize: 24.0,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.bold,
        color: Colors.black,
        letterSpacing: 1),
    displayMedium: TextStyle(
        // fontSize: 20.0,
        fontSize: 14,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        // color: Colors.black,
        color: Colors.white,
        letterSpacing: 1),
    displaySmall: TextStyle(
        fontSize: 12,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.normal,
        color: Colors.black,
        letterSpacing: 1),
    headlineMedium: TextStyle(
        fontSize: 12,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.normal,
        color: Colors.blue,
        letterSpacing: 1),
    headlineSmall: TextStyle(
        fontSize: 16.0,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.bold,
        color: Color(0xffE51837),
        letterSpacing: 1),
    titleLarge: TextStyle(
        fontSize: 7.0,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.normal,
        color: Colors.blue,
        letterSpacing: 1),
    titleMedium: TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.normal,
        letterSpacing: 1),
    titleSmall: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.normal,
        letterSpacing: 1),
    bodyLarge: TextStyle(
        // fontSize: 12.0,
        fontSize: 8,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.normal,
        color: Colors.black,
        letterSpacing: 1),
    bodyMedium: TextStyle(
        // fontSize: 10.0,120
        fontSize: 7,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.normal,
        // fontWeight: FontWeight.bold,
        color: Colors.grey[700],
        letterSpacing: 1),
  ),
);

final greentheme = ThemeData(
    // Define the default brightness and colors.
    // brightness: Brightness.dark,
    primaryColor: Colors.green,
    // primaryColor: Colors.yellow[700],
    // Define the default font family.
    fontFamily: 'Gilroy',

    // Define the default TextTheme. Use this to specify the default
    // text styling for headlines, titles, bodies of text, and more.
    textTheme:
        TextTheme(
      displayLarge: TextStyle(
          fontSize: 24.0,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.bold,
          color: Colors.black,
          letterSpacing: 1),
      displayMedium: TextStyle(
          // fontSize: 20.0,
          fontSize: 14,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          // color: Colors.black,
          color: Colors.white,
          letterSpacing: 1),
      displaySmall: TextStyle(
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.black,
          letterSpacing: 1),
      headlineMedium: TextStyle(
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.blue,
          letterSpacing: 1),
      headlineSmall: TextStyle(
          fontSize: 16.0,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.bold,
          color: Color(0xffE51837),
          letterSpacing: 1),
      titleLarge: TextStyle(
          fontSize: 7.0,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.blue,
          letterSpacing: 1),
      titleMedium: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          letterSpacing: 1),
      titleSmall: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          letterSpacing: 1),
      bodyLarge: TextStyle(
          // fontSize: 12.0,
          fontSize: 8,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.black,
          letterSpacing: 1),
      bodyMedium: TextStyle(
          // fontSize: 10.0,120
          fontSize: 7,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          // fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 1),
    ));

final blueTheme = ThemeData(
    // Define the default brightness and colors.
    // brightness: Brightness.dark,
    primaryColor: Colors.blue,
    // primaryColor: Colors.yellow[700],
    // Define the default font family.
    fontFamily: 'Gilroy',

    // Define the default TextTheme. Use this to specify the default
    // text styling for headlines, titles, bodies of text, and more.
    textTheme:
        TextTheme(
      displayLarge: TextStyle(
          fontSize: 24.0,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.bold,
          color: Colors.black,
          letterSpacing: 1),
      displayMedium: TextStyle(
          // fontSize: 20.0,
          fontSize: 14,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          // color: Colors.black,
          color: Colors.white,
          letterSpacing: 1),
      displaySmall: TextStyle(
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.black,
          letterSpacing: 1),
      headlineMedium: TextStyle(
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.blue,
          letterSpacing: 1),
      headlineSmall: TextStyle(
          fontSize: 16.0,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.bold,
          color: Color(0xffE51837),
          letterSpacing: 1),
      titleLarge: TextStyle(
          fontSize: 7.0,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.blue,
          letterSpacing: 1),
      titleMedium: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          letterSpacing: 1),
      titleSmall: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          letterSpacing: 1),
      bodyLarge: TextStyle(
          // fontSize: 12.0,
          fontSize: 8,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          color: Colors.black,
          letterSpacing: 1),
      bodyMedium: TextStyle(
          // fontSize: 10.0,120
          fontSize: 7,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.normal,
          // fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 1),
    ));

class ThemeNotifier with ChangeNotifier {
  ThemeData _themeData;

  ThemeNotifier(this._themeData);

  getTheme() => _themeData;

  setTheme(ThemeData themeData) async {
    _themeData = themeData;
    notifyListeners();
  }

  Locale _currentLocale = Locale('en'); // Store the current locale

  // Getter to access the current locale
  Locale get currentLocale => _currentLocale;

  // Method to update the current locale and notify listeners
  updateLocale(Locale newLocale) {
    _currentLocale = newLocale;
    notifyListeners();
  }

    // Method to load the locale from SharedPreferences
  getLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? localeString = await prefs.getString('locale');

    if (localeString != null) {
      _currentLocale = Locale(localeString);
      notifyListeners();
    }
  }
}
