import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testable_form_field/testable_form_field.dart';
import '../data/http_sns_datasource.dart';
import '../data/sns_repository.dart';
import '../data/sqflite_sns_datasource.dart';
import '../connectivity_module.dart';
import '../location_module.dart';
import '../models/hospital.dart';
import '../models/evaluation_report.dart';
import 'package:intl/intl.dart';

class EvaluateHospital extends StatefulWidget {
  const EvaluateHospital({Key? key}) : super(key: key);

  @override
  State<EvaluateHospital> createState() => _EvaluateHospitalState();
}

class _EvaluateHospitalState extends State<EvaluateHospital> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  Hospital? _selectedHospital;
  int? _rating;
  DateTime? _selectedDateTime = DateTime.now();
  String _comment = '';
  List<Hospital> _hospitals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _updateDateTimeController();
    _loadHospitals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _dateTimeController.dispose();
    _ratingController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadHospitals() async {
    try {
      final httpDataSource = context.read<HttpSnsDataSource>();
      final sqfliteDataSource = context.read<SqfliteSnsDataSource>();
      final connectivityModule = context.read<ConnectivityModule>();
      final locationModule = context.read<LocationModule>();
      final repository = SnsRepository(httpDataSource, sqfliteDataSource, connectivityModule, locationModule);


      // Initialize local database if needed
      await sqfliteDataSource.init();

      List<Hospital> hospitals = await repository.getAllHospitals();

      setState(() {
        _hospitals = hospitals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Erro ao carregar hospitais: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildFormFields(),
          ),
        ),
      ),
    );
  }

  // Form building methods
  List<Widget> _buildFormFields() {
    return [
      _buildHospitalSelectionField(),
      const SizedBox(height: 12),
      _buildRatingField(),
      const SizedBox(height: 12),
      _buildDateTimeField(),
      const SizedBox(height: 12),
      _buildCommentField(),
      const SizedBox(height: 12),
      _buildSubmitButton(),
    ];
  }

  Widget _buildHospitalSelectionField() {
    return TestableFormField<Hospital>(
      key: const Key('evaluation-hospital-selection-field'),
      initialValue: _selectedHospital,
      getValue: () => _selectedHospital!,
      internalSetValue: (state, value) {
        state.didChange(value);
        setState(() => _selectedHospital = value);
      },
      validator: _validateHospitalSelection,
      builder: (field) => _buildHospitalDropdown(field),
    );
  }

  Widget _buildHospitalDropdown(FormFieldState<Hospital> field) {
    return DropdownButtonFormField<int?>(
      decoration: InputDecoration(
        labelText: 'Selecione o Hospital',
        border: const OutlineInputBorder(),
        errorText: field.errorText,
      ),
      value: _selectedHospital?.id,
      items: _buildHospitalDropdownItems(),
      onChanged: (newHospitalId) {
        if (newHospitalId != null) {
          final newHospital =
              _hospitals.firstWhere((h) => h.id == newHospitalId);
          _handleHospitalSelection(field, newHospital);
        }
      },
      isExpanded: true,
    );
  }

  List<DropdownMenuItem<int?>> _buildHospitalDropdownItems() {
    return _hospitals
        .map((h) => DropdownMenuItem(
              value: h.id,
              child: Text(
                h.name,
                overflow: TextOverflow.ellipsis,
              ),
            ))
        .toList();
  }

  Widget _buildRatingField() {
    return TestableFormField<int>(
      key: const Key('evaluation-rating-field'),
      initialValue: _rating,
      getValue: () => _rating!,
      internalSetValue: (state, value) {
        state.didChange(value);
        setState(() => _rating = value);
      },
      validator: _validateRating,
      builder: (field) => _buildRatingSegmentedButton(field),
    );
  }

  Widget _buildRatingSegmentedButton(FormFieldState<int> field) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Avaliação',
        border: InputBorder.none,
        errorText: field.errorText,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: SegmentedButton<int>(
          segments: _buildRatingSegments(),
          selected: <int>{if (_rating != null) _rating!},
          onSelectionChanged: (Set<int> newSelection) =>
              _handleRatingSelection(field, newSelection),
          multiSelectionEnabled: false,
          emptySelectionAllowed: true,
        ),
      ),
    );
  }

  List<ButtonSegment<int>> _buildRatingSegments() {
    return const <ButtonSegment<int>>[
      ButtonSegment<int>(value: 1, label: Text('1')),
      ButtonSegment<int>(value: 2, label: Text('2')),
      ButtonSegment<int>(value: 3, label: Text('3')),
      ButtonSegment<int>(value: 4, label: Text('4')),
      ButtonSegment<int>(value: 5, label: Text('5')),
    ];
  }

  Widget _buildDateTimeField() {
    return TestableFormField<DateTime>(
      key: const Key('evaluation-datetime-field'),
      initialValue: _selectedDateTime,
      getValue: () => _selectedDateTime!,
      internalSetValue: (state, value) {
        state.didChange(value);
        setState(() {
          _selectedDateTime = value;
          _updateDateTimeController();
        });
      },
      validator: _validateDateTime,
      builder: (field) => _buildDateTimeTextField(field),
    );
  }

  Widget _buildDateTimeTextField(FormFieldState<DateTime> field) {
    return TextFormField(
      controller: _dateTimeController,
      readOnly: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Data e Hora',
        hintText: 'Clique para selecionar data e hora',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
        errorText: field.errorText,
      ),
      onTap: () => _handleDateTimeFieldTap(field),
    );
  }

  Widget _buildCommentField() {
    return TestableFormField<String>(
      key: const Key('evaluation-comment-field'),
      initialValue: _comment,
      getValue: () => _comment,
      internalSetValue: (state, value) {
        state.didChange(value);
        setState(() {
          _comment = value;
          _commentController.text = value;
        });
      },
      builder: (field) => _buildCommentTextField(field),
    );
  }

  Widget _buildCommentTextField(FormFieldState<String> field) {
    return TextFormField(
      controller: _commentController,
      decoration: const InputDecoration(
        labelText: 'Nota (opcional)',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      onChanged: (value) => _handleCommentChange(field, value),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('evaluation-form-submit-button'),
        onPressed: () => _submitForm(),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(fontSize: 18),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text('Submeter'),
      ),
    );
  }

  // Event handlers

  void _handleHospitalSelection(
      FormFieldState<Hospital> field, Hospital? newHospital) {
    field.didChange(newHospital);
    setState(() => _selectedHospital = newHospital);
  }

  void _handleRatingSelection(
      FormFieldState<int> field, Set<int> newSelection) {
    setState(() {
      _rating = newSelection.isEmpty ? null : newSelection.first;
      field.didChange(_rating);
    });
  }

  void _handleDateTimeFieldTap(FormFieldState<DateTime> field) async {
    FocusScope.of(context).unfocus();
    await _selectDateTime(context);
    field.didChange(_selectedDateTime);
  }

  void _handleCommentChange(FormFieldState<String> field, String value) {
    field.didChange(value);
    setState(() => _comment = value);
  }

  // Validation methods
  String? _validateHospitalSelection(Hospital? value) {
    return value == null ? 'Por favor, selecione um hospital' : null;
  }

  String? _validateRating(int? value) {
    if (value == null || value < 1 || value > 5) {
      return 'Preencha a avaliação (1-5)';
    }
    return null;
  }

  String? _validateDateTime(DateTime? value) {
    return value == null ? 'Por favor, insira a data e hora' : null;
  }

  // Data handling methods
  void _updateDateTimeController() {
    if (_selectedDateTime != null) {
      _dateTimeController.text =
          DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime!);
    } else {
      _dateTimeController.text = '';
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final initialDate = _selectedDateTime ?? DateTime.now();

    final datePicked = await _selectDate(context, initialDate);
    if (datePicked == null) return;

    final timePicked = await _selectTime(context, initialDate);
    if (timePicked == null) return;

    final combined = _combineDateTime(datePicked, timePicked);
    _updateSelectedDateTime(combined);
  }

  Future<DateTime?> _selectDate(BuildContext context, DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, DateTime initialDate) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  void _updateSelectedDateTime(DateTime combined) {
    setState(() {
      _selectedDateTime = combined;
      _updateDateTimeController();
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _dateTimeController.clear();
    _commentController.clear();

    setState(() {
      _selectedHospital = null;
      _rating = null;
      _selectedDateTime = DateTime.now();
      _updateDateTimeController();
      _comment = '';
    });
  }

  // Form submission methods
  void _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      _showErrorMessage('Por favor, corrija os erros no formulário.');
      return;
    }

    try {
      final evaluation = _createEvaluation();
      final sqfliteDataSource = context.read<SqfliteSnsDataSource>();

      await sqfliteDataSource.attachEvaluation(_selectedHospital!.id, evaluation);

      _showSuccessMessage('Avaliação submetida com sucesso!');
      _resetForm();
    } catch (e) {
      _showErrorMessage('Erro ao submeter avaliação: $e');
    }
  }

  EvaluationReport _createEvaluation() {
    return EvaluationReport(
      hospitalId: _selectedHospital!.id,
      rating: _rating!,
      dateTime: DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime!),
      comment: _comment,
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
