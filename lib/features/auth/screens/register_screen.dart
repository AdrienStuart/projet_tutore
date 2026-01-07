
import 'package:flutter/material.dart';
import 'package:projet_tutore/coeur/utils/validators.dart';
import 'package:projet_tutore/shared/widgets/custom_app_bar.dart';
import 'package:projet_tutore/shared/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      // Pass data to next screen via arguments or constructor
      Navigator.of(context).pushNamed(
        '/role_selection',
        arguments: {
          'nom': _nomController.text,
          'email': _emailController.text,
          'telephone': _telephoneController.text,
          'adresse': _adresseController.text,
          'password': _passwordController.text,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Inscription (1/2)'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informations Personnelles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nomController,
                label: 'Nom complet',
                prefixIcon: Icons.person,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _telephoneController,
                label: 'Téléphone',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (val) => Validators.required(val, field: 'Le téléphone'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _adresseController,
                label: 'Adresse',
                prefixIcon: Icons.location_on,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                prefixIcon: Icons.lock,
                obscureText: true,
                validator: Validators.password,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Suivant',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Déjà un compte ?'),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
