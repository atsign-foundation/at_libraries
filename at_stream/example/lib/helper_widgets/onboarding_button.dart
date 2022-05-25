import 'package:flutter/material.dart';
import 'package:at_client_mobile/at_client_mobile.dart';

class OnboardingButton extends StatefulWidget {
  const OnboardingButton(this.onboard, {Key? key}) : super(key: key);
  final void Function(String?) onboard;

  @override
  State<OnboardingButton> createState() => _OnboardingButtonState();
}

class _OnboardingButtonState extends State<OnboardingButton> {
  // * Get the [KeyChainManager] instance
  final KeyChainManager _keyChainManager = KeyChainManager.getInstance();

  List<String>? _atSignsList = [];
  String? _atsign;

  @override
  void initState() {
    super.initState();
    initKeyChain();
  }

  // * Get the atsigns from the keychain and load them into [_atSignsList]
  Future<void> initKeyChain() async {
    var atSignsList = await _keyChainManager.getAtSignListFromKeychain();
    if (atSignsList?.isNotEmpty ?? false) {
      setState(() {
        _atSignsList = atSignsList;
        _atsign = atSignsList![0];
      });
    } else {
      setState(() {
        _atSignsList = atSignsList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasExistingAtSigns = _atSignsList?.isNotEmpty ?? false;
    return Column(
      children: [
        if (hasExistingAtSigns) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton(
                value: _atsign,
                items: _atSignsList!.map((atsign) => DropdownMenuItem(child: Text(atsign), value: atsign)).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _atsign = value;
                    });
                  }
                },
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => widget.onboard(_atsign),
                child: const Text('Go'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        ElevatedButton(
          onPressed: () => widget.onboard(''),
          child: const Text('New @sign'),
        ),
        if (hasExistingAtSigns) ...[
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () {
              _showResetDialog(context, false);
            },
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
            child: const Text(
              "Reset @signs",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ]
      ],
    );
  }

  // * This dialog shows a list of the available atSigns, selecting one calls [_resetAtSign]
  _showResetDialog(BuildContext context, bool shouldPop) {
    if (shouldPop) Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reset your atsigns"),
          content: SizedBox(
            height: 360,
            width: 240,
            child: SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _atSignsList!.length,
                itemBuilder: (BuildContext context, int index) {
                  return Row(
                    children: [
                      Text(_atSignsList![index]),
                      Expanded(
                        child: Container(),
                      ),
                      TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.red),
                        ),
                        child: const Text("Reset", style: TextStyle(color: Colors.white)),
                        onPressed: () => _resetAtSign(_atSignsList![index]),
                      )
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  // * This is a simple confirmation dialog that will remove the atsign from the keychain when accepted
  void _resetAtSign(String atsign) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reset Confirmation"),
          content: Text("Are you sure you want to reset $atsign?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                _showResetDialog(context, true);
              },
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red),
              ),
              child: const Text("Reset", style: TextStyle(color: Colors.white)),
              onPressed: () {
                // * This function removes the atsign from the keychain
                // * then it updates [_atSignsList] to maintain state
                _showResetDialog(context, true);
                _keyChainManager.deleteAtSignFromKeychain(atsign);
                setState(() {
                  if (_atSignsList!.length == 1) {
                    _atsign = null;
                  }
                  if (_atSignsList!.length > 1 && _atsign == atsign) {
                    _atsign = _atSignsList!.firstWhere((element) => element != atsign);
                  }
                  _atSignsList!.remove(atsign);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Reset $atsign',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
