import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map_app/core/theming/colors.dart';
import 'package:map_app/core/theming/styles.dart';

class CustomizedDropdown extends StatelessWidget {
  final String? value; // selected value as String
  final void Function(String?) onChanged;

  final String hint;

  final List<String> items; // list of string items

  const CustomizedDropdown({
    super.key,
    required this.value,
    required this.onChanged,

    required this.hint,

    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: ColorsManager.lighterGray, // same color as OutlineInputBorder
          width: 1.3, // same width
        ),  
        color: ColorsManager.moreLightGray,
        borderRadius: BorderRadius.circular(16.0), // same radius
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 2.h),
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyles.font14LightGrayRegular),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text("$item"));
          }).toList(),
          onChanged: onChanged,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down),
          // selectedItemBuilder: (context) => items
          //     .map(
          //       (item) => Align(
          //         alignment: Alignment.centerLeft,
          //         child: Text(
          //           "$item",
          //           style: TextStyles.font14LightGrayRegular,
          //         ),
          //       ),
          //     )
          //     .toList(),
          borderRadius: BorderRadius.circular(20),
          elevation: 2,
          menuMaxHeight: 150,
        ),
      ),
    );
  }
}
