import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'firebase_options.dart';

const Color cDeepNavy = Color(0xFF001D39);
const Color cRoyalSlate = Color(0xFF0A4174);
const Color cSteelBlue = Color(0xFF49769F);
const Color cOceanTeal = Color(0xFF4E8EA2);
const Color cMutedCyan = Color(0xFF6EA2B3);
const Color cSkyBlue = Color(0xFF7BBDE8);
const Color cSoftIceBlue = Color(0xFFBDD8E9);

const Color surfaceBg = Color(0xFFF2F7FA);
const Color surfaceWhite = Color(0xFFFFFFFF);
const Color alertRed = Color(0xFFE63946);
const Color alertOrange = Color(0xFFF59E0B);
const Color successGreen = Color(0xFF10B981);

const String rtdbUrl = "";

String getModelPath(String fileName) {
  return kIsWeb ? 'assets/assets/models/$fileName' : 'assets/models/$fileName';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RoadMonitorApp());
}

class RoadMonitorApp extends StatelessWidget {
  const RoadMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Road Condition Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: surfaceBg,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme:
            ColorScheme.fromSeed(seedColor: cRoyalSlate, surface: surfaceWhite),
      ),
      home: const MainRootScreen(),
    );
  }
}

Map<String, dynamic> asMap(dynamic value) =>
    (value is Map) ? value.map((k, v) => MapEntry(k.toString(), v)) : {};
double asDouble(dynamic value) => (value == null)
    ? 0.0
    : ((value is num)
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0.0);
int asInt(dynamic value) => (value == null)
    ? 0
    : ((value is num) ? value.toInt() : int.tryParse(value.toString()) ?? 0);
bool asBool(dynamic value) =>
    (value is bool) ? value : (value?.toString().toLowerCase() == 'true');
String format2(dynamic v) => asDouble(v).toStringAsFixed(2);
String format6(dynamic v) => asDouble(v).toStringAsFixed(6);

List<Map<String, dynamic>> parseSortedPoints(dynamic rawData,
    {bool descending = false}) {
  final rows = <Map<String, dynamic>>[];
  if (rawData is Map) {
    rawData.forEach((k, v) {
      if (v is Map) {
        final r = asMap(v);
        r['_id'] = k.toString();
        rows.add(r);
      }
    });
  }
  rows.sort((a, b) {
    final ta = asInt(a['timestamp']);
    final tb = asInt(b['timestamp']);
    return descending ? tb.compareTo(ta) : ta.compareTo(tb);
  });
  return rows;
}

class MainRootScreen extends StatefulWidget {
  const MainRootScreen({super.key});

  @override
  State<MainRootScreen> createState() => _MainRootScreenState();
}

