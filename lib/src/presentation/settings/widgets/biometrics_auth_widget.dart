import 'package:flutter/material.dart';

import '../../../../main.dart';
import '../../../core/common.dart';
import '../../../data/settings/authenticate.dart';
import '../../widgets/future_resolve.dart';
import '../bloc/settings_controller.dart';

class BiometricAuthWidget extends StatefulWidget {
  const BiometricAuthWidget({
    super.key,
    required this.authenticate,
  });

  final Authenticate authenticate;

  @override
  State<BiometricAuthWidget> createState() => _BiometricAuthWidgetState();
}

class _BiometricAuthWidgetState extends State<BiometricAuthWidget> {
  final SettingsController settings = getIt.get<SettingsController>();
  late bool isSelected = settings.get(userAuthKey, defaultValue: false);

  @override
  Widget build(BuildContext context) => FutureResolve<List<bool>>(
        future: Future.wait([
          widget.authenticate.isDeviceSupported(),
          widget.authenticate.canCheckBiometrics()
        ]),
        builder: (supported) {
          return Visibility(
            visible: supported.every((element) => element),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    context.loc.localApp,
                  ),
                  onChanged: (bool value) async {
                    bool isAuthenticated = false;
                    if (value) {
                      isAuthenticated = await widget.authenticate
                          .authenticateWithBiometrics();
                    }
                    setState(() {
                      isSelected = value && isAuthenticated;
                    });
                    _showSnackBar(isSelected);
                  },
                  value: isSelected,
                ),
                const Divider(),
              ],
            ),
          );
        },
      );

  void _showSnackBar(bool result) => settings
      .put(userAuthKey, result)
      .then((value) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                result ? 'Authenticated' : 'Not authenticated',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ));
}
