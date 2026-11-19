import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/account_store.dart';
import '../../data/transaction_store.dart';
import '../home/transaction_picker_sheets.dart';

enum _ReceiptStep { camera, result }

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen>
    with WidgetsBindingObserver {
  static const _captureChannel = MethodChannel('fintrack/receipt_capture');
  static const _categories = [
    'Продукти',
    'Транспорт',
    'Ресторани та кафе',
    'Покупки',
    'Здоров’я',
    'Розваги',
    'Освіта',
    'Дім',
    'Інше',
  ];
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  final List<_ReceiptLine> _lines = [];
  _ReceiptStep _step = _ReceiptStep.camera;
  Uint8List? _receiptImage;
  String _category = _categories.first;
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _cameraInitializing = false;
  bool _takingPhoto = false;
  CameraController? _cameraController;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  int get _lineTotalCents => _lines.fold<int>(0, (sum, line) {
    final amount = _parseAmount(line.amountController.text);
    return sum + ((amount != null && amount > 0) ? (amount * 100).round() : 0);
  });

  int get _totalCents {
    if (_lineTotalCents > 0) return _lineTotalCents;
    final amount = _parseAmount(_amountController.text) ?? 0;
    return amount > 0 ? (amount * 100).round() : 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cameraController?.dispose());
    _merchantController.dispose();
    _amountController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_step != _ReceiptStep.camera) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_releaseCamera());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameraInitializing || _cameraController?.value.isInitialized == true) {
      return;
    }
    _cameraInitializing = true;
    if (mounted) setState(() => _cameraError = null);
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'На пристрої не знайдено камеру.');
      }
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted ||
          _step != _ReceiptStep.camera ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraError = null;
      });
    } on CameraException catch (error) {
      if (mounted) setState(() => _cameraError = _cameraMessage(error));
      await controller?.dispose();
    } catch (_) {
      if (mounted) {
        setState(() => _cameraError = 'Не вдалося під’єднатися до камери.');
      }
      await controller?.dispose();
    } finally {
      _cameraInitializing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _releaseCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (mounted) setState(() {});
    await controller?.dispose();
  }

  String _cameraMessage(CameraException error) => switch (error.code) {
    'CameraAccessDenied' || 'CameraAccessDeniedWithoutPrompt' =>
      'Дозвольте FinTrack використовувати камеру в налаштуваннях пристрою.',
    'noCamera' => error.description ?? 'На пристрої не знайдено камеру.',
    _ => error.description ?? 'Не вдалося відкрити камеру.',
  };

  Future<void> _takePhoto() async {
    final controller = _cameraController;
    if (_takingPhoto || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _takingPhoto = true);
    try {
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      if (mounted) _showCapturedImage(bytes);
    } on CameraException catch (error) {
      if (mounted) _showMessage(_cameraMessage(error));
    } catch (_) {
      if (mounted) {
        _showMessage('Не вдалося зробити фото чека. Спробуйте ще раз.');
      }
    } finally {
      if (mounted) setState(() => _takingPhoto = false);
    }
  }

  Future<void> _choosePhoto() => _pickImage('gallery');

  Future<void> _pickImage(String source) async {
    try {
      final bytes = await _captureChannel.invokeMethod<Uint8List>(source);
      if (!mounted || bytes == null) return;
      _showCapturedImage(bytes);
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Не вдалося відкрити фото.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Перезапустіть застосунок, щоб увімкнути камеру та галерею.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCapturedImage(Uint8List bytes) {
    setState(() {
      _receiptImage = bytes;
      _step = _ReceiptStep.result;
    });
    unawaited(_releaseCamera());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _enterManually() {
    setState(() => _step = _ReceiptStep.result);
    unawaited(_releaseCamera());
  }

  void _addLine() {
    setState(() => _lines.add(_ReceiptLine()));
  }

  void _removeLine(_ReceiptLine line) {
    setState(() => _lines.remove(line));
    line.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showTransactionDatePicker(
      context,
      selectedDate: _date,
    );
    if (selected == null || !mounted) return;
    setState(() => _date = selected);
  }

  Future<void> _saveExpense() async {
    if (_saving) return;
    if (_totalCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вкажіть суму чека або додайте позиції з цінами.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await AccountStore.instance.load();
    final accounts = AccountStore.instance.accounts;
    final account = accounts.isEmpty ? null : accounts.first;
    final itemsComment = _lines
        .where((line) => line.nameController.text.trim().isNotEmpty)
        .map((line) => line.nameController.text.trim())
        .join(', ');
    final merchant = _merchantController.text.trim();
    final comment = [
      if (merchant.isNotEmpty) merchant,
      if (itemsComment.isNotEmpty) itemsComment,
    ].join(' · ');
    await TransactionStore.instance.add(
      TransactionRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: merchant.isEmpty ? _category : merchant,
        category: _category,
        amountCents: _totalCents,
        type: TransactionType.expense,
        date: _date,
        accountId: account?.id,
        accountName: account?.name ?? 'Готівка',
        comment: comment,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _scanAnother() {
    for (final line in _lines) {
      line.dispose();
    }
    setState(() {
      _lines.clear();
      _merchantController.clear();
      _amountController.text = '0';
      _category = _categories.first;
      _date = DateTime.now();
      _receiptImage = null;
      _step = _ReceiptStep.camera;
    });
    unawaited(_initializeCamera());
  }

  @override
  Widget build(BuildContext context) {
    final isCamera = _step == _ReceiptStep.camera;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isCamera
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.black,
              systemNavigationBarColor: Colors.black,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: AppColors.background,
            ),
      child: Scaffold(
        backgroundColor: isCamera
            ? const Color(0xFF121212)
            : AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: switch (_step) {
                    _ReceiptStep.camera => _buildCameraPage(),
                    _ReceiptStep.result => _buildResultPage(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isCamera = _step == _ReceiptStep.camera;
    final title = switch (_step) {
      _ReceiptStep.camera => '',
      _ReceiptStep.result => 'Результат',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: isCamera ? 'Закрити' : 'Назад',
            onPressed: () {
              if (_step == _ReceiptStep.result) {
                setState(() => _step = _ReceiptStep.camera);
                unawaited(_initializeCamera());
              } else {
                Navigator.of(context).maybePop();
              }
            },
            icon: Icon(
              isCamera ? Icons.close_rounded : Icons.arrow_back_rounded,
              color: isCamera ? Colors.white : AppColors.textPrimary,
            ),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCamera ? Colors.white : AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (isCamera)
            IconButton(
              tooltip: 'Обрати з галереї',
              onPressed: _choosePhoto,
              icon: const Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
              ),
              visualDensity: VisualDensity.compact,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCameraPage() => LayoutBuilder(
    key: const ValueKey('camera'),
    builder: (context, constraints) {
      final previewHeight = (constraints.maxHeight * 0.68)
          .clamp(280.0, 520.0)
          .toDouble();
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: Column(
          children: [
            const Text(
              'Наведіть камеру на чек,\nщоб він повністю помістився в рамку',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: previewHeight,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildLiveCameraPreview(),
                    IgnorePointer(
                      child: CustomPaint(painter: _ViewfinderPainter()),
                    ),
                    Positioned(
                      bottom: 18,
                      left: 36,
                      right: 36,
                      child: Text(
                        _cameraInitializing
                            ? 'Під’єднуємо камеру…'
                            : 'Тримайте чек рівно та уникайте відблисків',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: _choosePhoto,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(50, 50),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
                const SizedBox(width: 24),
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap:
                        _cameraController?.value.isInitialized == true &&
                            !_takingPhoto
                        ? _takePhoto
                        : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 4),
                      ),
                      child: _takingPhoto
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton.filledTonal(
                  onPressed: _enterManually,
                  tooltip: 'Ввести вручну',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(50, 50),
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  Widget _buildLiveCameraPreview() {
    final camera = _cameraController;
    if (camera != null && camera.value.isInitialized) {
      final size = camera.value.previewSize;
      if (size == null) return CameraPreview(camera);
      return ColoredBox(
        color: Colors.black,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: size.height,
            height: size.width,
            child: CameraPreview(camera),
          ),
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xFF202522),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_cameraInitializing)
                const CircularProgressIndicator(color: Colors.white)
              else ...[
                const Icon(
                  Icons.no_photography_outlined,
                  size: 38,
                  color: Colors.white70,
                ),
                const SizedBox(height: 12),
                Text(
                  _cameraError ?? 'Камера недоступна',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _initializeCamera,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Спробувати ще раз'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultPage() => ListView(
    key: const ValueKey('result'),
    padding: const EdgeInsets.fromLTRB(18, 2, 18, 26),
    children: [
      if (_receiptImage != null) ...[
        Container(
          height: 190,
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(_receiptImage!, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Фото додано. Внесіть суму й товари вручну та перевірте дані перед збереженням.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
      ],
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1D7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFFE79830),
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _merchantController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Магазин або назва операції',
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Змінити дату',
              onPressed: _selectDate,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.calendar_month_outlined, size: 19),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Товари з чека',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton.icon(
            onPressed: _addLine,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Додати'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      if (_lines.isEmpty)
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Додайте товари й ціни з чека або введіть лише загальну суму нижче.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        )
      else
        for (var index = 0; index < _lines.length; index++)
          _buildLineEditor(_lines[index], index),
      if (_lineTotalCents == 0) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            labelText: 'Загальна сума',
            suffixText: '₴',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _category,
        decoration: InputDecoration(
          labelText: 'Категорія витрат',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        items: [
          for (final category in _categories)
            DropdownMenuItem(value: category, child: Text(category)),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _category = value);
        },
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Загальна сума',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${formatMoneyCents(_totalCents)} ₴',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _saving ? null : _saveExpense,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Зберегти як витрату'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _saving ? null : _scanAnother,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text('Сканувати інший чек'),
      ),
    ],
  );

  Widget _buildLineEditor(_ReceiptLine line, int index) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: line.nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Товар ${index + 1}',
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          width: 84,
          child: TextField(
            controller: line.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '0.00',
              suffixText: '₴',
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: () => _removeLine(line),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded, size: 17),
          color: AppColors.inactive,
        ),
      ],
    ),
  );
}

class _ReceiptLine {
  final nameController = TextEditingController();
  final amountController = TextEditingController();

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.3
      ..style = PaintingStyle.stroke;
    const length = 24.0;
    const radius = 8.0;
    for (final corner in <(double, double, double, double)>[
      (14, 14, 1, 1),
      (size.width - 14, 14, -1, 1),
      (14, size.height - 14, 1, -1),
      (size.width - 14, size.height - 14, -1, -1),
    ]) {
      final x = corner.$1;
      final y = corner.$2;
      final dx = corner.$3;
      final dy = corner.$4;
      final path = Path()
        ..moveTo(x, y + dy * length)
        ..lineTo(x, y + dy * radius)
        ..quadraticBezierTo(x, y, x + dx * radius, y)
        ..lineTo(x + dx * length, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double? _parseAmount(String value) =>
    double.tryParse(value.replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.'));
