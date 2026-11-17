// First screen of the student app: create an account or log in.
//
// Registration needs all six: photo, first name, surname, faculty,
// department, email and password. The account is stored on the phone
// for now (see services/account.dart); later it can switch to
// Supabase Auth without changing this screen.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../data/catalogue.dart';
import '../l10n/strings.dart';
import '../services/account.dart';
import '../services/store.dart';

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

  Future<void> _submitRegister() async {
    final isPs = context.read<AppState>().isPashto;
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

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String labelKey, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: tr(context, labelKey),
          border: const OutlineInputBorder(),
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
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Image.asset('assets/images/logo.png', width: 84, height: 84),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _isRegister
                  ? tr(context, 'createAccountTitle')
                  : tr(context, 'loginTitle'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          if (_isRegister) ...[
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: _photoFile == null
                    ? const CircleAvatar(
                        radius: 52,
                        child: Icon(Icons.add_a_photo, size: 32),
                      )
                    : CircleAvatar(
                        radius: 52,
                        backgroundImage: FileImage(_photoFile!),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                tr(context, 'tapToAddPhoto'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            _field(context, _firstName, 'firstName'),
            _field(context, _surname, 'surname'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                value: _facultyId,
                decoration: InputDecoration(
                  labelText: tr(context, 'faculty'),
                  border: const OutlineInputBorder(),
                ),
                hint: Text(tr(context, 'selectFaculty')),
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
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                value: _departmentId,
                decoration: InputDecoration(
                  labelText: tr(context, 'department'),
                  border: const OutlineInputBorder(),
                ),
                hint: Text(tr(context, 'selectDepartment')),
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
            ),
          ],
          _field(
            context,
            _email,
            'email',
            keyboardType: TextInputType.emailAddress,
          ),
          _field(context, _password, 'password', obscure: true),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _isRegister ? _submitRegister : _submitLogin,
            child: Text(tr(context, _isRegister ? 'register' : 'login')),
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
