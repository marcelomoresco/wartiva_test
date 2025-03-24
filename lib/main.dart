import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

const contentPadding = EdgeInsets.symmetric(vertical: 15, horizontal: 20);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _textFormController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final List<String> _suggestions = ['apple', 'tomato', 'watermelon'];
  final List<String> _newSuggestions = ['banana', 'orange', 'grape'];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _textFormController.addListener(_scheduleOverlayUpdate);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textFormController.removeListener(_scheduleOverlayUpdate);
    _focusNode.removeListener(_onFocusChanged);
    _textFormController.dispose();
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _scheduleOverlayUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateOverlay();
      }
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_focusNode.hasFocus) {
          _overlayEntry?.remove();
          _overlayEntry = null;
        }
      });
    }
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    if (_textFormController.text.isEmpty) return;

    final renderBox = _focusNode.context?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final textParts = _textFormController.text.split('.');
    final lastPart = textParts.last;

    final caretOffset = _getCaretPosition();
    final filteredSuggestions = _textFormController.text.endsWith('.')
        ? _newSuggestions
        : _suggestions.where((s) => s.contains(lastPart)).toList();

    if (filteredSuggestions.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      return;
    }

    final overlay = Overlay.of(context);
    const overlayWidth = 200.0;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: overlayWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(caretOffset.dx, caretOffset.dy + 12),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: filteredSuggestions
                    .map((suggestion) => ListTile(
                          title: Text(suggestion),
                          onTap: () {
                            _onSuggestionSelected(suggestion);
                          },
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _onSuggestionSelected(String suggestion) {
    final text = _textFormController.text;

    if (text.endsWith('.')) {
      _textFormController.text = '$text$suggestion';
    } else {
      final textParts = text.split('.');
      textParts.removeLast();
      _textFormController.text = '${textParts.join('.')}$suggestion';
    }

    _textFormController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textFormController.text.length),
    );

    _scheduleOverlayUpdate();
  }

  // getting the caret (cursor) position
  Offset _getCaretPosition() {
    final renderObject = _focusNode.context?.findRenderObject() as RenderBox?;
    if (renderObject == null) return Offset.zero;

    final renderEditable = _findRenderEditable(renderObject);
    if (renderEditable == null) return Offset.zero;

    final caretOffset = renderEditable
        .getLocalRectForCaret(
          _textFormController.selection.extent,
        )
        .bottomLeft;

    final adjustedOffset = Offset(
      caretOffset.dx + contentPadding.left,
      caretOffset.dy + 4,
    );
    return adjustedOffset;
  }

  RenderEditable? _findRenderEditable(RenderObject? root) {
    RenderEditable? result;
    root?.visitChildren((child) {
      if (child is RenderEditable) {
        result = child;
      } else {
        result ??= _findRenderEditable(child);
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          width: 500,
          child: CompositedTransformTarget(
            link: _layerLink,
            child: TextFormField(
              controller: _textFormController,
              focusNode: _focusNode,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              style: GoogleFonts.spaceMono(
                fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: contentPadding,
              ),
              onChanged: (value) {
                _scheduleOverlayUpdate();
              },
            ),
          ),
        ),
      ),
    );
  }
}
