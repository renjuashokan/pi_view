import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_viewmodel.dart';
import '../widgets/base_page.dart';
import '../widgets/common_widgets.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(text: 'test@example.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'password');
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedServerIp();
    });
  }

  Future<void> _loadSavedServerIp() async {
    final viewModel = Provider.of<LoginViewModel>(context, listen: false);
    final savedIp = await viewModel.getLastServerIp();
    if (savedIp != null && mounted) {
      setState(() {
        _serverController.text = savedIp;
      });
    } else if (mounted) {
      setState(() {
        _serverController.text = '10.0.2.2';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PiView'),
          backgroundColor: PiViewStyles.piViewRed,
        ),
        body: Consumer<LoginViewModel>(
          builder: (context, model, child) => Stack(
            children: [
              // Background decorative elements
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PiViewStyles.piViewRed.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PiViewStyles.piViewRed.withOpacity(0.1),
                  ),
                ),
              ),
              // Main content
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // App logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: PiViewStyles.piViewRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: PiViewStyles.piViewRed.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.storage_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Connect to Server',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      // Input fields using common widgets
                      PiViewTextField(
                        controller: _serverController,
                        label: 'Server',
                        icon: Icons.dns_rounded,
                      ),
                      const SizedBox(height: 16),
                      PiViewTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      PiViewTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onTogglePassword: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      // Login button
                      PiViewButton(
                        onPressed: model.isLoading
                            ? null
                            : () async {
                                bool success = await model.login(
                                  _serverController.text,
                                  _emailController.text,
                                  _passwordController.text,
                                );
                                if (success && mounted) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/file_browser',
                                    arguments: {
                                      'serverIp': _serverController.text
                                    },
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(model.error ?? 'Login failed'),
                                      backgroundColor: Colors.red[400],
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        isLoading: model.isLoading,
                        text: 'Login',
                      ),
                      const SizedBox(height: 40),
                      // Feature icons
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          PiViewFeatureIcon(
                            icon: Icons.image_outlined,
                            label: 'Photos',
                          ),
                          PiViewFeatureIcon(
                            icon: Icons.movie_outlined,
                            label: 'Videos',
                          ),
                          PiViewFeatureIcon(
                            icon: Icons.folder_outlined,
                            label: 'Files',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
