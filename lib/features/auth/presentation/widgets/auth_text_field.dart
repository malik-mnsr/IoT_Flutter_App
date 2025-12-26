import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool readOnly;
  final void Function()? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? focusedBorder;
  final InputBorder? enabledBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final Color? fillColor;
  final bool filled;

  const AuthTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText = '',
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.readOnly = false,
    this.onTap,
    this.contentPadding,
    this.focusedBorder,
    this.enabledBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.fillColor,
    this.filled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        contentPadding: contentPadding ?? const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: enabledBorder ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: focusedBorder ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: errorBorder ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: focusedErrorBorder ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: filled,
        fillColor: fillColor ?? Colors.grey[50],
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintStyle: TextStyle(color: Colors.grey[500]),
        errorStyle: const TextStyle(color: Colors.red),
        errorMaxLines: 2,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      readOnly: readOnly,
      onTap: onTap,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: enabled ? Colors.black87 : Colors.grey[600],
      ),
      cursorColor: Theme.of(context).primaryColor,
    );
  }
}

// Custom variant with icon button
class AuthTextFieldWithButton extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final IconData buttonIcon;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final bool buttonEnabled;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  const AuthTextFieldWithButton({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText = '',
    required this.prefixIcon,
    required this.buttonIcon,
    required this.buttonText,
    required this.onButtonPressed,
    this.buttonEnabled = true,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AuthTextField(
            controller: controller,
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            textInputAction: textInputAction,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 56, // Match text field height
          child: ElevatedButton.icon(
            onPressed: buttonEnabled ? onButtonPressed : null,
            icon: Icon(buttonIcon, size: 20),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Password strength indicator field
class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onChanged;

  const PasswordTextField({
    Key? key,
    required this.controller,
    this.labelText = 'Mot de passe',
    this.hintText = '',
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
  }) : super(key: key);

  @override
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;
  double _strength = 0;

  void _updateStrength(String password) {
    double strength = 0;

    // Length check
    if (password.length >= 8) strength += 0.25;

    // Upper & lower case
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'))) {
      strength += 0.25;
    }

    // Numbers
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;

    // Special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength += 0.25;
    }

    setState(() => _strength = strength);
    widget.onChanged?.call(password);
  }

  Color _getStrengthColor() {
    if (_strength < 0.25) return Colors.red;
    if (_strength < 0.5) return Colors.orange;
    if (_strength < 0.75) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _getStrengthText() {
    if (_strength < 0.25) return 'Faible';
    if (_strength < 0.5) return 'Moyen';
    if (_strength < 0.75) return 'Bon';
    return 'Fort';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          controller: widget.controller,
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () {
              setState(() => _obscureText = !_obscureText);
            },
          ),
          obscureText: _obscureText,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onChanged: _updateStrength,
        ),
        if (widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _strength,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStrengthColor(),
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _getStrengthText(),
                style: TextStyle(
                  color: _getStrengthColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Utilisez au moins 8 caractères avec majuscules, minuscules, chiffres et symboles',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}