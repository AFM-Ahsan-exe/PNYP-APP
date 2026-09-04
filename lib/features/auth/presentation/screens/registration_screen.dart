import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/validators/registration_validators.dart';
import '../controllers/registration_controller.dart';
import '../providers/auth_providers.dart';
import '../../../../app/theme/app_text_styles.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  // Tracks the actual picked date alongside the dd/MM/yyyy display text in
  // _dateOfBirthController. The display string was previously sent as-is
  // to the backend, which then tried `new Date("29/08/2006")` - invalid
  // in dd/MM/yyyy for any day > 12, silently dropping the date of birth
  // for most users. Sending the real DateTime's ISO string instead fixes
  // that while keeping the localized dd/MM/yyyy display untouched.
  DateTime? _dateOfBirth;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _educationController = TextEditingController();
  final _employmentController = TextEditingController();
  final _skillsController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _referralController = TextEditingController();

  int _step = 0;
  String? _gender;
  String? _province;
  String? _district;
  bool _acceptedTerms = false;

  final Map<String, List<int>> _documentBytes = {};
  final Map<String, String> _documentNames = {};

  static const _provinces = [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
    'Gilgit-Baltistan',
    'Azad Jammu and Kashmir',
  ];

  @override
  void dispose() {
    for (final controller in [
      _fullNameController,
      _fatherNameController,
      _cnicController,
      _dateOfBirthController,
      _phoneController,
      _emailController,
      _passwordController,
      _cityController,
      _districtController,
      _educationController,
      _employmentController,
      _skillsController,
      _emergencyNameController,
      _emergencyPhoneController,
      _referralController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String label) {
    return RegistrationValidators.required(value, label);
  }

  String? _validateCnic(String? value) {
    return RegistrationValidators.cnic(value);
  }

  String? _validatePhone(String? value) {
    return RegistrationValidators.phone(value);
  }

  String? _validateEmail(String? value) {
    return RegistrationValidators.email(value);
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 60),
      lastDate: DateTime(now.year - 15, now.month, now.day),
      initialDate: DateTime(now.year - 20),
    );
    if (picked != null) {
      _dateOfBirth = picked;
      _dateOfBirthController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {});
    }
  }

  Future<void> _pickFile(
    String key,
    String title,
    List<String> allowedExtensions,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: allowedExtensions.contains('pdf')
            ? FileType.custom
            : FileType.image,
        allowedExtensions: allowedExtensions,
      );
      if (result.isNotEmpty) {
        // .single throws Bad state ("No element" / "Too many elements")
        // if the platform picker ever returns zero or more than one file
        // despite this being a single-file picker - some Android file
        // manager UIs allow multi-select regardless of what the app
        // requested. .first with the isNotEmpty guard above can never
        // throw, and simply uses the first picked file if more than one
        // came back.
        final file = result.first;
        final bytes = await file.readAsBytes();
        setState(() {
          _documentBytes[key] = bytes;
          _documentNames[key] = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick $title: $e')));
      }
    }
  }

  Future<void> _next() async {
    if (!_formKeys[_step].currentState!.validate()) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      await _submitRegistration();
    }
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _submitRegistration() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the declaration before continuing.'),
        ),
      );
      return;
    }

    final authController = ref.read(authControllerProvider.notifier);
    final registrationController = ref.read(
      registrationControllerProvider.notifier,
    );

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();

    final authSuccess = await authController.signUp(
      email: email,
      password: password,
      name: fullName,
    );

    if (!mounted) return;

    if (!authSuccess) {
      final authState = ref.read(authControllerProvider);
      final error = authState.error;
      debugPrint('[REGISTER] Registration failed with error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Account creation failed')),
      );
      return;
    }

    final selectedSkills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final formData = {
      'fullName': fullName,
      'fatherName': _fatherNameController.text.trim(),
      'cnic': _cnicController.text.trim(),
      'dateOfBirth': _dateOfBirth?.toIso8601String() ??
          _dateOfBirthController.text.trim(),
      'gender': _gender ?? '',
      'province': _province ?? '',
      'district': _district ?? '',
      'city': _cityController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': email,
      'education': _educationController.text.trim(),
      'employment': _employmentController.text.trim(),
      'skills': selectedSkills,
      'emergencyContactName': _emergencyNameController.text.trim(),
      'emergencyContactPhone': _emergencyPhoneController.text.trim(),
      'referralSource': _referralController.text.trim(),
      'organizationId': 'unassigned',
    };

    final success = await registrationController.completeRegistration(
      formData: formData,
      documentBytes: _documentBytes,
    );

    if (!mounted) return;

    if (success) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registration submitted'),
          content: const Text(
            'Your account is pending administrator approval. Please verify your email to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/account/pending');
    } else {
      final error = ref.read(registrationControllerProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Registration failed')));
      await authController.signOut();
    }
  }

  InputDecoration _decoration(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: AppColors.surfaceMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.navyDeep, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _decoration(label, icon: icon),
      validator: validator ?? (value) => _required(value, label),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _stepForm({required int index, required Widget child}) {
    return Form(key: _formKeys[index], child: child);
  }

  Widget _personalStep() {
    return _stepForm(
      index: 0,
      child: Column(
        children: [
          _field(_fullNameController, 'Full name', icon: Icons.person_outline),
          const SizedBox(height: 16),
          _field(
            _fatherNameController,
            'Father name',
            icon: Icons.family_restroom,
          ),
          const SizedBox(height: 16),
          _field(
            _cnicController,
            'CNIC number',
            icon: Icons.badge_outlined,
            validator: _validateCnic,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dateOfBirthController,
            readOnly: true,
            onTap: _pickDateOfBirth,
            decoration: _decoration(
              'Date of birth',
              icon: Icons.calendar_today_outlined,
              hint: 'Select your date of birth',
            ),
            validator: (value) => _required(value, 'Date of birth'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: _decoration('Gender', icon: Icons.wc_outlined),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) => setState(() => _gender = value),
            validator: (value) => value == null ? 'Gender is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _contactStep() {
    return _stepForm(
      index: 1,
      child: Column(
        children: [
          _field(
            _emailController,
            'Email address',
            icon: Icons.email_outlined,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _field(
            _passwordController,
            'Password',
            icon: Icons.lock_outline,
            keyboardType: TextInputType.visiblePassword,
            validator: (value) => value != null && value.length >= 6
                ? null
                : 'Password must be at least 6 characters',
          ),
          const SizedBox(height: 16),
          _field(
            _phoneController,
            'Mobile number',
            icon: Icons.phone_outlined,
            validator: _validatePhone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _province,
            decoration: _decoration('Province', icon: Icons.map_outlined),
            items: _provinces
                .map(
                  (province) =>
                      DropdownMenuItem(value: province, child: Text(province)),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _province = value;
              _district = null;
            }),
            validator: (value) => value == null ? 'Province is required' : null,
          ),
          const SizedBox(height: 16),
          _field(
            _districtController,
            'District',
            icon: Icons.location_city_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'District is required';
              }
              _district = value.trim();
              return null;
            },
          ),
          const SizedBox(height: 16),
          _field(_cityController, 'City', icon: Icons.home_work_outlined),
        ],
      ),
    );
  }

  Widget _profileStep() {
    return _stepForm(
      index: 2,
      child: Column(
        children: [
          _field(
            _educationController,
            'Education',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 16),
          _field(_employmentController, 'Employment', icon: Icons.work_outline),
          const SizedBox(height: 16),
          _field(
            _skillsController,
            'Skills (comma separated)',
            icon: Icons.auto_awesome_outlined,
          ),
          const SizedBox(height: 16),
          _field(
            _emergencyNameController,
            'Emergency contact name',
            icon: Icons.contact_emergency_outlined,
          ),
          const SizedBox(height: 16),
          _field(
            _emergencyPhoneController,
            'Emergency contact phone',
            icon: Icons.phone_callback_outlined,
            validator: _validatePhone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _field(
            _referralController,
            'How did you hear about PYNP?',
            icon: Icons.share_outlined,
          ),
        ],
      ),
    );
  }

  Widget _documentsStep() {
    return _stepForm(
      index: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Required documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload these files before secure submission. Each file is validated server-side.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _uploadTile(
            'CNIC front image',
            'PNG or JPG, max 5 MB',
            Icons.badge_outlined,
            'cnicFront',
            ['png', 'jpg', 'jpeg'],
          ),
          const SizedBox(height: 12),
          _uploadTile(
            'CNIC back image',
            'PNG or JPG, max 5 MB',
            Icons.badge_outlined,
            'cnicBack',
            ['png', 'jpg', 'jpeg'],
          ),
          const SizedBox(height: 12),
          _uploadTile(
            'CV document',
            'PDF, max 10 MB',
            Icons.description_outlined,
            'cv',
            ['pdf'],
          ),
          const SizedBox(height: 12),
          _uploadTile(
            'Membership fee payment proof',
            'JPG, PNG or PDF, max 10 MB',
            Icons.payments_outlined,
            'paymentProof',
            ['png', 'jpg', 'jpeg', 'pdf'],
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            value: _acceptedTerms,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) =>
                setState(() => _acceptedTerms = value ?? false),
            title: const Text(
              'I confirm that the information provided is accurate and agree to PYNP verification.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadTile(
    String title,
    String subtitle,
    IconData icon,
    String key,
    List<String> allowedExtensions,
  ) {
    final hasFile = _documentBytes.containsKey(key);
    return OutlinedButton.icon(
      onPressed: () => _pickFile(key, title, allowedExtensions),
      icon: Icon(hasFile ? Icons.check_circle_outline : icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    hasFile ? _documentNames[key] ?? 'File selected' : subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasFile
                  ? Icons.remove_circle_outline
                  : Icons.upload_file_outlined,
            ),
          ],
        ),
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: BorderSide(color: hasFile ? AppColors.success : AppColors.border),
      ),
    );
  }

  Widget _review() {
    final rows = <String, String>{
      'Name': _fullNameController.text,
      'CNIC': _cnicController.text,
      'Email': _emailController.text,
      'Phone': _phoneController.text,
      'Location':
          '${_cityController.text}, ${_district ?? ''}, ${_province ?? ''}',
      'Education': _educationController.text,
    };
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final entry = rows.entries.elementAt(index);
        return ListTile(
          title: Text(
            entry.key,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          subtitle: Text(entry.value.isEmpty ? 'Not provided' : entry.value),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Personal details',
      'Contact details',
      'Profile details',
      'Documents',
    ];
    final isLast = _step == 3;
    final authState = ref.watch(authControllerProvider);
    final regState = ref.watch(registrationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: const Text('Member registration'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Step ${_step + 1} of 4',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_step + 1) / 4,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor: AppColors.border,
                  ),
                  const SizedBox(height: 16),
                  Text(titles[_step], style: AppTextStyles.title),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _step == 0
                    ? _personalStep()
                    : _step == 1
                    ? _contactStep()
                    : _step == 2
                    ? _profileStep()
                    : _documentsStep(),
              ),
            ),
            if (isLast && _acceptedTerms)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Review summary',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _review(),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (authState.isLoading || regState.isLoading)
                          ? null
                          : _next,
                      icon: Icon(
                        isLast ? Icons.send_outlined : Icons.arrow_forward,
                      ),
                      label: Text(
                        (authState.isLoading || regState.isLoading)
                            ? 'Submitting...'
                            : isLast
                            ? 'Submit registration'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
