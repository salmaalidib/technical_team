part of 'bloc_bloc.dart';

sealed class BlocState extends Equatable {
  const BlocState();
  
  @override
  List<Object> get props => [];
}

final class BlocInitial extends BlocState {}
