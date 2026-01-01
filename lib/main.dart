import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';

void main() {
  runApp(ChargingMonitorApp());
}

class ChargingMonitorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مراقب سرعة الشحن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Cairo',
      ),
      home: ChargingMonitorScreen(),
    );
  }
}

class ChargingMonitorScreen extends StatefulWidget {
  @override
  _ChargingMonitorScreenState createState() => _ChargingMonitorScreenState();
}

class _ChargingMonitorScreenState extends State<ChargingMonitorScreen> {
  final Battery _battery = Battery();
  
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  
  List<BatteryReading> _readings = [];
  double _chargingSpeed = 0.0;
  String _chargerType = 'غير معروف';
  int _minutesRemaining = 0;
  
  Timer? _updateTimer;
  
  @override
  void initState() {
    super.initState();
    _initBattery();
    _startMonitoring();
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
  
  void _initBattery() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    
    setState(() {
      _batteryLevel = level;
      _batteryState = state;
    });
    
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      setState(() {
        _batteryState = state;
      });
    });
  }
  
  void _startMonitoring() {
    _updateTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      await _updateBatteryInfo();
    });
    
    _updateBatteryInfo();
  }
  
  Future<void> _updateBatteryInfo() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    final now = DateTime.now();
    
    setState(() {
      _batteryLevel = level;
      _batteryState = state;
      
      if (state == BatteryState.charging) {
        _readings.add(BatteryReading(level: level, time: now));
        
        if (_readings.length > 20) {
          _readings.removeAt(0);
        }
        
        _calculateChargingSpeed();
      } else {
        _readings.clear();
        _chargingSpeed = 0.0;
        _chargerType = 'غير متصل';
        _minutesRemaining = 0;
      }
    });
  }
  
  void _calculateChargingSpeed() {
    if (_readings.length < 2) {
      _chargingSpeed = 0.0;
      return;
    }
    
    List<double> speeds = [];
    
    for (int i = 1; i < _readings.length; i++) {
      final timeDiff = _readings[i].time.difference(_readings[i-1].time).inSeconds / 60.0;
      final levelDiff = _readings[i].level - _readings[i-1].level;
      
      if (timeDiff > 0 && levelDiff > 0) {
        speeds.add(levelDiff / timeDiff);
      }
    }
    
    if (speeds.isEmpty) {
      _chargingSpeed = 0.0;
      return;
    }
    
    _chargingSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
    
    if (_chargingSpeed > 1.5) {
      _chargerType = '⚡ شحن سريع جداً';
    } else if (_chargingSpeed > 1.0) {
      _chargerType = '⚡ شحن سريع';
    } else if (_chargingSpeed > 0.5) {
      _chargerType = '🔌 شحن عادي';
    } else if (_chargingSpeed > 0) {
      _chargerType = '🐌 شحن بطيء';
    }
    
    if (_chargingSpeed > 0) {
      final remainingPercent = 100 - _batteryLevel;
      _minutesRemaining = (remainingPercent / _chargingSpeed).round();
    }
  }
  
  String _getTimeRemaining() {
    if (_minutesRemaining == 0 || _batteryState != BatteryState.charging) {
      return '--';
    }
    
    final hours = _minutesRemaining ~/ 60;
    final minutes = _minutesRemaining % 60;
    
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    } else {
      return '$minutes دقيقة';
    }
  }
  
  String _getBatteryIcon() {
    if (_batteryLevel < 20) return '🪫';
    if (_batteryLevel < 50) return '🔋';
    if (_batteryLevel < 80) return '🔋';
    return '🔋';
  }
  
  Color _getSpeedColor() {
    if (_chargingSpeed > 1.5) return Colors.green;
    if (_chargingSpeed > 1.0) return Colors.lightGreen;
    if (_chargingSpeed > 0.5) return Colors.orange;
    return Colors.red;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '⚡ مراقب سرعة الشحن',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Battery Display
                        Text(
                          _getBatteryIcon(),
                          style: TextStyle(fontSize: 80),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '$_batteryLevel%',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _batteryState == BatteryState.charging
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _batteryState == BatteryState.charging
                                ? '🔌 جاري الشحن'
                                : '⚠️ غير متصل بالشاحن',
                            style: TextStyle(
                              color: _batteryState == BatteryState.charging
                                  ? Colors.green.shade900
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 30),
                        
                        // Speed Indicator
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'سرعة الشحن',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _batteryState == BatteryState.charging && _chargingSpeed > 0
                                    ? '${_chargingSpeed.toStringAsFixed(2)} %/دقيقة'
                                    : 'جاري القياس...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Info Card
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow('نوع الشاحن', _chargerType),
                              Divider(height: 30),
                              _buildInfoRow('الوقت المتبقي', _getTimeRemaining()),
                              Divider(height: 30),
                              _buildInfoRow(
                                'عدد القراءات',
                                '${_readings.length}',
                              ),
                            ],
                          ),
                        ),
                        
                        if (_batteryState != BatteryState.charging) ...[
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              border: Border.all(color: Colors.orange.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange.shade900),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'قم بتوصيل الشاحن لبدء القياس',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        SizedBox(height: 20),
                        
                        ElevatedButton.icon(
                          onPressed: _updateBatteryInfo,
                          icon: Icon(Icons.refresh),
                          label: Text(
                            'تحديث القراءة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        Text(
                          '💡 التطبيق يحتاج دقيقة واحدة لحساب سرعة الشحن بدقة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class BatteryReading {
  final int level;
  final DateTime time;
  
  BatteryReading({required this.level, required this.time});
}
