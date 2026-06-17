import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentSuccessData {
  final String orderId;
  final String policyNumber;
  final String amountPaid;
  final String status;
  final String policyName;

  PaymentSuccessData({
    required this.orderId,
    required this.policyNumber,
    required this.amountPaid,
    required this.status,
    required this.policyName,
  });
}

abstract class PaymentSuccessEvent {}

class FetchPaymentSuccessDetails extends PaymentSuccessEvent {
  final String orderId;
  FetchPaymentSuccessDetails(this.orderId);
}

abstract class PaymentSuccessState {}

class PaymentSuccessInitial extends PaymentSuccessState {}

class PaymentSuccessLoading extends PaymentSuccessState {}

class PaymentSuccessLoaded extends PaymentSuccessState {
  final PaymentSuccessData data;
  PaymentSuccessLoaded(this.data);
}

class PaymentSuccessError extends PaymentSuccessState {
  final String message;
  PaymentSuccessError(this.message);
}

class PaymentSuccessBloc extends Bloc<PaymentSuccessEvent, PaymentSuccessState> {
  PaymentSuccessBloc() : super(PaymentSuccessInitial()) {
    on<FetchPaymentSuccessDetails>(_onFetchDetails);
  }

  Future<void> _onFetchDetails(
      FetchPaymentSuccessDetails event,
      Emitter<PaymentSuccessState> emit,
      ) async {
    emit(PaymentSuccessLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));

      final mockData = PaymentSuccessData(
        orderId: event.orderId,
        policyNumber: 'POL-3B668B7A',
        amountPaid: 'Rs. 1110.82',
        status: 'Active',
        policyName: 'amit yadssv',
      );

      emit(PaymentSuccessLoaded(mockData));
    } catch (e) {
      emit(PaymentSuccessError('Failed to load payment details.'));
    }
  }
}