// First screen of the student app: create an account or log in.
//
// Registration needs all six: photo, first name, surname, faculty,
// department, email and password. The account is stored on the phone
// for now (see services/account.dart); later it can switch to
// Supabase Auth without changing this screen.
//
// Design: every field lives in its own colourful card (the app
// palette: red / yellow / blue / brown / green), so the page is
// not a plain white form any more. Only the look changed —
// the fields, the order and the validation are exactly the same.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../data/catalogue.dart';
import '../l10n/strings.dart';
import '../services/account.dart';
import '../services/store.dart';

// App palette (same colours as the faculty/department cards).
const _kRed = Color(0xFFC62828);
const _kYellow = Color(0xFFF9A825);
const _kBlue = Color(0xFF1565C0);
const _kBrown = Color(0xFF6D4C41);
const _kGreen = Color(0xFF2E7D32);
const _kNavy = Color(0xFF0B2535);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = true;
  File? _photoFile;
  String? _facultyId;
  String? _departmentId;
  String? _error;

  final _firstName = TextEditingController();
  final _surname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If an account already exists on this phone (e.g. after logout),
    // open the login form; otherwise open registration.
    _isRegister = context.read<AppState>().currentAccount == null;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _surname.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    // file_picker 12: static API, no FilePicker.platform.
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    File? picked;
    if (file.path != null) {
      picked = File(file.path!);
    } else {
      final bytes = await file.readAsBytes();
      if (bytes != null) {
        final dir = await getTemporaryDirectory();
        final tmp = File('${dir.path}/picked_photo.jpg');
        await tmp.writeAsBytes(bytes);
        picked = tmp;
      }
    }
    if (picked != null && mounted) {
      setState(() => _photoFile = picked);
    }
  }

  /// True when the phone can actually reach the internet.
  /// Account creation requires internet: without it, no account
  /// may be created.
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submitRegister() async {
    final isPs = context.read<AppState>().isPashto;
    if (!await _hasInternet()) {
      setState(() => _error = Strings.t('internetRequired', isPs));
      return;
    }
    final firstName = _firstName.text.trim();
    final surname = _surname.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (firstName.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        _facultyId == null ||
        _departmentId == null) {
      setState(() => _error = Strings.t('allFieldsRequired', isPs));
      return;
    }
    if (_photoFile == null) {
      setState(() => _error = Strings.t('photoRequired', isPs));
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = Strings.t('invalidEmail', isPs));
      return;
    }
    if (password.length < 6) {
      setState(() => _error = Strings.t('passwordTooShort', isPs));
      return;
    }
    final photoPath = await AccountService.storePhoto(_photoFile!);
    final account = Account(
      firstName: firstName,
      surname: surname,
      facultyId: _facultyId!,
      departmentId: _departmentId!,
      email: email,
      photoPath: photoPath,
    );
    if (!mounted) return;
    // Saving the account logs the student in; main.dart then shows
    // the home screen automatically.
    await context.read<AppState>().setAccount(account, password);
  }

  void _submitLogin() async {
    final state = context.read<AppState>();
    final isPs = state.isPashto;
    final email = _email.text.trim();
    final password = _password.text;
    final account = state.currentAccount;
    if (account == null) {
      setState(() => _error = Strings.t('noAccountYet', isPs));
      return;
    }
    if (account.email != email || !state.checkPassword(password)) {
      setState(() => _error = Strings.t('wrongCredentials', isPs));
      return;
    }
    // Correct email and password: start the session, and the home
    // screen appears automatically (main.dart watches isLoggedIn).
    await state.login();
  }

  /// One colourful card holding one field: a coloured icon in a
  /// tinted circle, a small bold coloured label, and the input
  /// itself on a very light tint of the same colour.
  Widget _fieldCard(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textCard(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String labelKey,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return _fieldCard(
      context,
      color: color,
      icon: icon,
      label: tr(context, labelKey),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: tr(context, labelKey),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _dropdownCard(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String labelKey,
    required String hintKey,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return _fieldCard(
      context,
      color: color,
      icon: icon,
      label: tr(context, labelKey),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        hint: Text(tr(context, hintKey)),
        isExpanded: true,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _gradientButton(BuildContext context, String label, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_kBlue, _kGreen],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPs = state.isPashto;
    final facultyDepartments = _facultyId == null
        ? <Department>[]
        : departments.where((d) => d.facultyId == _facultyId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'appTitle')),
        actions: [
          TextButton(
            onPressed: () => state.setPashto(true),
            child: Text(
              'پښتو',
              style: TextStyle(
                color: isPs ? Colors.white : Colors.white70,
                fontWeight: isPs ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          TextButton(
            onPressed: () => state.setPashto(false),
            child: Text(
              'English',
              style: TextStyle(
                color: !isPs ? Colors.white : Colors.white70,
                fontWeight: !isPs ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Colourful header banner: logo, app name, page title.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [_kNavy, _kBlue],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', width: 76, height: 76),
                const SizedBox(height: 10),
                Text(
                  _isRegister
                      ? tr(context, 'createAccountTitle')
                      : tr(context, 'loginTitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_isRegister) ...[
            // Photo card (red): tap to choose your photo.
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [_kRed, Color(0xFFE65100)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kRed.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Row(
                  children: [
                    _photoFile == null
                        ? const CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.add_a_photo,
                                size: 30, color: _kRed),
                          )
                        : CircleAvatar(
                            radius: 34,
                            backgroundImage: FileImage(_photoFile!),
                          ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        tr(context, 'tapToAddPhoto'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.camera_alt,
                        color: Colors.white, size: 26),
                  ],
                ),
              ),
            ),
            _textCard(
              context,
              color: _kBlue,
              icon: Icons.person,
              labelKey: 'firstName',
              controller: _firstName,
            ),
            _textCard(
              context,
              color: _kGreen,
              icon: Icons.badge,
              labelKey: 'surname',
              controller: _surname,
            ),
            _dropdownCard(
              context,
              color: _kYellow,
              icon: Icons.school,
              labelKey: 'faculty',
              hintKey: 'selectFaculty',
              value: _facultyId,
              items: faculties
                  .map(
                    (f) => DropdownMenuItem<String>(
                      value: f.id,
                      child: Text(isPs ? f.namePs : f.nameEn),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _facultyId = value;
                _departmentId = null;
              }),
            ),
            _dropdownCard(
              context,
              color: _kBrown,
              icon: Icons.account_tree,
              labelKey: 'department',
              hintKey: 'selectDepartment',
              value: _departmentId,
              items: facultyDepartments
                  .map(
                    (d) => DropdownMenuItem<String>(
                      value: d.id,
                      child: Text(isPs ? d.namePs : d.nameEn),
                    ),
                  )
                  .toList(),
              onChanged: _facultyId == null
                  ? null
                  : (value) => setState(() => _departmentId = value),
            ),
          ],
          _textCard(
            context,
            color: _kRed,
            icon: Icons.email,
            labelKey: 'email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          _textCard(
            context,
            color: _kBlue,
            icon: Icons.lock,
            labelKey: 'password',
            controller: _password,
            obscure: true,
          ),
          if (_error != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kRed.withOpacity(0.5)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: _kRed),
              ),
            ),
          ],
          const SizedBox(height: 4),
          _gradientButton(
            context,
            tr(context, _isRegister ? 'register' : 'login'),
            _isRegister ? _submitRegister : _submitLogin,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _isRegister = !_isRegister;
              _error = null;
            }),
            child: Text(
              _isRegister
                  ? tr(context, 'haveAccount')
                  : tr(context, 'noAccountYet'),
            ),
          ),
        ],
      ),
    );
  }
}
