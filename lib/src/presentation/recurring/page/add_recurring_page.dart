import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../../../main.dart';
import '../../../app/routes.dart';
import '../../../core/common.dart';
import '../../../core/enum/recurring_type.dart';
import '../../../core/enum/transaction_type.dart';
import '../../../data/accounts/model/account_model.dart';
import '../../../data/category/model/category_model.dart';
import '../../../domain/account/entities/account.dart';
import '../../../domain/category/entities/category.dart';
import '../../expense/widgets/selectable_item_widget.dart';
import '../../widgets/paisa_annotate_region_widget.dart';
import '../../widgets/paisa_big_button_widget.dart';
import '../../widgets/paisa_pill_chip.dart';
import '../../widgets/paisa_text_field.dart';
import '../cubit/recurring_cubit.dart';

class AddRecurringPage extends StatefulWidget {
  const AddRecurringPage({super.key});

  @override
  State<AddRecurringPage> createState() => _AddRecurringPageState();
}

class _AddRecurringPageState extends State<AddRecurringPage> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final nameController = TextEditingController();
  late final RecurringCubit recurringCubit = getIt.get<RecurringCubit>();

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaisaAnnotatedRegionWidget(
      color: Theme.of(context).colorScheme.background,
      child: BlocProvider(
        create: (context) => recurringCubit,
        child: BlocConsumer(
          bloc: recurringCubit,
          listener: (context, state) {
            if (state is RecurringErrorState) {
              context.showMaterialSnackBar(
                state.error,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              );
            } else if (state is RecurringEventAddedState) {
              context.pop();
            }
          },
          builder: (context, state) {
            return ScreenTypeLayout(
              mobile: Scaffold(
                appBar: context.materialYouAppBar(
                  context.loc.recurring,
                ),
                body: ListView(
                  shrinkWrap: true,
                  children: [
                    TransactionToggleButtons(recurringCubit: recurringCubit),
                    const SizedBox(height: 16),
                    RecurringNameWidget(controller: nameController),
                    const SizedBox(height: 16),
                    RecurringAmountWidget(controller: amountController),
                    const SizedBox(height: 16),
                    const RecurringDatePickerWidget(),
                    RecurringWidget(
                      recurringCubit: recurringCubit,
                    ),
                    const SelectedAccount(),
                    const SelectCategory(),
                  ],
                ),
                bottomNavigationBar: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PaisaBigButton(
                      onPressed: () {
                        recurringCubit.addRecurringEvent();
                      },
                      title: context.loc.add,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TransactionToggleButtons extends StatelessWidget {
  const TransactionToggleButtons({
    Key? key,
    required this.recurringCubit,
  }) : super(key: key);

  final RecurringCubit recurringCubit;

  void _update(TransactionType type) {
    recurringCubit.changeTransactionType(type);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: recurringCubit,
      buildWhen: (previous, current) => current is TransactionTypeState,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                PaisaPillChip(
                  title: TransactionType.expense.stringName(context),
                  isSelected:
                      recurringCubit.transactionType == TransactionType.expense,
                  onPressed: () => _update(TransactionType.expense),
                ),
                PaisaPillChip(
                  title: TransactionType.income.stringName(context),
                  isSelected:
                      recurringCubit.transactionType == TransactionType.income,
                  onPressed: () => _update(TransactionType.income),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SelectedAccount extends StatelessWidget {
  const SelectedAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<AccountModel>>(
      valueListenable: getIt.get<Box<AccountModel>>().listenable(),
      builder: (context, value, child) {
        final accounts = value.values.toEntities();
        if (accounts.isEmpty) {
          return ListTile(
            onTap: () => context.pushNamed(addAccountPath),
            title: Text(context.loc.addAccountEmptyTitle),
            subtitle: Text(context.loc.addAccountEmptySubTitle),
            trailing: const Icon(Icons.keyboard_arrow_right),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                context.loc.selectAccount,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            AccountSelectedWidget(
              accounts: accounts,
              onSelected: (selectedId) {
                BlocProvider.of<RecurringCubit>(context).selectedAccountId =
                    selectedId;
              },
            )
          ],
        );
      },
    );
  }
}

class AccountSelectedWidget extends StatefulWidget {
  const AccountSelectedWidget({
    Key? key,
    required this.accounts,
    required this.onSelected,
  }) : super(key: key);

  final List<Account> accounts;
  final Function(int selectedId) onSelected;

  @override
  State<AccountSelectedWidget> createState() => _AccountSelectedWidgetState();
}

class _AccountSelectedWidgetState extends State<AccountSelectedWidget> {
  int selectedId = -1;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
        ),
        scrollDirection: Axis.horizontal,
        shrinkWrap: false,
        itemCount: widget.accounts.length + 1,
        itemBuilder: (_, index) {
          if (index == 0) {
            return ItemWidget(
              isSelected: false,
              title: 'Add New',
              icon: MdiIcons.plus.codePoint,
              onPressed: () => context.pushNamed(addAccountPath),
            );
          } else {
            final Account account = widget.accounts[index - 1];
            return ItemWidget(
              isSelected: account.superId == selectedId,
              title: account.name,
              icon: account.cardType!.icon.codePoint,
              onPressed: () {
                setState(() {
                  selectedId = account.superId!;
                  widget.onSelected(selectedId);
                });
              },
              subtitle: account.bankName,
            );
          }
        },
      ),
    );
  }
}

class SelectCategory extends StatelessWidget {
  const SelectCategory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<CategoryModel>>(
      valueListenable: getIt.get<Box<CategoryModel>>().listenable(),
      builder: (context, value, child) {
        final List<Category> categories = value.values.toEntities();
        if (categories.isEmpty) {
          return ListTile(
            onTap: () => context.pushNamed(addCategoryPath),
            title: Text(context.loc.addCategoryEmptyTitle),
            subtitle: Text(context.loc.addCategoryEmptySubTitle),
            trailing: const Icon(Icons.keyboard_arrow_right),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                context.loc.selectCategory,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            CategorySelectWidget(
              categories: categories,
              onSelected: (int selectedId) {
                BlocProvider.of<RecurringCubit>(context).selectedCategoryId =
                    selectedId;
              },
            )
          ],
        );
      },
    );
  }
}

class CategorySelectWidget extends StatefulWidget {
  const CategorySelectWidget({
    super.key,
    required this.categories,
    required this.onSelected,
  });

  final List<Category> categories;
  final Function(int selectedId) onSelected;

  @override
  State<CategorySelectWidget> createState() => _CategorySelectWidgetState();
}

class _CategorySelectWidgetState extends State<CategorySelectWidget> {
  int selectedId = -1;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 4.0,
        runSpacing: 8.0,
        children: List.generate(
          widget.categories.length + 1,
          (index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  onSelected: (value) => context.pushNamed(addCategoryPath),
                  avatar: Icon(
                    color: Theme.of(context).colorScheme.primary,
                    IconData(
                      MdiIcons.plus.codePoint,
                      fontFamily: 'Material Design Icons',
                      fontPackage: 'material_design_icons_flutter',
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                      width: 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(
                    context.loc.addNew,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  padding: const EdgeInsets.all(12),
                ),
              );
            } else {
              final Category category = widget.categories[index - 1];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: category.superId == selectedId,
                  onSelected: (value) {
                    setState(() {
                      selectedId = category.superId!;
                      widget.onSelected(selectedId);
                    });
                  },
                  avatar: Icon(
                    color: category.superId == selectedId
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    IconData(
                      category.icon,
                      fontFamily: 'Material Design Icons',
                      fontPackage: 'material_design_icons_flutter',
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                      width: 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(category.name),
                  labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: category.superId == selectedId
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant),
                  padding: const EdgeInsets.all(12),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class RecurringNameWidget extends StatelessWidget {
  const RecurringNameWidget({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: PaisaTextFormField(
        maxLines: 1,
        controller: controller,
        hintText: context.loc.recurring,
        keyboardType: TextInputType.name,
        inputFormatters: [
          FilteringTextInputFormatter.singleLineFormatter,
        ],
        validator: (value) {
          if (value!.isNotEmpty) {
            return null;
          } else {
            return context.loc.validName;
          }
        },
        onChanged: (value) =>
            BlocProvider.of<RecurringCubit>(context).recurringName = value,
      ),
    );
  }
}

class RecurringAmountWidget extends StatelessWidget {
  const RecurringAmountWidget({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: PaisaTextFormField(
        controller: controller,
        hintText: context.loc.amount,
        keyboardType: TextInputType.number,
        maxLength: 13,
        maxLines: 1,
        counterText: '',
        inputFormatters: <TextInputFormatter>[
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
          BlocProvider.of<RecurringCubit>(context).amount = amount;
        },
        validator: (value) {
          if (value!.isNotEmpty) {
            return null;
          } else {
            return context.loc.validAmount;
          }
        },
      ),
    );
  }
}

class RecurringDatePickerWidget extends StatefulWidget {
  const RecurringDatePickerWidget({
    super.key,
  });

  @override
  State<RecurringDatePickerWidget> createState() =>
      _RecurringDatePickerWidgetState();
}

class _RecurringDatePickerWidgetState extends State<RecurringDatePickerWidget> {
  late final RecurringCubit recurringCubit =
      BlocProvider.of<RecurringCubit>(context);

  late DateTime selectedDateTime = recurringCubit.selectedDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            horizontalTitleGap: 0,
            onTap: () async {
              final DateTime? dateTime = await showDatePicker(
                context: context,
                initialDate: selectedDateTime,
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (dateTime != null) {
                setState(() {
                  selectedDateTime = selectedDateTime.copyWith(
                    day: dateTime.day,
                    month: dateTime.month,
                    year: dateTime.year,
                  );
                  recurringCubit.selectedDate = selectedDateTime;
                });
              }
            },
            leading: Icon(
              Icons.today_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(selectedDateTime.formattedDate),
          ),
        ),
        Expanded(
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            horizontalTitleGap: 0,
            onTap: () async {
              final TimeOfDay? timeOfDay = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                initialEntryMode: TimePickerEntryMode.dialOnly,
              );
              if (timeOfDay != null) {
                setState(() {
                  selectedDateTime = selectedDateTime.copyWith(
                    hour: timeOfDay.hour,
                    minute: timeOfDay.minute,
                  );
                  recurringCubit.selectedDate = selectedDateTime;
                });
              }
            },
            leading: Icon(
              MdiIcons.clockOutline,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(selectedDateTime.formattedTime),
          ),
        ),
      ],
    );
  }
}

class RecurringWidget extends StatelessWidget {
  const RecurringWidget({
    super.key,
    required this.recurringCubit,
  });

  final RecurringCubit recurringCubit;

  void _update(RecurringType type) {
    recurringCubit.changeRecurringEvent(type);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: recurringCubit,
      buildWhen: (oldState, newState) => newState is RecurringTypeState,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Periodic',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    PaisaPillChip(
                      title: RecurringType.daily.name(context),
                      isSelected:
                          recurringCubit.recurringType == RecurringType.daily,
                      onPressed: () => _update(RecurringType.daily),
                    ),
                    PaisaPillChip(
                      title: RecurringType.weekly.name(context),
                      isSelected:
                          recurringCubit.recurringType == RecurringType.weekly,
                      onPressed: () => _update(RecurringType.weekly),
                    ),
                    PaisaPillChip(
                      title: RecurringType.monthly.name(context),
                      isSelected:
                          recurringCubit.recurringType == RecurringType.monthly,
                      onPressed: () => _update(RecurringType.monthly),
                    ),
                    PaisaPillChip(
                      title: RecurringType.yearly.name(context),
                      isSelected:
                          recurringCubit.recurringType == RecurringType.yearly,
                      onPressed: () => _update(RecurringType.yearly),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
