import 'package:flutter/material.dart';

import '../../../../core/security/usb_device_info.dart';
import '../../domain/usecases/get_connected_usb_devices.dart';

class UsbDevicePickerDialog extends StatefulWidget {
  final GetConnectedUsbDevices getConnectedUsbDevices;

  const UsbDevicePickerDialog({
    super.key,
    required this.getConnectedUsbDevices,
  });

  static Future<UsbDeviceInfo?> show(
    BuildContext context,
    GetConnectedUsbDevices getConnectedUsbDevices,
  ) =>
      showDialog<UsbDeviceInfo>(
        context: context,
        barrierDismissible: false,
        builder: (_) => UsbDevicePickerDialog(
          getConnectedUsbDevices: getConnectedUsbDevices,
        ),
      );

  @override
  State<UsbDevicePickerDialog> createState() => _UsbDevicePickerDialogState();
}

class _UsbDevicePickerDialogState extends State<UsbDevicePickerDialog> {
  late Future<List<UsbDeviceInfo>> _devices;
  UsbDeviceInfo? _selected;

  @override
  void initState() {
    super.initState();
    _devices = widget.getConnectedUsbDevices();
  }

  void _refresh() {
    setState(() {
      _selected = null;
      _devices = widget.getConnectedUsbDevices();
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return 'غير متاحة';
    const gib = 1024 * 1024 * 1024;
    return '${(bytes / gib).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('اختر وحدة USB'),
        content: SizedBox(
          width: 520,
          child: FutureBuilder<List<UsbDeviceInfo>>(
            future: _devices,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      'تعذّر فحص وحدات USB. أعد توصيل الفلاشة ثم حاول مجدداً.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final devices = snapshot.data ?? const [];
              if (devices.isEmpty) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      'لا توجد وحدة تخزين USB قابلة للإزالة متصلة بالجهاز.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final selected = _selected == device;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        enabled: device.isSupported,
                        selected: selected,
                        onTap: device.isSupported
                            ? () => setState(() => _selected = device)
                            : null,
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                        ),
                        title: Text(device.volumeLabel ?? 'وحدة USB'),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${device.driveLetter}  •  المساحة المتاحة: '
                            '${_formatBytes(device.freeBytes)}\n'
                            '${device.isSupported ? 'صالحة لإنشاء المفتاح' : 'غير مدعومة: لا يوجد رقم تسلسلي موثوق'}',
                          ),
                        ),
                        trailing: Icon(
                          device.isSupported
                              ? Icons.usb_rounded
                              : Icons.usb_off_rounded,
                          color:
                              device.isSupported ? Colors.green : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة الفحص'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: _selected == null
                ? null
                : () => Navigator.pop(context, _selected),
            child: const Text('اختيار'),
          ),
        ],
      ),
    );
  }
}
