import 'package:flutter/material.dart';

void main() {
  runApp(const WorkLedgerApp());
}

class WorkLedgerApp extends StatelessWidget {
  const WorkLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkLedger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      home: const WorkLedgerHomeScreen(),
    );
  }
}

class WorkLedgerHomeScreen extends StatelessWidget {
  const WorkLedgerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('내근무장부'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('내근무장부', style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('WorkLedger', style: textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
