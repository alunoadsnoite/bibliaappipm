import 'package:flutter/material.dart';

import 'reminders.dart';
import 'store.dart';

class ReminderSettings extends StatefulWidget {
  const ReminderSettings({super.key});
  @override
  State<ReminderSettings> createState() => _ReminderSettingsState();
}

class _ReminderSettingsState extends State<ReminderSettings> {
  bool _busy = false;
  Future<void> _configure(bool enabled, TimeOfDay time) async {
    setState(() => _busy = true);
    try {
      await ReminderService.i.configure(
        AppState.i,
        enabled: enabled,
        hour: time.hour,
        minute: time.minute,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível atualizar o lembrete. Verifique as permissões de notificações.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ReminderService.i;
    final state = AppState.i;
    return ListenableBuilder(
      listenable: Listenable.merge([state, service.error]),
      builder: (context, _) {
        final enabled = service.enabled(state);
        final time = TimeOfDay(
          hour: service.hour(state),
          minute: service.minute(state),
        );
        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lembrete de leitura',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text('Lembrar diariamente'),
                value: enabled,
                subtitle: const Text(
                  'Notificação local opcional. O horário pode variar conforme a economia de bateria do aparelho.',
                ),
                onChanged: _busy ? null : (v) => _configure(v, time),
              ),
              ListTile(
                title: const Text('Horário'),
                subtitle: Text(time.format(context)),
                trailing: const Icon(Icons.schedule),
                onTap: _busy
                    ? null
                    : () async {
                        final selected = await showTimePicker(
                          context: context,
                          initialTime: time,
                        );
                        if (selected != null && mounted) {
                          await _configure(enabled, selected);
                        }
                      },
              ),
              if (_busy) const LinearProgressIndicator(),
              if (service.error.value != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(service.error.value!),
                ),
            ],
          ),
        );
      },
    );
  }
}
