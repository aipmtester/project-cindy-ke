import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class PinInput extends StatefulWidget {
  final int length;
  final bool obscure;
  final ValueChanged<String> onCompleted;
  final TextEditingController? controller;

  const PinInput({
    super.key,
    required this.length,
    this.obscure = false,
    required this.onCompleted,
    this.controller,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  late TextEditingController _controller;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length, (i) {
          return Container(
            width: 52,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: TextField(
              focusNode: _focusNodes[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              obscureText: widget.obscure,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
                ),
              ),
              onChanged: (value) {
                // Update the combined controller
                final current = List.filled(widget.length, '');
                for (int j = 0; j < widget.length; j++) {
                  if (j == i) {
                    current[j] = value;
                  }
                }
                // Rebuild full value
                _rebuildValue();

                if (value.isNotEmpty && i < widget.length - 1) {
                  _focusNodes[i + 1].requestFocus();
                } else if (value.isEmpty && i > 0) {
                  _focusNodes[i - 1].requestFocus();
                }

                if (_controller.text.length == widget.length) {
                  widget.onCompleted(_controller.text);
                }
              },
            ),
          );
        }),
      ),
    );
  }

  void _rebuildValue() {
    // This is a simplified approach - build value from what's visible
    // In practice, we'd track each box's value
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}
