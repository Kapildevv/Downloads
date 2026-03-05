import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/net_worth_item.dart';
import '../../repositories/net_worth_repository.dart';
import '../../theme/app_colors.dart';

class NetWorthEntrySheet extends ConsumerStatefulWidget {
  final NetWorthItem? existingItem;
  final bool initialIsAsset;

  const NetWorthEntrySheet({
    super.key,
    this.existingItem,
    this.initialIsAsset = true,
  });

  @override
  ConsumerState<NetWorthEntrySheet> createState() => _NetWorthEntrySheetState();
}

class _NetWorthEntrySheetState extends ConsumerState<NetWorthEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late bool _isAsset;
  late TextEditingController _nameController;
  late TextEditingController _valueController;
  late String _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isAsset = widget.existingItem?.isAsset ?? widget.initialIsAsset;
    _nameController = TextEditingController(text: widget.existingItem?.name);
    _valueController = TextEditingController(
      text: widget.existingItem != null
          ? widget.existingItem!.value.toString()
          : '',
    );

    if (widget.existingItem != null) {
      _selectedCategory = widget.existingItem!.category;
    } else {
      _selectedCategory = _isAsset
          ? AssetCategory.cash.name
          : LiabilityCategory.personalLoan.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final item = NetWorthItem(
        id: widget.existingItem?.id,
        name: _nameController.text.trim(),
        value: double.parse(_valueController.text.trim()),
        isAsset: _isAsset,
        category: _selectedCategory,
        metadata: widget.existingItem?.metadata ?? {},
      );

      await ref.read(netWorthProvider.notifier).saveItem(item);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _isAsset
        ? AssetCategory.values.map((c) => c.name).toList()
        : LiabilityCategory.values.map((c) => c.name).toList();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkTextSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existingItem != null ? 'Edit Entry' : 'Add Entry',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (widget.existingItem == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Asset'),
                    selected: _isAsset,
                    selectedColor: Colors.tealAccent,
                    onSelected: (val) {
                      setState(() {
                        _isAsset = true;
                        if (!categories.contains(_selectedCategory)) {
                          _selectedCategory = AssetCategory.cash.name;
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Liability'),
                    selected: !_isAsset,
                    selectedColor: AppColors.error,
                    onSelected: (val) {
                      setState(() {
                        _isAsset = false;
                        if (!categories.contains(_selectedCategory)) {
                          _selectedCategory =
                              LiabilityCategory.personalLoan.name;
                        }
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: AppColors.darkTextSecondary,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: AppColors.darkTextSecondary),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.darkTextSecondary)),
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name (e.g. HDFC Savings)',
                labelStyle: TextStyle(color: AppColors.darkTextSecondary),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.darkTextSecondary)),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _valueController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: TextStyle(color: AppColors.darkTextSecondary),
                prefixIcon:
                    Icon(Icons.currency_rupee, color: Colors.tealAccent),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.darkTextSecondary)),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Enter amount';
                }
                if (double.tryParse(val.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isAsset ? Colors.tealAccent : AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : const Text('Save Entry',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
