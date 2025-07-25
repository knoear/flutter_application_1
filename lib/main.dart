import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

void main() {
  runApp(SecureOBDApp());
}

class SecureOBDApp extends StatefulWidget {
  @override
  State<SecureOBDApp> createState() => _SecureOBDAppState();
}

class _SecureOBDAppState extends State<SecureOBDApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() { _themeMode = isDark ? ThemeMode.dark : ThemeMode.light; });
  }

  void toggleTheme(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() { _themeMode = isDark ? ThemeMode.dark : ThemeMode.light; });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureOBD-Ex',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Color(0xFFF5F3FA),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: SplashScreen(toggleTheme: toggleTheme),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final Function(bool) toggleTheme;
  SplashScreen({required this.toggleTheme});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);

    Future.delayed(Duration(seconds: 3), checkLogin);
  }

  Future<void> checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn
            ? HomePage(toggleTheme: widget.toggleTheme)
            : LoginPage(toggleTheme: widget.toggleTheme),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple, // Splash screen background color
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.car_repair, size: 80, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'SecureOBD-Ex',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// LOGIN PAGE
class LoginPage extends StatefulWidget {
  final Function(bool) toggleTheme;
  LoginPage({required this.toggleTheme});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  bool otpSent = false;
  bool otpVerified = false;
  String generatedOtp = '';

  String generateOtp() => (100000 + Random().nextInt(900000)).toString();

  Future<void> sendOtp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPass = prefs.getString('password_${emailController.text}');
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showMsg('Please enter email & password'); return;
    }
    if (passwordController.text == savedPass) {
      generatedOtp = generateOtp();
      setState(() { otpSent = true; otpVerified = false; otpController.clear(); });
      showMsg('OTP sent: $generatedOtp');
    } else { showMsg('Invalid credentials'); }
  }

  Future<void> verifyOtp() async {
    if (otpController.text == generatedOtp) {
      setState(() { otpVerified = true; });
      showMsg('OTP verified!');
    } else { showMsg('Incorrect OTP'); }
  }

  Future<void> login() async {
    if (!otpVerified) { showMsg('Verify OTP first'); return; }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('currentUser', emailController.text);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(toggleTheme: widget.toggleTheme)));
  }

  void goToRegister() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage()));
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget gradientButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Login', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                SizedBox(height: 16),
                TextField(controller: emailController, decoration: InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                SizedBox(height: 16),
                TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(hintText: 'Password', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                SizedBox(height: 16),
                gradientButton('Send OTP', sendOtp),
                if (otpSent) ...[
                  SizedBox(height: 12),
                  TextField(
                    controller: otpController,
                    decoration: InputDecoration(
                      hintText: 'Enter OTP',
                      prefixIcon: Icon(Icons.vpn_key),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(height: 10),
                  gradientButton('Verify OTP', verifyOtp),
                ],
                if (otpVerified) ...[
                  SizedBox(height: 16),
                  gradientButton('Login', login),
                ],
                TextButton(onPressed: goToRegister, child: Text('No account? Register'))

              ],
            ),
          ),
        ),
      )),
    );
  }
}

// REGISTER PAGE
class RegisterPage extends StatefulWidget { @override State<RegisterPage> createState() => _RegisterPageState(); }
class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  bool otpSent = false;
  bool otpVerified = false;
  String generatedOtp = '';

  String generateOtp() => (100000 + Random().nextInt(900000)).toString();

  void sendOtp() {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      showMsg('Please fill all fields'); return;
    }
    generatedOtp = generateOtp();
    setState(() { otpSent = true; otpVerified = false; otpController.clear(); });
    showMsg('OTP sent: $generatedOtp');
  }

  void verifyOtp() {
    if (otpController.text == generatedOtp) {
      setState(() { otpVerified = true; });
      showMsg('OTP verified!');
    } else { showMsg('Incorrect OTP'); }
  }

  Future<void> register() async {
    if (!otpVerified) { showMsg('Verify OTP first'); return; }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('password_${emailController.text}', passwordController.text);
    await prefs.setString('name_${emailController.text}', nameController.text);
    showMsg('Registration successful! Please login.');
    Navigator.pop(context);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget gradientButton(String text, VoidCallback onTap, {bool enabled = true}) {
  return InkWell(
    onTap: enabled ? onTap : null,
    child: Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent])
            : LinearGradient(colors: [Colors.grey, Colors.grey]), // grey when disabled
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Center(child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Register', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                SizedBox(height: 16),
                TextField(controller: nameController, decoration: InputDecoration(hintText: 'Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                SizedBox(height: 16),
                TextField(controller: emailController, decoration: InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                SizedBox(height: 16),
                TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(hintText: 'Password', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                SizedBox(height: 16),
                gradientButton('Send OTP', sendOtp),
                if (otpSent) ...[
                  SizedBox(height: 12),
                  TextField(controller: otpController, decoration: InputDecoration(hintText: 'Enter OTP', prefixIcon: Icon(Icons.vpn_key), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  SizedBox(height: 10),
                  gradientButton('Verify OTP', verifyOtp),
                ],
                SizedBox(height: 16),
                gradientButton('Register', register, enabled: otpVerified),
              ],
            ),
          ),
        ),
      )),
    );
  }
}