class _MainRootScreenState extends State<MainRootScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceBg,
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: const [
              DashboardTab(),
              LiveMapTab(),
              DataSessionsTab(),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: cDeepNavy.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(Icons.home_filled, 'Home', 0),
                  _navItem(Icons.map_outlined, 'Route', 1),
                  _navItem(Icons.folder_shared_outlined, 'Logs', 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool isSelected = selectedIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => selectedIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSelected ? cRoyalSlate : cSteelBlue),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: cDeepNavy)),
            ],
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late final DatabaseReference rootRef;
  final String deviceId = 'rpi_road_01';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    rootRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: rtdbUrl,
    ).ref();
  }

  Future<void> _handleStart(Map<String, dynamic> live) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final sessionKey = 'session_${DateTime.now().millisecondsSinceEpoch}';
      final double lat = asDouble(live['latitude']);
      final double lng = asDouble(live['longitude']);

      await rootRef.child('road_sessions/$sessionKey').set({
        'sessionName':
            'Run ${DateFormat('MMM dd, HH:mm').format(DateTime.now())}',
        'startTime': ServerValue.timestamp,
        'startPoint': {
          'lat': lat != 0.0 ? lat : 18.989400,
          'lng': lng != 0.0 ? lng : 73.117500,
        },
      });

      await rootRef.child('devices/$deviceId/control').set({
        'logging': true,
        'command': 'START',
        'activeSessionId': sessionKey,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logging STARTED ($sessionKey)',
              style: GoogleFonts.poppins()),
          backgroundColor: cRoyalSlate,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Firebase Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: alertRed),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleStop(Map<String, dynamic> live) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final ctrlSnap = await rootRef.child('devices/$deviceId/control').get();
      final ctrl = ctrlSnap.exists ? asMap(ctrlSnap.value) : {};
      final activeSession = ctrl['activeSessionId']?.toString();

      final double lat = asDouble(live['latitude']);
      final double lng = asDouble(live['longitude']);

      if (activeSession != null && activeSession.isNotEmpty) {
        await rootRef.child('road_sessions/$activeSession').update({
          'endTime': ServerValue.timestamp,
          'stopPoint': {
            'lat': lat != 0.0 ? lat : 18.989400,
            'lng': lng != 0.0 ? lng : 73.117500,
          },
        });
      }

      await rootRef.child('devices/$deviceId/control').set({
        'logging': false,
        'command': 'STOP',
        'activeSessionId': '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logging STOPPED and saved to Logs',
              style: GoogleFonts.poppins()),
          backgroundColor: cDeepNavy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Firebase Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: alertRed),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _tareSensor() async {
    await rootRef
        .child('devices/$deviceId/control')
        .update({'command': 'tare'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Tare command sent', style: GoogleFonts.poppins()),
          backgroundColor: cDeepNavy),
    );
  }

  Future<void> _calibrateSensor() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaceWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Start Calibration?',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, color: cDeepNavy)),
          content: Text('Calibrates sensor zero offsets.',
              style: GoogleFonts.poppins(color: cSteelBlue, fontSize: 13)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: cSteelBlue))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: cRoyalSlate, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Start',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await rootRef
          .child('devices/$deviceId/control')
          .update({'command': 'calibrate', 'logging': false});
      await rootRef
          .child('devices/$deviceId/status')
          .update({'calibrationMode': true, 'bno055Calibrated': false});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: rootRef.child('devices/$deviceId').onValue,
      builder: (context, snapshot) {
        final data = (snapshot.hasData && snapshot.data!.snapshot.value != null)
            ? asMap(snapshot.data!.snapshot.value)
            : <String, dynamic>{};
        final live = asMap(data['live']);
        final ctrl = asMap(data['control']);
        final status = asMap(data['status']);

        final bool isLogging = asBool(ctrl['logging']);
        final double leftVib = asDouble(live['leftVibration']);
        final double rightVib = asDouble(live['rightVibration']);
        final double speed = asDouble(live['gpsSpeed']);
        final bool gpsValid = asBool(live['gpsValid']);
        final int pointCount = asInt(live['recordedPointsCount']);
        final double avgVib = (leftVib + rightVib) / 2.0;
        final double roadIndex = math.min(avgVib / 1.2, 1.0);

        return Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 190),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                                radius: 20,
                                backgroundColor: cSoftIceBlue,
                                child: Icon(Icons.person,
                                    color: cDeepNavy, size: 22)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fleet Telemetry',
                                    style: GoogleFonts.poppins(
                                        color: cSteelBlue, fontSize: 12)),
                                Text('Mini Truck Mk-II',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: cDeepNavy)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Grounded Semicircle Gauge
                    Center(
                      child: SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(290, 240),
                              painter: SegmentedSemicircleGaugePainter(
                                  progress: roadIndex),
                            ),
                            Positioned(
                              bottom: 35,
                              width: 250,
                              height: 145,
                              child: ModelViewer(
                                src: getModelPath('mini-truck.glb'),
                                alt: '3D Mini Truck',
                                autoRotate: true,
                                cameraControls: true,
                                cameraOrbit: "45deg 65deg 180%",
                                fieldOfView: "30deg",
                                loading: Loading.eager,
                                reveal: Reveal.auto,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              child: Column(
                                children: [
                                  Text(
                                    roadIndex > 0.6
                                        ? 'ROUGH SURFACE'
                                        : 'SMOOTH PAVEMENT',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: roadIndex > 0.6
                                            ? alertRed
                                            : cOceanTeal),
                                  ),
                                  Text(
                                      'IRI Shock Index: ${(roadIndex * 10).toStringAsFixed(1)} / 10',
                                      style: GoogleFonts.poppins(
                                          color: cSteelBlue, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                            child: _interactiveCard(
                                'Left Leaf Spring', leftVib, cRoyalSlate)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _interactiveCard(
                                'Right Leaf Spring', rightVib, cOceanTeal)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // GPS Telemetry
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: cDeepNavy.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_searching_rounded,
                                      size: 18, color: cRoyalSlate),
                                  const SizedBox(width: 8),
                                  Text('GPS Telemetry',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: cDeepNavy)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: gpsValid
                                        ? cSoftIceBlue
                                        : alertRed.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                    gpsValid ? 'FIX LOCKED' : 'SEARCHING',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            gpsValid ? cRoyalSlate : alertRed)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Velocity',
                                      style: GoogleFonts.poppins(
                                          color: cSteelBlue, fontSize: 11)),
                                  Text('${speed.toStringAsFixed(1)} km/h',
                                      style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: cDeepNavy)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Position Coordinates',
                                      style: GoogleFonts.poppins(
                                          color: cSteelBlue, fontSize: 11)),
                                  Text(
                                      '${format6(live['latitude'])}, ${format6(live['longitude'])}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: cDeepNavy)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Calibration Snippet
                    CalibrationSnippet(
                      status: status,
                      onTare: _tareSensor,
                      onCalibrate: _calibrateSensor,
                    ),
                  ],
                ),
              ),
            ),

            // LIVE RECORDING STATUS BAR & CONTROL BUTTONS
            Positioned(
              left: 20,
              right: 20,
              bottom: 84,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLogging)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: alertRed.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: alertRed.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fiber_manual_record,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'RECORDING ACTIVE • $pointCount POINTS LOGGED',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: surfaceWhite,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                            color: cDeepNavy.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (!isLogging && !_isProcessing)
                                  ? cRoyalSlate
                                  : cSoftIceBlue,
                              foregroundColor: (!isLogging && !_isProcessing)
                                  ? Colors.white
                                  : cSteelBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: (!isLogging && !_isProcessing)
                                ? () => _handleStart(live)
                                : null,
                            icon: _isProcessing && !isLogging
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: cRoyalSlate))
                                : const Icon(Icons.play_arrow_rounded,
                                    size: 20),
                            label: Text('START',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (isLogging && !_isProcessing)
                                  ? alertRed
                                  : cSoftIceBlue,
                              foregroundColor: (isLogging && !_isProcessing)
                                  ? Colors.white
                                  : cSteelBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: (isLogging && !_isProcessing)
                                ? () => _handleStop(live)
                                : null,
                            icon: _isProcessing && isLogging
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: alertRed))
                                : const Icon(Icons.stop_rounded, size: 20),
                            label: Text('STOP',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _interactiveCard(String title, double vibration, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: cDeepNavy.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 12, color: cDeepNavy)),
          const SizedBox(height: 8),
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
                color: surfaceBg, borderRadius: BorderRadius.circular(14)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: IgnorePointer(
                child: ModelViewer(
                  key: ValueKey('leaf_$title'),
                  src: getModelPath('leaf_spring.glb'),
                  alt: 'Leaf Spring',
                  autoRotate: true,
                  cameraControls: false,
                  cameraOrbit: "0deg 75deg 105%",
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('${vibration.toStringAsFixed(2)} g',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: accentColor)),
        ],
      ),
    );
  }
}

