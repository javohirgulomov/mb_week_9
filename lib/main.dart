
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'setstate/cart_page_setstate.dart';
import 'riverpod/cart_page_riverpod.dart';
import 'cubit/cart_page_cubit.dart';
import 'bloc/cart_page_bloc.dart';

void main() {
  runApp(
  const ProviderScope(
    child: MyApp(),
  ),
);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cart Four Ways',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One Cart, Four Ways'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SetStateCartPage(),
                    ),
                  );
                },
                child: const Text('setState'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RiverpodCartPage(),
                    ),
                  );
                },
                child: const Text('Riverpod'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CubitCartPage(),
                    ),
                  );
                },
                child: const Text('Cubit'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BlocCartPage(),
                    ),
                  );
                },
                child: const Text('Bloc'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
