import 'package:flutter/material.dart';
import 'package:tododo/auth/auth_service.dart';
import 'package:tododo/models/event_model.dart';
import 'package:tododo/services/event_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventPage extends StatefulWidget {
  final AuthService authService;

  const EventPage({super.key, required this.authService});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late final EventDatabase eventDatabase;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  DateTime? eventDate;
  String? userId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    userId = widget.authService.supabase.auth.currentUser?.id;
    eventDatabase = EventDatabase(supabase: widget.authService.supabase);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> updateEvent(EventModel event) async {
    setState(() {
      isLoading = true;
    });

    final updatedEvent = EventModel(
      id: event.id,
      userId: event.userId,
      title: titleController.text,
      description: descriptionController.text,
      eventDate: eventDate!,
      location: locationController.text,
      createdAt: event.createdAt,
      updatedAt: DateTime.now(),
    );

    await eventDatabase.updateEvent(updatedEvent);

    if (mounted) {
      setState(() {
        isLoading = false;
        titleController.clear();
        descriptionController.clear();
        locationController.clear();
        eventDate = null;
      });
      Navigator.pop(context);
    }
  }

  Future<void> deleteEvent(EventModel event) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        isLoading = true;
      });
      // Pass the event ID instead of the whole event object
      await eventDatabase.deleteEvent(event.id);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> openLocationInMaps(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final url =
        'https://www.google.com/maps/search/?api=1&query=$encodedLocation';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  Future<void> scheduleEventNotification(EventModel event) async {
    //nanti
  }

  Future<void> selectEventDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: eventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          eventDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> addNewEvent() async {
    try {
      if (titleController.text.isEmpty ||
          descriptionController.text.isEmpty ||
          locationController.text.isEmpty ||
          eventDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        isLoading = true;
      });

      final newEvent = EventModel(
        userId: userId!,
        title: titleController.text,
        description: descriptionController.text,
        eventDate: eventDate!,
        location: locationController.text,
      );

      await eventDatabase.createEvent(newEvent);

      // Schedule notification for the event
      await scheduleEventNotification(newEvent);

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      titleController.clear();
      descriptionController.clear();
      locationController.clear();
      eventDate = null;

      Navigator.pop(context);
    } catch (e, stackTrace) {
      print('Error adding event: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event: ${e.toString()}')),
      );
    }
  }

  void showEventDialog([EventModel? event]) {
    if (event != null) {
      titleController.text = event.title;
      descriptionController.text = event.description;
      locationController.text = event.location;
      eventDate = event.eventDate;
    } else {
      titleController.clear();
      descriptionController.clear();
      locationController.clear();
      eventDate = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => !isLoading,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(event == null ? "New Event" : "Edit Event"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        errorText: null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        errorText: null,
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: "Location",
                        errorText: null,
                        hintText: "Enter location address",
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text("Event Date & Time"),
                      subtitle: Text(
                        eventDate == null
                            ? "Select date and time"
                            : DateFormat('yyyy-MM-dd HH:mm').format(eventDate!),
                      ),
                      onTap: isLoading ? null : () => selectEventDate(context),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (event == null) {
                            await addNewEvent();
                          } else {
                            await updateEvent(event);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(event == null ? "Save" : "Update"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Events")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEventDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: eventDatabase.getEventsByUser(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('No events yet'));
          }

          return ListView.separated(
            itemCount: events.length,
            padding: const EdgeInsets.all(16),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final event = events[index];
              return Dismissible(
                key: Key(event.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await deleteEvent(event);
                  }
                },
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    showEventDialog(event);
                    return false;
                  }
                  return true;
                },
                child: Card(
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(event.description),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm')
                                  .format(event.eventDate),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => openLocationInMaps(event.location),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      event.location,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
