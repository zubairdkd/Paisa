import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/common.dart';
import '../../widgets/paisa_icon_picker.dart';
import '../bloc/category_bloc.dart';

class CategoryIconPickerWidget extends StatelessWidget {
  const CategoryIconPickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      buildWhen: (previous, current) =>
          current is CategoryIconSelectedState ||
          current is CategorySuccessState,
      bloc: BlocProvider.of<CategoryBloc>(context),
      builder: (context, state) {
        int codePoint = MdiIcons.home.codePoint;
        if (state is CategoryIconSelectedState) {
          codePoint = state.categoryIcon;
        }
        if (state is CategorySuccessState) {
          codePoint = state.category.icon;
        }
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(context.loc.selectIconTitle),
          subtitle: Text(context.loc.selectIconSubTitle),
          leading: Icon(
            IconData(
              codePoint,
              fontFamily: 'Material Design Icons',
              fontPackage: 'material_design_icons_flutter',
            ),
            color: Theme.of(context).colorScheme.primary,
          ),
          onTap: () {
            showIconPicker(
              context: context,
              defaultIcon: IconData(
                codePoint,
                fontFamily: 'Material Design Icons',
                fontPackage: 'material_design_icons_flutter',
              ),
            ).then((resultIcon) => BlocProvider.of<CategoryBloc>(context)
                .add(CategoryIconSelectedEvent(resultIcon.codePoint)));
          },
        );
      },
    );
  }
}
