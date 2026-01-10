import 'package:flutter/material.dart';

/// Global navigator key for navigation without BuildContext
/// Use this for notification routing when context may be unavailable
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