class CalibrationSnippet extends StatelessWidget {
  final Map<String, dynamic> status;
  final VoidCallback onTare;
  final VoidCallback onCalibrate;

  const CalibrationSnippet(
      {super.key,
      required this.status,
      required this.onTare,
      required this.onCalibrate});

  int _val(String key) => asInt(status[key]);

  @override
  Widget build(BuildContext context) {
    final bool calMode = asBool(status['calibrationMode']);
    final bool calibrated = asBool(status['bno055Calibrated']);
    final values = [
      _val('s1Sys'),
      _val('s1Gyro'),
      _val('s1Accel'),
      _val('s1Mag'),
      _val('s2Sys'),
      _val('s2Gyro'),
      _val('s2Accel'),
      _val('s2Mag')
    ];
    final completedCount = values.where((v) => v == 3).length;
    final progress = completedCount / 8.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: cDeepNavy.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sensor Calibration & Offsets',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: cDeepNavy)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: calMode
                        ? alertOrange.withOpacity(0.12)
                        : successGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                    calMode
                        ? 'IN PROGRESS'
                        : (calibrated ? 'READY' : 'UNCALIBRATED'),
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: calMode ? alertOrange : successGreen)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: cSoftIceBlue,
                valueColor: const AlwaysStoppedAnimation<Color>(cRoyalSlate)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _calSensorBox('Sensor 1 (Left)', _val('s1Sys'),
                      _val('s1Gyro'), _val('s1Accel'), _val('s1Mag'))),
              const SizedBox(width: 8),
              Expanded(
                  child: _calSensorBox('Sensor 2 (Right)', _val('s2Sys'),
                      _val('s2Gyro'), _val('s2Accel'), _val('s2Mag'))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: cSteelBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: onTare,
                  child: Text('Tare Level',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, color: cDeepNavy)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: cRoyalSlate,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: onCalibrate,
                  child: Text('Calibrate',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calSensorBox(String name, int sys, int gyro, int accel, int mag) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cSoftIceBlue)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700, color: cDeepNavy)),
          const SizedBox(height: 4),
          _regPill('SYS', sys),
          _regPill('GYR', gyro),
          _regPill('ACC', accel),
          _regPill('MAG', mag),
        ],
      ),
    );
  }

  Widget _regPill(String label, int val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(fontSize: 10, color: cSteelBlue)),
          Text('$val/3',
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: val == 3 ? successGreen : alertOrange)),
        ],
      ),
    );
  }
}