// HOMEPAGE
class HomePage extends StatefulWidget {
  final Function(bool) toggleTheme;
  HomePage({required this.toggleTheme});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  String name = '';
  bool accessAllowed = true;
  bool extenderConnected = true;
  bool extend = true;

  @override
  void initState() { super.initState(); loadPrefs(); }

  Future<void> loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('currentUser') ?? '';
    setState(() {
      name = prefs.getString('name_$email') ?? '';
      accessAllowed = prefs.getBool('accessAllowed_$email') ?? true;
    });
  }

  Future<void> toggleAccess(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('currentUser') ?? '';
    await prefs.setBool('accessAllowed_$email', value);
    setState(() { accessAllowed = value; });
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('currentUser');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage(toggleTheme: widget.toggleTheme)));
  }

  void showExtenderStatus() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Extender Status'),
        content: Text(extenderConnected ? 'Connected ✅' : 'Disconnected ❌'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  }

  Widget dashboardButton(IconData icon, String label, Widget page) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.deepPurple, size: 40),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Text('Hello, $name'),
  actions: [
    IconButton(
      icon: Icon(Icons.settings, size: 22), // small icon
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsPage(toggleTheme: widget.toggleTheme)),
        );
      },
    ),
    IconButton(
      onPressed: logout,
      icon: Icon(Icons.logout),
    ),
  ],
),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.usb, color: Colors.deepPurple),
              title: Text('Extender Status'),
              subtitle: Text(extenderConnected ? 'Connected ✅' : 'Disconnected ❌'),
              trailing: Icon(Icons.chevron_right),
              onTap: showExtenderStatus,
            ),
          ),
          SizedBox(height: 12),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: Text('Access: ${accessAllowed ? "Allowed" : "Blocked"}'),
              value: accessAllowed,
              onChanged: toggleAccess,
              activeColor: Colors.deepPurple,
            ),
          ),
          SizedBox(height: 20),
          Divider(),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            childAspectRatio: 3/2,
            children: [
             dashboardButton(Icons.person, 'Profile', ProfilePage()),
             dashboardButton(Icons.history, 'History', HistoryPage()),
           ],
         ),
        ],
      ),
    );
  }
}
// PROFILE PAGE
class ProfilePage extends StatefulWidget { @override _ProfilePageState createState() => _ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final vehicleModelController = TextEditingController();
  final plateNumberController = TextEditingController();
  final obdIdController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('currentUser') ?? '';
    setState(() {
      emailController.text = email;
      nameController.text = prefs.getString('name_$email') ?? '';
      phoneController.text = prefs.getString('phone_$email') ?? '';
      vehicleModelController.text = prefs.getString('vehicleModel_$email') ?? '';
      plateNumberController.text = prefs.getString('plateNumber_$email') ?? '';
      obdIdController.text = prefs.getString('obdId_$email') ?? '';
    });
  }

  Future<void> saveProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('currentUser') ?? '';
    await prefs.setString('name_$email', nameController.text);
    await prefs.setString('phone_$email', phoneController.text);
    await prefs.setString('vehicleModel_$email', vehicleModelController.text);
    await prefs.setString('plateNumber_$email', plateNumberController.text);
    await prefs.setString('obdId_$email', obdIdController.text);
    if (passwordController.text.isNotEmpty) {
      await prefs.setString('password_$email', passwordController.text);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated')));
  }

  Widget textField(String label, TextEditingController controller, {bool readOnly=false, bool obscure=false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget gradientButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                textField('Name', nameController),
                textField('Email', emailController, readOnly: true),
                textField('Phone Number', phoneController),
                Divider(),
                textField('Vehicle Model', vehicleModelController),
                textField('Plate Number', plateNumberController),
                textField('OBD Device ID', obdIdController),
                Divider(),
                textField('Change Password', passwordController, obscure: true),
                SizedBox(height: 16),
                gradientButton('Save Profile', saveProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// SETTINGS PAGE
class SettingsPage extends StatefulWidget {
  final Function(bool) toggleTheme;
  SettingsPage({required this.toggleTheme});
  @override _SettingsPageState createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  bool is2FAEnabled = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('currentUser') ?? '';
    setState(() {
      is2FAEnabled = prefs.getBool('2fa_$email') ?? false;
      isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> toggle2FA(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('currentUser') ?? '';
    await prefs.setBool('2fa_$email', value);
    setState(() { is2FAEnabled = value; });
  }

  Future<void> toggleDarkMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    widget.toggleTheme(value);
    setState(() { isDarkMode = value; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                title: Text('Enable Two-Factor Authentication'),
                value: is2FAEnabled,
                onChanged: toggle2FA,
                activeColor: Colors.deepPurple,
                secondary: Icon(Icons.shield, color: Colors.deepPurple),
              ),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                title: Text('Dark Mode'),
                value: isDarkMode,
                onChanged: toggleDarkMode,
                activeColor: Colors.deepPurple,
                secondary: Icon(Icons.dark_mode, color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// HISTORY PAGE
class HistoryPage extends StatelessWidget {
  final List<String> items = [
    'Connected to OBD at 12:34',
    'Disconnected at 13:00',
    'Access toggled to Allowed',
    'Profile updated',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('History')),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, index) {
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.history, color: Colors.deepPurple),
              title: Text(items[index]),
            ),
          );
        },
      ),
    );
  }
}
