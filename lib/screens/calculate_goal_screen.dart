import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/app_provider.dart';
import 'dashboard_screen.dart';

class CalculateGoalScreen extends StatefulWidget {
  final bool manualMode;
  const CalculateGoalScreen({super.key, this.manualMode = false});

  @override
  State<CalculateGoalScreen> createState() =>
      _CalculateGoalScreenState();
}

class _CalculateGoalScreenState extends State<CalculateGoalScreen> {
  // Shared
  String? _gender;

  // Calculate mode
  int? _age;
  double? _weight;
  int? _heightFeet;
  int? _heightInch;
  String _activity = 'Moderate';
  String _fitnessGoal = 'Maintain Weight';
  double? _recommendedKcal;
  String? _genderError, _ageError, _weightError, _heightError;

  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  // Manual mode
  final _manualCtrl = TextEditingController();
  String? _manualGender;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _activities = [
    'Sedentary (little)',
    'Light',
    'Moderate',
    'Active',
    'Very Active',
  ];
  final List<String> _goals = [
    'Lose Weight',
    'Maintain Weight',
    'Gain Weight',
  ];

  double _getMin(String? gender) =>
      gender == 'Female' ? 1200.0 : 1500.0;

  double _getMax(String? gender) =>
      gender == 'Female' ? 4000.0 : 5000.0;

  String _getMinLabel(String? gender) =>
      gender == 'Female' ? '1,200' : '1,500';

  String _getMaxLabel(String? gender) =>
      gender == 'Female' ? '4,000' : '5,000';

