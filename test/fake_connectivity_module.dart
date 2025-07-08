import 'package:prjectcm/connectivity_module.dart';

class FakeConnectivityModule extends ConnectivityModule {
  bool online;

  FakeConnectivityModule({this.online = true});

  @override
  Future<bool> checkConnectivity() async => online == true;
}