import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../core/enum/transaction_type.dart';

import '../../../app/routes.dart';
import '../../../core/common.dart';
import '../../../domain/account/entities/account.dart';
import '../../../domain/category/entities/category.dart';
import '../../../domain/expense/entities/expense.dart';

class ExpenseItemWidget extends StatelessWidget {
  const ExpenseItemWidget({
    Key? key,
    required this.expense,
    required this.account,
    required this.category,
  }) : super(key: key);

  final Account account;
  final Expense expense;
  final Category category;

  String getSubtitle(BuildContext context) {
    if (expense.type == TransactionType.transfer) {
      return expense.time.shortDayString;
    } else {
      return context.loc.transactionSubTittleText(
          account.bankName, expense.time.shortDayString);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        context.goNamed(
          editTransactionsName,
          params: <String, String>{'eid': expense.superId.toString()},
        );
      },
      child: ListTile(
        title: Text(
          expense.name,
          style: GoogleFonts.manrope(
            textStyle: Theme.of(context).textTheme.bodyMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          getSubtitle(context),
          style: GoogleFonts.manrope(
            textStyle: Theme.of(context).textTheme.bodySmall,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: Color(
                  category.color ?? Theme.of(context).colorScheme.surface.value)
              .withOpacity(0.2),
          child: Icon(
            IconData(
              category.icon,
              fontFamily: 'Material Design Icons',
              fontPackage: 'material_design_icons_flutter',
            ),
            color: Color(
                category.color ?? Theme.of(context).colorScheme.surface.value),
          ),
        ),
        trailing: Text(
          '${expense.type?.sign}${expense.currency.toFormateCurrency()}',
          style: GoogleFonts.manrope(
            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: expense.type?.color(context),
                ),
          ),
        ),
      ),
    );
  }
}

class ExpenseTransferItemWidget extends StatelessWidget {
  const ExpenseTransferItemWidget({
    Key? key,
    required this.expense,
    required this.fromAccount,
    required this.toAccount,
  }) : super(key: key);

  final Account fromAccount, toAccount;
  final Expense expense;

  String getSubtitle() {
    return expense.time.shortDayString;
  }

  String get title {
    return 'Transfer from ${fromAccount.bankName} to ${toAccount.bankName}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.goNamed(
          editTransactionsName,
          params: <String, String>{'eid': expense.superId.toString()},
        ),
        child: ListTile(
          title: Text(title),
          subtitle: Text(getSubtitle()),
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: Icon(
              MdiIcons.bankTransfer,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          trailing: Text(
            '${expense.type?.sign}${expense.currency.toFormateCurrency()}',
            style: GoogleFonts.manrope(
              textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: expense.type?.color(context),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