class LiveMapTab extends StatefulWidget {
  const LiveMapTab({super.key});

  @override
  State<LiveMapTab> createState() => _LiveMapTabState();
}

class _LiveMapTabState extends State<LiveMapTab> {
  late final DatabaseReference rootRef;
  final String deviceId = 'rpi_road_01';
  GoogleMapController? mapController;
  static const LatLng defaultCenter = LatLng(18.989400, 73.117500);

  @override
  void initState() {
    super.initState();
    rootRef =
        FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: rtdbUrl)
            .ref();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: rootRef.child('devices/$deviceId').onValue,
      builder: (context, devSnap) {
        final devData =
            devSnap.hasData ? asMap(devSnap.data!.snapshot.value) : {};
        final ctrl = asMap(devData['control']);
        final live = asMap(devData['live']);
        final bool isLogging = asBool(ctrl['logging']);
        final activeSession = ctrl['activeSessionId']?.toString() ?? '';
        final currentLat = asDouble(live['latitude']);
        final currentLng = asDouble(live['longitude']);
        final LatLng currentLoc = (currentLat != 0.0 && currentLng != 0.0)
            ? LatLng(currentLat, currentLng)
            : defaultCenter;

        return StreamBuilder<DatabaseEvent>(
          stream: (isLogging && activeSession.isNotEmpty)
              ? rootRef.child('road_sessions/$activeSession').onValue
              : null,
          builder: (context, sessSnap) {
            final sessionData =
                (sessSnap.hasData && sessSnap.data!.snapshot.value != null)
                    ? asMap(sessSnap.data!.snapshot.value)
                    : <String, dynamic>{};
            final points = parseSortedPoints(sessionData['points']);
            final polylinePoints = <LatLng>[];

            if (isLogging) {
              for (final p in points) {
                final lat = asDouble(p['latitude']);
                final lng = asDouble(p['longitude']);
                if (lat != 0.0 && lng != 0.0)
                  polylinePoints.add(LatLng(lat, lng));
              }
            }

            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: currentLoc, zoom: 16),
                  markers: {
                    Marker(
                        markerId: const MarkerId('live_truck'),
                        position: currentLoc,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure)),
                  },
                  polylines: {
                    if (isLogging && polylinePoints.isNotEmpty)
                      Polyline(
                          polylineId: const PolylineId('route_trace'),
                          points: polylinePoints,
                          width: 6,
                          color: cRoyalSlate),
                  },
                  onMapCreated: (c) => mapController = c,
                ),
                Positioned(
                  top: 48,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: surfaceWhite.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(18)),
                    child: Text(
                      isLogging
                          ? 'TRACING TRIP (${polylinePoints.length} PTS)'
                          : 'STANDBY (AWAITING RUN)',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: isLogging ? cRoyalSlate : cSteelBlue),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class DataSessionsTab extends StatelessWidget {
  const DataSessionsTab({super.key});

  Future<void> _exportPdf(BuildContext context, String sessionId,
      Map<String, dynamic> sessionData) async {
    final points = parseSortedPoints(sessionData['points']);
    final startPt = asMap(sessionData['startPoint']);
    final stopPt = asMap(sessionData['stopPoint']);
    final name = sessionData['sessionName']?.toString() ?? sessionId;

    final doc = pw.Document();
    final tableHeaders = [
      'Time',
      'Left (g)',
      'Right (g)',
      'Avg (g)',
      'Speed',
      'Coordinates'
    ];
    final tableRows = points.map((p) {
      final t = asInt(p['timestamp']);
      final timeStr = t > 0
          ? DateFormat('HH:mm:ss')
              .format(DateTime.fromMillisecondsSinceEpoch(t))
          : '-';
      return [
        timeStr,
        format2(p['leftVib']),
        format2(p['rightVib']),
        format2(p['avgVib']),
        '${format2(p['gpsSpeed'])} km/h',
        '${format6(p['latitude'])}, ${format6(p['longitude'])}'
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Header(
              level: 0,
              child: pw.Text('Road Telemetry & Leaf Spring Audit Report',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 6),
          pw.Text(
              'Section: $name | Start: (${format6(startPt['lat'])}, ${format6(startPt['lng'])}) | Stop: (${format6(stopPt['lat'])}, ${format6(stopPt['lng'])})'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: tableHeaders,
            data: tableRows,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF001D39)),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
        bytes: await doc.save(), filename: '$sessionId.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final sessionsRef =
        FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: rtdbUrl)
            .ref('road_sessions');

    return SafeArea(
      child: StreamBuilder<DatabaseEvent>(
        stream: sessionsRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
                child: Text('No recorded sessions found.',
                    style: GoogleFonts.poppins(color: cSteelBlue)));
          }

          final rawSessions = asMap(snapshot.data!.snapshot.value);
          final sessionKeys = rawSessions.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Text('Road Vibration Audit Sections',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cDeepNavy)),
              const SizedBox(height: 14),
              ...sessionKeys.map((sId) {
                final sData = asMap(rawSessions[sId]);
                final pts = asMap(sData['points']);
                final sName = sData['sessionName']?.toString() ?? sId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: surfaceWhite,
                      borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(sName,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: cDeepNavy)),
                          Text('${pts.length} Sec Points',
                              style: GoogleFonts.poppins(
                                  color: cSteelBlue, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: cDeepNavy,
                              foregroundColor: Colors.white),
                          onPressed: pts.isEmpty
                              ? null
                              : () => _exportPdf(context, sId, sData),
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              size: 16),
                          label: Text('Download Session PDF',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class SegmentedSemicircleGaugePainter extends CustomPainter {
  final double progress;
  SegmentedSemicircleGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = size.width * 0.44;
    const int totalSegments = 20;
    const double totalAngle = math.pi;
    const double gapRatio = 0.28;
    final double segmentAngle = totalAngle / totalSegments;
    final double sweepAngle = segmentAngle * (1.0 - gapRatio);

    final int activeSegments =
        (progress.clamp(0.0, 1.0) * totalSegments).round();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < totalSegments; i++) {
      final double startAngle =
          math.pi + (i * segmentAngle) + (segmentAngle * gapRatio / 2);
      paint.color = i < activeSegments ? cRoyalSlate : const Color(0xFFE2E8F0);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SegmentedSemicircleGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
