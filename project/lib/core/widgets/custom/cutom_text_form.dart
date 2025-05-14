// import 'package:flutter/material.dart';
//
// extension TextFormFieldStyleHelper on CustomTextFormField {
//   static OutlineInputBorder get fillPrimary => OutlineInputBorder(
//     borderSide: BorderSide.none,
//   );
// }
//
// class CustomTextFormField extends StatelessWidget {
//   CustomTextFormField({
//     Key? key,
//     this.alignment,
//     this.width,
//     this.boxDecoration,
//     this.controller,
//     this.focusNode,
//     this.autofocus = false,
//     this.textStyle,
//     this.obscureText = false,
//     this.readOnly = false,
//     this.onTap,
//     this.textInputAction = TextInputAction.next,
//     this.textInputType = TextInputType.text,
//     this.maxLines,
//     this.hintText,
//     this.hintStyle,
//     this.prefix,
//     this.prefixConstraints,
//     this.suffix,
//     this.suffixConstraints,
//     this.contentPadding,
//     this.borderDecoration,
//     this.fillColor,
//     this.filled = false,
//     this.validator,
//   }) : super(key: key);
//
//   final Alignment? alignment;
//   final double? width;
//   final BoxDecoration? boxDecoration;
//   final TextEditingController? controller;
//   final FocusNode? focusNode;
//   final bool? autofocus;
//   final TextStyle? textStyle;
//   final bool? obscureText;
//   final bool? readOnly;
//   final VoidCallback? onTap;
//   final TextInputAction? textInputAction;
//   final TextInputType? textInputType;
//   final int? maxLines;
//   final String? hintText;
//   final TextStyle? hintStyle;
//   final Widget? prefix;
//   final BoxConstraints? prefixConstraints;
//   final Widget? suffix;
//   final BoxConstraints? suffixConstraints;
//   final EdgeInsets? contentPadding;
//   final InputBorder? borderDecoration;
//   final Color? fillColor;
//   final bool? filled;
//   final FormFieldValidator<String>? validator;
//
//   @override
//   Widget build(BuildContext context) {
//     return alignment != null
//         ? Align(
//         alignment: alignment ?? Alignment.center,
//         child: textFormFieldWidget(context))
//         : textFormFieldWidget(context);
//   }
//
//   Widget textFormFieldWidget(BuildContext context) => Container(
//     width: width ?? double.maxFinite,
//     decoration: boxDecoration,
//     child: TextFormField(
//       scrollPadding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom),
//       controller: controller,
//       focusNode: focusNode,
//       onTapOutside: (event) {
//         if (focusNode != null) {
//           focusNode?.unfocus();
//         } else {
//           FocusManager.instance.primaryFocus?.unfocus();
//         }
//       },
//       autofocus: autofocus!,
//       style: textStyle ?? CustomTextStyles.bodyLargeOnPrimaryContainer,
//       obscureText: obscureText!,
//       readOnly: readOnly!,
//       onTap: () {
//         onTap?.call();
//       },
//       textInputAction: textInputAction,
//       keyboardType: textInputType,
//       maxLines: maxLines ?? 1,
//       decoration: decoration,
//       validator: validator,
//     ),
//   );
//
//   InputDecoration get decoration => InputDecoration(
//     hintText: hintText ?? "",
//     hintStyle: hintStyle ?? CustomTextStyles.bodyLargeOnPrimaryContainer,
//     prefixIcon: prefix,
//     prefixIconConstraints: prefixConstraints,
//     suffixIcon: suffix,
//     suffixIconConstraints: suffixConstraints,
//     isDense: true,
//     contentPadding:
//     contentPadding ?? EdgeInsets.fromLTRB(6.h, 6.h, 6.h, 6.h),
//     fillColor: fillColor,
//     filled: filled,
//     border: borderDecoration ?? InputBorder.none,
//     enabledBorder: borderDecoration ?? InputBorder.none,
//   );
