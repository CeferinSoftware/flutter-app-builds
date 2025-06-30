import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(WebViewApp());
}

class WebViewApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCG AI PRO',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(int.parse('{{PRIMARY_COLOR}}'.replaceFirst('#', '0xFF'))),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: WebViewScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _currentUrl = '{{APP_URL}}';
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkConnectivity();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode({{ENABLE_JAVASCRIPT}} ? JavaScriptMode.unrestricted : JavaScriptMode.disabled)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            // Inyectar CSS para mejorar experiencia móvil
            _controller.runJavaScript('''
              (function() {
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale={{ENABLE_ZOOM}} ? 5.0 : 1.0, user-scalable={{ENABLE_ZOOM}} ? yes : no';
                document.head.appendChild(meta);
                
                var style = document.createElement('style');
                style.innerHTML = `
                  body { 
                    font-size: 16px !important; 
                    line-height: 1.4 !important;
                    -webkit-text-size-adjust: 100% !important;
                  }
                  input, textarea, select { 
                    font-size: 16px !important; 
                  }
                  a, button { 
                    min-height: 44px !important; 
                    display: inline-block !important;
                  }
                `;
                document.head.appendChild(style);
              })();
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Permitir navegación dentro del mismo dominio
            if (request.url.startsWith('{{APP_URL}}')) {
              return NavigationDecision.navigate;
            }
            
            // Manejar enlaces externos
            if (request.url.startsWith('http')) {
              _showExternalLinkDialog(request.url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('{{APP_URL}}'));
  }

  void _checkConnectivity() async {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
      
      if (_isConnected && _hasError) {
        _reloadPage();
      }
    });
  }

  void _reloadPage() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _controller.reload();
  }

  void _goBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
    }
  }

  void _goForward() async {
    if (await _controller.canGoForward()) {
      _controller.goForward();
    }
  }

  void _showExternalLinkDialog(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enlace Externo'),
          content: Text('¿Deseas abrir este enlace en tu navegador?\n\n$url'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Abrir'),
              onPressed: () {
                Navigator.of(context).pop();
                // En una app real, usarías url_launcher aquí
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TCG AI PRO'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: _goForward,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _reloadPage,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_isConnected)
            Container(
              color: Colors.red.withOpacity(0.1),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Sin conexión a Internet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Verifica tu conexión e intenta de nuevo'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reloadPage,
                      child: Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (_hasError)
            Container(
              color: Colors.grey.withOpacity(0.1),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Error al cargar la página',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('No se pudo conectar al sitio web'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reloadPage,
                      child: Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else
            RefreshIndicator(
              onRefresh: () async {
                _reloadPage();
                await Future.delayed(Duration(milliseconds: 500));
              },
              child: WebViewWidget(controller: _controller),
            ),
          
          if (_isLoading && !_hasError)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(int.parse('{{PRIMARY_COLOR}}'.replaceFirst('#', '0xFF'))),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 