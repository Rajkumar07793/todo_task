import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  final Connectivity _connectivity = Connectivity();
  ConnectivityCubit() : super(ConnectivityStatus.online) {
    _monitor();
  }

  void _monitor() async {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        emit(ConnectivityStatus.offline);
      } else {
        emit(ConnectivityStatus.online);
      }
    });
  }
}
