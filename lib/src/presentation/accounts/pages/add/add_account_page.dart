import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paisa/src/presentation/widgets/paisa_annotate_region_widget.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../../../../main.dart';
import '../../../../core/common.dart';
import '../../../../core/enum/card_type.dart';
import '../../../settings/bloc/settings_controller.dart';
import '../../../widgets/paisa_big_button_widget.dart';
import '../../../widgets/paisa_bottom_sheet.dart';
import '../../../widgets/paisa_color_picker.dart';
import '../../../widgets/paisa_text_field.dart';
import '../../bloc/accounts_bloc.dart';
import '../../widgets/card_type_drop_down.dart';

final GlobalKey<FormState> _form = GlobalKey<FormState>();

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({
    Key? key,
    this.accountId,
  }) : super(key: key);

  final String? accountId;

  @override
  AddAccountPageState createState() => AddAccountPageState();
}

class AddAccountPageState extends State<AddAccountPage> {
  late final bool isAccountAddOrUpdate = widget.accountId == null;

  final accountNumberController = TextEditingController();
  final accountHolderController = TextEditingController();
  final accountNameController = TextEditingController();
  final accountInitialAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    BlocProvider.of<AccountsBloc>(context)
        .add(FetchAccountFromIdEvent(widget.accountId));
  }

  @override
  void dispose() {
    accountHolderController.dispose();
    accountInitialAmountController.dispose();
    accountNumberController.dispose();
    accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaisaAnnotatedRegionWidget(
      color: Theme.of(context).colorScheme.background,
      child: BlocConsumer<AccountsBloc, AccountsState>(
        listener: (context, state) {
          if (state is AccountAddedState) {
            context.showMaterialSnackBar(
              isAccountAddOrUpdate
                  ? context.loc.addedAccount
                  : context.loc.updateAccount,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            );
            context.pop();
          }
          if (state is AccountDeletedState) {
            context.showMaterialSnackBar(
              context.loc.deleteAccount,
              backgroundColor: Theme.of(context).colorScheme.error,
              color: Theme.of(context).colorScheme.onError,
            );
            context.pop();
          } else if (state is AccountErrorState) {
            context.showMaterialSnackBar(
              state.errorString,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              color: Theme.of(context).colorScheme.onErrorContainer,
            );
          } else if (state is AccountSuccessState) {
            accountNameController.text = state.account.bankName;
            accountNameController.selection =
                TextSelection.collapsed(offset: state.account.bankName.length);

            accountNumberController.text = state.account.number;
            accountNumberController.selection =
                TextSelection.collapsed(offset: state.account.number.length);

            accountHolderController.text = state.account.name;
            accountHolderController.selection =
                TextSelection.collapsed(offset: state.account.name.length);

            accountInitialAmountController.text =
                state.account.amount.toString();
            accountInitialAmountController.selection = TextSelection.collapsed(
                offset: state.account.amount.toString().length);
          }
        },
        builder: (context, state) {
          return ScreenTypeLayout(
            mobile: Scaffold(
              appBar: context.materialYouAppBar(
                isAccountAddOrUpdate
                    ? context.loc.addAccount
                    : context.loc.updateAccount,
                actions: [
                  isAccountAddOrUpdate
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: () {
                            paisaAlertDialog(
                              context,
                              title: Text(context.loc.dialogDeleteTitle),
                              child: RichText(
                                text: TextSpan(
                                  text: context.loc.deleteAccount,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text:
                                          BlocProvider.of<AccountsBloc>(context)
                                              .accountName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmationButton: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                onPressed: () {
                                  BlocProvider.of<AccountsBloc>(context).add(
                                      DeleteAccountEvent(
                                          int.parse(widget.accountId!)));

                                  Navigator.pop(context);
                                },
                                child: Text(context.loc.delete),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.delete_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                  IconButton(
                    onPressed: _showInfo,
                    icon: const Icon(Icons.info_rounded),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: CardTypeButtons(),
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      onTap: () async {
                        final color = await paisaColorPicker(
                          context,
                          defaultColor: BlocProvider.of<AccountsBloc>(context)
                                  .selectedColor ??
                              Colors.red.value,
                        );
                        if (context.mounted) {
                          BlocProvider.of<AccountsBloc>(context)
                              .add(AccountColorSelectedEvent(color));
                        }
                      },
                      leading: Icon(
                        Icons.color_lens,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        context.loc.pickColor,
                      ),
                      subtitle: Text(
                        context.loc.pickColorDesc,
                      ),
                      trailing: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(BlocProvider.of<AccountsBloc>(context)
                                  .selectedColor ??
                              Colors.red.value),
                        ),
                      ),
                    ),
                    Form(
                      key: _form,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            AccountCardHolderNameWidget(
                              controller: accountHolderController,
                            ),
                            const SizedBox(height: 16),
                            AccountNameWidget(
                              controller: accountNameController,
                            ),
                            const SizedBox(height: 16),
                            AccountInitialAmountWidget(
                              controller: accountInitialAmountController,
                            ),
                            const SizedBox(height: 16),
                            Builder(
                              builder: (context) {
                                if (state is UpdateCardTypeState &&
                                    state.cardType == CardType.bank) {
                                  return AccountNumberWidget(
                                    controller: accountNumberController,
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            AccountDefaultSwitchWidget(
                              accountId:
                                  int.tryParse(widget.accountId ?? '') ?? -1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: PaisaBigButton(
                    onPressed: () {
                      final isValid = _form.currentState!.validate();
                      if (!isValid) {
                        return;
                      }
                      BlocProvider.of<AccountsBloc>(context)
                          .add(AddOrUpdateAccountEvent(isAccountAddOrUpdate));
                    },
                    title: isAccountAddOrUpdate
                        ? context.loc.add
                        : context.loc.update,
                  ),
                ),
              ),
            ),
            tablet: Scaffold(
              appBar: context.materialYouAppBar(
                isAccountAddOrUpdate
                    ? context.loc.addAccount
                    : context.loc.updateAccount,
                actions: [
                  IconButton(
                    onPressed: _showInfo,
                    icon: const Icon(Icons.info_rounded),
                  ),
                  isAccountAddOrUpdate
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: () {
                            paisaAlertDialog(
                              context,
                              title: Text(context.loc.dialogDeleteTitle),
                              child: RichText(
                                text: TextSpan(
                                  text: context.loc.deleteAccount,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text:
                                          BlocProvider.of<AccountsBloc>(context)
                                              .accountName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmationButton: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                onPressed: () {
                                  BlocProvider.of<AccountsBloc>(context).add(
                                      DeleteAccountEvent(
                                          int.parse(widget.accountId!)));

                                  Navigator.pop(context);
                                },
                                child: Text(context.loc.delete),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.delete_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                ],
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: PaisaBigButton(
                    onPressed: () {
                      final isValid = _form.currentState!.validate();
                      if (!isValid) {
                        return;
                      }
                      BlocProvider.of<AccountsBloc>(context)
                          .add(AddOrUpdateAccountEvent(isAccountAddOrUpdate));
                    },
                    title: isAccountAddOrUpdate
                        ? context.loc.add
                        : context.loc.update,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Form(
                        key: _form,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const CardTypeButtons(),
                              const SizedBox(height: 16),
                              AccountCardHolderNameWidget(
                                controller: accountHolderController,
                              ),
                              const SizedBox(height: 16),
                              AccountNameWidget(
                                controller: accountNameController,
                              ),
                              const SizedBox(height: 16),
                              AccountInitialAmountWidget(
                                controller: accountInitialAmountController,
                              ),
                              const SizedBox(height: 16),
                              AccountNumberWidget(
                                controller: accountNumberController,
                              ),
                              const SizedBox(height: 16),
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
        },
      ),
    );
  }

  void _showInfo() => showModalBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        context: context,
        builder: (context) {
          return SafeArea(
            maintainBottomViewPadding: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_rounded),
                  title: Text(
                    context.loc.accountInformationTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(context.loc.accountInformationSubTitle),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () {
                        GoRouter.of(context).pop();
                      },
                      child: Text(context.loc.ok),
                    ),
                  ),
                ),
                const SizedBox(height: 10)
              ],
            ),
          );
        },
      );
}

class AccountCardHolderNameWidget extends StatelessWidget {
  const AccountCardHolderNameWidget({
    super.key,
    required this.controller,
  });
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return PaisaTextFormField(
          controller: controller,
          hintText: context.loc.enterCardHolderName,
          keyboardType: TextInputType.name,
          inputFormatters: [
            FilteringTextInputFormatter.singleLineFormatter,
          ],
          onChanged: (value) =>
              BlocProvider.of<AccountsBloc>(context).accountHolderName = value,
        );
      },
    );
  }
}

class AccountNameWidget extends StatelessWidget {
  const AccountNameWidget({
    super.key,
    required this.controller,
  });
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return PaisaTextFormField(
          controller: controller,
          hintText: context.loc.enterAccountName,
          keyboardType: TextInputType.name,
          inputFormatters: [
            FilteringTextInputFormatter.singleLineFormatter,
          ],
          onChanged: (value) =>
              BlocProvider.of<AccountsBloc>(context).accountName = value,
        );
      },
    );
  }
}

class AccountNumberWidget extends StatelessWidget {
  const AccountNumberWidget({
    super.key,
    required this.controller,
  });
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    return PaisaTextFormField(
      maxLength: 4,
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      hintText: context.loc.enterNumberOptional,
      keyboardType: TextInputType.number,
      onChanged: (value) =>
          BlocProvider.of<AccountsBloc>(context).accountNumber = value,
    );
  }
}

class AccountInitialAmountWidget extends StatelessWidget {
  const AccountInitialAmountWidget({
    super.key,
    required this.controller,
  });
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    return PaisaTextFormField(
      controller: controller,
      hintText: context.loc.enterAmount,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
        TextInputFormatter.withFunction((oldValue, newValue) {
          try {
            final text = newValue.text;
            if (text.isNotEmpty) double.parse(text);
            return newValue;
          } catch (_) {}
          return oldValue;
        }),
      ],
      onChanged: (value) {
        double? amount = double.tryParse(value);
        BlocProvider.of<AccountsBloc>(context).initialAmount = amount;
      },
    );
  }
}

class AccountDefaultSwitchWidget extends StatefulWidget {
  const AccountDefaultSwitchWidget({
    super.key,
    required this.accountId,
  });
  final int accountId;

  @override
  State<AccountDefaultSwitchWidget> createState() =>
      _AccountDefaultSwitchWidgetState();
}

class _AccountDefaultSwitchWidgetState
    extends State<AccountDefaultSwitchWidget> {
  final SettingsController settingsController = getIt.get();
  late bool isAccountDefault =
      settingsController.defaultAccountId == widget.accountId;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Default account'),
      value: isAccountDefault,
      onChanged: (value) {
        if (value) {
          settingsController.setDefaultAccountId(widget.accountId);
        } else {
          settingsController.setDefaultAccountId(-1);
        }
        setState(() {
          isAccountDefault = value;
        });
      },
    );
  }
}
