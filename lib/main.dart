import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Login_page/widgets/login.dart';
import 'Home_page/home_page.dart';
import 'Home_page/My_Shop/my_shop_page.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'utils/performance_optimizer.dart';
import 'services/connectivity_service.dart';
import 'services/storage_service.dart';
import 'services/session_manager.dart';
import 'widgets/no_internet_page.dart';
import 'notifications/notification_service.dart';
import 'theme/sipora_theme.dart';
import 'widgets/animated_splash_screen.dart';

// ✅ Global key for ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await NotificationService.initialize();
  PerformanceOptimizer.initialize();
  ConnectivityService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Widget? _homeWidget;
  bool _isLoading = true;
  bool _hasInternet = true;
  StreamSubscription<bool>? _connectivitySubscription;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  bool _showAnimatedSplash = true;

  // Flag to prevent multiple simultaneous checks
  bool _isCheckingLogin = false;

  // Track if app is in background
  bool _isAppInBackground = false;

  // ✅ Track if auth failure is already being handled
  bool _isHandlingAuthFailure = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // Stop session monitoring if running
    SessionManager.stopMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        // Check login status when app returns to foreground
        _checkLoginStatus();
        break;
      case AppLifecycleState.paused:
        _isAppInBackground = true;
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initializeApp() async {
    _setupConnectivityListener();
    await _checkLoginStatus();
    _setupAuthFailureCallback();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivityService.internetStatusStream
        .listen((hasInternet) async {
          if (hasInternet != _hasInternet && mounted) {
            setState(() {
              _hasInternet = hasInternet;
            });

            if (hasInternet) {
              // Only check if not in background
              if (!_isAppInBackground) {
                await _checkLoginStatus();
              }
            } else {
              setState(() {
                _homeWidget = const NoInternetPage();
                _showAnimatedSplash = false;
                _isLoading = false;
              });
            }
          }
        });
  }

  void _setupAuthFailureCallback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.onAuthFailure = () {
        _handleAuthFailure();
      };
    });
  }

  Future<void> _handleAuthFailure() async {
    // ✅ Prevent multiple simultaneous auth failures
    if (_isHandlingAuthFailure) {
      debugPrint('⚠️ Auth failure already being handled, skipping...');
      return;
    }
    _isHandlingAuthFailure = true;

    if (!mounted) {
      _isHandlingAuthFailure = false;
      return;
    }

    debugPrint('🔄 Handling auth failure...');

    // Stop session monitoring
    SessionManager.stopMonitoring();

    // Clear all auth data
    await StorageService.clearAuthData();

    // Update user provider
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.clearUser();
    } catch (e) {
      debugPrint('⚠️ Error clearing user provider: $e');
    }

    if (mounted) {
      setState(() {
        _homeWidget = const HomePage();
        _isLoading = false;
        _showAnimatedSplash = false;
      });

      // ✅ Use the global scaffoldMessengerKey
      scaffoldMessengerKey.currentState?.clearSnackBars();
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }

    _isHandlingAuthFailure = false;
  }

  // ✅ Updated to check user role and navigate accordingly
  Future<void> _checkLoginStatus() async {
    // Prevent multiple simultaneous checks
    if (_isCheckingLogin) {
      return;
    }

    _isCheckingLogin = true;
    debugPrint('🔍 Starting login status check...');

    try {
      // Check internet connection
      final hasInternet = await _connectivityService.hasInternetConnection();
      if (!hasInternet) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasInternet = false;
            _homeWidget = const NoInternetPage();
            _showAnimatedSplash = false;
          });
        }
        _isCheckingLogin = false;
        return;
      }

      if (mounted) {
        setState(() {
          _hasInternet = true;
        });
      }

      // Check if user is logged in with valid token
      final token = await StorageService.getToken();
      // debugPrint('🔍 Token found: ${token != null ? "Yes" : "No"}');

      if (token != null) {
        // Check if token is valid locally
        final isValid = await StorageService.isTokenValid();
        // debugPrint('🔍 Token valid locally: $isValid');

        if (!isValid) {
          debugPrint('❌ Token expired, redirecting to login');
          await StorageService.clearAuthData();
          if (mounted) {
            setState(() {
              _homeWidget = const HomePage();
              _isLoading = false;
              _showAnimatedSplash = false;
            });
          }
        } else {
          // ✅ Only validate with backend if token is valid locally
          bool isBackendValid = true;
          try {
            isBackendValid = await StorageService.validateSessionWithBackend();
            debugPrint('🔍 Backend session valid: $isBackendValid');
          } catch (e) {
            // ✅ If backend validation fails (network error), keep session valid
            debugPrint(
              '⚠️ Backend validation error: $e, keeping session valid',
            );
            isBackendValid = true;
          }

          if (!isBackendValid) {
            debugPrint('❌ Backend session invalid, redirecting to login');
            await StorageService.clearAuthData();
            if (mounted) {
              setState(() {
                _homeWidget = const HomePage();
                _isLoading = false;
                _showAnimatedSplash = false;
              });
            }
          } else {
            // ✅ Token is valid - check user data
            final userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );

            // ✅ Temporarily disable auth failure callback
            final originalCallback = userProvider.onAuthFailure;
            userProvider.onAuthFailure = null;

            try {
              final userLoaded = await userProvider.loadUser();
              debugPrint(
                '🔍 User loaded: $userLoaded, Authenticated: ${userProvider.isAuthenticated}',
              );

              if (userLoaded && userProvider.isAuthenticated) {
                // ✅ CHECK USER ROLE to determine which screen to show
                final userRole = await StorageService.getUserRole();
                debugPrint('🔍 User role from StorageService: $userRole');

                // Also check from SharedPreferences directly
                final prefs = await SharedPreferences.getInstance();
                final roleFromPrefs = prefs.getString('user_role');
                debugPrint(
                  '🔍 User role from SharedPreferences: $roleFromPrefs',
                );

                // Use the role from StorageService or fallback to prefs
                final effectiveRole = userRole ?? roleFromPrefs ?? 'user';
                debugPrint('🔍 Effective role: $effectiveRole');

                // Check if user is a franchise owner
                final isFranchiseOwner =
                    effectiveRole.toLowerCase().contains('franchise') ||
                    effectiveRole.toLowerCase() == 'franchise_owner' ||
                    effectiveRole.toLowerCase() == 'franchiseowner' ||
                    effectiveRole.toLowerCase() == 'franchise-admin' ||
                    effectiveRole.toLowerCase() == 'franchiseadmin';

                debugPrint('🔍 Is franchise owner: $isFranchiseOwner');

                if (mounted) {
                  setState(() {
                    // ✅ Show MyShopPage for franchise owners, HomePage for regular users
                    _homeWidget = isFranchiseOwner
                        ? const MyShopPage()
                        : const HomePage();
                    _isLoading = false;
                    _showAnimatedSplash = false;
                  });
                }

                // Start session monitoring after successful login
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      SessionManager.startMonitoring(context);
                    }
                  });
                }
              } else {
                debugPrint('⚠️ User data not loaded, staying on login');
                if (mounted) {
                  setState(() {
                    _homeWidget = const HomePage();
                    _isLoading = false;
                    _showAnimatedSplash = false;
                  });
                }
              }
            } catch (e) {
              // ✅ If user data fails to load, don't clear auth
              debugPrint('⚠️ Error loading user data: $e, keeping token valid');
              if (mounted) {
                setState(() {
                  _homeWidget = const HomePage();
                  _isLoading = false;
                  _showAnimatedSplash = false;
                });
              }
            } finally {
              // ✅ Restore callback
              userProvider.onAuthFailure = originalCallback;
            }
          }
        }
      } else {
        // debugPrint('🔴 No token found, showing login');
        if (mounted) {
          setState(() {
            _homeWidget = const HomePage();
            _isLoading = false;
            _showAnimatedSplash = false;
          });
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking login status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _homeWidget = const HomePage();
          _showAnimatedSplash = false;
        });
      }
    } finally {
      _isCheckingLogin = false;
    }
  }

  void _onSplashComplete() {
    setState(() {
      _showAnimatedSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ScreenUtilPlusInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          autoRebuild: false,
          builder: (context, child) {
            return MaterialApp(
              // ✅ Add the scaffoldMessengerKey
              scaffoldMessengerKey: scaffoldMessengerKey,
              debugShowCheckedModeBanner: false,
              title: "Sipora",
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              home: _showAnimatedSplash
                  ? AnimatedSplashScreen(onAnimationComplete: _onSplashComplete)
                  : _isLoading
                  ? Scaffold(
                      backgroundColor:
                          Theme.of(
                            context,
                          ).extension<SiporaThemeExtension>()?.cream ??
                          SiporaTheme.creamLight,
                      body: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _homeWidget,
            );
          },
          child: const SizedBox.shrink(),
        );
      },
    );
  }
}
