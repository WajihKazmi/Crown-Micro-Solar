import 'package:flutter/material.dart';
import 'app_animations.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    Key? key,
    this.hintText,
    this.labelText,
    this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.decoration,
    this.focusNode,
    this.enabled = true,
  }) : super(key: key);

  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final GestureTapCallback? onTap;
  final InputDecoration? decoration;
  final FocusNode? focusNode;
  final bool enabled;

  @override
  _AppTextFieldState createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  bool _hasError = false;
  String? _errorMessage;
  late FocusNode _focusNode;

  // Expose the error state
  bool get hasError => _hasError;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    // Only dispose the focus node if we created it
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && _hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShakeAnimation(
      shouldShake: _hasError,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: _obscureText,
        enabled: widget.enabled,
        validator: (value) {
          if (value == null || value.isEmpty) {
            final error = widget.validator?.call(value);
            setState(() {
              _hasError = error != null;
              _errorMessage = error;
            });
            return error;
          }
          return null;
        },
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        textAlign: widget.textAlign,
        onChanged: (value) {
          if (_hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
              }
            });
          }
          widget.onChanged?.call(value);
        },
        onFieldSubmitted: widget.onFieldSubmitted,
        onTap: widget.onTap,
        decoration: widget.decoration ?? InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          errorText: _errorMessage,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: widget.enabled ? Colors.grey[200] : Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: widget.enabled ? _togglePasswordVisibility : null,
                )
              : null,
        ),
      ),
    );
  }
}
