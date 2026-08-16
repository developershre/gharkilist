import 'package:flutter/material.dart';

class CreateListDialog extends StatefulWidget {
  final bool isHindi;
  final Function(String name) onCreate;

  const CreateListDialog({
    super.key,
    this.isHindi = false,
    required this.onCreate,
  });

  @override
  State<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<CreateListDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.isHindi ? 'नई सूची बनाएं' : 'Create Custom Inventory List',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isHindi ? 'सूची का नाम लिखें (जैसे त्यौहार, पूजा, दवायां):' : 'Enter List Name (e.g. Navratri, Party, Medicine):',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.isHindi ? 'सूची का नाम...' : 'List name...',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isHindi ? 'रद्द करें' : 'Cancel', style: const TextStyle(fontSize: 15)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context);
              widget.onCreate(name);
            }
          },
          child: Text(
            widget.isHindi ? 'बनाएं' : 'Create List',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
