import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../services/connectivity_service.dart';
import '../utils/screen_utils.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.w(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Internet connection icon
              Container(
                width: context.w(120),
                height: context.w(120),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off,
                  size: context.w(60),
                  color: Colors.red.shade400,
                ),
              ),

              SizedBox(height: context.h(32)),

              // Title
              Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(28) : context.sp(24),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: context.h(16)),

              // Description
              Text(
                'Please check your internet connection and try again. You can enable WiFi or mobile data from your device settings.',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(18) : context.sp(16),
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: context.h(40)),

              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: isTablet ? context.h(56) : context.h(50),
                    child: ElevatedButton(
                      onPressed: () {
                        ConnectivityService.showConnectivityDialog(
                          context,
                          isWifi: true,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                      ),
                      child: Text(
                        'Enable WiFi',
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(18) : context.sp(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: context.h(12)),

                  SizedBox(
                    width: double.infinity,
                    height: isTablet ? context.h(56) : context.h(50),
                    child: ElevatedButton(
                      onPressed: () {
                        ConnectivityService.showConnectivityDialog(
                          context,
                          isWifi: false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                      ),
                      child: Text(
                        'Enable Mobile Data',
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(18) : context.sp(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: context.h(12)),

                  SizedBox(
                    width: double.infinity,
                    height: isTablet ? context.h(56) : context.h(50),
                    child: OutlinedButton(
                      onPressed: () {
                        // Retry connection check
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(18) : context.sp(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