  void _applyGoal(double kcal) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.setCalorieGoal(kcal);
    // The calorie goal syncs itself via setCalorieGoal(), but gender/age/
    // weight/height/activity level/fitness goal were only ever set on the
    // in-memory provider.user above — they were never sent to the backend.
    // That's why the admin panel showed these fields empty for every user.
    provider.syncProfileToServer();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (_) => false,
    );
  }

  void _saveManualGoal() {
    if (_manualGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender first'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final text = _manualCtrl.text.trim();
    final val = double.tryParse(text);
    final minKcal = _getMin(_manualGender);
    final maxKcal = _getMax(_manualGender);

    if (text.isEmpty || val == null || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid calorie amount'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (val < minKcal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ This calorie goal is too low and may be unhealthy.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } else if (val > maxKcal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ This calorie goal is unusually high.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      // Save gender to provider too
      Provider.of<AppProvider>(context, listen: false)
          .user
          .gender = _manualGender!;
      _applyGoal(val);
    }
  }

  void _calculate() {
    final ageVal = int.tryParse(_ageCtrl.text);
    final weightVal = double.tryParse(_weightCtrl.text);
    setState(() {
      _genderError =
      _gender == null ? 'Please select gender' : null;

      if (_ageCtrl.text.isEmpty || ageVal == null) {
        _ageError = 'Please enter a valid age';
      } else if (ageVal < 1 || ageVal > 120) {
        _ageError = 'Age must be between 1 and 120';
      } else {
        _ageError = null;
      }

      if (_weightCtrl.text.isEmpty || weightVal == null) {
        _weightError = 'Please enter a valid weight';
      } else if (weightVal < 10 || weightVal > 500) {
        _weightError = 'Weight must be between 10 and 500 kg';
      } else {
        _weightError = null;
      }

      _heightError =
      (_heightFeet == null || _heightInch == null)
          ? 'Please select height'
          : null;
    });

    if (_genderError != null ||
        _ageError != null ||
        _weightError != null ||
        _heightError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _age = int.parse(_ageCtrl.text);
    _weight = double.parse(_weightCtrl.text);

    final provider =
    Provider.of<AppProvider>(context, listen: false);
    provider.user.gender = _gender!;
    provider.user.age = _age!;
    provider.user.weight = _weight!;
    provider.user.heightFeet = _heightFeet!;
    provider.user.heightInch = _heightInch!;
    provider.user.activityLevel = _activity;
    provider.user.fitnessGoal = _fitnessGoal;
    setState(() => _recommendedKcal = provider.calculateGoal());
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.manualMode) {
      return _buildManualScreen();
    }
    return _buildCalculateScreen();
  }

  // ── MANUAL MODE SCREEN ──────────────────────────────
  Widget _buildManualScreen() {
    final minLabel = _getMinLabel(_manualGender);
    final maxLabel = _getMaxLabel(_manualGender);
    final genderLabel = _manualGender ?? 'your gender';

    return Scaffold(
      appBar: AppBar(title: const Text('Set Goal Manually')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1 — Gender
            const Text('STEP 1',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Select your gender',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _manualGender,
              hint: const Text('Select gender'),
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: _genders
                  .map((g) =>
                  DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _manualGender = v),
            ),
            const SizedBox(height: 24),

            // Step 2 — Calorie input
            const Text('STEP 2',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Enter your daily calorie goal',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _manualCtrl,
              keyboardType: TextInputType.number,
              enabled: _manualGender != null,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              decoration: InputDecoration(
                labelText: 'Daily Calorie Goal (kcal)',
                prefixIcon: const Icon(
                    Icons.local_fire_department_outlined),
                hintText: _manualGender == null
                    ? 'Select gender first'
                    : 'e.g. ${_manualGender == "Female" ? "1800" : "2000"}',
              ),
            ),
            const SizedBox(height: 12),

            // Limit info box
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _manualGender != null
                    ? Colors.orange.withAlpha(25)
                    : Colors.grey.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _manualGender != null
                      ? Colors.orange.withAlpha(80)
                      : Colors.grey.withAlpha(80),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                      Icons.info_outline,
                      color: _manualGender != null
                          ? Colors.orange
                          : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _manualGender != null
                          ? 'Healthy range for $genderLabel'
                          : 'Healthy ranges by gender',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _manualGender != null
                            ? Colors.orange
                            : Colors.grey,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  if (_manualGender == null) ...[
                    _LimitRow('Female', '1,200', '4,000',
                        Colors.pink),
                    const SizedBox(height: 4),
                    _LimitRow(
                        'Male', '1,500', '5,000', Colors.blue),
                  ] else ...[
                    Row(children: [
                      Icon(Icons.arrow_downward,
                          size: 14,
                          color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text('Minimum: $minLabel kcal/day',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.arrow_upward,
                          size: 14,
                          color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text('Maximum: $maxLabel kcal/day',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Warning info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.health_and_safety_outlined,
                    color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Going below the minimum may be unhealthy. '
                        'Going above the maximum is unusually high.',
                    style: TextStyle(
                        color: Colors.blue, fontSize: 12),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _saveManualGoal,
              child: const Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
  }

  // ── CALCULATE MODE SCREEN ───────────────────────────
  Widget _buildCalculateScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Calculator'),
        actions: [
          if (_recommendedKcal != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_recommendedKcal!.toInt()} KCAL',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_recommendedKcal != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00C853),
                      Color(0xFF1B5E20)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  const Text('RECOMMENDED INTAKE',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12)),
                  Text(
                    '${_recommendedKcal!.toInt()} kcal',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Text('per day',
                      style:
                      TextStyle(color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            const Text('YOUR BIOMETRICS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 1)),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                  labelText: 'Gender',
                  errorText: _genderError),
              hint: const Text('Select gender'),
              items: _genders
                  .map((g) => DropdownMenuItem(
                  value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(
                      labelText: 'Age',
                      suffixText: 'yrs',
                      errorText: _ageError,
                      hintText: '1–120'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    _DecimalRangeFormatter(max: 500),
                  ],
                  decoration: InputDecoration(
                      labelText: 'Weight',
                      suffixText: 'kg',
                      errorText: _weightError,
                      hintText: '10–500'),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            const Text('HEIGHT',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 1)),
            const SizedBox(height: 8),

            Row(children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _heightFeet,
                  decoration: InputDecoration(
                      labelText: 'Feet',
                      errorText: _heightError),
                  hint: const Text('ft'),
                  items: List.generate(5, (i) => i + 3)
                      .map((f) => DropdownMenuItem(
                      value: f,
                      child: Text('$f ft')))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _heightFeet = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _heightInch,
                  decoration: const InputDecoration(
                      labelText: 'Inches'),
                  hint: const Text('in'),
                  items: List.generate(12, (i) => i)
                      .map((i) => DropdownMenuItem(
                      value: i,
                      child: Text('$i in')))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _heightInch = v),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            const Text('YOUR LIFESTYLE AND GOALS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 1)),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _activity,
              decoration: const InputDecoration(
                  labelText: 'Activity Level'),
              items: _activities
                  .map((a) => DropdownMenuItem(
                  value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _activity = v!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _fitnessGoal,
              decoration: const InputDecoration(
                  labelText: 'Fitness Goal'),
              items: _goals
                  .map((g) => DropdownMenuItem(
                  value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _fitnessGoal = v!),
            ),
            const SizedBox(height: 28),

            OutlinedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calculate Goal'),
            ),
            const SizedBox(height: 12),

            if (_recommendedKcal != null)
              ElevatedButton.icon(
                onPressed: () =>
                    _applyGoal(_recommendedKcal!),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Apply Calorie Goal'),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Helper widget ───────────────────────────────────────
class _LimitRow extends StatelessWidget {
  final String gender;
  final String min;
  final String max;
  final Color color;

  const _LimitRow(this.gender, this.min, this.max, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
            color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(
        '$gender: $min – $max kcal/day',
        style: TextStyle(
            color: color, fontWeight: FontWeight.w500),
      ),
    ]);
  }
}

// ── Custom formatter: prevents leading dot and values above max ───────────────
class _DecimalRangeFormatter extends TextInputFormatter {
  final double max;
  const _DecimalRangeFormatter({required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // Block leading dot (e.g. ".5")
    if (text.startsWith('.')) return oldValue;

    // Block more than one dot
    if ('.'.allMatches(text).length > 1) return oldValue;

    // Allow partial decimal (e.g. "65.") without blocking mid-type
    if (text.endsWith('.')) return newValue;

    final val = double.tryParse(text);
    if (val != null && val > max) return oldValue;

    return newValue;
  }
}