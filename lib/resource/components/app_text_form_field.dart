import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final bool? isPassword;
  final String? hintText;
  final TextInputType? keyboardType;
  Widget? prefixIcon;
  Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final void Function()? onTap;
  final Iterable<String>? autofillHints;
  final Color? fillColor;
  final bool obscureText;
  final String obscuringCharacter;

  AppTextFormField({
    Key? key,
    this.controller,
    this.isPassword,
    this.hintText,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.autofillHints,
    this.fillColor,
    this.obscureText = false,
    this.obscuringCharacter = '•',
  }) : super(key: key);

  @override
  _AppTextFormFieldState createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  late TextEditingController _controller;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _obscureText = widget.isPassword!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPassword == true) {
      widget.suffixIcon = InkWell(
        onTap: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        child: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).primaryColor.withOpacity(0.7),
        ),
      );
    }

    return TextFormField(
      obscureText: _obscureText,
      obscuringCharacter: widget.obscuringCharacter,
      autofillHints: widget.autofillHints,
      cursorOpacityAnimates: true,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      keyboardType: widget.keyboardType,
      textInputAction: TextInputAction.next,
      validator: widget.validator,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        suffixIcon: widget.suffixIcon,
        isDense: true,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(20.0.r),
        ),
        fillColor: widget.fillColor ?? Theme.of(context).colorScheme.surface,
        filled: true,
        prefixIcon: widget.prefixIcon,
        hintText: widget.hintText,
        hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
      ),
      controller: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
